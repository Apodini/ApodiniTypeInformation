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
    private var storage: [ReferenceKey: TypeInformation]
    
    /// Initializes a store with an empty storage
    public init() {
        storage = [:]
    }
    
    /// Stores an enum or object type by its type name, and returns the reference
    /// If attempting to store a non referencable type, the operation is ignored and the input type is returned directly
    public mutating func store(_ type: TypeInformation) -> TypeInformation {
        guard type.isReferencable else {
            return type
        }

        let reference = type.asReference()
        guard let key = reference.referenceKey else {
            fatalError("Entered irrecoverable state. ReferenceKey wasn't available after creating type reference!")
        }
        
        if let enumType = type.enumType { // retrieving the nested enum
            storage[key] = enumType
        } else if let objectType = type.objectType { // retrieving the nested object
            let referencedProperties = objectType.objectProperties.map { property -> TypeProperty in
                TypeProperty(
                    name: property.name,
                    type: store(property.type), // storing potentially referencable properties
                    annotation: property.annotation
                )
            }

            storage[key] = .object(
                name: objectType.typeName,
                properties: referencedProperties,
                context: objectType.context ?? .init()
            )
        }
        
        return reference
    }
    
    /// Constructs a type from a reference
    public func construct(from reference: TypeInformation) -> TypeInformation {
        guard let referenceKey = reference.referenceKey,
              var stored = storage[referenceKey] else {
            return reference
        }
        
        /// If the stored type is an object, we recursively construct its properties and update the stored
        if case let .object(name, properties, context) = stored {
            let newProperties = properties.map { property -> TypeProperty in
                if property.type.reference != nil {
                    return TypeProperty(
                        name: property.name,
                        type: property.type.construct(in: self),
                        annotation: property.annotation
                    )
                }
                return property
            }
            stored = .object(name: name, properties: newProperties, context: context)
        }

        // If the reference is at root, means the stored object has either been an object or enum -> return directly
        if case .reference = reference {
            return stored
        }

        // otherwise the stored object has been nested -> construct recursively
        return reference.construct(in: self)
    }
}

// MARK: - TypeInformation + TypesStore support
private extension TypeInformation {
    /// Used to construct properties of object or enum types recursively
    func construct(in store: TypesStore) -> TypeInformation {
        switch self {
        case let .repeated(element):
            return .repeated(element: element.construct(in: store))
        case let .dictionary(key, value):
            return .dictionary(key: key, value: value.construct(in: store))
        case let .optional(wrappedValue):
            return .optional(wrappedValue: wrappedValue.construct(in: store))
        // initial reference has been recursively deconstructed until here -> construct from self
        case .reference:
            return store.construct(from: self)
        default:
            fatalError("Attempted to construct a non referencable type")
        }
    }
}

extension TypesStore: Codable {
    public init(from decoder: Decoder) throws {
        try storage = .init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        try storage.encode(to: encoder)
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
