// PEGExBuilders - Error types for PEG parsing
// No Foundation import - stdlib only for cross-platform support

/// Simple parse failure for PEGEx parsers (ParsingError is internal to swift-parsing).
public struct PEGExParseError: Error, Sendable {
    public let message: String
    @inlinable public init(_ message: String) { self.message = message }
}

/// Source position for diagnostics.
public struct PEGExSourceLocation: Equatable, Sendable {
    public let line: Int
    public let column: Int
    public let offset: Int

    @inlinable
    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }
}

/// Parse failure enriched with source position information.
public struct PEGExLocatedError: Error, Sendable {
    public let message: String
    public let expected: String?
    public let location: PEGExSourceLocation

    @inlinable
    public init(message: String, expected: String? = nil, location: PEGExSourceLocation) {
        self.message = message
        self.expected = expected
        self.location = location
    }
}

/// Opaque parser position captured for diagnostics and recovery.
public struct PEGExPosition: @unchecked Sendable {
    @usableFromInline
    let storage: Any

    @inlinable
    public init(_ storage: Any) {
        self.storage = storage
    }

    public var rawValue: Any {
        storage
    }
}

/// Errors thrown by PEGEx parsers.
public enum PEGExError: Error {
    /// Parser failed at a specific input position.
    case failure(String, at: PEGExPosition)
    /// Parser expected a specific construct but found something else.
    case expected(String, at: PEGExPosition, underlying: Error)
    /// Negative lookahead failed (inner parser succeeded when it should have failed).
    case negativeLookaheadFailed(at: PEGExPosition)
    /// Cut was reached; backtracking is disabled and parsing failed after commit.
    case cutCommitted(underlying: Error)
    /// Error recovery produced a result after skipping to sync point.
    case recovery(message: String, skipped: PEGExPosition)
}

/// Internal error thrown by Cut to signal no-backtrack to ChoiceOf.
/// ChoiceOf catches this and re-throws instead of trying next alternative.
public struct CutError: Error {
    public let underlying: Error
    public let position: PEGExPosition

    @inlinable
    public init(underlying: Error, position: PEGExPosition) {
        self.underlying = underlying
        self.position = position
    }
}

@inlinable
public func pegexFailure<Input>(_ message: String, at input: Input) -> PEGExError {
    .failure(message, at: PEGExPosition(input))
}
