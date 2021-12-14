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

    // swiftlint:disable:next function_body_length
    func testTypeName() throws {
        let genericTypeName = TypeName(TestTypes.Generic<TestTypes.SomeStruct, Int>.self)

        XCTAssertEqual(genericTypeName.mangledName, "Generic")
        XCTAssertEqual(genericTypeName.nestedTypes.first?.name, "TestTypes")
        XCTAssertEqual(genericTypeName.definedIn, "ApodiniTypeInformationTests")
        XCTAssertEqual(genericTypeName.buildName(), "TestTypesGenericOfTestTypesSomeStructAndInt")
        XCTAssert(genericTypeName.generics.contains(TypeName(Int.self)))

        let string = TypeName(String.self)
        XCTAssertEqual(string.mangledName, "String")
        XCTAssertEqual(string.definedIn, "Swift")
        XCTAssert(string.nestedTypes.isEmpty)
        XCTAssert(string.generics.isEmpty)
        XCTAssertEqual(string.mangledName, string.buildName())

        let nsdata = TypeName(NSData.self)
        #if os(macOS)
        XCTAssertEqual(nsdata.definedIn, nil)
        XCTAssertEqual(nsdata.mangledName, "NSData")
        #else
        XCTAssertEqual(nsdata.definedIn, "Foundation")
        XCTAssertEqual(nsdata.name, "NSData")
        #endif

        let nsString = TypeName(NSString.self)
        #if os(macOS)
        XCTAssertEqual(nsString.definedIn, nil)
        XCTAssertEqual(nsString.mangledName, "NSString")
        #else
        XCTAssertEqual(nsString.definedIn, "Foundation")
        XCTAssertEqual(nsString.name, "NSString")
        #endif

        let nsURL = TypeName(NSURL.self)
        #if os(macOS)
        XCTAssertEqual(nsURL.definedIn, nil)
        XCTAssertEqual(nsURL.mangledName, "NSURL")
        #else
        XCTAssertEqual(nsURL.definedIn, "Foundation")
        XCTAssertEqual(nsURL.name, "NSURL")
        #endif

        let nsStringCompare = TypeName(NSString.CompareOptions.self)
        #if os(macOS)
        XCTAssertEqual(nsStringCompare.definedIn, "__C")
        XCTAssertEqual(nsStringCompare.mangledName, "NSStringCompareOptions")
        #else
        XCTAssertEqual(nsStringCompare.definedIn, "Foundation")
        XCTAssertEqual(nsStringCompare.nestedTypeNames.count, 1)
        XCTAssertEqual(nsStringCompare.nestedTypeNames[0].name, "NSString")
        XCTAssertEqual(nsStringCompare.name, "CompareOptions")
        #endif

        let jsonEncoder = TypeName(JSONEncoder.self)
        XCTAssert(jsonEncoder.mangledName == String(describing: JSONEncoder.self))
        XCTAssert(jsonEncoder.definedIn == "Foundation")
        XCTAssert(jsonEncoder.nestedTypes.isEmpty)
        XCTAssert(jsonEncoder.generics.isEmpty)

        let someDictionary = TypeName(Dictionary<Int, String>.self)
        XCTAssert(someDictionary.mangledName == "Dictionary")
        XCTAssert(someDictionary.definedIn == "Swift")
        XCTAssert(someDictionary.nestedTypes.isEmpty)
        XCTAssert(someDictionary.buildName(genericsStart: "VON", genericsSeparator: "UND") == "DictionaryVONIntUNDString")
        XCTAssert(someDictionary.generics.equalsIgnoringOrder(to: [TypeName(String.self), TypeName(Int.self)]))

        let someOptional = TypeName(UUID?.self)
        XCTAssert(someOptional.mangledName == "Optional")
        XCTAssert(someOptional.nestedTypes.isEmpty)
        XCTAssert(someOptional.generics.contains(TypeName(UUID.self)))

        let someArray = TypeName([Self].self)
        XCTAssert(someArray.mangledName == "Array")
        XCTAssert(someArray.buildName(genericsStart: "PREFIX") == "ArrayPREFIX\(Self.self)")
        XCTAssert(someArray.nestedTypes.isEmpty)
        XCTAssert(someArray.generics.first == TypeName(Self.self))

        let null = TypeName(Null.self)
        XCTAssert(null.mangledName == "Null")
        XCTAssert(null.definedIn == "ApodiniTypeInformation")

        let innerTypeName = TypeName(TestTypes.Direction.SomeInnerType.self)
        XCTAssertEqual(innerTypeName.mangledName, "SomeInnerType")
        XCTAssertEqual(innerTypeName.buildName(), "TestTypesDirectionSomeInnerType")
        XCTAssert(innerTypeName.nestedTypes.equalsIgnoringOrder(to: [TypeNameComponent(name: "TestTypes"), TypeNameComponent(name: "Direction")]))
    }

    func testLegacyTypeNameDecoding() throws {
        // describes ApodiniTypeInformationTests.TestTypes.Generic<ApodiniTypeInformationTests.TestTypes.SomeStruct,Swift.String>.Asdf<Swift.Int>
        let legacyEncodedString = """
                                  {
                                      "genericTypeNames" : [
                                          {
                                              "name" : "Int",
                                              "defined-in" : "Swift"
                                          }
                                      ],
                                      "defined-in" : "ApodiniTypeInformationTests",
                                      "nestedTypeNames" : [
                                          {
                                              "name" : "TestTypes",
                                              "defined-in" : "ApodiniTypeInformationTests"
                                          },
                                          {
                                              "genericTypeNames" : [
                                                  {
                                                      "name" : "SomeStruct",
                                                      "defined-in" : "ApodiniTypeInformationTests",
                                                      "nestedTypeNames" : [
                                                          {
                                                              "name" : "TestTypes",
                                                              "defined-in" : "ApodiniTypeInformationTests"
                                                          }
                                                      ]
                                                  },
                                                  {
                                                      "name" : "String",
                                                      "defined-in" : "Swift"
                                                  }
                                              ],
                                              "defined-in" : "ApodiniTypeInformationTests",
                                              "nestedTypeNames" : [
                                                  {
                                                      "name" : "TestTypes",
                                                      "defined-in" : "ApodiniTypeInformationTests"
                                                  }
                                              ],
                                              "name" : "Generic"
                                          }
                                      ],
                                      "name" : "Asdf"
                                  }
                                  """

        let typeName = try JSONDecoder().decode(TypeName.self, from: legacyEncodedString.data(using: .utf8)!)

        XCTAssertEqual(
            typeName,
            TypeName(
                definedIn: "ApodiniTypeInformationTests",
                rootType: TypeNameComponent(name: "Asdf", generics: [TypeName(definedIn: "Swift", rootType: .init(name: "Int"))]),
                nestedTypes: [
                    TypeNameComponent(name: "TestTypes"),
                    TypeNameComponent(name: "Generic", generics: [
                        TypeName(definedIn: "ApodiniTypeInformationTests", rootType: .init(name: "SomeStruct"), nestedTypes: [
                            TypeNameComponent(name: "TestTypes")
                        ]),
                        TypeName(definedIn: "Swift", rootType: .init(name: "String"))
                    ])
                ]
            )
        )
    }
}
