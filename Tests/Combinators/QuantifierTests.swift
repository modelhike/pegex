import PegexBuilder
import Testing

@Suite("QuantifierTests")
struct QuantifierTests {
    @Test func zeroOrMoreEmpty() throws {
        let parser = ZeroOrMore { Char.digit }
        var input = "abc"[...]
        let result: [Character] = try parser.parse(&input)
        #expect(result.isEmpty)
        #expect(input == "abc")
    }

    @Test func zeroOrMoreMultiple() throws {
        let parser = ZeroOrMore { Char.digit }
        var input = "123abc"[...]
        let result: [Character] = try parser.parse(&input)
        #expect(result == ["1", "2", "3"])
        #expect(input == "abc")
    }

    @Test func repeatExactCount() throws {
        let parser = Repeat(count: 3) { Char.digit }
        var input = "123"[...]
        let result: [Character] = try parser.parse(&input)
        #expect(result == ["1", "2", "3"])
    }

    @Test func repeatRange() throws {
        let parser = Repeat(2...4) { Char.digit }
        var input = "12"[...]
        let result: [Character] = try parser.parse(&input)
        #expect(result.count == 2)
    }

    @Test func optionallyPresent() throws {
        let parser = Pegex {
            "x"
            Optionally { "y" }
        }
        var input = "xy"[...]
        _ = try parser.parse(&input)
        #expect(input.isEmpty)
    }

    @Test func optionallyAbsent() throws {
        let parser = Pegex {
            "x"
            Optionally { "y" }
        }
        var input = "x"[...]
        _ = try parser.parse(&input)
        #expect(input.isEmpty)
    }
}
