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

    @Test func tracksStartOffsetAndStartLine() throws {
        let splitter = BatchSplitter()
        let source = """
            CREATE TABLE t (c INT)
            GO
            INSERT INTO t VALUES (1)
            GO
            SELECT * FROM t
            """
        let batches = try splitter.split(source)

        #expect(batches.count == 3)
        #expect(batches[0].startOffset == 0)
        #expect(batches[0].startLine == 1)
        #expect(batches[1].startLine == 3)
        #expect(batches[2].startLine == 5)
        // second batch starts right after "CREATE TABLE t (c INT)\nGO\n"
        let expectedOffset = "CREATE TABLE t (c INT)\nGO\n".count
        #expect(batches[1].startOffset == expectedOffset)
    }

    @Test func firstBatchAlwaysHasZeroOffsetAndLineOne() throws {
        let splitter = BatchSplitter()
        let batches = try splitter.split("SELECT 1\nGO\n")
        #expect(batches.count == 1)
        #expect(batches[0].startOffset == 0)
        #expect(batches[0].startLine == 1)
    }

    @Test func trailingBatchHasCorrectStartPosition() throws {
        let splitter = BatchSplitter()
        let source = "SELECT 1\nGO\nSELECT 2"
        let batches = try splitter.split(source)
        #expect(batches.count == 2)
        #expect(batches[1].startOffset == "SELECT 1\nGO\n".count)
        #expect(batches[1].startLine == 3)
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
