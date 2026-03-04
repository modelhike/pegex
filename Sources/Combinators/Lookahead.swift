// PEGExBuilders - Positive lookahead (PEG & predicate)

import Parsing

/// A parser that runs the inner parser but does not consume any input.
/// Succeeds if the inner parser succeeds; fails if it fails.
/// Output is always Void.
public struct Lookahead<Input, Upstream: Parser>: Parser
where Upstream.Input == Input {
    public typealias Output = Void

    @usableFromInline
    let upstream: Upstream

    @inlinable
    public init(@ParserBuilder<Input> _ build: () -> Upstream) {
        self.upstream = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Void {
        var copy = input
        _ = try upstream.parse(&copy)
        // Do NOT advance input - that's the point of lookahead
    }
}
