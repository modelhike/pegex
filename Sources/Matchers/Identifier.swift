// PEGExBuilders - Identifier parser

import Parsing

/// Parser for identifiers (variable names, column names, etc.).
public struct Identifier<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    public enum Style {
        case standard  // [a-zA-Z_][a-zA-Z0-9_]*
        case sql       // [a-zA-Z_@#$][a-zA-Z0-9_@#$]*
    }

    @usableFromInline
    let style: Style

    @inlinable
    public init(style: Style = .standard) {
        self.style = style
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> String {
        guard let first = input.first else {
            throw PEGExParseError("expected identifier")
        }
        let isStart: (Character) -> Bool
        let isCont: (Character) -> Bool
        switch style {
        case .standard:
            isStart = { $0.isLetter || $0 == "_" }
            isCont = { $0.isLetter || $0.isNumber || $0 == "_" }
        case .sql:
            isStart = { $0.isLetter || $0 == "_" || $0 == "@" || $0 == "#" || $0 == "$" }
            isCont = { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "@" || $0 == "#" || $0 == "$" }
        }
        guard isStart(first) else {
            throw PEGExParseError("expected identifier")
        }
        var result = ""
        while let c = input.first, isCont(c) {
            result.append(c)
            input = input.dropFirst()
        }
        return result
    }
}
