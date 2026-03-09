import PegexBuilder
import Testing

/// Integration test: basic SELECT parsing using Pegex.
/// Validates: Keyword, Identifier, ImplicitWhitespace, Clause, CommaSeparated, IntegerLiteral.
@Suite("SimpleSelectTests")
struct SimpleSelectTests {
    @Test func simpleSelectColumnsFromTable() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { CommaSeparated { Identifier() } }
                Keyword("FROM")
                Capture { Identifier() }
            }
        }
        var input = "SELECT a,b FROM t"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        let (inner, table) = result!
        let ((_, cols), _) = inner
        #expect(cols == ["a", "b"])
        #expect(table == "t")
    }

    @Test func simpleSelectWithWhere() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { Identifier() }
                Keyword("FROM")
                Capture { Identifier() }
                Clause("WHERE") {
                    OptionalWhitespace()
                    Identifier()
                    OptionalWhitespace()
                    "="
                    OptionalWhitespace()
                    IntegerLiteral()
                }
            }
        }
        var input = "SELECT a FROM t WHERE x = 1"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        let (outer, whereClause) = result!
        let (((_, col), _), table) = outer
        #expect(col == "a")
        #expect(table == "t")
        #expect(whereClause != nil)
        let (colName, value) = whereClause!
        #expect(colName == "x")
        #expect(value == 1)
    }

    @Test func selectStar() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture {
                    ChoiceOf {
                        "*".map { ["*"] }
                        CommaSeparated { Identifier() }
                    }
                }
                Keyword("FROM")
                Capture { Identifier() }
            }
        }
        var input = "SELECT * FROM users"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        let (inner, table) = result!
        let ((_, cols), _) = inner
        #expect(cols == ["*"])
        #expect(table == "users")
    }

    @Test func selectWithInList() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { Identifier() }
                Keyword("FROM")
                Capture { Identifier() }
                Clause("WHERE") {
                    OptionalWhitespace()
                    Identifier()
                    OptionalWhitespace()
                    Keyword("IN")
                    OptionalWhitespace()
                    Parenthesized { CommaSeparated { Identifier() } }
                }
            }
        }
        var input = "SELECT x FROM t WHERE col IN (a,b,c)"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

}
