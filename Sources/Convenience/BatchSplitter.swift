/// Metadata for a single script batch.
public struct ScriptBatch: Equatable, Sendable {
    public let text: String
    public let repeatCount: Int?
    /// Character offset of this batch's first character within the original source string.
    public let startOffset: Int
    /// 1-based line number where this batch begins in the original source string.
    public let startLine: Int
    /// 1-based column number where this batch begins in the original source string.
    public let startColumn: Int

    @inlinable
    public init(
        text: String,
        repeatCount: Int? = nil,
        startOffset: Int = 0,
        startLine: Int = 1,
        startColumn: Int = 1
    ) {
        self.text = text
        self.repeatCount = repeatCount
        self.startOffset = startOffset
        self.startLine = startLine
        self.startColumn = startColumn
    }
}

/// Splits a script into batches using a line-oriented directive such as `GO`.
public struct BatchSplitter: Sendable {
    public struct DelimitedRegion: Equatable, Sendable {
        public let opening: Character
        public let closing: Character
        public let escapeMode: StringLiteral<Substring>.EscapeMode

        @inlinable
        public init(
            opening: Character,
            closing: Character? = nil,
            escapeMode: StringLiteral<Substring>.EscapeMode = .none
        ) {
            self.opening = opening
            self.closing = closing ?? opening
            self.escapeMode = escapeMode
        }
    }

    public struct Configuration: Equatable, Sendable {
        public var directive: String
        public var isCaseSensitive: Bool
        public var allowsRepeatCount: Bool
        public var commentSyntax: CommentSyntax
        public var ignoredDelimitedRegions: [DelimitedRegion]

        @inlinable
        public init(
            directive: String = "GO",
            isCaseSensitive: Bool = false,
            allowsRepeatCount: Bool = true,
            commentSyntax: CommentSyntax = .sql,
            ignoredDelimitedRegions: [DelimitedRegion] = [
                .init(opening: "'", escapeMode: .doubledClosingDelimiter),
                .init(opening: "\"", escapeMode: .doubledClosingDelimiter)
            ]
        ) {
            self.directive = directive
            self.isCaseSensitive = isCaseSensitive
            self.allowsRepeatCount = allowsRepeatCount
            self.commentSyntax = commentSyntax
            self.ignoredDelimitedRegions = ignoredDelimitedRegions
        }
    }

    enum ParserState: Equatable, Sendable {
        case neutral
        case string(DelimitedRegion)
        case blockComment(CommentSyntax.BlockDelimiter, depth: Int)
    }

    public let configuration: Configuration

    struct DirectiveMatch: Equatable, Sendable {
        let repeatCount: Int?
    }

    @inlinable
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    public func split(_ source: String) throws -> [ScriptBatch] {
        var batches: [ScriptBatch] = []
        var batchStart = source.startIndex
        var batchStartOffset = 0
        var batchStartLine = 1
        var lineStart = source.startIndex
        var currentOffset = 0
        var currentLine = 1
        var state: ParserState = .neutral

        while lineStart < source.endIndex {
            let lineEnd = source[lineStart...].firstIndex(where: { $0 == "\n" || $0 == "\r" }) ?? source.endIndex
            let line = source[lineStart..<lineEnd]
            let inspection = inspect(line: line, state: state)
            state = inspection.endingState

            let afterLine = indexAfterLineEnding(in: source, from: lineEnd)
            let lineEndLength = lineEnd < source.endIndex ? lineEndingLength(in: source, at: lineEnd) : 0
            let nextOffset = currentOffset + line.count + lineEndLength

            if state == .neutral, let directive = parseDirective(from: inspection.significantContent) {
                let batchText = String(source[batchStart..<lineStart])
                if !batchText.pegexTrimmed().isEmpty {
                    batches.append(ScriptBatch(
                        text: batchText,
                        repeatCount: directive.repeatCount,
                        startOffset: batchStartOffset,
                        startLine: batchStartLine,
                        startColumn: 1
                    ))
                }
                batchStart = afterLine
                batchStartOffset = nextOffset
                batchStartLine = currentLine + 1
            }

            currentOffset = nextOffset
            currentLine += 1
            lineStart = afterLine
        }

        if case .blockComment = state {
            throw PEGExParseError("unclosed block comment")
        }

        let trailingBatch = String(source[batchStart..<source.endIndex])
        if !trailingBatch.pegexTrimmed().isEmpty {
            batches.append(ScriptBatch(
                text: trailingBatch,
                repeatCount: nil,
                startOffset: batchStartOffset,
                startLine: batchStartLine,
                startColumn: 1
            ))
        }
        return batches
    }

