// PEGExBuilders - Zero or more occurrences

import Parsing

/// A parser that runs the inner parser zero or more times.
public struct ZeroOrMore<Input, Element: Parser>: Parser
where Element.Input == Input {
    @usableFromInline
    let element: Element

    @inlinable
    public init(
        _ behavior: QuantifierBehavior = .greedy,
        @ParserBuilder<Input> element: () -> Element
    ) {
        self.element = element()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> [Element.Output] {
        var result: [Element.Output] = []
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

