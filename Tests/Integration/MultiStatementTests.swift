import PegexBuilder
import Testing

/// Integration test: multi-statement parsing (SemicolonSeparated, Bracketed).
/// Validates: SemicolonSeparated, Bracketed, Keyword, Identifier.
@Suite("MultiStatementTests")
struct MultiStatementTests {
    @Test func semicolonSeparatedDeclares() {
        let stmt = ImplicitWhitespace {
            Keyword("DECLARE")
            Capture { Identifier(style: .sql) }
            Keyword("INT")
        }
        let parser = SemicolonSeparated { stmt }
        var input = "DECLARE @a INT;DECLARE @b INT;DECLARE @c INT"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        #expect(result!.count == 3)
        #expect(result![0] == "@a")
        #expect(result![1] == "@b")
        #expect(result![2] == "@c")
    }

    @Test func bracketedColumnName() {
        let parser = Bracketed { Identifier() }
        var input = "[column_name]"[...]
        let result = try? parser.parse(&input)
        #expect(result == "column_name")
    }

    @Test func bracketedWithOptionalWhitespace() {
        let parser = Bracketed {
            OptionalWhitespace()
            Identifier()
            OptionalWhitespace()
        }
        var input = "[ my_col ]"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        #expect(input.isEmpty)
    }
}
