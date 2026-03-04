// PEGExBuilders - Main entry point (mirrors RegexBuilder's Regex { })

import Parsing

/// Root parser builder. Use `Pegex { ... }` as the entry point for all parsers.
/// Wraps swift-parsing's Parse to provide RegexBuilder-like declarative PEG parsing.
public struct Pegex<Input, Parsers: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Parsers.Input == Input {
    @usableFromInline let underlying: Parsing.Parse<Input, Parsers>

    @inlinable public init(
        input inputType: Input.Type = Input.self,
        @ParserBuilder<Input> _ build: () -> Parsers
    ) {
        self.underlying = Parsing.Parse(input: inputType, with: build)
    }

    @inlinable public init<Upstream, NewOutput>(
        input inputType: Input.Type = Input.self,
        _ transform: @escaping (Upstream.Output) -> NewOutput,
        @ParserBuilder<Input> _ build: () -> Upstream
    ) where Parsers == Parsing.Parsers.Map<Upstream, NewOutput> {
        self.underlying = Parsing.Parse(input: inputType, transform, with: build)
    }

    @inlinable public init<Upstream, NewOutput>(
        input inputType: Input.Type = Input.self,
        _ output: NewOutput,
        @ParserBuilder<Input> _ build: () -> Upstream
    ) where Parsers == Parsing.Parsers.MapConstant<Upstream, NewOutput> {
        self.underlying = Parsing.Parse(input: inputType, output, with: build)
    }

    @inlinable public func parse(_ input: inout Input) throws -> Parsers.Output {
        try underlying.parse(&input)
    }
}

extension Pegex where Input == Substring {
    @inlinable public init(@ParserBuilder<Substring> _ build: () -> Parsers) {
        self.underlying = Parsing.Parse(input: Substring.self, with: build)
    }
}
