// PEGExBuilders - String literal parser with configurable quote and escape

import Parsing

/// Parses quoted string literals with configurable quote character(s) and escape.
public struct StringLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let quotes: [Character]
    @usableFromInline
    let escape: Character?

    /// Single quote (e.g. `StringLiteral(quote: "'")` for SQL).
    @inlinable
    public init(quote: Character = "\"", escape: Character? = "\\") {
        self.quotes = [quote]
        self.escape = escape
    }

    /// Multiple quote options (e.g. `StringLiteral(quotes: ["\"", "'", "\`"])` for SQL/JS).
    /// The opening quote determines the closing quote; they must match.
    @inlinable
    public init(quotes: [Character], escape: Character? = "\\") {
        self.quotes = quotes.isEmpty ? ["\""] : quotes
        self.escape = escape
    }

    /// Variadic multiple quotes.
    @inlinable
    public init(quotes: Character..., escape: Character? = "\\") {
        self.quotes = quotes.isEmpty ? ["\""] : quotes
        self.escape = escape
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> String {
        guard let first = input.first, quotes.contains(first) else {
            throw PEGExParseError("expected one of: \(quotes.map { String($0) }.joined(separator: ", "))")
        }
        let quote = first
        input = input.dropFirst()
        var result = ""
        while let c = input.first {
            if c == quote {
                input = input.dropFirst()
                return result
            }
            if let esc = escape, c == esc {
                input = input.dropFirst()
                guard let next = input.first else { throw PEGExParseError("unexpected end after escape") }
                result.append(next)
                input = input.dropFirst()
                continue
            }
            result.append(c)
            input = input.dropFirst()
        }
        throw PEGExParseError("unclosed string literal")
    }
}
