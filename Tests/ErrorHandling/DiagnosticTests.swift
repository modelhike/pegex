import PegexBuilder
import Testing

@Suite("DiagnosticTests")
struct DiagnosticTests {
    @Test func diagnosticFromExpectedError() {
        let parser = Expected("keyword") { "SELECT" }
        var input = "SELE"[...]
        do {
            _ = try parser.parse(&input)
        } catch {
            let diag = PEGExDiagnostic(from: error, source: "SELE")
            #expect(diag.message.contains("keyword"))
            #expect(diag.line != nil)
            #expect(diag.column != nil)
        }
    }

    @Test func diagnosticFormatted() {
        let diag = PEGExDiagnostic(from: PEGExError.expected("x", at: "abc"[...], underlying: PEGExParseError("fail")))
        let formatted = diag.formatted
        #expect(formatted.contains("expected x"))
    }
}
