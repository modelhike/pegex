// PEGExBuilders - At least one whitespace

import Parsing

/// Parses at least one whitespace character (not comments).
public struct RequiredWhitespace<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws {
        guard let first = input.first, first.isWhitespace else {
            throw PEGExParseError("expected whitespace")
        }
        repeat { input = input.dropFirst() } while input.first?.isWhitespace == true
    }
}
