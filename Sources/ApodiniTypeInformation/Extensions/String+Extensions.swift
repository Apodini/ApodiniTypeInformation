//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

extension String {
    /// Return the string with an uppercased first character
    var upperFirst: String {
        if let first = first {
            return first.uppercased() + dropFirst()
        }
        return self
    }

    /// Return the string with a lowercased first character
    var lowerFirst: String {
        if let first = first {
            return first.lowercased() + dropFirst()
        }
        return self
    }

    /// Splits the string by a character and returns the result as a String array
    func split(character: Character) -> [String] {
        split(separator: character).map { String($0) }
    }

    /// Splits `self` by the passed string
    /// - Parameters:
    ///      - string: separator
    ///      - ignoreEmptyComponents: flag whether empty components should be ignored, `false` by default
    /// - Returns: the array of string components
    func split(string: String, ignoreEmptyComponents: Bool = false) -> [String] {
        components(separatedBy: string).filter { ignoreEmptyComponents ? !$0.isEmpty : true }
    }

    func without(_ string: String) -> String {
        with("", insteadOf: string)
    }

    /// Replaces occurrences of `target` with `replacement`
    func with(_ replacement: String, insteadOf target: String) -> String {
        replacingOccurrences(of: target, with: replacement)
    }

    /// Returns encoded data of `self`
    func data(_ encoding: Encoding = .utf8) -> Data {
        data(using: encoding) ?? .init()
    }
}
