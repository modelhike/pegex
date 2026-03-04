import PegexBuilder
import Testing

@Suite("RecoverTests")
struct RecoverTests {
    @Test func recoverSkipsToSemicolon() {
        var errors: [Error] = []
        let parser = Recover(
            upstream: { "good" },
            recovery: { ";" },
            onError: { err, _ in errors.append(err) }
        )
        var input = "bad stuff ; rest"[...]
        #expect(throws: Error.self) { try parser.parse(&input) }
        #expect(errors.count == 1)
        #expect(input == " rest")
    }

    @Test func recoverSucceedsWhenUpstreamSucceeds() {
        var errors: [Error] = []
        let parser = Recover(
            upstream: { Prefix(2) { $0.isNumber } },
            recovery: { ";" },
            onError: { err, _ in errors.append(err) }
        )
        var input = "12"[...]
        let result = try? parser.parse(&input)
        #expect(result == "12")
        #expect(errors.isEmpty)
    }
}
