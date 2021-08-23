//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A protocol that requires conformance to `Codable` and `Hashable` (also `Equatable`),
/// that any api endpoints of the `ApodiniTypeInformation` conform to.
public protocol TypeInformationElement: Codable, Hashable {}
