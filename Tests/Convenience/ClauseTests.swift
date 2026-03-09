import PegexBuilder
import Testing

@Suite("ClauseTests")
struct ClauseTests {
    @Test func clausePresent() {
        let parser = Clause("ORDER", "BY") {
            OptionalWhitespace()
            Prefix { $0.isLetter }
        }
        var input = "ORDER BY name"[...]
        let result = try? parser.parse(&input)
        #expect(result.map { String($0) } == "name")
    }

    @Test func clauseAbsent() {
        let parser = Clause("ORDER", "BY") {
            Prefix { $0.isLetter }
        }
        var input = "SELECT x"[...]
        let result = try? parser.parse(&input)
        #expect(result == nil)
        #expect(input == "SELECT x")
    }
}
