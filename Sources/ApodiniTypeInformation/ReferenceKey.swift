//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A `ReferenceKey` uniquely identifies a `TypeInformation` inside a ``TypeStore`` instance.
public struct ReferenceKey: RawRepresentable, TypeInformationElement {
    /// Raw value
    public let rawValue: String

    /// Initializes self from a rawValue
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Initializes self from a rawValue
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}

// MARK: - Hashable
extension ReferenceKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: - Equatable
extension ReferenceKey: Equatable {
    public static func == (lhs: ReferenceKey, rhs: ReferenceKey) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

// MARK: - Codable
extension ReferenceKey: Codable {
    /// Creates a new instance by decoding from the given decoder.
    public init(from decoder: Decoder) throws {
        try rawValue = decoder.singleValueContainer().decode(String.self)
    }

    /// Encodes self into the given encoder.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
