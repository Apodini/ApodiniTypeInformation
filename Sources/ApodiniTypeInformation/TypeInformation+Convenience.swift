//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniContext

public extension TypeInformation {
    /// A simplified enum of the `typeInformation`
    enum RootType: String, CustomStringConvertible {
        case scalar
        case repeated
        case dictionary
        case optional
        case `enum`
        case object
        case reference
        
        public var description: String {
            rawValue.upperFirst
        }
    }
    
    /// The root type of this `typeInformation`
    var rootType: RootType {
        switch self {
        case .scalar: return .scalar
        case .repeated: return .repeated
        case .dictionary: return .dictionary
        case .optional: return .optional
        case .enum: return .enum
        case .object: return .object
        case .reference: return .reference
        }
    }
    
    /// Indicates whether the root type is a scalar (primitive type)
    var isScalar: Bool {
        rootType == .scalar
    }
    
    /// Indicates whether the root type is a repeated type
    var isRepeated: Bool {
        rootType == .repeated
    }
    
    /// Indicates whether the root type is a dictionary
    var isDictionary: Bool {
        rootType == .dictionary
    }
    
    /// Indicates whether the root type is an optional
    var isOptional: Bool {
        rootType == .optional
    }
    
    /// Indicates whether the root type is an enum
    var isEnum: Bool {
        rootType == .enum
    }
    
    /// Indicates whether the root type is an object
    var isObject: Bool {
        rootType == .object
    }
    
    /// Indicates whether the root type is an enum or an object
    var isEnumOrObject: Bool {
        isEnum || isObject
    }
    
    /// Indicates whether the root type is a reference
    var isReference: Bool {
        rootType == .reference
    }
    
    /// If the root type is enum, returns `self`, otherwise the nested types are searched recursively
    var enumType: TypeInformation? {
        switch self {
        case let .repeated(element): return element.enumType
        case let .dictionary(_, value): return value.enumType
        case let .optional(wrappedValue): return wrappedValue.unwrapped.enumType
        case .enum: return self
        default: return nil
        }
    }
    
    /// If the root type is an object, returns `self`, otherwise the nested types are searched recursively
    var objectType: TypeInformation? {
        switch self {
        case let .repeated(element): return element.objectType
        case let .dictionary(_, value): return value.objectType
        case let .optional(wrappedValue): return wrappedValue.objectType
        case .object: return self
        default: return nil
        }
    }

    /// Returns the referenceKey of an nested reference
    var referenceKey: ReferenceKey? {
        if case let .reference(key) = reference {
            return key
        }
        return nil
    }
    
    /// Returns the nested reference if any. References can be stored inside repeated types, dictionaries, optionals, or at top level
    var reference: TypeInformation? {
        switch self {
        case let .repeated(element): return element.reference
        case let .dictionary(_, value): return value.reference
        case let .optional(wrappedValue): return wrappedValue.reference
        case .reference: return self
        default: return nil
        }
    }
    
    /// Indicates whether the nested or top level element is an object
    var elementIsObject: Bool {
        objectType != nil
    }
    
    /// Indicates whether the nested or top level element is an enum
    var elementIsEnum: Bool {
        enumType != nil
    }
    
    /// Indicates whether the nested or top level element is an enum or an object
    var isReferencable: Bool {
        elementIsObject || elementIsEnum
    }
    
    /// The typeName of this `typeInformation`
    /// results in fatal error if requested for a `.reference`
    var typeName: TypeName {
        switch self {
        case let .scalar(primitiveType): return primitiveType.typeName
        case let .repeated(element): return element.unwrapped.typeName
        case let .dictionary(_, value): return value.unwrapped.typeName
        case let .optional(wrappedValue): return wrappedValue.unwrapped.typeName
        case let .enum(name, _, _, _): return name
        case let .object(name, _, _): return name
        case .reference:
            fatalError("Cannot unwrap `TypeName` for the reference type \(self). Please dereference the type beforehand.")
        }
    }
    
    /// String representation of the type in a `Swift` compliant way, e.g. `User`, `User?`, `[String: User]` or `[User]`
    /// This computed property results in a fatalError if called for a `.reference`.
    var typeString: String {
        switch self {
        case let .scalar(primitiveType): return primitiveType.description
        case let .repeated(element): return "[\(element.typeString)]"
        case let .dictionary(key, value): return "[\(key.description): \(value.typeString)]"
        case let .optional(wrappedValue): return wrappedValue.typeString + "?"
        case .enum, .object, .reference: return typeName.buildName()
        }
    }
    
    /// Nested type string of this type information
    /// This computed property results in a fatalError if called for a `.reference`.
    var nestedTypeString: String {
        switch self {
        case .scalar, .enum, .object: return typeString
        case let .repeated(element): return element.nestedTypeString
        case let .dictionary(_, value): return value.nestedTypeString
        case let .optional(wrappedValue): return wrappedValue.unwrapped.nestedTypeString
        case let .reference(referenceKey): return referenceKey.rawValue
        }
    }
    
    /// Indicate whether `self` has the same root type with other `typeInformation`
    /// - Note: This method was replaced with ``comparingRootType(with:)` to more clearly communicate
    ///     what this method actually does.
    @available(*, deprecated, renamed: "comparingRootType(with:)")
    func sameType(with typeInformation: TypeInformation) -> Bool {
        rootType == typeInformation.rootType
    }

    /// Indicate whether `self` has the same root type with other `typeInformation`
    func comparingRootType(with typeInformation: TypeInformation) -> Bool {
        rootType == typeInformation.rootType
    }
    
