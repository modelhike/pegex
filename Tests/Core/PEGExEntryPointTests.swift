import PegexBuilder
import Testing

@Suite("PegexEntryPointTests")
struct PegexEntryPointTests {
    @Test func basicPegex() throws {
        let parser = Pegex {
            "hello"
        }
        var input = "hello world"[...]
        _ = try parser.parse(&input)
        #expect(input == " world")
    }

    @Test func pegExWithKeywordAndOneOrMore() throws {
        let parser = Pegex {
            Keyword("SELECT")
            " "
            OneOrMore { Char.word }
        }
        let result = try parser.parse("SELECT hello")
        #expect(result.count == 5)  // "hello" = 5 chars
        #expect(String(result) == "hello")
    }

    @Test func pegExWithCapture() throws {
        let parser = Pegex {
            Keyword("SELECT")
            " "
            OneOrMore { Char.word }
        }
        var input = "SELECT name"[...]
        let result: [Character] = try parser.parse(&input)
        #expect(String(result) == "name")
    }
}
