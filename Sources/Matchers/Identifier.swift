// PEGExBuilders - Identifier parser

import Parsing

/// Parsed identifier token with optional delimiter metadata.
public struct ParsedIdentifier: Equatable, Sendable {
    public enum Delimiter: Equatable, Sendable {
        case none
        case paired(open: Character, close: Character)
    }

    public let raw: String
    public let value: String
    public let delimiter: Delimiter

    @inlinable
    public init(raw: String, value: String, delimiter: Delimiter = .none) {
        self.raw = raw
        self.value = value
        self.delimiter = delimiter
    }
}

/// Parses a single identifier component.
public struct Identifier<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    public enum Style {
        case standard
        case sql
        case custom(Configuration)
    }

    public struct RegularForm {
        public var additionalStartCharacters: Set<Character>
        public var additionalContinuingCharacters: Set<Character>
        public var maxLength: Int?

        @inlinable
        public init(
            additionalStartCharacters: Set<Character> = [],
            additionalContinuingCharacters: Set<Character> = [],
            maxLength: Int? = nil
        ) {
            self.additionalStartCharacters = additionalStartCharacters
            self.additionalContinuingCharacters = additionalContinuingCharacters
            self.maxLength = maxLength
        }

        @inlinable
        func isStart(_ character: Character) -> Bool {
            character.isLetter || character == "_" || additionalStartCharacters.contains(character)
        }

        @inlinable
        func isContinuing(_ character: Character) -> Bool {
            character.isLetter
                || character.isNumber
                || character == "_"
                || additionalStartCharacters.contains(character)
                || additionalContinuingCharacters.contains(character)
        }
    }

    public struct DelimitedForm: Equatable, Sendable {
        public enum EscapeStrategy: Equatable, Sendable {
            case none
            case doubledClosingDelimiter
        }

        public var opening: Character
        public var closing: Character
        public var escapeStrategy: EscapeStrategy

        @inlinable
        public init(
            opening: Character,
            closing: Character? = nil,
            escapeStrategy: EscapeStrategy = .none
        ) {
            self.opening = opening
            self.closing = closing ?? opening
            self.escapeStrategy = escapeStrategy
        }
    }

    public struct Configuration {
        public var regularForm: RegularForm?
        public var prefixedForms: [PrefixedForm]
        public var delimitedForms: [DelimitedForm]

        public struct PrefixedForm {
            public var prefix: String
            public var body: RegularForm
            public var requiresBody: Bool

            @inlinable
            public init(
                prefix: String,
                body: RegularForm = RegularForm(),
                requiresBody: Bool = true
            ) {
                self.prefix = prefix
                self.body = body
                self.requiresBody = requiresBody
            }
        }

        @inlinable
        public init(
            regularForm: RegularForm? = RegularForm(),
            prefixedForms: [PrefixedForm] = [],
            delimitedForms: [DelimitedForm] = []
        ) {
            self.regularForm = regularForm
            self.prefixedForms = prefixedForms.sorted { $0.prefix.count > $1.prefix.count }
            self.delimitedForms = delimitedForms
        }

        public static var standard: Self {
            .init()
        }

        public static var sql: Self {
            .init(
                regularForm: .init(
                    additionalContinuingCharacters: Set(["@", "#", "$"])
                ),
                prefixedForms: [
                    .init(
                        prefix: "@@",
                        body: .init(
                            additionalStartCharacters: Set(["#"]),
                            additionalContinuingCharacters: Set(["@", "#", "$"])
                        )
                    ),
                    .init(
                        prefix: "@",
                        body: .init(
                            additionalStartCharacters: Set(["#"]),
                            additionalContinuingCharacters: Set(["@", "#", "$"])
                        )
                    ),
                    .init(
                        prefix: "##",
                        body: .init(additionalContinuingCharacters: Set(["@", "#", "$"]))
                    ),
                    .init(
                        prefix: "#",
                        body: .init(additionalContinuingCharacters: Set(["@", "#", "$"]))
                    ),
                ]
            )
        }
    }

    @usableFromInline
    let configuration: Configuration

    @inlinable
    public init(style: Style = .standard) {
        switch style {
        case .standard:
            self.configuration = .standard
        case .sql:
            self.configuration = .sql
        case .custom(let configuration):
            self.configuration = configuration
        }
    }

    @inlinable
    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> String {
        try IdentifierToken(configuration: configuration).parse(&input).value
    }
}

