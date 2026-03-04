import PegexBuilder
import Testing

@Suite("CharTests")
struct CharTests {
    @Test func charDigit() throws {
        let parser = Char.digit
        var input = "123"[...]
        let c = try parser.parse(&input)
        #expect(c == "1")
        #expect(input == "23")
    }

    @Test func charLetter() throws {
        let parser = Char.letter
        var input = "abc"[...]
        let c = try parser.parse(&input)
        #expect(c == "a")
    }

    @Test func charWord() throws {
        let parser = Char.word
        var input = "_x"[...]
        let c = try parser.parse(&input)
        #expect(c == "_")
    }

    @Test func charAny() throws {
        let parser = Char.any
        var input = "!"[...]
        let c = try parser.parse(&input)
        #expect(c == "!")
    }

    @Test func charMatching() throws {
        let parser = Char.matching { $0 == "(" || $0 == ")" }
        var input = "(x)"[...]
        let c = try parser.parse(&input)
        #expect(c == "(")
    }

    @Test func charFailsOnEmpty() {
        let parser = Char.digit
        var input = ""[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }

    @Test func charFailsOnMismatch() {
        let parser = Char.digit
        var input = "x"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }
}
