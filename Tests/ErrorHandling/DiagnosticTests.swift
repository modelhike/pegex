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
        let diag = PEGExDiagnostic(from: PEGExError.expected("x", at: PEGExPosition("abc"[...]), underlying: PEGExParseError("fail")))
        let formatted = diag.formatted
        #expect(formatted.contains("expected x"))
    }

    @Test func parseWithLocationReportsOffset() {
        let parser = Pegex { "SELECT" }
        #expect(throws: PEGExLocatedError.self) {
            _ = try parser.parseWithLocation("SELE")
        }
    }

    @Test func parseWithLocationPreservesExpectedLabel() {
        let parser = Expected("keyword") { "SELECT" }
        do {
            _ = try parser.parseWithLocation("SELE")
            Issue.record("Expected parseWithLocation to throw")
        } catch let error as PEGExLocatedError {
            #expect(error.expected == "keyword")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
