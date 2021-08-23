//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Decodable {
    /// Initializes self from data
    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }

    /// Initializes self from string
    static func decode(from string: String) throws -> Self {
        try decode(from: string.data())
    }
}

// MARK: - KeyedDecodingContainerProtocol
extension KeyedDecodingContainerProtocol {
    /// Decodes a value of the given collection type for the given key, if present, otherwise initializes it as empty collection
    func decodeIfPresentOrInitEmpty<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T where T: Collection, T.Element: Decodable {
        // swiftlint:disable:next force_cast
        (try decodeIfPresent(T.self, forKey: key)) ?? [] as! T
    }
}
