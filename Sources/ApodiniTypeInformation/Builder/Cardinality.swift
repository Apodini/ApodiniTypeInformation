//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents different cardinalities of type
enum Cardinality {
    /// An exactly one cardinality
    case exactlyOne(Any.Type)
    /// A repeated cardinality
    case repeated(Any.Type)
    /// An optional cardinality
    case optional(Any.Type)
    /// A dictionary
    case dictionary(key: Any.Type, value: Any.Type)
}

// MARK: - Equatable
extension Cardinality: Equatable {
    static func == (lhs: Cardinality, rhs: Cardinality) -> Bool {
        switch (lhs, rhs) {
        case let (.exactlyOne(lhsType), .exactlyOne(rhsType)):
            return lhsType == rhsType
        case let (.repeated(lhsType), .repeated(rhsType)):
            return lhsType == rhsType
        case let (.optional(lhsType), .optional(rhsType)):
            return lhsType == rhsType
        case let (.dictionary(lhsKeyType, lhsValueType), .dictionary(rhsKeyType, rhsValueType)):
            return lhsKeyType == rhsKeyType && lhsValueType == rhsValueType
        default: return false
        }
    }
}
