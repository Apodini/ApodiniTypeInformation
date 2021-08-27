//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import ApodiniTypeInformation

final class TypeNameParserTests: TypeInformationTestCase {
    func testSimpleType() {
        XCTAssertEqual(
            TypeNameParser("SomeTarget.TestType1.TestType2").parse(),
            [
                .targetName(name: "SomeTarget"),
                .typeName(name: "TestType1"),
                .typeName(name: "TestType2")
            ]
        )
    }

    func testGenericType() {
        XCTAssertEqual(
            TypeNameParser("ApodiniMigratorTests.TestTypes.Generic<ApodiniMigratorTests.Queue, Swift.String>").parse(),
            [
                .targetName(name: "ApodiniMigratorTests"),
                .typeName(name: "TestTypes"),
                .typeName(name: "Generic", generics: [
                    [
                        .targetName(name: "ApodiniMigratorTests"),
                        .typeName(name: "Queue")
                    ],
                    [
                        .targetName(name: "Swift"),
                        .typeName(name: "String")
                    ]
                ])
            ]
        )
    }

    func testMultipleGenerics() {
        XCTAssertEqual(
            // swiftlint:disable:next line_length
            TypeNameParser("TargetName.SomeType<TargetName.Generic<Swift.String, Swift.Int>>.SomeNestedType<TargetName.SomeOtherType, TargetName.Type2>")
                .parse(),
            [
                .targetName(name: "TargetName"),
                .typeName(name: "SomeType", generics: [
                    [
                        .targetName(name: "TargetName"),
                        .typeName(name: "Generic", generics: [
                            [
                                .targetName(name: "Swift"),
                                .typeName(name: "String")
                            ],
                            [
                                .targetName(name: "Swift"),
                                .typeName(name: "Int")
                            ]
                        ])
                    ]
                ]),
                .typeName(name: "SomeNestedType", generics: [
                    [
                        .targetName(name: "TargetName"),
                        .typeName(name: "SomeOtherType")
                    ],
                    [
                        .targetName(name: "TargetName"),
                        .typeName(name: "Type2")
                    ]
                ])
            ]
        )
    }
}
