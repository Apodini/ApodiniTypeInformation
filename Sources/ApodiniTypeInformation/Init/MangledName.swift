//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

enum MangledName: Equatable {
    case dictionary
    case repeated
    case optional
    case fluentPropertyType(FluentPropertyType)
    case other(String)

    init(_ mangledName: String) {
        switch mangledName {
        case "Optional": self = .optional
        case "Dictionary": self = .dictionary
        case "Array", "Set": self = .repeated
        case let other:
            if let fluentProperty = FluentPropertyType(rawValue: other.lowerFirst) {
                self = .fluentPropertyType(fluentProperty)
            } else {
                self = .other(other)
            }
        }
    }
}
