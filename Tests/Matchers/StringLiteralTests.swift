import PegexBuilder
import Testing

@Suite("StringLiteralTests")
struct StringLiteralTests {
    @Test func basicStringLiteral() {
        let parser = StringLiteral()
        var input = "\"hello\""[...]
        let result = try? parser.parse(&input)
        #expect(result == "hello")
    }

    @Test func stringLiteralWithEscape() {
        let parser = StringLiteral()
        var input = "\"hi\\\"there\""[...]
        let result = try? parser.parse(&input)
        #expect(result == "hi\"there")
    }

    @Test func stringLiteralSingleQuote() {
        let parser = StringLiteral(quote: "'")
        var input = "'test'"[...]
        let result = try? parser.parse(&input)
        #expect(result == "test")
    }

    @Test func stringLiteralMultipleQuotes() {
        let parser = StringLiteral(quotes: "\"", "'", "`")
        var input1 = "\"double\""[...]
        #expect((try? parser.parse(&input1)) == "double")
        var input2 = "'single'"[...]
        #expect((try? parser.parse(&input2)) == "single")
        var input3 = "`backtick`"[...]
        #expect((try? parser.parse(&input3)) == "backtick")
    }
}
