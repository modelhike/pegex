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

    @Test func batchedParseCanAllowTrailingInputWhenConfigured() throws {
        let child = Pegex { Int.parser().pullback(\.utf8) }
        let parser = BatchedParse(
            configuration: .init(
                splitter: .init(directive: "GO"),
                requiresFullConsumption: false,
                trailingWhitespace: nil
            ),
            child: child
        )

        let result = try parser.parse(
            """
            1 trailing
            GO
            2 trailing
            GO
            """
        )

        #expect(result.outputs == [1, 2])
        #expect(result.failures.isEmpty)
    }

    @Test func batchedParseProducesLocatedFailures() throws {
        let child = Pegex { Int.parser().pullback(\.utf8) }
        let parser = BatchedParse(
            configuration: .init(splitter: .init(directive: "GO")),
            child: child
        )

        let result = try parser.parse(
            """
            nope
            GO
            """
        )

        #expect(result.failures.count == 1)
        let error = result.failures[0].underlying as? PEGExLocatedError
        #expect(error != nil)
        #expect(error?.location.line == 1)
    }

    @Test func batchedParseSupportsCustomDirectives() throws {
        let child = Pegex { Int.parser().pullback(\.utf8) }
        let parser = BatchedParse(
            configuration: .init(
                splitter: .init(directive: "END", isCaseSensitive: true)
            ),
            child: child
        )

        let result = try parser.parse(
            """
            1
            END
            2
            END
            """
        )

        #expect(result.outputs == [1, 2])
        #expect(result.failures.isEmpty)
    }
}
