// PEGExBuilders - Generic delimited list

import Parsing

/// Parses one or more elements separated by a delimiter.
public struct Delimited<Element: Parser, Separator: Parser>: Parser
where Element.Input == Substring, Separator.Input == Substring {
    @usableFromInline
    let element: Element
    @usableFromInline
    let separator: Separator

    @inlinable
    public init(
        separator: Separator,
        @ParserBuilder<Substring> element build: () -> Element
    ) {
        self.element = build()
        self.separator = separator
    }

    @inlinable
    public func parse(_ input: inout Substring) throws -> [Element.Output] {
        var result: [Element.Output] = []
        result.append(try element.parse(&input))
        while true {
            var copy = input
            do {
                _ = try separator.parse(&copy)
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
