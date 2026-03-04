// PEGExBuilders - Position assertions (zero-width)

import Parsing

/// Zero-width position assertions. Consume no input, succeed or fail based on position.
public struct Anchor<Input: Collection & Sendable>: Parser, Sendable
where Input.SubSequence == Input, Input.Element == Character {
    public typealias Output = Void

    public enum Kind: Sendable {
        case startOfInput
        case endOfInput
        case startOfLine
        case endOfLine
        case wordBoundary
    }

    @usableFromInline
    let kind: Kind

    @inlinable
    init(kind: Kind) {
        self.kind = kind
    }

    public static var startOfInput: Anchor {
        Anchor(kind: .startOfInput)
    }

    public static var endOfInput: Anchor {
        Anchor(kind: .endOfInput)
    }

    public static var startOfLine: Anchor {
        Anchor(kind: .startOfLine)
    }

    public static var endOfLine: Anchor {
        Anchor(kind: .endOfLine)
    }

    public static var wordBoundary: Anchor {
        Anchor(kind: .wordBoundary)
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Void {
        switch kind {
        case .startOfInput:
            try parseStartOfInput(&input)
        case .endOfInput:
            guard input.isEmpty else {
                throw PEGExParseError("expected end of input")
            }
        case .startOfLine:
            try parseStartOfLine(&input)
        case .endOfLine:
            try parseEndOfLine(&input)
        case .wordBoundary:
            try parseWordBoundary(&input)
        }
    }
}

extension Anchor {
    @inlinable
    func parseStartOfInput(_ input: inout Input) throws {
        if let substr = _castToSubstring(&input) {
            guard substr.startIndex == substr.base.startIndex else {
                throw PEGExParseError("expected start of input")
            }
        }
        // For non-Substring, we cannot verify - succeed when used as first parser
    }

    @inlinable
    func parseStartOfLine(_ input: inout Input) throws {
        if let substr = _castToSubstring(&input) {
            if substr.isEmpty { return }
            if substr.startIndex == substr.base.startIndex { return }
            let idx = substr.base.index(before: substr.startIndex)
            let prev = substr.base[idx]
            if prev == "\n" || prev == "\r" { return }
        }
        return
    }

    @inlinable
    func parseEndOfLine(_ input: inout Input) throws {
        if input.isEmpty { return }
        if input.first == "\n" || input.first == "\r" { return }
        throw PEGExParseError("expected end of line")
    }

    @inlinable
    func parseWordBoundary(_ input: inout Input) throws {
        func isWordChar(_ c: Character) -> Bool {
            c.isLetter || c.isNumber || c == "_"
        }
        if input.isEmpty { return }
        if let substr = _castToSubstring(&input) {
            let atBegin = substr.startIndex == substr.base.startIndex
            if atBegin { return }
            let prevIdx = substr.base.index(before: substr.startIndex)
            let prevIsWord = isWordChar(substr.base[prevIdx])
            let currIsWord = substr.first.map(isWordChar) ?? false
            if prevIsWord != currIsWord { return }
        }
        return
    }

    @usableFromInline
    @inline(__always)
    func _castToSubstring(_ input: inout Input) -> Substring? {
        (input as? Substring)
    }
}