    /// Recursively unwraps the value of optional type if `self` is `.optional`
    var unwrapped: TypeInformation {
        if case let .optional(wrapped) = self {
            return wrapped.unwrapped
        }
        return self
    }
    
    /// Returns the dictionary key if `self` is `.dictionary`
    var dictionaryKey: PrimitiveType? {
        if case let .dictionary(key, _) = self {
            return key
        }
        return nil
    }
    
    /// Returns the dictionary value type if `self` is `.dictionary`
    var dictionaryValue: TypeInformation? {
        if case let .dictionary(_, value) = self {
            return value
        }
        return nil
    }
    
    /// Returns object properties if `self` is `.object`, otherwise an empty array
    var objectProperties: [TypeProperty] {
        switch self {
        case let .object(_, properties, _): return properties
        default: return objectType?.objectProperties ?? []
        }
    }
    
    /// Returns enum cases if `self` is `.enum`, otherwise an empty array
    var enumCases: [EnumCase] {
        if case let .enum(_, _, cases, _) = self {
            return cases
        }
        return []
    }
    
    /// Return rawValueType type if `self` is enum and enum has a raw value type.
    var rawValueType: TypeInformation? {
        if case let .enum(_, rawValueType, _, _) = self {
            return rawValueType
        }
        return nil
    }
    
    /// Wraps a type descriptor as an optional type. If already an optional, returns self
    var asOptional: TypeInformation {
        isOptional ? self : .optional(wrappedValue: self)
    }

    /// Retrieves the `Context` where parsed Metadata is stored of a ``TypeInformation`` instance.
    /// Returns nil for cases of ``TypeInformation`` which don't expose Metadata declaration blocks.
    var context: Context? {
        switch self {
        case let .object(_, _, context):
            return context
        case let .enum(_, _, _, context):
            return context
        default:
            return nil
        }
    }
    
    /// Recursively returns all types included in this `typeInformation`, e.g. primitive types, enums, objects
    ///  and nested elements in repeated types, dictionaries and optionals
    func allTypes() -> [TypeInformation] {
        var allTypes: Set<TypeInformation> = [self]
        switch self {
        case let .repeated(element):
            allTypes += element.allTypes()
        case let .dictionary(key, value):
            allTypes += .scalar(key) + value.allTypes()
        case let .optional(wrappedValue):
            allTypes += wrappedValue.allTypes()
        case let .object(_, properties, _):
            allTypes += properties.flatMap { $0.type.allTypes() }
        default: break
        }
        return Array(allTypes)
    }
    
    /// Returns whether the typeInformation is contained in `allTypes()` of self
    func contains(_ typeInformation: TypeInformation?) -> Bool {
        guard let typeInformation = typeInformation else {
            return false
        }
        return allTypes().contains(typeInformation)
    }
    
    /// Returns whether the `self` is contained in `allTypes()` of `typeInformation`
    func isContained(in typeInformation: TypeInformation) -> Bool {
        typeInformation.contains(self)
    }
    
    /// Filters `allTypes()` by a boolean property of `TypeInformation`
    func filter(_ keyPath: KeyPath<TypeInformation, Bool>) -> [TypeInformation] {
        allTypes().filter { $0[keyPath: keyPath] }
    }
    
    /// Returns a version of self as a reference
    func asReference() -> TypeInformation {
        switch self {
        case .scalar: return self
        case let .repeated(element):
            return .repeated(element: element.asReference())
        case let .dictionary(key, value):
            return .dictionary(key: key, value: value.asReference())
        case let .optional(wrappedValue):
            return .optional(wrappedValue: wrappedValue.asReference())
        case .enum, .object:
            return .reference(.init(typeName.buildName(componentSeparator: ".", genericsStart: "<", genericsSeparator: ",", genericsDelimiter: ">")))
        case .reference:
            fatalError("Attempted to reference a reference")
        }
    }
    
    /// Returns the property with name `named`
    func property(_ named: String) -> TypeProperty? {
        objectProperties.first { $0.name == named }
    }
    
    /// If a object, types of object properties are changed to references
    func referencedProperties() -> TypeInformation {
        switch self {
        case .scalar, .enum: return self
        case let .repeated(element):
            return .repeated(element: element.referencedProperties())
        case let .dictionary(key, value):
            return .dictionary(key: key, value: value.referencedProperties())
        case let .optional(wrappedValue):
            return .optional(wrappedValue: wrappedValue.referencedProperties())
        case let .object(typeName, properties, context):
            return .object(
                name: typeName,
                properties: properties.map { $0.referencedType() },
                context: context
            )
        case .reference: fatalError("Attempted to reference a reference")
        }
    }
    
    /// Returns all distinct scalars in `allTypes()`
    func scalars() -> [TypeInformation] {
        filter(\.isScalar)
    }
    
    /// Returns all distinct repeated types in `allTypes()`
    func repeatedTypes() -> [TypeInformation] {
        filter(\.isRepeated)
    }
    
    /// Returns all distinct dictionaries in `allTypes()`
    func dictionaries() -> [TypeInformation] {
        filter(\.isDictionary)
    }
    
    /// Returns all distinct optionals in `allTypes()`
    func optionals() -> [TypeInformation] {
        filter(\.isOptional)
    }
    
    /// Returns all distinct enums in `allTypes()`
    func enums() -> [TypeInformation] {
        filter(\.isEnum)
    }
    
    /// Returns all distinct objects in `allTypes()`
    func objectTypes() -> [TypeInformation] {
        filter(\.isObject)
    }

    /// Returns a reference with the given string key
    static func reference(_ key: String) -> TypeInformation {
        .reference(.init(key))
    }
}
