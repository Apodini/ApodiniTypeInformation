//
// Created by Andreas Bauer on 27.08.21.
//

import XCTest
import TypeInformationMetadata
@testable import ApodiniTypeInformation

private struct DescriptionContextKey: OptionalContextKey {
    typealias Value = String
}

private extension ContentMetadataNamespace {
    typealias Description = DescriptionMetadata
}

private struct DescriptionMetadata: ContentMetadataDefinition {
    typealias Key = DescriptionContextKey

    let value: String

    init(_ description: String) {
        self.value = description
    }
}

final class TypeInformationMetadataTests: TypeInformationTestCase {
    struct SomeType: StaticContentMetadataBlock {
        var id: String

        var name: String

        var subType: SubType

        static var metadata: Metadata {
            Description("This is a Description!")
        }
    }

    struct SubType: StaticContentMetadataBlock {
        var someValue: String

        static var metadata: Metadata {
            Description("This is a sub Description!")
        }
    }

    func testContentMetadata() throws {
        let info = try TypeInformation.of(SomeType.self, with: RuntimeBuilder.self)

        guard case let .object(name, properties, context) = info else {
            XCTFail("Expected an .object received '\(info)'")
            return
        }

        XCTAssertEqual(name.name, "TypeInformationMetadataTestsSomeType")
        XCTAssertEqual(name.definedIn, "ApodiniTypeInformationTests")
        XCTAssertEqual(name.genericTypeNames, [])

        XCTAssertEqual(context.get(valueFor: DescriptionMetadata.self), "This is a Description!")

        for property in properties {
            switch property.name {
            case "id":
                XCTAssertEqual(property.type, .scalar(.string))
            case "name":
                XCTAssertEqual(property.type, .scalar(.string))
            case "subType":
                guard case let .object(name, properties, context) = property.type else {
                    XCTFail("Unexpected property type \(property)")
                    return
                }

                XCTAssertEqual(name.name, "TypeInformationMetadataTestsSubType")
                XCTAssertEqual(name.definedIn, "ApodiniTypeInformationTests")
                XCTAssertEqual(name.genericTypeNames, [])

                XCTAssertEqual(context.get(valueFor: DescriptionMetadata.self), "This is a sub Description!")

                XCTAssertEqual(properties.count, 1)
                XCTAssertEqual(properties[0].type, .scalar(.string))
            default:
                XCTFail("Encountered unexpected property type: \(property)")
            }
        }
    }
}
