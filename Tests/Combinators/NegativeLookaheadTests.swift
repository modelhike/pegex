import PegexBuilder
import Testing

@Suite("NegativeLookaheadTests")
struct NegativeLookaheadTests {
    @Test func negativeLookaheadSucceedsWhenInnerFails() throws {
        let parser = Pegex {
            NegativeLookahead { "xyz" }
            "hello"
        }
        var input = "hello"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func negativeLookaheadFailsWhenInnerSucceeds() {
        let parser = Pegex {
            NegativeLookahead { "x" }
            "y"
        }
        var input = "xy"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }

    @Test func negativeLookaheadDoesNotConsume() throws {
        let parser = Pegex {
            NegativeLookahead { "0" }
            Char.digit
        }
        var input = "1"[...]
        let c: Character = try parser.parse(&input)
        #expect(c == "1")
        #expect(input.isEmpty)
    }
}
