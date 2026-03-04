// PEGExBuilders - Named reference for captures

import Parsing

/// A reference for named capture access. Use with Capture(as: ref) to store captured values.
public final class Reference<Output>: @unchecked Sendable {
    @usableFromInline
    var value: Output?

    @inlinable
    public init() {
        self.value = nil
    }

    @inlinable
    public func get() -> Output? {
        value
    }

    @inlinable
    public func set(_ v: Output) {
        value = v
    }
}

/// A parser that captures into a reference and produces Void (for use in sequences).
public struct CaptureAs<Input, Upstream: Parser, Output>: Parser
where Upstream.Input == Input {
    @usableFromInline
    let reference: Reference<Output>
    @usableFromInline
    let upstream: Upstream
    @usableFromInline
    let transform: (Upstream.Output) -> Output

    @inlinable
    public init(
        as reference: Reference<Output>,
        @ParserBuilder<Input> _ build: () -> Upstream,
        transform: @escaping (Upstream.Output) -> Output
    ) {
        self.reference = reference
        self.upstream = build()
        self.transform = transform
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Void {
        let output = try upstream.parse(&input)
        reference.set(transform(output))
    }
}
