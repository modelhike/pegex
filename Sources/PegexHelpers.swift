// Pegex - RegexBuilder-like DSL for PEG parsers
//
// Export all public types. Individual files are in subdirectories.

import Parsing

// Re-export Parsing types that consumers need, so they never import Parsing directly
public typealias AnyParser = Parsing.AnyParser
public typealias ParserBuilder = Parsing.ParserBuilder
public typealias Prefix = Parsing.Prefix
public typealias Skip = Parsing.Skip
@_exported import protocol Parsing.Parser

/// Substring typealiases for tests; use `PegexSubstringTypes.Keyword` to avoid `Pegex.X` module/struct clash.
/// Uses distinct names (KeywordSubstring etc.) to avoid shadowing module types.
public enum PegexSubstringTypes {
    public typealias KeywordSubstring = Keyword<Substring>
    public typealias IdentifierSubstring = Identifier<Substring>
    public typealias IntegerLiteralSubstring = IntegerLiteral<Substring>
    public typealias FloatLiteralSubstring = FloatLiteral<Substring>
    public typealias HexLiteralSubstring = HexLiteral<Substring>
    public typealias StringLiteralSubstring = StringLiteral<Substring>
    public typealias OptionalWhitespaceSubstring = OptionalWhitespace<Substring>
    public typealias WhitespaceSubstring = Whitespace<Substring>
    public typealias CutSubstring = Cut<Substring>
    public typealias AnchorSubstring = Anchor<Substring>
    public typealias CharSubstring = Char<Substring>
    public typealias MemoTableSubstring = MemoTable<Substring>
}
