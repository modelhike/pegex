// PEGExBuilders - Failable transform capture

import Parsing

/// A parser that captures and applies a failable transform.
/// If the transform returns nil, parsing fails at that position.
public struct TryCapture<Input, Upstream: Parser, Output>: Parser
where Upstream.Input == Input {
    @usableFromInline
    let upstream: Upstream
    @usableFromInline
    let transform: (Upstream.Output) -> Output?

    @inlinable
    public init(
        @ParserBuilder<Input> _ build: () -> Upstream,
        transform: @escaping (Upstream.Output) -> Output?
    ) {
        self.upstream = build()
        self.transform = transform
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Output {
        let output = try upstream.parse(&input)
        guard let result = transform(output) else {
            throw PEGExParseError("transform returned nil")
        }
        return result
    }
}
