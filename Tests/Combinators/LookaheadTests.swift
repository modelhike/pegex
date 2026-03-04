import PegexBuilder
import Testing

@Suite("LookaheadTests")
struct LookaheadTests {
    @Test func lookaheadSucceedsWithoutConsuming() throws {
        let parser = Pegex {
            Lookahead { "hello" }
            "hello"
        }
        var input = "hello"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func lookaheadDoesNotConsume() throws {
        let parser = Pegex {
            Lookahead { Char.letter }
            Char.letter
        }
        var input = "a"[...]
        let c: Character = try parser.parse(&input)
        #expect(c == "a")
        #expect(input.isEmpty)
    }

    @Test func lookaheadFailsWhenInnerFails() {
        let parser = Pegex {
            Lookahead { "xyz" }
            "hello"
        }
        var input = "hello"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }
}
