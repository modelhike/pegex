// PEGExBuilders - Shared whitespace/comment configuration

/// Configures how token gaps are consumed.
public struct WhitespaceConfiguration {
    public typealias CharacterMatcher = @Sendable (Character) -> Bool

    public var commentSyntax: CommentSyntax
    public var isWhitespaceCharacter: CharacterMatcher

    @inlinable
    public init(
        commentSyntax: CommentSyntax = .sql,
        isWhitespaceCharacter: @escaping CharacterMatcher = { $0.isWhitespace }
    ) {
        self.commentSyntax = commentSyntax
        self.isWhitespaceCharacter = isWhitespaceCharacter
    }

    public static var standard: Self {
        Self()
    }

    public static func horizontal(commentSyntax: CommentSyntax = .sql) -> Self {
        Self(commentSyntax: commentSyntax) { character in
            character == " " || character == "\t"
        }
    }

    public static func commentsOnly(commentSyntax: CommentSyntax = .sql) -> Self {
        Self(commentSyntax: commentSyntax) { _ in false }
    }

    public static func characters<S: Swift.Sequence>(
        _ characters: S,
        commentSyntax: CommentSyntax = .sql
    ) -> Self where S.Element == Character {
        let allowed = Set(characters)
        return Self(commentSyntax: commentSyntax) { allowed.contains($0) }
    }
}
