import PegexBuilder
import Testing

@Suite("TryCaptureTests")
struct TryCaptureTests {
    @Test func tryCaptureSuccess() throws {
        let parser = Pegex {
            TryCapture {
                OneOrMore { Char.digit }
            } transform: { chars in
                Int(String(chars))
            }
        }
        let result: Int = try parser.parse("42")
        #expect(result == 42)
    }

    @Test func tryCaptureFailure() {
        let parser = Pegex {
            TryCapture {
                OneOrMore { Char.digit }
            } transform: { chars in
                let i = Int(String(chars))!
                return i > 100 ? i : nil
            }
        }
        var input = "42"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
    }
}
