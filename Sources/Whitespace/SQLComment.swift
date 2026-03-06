// PEGExBuilders - SQL comment parser

import Parsing

public struct CommentSyntax: Equatable, Sendable {
    public struct BlockDelimiter: Equatable, Sendable {
        public var opening: String
        public var closing: String
        public var allowsNesting: Bool

        @inlinable
        public init(opening: String, closing: String, allowsNesting: Bool = false) {
            self.opening = opening
            self.closing = closing
            self.allowsNesting = allowsNesting
        }
    }

    public var singleLinePrefixes: [String]
    public var blockDelimiters: [BlockDelimiter]

    @inlinable
    public init(
        singleLinePrefixes: [String] = [],
        blockDelimiters: [BlockDelimiter] = []
    ) {
        self.singleLinePrefixes = singleLinePrefixes.sorted { $0.count > $1.count }
        self.blockDelimiters = blockDelimiters.sorted { $0.opening.count > $1.opening.count }
    }

    public static let sql = Self(
        singleLinePrefixes: ["--"],
        blockDelimiters: [
            .init(opening: "/*", closing: "*/", allowsNesting: true)
        ]
    )
}

/// Parses SQL-style comments with configurable single-line and block delimiters.
public struct SQLComment<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let syntax: CommentSyntax

    @inlinable
    public init(syntax: CommentSyntax = .sql) {
        self.syntax = syntax
    }

    @inlinable
    public func parse(_ input: inout Input) throws {
        for prefix in syntax.singleLinePrefixes {
            if input.starts(with: prefix) {
                input = input.dropFirst(prefix.count)
                while let first = input.first, first != "\n", first != "\r" {
                    input = input.dropFirst()
                }
                return
            }
        }

        for block in syntax.blockDelimiters {
            if input.starts(with: block.opening) {
                input = input.dropFirst(block.opening.count)
                var depth = 1
                while depth > 0, !input.isEmpty {
                    if block.allowsNesting, input.starts(with: block.opening) {
                        depth += 1
                        input = input.dropFirst(block.opening.count)
                    } else if input.starts(with: block.closing) {
                        depth -= 1
                        input = input.dropFirst(block.closing.count)
                    } else {
                        input = input.dropFirst()
                    }
                }
                if depth > 0 {
                    throw pegexFailure("unclosed block comment", at: input)
                }
                return
            }
        }

        throw pegexFailure("expected comment", at: input)
    }
}
