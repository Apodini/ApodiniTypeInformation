//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension Array where Element: Equatable {
    /// Returns whether self is equal to other not considering the order of elements
    func equalsIgnoringOrder(to other: Self) -> Bool {
        guard count == other.count else {
            return false
        }

        for element in self where !other.contains(element) {
            return false
        }

        return true
    }
}

extension Sequence {
    /// Returns the first matched element, where the value of the property is equal to other
    func firstMatch<E: Equatable>(on keyPath: KeyPath<Element, E>, with other: E) -> Element? {
        first(where: { $0[keyPath: keyPath] == other })
    }
}


extension Set {
    /// Forms an union with another sequence
    static func += <S: Sequence> (lhs: inout Self, rhs: S) where S.Element == Element {
        lhs.formUnion(rhs)
    }
}

// MARK: - Array + Value
extension Array where Element: TypeInformationElement {
    /// Appends rhs to lhs
    static func + (lhs: Self, rhs: Element) -> Self {
        var mutableLhs = lhs
        mutableLhs.append(rhs)
        return mutableLhs
    }

    /// Appends lhs to rhs
    static func + (lhs: Element, rhs: Self) -> Self {
        rhs + lhs
    }
}
