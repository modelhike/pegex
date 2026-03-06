import PegexBuilder
import Parsing
import Testing

@Suite("HeterogeneousChoiceOfTests")
struct HeterogeneousChoiceOfTests {
    enum Statement: Equatable {
        case select(String)
        case insert(String)
    }

    protocol StatementNode {
        var kind: String { get }
    }

    struct SelectNode: StatementNode {
        let kind = "select"
        let column: String
    }

    struct InsertNode: StatementNode {
        let kind = "insert"
        let table: String
    }

    @Test func heterogeneousChoiceReturnsCommonProtocol() throws {
        let select = Pegex {
            ImplicitWhitespace {
                Keyword("SELECT")
                Capture { Identifier() }
            }
        }
        .eraseOutput { output in
            let (_, column) = output
            return SelectNode(column: column) as any StatementNode
        }

        let insert = Pegex {
            ImplicitWhitespace {
                Keyword("INSERT")
                Capture { Identifier() }
            }
        }
        .eraseOutput { output in
            let (_, table) = output
            return InsertNode(table: table) as any StatementNode
        }

        let parser = HeterogeneousChoiceOf<Substring, any StatementNode>([
            select,
            insert,
        ])

        var input = "INSERT users"[...]
        let result = try parser.parse(&input)
        #expect(result.kind == "insert")
    }

    @Test func eraseOutputHelpsBuildSharedChoiceType() throws {
        let parser = HeterogeneousChoiceOf<Substring, String> {
            Keyword("SELECT").eraseOutput { _ in "select" }
            Keyword("UPDATE").eraseOutput { _ in "update" }
        }

        var input = "update"[...]
        let result = try parser.parse(&input)
        #expect(result == "update")
    }

    @Test func mapToSupportsProtocolBasedNodesWithoutCastNoise() throws {
        let parser = HeterogeneousChoiceOf<Substring, any StatementNode> {
            Pegex {
                ImplicitWhitespace {
                    Skip { Keyword("SELECT") }
                    Capture { Identifier() }
                }
            }
            .mapTo { column -> any StatementNode in
                SelectNode(column: column)
            }

            Pegex {
                ImplicitWhitespace {
                    Skip { Keyword("INSERT") }
                    Capture { Identifier() }
                }
            }
            .mapTo { table -> any StatementNode in
                InsertNode(table: table)
            }
        }

        var input = "SELECT users"[...]
        let result = try parser.parse(&input)
        #expect(result.kind == "select")
    }

    @Test func mapToWorksNicelyWithEnumCaseConstructors() throws {
        let parser = HeterogeneousChoiceOf<Substring, Statement> {
            Pegex {
                ImplicitWhitespace {
                    Keyword("SELECT")
                    Capture { Identifier() }
                }
            }
            .mapTo(Statement.select)

            Pegex {
                ImplicitWhitespace {
                    Keyword("INSERT")
                    Capture { Identifier() }
                }
            }
            .mapTo(Statement.insert)
        }

        var input = "INSERT accounts"[...]
        let result = try parser.parse(&input)
        #expect(result == .insert("accounts"))
    }

    @Test func mapToAlsoWorksWithoutRedundantSkipMarkers() throws {
        let parser = HeterogeneousChoiceOf<Substring, Statement> {
            Pegex {
                ImplicitWhitespace {
                    Keyword("SELECT")
                    Capture { Identifier() }
                }
            }
            .mapTo(Statement.select)

            Pegex {
                ImplicitWhitespace {
                    Keyword("INSERT")
                    Capture { Identifier() }
                }
            }
            .mapTo(Statement.insert)
        }

        var input = "SELECT people"[...]
        let result = try parser.parse(&input)
        #expect(result == .select("people"))
    }
}
