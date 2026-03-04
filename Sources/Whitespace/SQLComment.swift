// PEGExBuilders - SQL comment parser

import Parsing

/// Parses SQL-style comments: -- to EOL and /* ... */
public struct SQLComment<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws {
        if input.starts(with: "--") {
            input = input.dropFirst(2)
            while let first = input.first, first != "\n", first != "\r" {
                input = input.dropFirst()
            }
            return
        }
        if input.starts(with: "/*") {
            input = input.dropFirst(2)
            var depth = 1
            while depth > 0, !input.isEmpty {
                if input.starts(with: "/*") {
                    depth += 1
                    input = input.dropFirst(2)
                } else if input.starts(with: "*/") {
                    depth -= 1
                    input = input.dropFirst(2)
                } else {
                    input = input.dropFirst()
                }
            }
            return
        }
        throw PEGExParseError("expected SQL comment")
    }
}
