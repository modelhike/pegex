// PEGExBuilders - Optional keyword-prefixed clause

import Parsing

/// Parses an optional clause: KEYWORD followed by content.
public struct Clause<Input, Content: Parser>: Parser
where Input: Collection & Sendable, Input.SubSequence == Input, Input.Element == Character, Content.Input == Input {
    @usableFromInline
    let keyword: Keyword<Input>
    @usableFromInline
    let content: Content

    @inlinable
    public init(_ words: String..., @ParserBuilder<Input> content build: () -> Content) {
        self.keyword = Keyword<Input>(words: Array(words))
        self.content = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Content.Output? {
        let original = input
        do {
            try keyword.parse(&input)
            return try content.parse(&input)
        } catch {
            input = original
            return nil
        }
    }
}
