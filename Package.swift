// swift-tools-version:5.7

//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import PackageDescription


enum RuntimeDependency {
    /// contains experimental enum support
    case enumSupport
    /// The regular upstream package
    case standard
}

func runtimeDependency(selecting dependency: RuntimeDependency) -> Package.Dependency {
    switch dependency {
    case .enumSupport:
        return .package(url: "https://github.com/PSchmiedmayer/Runtime.git", .revision("b810847a466ecd1cf65e7f39e6e715734fdc672c"))
    case .standard:
        return .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.2.4")
    }
}


let package = Package(
    name: "ApodiniTypeInformation",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .library(name: "ApodiniTypeInformation", targets: ["ApodiniTypeInformation"]),
        .library(name: "TypeInformationMetadata", targets: ["TypeInformationMetadata"])
    ],
    dependencies: [
        runtimeDependency(selecting: .standard),
        .package(url: "https://github.com/Apodini/MetadataSystem.git", .upToNextMinor(from: "0.1.7"))
    ],
    targets: [
        .target(
            name: "ApodiniTypeInformation",
            dependencies: [
                .product(name: "Runtime", package: "Runtime"),
                .target(name: "TypeInformationMetadata")
            ]
        ),
        .target(
            name: "TypeInformationMetadata",
            dependencies: [
                .product(name: "MetadataSystem", package: "MetadataSystem")
            ]
        ),
        .testTarget(
            name: "ApodiniTypeInformationTests",
            dependencies: [
                .target(name: "ApodiniTypeInformation")
            ]
        )
    ]
)
