// PEGExBuilders - Result builder that inserts whitespace between parsers

import Parsing

@resultBuilder
public enum ImplicitWhitespaceBuilder<Input: Collection>
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public static func buildBlock<P: Parser>(_ parser: P) -> P
    where P.Input == Input {
        parser
    }

    @inlinable
    public static func buildPartialBlock<P: Parser>(first: P) -> P
    where P.Input == Input {
        first
    }

    @inlinable
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> ImplicitWhitespaceSequence<A, B>
    where A.Input == Input, B.Input == Input, Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        ImplicitWhitespaceSequence(accumulated, next)
    }
}

/// Sequence with implicit whitespace between parsers.
public struct ImplicitWhitespaceSequence<A: Parser, B: Parser>: Parser
where A.Input == B.Input, A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B

    @inlinable
    public init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> (A.Output, B.Output) {
        let o1 = try a.parse(&input)
        _ = try Whitespace<A.Input>().parse(&input)
        let o2 = try b.parse(&input)
        return (o1, o2)
    }
}
