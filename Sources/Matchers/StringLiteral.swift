// PEGExBuilders - String literal parser with configurable quote and escape

import Parsing

/// Parses quoted string literals with configurable quote character(s) and escape.
public struct StringLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    public enum EscapeMode: Equatable, Sendable {
        case none
        case character(Character)
        case doubledClosingDelimiter
    }

    public struct Delimiter: Equatable, Sendable {
        public var opening: Character
        public var closing: Character
        public var escapeMode: EscapeMode

        @inlinable
        public init(
            opening: Character,
            closing: Character? = nil,
            escapeMode: EscapeMode = .character("\\")
        ) {
            self.opening = opening
            self.closing = closing ?? opening
            self.escapeMode = escapeMode
        }
    }

    @usableFromInline
    let delimiters: [Delimiter]

    /// Single quote (e.g. `StringLiteral(quote: "'")` for SQL).
    @inlinable
    public init(quote: Character = "\"", escape: Character? = "\\") {
        self.delimiters = [
            Delimiter(
                opening: quote,
                escapeMode: escape.map(EscapeMode.character) ?? .none
            )
        ]
    }

    /// Single quote with configurable escape mode, including doubled delimiters.
    @inlinable
    public init(quote: Character = "\"", escapeMode: EscapeMode) {
        self.delimiters = [Delimiter(opening: quote, escapeMode: escapeMode)]
    }

    /// Multiple quote options (e.g. `StringLiteral(quotes: ["\"", "'", "\`"])` for SQL/JS).
    /// The opening quote determines the closing quote; they must match.
    @inlinable
    public init(quotes: [Character], escape: Character? = "\\") {
        let chosenQuotes = quotes.isEmpty ? ["\""] : quotes
        self.delimiters = chosenQuotes.map {
            Delimiter(
                opening: $0,
                escapeMode: escape.map(EscapeMode.character) ?? .none
            )
        }
    }

    /// Multiple quote options with configurable escape mode.
    @inlinable
    public init(quotes: [Character], escapeMode: EscapeMode) {
        let chosenQuotes = quotes.isEmpty ? ["\""] : quotes
        self.delimiters = chosenQuotes.map { Delimiter(opening: $0, escapeMode: escapeMode) }
    }

    /// Variadic multiple quotes.
    @inlinable
    public init(quotes: Character..., escape: Character? = "\\") {
        let chosenQuotes = quotes.isEmpty ? ["\""] : quotes
        self.delimiters = chosenQuotes.map {
            Delimiter(
                opening: $0,
                escapeMode: escape.map(EscapeMode.character) ?? .none
            )
        }
    }

    /// Full delimiter configuration when opening and closing delimiters differ.
    @inlinable
    public init(delimiters: [Delimiter]) {
        self.delimiters = delimiters.isEmpty ? [Delimiter(opening: "\"")] : delimiters
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> String {
        guard let opening = input.first else {
            throw pegexFailure("expected string literal", at: input)
        }
        guard let delimiter = delimiters.first(where: { $0.opening == opening }) else {
            let openings = delimiters.map { String($0.opening) }.joined(separator: ", ")
            throw pegexFailure("expected one of: \(openings)", at: input)
        }

        input = input.dropFirst()
        var result = ""
        while let c = input.first {
            switch delimiter.escapeMode {
            case .character(let escape) where c == escape:
                input = input.dropFirst()
                guard let next = input.first else {
                    throw pegexFailure("unexpected end after escape", at: input)
                }
                result.append(next)
                input = input.dropFirst()
                continue
            case .doubledClosingDelimiter where c == delimiter.closing:
                let afterClosing = input.dropFirst()
                if afterClosing.first == delimiter.closing {
                    result.append(delimiter.closing)
                    input = afterClosing.dropFirst()
                    continue
                }
                input = afterClosing
                return result
            default:
                break
            }

            if c == delimiter.closing {
                input = input.dropFirst()
                return result
            }

            result.append(c)
            input = input.dropFirst()
        }
        throw pegexFailure("unclosed string literal", at: input)
    }
}
