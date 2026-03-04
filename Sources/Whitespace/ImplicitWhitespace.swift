// PEGExBuilders - Auto whitespace insertion

import Parsing

/// Wraps a parser block with implicit whitespace between each parser.
public struct ImplicitWhitespace<Input, Parsers: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Input.Element == Character, Parsers.Input == Input {
    @usableFromInline
    let parsers: Parsers

    @inlinable
    public init(input inputType: Input.Type = Input.self, @ImplicitWhitespaceBuilder<Input> _ build: () -> Parsers) {
        self.parsers = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Parsers.Output {
        try parsers.parse(&input)
    }
}

extension ImplicitWhitespace where Input == Substring {
    /// Convenience initializer for Substring parsing (the common case).
    /// Use `ImplicitWhitespace { ... }` instead of `ImplicitWhitespace(input: Substring.self) { ... }`.
    @inlinable
    public init(@ImplicitWhitespaceBuilder<Substring> _ build: () -> Parsers) {
        self.parsers = build()
    }
}
