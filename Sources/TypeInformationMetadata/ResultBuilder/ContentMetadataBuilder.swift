//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable missing_docs

@resultBuilder
public enum ContentMetadataBuilder {}

public extension ContentMetadataBuilder {
    static func buildExpression<Metadata: ContentMetadataDefinition>(_ expression: Metadata) -> AnyContentMetadata {
        WrappedContentMetadataDefinition(expression)
    }

    static func buildExpression<Metadata: ContentMetadataBlock>(_ expression: Metadata) -> AnyContentMetadata {
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
