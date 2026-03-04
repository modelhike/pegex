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
}
