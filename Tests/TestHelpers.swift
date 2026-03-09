import PegexBuilder

// MARK: - Substring typealiases for cleaner builder syntax
// Use PegexSubstringTypes to avoid repeating <Substring>.

typealias Keyword = PegexSubstringTypes.KeywordSubstring
typealias Prefix = PegexBuilder.Prefix<Substring>
typealias Identifier = PegexSubstringTypes.IdentifierSubstring
typealias IntegerLiteral = PegexSubstringTypes.IntegerLiteralSubstring
typealias FloatLiteral = PegexSubstringTypes.FloatLiteralSubstring
typealias HexLiteral = PegexSubstringTypes.HexLiteralSubstring
typealias StringLiteral = PegexSubstringTypes.StringLiteralSubstring
typealias OptionalWhitespace = PegexSubstringTypes.OptionalWhitespaceSubstring
typealias Whitespace = PegexSubstringTypes.WhitespaceSubstring
typealias Cut = PegexSubstringTypes.CutSubstring
typealias Anchor = PegexSubstringTypes.AnchorSubstring
typealias Char = PegexSubstringTypes.CharSubstring
typealias MemoTable = PegexSubstringTypes.MemoTableSubstring

// MARK: - SQL-style parser helper
/// Reusable parent: Pegex + ImplicitWhitespace. Use for varying child statements.
/// Example: `let parser = sql { Keyword("SELECT"); Capture { Identifier() } }`
func sql<Content: Parser>(
    @ImplicitWhitespaceBuilder<Substring> _ build: () -> Content
) -> Pegex<Substring, ImplicitWhitespace<Substring, Content>>
where Content.Input == Substring {
    Pegex { ImplicitWhitespace(build) }
}
