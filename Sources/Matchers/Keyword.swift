// PEGExBuilders - Case-insensitive keyword with word boundary

import Parsing

/// A parser that matches a keyword case-insensitively with word boundary assertion.
/// After the final word, the next character must NOT be alphanumeric or underscore.
public struct Keyword<Input: Collection & Sendable>: Parser, Sendable
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let words: [String]

    @inlinable
    public init(_ words: String...) {
        self.words = words
    }

    @usableFromInline
    init(words: [String]) {
        self.words = words
    }

    @inlinable
    public func parse(_ input: inout Input) throws {
        for (index, word) in words.enumerated() {
            // Case-insensitive prefix match
            guard input.count >= word.count else {
                throw PEGExParseError("expected \"\(word)\"")
            }
            let prefix = input.prefix(word.count)
            let inputStr = String(prefix)
            guard inputStr.lowercased() == word.lowercased() else {
                throw PEGExParseError("expected \"\(word)\"")
            }
            input = input.dropFirst(word.count)

            // Between words: consume one or more whitespace
            if index < words.count - 1 {
                guard let first = input.first, first.isWhitespace else {
                    throw PEGExParseError("expected whitespace")
                }
                repeat {
                    input = input.dropFirst()
                } while input.first?.isWhitespace == true
            }
        }

        // After last word: assert word boundary (next char must NOT be word char)
        if let next = input.first {
            let isWordChar = next.isLetter || next.isNumber || next == "_"
            if isWordChar {
                throw PEGExParseError("expected word boundary after \"\(words.last!)\"")
            }
        }
    }
}