    func inspect(line: Substring, state: ParserState) -> (significantContent: String, endingState: ParserState) {
        var state = state
        var index = line.startIndex
        var significant = ""

        func appendSpaceIfNeeded() {
            if significant.last != " ", !significant.isEmpty {
                significant.append(" ")
            }
        }

        while index < line.endIndex {
            switch state {
            case .neutral:
                let character = line[index]
                if character.isWhitespace {
                    appendSpaceIfNeeded()
                    index = line.index(after: index)
                    continue
                }

                if let prefix = configuration.commentSyntax.singleLinePrefixes.first(where: { line[index...].starts(with: $0) }) {
                    _ = prefix
                    index = line.endIndex
                    continue
                }

                if let block = configuration.commentSyntax.blockDelimiters.first(where: { line[index...].starts(with: $0.opening) }) {
                    state = .blockComment(block, depth: 1)
                    index = line.index(index, offsetBy: block.opening.count)
                    continue
                }

                if let delimiter = configuration.ignoredDelimitedRegions.first(where: { $0.opening == character }) {
                    significant.append("#")
                    state = .string(delimiter)
                    index = line.index(after: index)
                    continue
                }

                significant.append(character)
                index = line.index(after: index)

            case .string(let delimiter):
                guard index < line.endIndex else { break }
                let character = line[index]
                switch delimiter.escapeMode {
                case .character(let escape) where character == escape:
                    let next = line.index(after: index)
                    index = next < line.endIndex ? line.index(after: next) : line.endIndex
                case .doubledClosingDelimiter where character == delimiter.closing:
                    let next = line.index(after: index)
                    if next < line.endIndex, line[next] == delimiter.closing {
                        index = line.index(after: next)
                    } else {
                        state = .neutral
                        index = next
                    }
                default:
                    if character == delimiter.closing {
                        state = .neutral
                    }
                    index = line.index(after: index)
                }

            case .blockComment(let block, let depth):
                if line[index...].starts(with: block.closing) {
                    let newDepth = depth - 1
                    index = line.index(index, offsetBy: block.closing.count)
                    state = newDepth == 0 ? .neutral : .blockComment(block, depth: newDepth)
                    continue
                }
                if block.allowsNesting, line[index...].starts(with: block.opening) {
                    state = .blockComment(block, depth: depth + 1)
                    index = line.index(index, offsetBy: block.opening.count)
                    continue
                }
                index = line.index(after: index)
            }
        }

        return (significant.pegexTrimmed(), state)
    }

    func parseDirective(from line: String) -> DirectiveMatch? {
        guard !line.isEmpty else {
            return nil
        }

        let parts = line.split(whereSeparator: \.isWhitespace)
        guard let directive = parts.first else {
            return nil
        }

        let lhs = configuration.isCaseSensitive ? String(directive) : String(directive).lowercased()
        let rhs = configuration.isCaseSensitive ? configuration.directive : configuration.directive.lowercased()
        guard lhs == rhs else {
            return nil
        }

        guard parts.count <= 2 else {
            return nil
        }
        guard parts.count == 2 else {
            return DirectiveMatch(repeatCount: nil)
        }
        guard configuration.allowsRepeatCount, let count = Int(parts[1]) else {
            return nil
        }
        return DirectiveMatch(repeatCount: count)
    }

    func lineEndingLength(in source: String, at index: String.Index) -> Int {
        guard index < source.endIndex else { return 0 }
        if source[index] == "\r" {
            let next = source.index(after: index)
            return (next < source.endIndex && source[next] == "\n") ? 2 : 1
        }
        return 1
    }

    func indexAfterLineEnding(in source: String, from index: String.Index) -> String.Index {
        guard index < source.endIndex else {
            return index
        }
        let first = source[index]
        if first == "\r" {
            let next = source.index(after: index)
            if next < source.endIndex, source[next] == "\n" {
                return source.index(after: next)
            }
            return next
        }
        if first == "\n" {
            return source.index(after: index)
        }
        return index
    }
}

extension String {
    @usableFromInline
    func pegexTrimmed() -> String {
        var start = startIndex
        var end = endIndex

        while start < end, self[start].isWhitespace {
            start = index(after: start)
        }
        while start < end {
            let previous = index(before: end)
            guard self[previous].isWhitespace else {
                break
            }
            end = previous
        }
        return String(self[start..<end])
    }
}
