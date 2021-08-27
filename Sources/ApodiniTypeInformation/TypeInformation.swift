//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import MetadataSystem

public enum TypeInformation: TypeInformationElement {
    /// A scalar type
    case scalar(PrimitiveType)
    /// A repeated type (set or array), with `TypeInformation` elements
    indirect case repeated(element: TypeInformation)
    /// A dictionary with primitive keys and `TypeInformation` values
    indirect case dictionary(key: PrimitiveType, value: TypeInformation)
    /// An optional type with `TypeInformation` wrapped values
    indirect case optional(wrappedValue: TypeInformation)
    /// An enum type with `String` cases.
    /// The `Context` captures any Metadata Declarations, if the analyzed type provides
    /// Metadata Declarations by conforming to `StaticContentMetadataBlock`.
    indirect case `enum`(name: TypeName, rawValueType: TypeInformation?, cases: [EnumCase], context: Context = .init())
    /// An object type with properties containing a `TypeInformation` and a name.
    /// The `Context` captures any Metadata Declarations, if the analyzed type provides
    /// Metadata Declarations by conforming to `StaticContentMetadataBlock`.
    case object(name: TypeName, properties: [TypeProperty], context: Context = .init())
    /// A reference to a type information instance
    case reference(ReferenceKey)
}

// MARK: - TypeInformation + Equatable + Hashable
extension TypeInformation: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .scalar(primitiveType):
            hasher.combine(0)
            hasher.combine(primitiveType)
        case let .repeated(element):
            hasher.combine(1)
            hasher.combine(element)
        case let .dictionary(key, value):
            hasher.combine(2)
            hasher.combine(key)
            hasher.combine(value)
        case let .optional(wrappedValue):
            hasher.combine(3)
            hasher.combine(wrappedValue)
        case let .enum(name, rawValueType, cases, _):
            hasher.combine(4)
            hasher.combine(name)
            hasher.combine(rawValueType)
            hasher.combine(cases)
            // context is not considered for hashing
        case let .object(name, properties, _):
            hasher.combine(5)
            hasher.combine(name)
            hasher.combine(properties)
            // context is not considered for hashing
        case let .reference(referenceKey):
            hasher.combine(6)
            hasher.combine(referenceKey)
        }
    }

    /// Returns with lhs is equal to rhs
    public static func == (lhs: TypeInformation, rhs: TypeInformation) -> Bool {
        if !lhs.sameType(with: rhs) {
            return false
        }
        
        switch (lhs, rhs) {
        case let (.scalar(lhsPrimitiveType), .scalar(rhsPrimitiveType)):
            return lhsPrimitiveType == rhsPrimitiveType
        case let (.repeated(lhsElement), .repeated(rhsElement)):
            return lhsElement == rhsElement
        case let (.dictionary(lhsKey, lhsValue), .dictionary(rhsKey, rhsValue)):
            return lhsKey == rhsKey && lhsValue == rhsValue
        case let (.optional(lhsWrappedValue), .optional(rhsWrappedValue)):
            return lhsWrappedValue == rhsWrappedValue
        case let (.enum(lhsName, lhsRawValue, lhsCases, _), .enum(rhsName, rhsRawValue, rhsCases, _)):
            return lhsName == rhsName && lhsRawValue == rhsRawValue && lhsCases.equalsIgnoringOrder(to: rhsCases)
        case let (.object(lhsName, lhsProperties, _), .object(rhsName, rhsProperties, _)):
            return lhsName == rhsName && lhsProperties.equalsIgnoringOrder(to: rhsProperties)
        case let (.reference(lhsKey), .reference(rhsKey)):
            return lhsKey == rhsKey
        default:
            return false
        }
    }
}

// MARK: - TypeInformation + Codable
extension TypeInformation {
    // MARK: CodingKeys
    private enum CodingKeys: String, CodingKey {
        case scalar, repeated, dictionary, optional, `enum`, object, reference
    }
    
    private enum DictionaryKeys: String, CodingKey {
        case key, value
    }
    
    private enum EnumKeys: String, CodingKey {
        case typeName, rawValueType, cases
    }
    
    private enum ObjectKeys: String, CodingKey {
        case typeName, properties
    }
    
    /// Encodes self into the given encoder.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .scalar(primitiveType):
            try container.encode(primitiveType, forKey: .scalar)
        case let .repeated(element):
            try container.encode(element, forKey: .repeated)
        case let .dictionary(key, value):
            var dictionaryContainer = container.nestedContainer(keyedBy: DictionaryKeys.self, forKey: .dictionary)
            try dictionaryContainer.encode(key, forKey: .key)
            try dictionaryContainer.encode(value, forKey: .value)
        case let .optional(wrappedValue): try container.encode(wrappedValue, forKey: .optional)
        case let .enum(name, rawValue, cases, _):
            var enumContainer = container.nestedContainer(keyedBy: EnumKeys.self, forKey: .enum)
            try enumContainer.encode(name, forKey: .typeName)
            try enumContainer.encodeIfPresent(rawValue, forKey: .rawValueType)
            try enumContainer.encode(cases, forKey: .cases)
        case let .object(name, properties, _):
            var objectContainer = container.nestedContainer(keyedBy: ObjectKeys.self, forKey: .object)
            try objectContainer.encode(name, forKey: .typeName)
            try objectContainer.encodeIfNotEmpty(properties, forKey: .properties)
        case let .reference(key):
            try container.encode(key, forKey: .reference)
        }
    }
    
    /// Creates a new instance by decoding from the given decoder.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
        case .scalar: self = .scalar(try container.decode(PrimitiveType.self, forKey: .scalar))
        case .repeated: self = .repeated(element: try container.decode(TypeInformation.self, forKey: .repeated))
        case .optional: self = .optional(wrappedValue: try container.decode(TypeInformation.self, forKey: .optional))
        case .dictionary:
            let dictionaryContainer = try container.nestedContainer(keyedBy: DictionaryKeys.self, forKey: .dictionary)
            self = .dictionary(
                key: try dictionaryContainer.decode(PrimitiveType.self, forKey: .key),
                value: try dictionaryContainer.decode(TypeInformation.self, forKey: .value)
            )
        case .enum:
            let enumContainer = try container.nestedContainer(keyedBy: EnumKeys.self, forKey: .enum)
            let name = try enumContainer.decode(TypeName.self, forKey: .typeName)
            let rawValueType = try enumContainer.decodeIfPresent(TypeInformation.self, forKey: .rawValueType)
            let cases = try enumContainer.decode([EnumCase].self, forKey: .cases)
            self = .enum(name: name, rawValueType: rawValueType, cases: cases, context: .init())
        case .object:
            let objectContainer = try container.nestedContainer(keyedBy: ObjectKeys.self, forKey: .object)
            self = .object(
                name: try objectContainer.decode(TypeName.self, forKey: .typeName),
                properties: try objectContainer.decodeIfPresentOrInitEmpty([TypeProperty].self, forKey: .properties),
                context: .init()
            )
        case .reference: self = .reference(try container.decode(ReferenceKey.self, forKey: .reference))
        default: throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Failed to decode TypeInformation"))
        }
    }
}
