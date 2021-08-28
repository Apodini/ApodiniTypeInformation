//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// The `ContentMetadataNamespace` can be used to define an appropriate
/// Name for your `ContentMetadataDefinition` in a way that avoids Name collisions
/// on the global Scope.
///
/// Given the example of `DescriptionContentMetadata` you can define a Name like the following:
/// ```swift
/// extension ContentMetadataNamespace {
///     public typealias Description = DescriptionContentMetadata
/// }
/// ```
///
/// Refer to `TypedContentMetadataNamespace` if you need access to the generic `Content`
/// Type where the Metadata is used on.
public protocol ContentMetadataNamespace {}
