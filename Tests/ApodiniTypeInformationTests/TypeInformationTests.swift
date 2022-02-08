//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import ApodiniTypeInformation
import Runtime

final class TypeInformationTests: TypeInformationTestCase {
    func testUserTypeInformation() throws {
        let user = XCTAssertNoThrowWithResult(try TypeInformation.of(TestTypes.User.self, with: RuntimeBuilder.self))
        
        XCTAssert(user.isObject)
        XCTAssert(user.rootType.description == "Object")
        XCTAssert(user.objectProperties.count == 9)
        XCTAssert(user.property("birthday")?.type == .repeated(element: .scalar(.date)))
        XCTAssert(user.property("name")?.necessity == .optional)
        XCTAssert(user.property("name")?.type.unwrapped.isScalar == true)
        XCTAssert(user.property("shops")?.type.isRepeated == true)
        XCTAssert(user.property("cars")?.type.isDictionary == true)
        XCTAssert(user.property("cars")?.type.dictionaryKey == .string)
        XCTAssert(user.property("cars")?.type.dictionaryValue?.isObject == true)
        XCTAssert(user.dictionaryKey == nil)
        XCTAssert(user.dictionaryValue == nil)
        XCTAssertEqual(user.typeName.buildName(), "TestTypesUser")
        XCTAssertEqual(user.property("otherCars")?.type.nestedTypeString, "TestTypesCar")
        XCTAssert(user.property("url")?.type.objectProperties.isEmpty == true)
        XCTAssert(user.enumCases.isEmpty)
        XCTAssert(user.rawValueType == nil)
        XCTAssert(!user.scalars().isEmpty)
        XCTAssert(!user.repeatedTypes().isEmpty)
        XCTAssert(!user.dictionaries().isEmpty)
        XCTAssert(!user.enums().isEmpty)
        XCTAssert(!user.optionals().isEmpty)
        XCTAssert(!user.objectTypes().isEmpty)
        
        XCTAssertEqual(user.referencedProperties().property("birthday"), user.referencedProperties().property("birthday"))
        
        let allTypes = user.allTypes()
        XCTAssert(allTypes.contains(.scalar(.url)))
        XCTAssert(allTypes.contains(.scalar(.string)))
        XCTAssert(allTypes.contains(.scalar(.uuid)))
        XCTAssert(allTypes.contains(.scalar(.date)))
        XCTAssert(allTypes.contains(.scalar(.int)))
        XCTAssert(allTypes.contains(.scalar(.uint)))
        XCTAssert(!user.contains(.scalar(.bool)))
        XCTAssert(!user.contains(nil))
        
        let direction = try TypeInformation(type: TestTypes.Direction.self)
        XCTAssert(direction.isEnum)
        XCTAssert(user.contains(direction))
        XCTAssert(direction.isContained(in: user))
        XCTAssertEqual(direction.rawValueType, .scalar(.string))

        XCTAssert(!user.comparingRootType(with: direction))

        let data = try user.toJSON()
        let userFromData = try TypeInformation.fromJSON(data)
        XCTAssertEqual(user, userFromData)
        
        let userReference = user.asReference()
        let directionReference = direction.asReference()
        XCTAssert(userReference.isReference)
        XCTAssert(userReference.comparingRootType(with: directionReference))
        XCTAssertNotEqual(userReference, directionReference)
    }
    
    func testPrimitiveTypes() throws {
        let int = try TypeInformation.of(Int.self, with: RuntimeBuilder.self)
        let arrayInt = try TypeInformation.of([Int].self, with: RuntimeBuilder.self)
        let bool = try TypeInformation(value: false)
        
        XCTAssertEqual(int, .scalar(.int))
        XCTAssertEqual(arrayInt, .repeated(element: int))
        XCTAssertEqual(bool, .scalar(.bool))

        let nonValidScalar = try TypeInformation.scalar(.bool).toJSON().string().replacingOccurrences(of: "Bool", with: "")
        XCTAssertThrows(try TypeInformation.fromJSON(nonValidScalar.data()))
        
        let null = try XCTUnwrap(PrimitiveType(Null.self))
        XCTAssert(null.debugDescription == "\(null.swiftType)")
        XCTAssert(null.scalarType == .null)
        
        let primitiveTypes: [Any.Type] = [
            Null.self,
            Bool.self,
            Int.self,
            Int8.self,
            Int16.self,
            Int32.self,
            Int64.self,
            UInt.self,
            UInt8.self,
            UInt16.self,
            UInt32.self,
            UInt64.self,
            String.self,
            Double.self,
            Float.self,
            URL.self,
            UUID.self,
            Date.self,
            Data.self
        ]
        
        try primitiveTypes.forEach {
            let type = try XCTUnwrap(PrimitiveType($0))
            _ = type.swiftType.init(.default)
            XCTAssertNoThrow(try TypeInformation(type: $0))
        }
        
        XCTAssert([Int: String].default == [0: ""])
        XCTAssertEqual(String?.default, "")
        XCTAssert(Set<String>.default == [""])
        XCTAssert([URL].default == [.default])
    }
    
