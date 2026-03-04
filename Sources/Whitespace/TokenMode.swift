// PEGExBuilders - Token mode for whitespace handling

import Parsing

/// Mode for token/whitespace handling.
public enum TokenModeKind {
    /// Skip leading whitespace and comments before each token.
    case skipWhitespaceAndComments
    /// Character mode - no implicit whitespace.
    case character
}

/// Wraps parsers with optional whitespace skipping.
public struct TokenMode<Input, Parsers: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Input.Element == Character, Parsers.Input == Input {
    @usableFromInline
    let mode: TokenModeKind
    @usableFromInline
    let parsers: Parsers

    @inlinable
    public init(_ mode: TokenModeKind, @ImplicitWhitespaceBuilder<Input> _ build: () -> Parsers) {
        self.mode = mode
        self.parsers = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Parsers.Output {
        if case .skipWhitespaceAndComments = mode {
            _ = try? Whitespace<Input>().parse(&input)
        }
        return try parsers.parse(&input)
    }
}
