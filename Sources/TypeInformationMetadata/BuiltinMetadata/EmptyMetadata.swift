//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

extension ContentMetadataNamespace {
    /// Name definition for the `EmptyContentMetadata`
    public typealias Empty = EmptyContentMetadata
}

/// `EmptyContentMetadata` is a `AnyContentMetadata` which in fact doesn't hold any Metadata.
/// The Metadata is available under the `ContentMetadataNamespace.Empty` name and can be used like the following:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     var metadata: Metadata {
///         Empty()
///     }
/// }
/// ```
public struct EmptyContentMetadata: EmptyMetadata, ContentMetadataDefinition {
    public init() {}
}
