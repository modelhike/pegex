import PegexBuilder
import Parsing
import Testing

@Suite("RecoveringManyTests")
struct RecoveringManyTests {
    @Test func recoveringManyContinuesAfterRecoverableFailures() throws {
        let element = Pegex {
            Capture { Prefix(1...) { $0.isLowercase } }
            ";"
        }

        let parser = RecoveringMany(
            element: { element },
            recovery: { ";" }
        )

        var input = "alpha;BAD;beta;"[...]
        let result = try parser.parse(&input)

        #expect(result.elements == ["alpha", "beta"])
        #expect(result.errors.count == 1)
        #expect(input.isEmpty)
    }

    @Test func recoveringManyStopsWhenRecoveryCannotBeFound() throws {
        let element = Pegex {
            Capture { Prefix(1...) { $0.isLowercase } }
            ";"
        }

        let parser = RecoveringMany(
            element: { element },
            recovery: { ";" }
        )

        var input = "alpha;BAD"[...]
        let result = try parser.parse(&input)

        #expect(result.elements == ["alpha"])
        #expect(result.errors.count == 1)
        #expect(input.isEmpty)
    }

    @Test func recoveringManySupportsStructuredRecoveryMarkers() throws {
        let element = Pegex {
            Capture { Prefix(1...) { $0.isLetter } }
            ";"
        }

        let parser = RecoveringMany(
            element: { element },
            recovery: { "RESYNC;" }
        )

        var input = "alpha;123RESYNC;beta;"[...]
        let result = try parser.parse(&input)

        #expect(result.elements == ["alpha", "beta"])
        #expect(result.errors.count == 1)
        #expect(input.isEmpty)
    }
}
