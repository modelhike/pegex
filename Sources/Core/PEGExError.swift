// PEGExBuilders - Error types for PEG parsing
// No Foundation import - stdlib only for cross-platform support

/// Simple parse failure for PEGEx parsers (ParsingError is internal to swift-parsing).
public struct PEGExParseError: Error, Sendable {
    public let message: String
    @inlinable public init(_ message: String) { self.message = message }
}

/// Errors thrown by PEGEx parsers.
public enum PEGExError: Error {
    /// Parser expected a specific construct but found something else.
    case expected(String, at: Any, underlying: Error)
    /// Negative lookahead failed (inner parser succeeded when it should have failed).
    case negativeLookaheadFailed(at: Any)
    /// Cut was reached; backtracking is disabled and parsing failed after commit.
    case cutCommitted(underlying: Error)
    /// Error recovery produced a result after skipping to sync point.
    case recovery(message: String, skipped: Any)
}

/// Internal error thrown by Cut to signal no-backtrack to ChoiceOf.
/// ChoiceOf catches this and re-throws instead of trying next alternative.
public struct CutError: Error {
    public let underlying: Error
    public let position: Any

    @inlinable
    public init(underlying: Error, position: Any) {
        self.underlying = underlying
        self.position = position
    }
}
