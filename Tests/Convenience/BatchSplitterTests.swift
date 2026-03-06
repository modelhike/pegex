import PegexBuilder
import Testing

@Suite("BatchSplitterTests")
struct BatchSplitterTests {
    @Test func splitsGoBatches() throws {
        let splitter = BatchSplitter()
        let batches = try splitter.split(
            """
            CREATE TABLE t (c INT)
            GO
            INSERT INTO t VALUES (1)
            GO
            """
        )

        #expect(batches.count == 2)
        #expect(batches[0].repeatCount == nil)
        #expect(batches[1].repeatCount == nil)
        #expect(batches[0].text.contains("CREATE TABLE"))
        #expect(batches[1].text.contains("INSERT INTO"))
    }

    @Test func ignoresDirectiveInsideStringLiteral() throws {
        let splitter = BatchSplitter()
        let batches = try splitter.split(
            """
            SELECT 'GO' AS keyword
            GO
            """
        )

        #expect(batches.count == 1)
        #expect(batches[0].text.contains("'GO'"))
    }

    @Test func parsesRepeatCountAndComments() throws {
        let splitter = BatchSplitter()
        let batches = try splitter.split(
            """
            SELECT 1
            GO 100 -- rerun
            """
        )

        #expect(batches.count == 1)
        #expect(batches[0].repeatCount == 100)
    }

    @Test func supportsNestedBlockCommentsAroundDirective() throws {
        let splitter = BatchSplitter()
        let batches = try splitter.split(
            """
            SELECT 1
            /* outer /* inner */ still outer */ GO /* trailing */
            SELECT 2
            """
        )

        #expect(batches.count == 2)
        #expect(batches[0].text.contains("SELECT 1"))
        #expect(batches[1].text.contains("SELECT 2"))
    }

    @Test func throwsForUnclosedBlockComment() {
        let splitter = BatchSplitter()
        #expect(throws: Error.self) {
            _ = try splitter.split(
                """
                SELECT 1
                /* unclosed
                """
            )
        }
    }

    @Test func supportsCustomDirectiveAndCaseSensitivity() throws {
        let splitter = BatchSplitter(
            configuration: .init(
                directive: "END",
                isCaseSensitive: true
            )
        )
        let batches = try splitter.split(
            """
            SELECT 1
            end
            SELECT 2
            END
            """
        )

        #expect(batches.count == 1)
        #expect(batches[0].text.contains("SELECT 1"))
        #expect(batches[0].text.contains("end"))
    }
}
