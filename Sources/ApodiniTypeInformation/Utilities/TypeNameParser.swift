//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

typealias ParsedTypeName = [ParsedTypeNamePart]

enum ParsedTypeNamePart: Hashable {
    case targetName(name: String)
    indirect case typeName(name: String, generics: [ParsedTypeName] = [])
    
    var name: String {
        switch self {
        case let .targetName(name):
            return name
        case let .typeName(name, _):
            return name
        }
    }
    
    var isTargetName: Bool {
        if case .targetName = self {
            return true
        }
        return false
    }
    
    var generics: [ParsedTypeName] {
        if case let .typeName(_, generics) = self {
            return generics
        }
        return []
    }
}

class TypeNameParser {
    enum State {
        case targetName
        case typeName
        case parsingGeneric
    }

    /// The input to the parser!
    private let input: String
    /// The current index to the character which we are parsing.
    private var index: String.Index

    /// The current parser state.
    private var state: State = .targetName

    /// Used to store all characters of a type name or target name while parsing.
    private var typeNameOutput: [Character] = []
    /// Used to store all characters of a generic argument while parsing input.
    /// The resulting string is used as the input for another ``TypeNameParser`` parser.
    private var subParserInput: [Character] = []
    /// Collects all the results of an instantiated sub ``TypeNameParser``.
    /// Those collect the ``ParsedTypeName`` of all the generic arguments of the currently parsed type name.
    private var genericOutput: [ParsedTypeName] = []

    /// Captures the current generic argument parsing depth.
    /// Property is incremented for every `<` encountered, and decremeneted for every `>` encountered.
    private var genericParsingDepth = 0

    /// Consecutively stores the result of the parser.
    private var result: ParsedTypeName = []

    var hasRemainingInput: Bool {
        self.index < input.endIndex
    }

    init(_ input: String) {
        self.input = input.replacingOccurrences(of: " ", with: "")
        self.index = input.startIndex
    }

    func parse() -> ParsedTypeName {
        while hasRemainingInput {
            let next = input[index]
            self.index = input.index(after: self.index)
            handle(next: next)
        }

        return result
    }

    func handle(next character: Character) {
        switch state {
        case .targetName:
            handlePackageName(character: character)
        case .typeName:
            handleTypeName(character: character)
        case .parsingGeneric:
            handleGeneric(character: character)
        }
    }

    private func handlePackageName(character: Character) {
        if character == "." || !hasRemainingInput {
            result.append(.targetName(name: String(typeNameOutput)))
            typeNameOutput.removeAll()

            state = .typeName
        } else {
            typeNameOutput.append(character)
        }
    }

    private func handleTypeName(character: Character) {
        if character == "." {
            finishUpTypeName()
        } else if character == "<" {
            genericParsingDepth += 1
            state = .parsingGeneric
        } else {
            typeNameOutput.append(character)

            if !hasRemainingInput {
                finishUpTypeName()
            }
        }
    }

    private func handleGeneric(character: Character) {
        if (character == "," || character == ">") && genericParsingDepth == 1 {
            // we only consider "," and ">" if they appear on level 1,
            // otherwise they are part of the current generic argument parsed, and are treated in the else branch

            let genericArgument = String(subParserInput)
            subParserInput.removeAll()

            // feed the argument into a sub parser instance to parse the type name.
            let result = TypeNameParser(genericArgument).parse()
            genericOutput.append(result)

            if character == ">" {
                genericParsingDepth -= 1
                state = .typeName

                if !hasRemainingInput {
                    finishUpTypeName()
                }
            }
        } else {
            // update the genericParsingDepth counter
            if character == "<" {
                genericParsingDepth += 1
            } else if character == ">" {
                genericParsingDepth -= 1
            }

            subParserInput.append(character)
        }
    }

    private func finishUpTypeName() {
        result.append(.typeName(name: String(typeNameOutput), generics: genericOutput))

        typeNameOutput.removeAll()
        genericOutput.removeAll()
    }
}