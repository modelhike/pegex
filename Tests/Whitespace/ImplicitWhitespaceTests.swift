import PegexBuilder
import Testing

@Suite("ImplicitWhitespaceTests")
struct ImplicitWhitespaceTests {
    @Test func implicitWhitespaceBetweenKeywords() throws {
        let parser = ImplicitWhitespace {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT   FROM x"[...]
        _ = try parser.parse(&input)
        #expect(input == " x")
    }

    @Test func whitespaceConsumesComments() throws {
        var input = "  -- comment\n  /* block */  "[...]
        try Whitespace().parse(&input)
        #expect(input.isEmpty)
    }

    @Test func whitespaceUsesCustomCommentSyntax() throws {
        var input = "  // comment\n  #"[...]
        try Whitespace(commentSyntax: .init(singleLinePrefixes: ["//"])).parse(&input)
        #expect(input == "#")
    }

    @Test func implicitWhitespaceUsesCustomCommentSyntax() throws {
        let parser = ImplicitWhitespace(commentSyntax: .init(singleLinePrefixes: ["//"])) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT // between tokens\n FROM tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func whitespaceUsesCustomCharacterMatcher() throws {
        var input = " \t#"[...]
        try Whitespace(configuration: .horizontal(commentSyntax: .init())).parse(&input)
        #expect(input == "#")
    }

    @Test func implicitWhitespaceCanDisableNewlineConsumption() {
        let parser = ImplicitWhitespace(configuration: .horizontal(commentSyntax: .init())) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT\nFROM"[...]
        #expect(throws: Error.self) {
            _ = try parser.parse(&input)
        }
    }

    @Test func implicitWhitespaceCanSkipCommentsWithoutWhitespace() throws {
        let parser = ImplicitWhitespace(configuration: .commentsOnly(commentSyntax: .sql)) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT/* gap */FROM tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func tokenModeUsesCustomWhitespaceConfiguration() throws {
        let parser = TokenMode<Substring, _>(
            .skipWhitespaceAndComments,
            configuration: .commentsOnly(commentSyntax: .sql)
        ) {
            Keyword("SELECT")
        }
        var input = "/* lead */SELECT tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func tokenModeCharacterModeDoesNotSkipLeadingInput() {
        let parser = TokenMode<Substring, _>(.character) {
            Keyword("SELECT")
        }
        var input = "  SELECT"[...]
        #expect(throws: Error.self) {
            _ = try parser.parse(&input)
        }
    }

    @Test func whitespaceCanBeRestrictedToSpecificCharacters() throws {
        var input = "__value"[...]
        try Whitespace(configuration: .characters(["_"], commentSyntax: .init())).parse(&input)
        #expect(input == "value")
    }

    // SQL comment handling in ImplicitWhitespace (TASKS.md verification)
    @Test func sqlLineCommentBetweenKeywords() throws {
        let parser = ImplicitWhitespace(commentSyntax: .sql) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT -- pick columns\nFROM tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func sqlBlockCommentBetweenKeywords() throws {
        let parser = ImplicitWhitespace(commentSyntax: .sql) {
            Keyword("CREATE")
            Keyword("TABLE")
        }
        var input = "CREATE /* this creates a table */ TABLE tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func sqlNestedBlockCommentBetweenKeywords() throws {
        let parser = ImplicitWhitespace(commentSyntax: .sql) {
            Keyword("SELECT")
            Keyword("FROM")
        }
        var input = "SELECT /* outer /* inner */ still outer */ FROM tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }

    @Test func sqlMixedCommentsAndWhitespaceBetweenTokens() throws {
        let parser = ImplicitWhitespace(commentSyntax: .sql) {
            Keyword("INSERT")
            Keyword("INTO")
            Keyword("VALUES")
        }
        var input = "INSERT -- comment\n  INTO /* block */ VALUES tail"[...]
        _ = try parser.parse(&input)
        #expect(input == " tail")
    }
}
