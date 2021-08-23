//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
/// A protocol for types that implement by default their type information representation
public protocol TypeInformationPrimitiveConstructor {
    /// Returns the default type information
    static func construct() -> TypeInformation
}
