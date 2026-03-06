// PEGExBuilders - Ordered choice (PEG alternative) with Cut support

import Parsing

/// A parser that tries each alternative in order until one succeeds.
public struct ChoiceOf<Input, Output>: Parser {
    @usableFromInline
    let alternatives: [AnyParser<Input, Output>]

    @inlinable
    public init(_ alternatives: [AnyParser<Input, Output>]) {
        self.alternatives = alternatives
    }

    @inlinable
    public init(
        input inputType: Input.Type = Input.self,
        output outputType: Output.Type = Output.self,
        @HeterogeneousChoiceBuilder<Input, Output> _ build: () -> [AnyParser<Input, Output>]
    ) {
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
