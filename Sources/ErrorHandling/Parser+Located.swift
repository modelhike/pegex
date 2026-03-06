import Parsing

extension Parser where Input == Substring {
    /// Parses a full source string and converts failures into a location-aware error.
    public func parseWithLocation(_ source: String) throws -> Output {
        var input = source[...]
        do {
            return try parse(&input)
        } catch {
            let diagnostic = PEGExDiagnostic(from: error, source: source)
            if let line = diagnostic.line, let column = diagnostic.column, let offset = diagnostic.offset {
                throw PEGExLocatedError(
                    message: diagnostic.message,
                    expected: diagnostic.expected,
                    location: PEGExSourceLocation(line: line, column: column, offset: offset)
                )
            }
            let location = source.pegexLocation(at: input.startIndex)
            throw PEGExLocatedError(
                message: diagnostic.message,
                expected: diagnostic.expected,
                location: PEGExSourceLocation(line: location.line, column: location.column, offset: location.offset)
            )
        }
    }
}

extension String {
    @usableFromInline
    func pegexLocation(at index: Index) -> (line: Int, column: Int, offset: Int) {
        var line = 1
        var column = 1
        var offset = 0
        var current = startIndex
        while current < index && current < endIndex {
            if self[current] == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            offset += 1
            current = self.index(after: current)
        }
        return (line, column, offset)
    }
}
