import PegexBuilder
import Parsing
import Testing

/// Integration test: nested SELECT subqueries (e.g. WHERE x IN (SELECT ...)).
/// Validates: Recursive, Parenthesized, Clause, ImplicitWhitespace.
@Suite("NestedSubqueryTests")
struct NestedSubqueryTests {
    @Test func nestedSubqueryInWhere() {
        let selectParser = Recursive<Substring, Void> { selectRef in
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { CommaSeparated { Identifier() } }
                Keyword("FROM")
                Capture { Identifier() }
                Clause("WHERE") {
                    OptionalWhitespace()
                    Identifier()
                    OptionalWhitespace()
                    Keyword("IN")
                    OptionalWhitespace()
                    Parenthesized { selectRef }
                }
            }.map { _ in () }.eraseToAnyParser()
        }

        var input = "SELECT a FROM t WHERE x IN (SELECT b FROM t2)"[...]
        let result: Void? = try? selectParser.parse(&input)
        #expect(result != nil)
    }

    @Test func simpleSelectWithoutSubquery() {
        let selectParser = Recursive<Substring, Void> { _ in
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { CommaSeparated { Identifier() } }
                Keyword("FROM")
                Capture { Identifier() }
            }.map { _ in () }.eraseToAnyParser()
        }

        var input = "SELECT x,y FROM orders"[...]
        let result: Void? = try? selectParser.parse(&input)
        #expect(result != nil)
    }

    @Test func subqueryInFrom() {
        let innerSelect = ImplicitWhitespace {
            Keyword("SELECT")
            Capture { Identifier() }
            Keyword("FROM")
            Capture { Identifier() }
        }

        let parser = ImplicitWhitespace {
            Keyword("SELECT")
            Capture { Identifier() }
            Keyword("FROM")
            Parenthesized { innerSelect }
        }

        var input = "SELECT a FROM (SELECT b FROM t2)"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func deeplyNestedSubquery() {
        let selectParser = Recursive<Substring, Void> { selectRef in
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
                    Parenthesized { selectRef }
                }
            }.map { _ in () }.eraseToAnyParser()
        }

        var input = "SELECT a FROM t1 WHERE x IN (SELECT b FROM t2 WHERE y IN (SELECT c FROM t3))"[...]
        let result: Void? = try? selectParser.parse(&input)
        #expect(result != nil)
    }
}
