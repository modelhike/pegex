// PEGExBuilders - Self-referencing parser

import Parsing

/// A parser that can reference itself for recursive grammars.
public struct Recursive<Input, Output>: Parser
where Input: Collection, Input.SubSequence == Input {
    private let box: ParserBox<Input, Output>

    public init(
        _ inputType: Input.Type = Input.self,
        _ outputType: Output.Type = Output.self,
        _ build: @escaping (Parsing.AnyParser<Input, Output>) -> Parsing.AnyParser<Input, Output>
    ) {
        let box = ParserBox<Input, Output>()
        let ref = Parsing.AnyParser<Input, Output> { try box.parse(&$0) }
        let inner = build(ref)
        box.parser = inner
        self.box = box
    }

    public func parse(_ input: inout Input) throws -> Output {
        try box.parse(&input)
    }
}

private final class ParserBox<Input, Output>: @unchecked Sendable {
    var parser: Parsing.AnyParser<Input, Output>?

    func parse(_ input: inout Input) throws -> Output {
        guard let parser else { fatalError("Recursive parser not initialized") }
        return try parser.parse(&input)
    }
}
