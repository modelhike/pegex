// PEGExBuilders - Pretty-print diagnostics from parse errors
// No Foundation - stdlib only for cross-platform

/// Pretty-prints parse errors with source location.
public struct PEGExDiagnostic {
    public let message: String
    public let expected: String?
    public let line: Int?
    public let column: Int?
    public let offset: Int?
    public let snippet: String?
    public let underlying: Error?

    public init(from error: Error, source: String? = nil) {
        self.underlying = error
        func resolveLocation(at position: PEGExPosition) -> (Int?, Int?, Int?, String?) {
            guard let sub = position.rawValue as? Substring, let src = source else {
                return (nil, nil, nil, nil)
            }
            let location = Self.location(in: src, at: sub.startIndex)
            return (location.line, location.column, location.offset, location.snippet)
        }

        if let peg = error as? PEGExError {
            switch peg {
            case .failure(let message, at: let at):
                self.message = message
                self.expected = nil
                let location = resolveLocation(at: at)
                self.line = location.0
                self.column = location.1
                self.offset = location.2
                self.snippet = location.3
            case .expected(let label, at: let at, underlying: _):
                self.message = "expected \(label)"
                self.expected = label
                let location = resolveLocation(at: at)
                self.line = location.0
                self.column = location.1
                self.offset = location.2
                self.snippet = location.3
            case .negativeLookaheadFailed(at: _):
                self.message = "negative lookahead failed"
                self.expected = nil
                self.line = nil
                self.column = nil
                self.offset = nil
                self.snippet = nil
            case .cutCommitted(underlying: _):
                self.message = "cut committed; no backtrack"
                self.expected = nil
                self.line = nil
                self.column = nil
                self.offset = nil
                self.snippet = nil
            case .recovery(message: let msg, skipped: _):
                self.message = msg
                self.expected = nil
                self.line = nil
                self.column = nil
                self.offset = nil
                self.snippet = nil
            }
        } else if let located = error as? PEGExLocatedError {
            self.message = located.expected.map { "expected \($0)" } ?? located.message
            self.expected = located.expected
            self.line = located.location.line
            self.column = located.location.column
            self.offset = located.location.offset
            self.snippet = nil
        } else {
            self.message = String(describing: error)
            self.expected = nil
            self.line = nil
            self.column = nil
            self.offset = nil
            self.snippet = nil
        }
    }

    static func location(in source: String, at index: String.Index) -> (line: Int, column: Int, offset: Int, snippet: String) {
        var line = 1
        var column = 1
        var offset = 0
        var i = source.startIndex
        while i < index && i < source.endIndex {
            if source[i] == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            offset += 1
            i = source.index(after: i)
        }
        // Capture up to 20 chars before and 40 after the error position for context.
        let contextStart = source.index(index, offsetBy: -20, limitedBy: source.startIndex) ?? source.startIndex
        let contextEnd = source.index(index, offsetBy: 40, limitedBy: source.endIndex) ?? source.endIndex
        let snippet = String(source[contextStart..<contextEnd])
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        return (line, column, offset, snippet)
    }

    public var formatted: String {
        var out = "error: \(message)"
        if let line = line, let col = column {
            out += "\n  at line \(line), column \(col)"
            if let offset = offset {
                out += " (offset \(offset))"
            }
        }
        if let snip = snippet, !snip.isEmpty {
            out += "\n  \(snip)"
            // The snippet starts up to 20 chars before the error position; place ^ accordingly.
            let contextLeadLength = min(20, snip.count)
            out += "\n  \(String(repeating: " ", count: contextLeadLength))^"
        }
        return out
    }
}

extension PEGExLocatedError {
    public init(from error: Error, source: String, at position: String.Index) {
        let diagnostic = PEGExDiagnostic(from: error, source: source)
        let location = PEGExDiagnostic.location(in: source, at: position)
        self.init(
            message: diagnostic.message,
            expected: nil,
            location: PEGExSourceLocation(line: location.line, column: location.column, offset: location.offset)
        )
    }
}
