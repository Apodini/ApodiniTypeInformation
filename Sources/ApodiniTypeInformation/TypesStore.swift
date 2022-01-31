//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// ``TypesStore`` provides logic to reference and store ``TypeInformation`` instances, while e.g. an endpoint keeps only the reference of the response type
/// Provided with a reference from ``TypeStore``, the instance of ``TypeInformation``
/// can be constructed without information-loss via `construct(from:)`
/// The lifecycle of a ``TypeStore`` is limited only during encoding and decoding of `Document`
public struct TypesStore {
    /// Stored references of enums and objects
    /// Properties of objects are recursively stored
    var storage: [ReferenceKey: TypeInformation]

    /// A collection containing just the keys of the ``TypeStore``.
    public var keys: Dictionary<ReferenceKey, TypeInformation>.Keys {
        storage.keys
    }

    /// A collection containing just the values of the ``TypeStore``.
    public var values: Dictionary<ReferenceKey, TypeInformation>.Values {
        storage.values
    }


    /// Initializes a store with an empty storage
    public init() {
        storage = [:]
    }

    /// Stores an enum or object type by its type name, and returns the reference
    /// If attempting to store a non referencable type, the operation is ignored and the input type is returned directly
    public mutating func store(_ type: TypeInformation) -> TypeInformation {
        switch type {
        case .scalar:
            return type
        case let .repeated(element):
            return .repeated(element: store(element))
        case let .dictionary(key, value):
            return .dictionary(key: key, value: store(value))
        case let .optional(wrappedValue):
            return .optional(wrappedValue: store(wrappedValue))
        case .enum:
            let reference = type.asReference()
            guard let key = reference.referenceKey else {
                fatalError("Entered irrecoverable state. ReferenceKey wasn't available after creating type reference!")
            }

            storage[key] = type
            return reference
        case let .object(name, properties, context):
            let reference = type.asReference()
            guard let key = reference.referenceKey else {
                fatalError("Entered irrecoverable state. ReferenceKey wasn't available after creating type reference!")
            }

            let referencedProperties = properties.map { property in
                TypeProperty(
                    name: property.name,
                    type: store(property.type), // storing potentially referencable properties
                    annotation: property.annotation
                )
            }

            storage[key] = .object(name: name, properties: referencedProperties, context: context)
            return reference
        case .reference:
            return type
        }
    }

    /// Constructs a type from a reference
    public func construct(from type: TypeInformation) -> TypeInformation {
        switch type {
        case .scalar:
            return type
        case let .repeated(element):
            return .repeated(element: construct(from: element))
        case let .dictionary(key, value):
            return .dictionary(key: key, value: construct(from: value))
        case let .optional(wrappedValue):
            return .optional(wrappedValue: construct(from: wrappedValue))
        case .enum:
            return type
        case let .object(name, properties, context):
            let dereferencedProperties = properties.map { property in
                TypeProperty(
                    name: property.name,
                    type: construct(from: property.type),
                    annotation: property.annotation
                )
            }

            return .object(name: name, properties: dereferencedProperties, context: context)
        case .reference:
            return dereference(reference: type)
        }
    }

    private func dereference(reference: TypeInformation) -> TypeInformation {
        guard let referenceKey = reference.referenceKey,
              let stored = storage[referenceKey] else {
            return reference // we don't have the reference :(
        }

        return construct(from: stored)
    }
}

extension TypesStore: Codable {
    public init(from decoder: Decoder) throws {
        try storage = [String: TypeInformation](from: decoder)
            .map { (ReferenceKey(rawValue: $0.key), $0.value) }
            .reduce(into: [:]) { result, element in
                result[element.0] = element.1
            }
    }

    public func encode(to encoder: Encoder) throws {
        try storage
            .map { ($0.key.rawValue, $0.value) }
            .reduce(into: [String: TypeInformation]()) { result, element in
                result[element.0] = element.1
            }
            .encode(to: encoder)
    }
}

extension TypesStore: Hashable {}

extension TypesStore: Sequence {
    public typealias Iterator = Dictionary<ReferenceKey, TypeInformation>.Iterator

    public func makeIterator() -> Iterator {
        storage.makeIterator()
    }
}

extension TypesStore: Collection {
    public typealias Index = Dictionary<ReferenceKey, TypeInformation>.Index
    public typealias Element = Dictionary<ReferenceKey, TypeInformation>.Element

    public var startIndex: Index {
        storage.startIndex
    }
    public var endIndex: Index {
        storage.endIndex
    }
    public subscript(position: Index) -> Element {
        storage[position]
    }

    public func index(after index: Index) -> Index {
        storage.index(after: index)
    }
}
