//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents a case of an enumeration
public struct EnumCase: TypeInformationElement {
    /// Name of the case
    public let name: String
    /// Raw value of the case
    public let rawValue: String
    /// Any `Context` information associated with the enum case.
    public let context: Context
    
    /// Initializes self out of a `name`
    ///  - Note: `rawValue` is set equal to `name`
    public init(_ name: String, context: Context = Context()) {
        self.name = name
        self.rawValue = name
        self.context = context
    }
    
    /// Initializes a new instance
    public init(_ name: String, rawValue: String, context: Context = Context()) {
        self.name = name
        self.rawValue = rawValue
        self.context = context
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(rawValue)
    }

    public static func == (lhs: EnumCase, rhs: EnumCase) -> Bool {
        lhs.name == rhs.name
            && lhs.rawValue == rhs.rawValue
    }
}

extension EnumCase: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case rawValue
        case context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        rawValue = try container.decode(String.self, forKey: .rawValue)
        context = try container.decodeIfPresent(Context.self, forKey: .context) ?? Context()
    }
}
