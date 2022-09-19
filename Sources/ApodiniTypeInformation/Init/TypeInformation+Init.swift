//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import TypeInformationMetadata

/// With this enum option you can control how Enum cases with associated values are handled in the TypeInformation representation.
public enum EnumWithAssociatedValuesHandling {
    /// The parser will reject enums which contain cases with associated values.
    case reject
    /// The parser will not include enum cases with a payload type in the TypeInformation representation.
    case ignore
    // we could eventually add a `.support` case, but this would require some major refactoring of the `EnumCase` structure
}

// MARK: - TypeInformation public
public extension TypeInformation {
    /// Errors
    enum TypeInformationError: Error {
        case notSupportedDictionaryKeyType
        case initFailure(message: String)
        case malformedFluentProperty(message: String)
        case enumCaseWithAssociatedValue(message: String)
    }
    
    /// Initializes a type information from Any instance using `RuntimeBuilder`
    init(value: Any, enumAssociatedValues: EnumWithAssociatedValuesHandling = .reject) throws {
        self = try .init(type: type(of: value), enumAssociatedValues: enumAssociatedValues)
    }
    
    /// Initializes a type information instance from any type using `RuntimeBuilder`
    init(type: Any.Type, enumAssociatedValues: EnumWithAssociatedValuesHandling = .reject) throws {
        self = try .init(for: type, enumAssociatedValues: enumAssociatedValues)
    }
}

// MARK: - TypeInformation internal
extension TypeInformation {
    /// Initializes a ``TypeInformation`` instance from `type`
    private init(for type: Any.Type, enumAssociatedValues: EnumWithAssociatedValuesHandling) throws {
        if let type = type as? TypeInformationDefaultConstructor.Type {
            self = type.construct()
        } else if let type = type as? TypeInformationComplexConstructor.Type {
            self = try type.construct(with: RuntimeBuilder.self)
        } else {
            let typeInfo = try info(of: type)
        
            if typeInfo.kind == .enum {
                if typeInfo.numberOfPayloadEnumCases > 0 && enumAssociatedValues == .reject {
                    throw TypeInformationError.enumCaseWithAssociatedValue(
                        message: "Construction of enums with associated values is currently not supported"
                    )
                }

                let rawValueType: TypeInformation?
                if let rawRepresentableTy = type as? any RawRepresentable.Type {
                    rawValueType = try .init(for: rawRepresentableTy.underlyingRawValueType, enumAssociatedValues: enumAssociatedValues)
                } else {
                    rawValueType = nil
                }

                let context = Self.parseMetadata(for: type)

                let cases: [EnumCase] = typeInfo
                    .cases
                    .filter { (enumAssociatedValues == .ignore ? $0.payloadType == nil : true) }
                    .map { EnumCase($0.name) }

                self = .enum(name: typeInfo.typeName, rawValueType: rawValueType, cases: cases, context: context)
            } else if [.struct, .class].contains(typeInfo.kind) {
                let properties: [TypeProperty] = try typeInfo.properties()
                    .compactMap {
                        do {
                            if let fluentProperty = $0.fluentPropertyType {
                                return .init(
                                    name: $0.name,
                                    type: try .fluentProperty($0, associatedValues: enumAssociatedValues),
                                    annotation: fluentProperty.description
                                )
                            }
                            
                            if let wrappedValueType = $0.propertyWrapperWrappedValueType {
                                return .init(
                                    name: $0.name,
                                    type: try .init(for: wrappedValueType, enumAssociatedValues: enumAssociatedValues),
                                    annotation: "@" + $0.typeInfo.mangledName
                                )
                            }
                            
                            return .init(name: $0.name, type: try .init(for: $0.type, enumAssociatedValues: enumAssociatedValues))
                        } catch {
                            if knownRuntimeError(error) {
                                return nil
                            }
                            
                            throw TypeInformationError.initFailure(message: error.localizedDescription)
                        }
                    }

                let context = Self.parseMetadata(for: type)

                self = .object(name: typeInfo.typeName, properties: properties, context: context)
            } else {
                throw TypeInformationError.initFailure(message: "TypeInformation construction of \(typeInfo.kind) is not supported")
            }
        }
    }

    static func parseMetadata(for type: Any.Type) -> Context {
        let parser = StandardMetadataParser()
        if let content = type as? AnyStaticContentMetadataBlock.Type {
            content.collectMetadata(parser)
        }
        return parser.exportContext()
    }
    
