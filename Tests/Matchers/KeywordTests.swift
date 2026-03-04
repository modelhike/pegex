import PegexBuilder
import Testing

@Suite("KeywordTests")
struct KeywordTests {
    @Test func keywordCaseInsensitive() throws {
        let parser = Keyword("SELECT")
        var input = "select x"[...]
        try parser.parse(&input)
        #expect(input == " x")
    }

    @Test func keywordExactMatch() throws {
        let parser = Keyword("SELECT")
        var input = "SELECT x"[...]
        try parser.parse(&input)
        #expect(input == " x")
    }

    @Test func keywordWordBoundary() {
        let parser = Keyword("SELECT")
        var input = "SELECTION"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }

    @Test func keywordMultiWord() throws {
        let parser = Keyword("ORDER", "BY")
        var input = "order by x"[...]
        try parser.parse(&input)
        #expect(input == " x")
    }

    @Test func keywordFailsOnWrongInput() {
        let parser = Keyword("SELECT")
        var input = "INSERT x"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }
}
