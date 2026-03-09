import PegexBuilder
import Testing

@Suite("ExpectedTests")
struct ExpectedTests {
    @Test func expectedWrapsError() {
        let parser = Expected("integer") {
            Prefix(1...) { $0.isNumber }
        }
        var input = "abc"[...]
        do {
            _ = try parser.parse(&input)
            #expect(Bool(false), "Expected parse to throw")
        } catch let error as PEGExError {
            if case .expected(let label, _, _) = error {
                #expect(label == "integer")
            } else {
                #expect(Bool(false), "Expected PEGExError.expected case")
            }
        } catch {
            #expect(Bool(false), "Expected PEGExError, got \(error)")
        }
    }

    @Test func expectedSucceedsWhenInnerSucceeds() {
        let parser = Expected("digits") {
            Prefix { $0.isNumber }
        }
        var input = "123"[...]
        let result = try? parser.parse(&input)
        #expect(result == "123")
    }
}
