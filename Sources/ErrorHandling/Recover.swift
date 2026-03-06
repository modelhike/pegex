// PEGExBuilders - Skip-to-sync-point error recovery

import Parsing

/// Tries upstream parser; on failure, skips input until recovery parser matches, then emits error via callback.
public struct Recover<Input, Upstream: Parser, Recovery: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Upstream.Input == Input, Recovery.Input == Input {
    @usableFromInline
    let upstream: Upstream
    @usableFromInline
    let recovery: Recovery
    @usableFromInline
    let onError: (Error, Input) -> Void

    @inlinable
    public init(
        @ParserBuilder<Input> upstream buildUpstream: () -> Upstream,
        @ParserBuilder<Input> recovery buildRecovery: () -> Recovery,
        onError: @escaping (Error, Input) -> Void
    ) {
        self.upstream = buildUpstream()
        self.recovery = buildRecovery()
        self.onError = onError
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Upstream.Output {
        do {
            return try upstream.parse(&input)
        } catch {
            onError(error, input)
            var copy = input
            while !copy.isEmpty {
                var attempt = copy
                do {
                    _ = try recovery.parse(&attempt)
                    input = attempt
                    throw PEGExError.recovery(message: "recovered after skip", skipped: PEGExPosition(input))
                } catch {
                    copy = copy.dropFirst()
                }
            }
            throw error
        }
    }
}
