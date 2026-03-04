// PEGExBuilders - Pratt parser generator

import Parsing

/// Pratt-style precedence parser for expressions.
public struct PrecedenceGroup<Input, Output>: Parser
where Input: Collection, Input.SubSequence == Input {
    private let atomParser: AnyParser<Input, Output>
    private let levels: [AnyPrecedenceLevel<Input, Output>]

    public init(
        atom: some Parser<Input, Output>,
        levels: [AnyPrecedenceLevel<Input, Output>]
    ) {
        self.atomParser = atom.eraseToAnyParser()
        self.levels = levels
    }

    public init(
        atom: some Parser<Input, Output>,
        @PrecedenceBuilder<Input, Output> buildLevels: () -> [AnyPrecedenceLevel<Input, Output>]
    ) {
        self.atomParser = atom.eraseToAnyParser()
        self.levels = buildLevels()
    }

    public func parse(_ input: inout Input) throws -> Output {
        try parseExpr(minPrecedence: 0, input: &input)
    }

    private func parseExpr(minPrecedence: Int, input: inout Input) throws -> Output {
        var lhs = try parsePrefixOrAtom(input: &input)

        loop: while true {
            for level in levels {
                guard level.precedence >= minPrecedence else { continue }
                switch level.kind {
                case .infixLeft(let opParser, let combine):
                    var copy = input
                    do {
                        _ = try opParser.parse(&copy)
                        let rhs = try parseExpr(minPrecedence: level.precedence + 1, input: &copy)
                        input = copy
                        lhs = combine(lhs, rhs)
                        continue loop
                    } catch {}
                case .infixRight(let opParser, let combine):
                    var copy = input
                    do {
                        _ = try opParser.parse(&copy)
                        let rhs = try parseExpr(minPrecedence: level.precedence, input: &copy)
                        input = copy
                        lhs = combine(lhs, rhs)
                        continue loop
                    } catch {}
                case .postfix(let opParser, let apply):
                    var copy = input
                    do {
                        _ = try opParser.parse(&copy)
                        input = copy
                        lhs = apply(lhs)
                        continue loop
                    } catch {}
                case .atom, .prefix:
                    break
                }
            }
            break
        }
        return lhs
    }

    private func parsePrefixOrAtom(input: inout Input) throws -> Output {
        for level in levels.reversed() {
            if case .prefix(let opParser, let apply) = level.kind {
                var copy = input
                do {
                    _ = try opParser.parse(&copy)
                    let operand = try parseExpr(minPrecedence: level.precedence, input: &copy)
                    input = copy
                    return apply(operand)
                } catch {}
            }
        }
        return try atomParser.parse(&input)
    }
}
