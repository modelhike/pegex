import PegexBuilder
import Testing

/// Integration test: stored procedure constructs (IF/ELSE, WHILE, DECLARE).
/// Validates: Keyword, Clause, ImplicitWhitespace.
@Suite("StoredProcedureTests")
struct StoredProcedureTests {
    @Test func declareVariable() {
        let parser = sql {
            Keyword("DECLARE")
            Capture { Identifier(style: .sql) }
            Keyword("INT")
        }

        var input = "DECLARE @count INT"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func ifCondition() {
        let parser = sql {
            Keyword("IF")
            IntegerLiteral()
            ">"
            IntegerLiteral()
        }

        var input = "IF 1>0"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func whileCondition() {
        let parser = sql {
            Keyword("WHILE")
            Identifier()
            ">"
            IntegerLiteral()
        }

        var input = "WHILE x>0"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func printStatement() {
        let parser = sql {
            Keyword("PRINT")
            StringLiteral(quote: "'")
        }

        var input = "PRINT 'hello'"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func declareMultipleVariables() {
        let parser = sql {
            Keyword("DECLARE")
            Capture { CommaSeparated { Identifier(style: .sql) } }
            Keyword("INT")
        }
        var input = "DECLARE @a,@b,@c INT"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        guard let r = result else { return }
        #expect(r == ["@a", "@b", "@c"])
    }
}
