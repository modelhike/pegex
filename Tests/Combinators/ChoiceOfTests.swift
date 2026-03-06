import PegexBuilder
import Testing

@Suite("ChoiceOfTests")
struct ChoiceOfTests {
    @Test func choiceOfFirstMatch() throws {
        let parser = ChoiceOf {
            "a"
            "b"
            "c"
        }
        var input = "a"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func choiceOfSecondMatch() throws {
        let parser = ChoiceOf {
            "x"
            "y"
            "z"
        }
        var input = "y"[...]
        try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func choiceOfFails() {
        let parser = ChoiceOf {
            "a"
            "b"
        }
        var input = "c"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }

    @Test func choiceOfWithKeyword() throws {
        let parser = ChoiceOf {
            Keyword("SELECT")
            Keyword("INSERT")
            Keyword("UPDATE")
        }
        var input = "insert x"[...]
        try parser.parse(&input)
        #expect(input == " x")
    }

    @Test func cutPreventsBacktrackingToLaterAlternatives() {
        let parser = ChoiceOf<Substring, String> {
            Pegex({ _ in "abc" }) {
                "ab"
                Cut()
                "c"
            }
            Pegex({ _ in "abd" }) {
                "ab"
                "d"
            }
        }

        var input = "abd"[...]
        #expect(throws: CutError.self) {
            _ = try parser.parse(&input)
        }
    }
}
