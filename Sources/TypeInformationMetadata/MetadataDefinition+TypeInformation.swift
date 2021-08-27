//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

/// See `MetadataDefinition` for an explanation on what a Metadata Definition is
/// and a recommendation for a naming convention.
///
/// Any Metadata Definition conforming to `ContentMetadataDefinition` can be used in
/// the Metadata Declaration Blocks of a `Content` Type to annotate the `Content` Type with
/// the given Metadata.
///
/// Use the `ContentMetadataNamespace` to define the name used in the Metadata DSL.
public protocol ContentMetadataDefinition: MetadataDefinition, AnyContentMetadata {}
