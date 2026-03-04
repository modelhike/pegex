// PEGExBuilders - Configurable bracketed content

import Parsing

/// Parses content surrounded by configurable open/close brackets.
public struct Bracketed<Content: Parser>: Parser
where Content.Input == Substring {
    @usableFromInline
    let open: Character
    @usableFromInline
    let close: Character
    @usableFromInline
    let content: Content

    @inlinable
    public init(open: Character = "[", close: Character = "]", @ParserBuilder<Substring> _ build: () -> Content) {
        self.open = open
        self.close = close
        self.content = build()
    }

    @inlinable
    public func parse(_ input: inout Substring) throws -> Content.Output {
        guard let first = input.first, first == open else {
            throw PEGExParseError("expected \(open)")
        }
        input = input.dropFirst()
        let result = try content.parse(&input)
        guard let last = input.first, last == close else {
            throw PEGExParseError("expected \(close)")
        }
        input = input.dropFirst()
        return result
    }
}
