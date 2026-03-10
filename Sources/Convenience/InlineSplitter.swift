// PEGExBuilders - Inline statement splitter with SQL context awareness

/// Splits a SQL source string at occurrences of a delimiter character
/// (such as `;`) that appear outside quoted strings, delimited identifiers,
/// and comments. Each returned `ScriptBatch` has its `text` stripped of
/// leading and trailing whitespace/comments, with `startOffset`,
/// `startLine`, and `startColumn` pointing to its first meaningful character.
///
/// Unlike `BatchSplitter` (which recognises line-oriented directives like `GO`),
/// `InlineSplitter` handles inline delimiters, making it suitable for splitting
/// individual SQL batches into their constituent statements.
public struct InlineSplitter: Sendable {
    public struct Configuration: Sendable {
        /// The character that separates statements. Defaults to `";"`.
        public var delimiter: Character
        /// Comment syntax used to identify regions to skip. Defaults to `.sql`.
        public var commentSyntax: CommentSyntax
        /// Quoted-string regions whose contents are opaque to the splitter.
        public var stringRegions: [BatchSplitter.DelimitedRegion]
        /// Delimited-identifier regions whose contents are opaque to the splitter.
        public var identifierRegions: [BatchSplitter.DelimitedRegion]
        /// When `true` (the default), segments containing only whitespace or
        /// comments are omitted from the result.
        public var skipsEmptyBatches: Bool

        @inlinable
        public init(
            delimiter: Character = ";",
            commentSyntax: CommentSyntax = .sql,
            stringRegions: [BatchSplitter.DelimitedRegion] = [
                .init(opening: "'", escapeMode: .doubledClosingDelimiter),
                .init(opening: "\"", escapeMode: .doubledClosingDelimiter),
            ],
            identifierRegions: [BatchSplitter.DelimitedRegion] = [
                .init(opening: "[", closing: "]"),
            ],
            skipsEmptyBatches: Bool = true
        ) {
            self.delimiter = delimiter
            self.commentSyntax = commentSyntax
            self.stringRegions = stringRegions
            self.identifierRegions = identifierRegions
            self.skipsEmptyBatches = skipsEmptyBatches
        }
    }

    public let configuration: Configuration

