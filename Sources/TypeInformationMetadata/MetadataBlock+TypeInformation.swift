import MetadataSystem

public protocol AnyContentMetadataBlock: AnyMetadataBlock, AnyContentMetadata, ContentMetadataNamespace {}

public protocol AnyStaticContentMetadataBlock: AnyContentMetadataBlock {
    static var typeErasedContent: AnyMetadata { get }
}

public extension AnyStaticContentMetadataBlock {
    var typeErasedContent: AnyMetadata {
        Self.typeErasedContent
    }

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
        self.metadata as! AnyMetadata
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
        Self.metadata as! AnyMetadata
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