    /// Returns the ``TypeInformation`` instance corresponding to `property`, by considering the type of wrappedValue of property wrapper
    private static func fluentProperty(_ property: RuntimeProperty, associatedValues: EnumWithAssociatedValuesHandling) throws -> TypeInformation {
        guard let fluentProperty = property.fluentPropertyType, property.genericTypes.count > 1 else {
            throw TypeInformationError.malformedFluentProperty(message: "Failed to construct TypeInformation of property \(property.name) of \(property.ownerType)")
        }
        
        let nestedPropertyType = property.genericTypes[1]
        switch fluentProperty {
        case .timestampProperty: return .optional(wrappedValue: .scalar(.date))
        case .enumProperty, .fieldProperty, .groupProperty:
            return try .init(for: nestedPropertyType, enumAssociatedValues: associatedValues)
        case .iDProperty, .optionalEnumProperty, .optionalChildProperty, .optionalFieldProperty:
            return .optional(wrappedValue: try .init(for: nestedPropertyType, enumAssociatedValues: associatedValues))
        case .childrenProperty:
            return .repeated(element: try .init(for: nestedPropertyType, enumAssociatedValues: associatedValues))
        case .optionalParentProperty, .parentProperty: return try .parentProperty(of: property, associatedValues: associatedValues)
        case .siblingsProperty: return try .siblingsProperty(of: property, associatedValues: associatedValues)
        }
    }
    
    /// Initializes a ``TypeInformation`` instance corresponding to a `@Parent` fluent property wrapper
    private static func parentProperty(of property: RuntimeProperty, associatedValues: EnumWithAssociatedValuesHandling) throws -> TypeInformation {
        let nestedPropertyType = property.genericTypes[1] /// safe access, ensured in `fluentProperty(:)`
        let typeInfo = try info(of: nestedPropertyType)
        guard
            let idProperty = typeInfo.properties.firstMatch(on: \.name, with: "_id"),
            let propertyTypeInfo = try? RuntimeProperty(idProperty),
            propertyTypeInfo.isIDProperty,
            propertyTypeInfo.genericTypes.count > 1
        else { throw TypeInformationError.malformedFluentProperty(message: "Could not find the id property of \(nestedPropertyType)") }
        
        let idType = propertyTypeInfo.genericTypes[1]
        
        let customIDObject: TypeInformation = .object(
            name: .init(rawValue: String(describing: nestedPropertyType) + "ID"),
            properties: [.init(name: "id", type: .optional(wrappedValue: try .init(for: idType, enumAssociatedValues: associatedValues)))],
            context: parseMetadata(for: nestedPropertyType)
        )
        
        return property.fluentPropertyType == .optionalParentProperty
            ? .optional(wrappedValue: customIDObject)
            : customIDObject
    }
    
    /// Initializes a ``TypeInformation`` instance corresponding to a `@Siblings` fluent property wrapper
    private static func siblingsProperty(
        of siblingsProperty: RuntimeProperty,
        associatedValues: EnumWithAssociatedValuesHandling
    ) throws -> TypeInformation {
        let nestedPropertyType = siblingsProperty.genericTypes[1] /// safe access, ensured in `fluentProperty(:)`
        let typeInfo = try info(of: nestedPropertyType)
        let properties: [TypeProperty] = try typeInfo.properties()
            .compactMap { nestedTypeProperty in
                if nestedTypeProperty.isFluentProperty {
                    if nestedTypeProperty.fluentPropertyType == .siblingsProperty,
                       ObjectIdentifier(siblingsProperty.ownerType) == ObjectIdentifier(nestedTypeProperty.genericTypes[1]) {
                        return nil
                    }
                    
                    let propertyTypeInformation: TypeInformation = try .fluentProperty(nestedTypeProperty, associatedValues: associatedValues)
                    return .init(
                        name: nestedTypeProperty.name,
                        type: propertyTypeInformation,
                        annotation: nestedTypeProperty.fluentPropertyType?.description
                    )
                }
                return .init(
                    name: nestedTypeProperty.name,
                    type: try .init(for: nestedTypeProperty.type, enumAssociatedValues: associatedValues),
                    annotation: nestedTypeProperty.fluentPropertyType?.description
                )
            }

        return .repeated(element: .object(
            name: typeInfo.typeName,
            properties: properties,
            context: parseMetadata(for: nestedPropertyType)
        ))
    }
}

//private struct RawEnumVisitor: RawRepresentableTypeVisitor {
//    func callAsFunction<T: RawRepresentable>(_ type: T.Type) -> Any.Type {
//        T.self.RawValue
//    }
//}

extension RawRepresentable {
    fileprivate static var underlyingRawValueType: Any.Type {
        Self.RawValue.self
    }
}
