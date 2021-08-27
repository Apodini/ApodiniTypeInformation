//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// Represents a case of an enumeration
public struct EnumCase: TypeInformationElement {
    /// Name of the case
    public let name: String
    /// Raw value of the case
    public let rawValue: String
    
    /// Initializes self out of a `name`
    ///  - Note: `rawValue` is set equal to `name`
    public init(_ name: String) {
        self.name = name
        self.rawValue = name
    }
    
    /// Initializes a new instance
    public init(_ name: String, rawValue: String) {
        self.name = name
        self.rawValue = rawValue
    }
}
