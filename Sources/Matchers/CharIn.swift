// PEGExBuilders - Character range inclusion (CharIn)

import Parsing

/// A parser that consumes exactly one character from a set of ranges and characters.
public struct CharIn<Input: Collection & Sendable>: Parser, Sendable
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let ranges: [ClosedRange<Character>]
    @usableFromInline
    let characters: Set<Character>

    @inlinable
    public init(_ ranges: ClosedRange<Character>...) {
        self.ranges = Array(ranges)
        self.characters = []
    }

    @inlinable
    public init(characters: Character...) {
        self.ranges = []
        self.characters = Set(characters)
    }

    @inlinable
    public init(ranges: ClosedRange<Character>..., characters: Character...) {
        self.ranges = Array(ranges)
        self.characters = Set(characters)
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Character {
        guard let first = input.first else {
            throw PEGExParseError("expected character in set")
        }
        let inRange = ranges.contains { $0.contains(first) }
        let inChars = characters.contains(first)
        guard inRange || inChars else {
            throw PEGExParseError("expected character in set")
        }
        input = input.dropFirst()
        return first
    }
}
