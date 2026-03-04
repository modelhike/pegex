// PEGExBuilders - Whitespace and comment parser

import Parsing

/// Parses zero or more whitespace characters and SQL comments.
public struct Whitespace<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws {
        parseLoop: while !input.isEmpty {
            if input.first?.isWhitespace == true {
                repeat { input = input.dropFirst() } while input.first?.isWhitespace == true
                continue
            }
            if input.starts(with: "--") || input.starts(with: "/*") {
                try SQLComment<Input>().parse(&input)
                continue
            }
            break parseLoop
        }
    }
}
