// PEGExBuilders - Pretty-print diagnostics from parse errors
// No Foundation - stdlib only for cross-platform

/// Pretty-prints parse errors with source location.
public struct PEGExDiagnostic {
    public let message: String
    public let line: Int?
    public let column: Int?
    public let snippet: String?
    public let underlying: Error?

    public init(from error: Error, source: String? = nil) {
        self.underlying = error
        if let peg = error as? PEGExError {
            switch peg {
            case .expected(let label, at: let at, underlying: _):
                self.message = "expected \(label)"
                if let sub = at as? Substring, let src = source {
                    let (line, col, snip) = Self.location(in: src, at: sub.startIndex)
                    self.line = line
                    self.column = col
                    self.snippet = snip
                } else {
                    self.line = nil
                    self.column = nil
                    self.snippet = nil
                }
            case .negativeLookaheadFailed(at: _):
                self.message = "negative lookahead failed"
                self.line = nil
                self.column = nil
                self.snippet = nil
            case .cutCommitted(underlying: _):
                self.message = "cut committed; no backtrack"
                self.line = nil
                self.column = nil
                self.snippet = nil
            case .recovery(message: let msg, skipped: _):
                self.message = msg
                self.line = nil
                self.column = nil
                self.snippet = nil
            }
        } else {
            self.message = String(describing: error)
            self.line = nil
            self.column = nil
            self.snippet = nil
        }
    }

    private static func location(in source: String, at index: String.Index) -> (Int, Int, String) {
        var line = 1
        var column = 1
        var i = source.startIndex
        while i < index && i < source.endIndex {
            if source[i] == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            i = source.index(after: i)
        }
        let contextStart = source.index(index, offsetBy: -20, limitedBy: source.startIndex) ?? source.startIndex
        let contextEnd = source.index(index, offsetBy: 40, limitedBy: source.endIndex) ?? source.endIndex
        let snippet = String(source[contextStart..<contextEnd])
            .replacingOccurrences(of: "\n", with: " ")
        return (line, column, snippet)
    }

    public var formatted: String {
        var out = "error: \(message)"
        if let line = line, let col = column {
            out += "\n  at line \(line), column \(col)"
        }
        if let snip = snippet, !snip.isEmpty {
            out += "\n  \(snip)"
            out += "\n  \(String(repeating: " ", count: min(2, snip.count)))^"
        }
        return out
    }
}
