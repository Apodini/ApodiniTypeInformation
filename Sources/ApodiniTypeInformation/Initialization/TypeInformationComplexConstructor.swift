//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

protocol TypeInformationComplexConstructor {
    static func construct<T: TypeInformationBuilder>(with builderType: T.Type) throws -> TypeInformation
}

extension Optional: TypeInformationComplexConstructor {
    static func construct<T: TypeInformationBuilder>(with builderType: T.Type) throws -> TypeInformation {
        .optional(wrappedValue: try .of(Wrapped.self, with: T.self))
    }
}

extension Array: TypeInformationComplexConstructor {
    static func construct<T: TypeInformationBuilder>(with builderType: T.Type) throws -> TypeInformation {
        .repeated(element: try .of(Element.self, with: T.self))
    }
}

extension Set: TypeInformationComplexConstructor {
    static func construct<T: TypeInformationBuilder>(with builderType: T.Type) throws -> TypeInformation {
        .repeated(element: try .of(Element.self, with: T.self))
    }
}

extension Dictionary: TypeInformationComplexConstructor {
    static func construct<T: TypeInformationBuilder>(with builderType: T.Type) throws -> TypeInformation {
        guard let primitiveKey = PrimitiveType(Key.self) else {
            throw TypeInformation.TypeInformationError.notSupportedDictionaryKeyType
        }
        return .dictionary(key: primitiveKey, value: try .of(Value.self, with: T.self))
    }
}
