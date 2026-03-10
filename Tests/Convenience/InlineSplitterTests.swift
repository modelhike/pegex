import Testing
@testable import PegexBuilder

@Suite("InlineSplitter")
struct InlineSplitterTests {
    let splitter = InlineSplitter()

    // MARK: - Basic splitting

    @Test func singleStatementNoDelimiter() throws {
        let result = splitter.split("SELECT 1")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1")
    }

    @Test func twoStatements() throws {
        let result = splitter.split("SELECT 1; SELECT 2")
        #expect(result.count == 2)
        #expect(result[0].text == "SELECT 1")
        #expect(result[1].text == "SELECT 2")
    }

    @Test func trailingDelimiterIsIgnored() throws {
        // A trailing ";" produces an empty trailing segment which is skipped.
        let result = splitter.split("SELECT 1;")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1")
    }

    @Test func emptyInputReturnsNoBatches() throws {
        let result = splitter.split("")
        #expect(result.isEmpty)
    }

    @Test func whitespaceOnlyInputReturnsNoBatches() throws {
        let result = splitter.split("   \n  ")
        #expect(result.isEmpty)
    }

    // MARK: - Trivia trimming

    @Test func leadingWhitespaceIsTrimmed() throws {
        let result = splitter.split("  \n  SELECT 1")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1")
    }

    @Test func trailingWhitespaceIsTrimmed() throws {
        let result = splitter.split("SELECT 1   \n")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1")
    }

    @Test func surroundingWhitespaceIsTrimmed() throws {
        let result = splitter.split("  SELECT 1  ;  SELECT 2  ")
        #expect(result.count == 2)
        #expect(result[0].text == "SELECT 1")
        #expect(result[1].text == "SELECT 2")
    }

    @Test func leadingLineCommentIsTrimmed() throws {
        let result = splitter.split("-- comment\nSELECT 1")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1")
    }

    @Test func leadingBlockCommentIsTrimmed() throws {
        let result = splitter.split("/* header */\nSELECT 1")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1")
    }

    @Test func commentOnlySegmentIsSkipped() throws {
        let result = splitter.split("SELECT 1; -- comment\n; SELECT 2")
        #expect(result.count == 2)
        #expect(result[0].text == "SELECT 1")
        #expect(result[1].text == "SELECT 2")
    }

    // MARK: - Protected regions: strings

    @Test func delimiterInsideSingleQuoteStringIsIgnored() throws {
        let result = splitter.split("SELECT 'a;b' FROM t")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 'a;b' FROM t")
    }

    @Test func doubledSingleQuoteEscapeIsHandled() throws {
        let result = splitter.split("SELECT 'O''Brien'; SELECT 2")
        #expect(result.count == 2)
        #expect(result[0].text == "SELECT 'O''Brien'")
        #expect(result[1].text == "SELECT 2")
    }

    @Test func delimiterInsideDoubleQuoteStringIsIgnored() throws {
        let result = splitter.split(#"SELECT "a;b" FROM t"#)
        #expect(result.count == 1)
        #expect(result[0].text == #"SELECT "a;b" FROM t"#)
    }

    // MARK: - Protected regions: identifiers

    @Test func delimiterInsideBracketedIdentifierIsIgnored() throws {
        let result = splitter.split("SELECT [col;name] FROM t")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT [col;name] FROM t")
    }

    // MARK: - Protected regions: comments

    @Test func delimiterInsideLineCommentIsIgnored() throws {
        let result = splitter.split("SELECT 1 -- split here;\nFROM t")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1 -- split here;\nFROM t")
    }

    @Test func delimiterInsideBlockCommentIsIgnored() throws {
        let result = splitter.split("SELECT 1 /* semi; here */ FROM t")
        #expect(result.count == 1)
        #expect(result[0].text == "SELECT 1 /* semi; here */ FROM t")
    }

    @Test func nestedBlockCommentIsHandled() throws {
        let result = splitter.split("SELECT 1 /* outer /* inner ; */ still */ FROM t; SELECT 2")
        #expect(result.count == 2)
        #expect(result[0].text == "SELECT 1 /* outer /* inner ; */ still */ FROM t")
        #expect(result[1].text == "SELECT 2")
    }

    // MARK: - Source position tracking

    @Test func firstBatchStartsAtGivenOrigin() throws {
        let result = splitter.split("SELECT 1", startingAt: (offset: 0, line: 1, column: 1))
        #expect(result[0].startOffset == 0)
        #expect(result[0].startLine == 1)
        #expect(result[0].startColumn == 1)
    }

    @Test func leadingWhitespaceAdvancesStartPosition() throws {
        // "  SELECT 1" — the "S" is at offset 2, column 3
        let result = splitter.split("  SELECT 1", startingAt: (offset: 0, line: 1, column: 1))
        #expect(result[0].startOffset == 2)
        #expect(result[0].startLine == 1)
        #expect(result[0].startColumn == 3)
    }

    @Test func leadingNewlineAdvancesStartLine() throws {
        // "\nSELECT 1" — "S" is at line 2, column 1, offset 1
        let result = splitter.split("\nSELECT 1", startingAt: (offset: 0, line: 1, column: 1))
        #expect(result[0].startOffset == 1)
        #expect(result[0].startLine == 2)
        #expect(result[0].startColumn == 1)
    }

    @Test func secondStatementPositionIsTrackedAcrossDelimiter() throws {
        // "SELECT 1;\nSELECT 2"
        //  01234567 8 9
        // delimiter at offset 8; newline at 8 (after ;)? No:
        // S=0,E=1,L=2,E=3,C=4,T=5, =6,1=7,;=8,\n=9,S=10
        let result = splitter.split("SELECT 1;\nSELECT 2", startingAt: (offset: 0, line: 1, column: 1))
        #expect(result.count == 2)
        #expect(result[1].startOffset == 10)
        #expect(result[1].startLine == 2)
        #expect(result[1].startColumn == 1)
    }

    @Test func startingAtOffsetIsAddedToAllPositions() throws {
        // Simulates the second batch in a script starting at offset 100, line 5.
        let result = splitter.split("SELECT 1; SELECT 2", startingAt: (offset: 100, line: 5, column: 1))
        #expect(result[0].startOffset == 100)
        #expect(result[0].startLine == 5)
        // "SELECT 2" starts after "SELECT 1; " (10 chars), all on same line
        #expect(result[1].startOffset == 110)
        #expect(result[1].startLine == 5)
        #expect(result[1].startColumn == 11)
    }

    // MARK: - skipsEmptyBatches = false

    @Test func keepEmptyBatchesWhenConfigured() throws {
        let keepEmpty = InlineSplitter(
            configuration: .init(skipsEmptyBatches: false)
        )
        let result = keepEmpty.split(";SELECT 1;")
        #expect(result.count == 3)
        #expect(result[0].text == "")
        #expect(result[1].text == "SELECT 1")
        #expect(result[2].text == "")
    }
}
