import PegexBuilder
import Testing

@Suite("OneTests")
struct OneTests {
    @Test func oneMatchesSingle() throws {
        let parser = One { Char.digit }
        var input = "1"[...]
        let c: Character = try parser.parse(&input)
        #expect(c == "1")
        #expect(input.isEmpty)
    }

    @Test func oneFailsOnEmpty() {
        let parser = One { Char.digit }
        var input = ""[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }
}
