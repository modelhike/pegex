import PegexBuilder
import Testing

@Suite("IdentifierTests")
struct IdentifierTests {
    @Test func standardIdentifier() {
        let parser = Identifier(style: .standard)
        var input = "hello"[...]
        let result = try? parser.parse(&input)
        #expect(result == "hello")
    }

    @Test func sqlIdentifierWithAt() {
        let parser = Identifier(style: .sql)
        var input = "@variable"[...]
        let result = try? parser.parse(&input)
        #expect(result == "@variable")
    }

    @Test func identifierFailsOnDigitStart() {
        let parser = Identifier()
        var input = "123"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }
}
