// PEGExBuilders - Explicit sequence wrapper

import Parsing

/// Explicit sequence wrapper - wraps Parse for documentation clarity.
public struct Sequence<Input, Parsers: Parser>: Parser
where Parsers.Input == Input {
    @usableFromInline
    let underlying: Parsing.Parse<Input, Parsers>

    @inlinable
    public init(
        input inputType: Input.Type = Input.self,
        @ParserBuilder<Input> _ build: () -> Parsers
    ) {
        self.underlying = Parsing.Parse(input: inputType, with: build)
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Parsers.Output {
        try underlying.parse(&input)
    }
}
