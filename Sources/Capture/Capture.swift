// PEGExBuilders - Basic capture

import Parsing

/// A parser that captures and includes the output of its inner parser in the result.
/// In ParserBuilder context, non-Void outputs are collected into tuples.
public struct Capture<Input, Upstream: Parser>: Parser
where Upstream.Input == Input {
    @usableFromInline
    let upstream: Upstream

    @inlinable
    public init(@ParserBuilder<Input> _ build: () -> Upstream) {
        self.upstream = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Upstream.Output {
        try upstream.parse(&input)
    }
}
