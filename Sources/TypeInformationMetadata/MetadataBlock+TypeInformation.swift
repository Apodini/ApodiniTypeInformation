//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

public protocol AnyContentMetadataBlock: AnyMetadataBlock, AnyContentMetadata, ContentMetadataNamespace {}

public protocol AnyStaticContentMetadataBlock: AnyContentMetadataBlock {
    static var typeErasedContent: AnyMetadata { get }
}

public extension AnyStaticContentMetadataBlock {
    /// Type erased metadata content of this block.
    var typeErasedContent: AnyMetadata {
        Self.typeErasedContent
    }

    /// This method accepts the `MetadataParser` in order to parse the Metadata tree.
    /// The implementation should either forward the visitor to its content (e.g. in the case of a `AnyMetadataBlock`)
    /// or add the parsed Metadata to the visitor.
    ///
    /// - Parameter visitor: The `MetadataParser` parsing the Metadata tree.
    static func collectMetadata(_ visitor: MetadataParser) {
        typeErasedContent.collectMetadata(visitor)
    }
}


extension ContentMetadataNamespace {
    /// Name definition for the `StandardContentMetadataBlock`
    public typealias Block = StandardContentMetadataBlock
}

/// The `ContentMetadataBlock` protocol represents `AnyMetadataBlock`s which can only contain
/// `AnyContentMetadata` and itself can only be placed in `AnyContentMetadata` Declaration Blocks.
///
/// See `StandardContentMetadataBlock` for a general purpose `ContentMetadataBlock` available by default.
///
/// By conforming to `ContentMetadataBlock` you can create reusable Metadata like the following:
/// ```swift
/// struct DefaultDescriptionMetadata: ContentMetadataBlock {
///     var metadata: Metadata {
///         Description("Example Description")
///         // ...
///     }
/// }
///
/// struct ExampleContent: Content {
///     // ...
///     static var metadata: Metadata {
///         DefaultDescriptionMetadata()
///     }
/// }
/// ```
public protocol ContentMetadataBlock: AnyContentMetadataBlock {
    associatedtype Metadata = AnyContentMetadata

    @ContentMetadataBuilder
    var metadata: Metadata { get }
}

public extension ContentMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    var typeErasedContent: AnyMetadata {
        self.metadata as! AnyMetadata // swiftlint:disable:this force_cast
    }
}

public protocol StaticContentMetadataBlock: AnyStaticContentMetadataBlock {
    associatedtype Metadata = AnyContentMetadata

    @ContentMetadataBuilder
    static var metadata: Metadata { get }
}

public extension StaticContentMetadataBlock {
    /// Returns the type erased metadata content of the ``AnyMetadataBlock``.
    static var typeErasedContent: AnyMetadata {
        Self.metadata as! AnyMetadata // swiftlint:disable:this force_cast
    }
}


/// `StandardContentMetadataBlock` is a `ContentMetadataBlock` available by default.
/// It is available under the `Collect` name in `Content` Metadata Declaration Blocks.
///
/// It may be used in `Content` Metadata Declaration Blocks in the following way:
/// ```swift
/// struct ExampleContent: Content {
///     // ...
///     static var metadata: Metadata {
///         // ...
///         Block {
///             // ...
///         }
///     }
/// }
/// ```
public struct StandardContentMetadataBlock: ContentMetadataBlock {
    public var metadata: AnyContentMetadata

    public init(@ContentMetadataBuilder metadata: () -> AnyContentMetadata) {
        self.metadata = metadata()
    }
}
