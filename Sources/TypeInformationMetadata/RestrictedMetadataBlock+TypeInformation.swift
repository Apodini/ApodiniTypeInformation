//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

/// The `RestrictedContentMetadataBlock` protocol represents `RestrictedMetadataBlock`s which can only contain
/// `AnyContentMetadata` and itself can only be placed in `AnyContentMetadata` Declaration Blocks.
/// Use the generic type `RestrictedContent` to define which `AnyContentMetadata` is allowed in the Block.
///
/// Given a `Example` Metadata (already part of the `ContentMetadataNamespace`), a `RestrictedContentMetadataBlock`
/// can be added to the Namespace like the following:
/// ```swift
/// extension ContentMetadataNamespace {
///     public typealias Examples = RestrictedContentMetadataBlock<Example>
/// }
/// ```
public struct RestrictedContentMetadataBlock<RestrictedContent: AnyContentMetadata>: ContentMetadataBlock, RestrictedMetadataBlock {
    public typealias RestrictedContent = RestrictedContent

    public var metadata: AnyContentMetadata

    public init(@RestrictedMetadataBlockBuilder<Self> metadata: () -> AnyContentMetadata) {
        self.metadata = metadata()
    }
}
