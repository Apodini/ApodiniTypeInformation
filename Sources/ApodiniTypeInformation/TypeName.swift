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
    /// Name of the type `String(describing:)`.
    /// Additionally holds generic type names: e.g. `Container<Int, String>` as `ContainerOfIntAndString`
    public let name: String
    /// Name of the module where the type has been defined, where components are joined by `/`
    public let definedIn: String
    /// String array of the generic type names: e.g. `Container<Int, String>` as `[Int, String]`
    public let genericTypeNames: [String]
    
    /// DefinedIn and the name of the type
    public var absoluteName: String {
        definedIn + "/" + name
    }

    /// Initializes `self` out of `Any.Type`
    public init(_ type: Any.Type) {
        var components = String(reflecting: type).split(character: ".")
        var name = String(describing: type)
        
        if components.last == name {
            components = components.dropLast()
        }
        
        while components.count > 1, let last = components.last {
            name = "\(last)\(name)"
            components = components.dropLast()
        }
        
        self.init(name: name, definedIn: components.joined(separator: "/"))
    }

    /// Initializes `self` with `name` and `definedIn`.
    /// - Note: `genericTypeNames` are initialized from `name`, if it is a string of e.g. the form: `Container<Int, String>` -> `[Int, String]`
    public init(name: String, definedIn: String) {
        self.name = name
            .replacingOccurrences(of: "<", with: "Of")
            .replacingOccurrences(of: ", ", with: "And")
            .replacingOccurrences(of: ">", with: "")

        self.definedIn = definedIn
        if let openingBrackedIndex = name.firstIndex(of: "<"), let closingBracketIndex = name.firstIndex(of: ">") {
            genericTypeNames = String(name[name.index(after: openingBrackedIndex) ..< closingBracketIndex]).split(string: ", ")
        } else {
            genericTypeNames = []
        }
    }
    
    /// Initializes self with `name`
    public init(name: String) {
        self.init(name: name, definedIn: name)
    }
}

// MARK: - Codable
extension TypeName: Codable {
    // MARK: Coding Keys
    private enum CodingKeys: String, CodingKey {
        case name, definedIn = "defined-in", genericTypeNames
    }

    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        definedIn = try container.decode(String.self, forKey: .definedIn)
        genericTypeNames = try container.decodeIfPresentOrInitEmpty([String].self, forKey: .genericTypeNames)
    }

    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(definedIn, forKey: .definedIn)
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
