//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable missing_docs

import MetadataSystem


@resultBuilder
public enum RestrictedMetadataBlockBuilder<Block: RestrictedMetadataBlock> {}


// MARK: Restricted Content Metadata Block
public extension RestrictedMetadataBlockBuilder where Block: ContentMetadataBlock, Block.RestrictedContent: AnyContentMetadata {
    static func buildExpression(_ expression: Block.RestrictedContent) -> AnyContentMetadata {
        expression
    }

    static func buildExpression(_ expression: Block) -> AnyContentMetadata {
        expression
    }

    static func buildOptional(_ component: AnyContentMetadata?) -> AnyContentMetadata {
        component ?? EmptyContentMetadata()
    }

    static func buildEither(first: AnyContentMetadata) -> AnyContentMetadata {
        first
    }

    static func buildEither(second: AnyContentMetadata) -> AnyContentMetadata {
        second
    }

    static func buildArray(_ components: [AnyContentMetadata]) -> AnyContentMetadata {
        AnyContentMetadataArray(components)
    }

    static func buildBlock(_ components: AnyContentMetadata...) -> AnyContentMetadata {
        AnyContentMetadataArray(components)
    }
}
