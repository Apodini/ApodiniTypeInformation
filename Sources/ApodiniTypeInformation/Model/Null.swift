//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A similar to `NSNull` type that encodes `nil`
public struct Null: Hashable, Codable {
    /// Initializer for `self`
    public init() {}
    
    // MARK: - Decodable
    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        guard singleValueContainer.decodeNil() else {
            throw DecodingError.dataCorruptedError(in: singleValueContainer, debugDescription: "Expected to decode `null`")
        }
    }
    
    // MARK: - Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
