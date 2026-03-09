// PEGExBuilders - Negative lookahead (PEG ! predicate)

import Parsing

/// A parser that succeeds if the inner parser FAILS, and does not consume any input.
/// Succeeds (consuming nothing) if the inner parser fails; fails if the inner parser succeeds.
/// Output is always Void.
public struct NegativeLookahead<Input, Upstream: Parser>: Parser
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
        do {
            _ = try upstream.parse(&copy)
        } catch {
            // Inner parser failed — lookahead succeeds (consume nothing)
            return
        }
        // Inner parser succeeded — lookahead must fail
        throw PEGExError.negativeLookaheadFailed(at: PEGExPosition(input))
    }
}
