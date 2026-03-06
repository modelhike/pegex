// PEGExBuilders - Parse many script batches with per-batch results

import Parsing

/// Failure information for one batch parsed by `BatchedParse`.
public struct BatchedParseFailure: Error {
    public let batchIndex: Int
    public let batch: ScriptBatch
    public let underlying: Error

    @inlinable
    public init(batchIndex: Int, batch: ScriptBatch, underlying: Error) {
        self.batchIndex = batchIndex
        self.batch = batch
        self.underlying = underlying
    }
}

/// Parsed outcome for a single batch.
public struct ParsedBatch<Output> {
    public let index: Int
    public let batch: ScriptBatch
    public let output: Output?
    public let failure: BatchedParseFailure?

    @inlinable
    public init(index: Int, batch: ScriptBatch, output: Output? = nil, failure: BatchedParseFailure? = nil) {
        self.index = index
        self.batch = batch
        self.output = output
        self.failure = failure
    }
}

/// Aggregate result for `BatchedParse`.
public struct BatchedParseResult<Output> {
    public let batches: [ParsedBatch<Output>]

    @inlinable
    public init(batches: [ParsedBatch<Output>]) {
        self.batches = batches
    }

    public var outputs: [Output] {
        batches.compactMap(\.output)
    }

    public var failures: [BatchedParseFailure] {
        batches.compactMap(\.failure)
    }
}

/// Runs a `Substring` parser independently over each script batch.
public struct BatchedParse<Child: Parser> where Child.Input == Substring {
    public struct Configuration {
        public var splitter: BatchSplitter.Configuration
        public var requiresFullConsumption: Bool
        public var trailingWhitespace: WhitespaceConfiguration?

        @inlinable
        public init(
            splitter: BatchSplitter.Configuration = .init(),
            requiresFullConsumption: Bool = true,
            trailingWhitespace: WhitespaceConfiguration? = .standard
        ) {
            self.splitter = splitter
            self.requiresFullConsumption = requiresFullConsumption
            self.trailingWhitespace = trailingWhitespace
        }
    }

    @usableFromInline
    let configuration: Configuration
    @usableFromInline
    let child: Child

    @inlinable
    public init(configuration: Configuration = .init(), child: Child) {
        self.configuration = configuration
        self.child = child
    }

    @inlinable
    public init(configuration: Configuration = .init(), @ParserBuilder<Substring> _ build: () -> Child) {
        self.configuration = configuration
        self.child = build()
    }

    public func parse(_ source: String) throws -> BatchedParseResult<Child.Output> {
        let scriptBatches = try BatchSplitter(configuration: configuration.splitter).split(source)
        var results: [ParsedBatch<Child.Output>] = []

        for (index, batch) in scriptBatches.enumerated() {
            results.append(parseBatch(batch, index: index))
        }

        return BatchedParseResult(batches: results)
    }

    func parseBatch(_ batch: ScriptBatch, index: Int) -> ParsedBatch<Child.Output> {
        var input = batch.text[...]

        do {
            let output = try child.parse(&input)
            if let trailingWhitespace = configuration.trailingWhitespace {
                _ = try? Whitespace<Substring>(configuration: trailingWhitespace).parse(&input)
            }
            if configuration.requiresFullConsumption, !input.isEmpty {
                throw trailingInputError(in: batch.text, remaining: input)
            }
            return ParsedBatch(index: index, batch: batch, output: output)
        } catch {
            let located = locate(error, in: batch.text, fallback: input)
            return ParsedBatch(
                index: index,
                batch: batch,
                failure: BatchedParseFailure(batchIndex: index, batch: batch, underlying: located)
            )
        }
    }

    func locate(_ error: Error, in source: String, fallback remaining: Substring) -> Error {
        if error is PEGExLocatedError {
            return error
        }

        let diagnostic = PEGExDiagnostic(from: error, source: source)
        if let line = diagnostic.line, let column = diagnostic.column, let offset = diagnostic.offset {
            return PEGExLocatedError(
                message: diagnostic.message,
                expected: diagnostic.expected,
                location: PEGExSourceLocation(line: line, column: column, offset: offset)
            )
        }

        let location = source.pegexLocation(at: remaining.startIndex)
        return PEGExLocatedError(
            message: diagnostic.message,
            expected: diagnostic.expected,
            location: PEGExSourceLocation(line: location.line, column: location.column, offset: location.offset)
        )
    }

    func trailingInputError(in source: String, remaining: Substring) -> PEGExLocatedError {
        let location = source.pegexLocation(at: remaining.startIndex)
        return PEGExLocatedError(
            message: "unexpected trailing input",
            location: PEGExSourceLocation(line: location.line, column: location.column, offset: location.offset)
        )
    }
}
