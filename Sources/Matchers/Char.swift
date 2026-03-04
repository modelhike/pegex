// PEGExBuilders - Character class parsers (.digit, .letter, .word, etc.)

import Parsing

/// A parser that consumes exactly one character matching a predicate.
public struct CharParser<Input: Collection & Sendable>: Parser, Sendable
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let predicate: @Sendable (Character) -> Bool

    @inlinable
    public init(while predicate: @escaping @Sendable (Character) -> Bool) {
        self.predicate = predicate
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Character {
        guard let first = input.first else {
            throw PEGExParseError("expected character")
        }
        guard predicate(first) else {
            throw PEGExParseError("expected character satisfying predicate")
        }
        input = input.dropFirst()
        return first
    }
}

/// Namespace for character class parsers.
public enum Char<Input: Collection & Sendable>: Sendable
where Input.SubSequence == Input, Input.Element == Character {
    /// Matches a digit [0-9].
    public static var digit: CharParser<Input> {
        CharParser { $0.isNumber }
    }

    /// Matches a Unicode letter.
    public static var letter: CharParser<Input> {
        CharParser { $0.isLetter }
    }

    /// Matches a letter or digit.
    public static var alphanumeric: CharParser<Input> {
        CharParser { $0.isLetter || $0.isNumber }
    }

    /// Matches whitespace (space, tab, etc.).
    public static var whitespace: CharParser<Input> {
        CharParser { $0.isWhitespace }
    }

    /// Matches newline (\n, \r\n, \r).
    public static var newline: CharParser<Input> {
        CharParser { $0 == "\n" || $0 == "\r" }
    }

    /// Matches any single character (PEG ".").
    public static var any: CharParser<Input> {
        CharParser { _ in true }
    }

    /// Matches letter, digit, or underscore.
    public static var word: CharParser<Input> {
        CharParser { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    /// Matches hex digit [0-9a-fA-F].
    public static var hexDigit: CharParser<Input> {
        CharParser { c in
            c.isNumber || (c >= "a" && c <= "f") || (c >= "A" && c <= "F")
        }
    }

    /// Matches a character satisfying a custom predicate.
    public static func matching(_ predicate: @escaping @Sendable (Character) -> Bool) -> CharParser<Input> {
        CharParser(while: predicate)
    }

    /// Matches exactly the given character.
    public static func character(_ c: Character) -> CharParser<Input> {
        CharParser { $0 == c }
    }
}
