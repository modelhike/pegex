# PegexBuilder — Complete Element Reference

A comprehensive guide to every parser element, combinator, and construct in PegexBuilder. Each section covers API signatures, usage scenarios, and practical examples.

---

## Prerequisites & Input Constraints

Most PegexBuilder parsers require:
- `Input: Collection`
- `Input.SubSequence == Input` (e.g. `Substring` for `String`)
- `Input.Element == Character`

**Substring is the typical choice** for parsing `String` or `Substring` input. Several convenience parsers are **Substring-only**: `CommaSeparated`, `Delimited`, `SemicolonSeparated`, `Parenthesized`, `Braced`, `Bracketed`. Use `Substring` (e.g. `"hello"[...]`) when calling `parse(&input)`.

---

## Table of Contents

1. [Entry Points & Builders](#1-entry-points--builders)
2. [Whitespace & Tokenization](#2-whitespace--tokenization)
3. [Matchers](#3-matchers)
4. [Quantifiers](#4-quantifiers)
5. [Combinators](#5-combinators)
6. [Capture](#6-capture)
7. [Convenience Constructs](#7-convenience-constructs)
8. [Recursion & Precedence](#8-recursion--precedence)
9. [Error Handling](#9-error-handling)
10. [Core Types & Protocols](#10-core-types--protocols)
11. [swift-parsing Companion Types](#11-swift-parsing-companion-types)

---

## 1. Entry Points & Builders

### `Pegex`

The root parser builder. Use `Pegex { ... }` as the entry point for all parsers. Wraps swift-parsing's `Parse` to provide a RegexBuilder-like declarative API.

**Signatures:**
```swift
Pegex { @ParserBuilder content }
Pegex(input: Input.Type) { @ParserBuilder content }
Pegex(_ transform: (Upstream.Output) -> NewOutput) { @ParserBuilder content }  // Map
Pegex(_ output: NewOutput) { @ParserBuilder content }  // MapConstant — constant value
```

**Usage scenarios:**
- Top-level parser definition
- Wrapping any sequence of parsers into a single parser
- Applying inline transforms (Map) or constant output (MapConstant)

**Examples:**
```swift
// Basic literal matching
let parser = Pegex { "hello" }
var input = "hello world"[...]
_ = try parser.parse(&input)  // input becomes " world"

// With transform (Map): first arg is closure, second is builder
let parser = Pegex({ Int(String($0))! }) {
    Prefix { $0.isNumber }
}
var input = "42"[...]
let n: Int = try parser.parse(&input)

// With constant output (MapConstant): first arg is the constant value
let parser = Pegex(()) {
    Keyword("SELECT")
    " *"
}
// Output is always () regardless of input consumed

// Substring convenience (default)
let parser = Pegex {
    Keyword("SELECT")
    Capture { Identifier() }
}
```

---

### `ImplicitWhitespace`

Wraps a parser block so that **optional whitespace and SQL-style comments** are automatically consumed between each adjacent parser. Essential for tokenized languages (SQL, config files, etc.).

**Signatures:**
```swift
ImplicitWhitespace { @ImplicitWhitespaceBuilder content }
ImplicitWhitespace(input: Input.Type) { @ImplicitWhitespaceBuilder content }
```

**Behavior:**
- Between `A` and `B`, `Whitespace` is parsed (spaces, tabs, `--` line comments, `/* */` block comments)
- No explicit `OptionalWhitespace()` calls needed between tokens

**Examples:**
```swift
// SQL: "SELECT  a  ,  b  FROM  users" parses the same as "SELECT a,b FROM users"
let parser = Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")
        Capture { CommaSeparated { Identifier() } }
        Keyword("FROM")
        Capture { Identifier() }
    }
}
var input = "SELECT  a  ,  b  FROM  users"[...]
let (cols, table) = try parser.parse(&input)  // cols: ["a","b"], table: "users"

// With optional clause
let parser = Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")
        Capture { Identifier() }
        Keyword("FROM")
        Capture { Identifier() }
        Clause("WHERE") {
            Identifier()
            "="
            IntegerLiteral()
        }
    }
}
```

---

### `ImplicitWhitespaceBuilder` (Result Builder)

Used implicitly inside `ImplicitWhitespace { ... }`. Composes parsers with automatic whitespace insertion between them. Produces `ImplicitWhitespaceSequence<A, B>` for adjacent parsers. You typically don't reference these types directly.

---

### `PEGExBuilder` (Type Alias)

Type alias for `Parsing.ParserBuilder`. Used for sequential composition of parsers. Inside `Pegex { ... }` and `ParserBuilder` contexts, parsers are composed in sequence.

---

## 2. Whitespace & Tokenization

### `OptionalWhitespace`

Parses **zero or more** whitespace characters (space, tab, etc.). Does **not** consume SQL comments.

**Signature:**
```swift
OptionalWhitespace()
```

**Examples:**
```swift
// Manual spacing between tokens
Pegex {
    Keyword("SELECT")
    OptionalWhitespace()
    Capture { Identifier() }
}
```

---

### `RequiredWhitespace`

Parses **at least one** whitespace character. Fails if no whitespace is present.

**Signature:**
```swift
RequiredWhitespace()
```

**Examples:**
```swift
// Enforce space between multi-word keyword parts
Pegex {
    Keyword("ORDER", "BY")  // internally uses RequiredWhitespace between words
}
```

---

### `Whitespace`

Parses **zero or more** whitespace **and** SQL-style comments (`--` to EOL, `/* ... */` including nested).

**Signature:**
```swift
Whitespace()
```

**Examples:**
```swift
// Used internally by ImplicitWhitespace between parsers
// Can be used explicitly when you need comment-aware skipping
Pegex {
    "SELECT"
    Whitespace()
    Identifier()
}
```

---

### `SQLComment`

Parses a single SQL-style comment. Used internally by `Whitespace`.

**Forms:**
- `--` to end of line
- `/* ... */` (supports nested `/*`)

**Signature:**
```swift
SQLComment()
```

---

### `TokenMode`

Wraps parsers with optional leading whitespace/comment skipping.

**Signature:**
```swift
TokenMode(_ mode: TokenModeKind) { @ImplicitWhitespaceBuilder content }
```

**Modes:**
- `.skipWhitespaceAndComments` — skip `Whitespace` before parsing
- `.character` — no implicit skipping

**Examples:**
```swift
let parser = TokenMode(.skipWhitespaceAndComments) {
    Identifier()
}
```

---

## 3. Matchers

### `Keyword`

Case-insensitive keyword with **word boundary** assertion. After the last word, the next character must NOT be alphanumeric or underscore.

**Signatures:**
```swift
Keyword(_ words: String...)
Keyword(words: [String])
```

**Examples:**
```swift
// Single word
Keyword("SELECT")   // matches "select", "Select", "SELECT"
Keyword("from")     // matches "FROM", "from"
// "selectX" fails — word boundary required

// Multi-word keyword
Keyword("ORDER", "BY")   // matches "ORDER BY", "order by"
Keyword("GROUP", "BY")   // matches "GROUP BY"

// In sequences
Pegex {
    ImplicitWhitespace {
        Keyword("DECLARE")
        Capture { Identifier(style: .sql) }
        Keyword("INT")
    }
}
```

---

### `Identifier`

Parses identifiers (variable names, column names): `[a-zA-Z_][a-zA-Z0-9_]*` or SQL-style with `@`, `#`, `$`.

**Signatures:**
```swift
Identifier(style: Identifier.Style = .standard)
```

**Styles:**
- `.standard` — `[a-zA-Z_][a-zA-Z0-9_]*`
- `.sql` — also allows `@`, `#`, `$` (e.g. `@count`, `#temp`, `$var`)

**Examples:**
```swift
Identifier()                    // "foo", "bar_baz", "x123"
Identifier(style: .sql)         // "@count", "#temp", "$var", "col_name"
```

---

### `Char` (Character Class Parsers)

Single-character parsers. `Char` is a namespace; use static properties/ methods.

**Static properties:**
| Property | Matches |
|----------|---------|
| `Char.digit` | `[0-9]` |
| `Char.letter` | Unicode letter |
| `Char.alphanumeric` | Letter or digit |
| `Char.whitespace` | Space, tab, etc. |
| `Char.newline` | `\n`, `\r\n`, `\r` |
| `Char.any` | Any single character (PEG `.`) |
| `Char.word` | Letter, digit, underscore |
| `Char.hexDigit` | `[0-9a-fA-F]` |

**Static methods:**
```swift
Char.matching(_ predicate: (Character) -> Bool) -> CharParser<Input>
Char.character(_ c: Character) -> CharParser<Input>
```

**Examples:**
```swift
OneOrMore { Char.word }           // "hello"
OneOrMore { Char.digit }          // "12345"
ZeroOrMore { Char.whitespace }    // "   \t  "
Char.any                          // any single char
Char.matching { $0.isLetter }     // custom predicate
Char.character("x")               // exactly "x"
```

---

### `CharIn`

Consumes exactly one character from a set of ranges and/or characters.

**Signatures:**
```swift
CharIn(_ ranges: ClosedRange<Character>...)
CharIn(characters: Character...)
CharIn(ranges: ClosedRange<Character>..., characters: Character...)
```

**Examples:**
```swift
CharIn("a"..."z")                    // lowercase letter
CharIn("0"..."9")                    // digit
CharIn("a"..."z", "A"..."Z")         // any letter
CharIn(characters: "+", "-", "*")    // operators
CharIn(ranges: "0"..."9", characters: ".", "e", "E")  // number chars
```

---

### `CharNotIn`

Consumes exactly one character **not** in the given set.

**Signature:**
```swift
CharNotIn(_ ranges: ClosedRange<Character>..., characters: Character...)
```

**Examples:**
```swift
CharNotIn(characters: "\n", "\r")    // any char except newline
OneOrMore { CharNotIn(characters: "\"") }  // until quote
```

---

### `Anchor`

Zero-width position assertions. Consume no input; succeed or fail based on position.

**Static properties:**
| Property | Meaning |
|----------|---------|
| `Anchor.startOfInput` | At beginning of input |
| `Anchor.endOfInput` | At end of input (input must be empty) |
| `Anchor.startOfLine` | At start of line (after `\n` or start) |
| `Anchor.endOfLine` | Before `\n` or at end |
| `Anchor.wordBoundary` | Between word and non-word char |

**Examples:**
```swift
Pegex {
    Anchor.startOfInput
    Keyword("SELECT")
}
Pegex {
    Identifier()
    Anchor.endOfInput
}
```

---

### `IntegerLiteral`

Parses decimal integers, optional leading `+` or `-`.

**Signature:**
```swift
IntegerLiteral()
```

**Examples:**
```swift
IntegerLiteral()   // "42", "-17", "+0"
```

---

### `FloatLiteral`

Parses decimal floats: optional sign, digits, optional `.` fraction, optional `e`/`E` exponent.

**Signature:**
```swift
FloatLiteral()
```

**Examples:**
```swift
FloatLiteral()   // "3.14", "-1.5e10", "2e-3"
```

---

### `HexLiteral`

Parses hex literals with `0x` or `0X` prefix.

**Signature:**
```swift
HexLiteral()
```

**Examples:**
```swift
HexLiteral()   // "0x1a", "0XFF"
```

---

### `StringLiteral`

Parses quoted strings with configurable quote character(s) and escape.

**Signatures:**
```swift
StringLiteral(quote: Character = "\"", escape: Character? = "\\")
StringLiteral(quotes: [Character], escape: Character? = "\\")
StringLiteral(quotes: Character..., escape: Character? = "\\")
```

**Examples:**
```swift
StringLiteral(quote: "'")              // SQL: 'hello'
StringLiteral(quote: "\"")             // JSON: "hello"
StringLiteral(quotes: "\"", "'", "`")  // Multiple quote types
StringLiteral(quote: "'", escape: nil) // No escape (e.g. '' for SQL)
```

---

## 4. Quantifiers

### `One`

Runs the inner parser exactly once. Use for clarity or when wrapping a single parser in a builder context.

**Signatures:**
```swift
One(_ component: Component)
One { @ParserBuilder content }
```

**Examples:**
```swift
One { Identifier() }
```

---

### `ZeroOrMore`

Zero or more occurrences. Returns `[Element.Output]`. Always greedy (consumes as much as possible).

**Signature:**
```swift
ZeroOrMore(_ behavior: QuantifierBehavior = .greedy) { @ParserBuilder element }
```

**Note:** The `behavior` parameter is accepted for API consistency but is **not yet implemented**; parsing is always greedy.

**Examples:**
```swift
ZeroOrMore { Char.whitespace }
ZeroOrMore { Identifier() }   // list of identifiers
```

---

### `OneOrMore`

One or more occurrences. Returns `[Element.Output]`.

**Signature:**
```swift
OneOrMore { @ParserBuilder element }
```

**Examples:**
```swift
OneOrMore { Char.word }       // at least one word char
OneOrMore { Identifier() }   // non-empty list
```

---

### `Optionally`

Zero or one occurrence. Returns `Output?`. Re-exports `Parsing.Optionally`.

**Signature:**
```swift
Optionally { @ParserBuilder content }
```

**Examples:**
```swift
Optionally { Clause("WHERE") { ... } }
Optionally { Capture { Parenthesized { CommaSeparated { Identifier() } } } }
```

---

### `Repeat`

Bounded repetition. Specify exact count or range.

**Signatures:**
```swift
Repeat(count: Int) { @ParserBuilder element }
Repeat(_ range: ClosedRange<Int>) { @ParserBuilder element }   // e.g. 2...5
Repeat(_ range: PartialRangeFrom<Int>) { @ParserBuilder element }  // e.g. 2...
Repeat(_ range: PartialRangeThrough<Int>) { @ParserBuilder element }  // e.g. ...5
```

**Examples:**
```swift
Repeat(count: 4) { Char.hexDigit }   // exactly 4 hex digits
Repeat(2...5) { Identifier() }     // 2 to 5 identifiers
Repeat(1...) { Char.digit }         // one or more (like OneOrMore)
Repeat(...3) { Char.letter }        // zero to three letters
```

---

### `QuantifierBehavior`

- `.greedy` — consume as much as possible (PEG default)
- `.lazy` — consume as little as possible

**Note:** Only `ZeroOrMore` accepts this parameter; it is not yet used. All quantifiers currently behave greedily.

---

## 5. Combinators

### `ChoiceOf`

Ordered choice (PEG alternative). Tries each branch in order; first success wins. When a branch throws `CutError`, re-throws immediately (no backtracking).

**Signature:**
```swift
ChoiceOf { @OneOfBuilder content }
```

**Examples:**
```swift
ChoiceOf {
    Keyword("SELECT")
    Keyword("INSERT")
    Keyword("UPDATE")
    Keyword("DELETE")
}

ChoiceOf {
    IntegerLiteral().map { Expr.number($0) }
    FloatLiteral().map { Expr.number($0) }
    Identifier().map { Expr.column($0) }
}
```

---

### `Cut`

Zero-width commit marker. Succeeds without consuming input.

**Current status:** Cut is a **placeholder**. The intended PEG semantics: when used inside `ChoiceOf`, if parsing fails *after* Cut, backtracking should be disabled and the error should propagate instead of trying the next alternative. `ChoiceOf` is wired to catch and rethrow `CutError`, but **Cut does not currently throw `CutError`** — nothing in the codebase emits it. So Cut currently has no effect on backtracking; it simply succeeds. Use it for future compatibility or documentation of intent.

**Signature:**
```swift
Cut()
```

**Examples:**
```swift
// Documents intent; no behavioral effect yet
ChoiceOf {
    Keyword("SELECT")
    Cut()
    Capture { CommaSeparated { Identifier() } }
    Keyword("INSERT")
    ...
}
```

---

### `Lookahead`

Positive lookahead. Runs the inner parser but **does not consume** input. Succeeds if inner succeeds; fails if inner fails. Output is always `Void`.

**Signature:**
```swift
Lookahead { @ParserBuilder content }
```

**Examples:**
```swift
// Ensure we're at a word boundary before consuming
Lookahead { Char.word }
Identifier()

// Check that "END" follows without consuming it
Lookahead { Keyword("END") }
```

---

### `NegativeLookahead`

Negative lookahead. Succeeds if the inner parser **fails**; fails if inner succeeds. Consumes nothing.

**Signature:**
```swift
NegativeLookahead { @ParserBuilder content }
```

**Examples:**
```swift
// Identifier that is not a keyword
NegativeLookahead { Keyword("SELECT") }
Identifier()

// Not at end of input
NegativeLookahead { Anchor.endOfInput }
```

---

### `Sequence`

Explicit sequence wrapper. Same as `Pegex` for sequential composition; use for documentation clarity.

**Signature:**
```swift
Sequence { @ParserBuilder content }
```

---

## 6. Capture

### `Capture`

Captures and includes the output of its inner parser in the result. In `ParserBuilder` context, non-`Void` outputs are collected into tuples.

**Signature:**
```swift
Capture { @ParserBuilder content }
```

**Examples:**
```swift
// Single capture
Pegex {
    Keyword("SELECT")
    Capture { Identifier() }
}
// Output: String

// Multiple captures → tuple
Pegex {
    Keyword("SELECT")
    Capture { CommaSeparated { Identifier() } }
    Keyword("FROM")
    Capture { Identifier() }
}
// Output: (([String], String)) — nested from CommaSeparated
```

---

### `TryCapture`

Capture with a failable transform. If the transform returns `nil`, parsing fails at that position.

**Signature:**
```swift
TryCapture(transform: (Upstream.Output) -> Output?) { @ParserBuilder content }
```

**Examples:**
```swift
TryCapture(transform: { Int(String($0)) }) {
    OneOrMore { Char.digit }
}
// "123" → 123; "abc" fails (transform returns nil)

TryCapture(transform: { $0 > 0 ? $0 : nil }) {
    IntegerLiteral()
}
// Only positive integers; negative fails
```

---

### `Reference` & `CaptureAs`

Named capture for subscript-style access. `Reference<Output>` is a **class** that holds the value; `CaptureAs` stores into it and produces `Void` (for use in sequences). Create the `Reference` before building the parser; read via `reference.get()` after parsing.

**Signatures:**
```swift
Reference<Output>()
CaptureAs(as: Reference<Output>, transform: (Upstream.Output) -> Output) { @ParserBuilder content }
```

**Examples:**
```swift
let tableRef = Reference<String>()
let parser = Pegex {
    Keyword("FROM")
    CaptureAs(as: tableRef, transform: { $0 }) { Identifier() }
}
var input = "FROM users"[...]
_ = try parser.parse(&input)
let table = tableRef.get()  // "users"
```

---

## 7. Convenience Constructs

**Substring-only:** `CommaSeparated`, `Delimited`, `SemicolonSeparated`, `Parenthesized`, `Braced`, and `Bracketed` require `Input == Substring`. Use with `Substring` input (e.g. `var input = "a,b,c"[...]`).

---

### `CommaSeparated`

One or more elements separated by commas. **Substring-only.**

**Signature:**
```swift
CommaSeparated { @ParserBuilder element }
```

**Examples:**
```swift
CommaSeparated { Identifier() }      // "a, b, c" → ["a","b","c"]
CommaSeparated { IntegerLiteral() }   // "1, 2, 3" → [1, 2, 3]
```

---

### `Delimited`

One or more elements separated by a configurable delimiter. **Substring-only.** The separator is a `Parser` (e.g. `","` or `"|"` for `Substring`).

**Signature:**
```swift
Delimited(separator: Separator) { @ParserBuilder element }
```

**Examples:**
```swift
Delimited(separator: ",") { Identifier() }   // "a,b,c"
Delimited(separator: "|") { Identifier() }   // "x|y|z"
Delimited(separator: " ") { IntegerLiteral() }
```

---

### `SemicolonSeparated`

One or more elements separated by semicolons. **Substring-only.**

**Signature:**
```swift
SemicolonSeparated { @ParserBuilder element }
```

**Examples:**
```swift
SemicolonSeparated { Identifier() }   // "a; b; c"
```

---

### `Parenthesized`

Content surrounded by `(` and `)`. **Substring-only.**

**Signature:**
```swift
Parenthesized { @ParserBuilder content }
```

**Examples:**
```swift
Parenthesized { CommaSeparated { Identifier() } }   // "(a, b, c)"
Parenthesized { IntegerLiteral() }                  // "(42)"
```

---

### `Braced`

Content surrounded by `{` and `}`. **Substring-only.**

**Signature:**
```swift
Braced { @ParserBuilder content }
```

**Examples:**
```swift
Braced { SemicolonSeparated { Identifier() } }   // "{ a; b; c }"
```

---

### `Bracketed`

Content surrounded by configurable open/close brackets. **Substring-only.**

**Signature:**
```swift
Bracketed(open: Character = "[", close: Character = "]") { @ParserBuilder content }
```

**Examples:**
```swift
Bracketed { IntegerLiteral() }                    // "[42]"
Bracketed(open: "<", close: ">") { Identifier() } // "<foo>"
```

---

### `Clause`

Optional keyword-prefixed clause. Tries to parse `KEYWORD content`; on failure, restores input and returns `nil`.

**Signature:**
```swift
Clause(_ words: String..., content: @ParserBuilder () -> Content)
```

**Examples:**
```swift
Clause("WHERE") {
    Identifier()
    "="
    IntegerLiteral()
}
// Parses "WHERE x = 5" → Content.Output; "SELECT ..." → nil

Clause("ORDER", "BY") {
    CommaSeparated { Identifier() }
}
```

---

## 8. Recursion & Precedence

### `Recursive`

Self-referencing parser for recursive grammars. The closure receives a reference to the parser being defined.

**Signature:**
```swift
Recursive<Input, Output>(_ build: (AnyParser<Input, Output>) -> AnyParser<Input, Output>)
```

**Examples:**
```swift
// Nested parentheses: ( ( 42 ) ) → 42
let expr = Recursive<Substring, Int> { ref in
    AnyParser { input in
        var copy = input
        do {
            _ = try "(".parse(&copy)
            let inner = try ref.parse(&copy)
            _ = try ")".parse(&copy)
            input = copy
            return inner
        } catch {
            let result = try numberParser.parse(&copy)
            input = copy
            return result
        }
    }
}

// Nested SELECT: SELECT a FROM t WHERE x IN (SELECT b FROM t2)
let selectRef = Recursive<Substring, Void> { ref in
    Pegex {
        ImplicitWhitespace {
            Keyword("SELECT")
            Capture { CommaSeparated { Identifier() } }
            Keyword("FROM")
            Capture { Identifier() }
            Clause("WHERE") {
                Keyword("IN")
                Parenthesized { ref }
            }
        }
    }.map { _ in () }.eraseToAnyParser()
}
```

---

### `PrecedenceGroup`

Pratt-style precedence parser for expressions. Define an atom and levels (infix, prefix, postfix).

**Signature:**
```swift
PrecedenceGroup(atom: Parser, levels: [AnyPrecedenceLevel])
PrecedenceGroup(atom: Parser) { @PrecedenceBuilder levels }
```

**Examples:**
```swift
let number = Prefix { $0.isNumber }.map { Int(String($0))! }
let parser = PrecedenceGroup(atom: number) {
    AtomLevel { number }
    InfixLeftLevel(precedence: 1, Skip { " + " }) { $0 + $1 }
    InfixLeftLevel(precedence: 1, Skip { " - " }) { $0 - $1 }
    InfixLeftLevel(precedence: 2, Skip { " * " }) { $0 * $1 }
    InfixLeftLevel(precedence: 2, Skip { " / " }) { $0 / $1 }
}
// "1 + 2 * 3" → 7
```

---

### `Atom` (standalone)

Thin parser wrapper. Use when you need a named "atom" parser for `PrecedenceGroup` or elsewhere. Equivalent to using the inner parser directly; useful for clarity.

**Signature:**
```swift
Atom { @ParserBuilder content }
```

---

### `AtomLevel`

Precedence level for `PrecedenceGroup` (used inside `@PrecedenceBuilder`). Parses the base/atom expressions (literals, identifiers, parenthesized). **Distinct from** the standalone `Atom` struct: `AtomLevel` is a *level* in a precedence table; `Atom` is a parser wrapper.

**Signature:**
```swift
AtomLevel { @ParserBuilder content }
```

---

### `InfixLeftLevel`

Left-associative infix operator.

**Signature:**
```swift
InfixLeftLevel(precedence: Int, _ opParser: Parser, combine: (Output, Output) -> Output)
```

---

### `InfixRightLevel`

Right-associative infix operator (e.g. `^` for exponentiation).

**Signature:**
```swift
InfixRightLevel(precedence: Int, _ opParser: Parser, combine: (Output, Output) -> Output)
```

---

### `PrefixLevel`

Prefix unary operator (e.g. `-`, `!`).

**Signature:**
```swift
PrefixLevel(precedence: Int, _ opParser: Parser, apply: (Output) -> Output)
```

---

### `PostfixLevel`

Postfix unary operator (e.g. `!` factorial).

**Signature:**
```swift
PostfixLevel(precedence: Int, _ opParser: Parser, apply: (Output) -> Output)
```

---

### `Memoized`

Packrat memoization. Caches parse results by (rule name, position). Use for left-recursive or highly ambiguous grammars. Requires `Input.Index: Hashable` (e.g. `Substring`).

**Signature:**
```swift
Memoized(_ ruleName: String, memoTable: MemoTable<Input>) { @ParserBuilder content }
```

**Examples:**
```swift
let memoTable = MemoTable()
let parser = Memoized("expr", memoTable: memoTable) {
    // ... recursive expression ...
}
var input = "((7))"[...]
_ = try parser.parse(&input)
// Create fresh MemoTable per parse; do not share across concurrent parses
```

---

### `MemoTable`

Thread-unsafe memoization cache for packrat parsing. Create a **fresh instance per parse**; do not share across concurrent parses. Requires `Input.Index: Hashable`.

**Signature:**
```swift
MemoTable()
```

---

## 9. Error Handling

### `Expected`

Wraps a parser with a label for better error messages. On failure, throws `PEGExError.expected(label, at:, underlying:)`.

**Signature:**
```swift
Expected(_ label: String) { @ParserBuilder content }
```

**Examples:**
```swift
Expected("integer") {
    Prefix(1...) { $0.isNumber }
}
// "abc" → "expected integer"
```

---

### `Recover`

Tries upstream; on failure, skips input until the recovery parser matches, then invokes `onError` and throws.

**Signature:**
```swift
Recover(
    upstream: { @ParserBuilder content },
    recovery: { @ParserBuilder content },
    onError: (Error, Input) -> Void
)
```

**Examples:**
```swift
var errors: [Error] = []
let parser = Recover(
    upstream: { "good" },
    recovery: { ";" },
    onError: { err, _ in errors.append(err) }
)
var input = "bad stuff ; rest"[...]
// Skips to ";", input becomes " rest", onError called, then throws
```

---

### `PEGExDiagnostic`

Pretty-prints parse errors with source location (line, column, snippet).

**Signature:**
```swift
PEGExDiagnostic(from: Error, source: String? = nil)
```

**Properties:** `message`, `line`, `column`, `snippet`, `underlying`  
**Computed:** `formatted` — human-readable string

**Examples:**
```swift
do {
    try parser.parse(&input)
} catch {
    let diag = PEGExDiagnostic(from: error, source: String(input))
    print(diag.formatted)
}
```

---

## 10. Core Types & Protocols

### `PEGExParseError`

Simple parse failure with a message.

```swift
PEGExParseError(_ message: String)
```

---

### `PEGExError`

Rich error enum:
- `.expected(String, at:, underlying:)` — expected construct
- `.negativeLookaheadFailed(at:)` — negative lookahead succeeded (should fail)
- `.cutCommitted(underlying:)` — cut reached, no backtrack
- `.recovery(message:, skipped:)` — recovered after skip

---

### `CutError`

Error type for Cut/ChoiceOf integration. `ChoiceOf` catches and rethrows `CutError` to disable backtracking. **Currently no parser throws `CutError`**; Cut is a placeholder that always succeeds.

---

### `PEGExRule`

Protocol for named, reusable parsers with a `body` property. Mirrors swift-parsing's body-style parsers.

```swift
protocol PEGExRule: Parser {
    associatedtype Body: Parser
    @ParserBuilder var body: Body { get }
}
```

---

### `PegexSubstringTypes`

Enum with typealiases for `Substring`-specialized parsers (e.g. `KeywordSubstring`, `IdentifierSubstring`). Use to avoid `Pegex.Keyword<Substring>` verbosity when the module and struct share a name.

---

## 11. swift-parsing Companion Types

PegexBuilder is built on [swift-parsing](https://github.com/pointfreeco/swift-parsing). These types are re-exported or used alongside PegexBuilder parsers. Import `Parsing` (or use `@_exported import Parsing` from PegexBuilder).

| Type | Description |
|------|--------------|
| `Prefix` | Consumes characters while predicate holds. `Prefix { $0.isNumber }`, `Prefix(1...) { ... }` |
| `Skip` | Parses and discards output. `Skip { " + " }` for operator in PrecedenceGroup |
| `AnyParser` | Type-erased parser. Use `parser.eraseToAnyParser()` for `Recursive` and `PrecedenceGroup` |
| `Int.parser()` | Built-in integer parser. Use `.pullback(\.utf8)` for `Substring` |
| `OneOfBuilder` | Result builder for `ChoiceOf` (alternatives must have same `Output` type) |
| `ParserBuilder` | Result builder for sequences (via `PEGExBuilder` alias) |
| `Parse` | Underlying type for `Pegex`; rarely used directly |

**Examples:**
```swift
// PrecedenceGroup operator — Skip consumes but discards
InfixLeftLevel(precedence: 1, Skip { " + " }) { $0 + $1 }

// Recursive — must return AnyParser
Recursive<Substring, Int> { ref in
    someParser.eraseToAnyParser()
}

// Int.parser for Memoized
Memoized("num", memoTable: memoTable) {
    Int.parser().pullback(\.utf8)
}
```

---

## Quick Reference Table

| Category | Elements |
|----------|----------|
| **Entry** | `Pegex`, `ImplicitWhitespace` |
| **Whitespace** | `OptionalWhitespace`, `RequiredWhitespace`, `Whitespace`, `SQLComment`, `TokenMode` |
| **Matchers** | `Keyword`, `Identifier`, `Char`, `CharIn`, `CharNotIn`, `Anchor`, `IntegerLiteral`, `FloatLiteral`, `HexLiteral`, `StringLiteral` |
| **Quantifiers** | `One`, `ZeroOrMore`, `OneOrMore`, `Optionally`, `Repeat` |
| **Combinators** | `ChoiceOf`, `Cut`, `Lookahead`, `NegativeLookahead`, `Sequence` |
| **Capture** | `Capture`, `TryCapture`, `Reference`, `CaptureAs` |
| **Convenience** | `CommaSeparated`, `Delimited`, `SemicolonSeparated`, `Parenthesized`, `Braced`, `Bracketed`, `Clause` |
| **Recursion** | `Recursive`, `PrecedenceGroup`, `Atom`, `AtomLevel`, `InfixLeftLevel`, `InfixRightLevel`, `PrefixLevel`, `PostfixLevel`, `Memoized`, `MemoTable` |
| **Error** | `Expected`, `Recover`, `PEGExDiagnostic`, `PEGExError`, `PEGExParseError` |

---

*PegexBuilder — RegexBuilder-like DSL for PEG parsers. Built on [swift-parsing](https://github.com/pointfreeco/swift-parsing).*
