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
}
