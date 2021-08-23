//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A builder protocol where `Result` is `TypeInformation`
public protocol TypeInformationBuilder: Builder where Input == Any.Type, Result == TypeInformation {}

// MARK: - TypeInformation
public extension TypeInformation {
    /// Returns a `TypeInformation` instance built with `builderType`
    static func of<B: TypeInformationBuilder>(_ type: Any.Type, with builderType: B.Type) throws -> TypeInformation {
        try builderType.init(type).build()
    }
}