    func testTypeInformationConvenience() throws {
        let car = try TypeInformation(type: TestTypes.Car.self)
        let shop = try TypeInformation(type: TestTypes.Shop.self)
        let shopRepeated: TypeInformation = .repeated(element: shop)
        let direction = try TypeInformation(type: TestTypes.Direction.self)
        let someStruct: TypeInformation = .dictionary(key: .string, value: try TypeInformation(type: TestTypes.SomeStruct.self))
        
        XCTAssert(shopRepeated.referencedProperties().isRepeated)
        XCTAssert(direction.referencedProperties() == direction)
        XCTAssert(someStruct.asOptional.referencedProperties().isOptional)
        XCTAssert(shopRepeated.objectType == shop)
        XCTAssert(car.isContained(in: shop))
    }
    
    func testThrowing() throws {
        XCTAssertThrows(try TypeInformation(type: [TestTypes.Direction: Int].self))
        enum TestEnum {
            case int(Int)
            case string(String)
        }
        XCTAssertThrows(try TypeInformation(type: TestEnum.self))
    }
    
    func testTypeStore() throws {
        let typeInformation = try TypeInformation(type: [Int: [UUID: TestTypes.User?????]].self)
        
        var store = TypesStore()
        
        let reference = store.store(typeInformation) // storing and retrieving a reference
        XCTAssert(reference.reference != nil)

        let result = store.construct(from: reference) // reconstructing type from the reference

        XCTAssertEqual(result, typeInformation)
        // TypesStore only stores complex types and enums
        XCTAssertEqual(store.store(.scalar(.string)), .scalar(.string))
    }

    func testTypeStoreCodable() throws {
        let encoded = """
                      {
                        "CategoryStatus" : {
                          "enum" : {
                            "rawValueType" : {
                              "scalar" : "String"
                            },
                            "cases" : [
                              {
                                "name" : "available",
                                "rawValue" : "available"
                              },
                              {
                                "name" : "unavailable",
                                "rawValue" : "unavailable"
                              }
                            ],
                            "typeName" : {
                              "defined-in" : "QONECTIQV1",
                              "rootComponent" : {
                                "name" : "CategoryStatus"
                              }
                            }
                          }
                        }
                      }
                      """

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let decoder = JSONDecoder()

        // swiftlint:disable:next force_unwrapping
        let typeStore = try decoder.decode(TypesStore.self, from: encoded.data(using: .utf8)!)
        let reencoded = try encoder.encode(typeStore).string()
        // swiftlint:disable:next force_unwrapping
        let typeStore0 = try decoder.decode(TypesStore.self, from: reencoded.data(using: .utf8)!)
        XCTAssertEqual(typeStore, typeStore0)

        for (key, type) in typeStore {
            XCTAssertEqual(key, ReferenceKey("CategoryStatus"))
            XCTAssertEqual(type.isEnum, true)
            XCTAssertEqual(type.enumCases.count, 2)
            XCTAssertEqual(type.rawValueType, .scalar(.string))
        }
    }

    func testEnumWithAssociatedValues() throws {
        let typeInfo = try TypeInformation(type: TestTypes.EnumWithAssociatedValues.self, enumAssociatedValues: .ignore)

        XCTAssert(typeInfo.isEnum)
        XCTAssertEqual(typeInfo.rawValueType, .scalar(.string))
        XCTAssertEqual(typeInfo.enumCases.count, 2)
    }
}
