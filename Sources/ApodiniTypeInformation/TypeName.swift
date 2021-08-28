//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// An object that represents names of the types
public struct TypeName: TypeInformationElement {
    /// Name of the module / target where the type has been defined
    public let definedIn: String?
    /// Mangled name of the type
    public let name: String
    /// Ordered nested types (namespace) where the type with name `name` has been defined
    public let nestedTypeNames: [TypeName]
    /// Type names of generic types of the type with name `name`
    public let genericTypeNames: [TypeName]
    
    /// `name` by prepending the mapped `namespacedName` of `nestedTypeNames`
    ///  - Note: generic type names are ignored. Use `absoluteName(_:_:)` for including generic type names
    public var namespacedName: String {
        nestedTypeNames.map { $0.namespacedName }.joined() + name
    }
    
    /// Initializes `self` out of `Any.Type`
    public init(_ type: Any.Type) {
        self.init(TypeNameParser(String(reflecting: type)).parse())
    }
    
    private init(_ parsedTypeName: ParsedTypeName) {
        precondition(!parsedTypeName.isEmpty, "Type name parser parsed empty components")
        var definedIn: String?

        if case let .targetName(name) = parsedTypeName.first {
            definedIn = name
        }

        // the last typeName element is always our "main" type.
        guard case let .typeName(mainTypeName, generics) = parsedTypeName.last else {
            fatalError("Something went fundamentally wrong. Failed to get the type name component")
        }

        // everything in between are nested types
        var nestedTypeNames: [TypeName] = []
        for index in parsedTypeName.indices.dropFirst() {
            let nestedParsedTypes = Array(parsedTypeName[parsedTypeName.startIndex ..< index])

            // ignoring targetName component
            if case .targetName = nestedParsedTypes.first, nestedParsedTypes.count == 1 {
                continue
            }

            nestedTypeNames.append(.init(nestedParsedTypes))
        }

        let genericTypeNames: [TypeName] = generics.isEmpty ? [] : generics.map { .init($0) }
        self.init(name: mainTypeName, definedIn: definedIn, nestedTypeNames: nestedTypeNames, genericTypeNames: genericTypeNames)
    }

    /// Initializes a new type name instance
    /// - Parameters:
    ///    - name: Mangled name of the type, e.g. `Container<Value>` -> `Container`
    ///    - definedIn: name of the module / target where the type has been defined, `Swift.Int` -> `Swift`
    ///    - nestedTypeNames: Ordered nested type names (namespaces) where the type with name `name` has been defined
    ///    - genericTypeNames: Type names of generic types of the type with name `name`
    public init(name: String, definedIn: String? = nil, nestedTypeNames: [TypeName] = [], genericTypeNames: [TypeName] = []) {
        self.name = name
        self.definedIn = definedIn
        self.nestedTypeNames = nestedTypeNames
        self.genericTypeNames = genericTypeNames
    }
    
    /// Absolute name of the type. Constructed by joining the absolute names of `nestedTypeNames`, appending `name` and the join
    /// of `genericTypeNames`, e.g. `Namespace.Container<String, Int>` -> `NamespaceContainerOfStringAndInt`
    ///  - Parameters:
    ///     - genericsPrefix: Prefix of the first generic type name, defaults to `Of`
    ///     - genericsJoiner: Joiner for generic type names, defaults to `And`
    public func absoluteName(_ genericsPrefix: String = "Of", _ genericsJoiner: String = "And") -> String {
        var absoluteName = nestedTypeNames.map { $0.absoluteName(genericsPrefix, genericsJoiner) }.joined()
        absoluteName += name
        if !genericTypeNames.isEmpty {
            let generics = genericTypeNames.map { $0.absoluteName(genericsPrefix, genericsJoiner) }.joined(separator: genericsJoiner)
            absoluteName += "\(genericsPrefix)\(generics)"
        }
        return absoluteName
    }
}

// MARK: - Codable
extension TypeName: Codable {
    // MARK: Coding Keys
    private enum CodingKeys: String, CodingKey {
        case name, definedIn = "defined-in", nestedTypeNames, genericTypeNames
    }

    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        definedIn = try container.decodeIfPresent(String.self, forKey: .definedIn)
        nestedTypeNames = try container.decodeIfPresentOrInitEmpty([TypeName].self, forKey: .nestedTypeNames)
        genericTypeNames = try container.decodeIfPresentOrInitEmpty([TypeName].self, forKey: .genericTypeNames)
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(definedIn, forKey: .definedIn)
        try container.encodeIfNotEmpty(nestedTypeNames, forKey: .nestedTypeNames)
        try container.encodeIfNotEmpty(genericTypeNames, forKey: .genericTypeNames)
    }
}

// MARK: - Comparable + Equatable
extension TypeName: Comparable {
    /// String comparison of `name`
    public static func < (lhs: TypeName, rhs: TypeName) -> Bool {
        lhs.name < rhs.name
    }
}
