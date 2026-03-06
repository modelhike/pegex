// PEGExBuilders - Token mode for whitespace handling

import Parsing

/// Mode for token/whitespace handling.
public enum TokenModeKind {
    /// Skip leading whitespace and comments before each token.
    case skipWhitespaceAndComments
    /// Character mode - no implicit whitespace.
    case character
}

/// Wraps parsers with optional whitespace skipping.
public struct TokenMode<Input, Parsers: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Input.Element == Character, Parsers.Input == Input {
    @usableFromInline
    let mode: TokenModeKind
    @usableFromInline
    let parsers: Parsers
    @usableFromInline
    let whitespaceConfiguration: WhitespaceConfiguration

    public init(
        _ mode: TokenModeKind,
        configuration: WhitespaceConfiguration = .standard,
        @ImplicitWhitespaceBuilder<Input> _ build: () -> Parsers
    ) {
        self.mode = mode
        self.whitespaceConfiguration = configuration
        self.parsers = ImplicitWhitespaceBuilderContext.withConfiguration(configuration) {
            build()
        }
    }

    public init(
        _ mode: TokenModeKind,
        commentSyntax: CommentSyntax,
        @ImplicitWhitespaceBuilder<Input> _ build: () -> Parsers
    ) {
        self.init(mode, configuration: .init(commentSyntax: commentSyntax), build)
    }

    public func parse(_ input: inout Input) throws -> Parsers.Output {
        if case .skipWhitespaceAndComments = mode {
            _ = try? Whitespace<Input>(configuration: whitespaceConfiguration).parse(&input)
        }
        return try parsers.parse(&input)
    }
}
