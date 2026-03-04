import PegexBuilder
import Parsing
import Testing

@Suite("DelimitedTests")
struct DelimitedTests {
    @Test func commaDelimited() {
        let parser = Delimited(separator: ",") {
            Prefix { $0.isLetter }
        }
        var input = "a,b,c"[...]
        let result = try? parser.parse(&input)
        #expect(result?.map { String($0) } == ["a", "b", "c"])
    }

    @Test func pipeDelimited() {
        let parser = Delimited(separator: "|") {
            Identifier()
        }
        var input = "x|y|z"[...]
        let result = try? parser.parse(&input)
        #expect(result == ["x", "y", "z"])
    }
}
