import PegexBuilder
import Parsing
import Testing

/// Integration test:  SQL constructs.
/// Validates: @@variables, #temp tables, EXEC, PRINT.
@Suite("FullSQLTests")
struct FullSQLTests {
    @Test func globalVariable() {
        let parser = Pegex {
            ImplicitWhitespace {
                ChoiceOf {
                "@@identity"
                "@@rowcount"
                "@@error"
                }
            }
        }

        var input = "@@rowcount"[...]
        let result: Void? = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func tempTableName() {
        let parser = Identifier(style: .sql)
        var input = "#temp"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        #expect(result == "#temp")
    }

    @Test func execStatement() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("EXEC")
                Capture { Identifier() }
            }
        }

        var input = "EXEC my_proc"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func execWithParameters() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("EXEC")
                Capture { Identifier() }
                Optionally {
                    Capture { Parenthesized { CommaSeparated { Identifier() } } }
                }
            }
        }
        var input = "EXEC my_proc (a,b,c)"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
        if let r = result {
            let ((_, proc), params) = r
            #expect(proc == "my_proc")
            #expect(params != nil)
            if let p = params {
                #expect(p == ["a", "b", "c"])
            }
        }
    }

    @Test func printStatement() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("PRINT")
                StringLiteral(quote: "'")
            }
        }

        var input = "PRINT 'hello'"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }

    @Test func selectInto() {
        let parser = Pegex {
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { Identifier() }
                Keyword("INTO")
                Capture { Identifier(style: .sql) }
                Keyword("FROM")
                Capture { Identifier() }
            }
        }

        var input = "SELECT id INTO #temp FROM users"[...]
        let result = try? parser.parse(&input)
        #expect(result != nil)
    }
}
