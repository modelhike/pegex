// PEGExBuilders - Comma-separated list

import Parsing

/// Parses one or more elements separated by commas.
public struct CommaSeparated<Element: Parser>: Parser
where Element.Input == Substring {
    @usableFromInline
    let element: Element

    @inlinable
    public init(@ParserBuilder<Substring> _ build: () -> Element) {
        self.element = build()
    }

    @inlinable
    public func parse(_ input: inout Substring) throws -> [Element.Output] {
        var result: [Element.Output] = []
        result.append(try element.parse(&input))
        while true {
            var copy = input
            do {
                _ = try ",".parse(&copy)
                let next = try element.parse(&copy)
                input = copy
                result.append(next)
            } catch {
                break
            }
        }
        return result
    }
}
