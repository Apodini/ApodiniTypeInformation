//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A result builder protocol out of an input
public protocol Builder {
    /// Input
    associatedtype Input
    
    /// Result of `build() throws`
    associatedtype Result
    
    /// Input of the builder
    var input: Input { get }
    
    /// Initializer of the instance
    init(_ input: Input)
    
    /// Builds and returns the result
    func build() throws -> Result
}
