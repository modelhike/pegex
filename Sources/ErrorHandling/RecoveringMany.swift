// PEGExBuilders - Recover and continue across many child parses

import Parsing

/// Result produced by `RecoveringMany`.
public struct RecoveringManyResult<Element> {
    public let elements: [Element]
    public let errors: [Error]

    @inlinable
    public init(elements: [Element], errors: [Error]) {
        self.elements = elements
        self.errors = errors
    }
}

/// Repeatedly parses child elements, records failures, resynchronizes, and continues.
public struct RecoveringMany<Input, Element: Parser, Recovery: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Element.Input == Input, Recovery.Input == Input {
    @usableFromInline
    let element: Element
    @usableFromInline
    let recovery: Recovery

    @inlinable
    public init(
        @ParserBuilder<Input> element buildElement: () -> Element,
        @ParserBuilder<Input> recovery buildRecovery: () -> Recovery
    ) {
        self.element = buildElement()
        self.recovery = buildRecovery()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> RecoveringManyResult<Element.Output> {
        var elements: [Element.Output] = []
        var errors: [Error] = []

        while !input.isEmpty {
            let start = input.startIndex
            var attempt = input

            do {
                let output = try element.parse(&attempt)
                guard attempt.startIndex != start || attempt.isEmpty else {
                    throw PEGExParseError("RecoveringMany child parser must consume input")
                }
                elements.append(output)
                input = attempt
                continue
            } catch {
                errors.append(error)
            }

            var scan = input
            var recovered = false

            while !scan.isEmpty {
                var recoveryAttempt = scan
                do {
                    _ = try recovery.parse(&recoveryAttempt)
                    if recoveryAttempt.startIndex == scan.startIndex {
                        scan = scan.dropFirst()
                        continue
                    }
                    input = recoveryAttempt
                    recovered = true
                    break
                } catch {
                    scan = scan.dropFirst()
                }
            }

            if !recovered {
                input = scan
                break
            }
        }

        return RecoveringManyResult(elements: elements, errors: errors)
    }
}
