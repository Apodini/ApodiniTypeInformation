//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

public struct TypeNameComponent: TypeInformationElement {
    private enum CodingKeys: String, CodingKey {
        case name
        case generics
    }

    /// Mangled name of the type component
    public let name: String
    public let generics: [TypeName]

    public init(name: String, generics: [TypeName] = []) {
        self.name = name
        self.generics = generics
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try name = container.decode(String.self, forKey: .name)
        try generics = container.decodeIfPresentOrInitEmpty([TypeName].self, forKey: .generics)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encodeIfNotEmpty(generics, forKey: .generics)
    }
}

/// An object that represents names of the types
public struct TypeName: TypeInformationElement, RawRepresentable {
    public var rawValue: String {
        buildName(printTargetName: true, componentSeparator: ".", genericsStart: "<", genericsSeparator: ",", genericsDelimiter: ">")
    }

    /// Name of the module / target where the type has been defined
    public let definedIn: String?

    /// The root type component. It holds the mangled name and its generic types
    private let rootType: TypeNameComponent

    /// Ordered nested types (namespace) where the root type is defined.
    public let nestedTypes: [TypeNameComponent]

    public var mangledName: String {
        rootType.name
    }

    public var generics: [TypeName] {
        rootType.generics
    }
    
    /// Initializes `self` out of `Any.Type`
    public init(_ type: Any.Type) {
        self.init(rawValue: String(reflecting: type))
    }

    public init(rawValue: String) {
        self.init(TypeNameParser(rawValue).parse())
    }
    
    private init(_ parsedTypeName: ParsedTypeName) {
        precondition(!parsedTypeName.isEmpty, "Type name parser parsed empty components")
        var parsedTypeName = parsedTypeName

        var definedIn: String?
        var nestedTypeNames: [TypeNameComponent] = []

        if case let .targetName(name) = parsedTypeName.first {
            definedIn = name
            parsedTypeName.removeFirst() // consumed!
        }

        // the last typeName element is always our "main" type.
        guard case let .typeName(mainTypeName, generics) = parsedTypeName.last else {
            fatalError("Something went fundamentally wrong. Failed to get the type name component")
        }

        parsedTypeName.removeLast()

        // everything in between are nested types
        for nestedType in parsedTypeName {
            guard case let .typeName(nestedTypeName, generics) = nestedType else {
                fatalError("Didn't expect another targetName component in parser result!")
            }

            nestedTypeNames.append(TypeNameComponent(
                name: nestedTypeName,
                generics: generics.map { TypeName($0) }
            ))
        }

        let rootType = TypeNameComponent(
            name: mainTypeName,
            generics: generics.map { TypeName($0) }
        )


        self.init(definedIn: definedIn, rootType: rootType, nestedTypes: nestedTypeNames)
    }

    /// Initializes a new type name instance
    /// - Parameters:
    ///    - definedIn: name of the module / target where the type has been defined, `Swift.Int` -> `Swift`
    ///    - rootType: The ``TypeNameComponent`` describing the actual type.
    ///    - nestedTypes: Array of ``TypeNameComponent``s describing any potentially nested types.
    public init(definedIn: String? = nil, rootType: TypeNameComponent, nestedTypes: [TypeNameComponent] = []) {
        self.definedIn = definedIn
        self.rootType = rootType
        self.nestedTypes = nestedTypes
    }

