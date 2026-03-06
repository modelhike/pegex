import PegexBuilder
import Parsing
import Testing

@Suite("HeterogeneousChoiceOfTests")
struct HeterogeneousChoiceOfTests {
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
}
