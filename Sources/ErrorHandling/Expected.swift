// PEGExBuilders - Error annotation

import Parsing

/// Wraps a parser with a label for better error messages.
public struct Expected<Input, Upstream: Parser>: Parser
where Upstream.Input == Input {
    @usableFromInline
    let label: String
    @usableFromInline
    let upstream: Upstream

    @inlinable
    public init(_ label: String, @ParserBuilder<Input> _ build: () -> Upstream) {
        self.label = label
        self.upstream = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Upstream.Output {
        do {
            return try upstream.parse(&input)
        } catch {
            throw PEGExError.expected(label, at: PEGExPosition(input), underlying: error)
        }
    }
}
