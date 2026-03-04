// PEGExBuilders - Exactly one occurrence (RegexBuilder parity)

import Parsing

/// A parser that runs the inner parser exactly once.
public struct One<Input, Component: Parser>: Parser
where Component.Input == Input {
    @usableFromInline
    let component: Component

    @inlinable
    public init(_ component: Component) {
        self.component = component
    }

    @inlinable
    public init(@ParserBuilder<Input> _ build: () -> Component) {
        self.component = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Component.Output {
        try component.parse(&input)
    }
}
