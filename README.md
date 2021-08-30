<!--

This source file is part of the Apodini open source project

SPDX-FileCopyrightText: 2021 Paul Schmiedmayer and the project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>

SPDX-License-Identifier: MIT

## How to use this repository
### Template

When creating a new repository, make sure to select this repository as a repository template.

### Customize the repository

Enter your repository-specific configuration
- Replace the "Package.swift", "Sources" and "Tests" folder with your Swift Package
- Enter your project name instead of "ApodiniTemplate" in .jazzy.yml
- Enter the correct test bundle name in the build-and-test.yml file under the "Convert coverage report" step. Most of the time, the name is the name of the project + "PackageTests".
- Update the DocC documentation to reflect the name of the new Swift package and adapt the docs and build and test GitHub Actions where the documentation is generated to the updated names to be sure the DocC generation works as expected 
- Update the README with your information and replace the links to the license with the new repository.
- Update the status badges to point to the GitHub actions of your repository
- If you create a new repository in the Apodini organization, you do not need to add a personal access token named "ACCESS_TOKEN". If you create the repo outside the Apodini organization, you need to create such a token with write access to the repo for all GitHub Actions to work. You will need to give the `ApodiniBot` user write access to the repository.

### ⬆️ Remove everything up to here ⬆️

-->

# ApodiniTypeInformation

[![REUSE Compliance Check](https://github.com/Apodini/ApodiniTypeInformation/actions/workflows/reuseaction.yml/badge.svg)](https://github.com/Apodini/ApodiniTypeInformation/actions/workflows/reuseaction.yml)
[![Build and Test](https://github.com/Apodini/ApodiniTypeInformation/actions/workflows/build-and-test.yml/badge.svg)](https://github.com/Apodini/ApodiniTypeInformation/actions/workflows/build-and-test.yml)
[![codecov](https://codecov.io/gh/Apodini/ApodiniTypeInformation/branch/develop/graph/badge.svg?token=5MMKMPO5NR)](https://codecov.io/gh/Apodini/ApodiniTypeInformation)

This package contains the implementation of a recurisive enum-based `TypeInformation`:
```swift
public enum TypeInformation {
    /// A scalar type
    case scalar(PrimitiveType)
    /// A repeated type (set or array), with `TypeInformation` elements
    indirect case repeated(element: TypeInformation)
    /// A dictionary with primitive keys and `TypeInformation` values
    indirect case dictionary(key: PrimitiveType, value: TypeInformation)
    /// An optional type with `TypeInformation` wrapped values
    indirect case optional(wrappedValue: TypeInformation)
    /// An enum type with `String` cases.
    indirect case `enum`(name: TypeName, rawValueType: TypeInformation?, cases: [EnumCase], context: Context = .init())
    /// An object type with properties containing a `TypeInformation` and a name.
    case object(name: TypeName, properties: [TypeProperty], context: Context = .init())
    /// A reference to a type information instance
    case reference(ReferenceKey)
}
```
The enum already conforms to `Codable` and `Hashable` and provides several other convenience methods that can be found in `TypeInformation+Convenience.swift`.
Currently, it supports the initialization out of an Any type via `init(type:) throws` and out of any instance `init(value:) throws` using `Runtime` for the names
of the properties of the objects. Furthermore, a `TypeInformation` instance can be initialized via `static func of<B: TypeInformationBuilder>(_ type: Any.Type, with builderType: B.Type) throws -> TypeInformation`
where currently the `RuntimeBuilder.self` is the only one supported, e.g. `try TypeInformation.of(User.self, with: RuntimeBuilder.self)`

When constructing the `TypeInformation` out of a type, the created instance recursively contains all the types of the properties. Additionally, a
`TypesStore` can be used to reference a `TypeInformation` instance via `store(_ type: TypeInformation) -> TypeInformation`, which returns a `.reference` if the passed
type contains an `enum` or an `object`. The same instance can be reconstructed from the same `TypesStore` via `construct(from reference: TypeInformation) -> TypeInformation`.

## Setup

The ApodiniTypeInformation library uses the Swift Package Manager for dependency management.

Add it to your project's list of dependencies and to the list of dependencies of your target:

```swift
dependencies: [
    .package(url: "https://github.com/Apodini/ApodiniTypeInformation.git", from: "X.X.X")
],

targets: [
    .target(
        name: "Your Target",
        dependencies: [
            .product(name: "ApodiniTypeInformation", "ApodiniTypeInformation")
        ]
    )
]

```

## Contributing
Contributions to this project are welcome. Please make sure to read the [contribution guidelines](https://github.com/Apodini/.github/blob/main/CONTRIBUTING.md) and the [contributor covenant code of conduct](https://github.com/Apodini/.github/blob/main/CODE_OF_CONDUCT.md) first.

## License
This project is licensed under the MIT License. See [Licenses](https://github.com/Apodini/ApodiniTypeInformation/blob/develop/LICENSES) for more information.
