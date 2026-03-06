// PEGExBuilders - Auto whitespace insertion

import Parsing

/// Wraps a parser block with implicit whitespace between each parser.
public struct ImplicitWhitespace<Input, Parsers: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Input.Element == Character, Parsers.Input == Input {
    @usableFromInline
    let parsers: Parsers
    @usableFromInline
    let whitespaceConfiguration: WhitespaceConfiguration

    public init(
        input inputType: Input.Type,
        configuration: WhitespaceConfiguration = .standard,
        @ImplicitWhitespaceBuilder<Input> _ build: () -> Parsers
    ) {
        self.whitespaceConfiguration = configuration
        self.parsers = ImplicitWhitespaceBuilderContext.withConfiguration(configuration) {
            build()
        }
    }

    public init(
        input inputType: Input.Type,
        commentSyntax: CommentSyntax,
        @ImplicitWhitespaceBuilder<Input> _ build: () -> Parsers
    ) {
        self.init(
            input: inputType,
            configuration: .init(commentSyntax: commentSyntax),
            build
        )
    }

    public func parse(_ input: inout Input) throws -> Parsers.Output {
        try parsers.parse(&input)
    }
}

extension ImplicitWhitespace where Input == Substring {
    /// Convenience initializer for Substring parsing (the common case).
    /// Use `ImplicitWhitespace { ... }` instead of `ImplicitWhitespace(input: Substring.self) { ... }`.
    public init(
        @ImplicitWhitespaceBuilder<Substring> _ build: () -> Parsers
    ) {
        self.init(configuration: .standard, build)
    }

    /// Convenience initializer for Substring parsing (the common case).
    /// Use `ImplicitWhitespace { ... }` instead of `ImplicitWhitespace(input: Substring.self) { ... }`.
    public init(
        configuration: WhitespaceConfiguration,
        @ImplicitWhitespaceBuilder<Substring> _ build: () -> Parsers
    ) {
        self.whitespaceConfiguration = configuration
        self.parsers = ImplicitWhitespaceBuilderContext.withConfiguration(configuration) {
            build()
        }
    }

    /// Convenience initializer for Substring parsing (the common case).
    /// Use `ImplicitWhitespace { ... }` instead of `ImplicitWhitespace(input: Substring.self) { ... }`.
    public init(
        commentSyntax: CommentSyntax,
        @ImplicitWhitespaceBuilder<Substring> _ build: () -> Parsers
    ) {
        self.init(configuration: .init(commentSyntax: commentSyntax), build)
    }
}
