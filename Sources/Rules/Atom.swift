// PEGExBuilders - Atomic expression level (highest precedence)

import Parsing

/// Marks the atom level for precedence parsing - literals, identifiers, parenthesized expressions.
public struct Atom<Input, Output, P: Parser>: Parser
where P.Input == Input, P.Output == Output {
    @usableFromInline
    let parser: P

    @inlinable
    public init(@ParserBuilder<Input> _ build: () -> P) {
        self.parser = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Output {
        try parser.parse(&input)
    }
}
