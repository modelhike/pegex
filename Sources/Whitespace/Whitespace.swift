// PEGExBuilders - Whitespace and comment parser

import Parsing

/// Parses zero or more whitespace characters and SQL comments.
public struct Whitespace<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let configuration: WhitespaceConfiguration

    @inlinable
    public init(configuration: WhitespaceConfiguration = .standard) {
        self.configuration = configuration
    }

    @inlinable
    public init(commentSyntax: CommentSyntax) {
        self.configuration = .init(commentSyntax: commentSyntax)
    }

    @inlinable
    public func parse(_ input: inout Input) throws {
        parseLoop: while !input.isEmpty {
            if let first = input.first, configuration.isWhitespaceCharacter(first) {
                repeat {
                    input = input.dropFirst()
                } while input.first.map(configuration.isWhitespaceCharacter) == true
                continue parseLoop
            }
            for prefix in configuration.commentSyntax.singleLinePrefixes {
                if input.starts(with: prefix) {
                    try SQLComment<Input>(syntax: configuration.commentSyntax).parse(&input)
                    continue parseLoop
                }
            }
            for delimiter in configuration.commentSyntax.blockDelimiters {
                if input.starts(with: delimiter.opening) {
                    try SQLComment<Input>(syntax: configuration.commentSyntax).parse(&input)
                    continue parseLoop
                }
            }
            break parseLoop
        }
    }
}
