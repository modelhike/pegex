# PegexBuilder

A RegexBuilder-like declarative DSL for constructing PEG (Parsing Expression Grammar) parsers in Swift. Built on [swift-parsing](https://github.com/pointfreeco/swift-parsing).

## Overview

PegexBuilder provides a composable, type-safe API for building parsers with:

- **RegexBuilder parity**: `Capture`, `ChoiceOf`, `OneOrMore`, `ZeroOrMore`, `Optionally`, `Repeat`, `Lookahead`, `Reference`, `TryCapture`
- **PEG extensions**: `Cut`, `Recursive`, `PrecedenceGroup`, `ImplicitWhitespace`
- **Language parsing**: `Keyword`, `Identifier`, `IntegerLiteral`, `StringLiteral`, `Clause`, `Parenthesized`, `CommaSeparated`, and more

For a complete element reference with usage scenarios and examples, see [docs/SYNTAX.md](docs/SYNTAX.md).

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.14.1"),
]
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Parsing", package: "swift-parsing"),
        ]
    ),
]
```

Then add PegexBuilder as a local dependency or copy the sources into your project.

## Quick Start

```swift
import PegexBuilder
import Parsing

// Basic SELECT parser (Pegex is the root; ImplicitWhitespace for tokenized parsing)
let parser = Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")
        Capture { CommaSeparated { Identifier() } }
        Keyword("FROM")
        Capture { Identifier() }
    }
}

var input = "SELECT a, b FROM users"[...]
let (cols, table) = try parser.parse(&input)
// cols: ["a", "b"], table: "users"
```

## Core API

### Entry Point

| Type | Description |
|------|-------------|
| `Pegex<Input> { ... }` | Main parser builder; wraps swift-parsing `Parse` |
| `ImplicitWhitespace { ... }` | Inserts optional whitespace between parsers |

### Matchers

| Type | Description |
|------|-------------|
| `Keyword("SELECT")` | Case-insensitive keyword with word boundary |
| `Keyword("ORDER", "BY")` | Multi-word keyword |
| `Identifier()` | `[a-zA-Z_][a-zA-Z0-9_]*` |
| `Identifier(style: .sql)` | Also allows `@`, `#`, `$` |
| `Char.digit`, `Char.letter`, `Char.word`, `Char.any` | Single-character parsers |
| `CharIn("a"..."z")`, `CharNotIn("\n")` | Character sets |
| `IntegerLiteral()`, `FloatLiteral()`, `HexLiteral()` | Numeric literals |
| `StringLiteral(quote: "'")` | Quoted strings with configurable escape |
| `Anchor.startOfInput`, `Anchor.endOfInput` | Position assertions |

### Quantifiers

| Type | Description |
|------|-------------|
| `One { ... }` | Exactly one occurrence |
| `ZeroOrMore { ... }` | Zero or more |
| `OneOrMore { ... }` | One or more |
| `Optionally { ... }` | Zero or one |
| `Repeat(2...5) { ... }` | Bounded repetition |

### Combinators

| Type | Description |
|------|-------------|
| `ChoiceOf { ... }` | Ordered choice (first match wins) |
| `Cut()` | Commit to current branch; disable backtracking |
| `Lookahead { ... }` | Positive lookahead (consume nothing) |
| `NegativeLookahead { ... }` | Negative lookahead |

### Capture

| Type | Description |
|------|-------------|
| `Capture { ... }` | Extract output into result tuple |
| `TryCapture { ... } transform:` | Capture with failable transform |
| `Reference<T>()` | Named capture for subscript access |

### Convenience

| Type | Description |
|------|-------------|
| `CommaSeparated { ... }` | `a, b, c` |
| `Delimited(separator: "|") { ... }` | `a | b | c` |
| `Parenthesized { ... }` | `( inner )` |
| `Braced { ... }` | `{ inner }` |
| `Bracketed(open: "[", close: "]") { ... }` | `[ inner ]` |
| `Clause("WHERE") { ... }` | Optional keyword-prefixed clause |

### Recursion & Precedence

| Type | Description |
|------|-------------|
| `Recursive { ref in ... }` | Self-referencing parser |
| `PrecedenceGroup(atom: ...) { ... }` | Pratt-style expression parser |
| `AtomLevel { ... }` | Base expression level |
| `InfixLeftLevel(precedence:, op:) { ... }` | Left-associative operator |
| `PrefixLevel(precedence:, op:) { ... }` | Prefix operator |
| `Memoized("name", memoTable:) { ... }` | Packrat memoization |

### Error Handling

| Type | Description |
|------|-------------|
| `Expected("label") { ... }` | Wrap errors with descriptive label |
| `Recover(to: recoveryParser) { ... } onError:` | Skip to sync point on failure |
| `PegexDiagnostic` | Pretty-print errors with line/column |

## Examples

### SQL SELECT with WHERE

```swift
let parser = Pegex {
    ImplicitWhitespace {
    Keyword("SELECT")
    Capture { Identifier() }
    Keyword("FROM")
    Capture { Identifier() }
    Clause("WHERE") {
        OptionalWhitespace()
        Identifier()
        OptionalWhitespace()
        "="
        OptionalWhitespace()
        IntegerLiteral()
    }
}
}
```

### Nested Subquery

```swift
let selectParser = Recursive<Substring, Void> { selectRef in
    Pegex {
        ImplicitWhitespace {
        Keyword("SELECT")
        Capture { CommaSeparated { Identifier() } }
        Keyword("FROM")
        Capture { Identifier() }
        Clause("WHERE") {
            OptionalWhitespace()
            Identifier()
            OptionalWhitespace()
            Keyword("IN")
            OptionalWhitespace()
            Parenthesized { selectRef }
        }
        }
    }.map { _ in () }.eraseToAnyParser()
}
// Parses: SELECT a FROM t WHERE x IN (SELECT b FROM t2)
```

### Expression Precedence

```swift
enum Expr {
    case column(String)
    case number(Double)
    case and(Expr, Expr)
    case or(Expr, Expr)
}

let atom = ChoiceOf {
    Identifier().map { Expr.column($0) }
    FloatLiteral().map { Expr.number($0) }
}

let expr = PrecedenceGroup<Substring, Expr>(atom: atom) {
    AtomLevel { atom }
    InfixLeftLevel(precedence: 1, Skip { " OR " }) { .or($0, $1) }
    InfixLeftLevel(precedence: 2, Skip { " AND " }) { .and($0, $1) }
}
// Parses: price > 100 AND category = 'A' OR status = 'active'
```

## Requirements

- Swift 6.0+
- swift-parsing 0.14.1

## License

MIT
