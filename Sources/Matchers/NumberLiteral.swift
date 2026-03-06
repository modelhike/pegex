// PEGExBuilders - Number literal parsers

import Parsing

/// Parses integer literals (decimal).
public struct IntegerLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws -> Int {
        var copy = input
        var neg = false
        if let first = copy.first, first == "-" {
            neg = true
            copy = copy.dropFirst()
        } else if let first = copy.first, first == "+" {
            copy = copy.dropFirst()
        }
        var result = 0
        var found = false
        while let c = copy.first, c.isNumber {
            found = true
            result = result * 10 + Int(c.asciiValue! - 48)
            copy = copy.dropFirst()
        }
        guard found else { throw PEGExParseError("expected integer") }
        input = copy
        return neg ? -result : result
    }
}

/// Parses float literals (decimal with optional fraction and exponent).
public struct FloatLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws -> Double {
        var copy = input
        var s = ""
        if let first = copy.first, first == "-" || first == "+" {
            s.append(copy.first!)
            copy = copy.dropFirst()
        }
        while let c = copy.first, c.isNumber {
            s.append(c)
            copy = copy.dropFirst()
        }
        if let c = copy.first, c == "." {
            s.append(c)
            copy = copy.dropFirst()
            while let c = copy.first, c.isNumber {
                s.append(c)
                copy = copy.dropFirst()
            }
        }
        if let c = copy.first, c == "e" || c == "E" {
            s.append(c)
            copy = copy.dropFirst()
            if let c = copy.first, c == "+" || c == "-" {
                s.append(c)
                copy = copy.dropFirst()
            }
            var expFound = false
            while let c = copy.first, c.isNumber {
                expFound = true
                s.append(c)
                copy = copy.dropFirst()
            }
            guard expFound else { throw PEGExParseError("expected exponent digits") }
        }
        guard let value = Double(s) else { throw PEGExParseError("invalid number") }
        input = copy
        return value
    }
}

/// Parses hex literals (0x or 0X prefix).
public struct HexLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws -> Int {
        guard input.count >= 3 else { throw PEGExParseError("expected hex literal") }
        let prefix = String(input.prefix(2))
        guard prefix.lowercased() == "0x" else { throw PEGExParseError("expected 0x prefix") }
        input = input.dropFirst(2)
        var result = 0
        var found = false
        func hexVal(_ c: Character) -> Int? {
            guard let a = c.asciiValue else { return nil }
            if a >= 48 && a <= 57 { return Int(a - 48) }
            if a >= 97 && a <= 102 { return Int(a - 97 + 10) }
            if a >= 65 && a <= 70 { return Int(a - 65 + 10) }
            return nil
        }
        while let c = input.first, let v = hexVal(c) {
            found = true
            result = result * 16 + v
            input = input.dropFirst()
        }
        guard found else { throw PEGExParseError("expected hex digits") }
        return result
    }
}

/// Parses binary literals (0b or 0B prefix).
public struct BinaryLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws -> Int {
        guard input.count >= 3 else { throw PEGExParseError("expected binary literal") }
        let prefix = String(input.prefix(2))
        guard prefix.lowercased() == "0b" else { throw PEGExParseError("expected 0b prefix") }
        input = input.dropFirst(2)
        var result = 0
        var found = false
        while let c = input.first, c == "0" || c == "1" {
            found = true
            result = result * 2 + (c == "1" ? 1 : 0)
            input = input.dropFirst()
        }
        guard found else { throw PEGExParseError("expected binary digits") }
        return result
    }
}

/// Parses money literals with configurable currency symbol and decimal places.
public struct MoneyLiteral<Input: Collection>: Parser
where Input.SubSequence == Input, Input.Element == Character {
    @usableFromInline
    let currencySymbol: Character
    @usableFromInline
    let requiresDecimal: Bool
    @usableFromInline
    let decimalPlaces: Int

    /// Creates a money literal parser.
    /// - Parameters:
    ///   - currencySymbol: Leading currency symbol (e.g. `$`, `€`, `£`)
    ///   - requiresDecimal: Whether a decimal point is required
    ///   - decimalPlaces: Number of decimal places (defaults to 2)
    @inlinable
    public init(currencySymbol: Character = "$", requiresDecimal: Bool = false, decimalPlaces: Int = 2) {
        self.currencySymbol = currencySymbol
        self.requiresDecimal = requiresDecimal
        self.decimalPlaces = decimalPlaces
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Double {
        guard input.first == currencySymbol else {
            throw PEGExParseError("expected currency symbol '\(currencySymbol)'")
        }
        input = input.dropFirst()
        
        var copy = input
        var s = ""
        var negative = false
        
        if let first = copy.first, first == "-" {
            negative = true
            copy = copy.dropFirst()
        } else if let first = copy.first, first == "+" {
            copy = copy.dropFirst()
        }
        
        var foundDigits = false
        while let c = copy.first, c.isNumber {
            foundDigits = true
            s.append(c)
            copy = copy.dropFirst()
        }
        
        var hasDecimal = false
        if let c = copy.first, c == "." {
            hasDecimal = true
            s.append(c)
            copy = copy.dropFirst()
            while let c = copy.first, c.isNumber {
                s.append(c)
                copy = copy.dropFirst()
            }
        }
        
        guard foundDigits || hasDecimal else {
            throw PEGExParseError("expected numeric value after currency symbol")
        }
        
        if requiresDecimal && !hasDecimal {
            throw PEGExParseError("money literal requires decimal point")
        }
        
        guard let value = Double(s) else {
            throw PEGExParseError("invalid money value")
        }
        
        input = copy
        return negative ? -value : value
    }
}
