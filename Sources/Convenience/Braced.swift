// PEGExBuilders - Braced content { inner }

import Parsing

/// Parses content surrounded by braces.
public struct Braced<Content: Parser>: Parser
where Content.Input == Substring {
    @usableFromInline
    let content: Content

    @inlinable
    public init(@ParserBuilder<Substring> _ build: () -> Content) {
        self.content = build()
    }

    @inlinable
    public func parse(_ input: inout Substring) throws -> Content.Output {
        _ = try "{".parse(&input)
        let result = try content.parse(&input)
        _ = try "}".parse(&input)
        return result
    }
}
