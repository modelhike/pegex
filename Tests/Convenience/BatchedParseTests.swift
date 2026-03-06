import PegexBuilder
import Testing

@Suite("BatchedParseTests")
struct BatchedParseTests {
    @Test func batchedParseCollectsOutputsAcrossBatches() throws {
        let child = Pegex { Int.parser().pullback(\.utf8) }
        let parser = BatchedParse(
            configuration: .init(
                splitter: .init(directive: "GO"),
                trailingWhitespace: .standard
            ),
            child: child
        )

        let result = try parser.parse(
            """
            1
            GO
            2
            GO
            """
        )

        #expect(result.outputs == [1, 2])
        #expect(result.failures.isEmpty)
    }

    @Test func batchedParseRecordsFailuresAndContinues() throws {
        let child = Pegex { Int.parser().pullback(\.utf8) }
        let parser = BatchedParse(
            configuration: .init(
                splitter: .init(directive: "GO"),
                trailingWhitespace: .standard
            ),
            child: child
        )

        let result = try parser.parse(
            """
            1
            GO
            abc
            GO
            2
            GO
            """
        )

        #expect(result.outputs == [1, 2])
        #expect(result.failures.count == 1)
        #expect(result.failures[0].batchIndex == 1)
    }
}
