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
}
