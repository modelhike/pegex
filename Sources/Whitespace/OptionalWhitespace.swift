// PEGExBuilders - Zero or more whitespace (no comments)

import Parsing

/// Parses zero or more whitespace characters.
public struct OptionalWhitespace<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws {
        while input.first?.isWhitespace == true {
            input = input.dropFirst()
        }
    }
}
