//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Encodable {
    func toJSON(outputFormatting: JSONEncoder.OutputFormatting? = nil) throws -> Data {
        let encoder = JSONEncoder()
        if let outputFormatting = outputFormatting {
            encoder.outputFormatting = outputFormatting
        }
        return try encoder.encode(self)
    }
}

extension Decodable {
    static func fromJSON(_ data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}
