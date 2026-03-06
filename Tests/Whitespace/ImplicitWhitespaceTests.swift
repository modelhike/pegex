import PegexBuilder
import Testing

@Suite("ImplicitWhitespaceTests")
struct ImplicitWhitespaceTests {
    @Test func implicitWhitespaceBetweenKeywords() throws {
        let parser = ImplicitWhitespace {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT   FROM x"[...]
        _ = try parser.parse(&input)
        #expect(input == " x")
    }

    @Test func whitespaceConsumesComments() throws {
        var input = "  -- comment\n  /* block */  "[...]
        try Whitespace().parse(&input)
        #expect(input.isEmpty)
    }

    @Test func whitespaceUsesCustomCommentSyntax() throws {
        var input = "  // comment\n  #"[...]
        try Whitespace(commentSyntax: .init(singleLinePrefixes: ["//"])).parse(&input)
        #expect(input == "#")
    }

    @Test func implicitWhitespaceUsesCustomCommentSyntax() throws {
        let parser = ImplicitWhitespace(commentSyntax: .init(singleLinePrefixes: ["//"])) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT // between tokens\n FROM tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func whitespaceUsesCustomCharacterMatcher() throws {
        var input = " \t#"[...]
        try Whitespace(configuration: .horizontal(commentSyntax: .init())).parse(&input)
        #expect(input == "#")
    }

    @Test func implicitWhitespaceCanDisableNewlineConsumption() {
        let parser = ImplicitWhitespace(configuration: .horizontal(commentSyntax: .init())) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT\nFROM"[...]
        #expect(throws: Error.self) {
            _ = try parser.parse(&input)
        }
    }
}
