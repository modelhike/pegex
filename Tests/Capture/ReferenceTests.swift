import PegexBuilder
import Testing

@Suite("ReferenceTests")
struct ReferenceTests {
    @Test func referenceCapture() throws {
        let colRef = Reference<String>()
        let tableRef = Reference<String>()

        let parser = Pegex {
            Keyword("SELECT")
            " "
            CaptureAs(as: colRef) {
                OneOrMore { Char.word }
            } transform: { String($0) }
            " "
            Keyword("FROM")
            " "
            CaptureAs(as: tableRef) {
                OneOrMore { Char.word }
            } transform: { String($0) }
        }

        _ = try parser.parse("SELECT name FROM users")
        #expect(colRef.get() == "name")
        #expect(tableRef.get() == "users")
    }
}