/// Parses an identifier while preserving delimiter/original-token information.
public struct IdentifierToken<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let configuration: Identifier<Input>.Configuration

    @inlinable
    public init(style: Identifier<Input>.Style = .standard) {
        switch style {
        case .standard:
            self.configuration = .standard
        case .sql:
            self.configuration = .sql
        case .custom(let configuration):
            self.configuration = configuration
        }
    }

    @inlinable
    public init(configuration: Identifier<Input>.Configuration) {
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> ParsedIdentifier {
        for form in configuration.delimitedForms {
            if let parsed = try parseDelimited(form, input: &input) {
                return parsed
            }
        }
        for form in configuration.prefixedForms {
            if let parsed = try parsePrefixed(form, input: &input) {
                return parsed
            }
        }
        if let regularForm = configuration.regularForm {
            return try parseRegular(regularForm, input: &input)
        }
        throw pegexFailure("expected identifier", at: input)
    }

    @inlinable
    func parseDelimited(
        _ form: Identifier<Input>.DelimitedForm,
        input: inout Input
    ) throws -> ParsedIdentifier? {
        guard input.first == form.opening else {
            return nil
        }

        let originalInput = input
        input = input.dropFirst()
        var value = ""
        var raw = String(form.opening)

        while let character = input.first {
            raw.append(character)
            if character == form.closing {
                switch form.escapeStrategy {
                case .none:
                    input = input.dropFirst()
                    return ParsedIdentifier(
                        raw: raw,
                        value: value,
                        delimiter: .paired(open: form.opening, close: form.closing)
                    )
                case .doubledClosingDelimiter:
                    let afterClosing = input.dropFirst()
                    if afterClosing.first == form.closing {
                        value.append(form.closing)
                        raw.append(form.closing)
                        input = afterClosing.dropFirst()
                        continue
                    }
                    input = afterClosing
                    return ParsedIdentifier(
                        raw: raw,
                        value: value,
                        delimiter: .paired(open: form.opening, close: form.closing)
                    )
                }
            }

            value.append(character)
            input = input.dropFirst()
        }

        input = originalInput[originalInput.endIndex...]
        throw pegexFailure("unclosed identifier delimiter", at: input)
    }

    @inlinable
    func parseRegular(
        _ form: Identifier<Input>.RegularForm,
        input: inout Input
    ) throws -> ParsedIdentifier {
        let originalInput = input
        let value = try parseRegularBody(form, input: &input)

        if let maxLength = form.maxLength, value.count > maxLength {
            throw pegexFailure("identifier exceeds maximum length \(maxLength)", at: originalInput)
        }

        return ParsedIdentifier(raw: value, value: value)
    }

    @inlinable
    func parsePrefixed(
        _ form: Identifier<Input>.Configuration.PrefixedForm,
        input: inout Input
    ) throws -> ParsedIdentifier? {
        guard input.starts(with: form.prefix) else {
            return nil
        }

        let originalInput = input
        var remainder = input.dropFirst(form.prefix.count)
        var body = ""

        if !remainder.isEmpty, remainder.first.map(form.body.isStart) == true {
            body = try parseRegularBody(form.body, input: &remainder)
        } else if form.requiresBody {
            throw pegexFailure("expected identifier after prefix \"\(form.prefix)\"", at: originalInput)
        }

        let value = form.prefix + body
        if let maxLength = form.body.maxLength, value.count > maxLength {
            throw pegexFailure("identifier exceeds maximum length \(maxLength)", at: originalInput)
        }

        input = remainder
        return ParsedIdentifier(raw: value, value: value)
    }

    @inlinable
    func parseRegularBody(
        _ form: Identifier<Input>.RegularForm,
        input: inout Input
    ) throws -> String {
        guard let first = input.first, form.isStart(first) else {
            throw pegexFailure("expected identifier", at: input)
        }

        var value = ""
        while let character = input.first, form.isContinuing(character) {
            value.append(character)
            input = input.dropFirst()
        }
        return value
    }
}

/// Fully qualified identifier, such as `schema.table` or `database..object`.
public struct QualifiedIdentifierValue: Equatable, Sendable {
    public let parts: [ParsedIdentifier?]

    @inlinable
    public init(parts: [ParsedIdentifier?]) {
        self.parts = parts
    }

    public var values: [String?] {
        parts.map { $0?.value }
    }
}

public struct QualifiedIdentifier<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let componentParser: IdentifierToken<Input>
    @usableFromInline
    let separator: Character
    @usableFromInline
    let allowsOmittedComponents: Bool
    @usableFromInline
    let maxParts: Int?

    @inlinable
    public init(
        component: IdentifierToken<Input> = IdentifierToken(),
        separator: Character = ".",
        allowsOmittedComponents: Bool = false,
        maxParts: Int? = nil
    ) {
        self.componentParser = component
        self.separator = separator
        self.allowsOmittedComponents = allowsOmittedComponents
        self.maxParts = maxParts
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> QualifiedIdentifierValue {
        var parts: [ParsedIdentifier?] = []
        var consumedAnyPart = false

        func appendPart(_ part: ParsedIdentifier?) throws {
            parts.append(part)
            if let maxParts, parts.count > maxParts {
                throw pegexFailure("identifier has more than \(maxParts) parts", at: input)
            }
        }

        while true {
            if input.first == separator {
                guard allowsOmittedComponents else {
                    throw pegexFailure("unexpected identifier separator", at: input)
                }
                input = input.dropFirst()
                try appendPart(nil)
                continue
            }

            do {
                let parsed = try componentParser.parse(&input)
                try appendPart(parsed)
                consumedAnyPart = true
            } catch {
                if consumedAnyPart || !parts.isEmpty {
                    break
                }
                throw error
            }

            guard input.first == separator else {
                break
            }
            input = input.dropFirst()
            if input.isEmpty {
                throw pegexFailure("expected identifier after separator", at: input)
            }
        }

        guard consumedAnyPart else {
            throw pegexFailure("expected identifier", at: input)
        }
        return QualifiedIdentifierValue(parts: parts)
    }
}
