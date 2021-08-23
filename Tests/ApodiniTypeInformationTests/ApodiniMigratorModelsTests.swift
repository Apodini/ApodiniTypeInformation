//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import ApodiniTypeInformation

final class ApodiniMigratorModelsTests: TypeInformationTestCase {
    func testFluentProperties() throws {
        try FluentPropertyType.allCases.forEach { property in
            let json = try property.toJSON()
            let instance = XCTAssertNoThrowWithResult(try FluentPropertyType.fromJSON(json))
            XCTAssertEqual(property.description, property.debugDescription)
            XCTAssert(instance == property)
        }

        XCTAssertThrows(try FluentPropertyType.fromJSON("@FluentID".toJSON()))
        
        let childrenMangledName = MangledName("ChildrenProperty")
        if case let .fluentPropertyType(type) = childrenMangledName {
            XCTAssert(type == .childrenProperty)
            XCTAssert(type.isGetOnly)
        } else {
            XCTFail("Mangled name did not correspond to a fluent property")
        }
    }
    
    func testRuntime() throws {
        typealias User = TestTypes.User
        let info = try info(of: User.self)
        
        let name = try RuntimeProperty(XCTAssertNoThrowWithResult(try info.property(named: "name")))
        XCTAssert(name.ownerType == User.self)
        XCTAssert(name.genericTypes.count == 1)
        XCTAssert(!name.isIDProperty)
        XCTAssert(!name.isFluentProperty)
        
        XCTAssert(info.cardinality == .exactlyOne(User.self))
        
        XCTAssert(type(User.self, isAnyOf: .struct))
        XCTAssert(!type(type(of: ()), isAnyOf: .struct, .enum))
        
        let url = try XCTUnwrap(try createInstance(of: URL.self) as? URL)
        XCTAssert(url == .default)
        
        enum TestError: Error {
            case test
            case opaque
        }
        
        XCTAssert(!knownRuntimeError(TestError.test))
        
        XCTAssertThrows(try instance(User.self)) // can't create an enum instance
        XCTAssertNoThrow(try instance(TestTypes.Shop.self))
    }
    
    func testNull() throws {
        let null = Null()
        let data = XCTAssertNoThrowWithResult(try JSONEncoder().encode(null))
        XCTAssertNoThrow(try JSONDecoder().decode(Null.self, from: data))
        XCTAssertThrows(try JSONDecoder().decode(Null.self, from: .init()))
    }
}
