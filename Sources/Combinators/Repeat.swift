// PEGExBuilders - Repeat with count or range

import Parsing

/// A parser that runs the inner parser a specified number of times.
public struct Repeat<Input, Element: Parser>: Parser
where Element.Input == Input {
    @usableFromInline
    let element: Element
    @usableFromInline
    let minimum: Int
    @usableFromInline
    let maximum: Int?

    @inlinable
    public init(
        count: Int,
        @ParserBuilder<Input> element: () -> Element
    ) {
        self.element = element()
        self.minimum = count
        self.maximum = count
    }

    @inlinable
    public init(
        _ range: ClosedRange<Int>,
        @ParserBuilder<Input> element: () -> Element
    ) {
        self.element = element()
        self.minimum = range.lowerBound
        self.maximum = range.upperBound
    }

    @inlinable
    public init(
        _ range: PartialRangeFrom<Int>,
        @ParserBuilder<Input> element: () -> Element
    ) {
        self.element = element()
        self.minimum = range.lowerBound
        self.maximum = nil
    }

    @inlinable
    public init(
        _ range: PartialRangeThrough<Int>,
        @ParserBuilder<Input> element: () -> Element
    ) {
        self.element = element()
        self.minimum = 0
        self.maximum = range.upperBound
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> [Element.Output] {
        var result: [Element.Output] = []
        var count = 0
        while maximum == nil || count < maximum! {
            do {
                result.append(try element.parse(&input))
                count += 1
            } catch {
                break
            }
        }
        guard count >= minimum else {
            throw PEGExParseError("expected at least \(minimum) occurrences, got \(count)")
        }
        if let max = maximum, count > max {
            throw PEGExParseError("expected at most \(max) occurrences")
        }
        return result
    }
}
