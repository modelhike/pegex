// PEGExBuilders - Convenience whitespace-wrapping extensions on Parser

import Parsing

extension Parser where Input == Substring {
    /// Returns a parser that consumes optional whitespace **before** this parser,
    /// then runs this parser.
    ///
    /// Useful for optional clauses that may be preceded by arbitrary whitespace:
    /// ```swift
    /// whereClause.leadTrimmed()   // skips leading spaces/newlines
    /// ```
    @inlinable
    public func leadTrimmed() -> some Parser<Substring, Output> {
        Pegex {
            OptionalWhitespace<Substring>()
            self
        }
    }

    /// Returns a parser that consumes optional whitespace **both before and after**
    /// this parser.
    ///
    /// Useful inside comma-separated lists or other contexts where a single value
    /// may have surrounding spaces:
    /// ```swift
    /// CommaSeparated { Identifier<Substring>().trimmed() }
    /// ```
    @inlinable
    public func trimmed() -> some Parser<Substring, Output> {
        Pegex {
            OptionalWhitespace<Substring>()
            self
            OptionalWhitespace<Substring>()
        }
    }
}
