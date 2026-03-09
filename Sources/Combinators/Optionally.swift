// PEGExBuilders - Optional parser with implicit whitespace support

import Parsing

/// Result builder for `Optionally` blocks that inserts whitespace between
/// child parsers and skips Void outputs (like `@ParserBuilder` does).
@resultBuilder
public enum OptionallyBuilder<Input> {
    public static func buildBlock<P: Parser>(_ parser: P) -> P
    where P.Input == Input {
        parser
    }

    public static func buildPartialBlock<P: Parser>(first: P) -> P
    where P.Input == Input {
        first
    }

    // Both non-Void: produce tuple (disfavored so Skip variants are preferred)
    @_disfavoredOverload
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> ImplicitWhitespaceSequence<A, B>
    where A.Input == Input, B.Input == Input,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
    }

    // Accumulated is Void: skip it (disfavored so SkipSecond wins when both are Void)
    @_disfavoredOverload
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> ImplicitWhitespaceSkipFirst<A, B>
    where A.Input == Input, B.Input == Input, A.Output == Void,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        ImplicitWhitespaceSkipFirst(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
    }

    // Next is Void: skip it
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> ImplicitWhitespaceSkipSecond<A, B>
    where A.Input == Input, B.Input == Input, B.Output == Void,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        ImplicitWhitespaceSkipSecond(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
    }
}

/// A parser that runs the inner parser and succeeds with nil if it fails.
///
/// Uses `@OptionallyBuilder` so that whitespace is automatically inserted
/// between child parsers and Void outputs are skipped.
///
/// When the wrapped parser fails, `Optionally` backtracks any consumption
/// of the input so that later parsers can attempt to parse it.
public struct Optionally<Input, Wrapped: Parser>: Parser
where Wrapped.Input == Input {
    @usableFromInline
    let wrapped: Wrapped

    @inlinable
    public init(@OptionallyBuilder<Input> _ build: () -> Wrapped) {
        self.wrapped = build()
    }

    @inlinable
    public func parse(_ input: inout Input) -> Wrapped.Output? {
        let original = input
        do {
            return try self.wrapped.parse(&input)
        } catch {
            input = original
            return nil
        }
    }
}
