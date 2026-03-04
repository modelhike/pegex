// PEGExBuilders - One or more occurrences (Many with minimum 1)

import Parsing

/// A parser that runs the inner parser one or more times.
public struct OneOrMore<Input, Element: Parser>: Parser
where Element.Input == Input {
    @usableFromInline
    let element: Element

    @inlinable
    public init(@ParserBuilder<Input> _ build: () -> Element) {
        self.element = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> [Element.Output] {
        var result: [Element.Output] = []
        result.append(try element.parse(&input))
        while true {
            do {
                result.append(try element.parse(&input))
            } catch {
                break
            }
        }
        return result
    }
}
