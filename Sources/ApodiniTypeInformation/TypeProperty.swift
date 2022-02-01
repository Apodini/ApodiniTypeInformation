//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents distinct cases of necessities for parameters or properties of an object
public enum Necessity: String, TypeInformationElement {
    /// `.required` necessity describes properties which require a value in any case.
    case required
    /// `.optional` necessity describes properties which do not necessarily require a value.
    case optional
}

/// An object that represents a property of an `.object` TypeInformation
public struct TypeProperty {
    /// Name of the property
    public let name: String
    /// Type of the property
    public private(set) var type: TypeInformation
    /// Annotation of the property, e.g. `@Field` of Fluent property
    public let annotation: String?
    /// Any `Context` information associated with the property.
    public let context: Context

    /// Necessity of a property
    public var necessity: Necessity {
        type.isOptional ? .optional : .required
    }
    
    /// Initializes a new `TypeProperty` instance
    public init(name: String, type: TypeInformation, annotation: String? = nil, context: Context = Context()) {
        self.name = name
        self.type = type
        self.annotation = annotation
        self.context = context
    }
    
    /// Returns a version of self where the type is a reference
    public func referencedType() -> TypeProperty {
        .init(name: name, type: type.asReference(), annotation: annotation)
    }

    /// Creates and stores a `.reference` of the `TypeInformation` into the desired `TypeStore`.
    /// - Parameter typeStore: The `TypeStore` to contact
    public mutating func reference(into typeStore: inout TypesStore) {
        type = typeStore.store(type)
    }

    /// Dereference the `TypeInformation` of the property.
    /// - Parameter typeStore: The `TypeStore` to contact
    public mutating func dereference(from typeStore: TypesStore) {
        type = typeStore.construct(from: type)
    }
}

extension TypeProperty: Codable {
    // MARK: Private Inner Types
    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case annotation
        case context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(TypeInformation.self, forKey: .type)
        annotation = try container.decodeIfPresent(String.self, forKey: .annotation)
        context = try container.decodeIfPresent(Context.self, forKey: .context) ?? Context()
    }
}

extension TypeProperty: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
    }

    public static func == (lhs: TypeProperty, rhs: TypeProperty) -> Bool {
        lhs.name == rhs.name
            && lhs.type == rhs.type
    }
}