    /// Builds the name of the ``TypeName``.
    ///
    /// - Parameters:
    ///   - printTargetName: Defines if the target name (``definedIn`` property) is included in the name.
    ///   - componentSeparator: The symbol to use to separate the individual ``TypeNameComponent``s.
    ///   - genericsStart: The symbol to start a list of generics.
    ///   - genericsSeparator: The symbol to separate individual generic items of a given ``TypeNameComponent``.
    ///   - genericsDelimiter: The symbol to indicate the ending of a list of generics  of a given ``TypeNameComponent``.
    /// - Returns: The resulting string description of the TypeName.
    public func buildName(
        printTargetName: Bool = false,
        componentSeparator: String = "",
        genericsStart: String = "Of",
        genericsSeparator: String = "And",
        genericsDelimiter: String = ""
    ) -> String {
        var name = printTargetName ? definedIn ?? "" : ""

        for type in (nestedTypes + rootType) {
            if !name.isEmpty {
                name += componentSeparator
            }

            name += type.name

            if !type.generics.isEmpty {
                let generics = rootType.generics
                    .map {
                        $0.buildName(
                            printTargetName: printTargetName,
                            componentSeparator: componentSeparator,
                            genericsStart: genericsStart,
                            genericsSeparator: genericsSeparator,
                            genericsDelimiter: genericsDelimiter
                        )
                    }
                    .joined(separator: genericsSeparator)
                name += "\(genericsStart)\(generics)\(genericsDelimiter)"
            }
        }

        return name
    }

    /// Absolute name of the type. Constructed by joining the absolute names of `nestedTypeNames`, appending `name` and the join
    /// of `genericTypeNames`, e.g. `Namespace.Container<String, Int>` -> `NamespaceContainerOfStringAndInt`
    ///  - Parameters:
    ///     - genericsPrefix: Prefix of the first generic type name, defaults to `Of`
    ///     - genericsJoiner: Joiner for generic type names, defaults to `And`
    @available(*, deprecated, message: "This method was replaced with the new `buildName` method, which exposes the same functionality.")
    public func absoluteName(_ genericsPrefix: String = "Of", _ genericsJoiner: String = "And") -> String {
        buildName(genericsStart: genericsPrefix, genericsSeparator: genericsJoiner)
    }
}

// MARK: - Codable
extension TypeName: Codable {
    // MARK: Coding Keys
    private enum CodingKeys: String, CodingKey {
        case definedIn = "defined-in"
        case rootComponent
        case nestedComponents

        // deprecated cases used for backwards compatibility
        case name
    }

    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard try container.decodeIfPresent(String.self, forKey: .name) == nil else {
            // parse legacy format for TypeName encoding
            try self = LegacyTypeName(from: decoder)
                .migrateToTypeName()
            return
        }

        try definedIn = container.decodeIfPresent(String.self, forKey: .definedIn)
        try rootType = container.decode(TypeNameComponent.self, forKey: .rootComponent)
        try nestedTypes = container.decodeIfPresentOrInitEmpty([TypeNameComponent].self, forKey: .nestedComponents)
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(definedIn, forKey: .definedIn)
        try container.encode(rootType, forKey: .rootComponent)
        try container.encodeIfNotEmpty(nestedTypes, forKey: .nestedComponents)
    }
}

// MARK: - Comparable + Equatable
extension TypeName: Comparable {
    /// String comparison of `name`
    public static func < (lhs: TypeName, rhs: TypeName) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

private struct LegacyTypeName: Decodable {
    private enum CodingKeys: String, CodingKey {
        case definedIn = "defined-in"
        case name
        case nestedTypeNames
        case genericTypeNames
    }

    let definedIn: String?
    let name: String
    let nestedTypeNames: [LegacyTypeName]
    let genericTypeNames: [LegacyTypeName]

    func migrateToTypeName() -> TypeName {
        TypeName(
            definedIn: definedIn,
            rootType: TypeNameComponent(
                name: name,
                generics: genericTypeNames
                    .map { $0.migrateToTypeName() }
            ),
            nestedTypes: nestedTypeNames
                .map { type in
                    TypeNameComponent(
                        name: type.name,
                        generics: type.genericTypeNames
                            .map { $0.migrateToTypeName() }
                    )
                }
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try definedIn = container.decodeIfPresent(String.self, forKey: .definedIn)
        try name = container.decode(String.self, forKey: .name)
        try nestedTypeNames = container.decodeIfPresentOrInitEmpty([LegacyTypeName].self, forKey: .nestedTypeNames)
        try genericTypeNames = container.decodeIfPresentOrInitEmpty([LegacyTypeName].self, forKey: .genericTypeNames)
    }
}
