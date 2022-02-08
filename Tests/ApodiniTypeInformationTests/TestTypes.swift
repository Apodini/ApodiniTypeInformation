//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

enum TestTypes {}

extension TestTypes {
    struct Student: Codable, Equatable {
        let id: UUID
        let name: String
        let friends: [String]
        let age: Int
        let grades: [Double: String]
        let birthday: Date
        let url: URL?
        var shop: Shop
        let car: Car

        static func == (lhs: TestTypes.Student, rhs: TestTypes.Student) -> Bool {
            //lhs.id == rhs.id
            lhs.name == rhs.name
                && lhs.friends == rhs.friends
                && lhs.age == rhs.age
                && lhs.grades == rhs.grades
                && lhs.birthday == rhs.birthday
                && lhs.url == rhs.url
                && lhs.shop == rhs.shop
                && lhs.car == rhs.car
        }
    }
    
    enum Direction: String, Codable, Hashable {
        case left
        case right
        
        struct SomeInnerType {}
    }

    enum EnumWithAssociatedValues: RawRepresentable, Codable, Hashable {
        case one
        case two
        case three(String)

        init(rawValue: String) {
            switch rawValue {
            case "one":
                self = .one
            case "two":
                self = .two
            default:
                self = .three(rawValue)
            }
        }

        var rawValue: String {
            switch self {
            case .one:
                return "one"
            case .two:
                return "two"
            case let .three(value):
                return value
            }
        }
    }
    
    struct Car: Codable, Equatable {
        let plateNumber: Int
        let name: String

        static func == (lhs: Car, rhs: Car) -> Bool {
            lhs.plateNumber == rhs.plateNumber && lhs.name == rhs.name
        }
    }
    
    struct SomeStudent: Codable {
        let id: UUID
        let exams: [Date]
    }
    
    struct Shop: Codable, Equatable {
        let id: UUID
        let licence: UInt?
        let url: URL
        var directions: [UUID: Int]
        let car: Car

        static func == (lhs: TestTypes.Shop, rhs: TestTypes.Shop) -> Bool {
            // lhs.id == rhs.id
            lhs.licence == rhs.licence
                && lhs.url == rhs.url
                && lhs.directions == rhs.directions
                && lhs.car == rhs.car
        }
    }
    
    struct SomeStruct: Codable {
        let someDictionary: [URL: Shop]
    }
    
    struct User: Codable {
        let student: [Int: SomeStudent??]
        let birthday: [Date]
        let url: URL
        let scores: [Set<Int>]
        let name: String?
        // swiftlint:disable:next discouraged_optional_collection
        let nestedDirections: Set<[[[[[Direction]?]?]?]]> // testing recursive storing and reconstructing in `TypesStore`
        let shops: [Shop]
        let cars: [String: Car]
        let otherCars: [Car]
    }
    
    struct Generic<V1, V2> {
        let value1: V1
        let value2: V2
    }
}
