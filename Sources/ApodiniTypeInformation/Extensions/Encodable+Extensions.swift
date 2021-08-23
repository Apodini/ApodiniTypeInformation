//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - Encodable extensions
extension Encodable {
    /// JSON String of this encodable
    /// - Parameters:
    ///     - outputFormatting: Output formatting of the `JSONEncoder`
    func json(outputFormatting: JSONEncoder.OutputFormatting = [.withoutEscapingSlashes, .prettyPrinted]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting

        do {
            return String(decoding: try encoder.encode(self), as: UTF8.self)
        } catch {
            return "JSON FAILED: \(error)"
        }
    }
}

// MARK: - KeyedEncodingContainerProtocol
extension KeyedEncodingContainerProtocol {
    /// Only encodes the value if the collection is not empty
    mutating func encodeIfNotEmpty<T: Encodable>(_ value: T, forKey key: Key) throws where T: Collection, T.Element: Encodable {
        if !value.isEmpty {
            try encode(value, forKey: key)
        }
    }
}
