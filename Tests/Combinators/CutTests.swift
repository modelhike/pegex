import PegexBuilder
import Testing

@Suite("CutTests")
struct CutTests {
    @Test func cutSucceedsWithoutConsuming() throws {
        let parser = Pegex {
            "x"
            Cut()
            "y"
        }
        var input = "xy"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func cutInSequence() throws {
        let parser = Pegex {
            Keyword("SELECT")
            Cut()
            " "
            OneOrMore { Char.word }
        }
        let result = try parser.parse("SELECT name")
        #expect(String(result) == "name")
    }
}
