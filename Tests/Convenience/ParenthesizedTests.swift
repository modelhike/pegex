import PegexBuilder
import Testing

@Suite("ParenthesizedTests")
struct ParenthesizedTests {
    @Test func parenthesizedContent() {
        let parser = Parenthesized {
            Prefix { $0.isLetter }
        }
        var input = "(hello)"[...]
        let result = try? parser.parse(&input)
        #expect(result.map { String($0) } == "hello")
    }

    @Test func parenthesizedWithNumber() {
        let parser = Parenthesized {
            IntegerLiteral()
        }
        var input = "(42)"[...]
        let result = try? parser.parse(&input)
        #expect(result == 42)
    }
}
