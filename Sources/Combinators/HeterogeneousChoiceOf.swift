import Parsing

/// Ordered choice for alternatives that have already been erased to a shared output type.
public struct HeterogeneousChoiceOf<Input, Output>: Parser {
    @usableFromInline
    let alternatives: [AnyParser<Input, Output>]

    @inlinable
    public init(_ alternatives: [AnyParser<Input, Output>]) {
        self.alternatives = alternatives
    }

    @inlinable
    public init(@HeterogeneousChoiceBuilder<Input, Output> _ build: () -> [AnyParser<Input, Output>]) {
        self.alternatives = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Output {
        var lastError: Error?

        for alternative in alternatives {
            let cutState = CutContext.push()
            var copy = input
            do {
                let output = try alternative.parse(&copy)
                CutContext.pop()
                input = copy
                return output
            } catch let cutError as CutError {
                CutContext.pop()
                throw cutError
            } catch {
                CutContext.pop()
                if cutState.didCommit {
                    throw CutError(underlying: error, position: cutState.position ?? PEGExPosition(copy))
                }
                lastError = error
            }
        }

        throw lastError ?? PEGExParseError("expected one of \(alternatives.count) alternatives")
    }
}

@resultBuilder
public enum HeterogeneousChoiceBuilder<Input, Output> {
    @inlinable
    public static func buildBlock(_ components: [AnyParser<Input, Output>]...) -> [AnyParser<Input, Output>] {
        components.flatMap { $0 }
    }

    @inlinable
    public static func buildExpression<P: Parser>(_ parser: P) -> [AnyParser<Input, Output>]
    where P.Input == Input, P.Output == Output {
        [parser.eraseToAnyParser()]
    }

    @inlinable
    public static func buildOptional(_ component: [AnyParser<Input, Output>]?) -> [AnyParser<Input, Output>] {
        component ?? []
    }

    @inlinable
    public static func buildEither(first component: [AnyParser<Input, Output>]) -> [AnyParser<Input, Output>] {
        component
    }

    @inlinable
    public static func buildEither(second component: [AnyParser<Input, Output>]) -> [AnyParser<Input, Output>] {
        component
    }

    @inlinable
    public static func buildArray(_ components: [[AnyParser<Input, Output>]]) -> [AnyParser<Input, Output>] {
        components.flatMap { $0 }
    }
}

extension Parser {
    /// Erases a parser to a shared output type for use in `HeterogeneousChoiceOf`.
    @inlinable
    public func eraseOutput<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> AnyParser<Input, NewOutput> {
        self.map(transform).eraseToAnyParser()
    }
}
