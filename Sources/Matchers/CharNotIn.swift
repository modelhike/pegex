// PEGExBuilders - Character range exclusion (CharNotIn)

import Parsing

/// A parser that consumes exactly one character NOT in a set of ranges and characters.
public struct CharNotIn<Input: Collection & Sendable>: Parser, Sendable
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let ranges: [ClosedRange<Character>]
    @usableFromInline
    let characters: Set<Character>

    @inlinable
    public init(_ ranges: ClosedRange<Character>..., characters: Character...) {
        self.ranges = Array(ranges)
        self.characters = Set(characters)
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Character {
        guard let first = input.first else {
            throw PEGExParseError("expected character not in set")
        }
        let inRange = ranges.contains { $0.contains(first) }
        let inChars = characters.contains(first)
        guard !inRange && !inChars else {
            throw PEGExParseError("expected character not in set")
        }
        input = input.dropFirst()
        return first
    }
}