    @inlinable
    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    /// Splits `source` into statement batches.
    ///
    /// - Parameters:
    ///   - source: The SQL text to split (typically a single batch from `BatchSplitter`).
    ///   - start: Absolute position of `source`'s first character in the original
    ///            script. Defaults to `(offset: 0, line: 1, column: 1)`.
    /// - Returns: An array of `ScriptBatch` values, each with `text` trimmed of
    ///   leading/trailing trivia and source-position fields pointing to the first
    ///   meaningful character.
    public func split(
        _ source: String,
        startingAt start: (offset: Int, line: Int, column: Int) = (0, 1, 1)
    ) -> [ScriptBatch] {
        var batches: [ScriptBatch] = []

        // Running absolute position in the original script.
        var absOffset = start.offset
        var absLine = start.line
        var absColumn = start.column

        // Start of the current (not-yet-flushed) segment within `source`.
        var segmentStartAbsOffset = start.offset
        var segmentStartAbsLine = start.line
        var segmentStartAbsColumn = start.column

        // Trivia-trimming state for the current segment.
        var firstMeaningfulIndex: String.Index? = nil
        var firstMeaningfulAbsOffset: Int? = nil
        var firstMeaningfulAbsLine: Int? = nil
        var firstMeaningfulAbsColumn: Int? = nil
        var lastMeaningfulEnd: String.Index? = nil

        // Parser state.
        enum State {
            case neutral
            case lineComment
            case blockComment(CommentSyntax.BlockDelimiter, depth: Int)
            case string(BatchSplitter.DelimitedRegion)
            case identifier(BatchSplitter.DelimitedRegion)
        }
        var state: State = .neutral

        var i = source.startIndex

        // MARK: - Helpers

        func advanceOne() {
            let c = source[i]
            absOffset += 1
            if c == "\n" {
                absLine += 1
                absColumn = 1
            } else {
                absColumn += 1
            }
            i = source.index(after: i)
        }

        func advanceMulti(_ count: Int) {
            for _ in 0..<count { advanceOne() }
        }

        func markMeaningful() {
            if firstMeaningfulIndex == nil {
                firstMeaningfulIndex = i
                firstMeaningfulAbsOffset = absOffset
                firstMeaningfulAbsLine = absLine
                firstMeaningfulAbsColumn = absColumn
            }
        }

        func flushSegment() {
            let trimmedText: String
            if let s = firstMeaningfulIndex, let e = lastMeaningfulEnd {
                trimmedText = String(source[s..<e])
            } else {
                trimmedText = ""
            }
            guard !trimmedText.isEmpty || !configuration.skipsEmptyBatches else { return }
            batches.append(ScriptBatch(
                text: trimmedText,
                repeatCount: nil,
                startOffset: firstMeaningfulAbsOffset ?? segmentStartAbsOffset,
                startLine: firstMeaningfulAbsLine ?? segmentStartAbsLine,
                startColumn: firstMeaningfulAbsColumn ?? segmentStartAbsColumn
            ))
        }

        func resetSegment() {
            segmentStartAbsOffset = absOffset
            segmentStartAbsLine = absLine
            segmentStartAbsColumn = absColumn
            firstMeaningfulIndex = nil
            firstMeaningfulAbsOffset = nil
            firstMeaningfulAbsLine = nil
            firstMeaningfulAbsColumn = nil
            lastMeaningfulEnd = nil
        }

        // MARK: - Main loop

        while i < source.endIndex {
            let c = source[i]

            switch state {
            case .neutral:
                // Line comment?
                for prefix in configuration.commentSyntax.singleLinePrefixes {
                    if source[i...].starts(with: prefix) {
                        state = .lineComment
                        advanceMulti(prefix.count)
                        break
                    }
                }
                if case .lineComment = state { continue }

                // Block comment?
                var enteredBlock = false
                for block in configuration.commentSyntax.blockDelimiters {
                    if source[i...].starts(with: block.opening) {
                        state = .blockComment(block, depth: 1)
                        advanceMulti(block.opening.count)
                        enteredBlock = true
                        break
                    }
                }
                if enteredBlock { continue }

                // Quoted string?
                if let region = configuration.stringRegions.first(where: { $0.opening == c }) {
                    markMeaningful()
                    state = .string(region)
                    advanceOne()
                    continue
                }

                // Delimited identifier?
                if let region = configuration.identifierRegions.first(where: { $0.opening == c }) {
                    markMeaningful()
                    state = .identifier(region)
                    advanceOne()
                    continue
                }

                // Split delimiter?
                if c == configuration.delimiter {
                    flushSegment()
                    advanceOne()
                    resetSegment()
                    continue
                }

                // Regular character.
                if !c.isWhitespace {
                    markMeaningful()
                    lastMeaningfulEnd = source.index(after: i)
                }
                advanceOne()

            case .lineComment:
                if c == "\n" || c == "\r" { state = .neutral }
                advanceOne()

            case .blockComment(let block, let depth):
                if source[i...].starts(with: block.closing) {
                    let newDepth = depth - 1
                    advanceMulti(block.closing.count)
                    state = newDepth == 0 ? .neutral : .blockComment(block, depth: newDepth)
                } else if block.allowsNesting, source[i...].starts(with: block.opening) {
                    advanceMulti(block.opening.count)
                    state = .blockComment(block, depth: depth + 1)
                } else {
                    advanceOne()
                }

            case .string(let region):
                let nextIndex = source.index(after: i)
                switch region.escapeMode {
                case .doubledClosingDelimiter where c == region.closing:
                    advanceOne()
                    if i < source.endIndex, source[i] == region.closing {
                        // Escaped closing delimiter — stay in string.
                        lastMeaningfulEnd = source.index(after: i)
                        advanceOne()
                    } else {
                        // True end of string.
                        lastMeaningfulEnd = i
                        state = .neutral
                    }
                case .character(let escape) where c == escape:
                    advanceOne()
                    if i < source.endIndex {
                        lastMeaningfulEnd = source.index(after: i)
                        advanceOne()
                    }
                default:
                    if c == region.closing {
                        lastMeaningfulEnd = nextIndex
                        state = .neutral
                    } else {
                        lastMeaningfulEnd = nextIndex
                    }
                    advanceOne()
                }

            case .identifier(let region):
                let nextIndex = source.index(after: i)
                if c == region.closing {
                    lastMeaningfulEnd = nextIndex
                    state = .neutral
                } else {
                    lastMeaningfulEnd = nextIndex
                }
                advanceOne()
            }
        }

        // Flush the final segment (content after the last delimiter, or the whole
        // source if no delimiter was found).
        flushSegment()
        return batches
    }
}
