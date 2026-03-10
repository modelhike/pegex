import PegexBuilder
import Testing

@Suite("IdentifierTests")
struct IdentifierTests {
    @Test func standardIdentifier() {
        let parser = Identifier(style: .standard)
        var input = "hello"[...]
        let result = try? parser.parse(&input)
        #expect(result == "hello")
    }

    @Test func sqlIdentifierWithAt() {
        let parser = Identifier(style: .sql)
        var input = "@variable"[...]
        let result = try? parser.parse(&input)
        #expect(result == "@variable")
    }

    @Test func identifierFailsOnDigitStart() {
        let parser = Identifier()
        var input = "123"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }

    @Test func delimitedIdentifierParsesBracketedContent() throws {
        let parser = Identifier(
            configuration: .init(
                regularForm: .init(additionalStartCharacters: Set(["@", "#"]), additionalContinuingCharacters: Set(["@", "#", "$"])),
                delimitedForms: [
                    .init(opening: "[", closing: "]"),
                    .init(opening: "\"", escapeStrategy: .doubledClosingDelimiter)
                ]
            )
        )
        var input = "[Order Details]"[...]
        let result = try parser.parse(&input)
        #expect(result == "Order Details")
    }

    @Test func identifierTokenPreservesQuotedMetadata() throws {
        let parser = IdentifierToken<Substring>(
            configuration: .init(
                regularForm: nil,
                delimitedForms: [.init(opening: "\"", escapeStrategy: .doubledClosingDelimiter)]
            )
        )
        var input = "\"Table\"\"Name\""[...]
        let result = try parser.parse(&input)
        #expect(result.value == "Table\"Name")
        #expect(result.raw == "\"Table\"\"Name\"")
    }

    @Test func identifierTokenExposesDelimiterMetadata() throws {
        let parser = IdentifierToken<Substring>(
            configuration: .init(
                regularForm: nil,
                delimitedForms: [.init(opening: "[", closing: "]")]
            )
        )
        var input = "[Order Details]"[...]
        let result = try parser.parse(&input)
        #expect(result.delimiter == .paired(open: "[", close: "]"))
    }

    @Test func sqlIdentifierRejectsBarePrefix() {
        let parser = Identifier(style: .sql)
        var input = "@"[...]
        #expect(throws: Error.self) {
            _ = try parser.parse(&input)
        }
    }

    @Test func sqlIdentifierSupportsDoublePrefixes() throws {
        let parser = Identifier(style: .sql)

        var globalVariable = "@@rowcount"[...]
        #expect(try parser.parse(&globalVariable) == "@@rowcount")

        var globalTemp = "##global_temp"[...]
        #expect(try parser.parse(&globalTemp) == "##global_temp")
    }

    @Test func qualifiedIdentifierAllowsOmittedParts() throws {
        let component = IdentifierToken<Substring>(
            configuration: .init(
                regularForm: .init(additionalStartCharacters: Set(["@", "#"]), additionalContinuingCharacters: Set(["@", "#", "$"])),
                delimitedForms: [.init(opening: "[", closing: "]")]
            )
        )
        let parser = QualifiedIdentifier<Substring>(
            component: component,
            allowsOmittedComponents: true,
            maxParts: 4
        )
        var input = "[Order Database]..[Order Details]"[...]
        let result = try parser.parse(&input)
        #expect(result.values.count == 3)
        #expect(result.values[0] == "Order Database")
        #expect(result.values[1] == nil)
        #expect(result.values[2] == "Order Details")
    }

    @Test func customPrefixedIdentifierFormIsGeneric() throws {
        let parser = Identifier(
            configuration: Identifier.Configuration(
                regularForm: Identifier.RegularForm(additionalContinuingCharacters: Set(["-"])),
                prefixedForms: [
                    Identifier.Configuration.PrefixedForm(
                        prefix: "$$",
                        body: Identifier.RegularForm(additionalContinuingCharacters: Set(["_"]))
                    )
                ]
            )
        )
        var input = "$$macro_name"[...]
        let result = try parser.parse(&input)
        #expect(result == "$$macro_name")
    }

    @Test func sqlStyleIncludesBracketedIdentifiers() throws {
        let parser = Identifier(style: .sql)
        var input = "[Order Details]"[...]
        let result = try parser.parse(&input)
        #expect(result == "Order Details")
    }

    @Test func sqlStyleIncludesQuotedIdentifiers() throws {
        let parser = Identifier(style: .sql)
        var input = "\"Column Name\""[...]
        let result = try parser.parse(&input)
        #expect(result == "Column Name")
    }

    @Test func sqlStyleQuotedIdentifierWithDoubledEscape() throws {
        let parser = Identifier(style: .sql)
        var input = "\"Table\"\"Name\""[...]
        let result = try parser.parse(&input)
        #expect(result == "Table\"Name")
    }

    @Test func sqlStyleBracketedWithReservedWord() throws {
        let parser = Identifier(style: .sql)
        var input = "[SELECT]"[...]
        let result = try parser.parse(&input)
        #expect(result == "SELECT")
    }

    @Test func sqlStyleBracketedWithSpaces() throws {
        let parser = Identifier(style: .sql)
        var input = "[Order Details With Spaces]"[...]
        let result = try parser.parse(&input)
        #expect(result == "Order Details With Spaces")
    }

    @Test func sqlStyleHashTempTable() throws {
        let parser = Identifier(style: .sql)
        var input = "#temp_table"[...]
        #expect(try parser.parse(&input) == "#temp_table")
    }

    @Test func sqlStyleDoubleHashGlobalTempTable() throws {
        let parser = Identifier(style: .sql)
        var input = "##global_temp"[...]
        #expect(try parser.parse(&input) == "##global_temp")
    }

    @Test func sqlStyleBracketedIdentifierWithReservedWord() throws {
        let parser = Identifier(style: .sql)
        var input = "[CREATE]"[...]
        #expect(try parser.parse(&input) == "CREATE")
    }

    @Test func sqlStyleQualifiedWithBracketedParts() throws {
        let parser = QualifiedIdentifier<Substring>(
            component: IdentifierToken(style: .sql),
            allowsOmittedComponents: true,
            maxParts: 4
        )
        var input = "[MyDB]..[Order Details]"[...]
        let result = try parser.parse(&input)
        #expect(result.values[0] == "MyDB")
        #expect(result.values[1] == nil)
        #expect(result.values[2] == "Order Details")
    }

    @Test func sqlStyleGlobalVariableAtAt() throws {
        let parser = Identifier(style: .sql)
        var input = "@@version"[...]
        #expect(try parser.parse(&input) == "@@version")
    }
}
