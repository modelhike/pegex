import PegexBuilder
import Testing

@Suite("AnchorTests")
struct AnchorTests {
    @Test func startOfInput() throws {
        let parser = Pegex {
            Anchor.startOfInput
            "x"
        }
        var input = "x"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func endOfInput() throws {
        let parser = Pegex {
            "x"
            Anchor.endOfInput
        }
        var input = "x"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func endOfInputFailsWithRemaining() {
        let parser = Pegex {
            "x"
            Anchor.endOfInput
        }
        var input = "xy"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }

    @Test func endOfLine() throws {
        let parser = Pegex {
            "x"
            Anchor.endOfLine
        }
        var input = "x\n"[...]
        try parser.parse(&input)
        #expect(input == "\n")
    }
}
