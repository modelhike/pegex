// PEGExBuilders - Protocol for named, reusable parser rules

import Parsing

/// A protocol for defining named, reusable parsers with a `body` property.
/// Mirrors swift-parsing's body-style parsers for PEGEx naming clarity.
public protocol PEGExRule: Parser where _Body: Parser, _Body.Input == Input, _Body.Output == Output {
    @ParserBuilder<Input> var body: Body { get }
}

extension PEGExRule where Body: Parser, Body.Input == Input, Body.Output == Output {
    @inlinable
    public func parse(_ input: inout Input) throws -> Output {
        try body.parse(&input)
    }
}
