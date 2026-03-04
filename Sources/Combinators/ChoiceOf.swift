// PEGExBuilders - Ordered choice (PEG alternative) with Cut support

import Parsing

/// A parser that tries each alternative in order until one succeeds.
/// Wraps swift-parsing's OneOf. When an alternative throws CutError, re-throws immediately.
public struct ChoiceOf<Input, Output, Parsers: Parser>: Parser
where Parsers.Input == Input, Parsers.Output == Output {
    @usableFromInline
    let underlying: Parsing.OneOf<Input, Output, Parsers>

    @inlinable
    public init(
        input inputType: Input.Type = Input.self,
        output outputType: Output.Type = Output.self,
        @OneOfBuilder<Input, Output> _ build: () -> Parsers
    ) {
        self.underlying = Parsing.OneOf(input: inputType, output: outputType, build)
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Output {
        do {
            return try underlying.parse(&input)
        } catch let cutError as CutError {
            throw cutError
        }
    }
}
