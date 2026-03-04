// PEGExBuilders - Precedence level protocol and concrete levels

import Parsing

/// Type-erased precedence level for Pratt parsing.
public struct AnyPrecedenceLevel<Input, Output> {
    public let precedence: Int
    public let kind: Kind

    public enum Kind {
        case atom(AnyParser<Input, Output>)
        case infixLeft(AnyParser<Input, Void>, (Output, Output) -> Output)
        case infixRight(AnyParser<Input, Void>, (Output, Output) -> Output)
        case prefix(AnyParser<Input, Void>, (Output) -> Output)
        case postfix(AnyParser<Input, Void>, (Output) -> Output)
    }

    public init(precedence: Int, kind: Kind) {
        self.precedence = precedence
        self.kind = kind
    }
}

/// Atom level - parses the base expression.
public struct AtomLevel<Input, Output, P: Parser>: PrecedenceLevelType
where P.Input == Input, P.Output == Output {
    let parser: P

    public init(@ParserBuilder<Input> _ build: () -> P) {
        self.parser = build()
    }

    public func eraseToPrecedenceLevel() -> AnyPrecedenceLevel<Input, Output> {
        .init(precedence: .max, kind: .atom(parser.eraseToAnyParser()))
    }
}

/// Infix left-associative level.
public struct InfixLeftLevel<Input, Output, P: Parser>: PrecedenceLevelType
where P.Input == Input, P.Output == Void {
    let precedence: Int
    let opParser: P
    let combine: (Output, Output) -> Output

    public init(precedence: Int, _ opParser: P, combine: @escaping (Output, Output) -> Output) {
        self.precedence = precedence
        self.opParser = opParser
        self.combine = combine
    }

    public func eraseToPrecedenceLevel() -> AnyPrecedenceLevel<Input, Output> {
        .init(precedence: precedence, kind: .infixLeft(opParser.eraseToAnyParser(), combine))
    }
}

/// Infix right-associative level.
public struct InfixRightLevel<Input, Output, P: Parser>: PrecedenceLevelType
where P.Input == Input, P.Output == Void {
    let precedence: Int
    let opParser: P
    let combine: (Output, Output) -> Output

    public init(precedence: Int, _ opParser: P, combine: @escaping (Output, Output) -> Output) {
        self.precedence = precedence
        self.opParser = opParser
        self.combine = combine
    }

    public func eraseToPrecedenceLevel() -> AnyPrecedenceLevel<Input, Output> {
        .init(precedence: precedence, kind: .infixRight(opParser.eraseToAnyParser(), combine))
    }
}

/// Prefix unary level.
public struct PrefixLevel<Input, Output, P: Parser>: PrecedenceLevelType
where P.Input == Input, P.Output == Void {
    let precedence: Int
    let opParser: P
    let apply: (Output) -> Output

    public init(precedence: Int, _ opParser: P, apply: @escaping (Output) -> Output) {
        self.precedence = precedence
        self.opParser = opParser
        self.apply = apply
    }

    public func eraseToPrecedenceLevel() -> AnyPrecedenceLevel<Input, Output> {
        .init(precedence: precedence, kind: .prefix(opParser.eraseToAnyParser(), apply))
    }
}

/// Postfix unary level.
public struct PostfixLevel<Input, Output, P: Parser>: PrecedenceLevelType
where P.Input == Input, P.Output == Void {
    let precedence: Int
    let opParser: P
    let apply: (Output) -> Output

    public init(precedence: Int, _ opParser: P, apply: @escaping (Output) -> Output) {
        self.precedence = precedence
        self.opParser = opParser
        self.apply = apply
    }

    public func eraseToPrecedenceLevel() -> AnyPrecedenceLevel<Input, Output> {
        .init(precedence: precedence, kind: .postfix(opParser.eraseToAnyParser(), apply))
    }
}
