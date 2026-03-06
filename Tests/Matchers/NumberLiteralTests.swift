import PegexBuilder
import Testing

@Suite("NumberLiteralTests")
struct NumberLiteralTests {
    @Test func integerLiteral() {
        let parser = IntegerLiteral()
        var input = "42"[...]
        let result = try? parser.parse(&input)
        #expect(result == 42)
    }

    @Test func integerLiteralNegative() {
        let parser = IntegerLiteral()
        var input = "-99"[...]
        let result = try? parser.parse(&input)
        #expect(result == -99)
    }

    @Test func floatLiteral() {
        let parser = FloatLiteral()
        var input = "3.14"[...]
        let result = try? parser.parse(&input)
        #expect(result == 3.14)
    }

    @Test func hexLiteral() {
        let parser = HexLiteral()
        var input = "0xFF"[...]
        let result = try? parser.parse(&input)
        #expect(result == 255)
    }

    @Test func hexLiteralLowercase() {
        let parser = HexLiteral()
        var input = "0x1a"[...]
        let result = try? parser.parse(&input)
        #expect(result == 26)
    }

    @Test func binaryLiteral() throws {
        let parser = BinaryLiteral<Substring>()
        var input = "0b101"[...]
        let result = try parser.parse(&input)
        #expect(result == 5)
    }

    @Test func binaryLiteralUppercase() throws {
        let parser = BinaryLiteral<Substring>()
        var input = "0B1101"[...]
        let result = try parser.parse(&input)
        #expect(result == 13)
    }

    @Test func binaryLiteralZero() throws {
        let parser = BinaryLiteral<Substring>()
        var input = "0b0"[...]
        let result = try parser.parse(&input)
        #expect(result == 0)
    }

    @Test func moneyLiteralBasic() throws {
        let parser = MoneyLiteral<Substring>()
        var input = "$123.45"[...]
        let result = try parser.parse(&input)
        #expect(result == 123.45)
    }

    @Test func moneyLiteralNegative() throws {
        let parser = MoneyLiteral<Substring>()
        var input = "$-456.78"[...]
        let result = try parser.parse(&input)
        #expect(result == -456.78)
    }

    @Test func moneyLiteralNoDecimal() throws {
        let parser = MoneyLiteral<Substring>()
        var input = "$100"[...]
        let result = try parser.parse(&input)
        #expect(result == 100.0)
    }

    @Test func moneyLiteralCustomSymbol() throws {
        let parser = MoneyLiteral<Substring>(currencySymbol: "€")
        var input = "€50.00"[...]
        let result = try parser.parse(&input)
        #expect(result == 50.0)
    }

    @Test func moneyLiteralRequiresDecimal() throws {
        let parser = MoneyLiteral<Substring>(requiresDecimal: true)
        var input = "$100"[...]
        #expect(throws: Error.self) {
            _ = try parser.parse(&input)
        }
    }
}
