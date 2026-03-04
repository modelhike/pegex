import PegexBuilder
import Testing

@Suite("CaptureTests")
struct CaptureTests {
    @Test func basicCapture() throws {
        let parser = Pegex {
            "x"
            Capture { OneOrMore { Char.digit } }
        }
        let result: [Character] = try parser.parse("x123")
        #expect(String(result) == "123")
    }

    @Test func multipleCaptures() throws {
        let parser = Pegex {
            Capture { OneOrMore { Char.letter } }
            ","
            Capture { OneOrMore { Char.digit } }
        }
        let result: ([Character], [Character]) = try parser.parse("abc,123")
        #expect(String(result.0) == "abc")
        #expect(String(result.1) == "123")
    }
}
