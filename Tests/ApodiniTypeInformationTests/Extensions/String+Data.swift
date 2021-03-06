//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest

extension String {
    func data() throws -> Data {
        try XCTUnwrap(self.data(using: .utf8))
    }
}

extension Data {
    func string() throws -> String {
        try XCTUnwrap(String(data: self, encoding: .utf8))
    }
}
