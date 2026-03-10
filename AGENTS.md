# AGENTS.md

## Project Overview

`PegexBuilder` is a Swift package providing a RegexBuilder-style declarative DSL for building PEG
(Parsing Expression Grammar) parsers. It is a thin ergonomic layer on top of
[swift-parsing](https://github.com/pointfreeco/swift-parsing), targeting `Substring` parsing for
string-based sources (SQL, DSLs, config files).

**Package manifest:** `Package.swift` — single library target `PegexBuilder`, one test target
`PegexBuilderTests`. Requires Swift 6.2, macOS 14+, iOS 17+.

**Key docs:**
- `README.md` — quick start and API summary
- `docs/SYNTAX.md` — exhaustive API reference with signatures and examples
- `docs/PATTERNS.md` — opinionated cookbook of recommended patterns

When you add or change a public API, update both `docs/SYNTAX.md` (signatures + behavior) and
`docs/PATTERNS.md` (when it affects recommended patterns).

---

## Source Layout

```
Sources/
├── PegexHelpers.swift          — re-exports from swift-parsing; PegexSubstringTypes namespace
├── Builders/
│   ├── ImplicitWhitespaceBuilder.swift   — @ImplicitWhitespaceBuilder result builder (~363 lines)
│   ├── PEGExBuilder.swift                — @ParserBuilder re-export / extensions
│   └── PrecedenceBuilder.swift           — result builder for PrecedenceGroup levels
├── Capture/
│   ├── Capture.swift           — Capture { }
│   ├── TryCapture.swift        — TryCapture { } transform:
│   └── Reference.swift         — Reference<T>() for named captures
├── Combinators/
│   ├── ChoiceOf.swift          — ordered choice, uniform output type
│   ├── HeterogeneousChoiceOf.swift  — ordered choice, heterogeneous output types
│   ├── Cut.swift               — commit / no-backtrack signal
│   ├── Lookahead.swift         — positive lookahead
│   ├── NegativeLookahead.swift — negative lookahead
│   ├── One.swift               — exactly-one wrapper
│   ├── OneOrMore.swift         — 1+
│   ├── Optionally.swift        — 0 or 1
│   ├── Repeat.swift            — bounded repetition
│   ├── Sequence.swift          — explicit sequence combinator
│   └── ZeroOrMore.swift        — 0+
├── Convenience/
│   ├── BatchSplitter.swift     — splits scripts by GO/custom directive; ScriptBatch
│   ├── BatchedParse.swift      — runs a parser over each batch; BatchedParseResult
│   ├── Braced.swift            — { inner }
│   ├── Bracketed.swift         — [ inner ] with configurable delimiters
│   ├── Clause.swift            — Optionally-prefixed keyword clause
│   ├── CommaSeparated.swift    — a, b, c
│   ├── Delimited.swift         — a | b | c with configurable separator
│   ├── Parenthesized.swift     — ( inner )
│   └── SemicolonSeparated.swift — a ; b ; c
├── Core/
│   ├── PEGExError.swift        — error hierarchy: PEGExError, PEGExLocatedError, CutError, ...
│   ├── PEGExRule.swift         — PEGExRule protocol for named reusable rules
│   ├── PegexParser.swift       — Pegex<Input, Parsers> entry point
│   └── QuantifierBehavior.swift — eager/possessive/lazy quantifier settings
├── ErrorHandling/
│   ├── Diagnostic.swift        — PEGExDiagnostic: pretty-print errors with line/col/snippet
│   ├── Expected.swift          — Expected("label") { } — named error context
│   ├── Parser+Located.swift    — parseWithLocation(_:) extension
│   ├── Recover.swift           — Recover(to:) { } onError: — single-item recovery
│   └── RecoveringMany.swift    — RecoveringMany { } recovery: — loop with error collection
├── Matchers/
│   ├── Anchor.swift            — Anchor.startOfInput, Anchor.endOfInput
│   ├── Char.swift              — Char.digit, Char.letter, Char.word, Char.any
│   ├── CharIn.swift            — CharIn("a"..."z")
│   ├── CharNotIn.swift         — CharNotIn("\n")
│   ├── Identifier.swift        — Identifier, IdentifierToken, QualifiedIdentifier (~424 lines)
│   ├── Keyword.swift           — case-insensitive keyword with word boundary
│   ├── NumberLiteral.swift     — IntegerLiteral, FloatLiteral, HexLiteral, BinaryLiteral, MoneyLiteral
│   └── StringLiteral.swift     — quoted strings with configurable delimiter and escape
├── Rules/
│   ├── Atom.swift              — AtomLevel for PrecedenceGroup
│   ├── MemoTable.swift         — MemoTable<Input>: per-parse packrat cache
│   ├── Memoized.swift          — Memoized("name", memoTable:) { } wrapper
│   ├── PrecedenceGroup.swift   — Pratt-style expression parser
│   ├── PrecedenceLevel.swift   — InfixLeftLevel, InfixRightLevel, PrefixLevel, PostfixLevel
│   └── Recursive.swift         — self-referencing parser via ParserBox indirection
└── Whitespace/
    ├── ImplicitWhitespace.swift       — wraps block with inter-token whitespace
    ├── OptionalWhitespace.swift       — zero-or-more whitespace
    ├── RequiredWhitespace.swift       — one-or-more whitespace
    ├── SQLComment.swift               — SQLComment + CommentSyntax
    ├── TokenMode.swift                — TokenMode: leading/surrounding whitespace modes
    ├── Whitespace.swift               — Whitespace: skips ws + comments in a loop
    └── WhitespaceConfiguration.swift  — configures which chars + comment syntax count as whitespace
```

Tests mirror this structure under `Tests/`, plus `Tests/Integration/` for end-to-end SQL examples.

---

## Generic Constraints

All parsers in this package are generic over `Input` with the following constraints:
```swift
Input: Collection, Input.SubSequence == Input, Input.Element == Character
```
`Substring` is the intended default. All public `init` overloads provide `Input == Substring`
convenience variants. The generic forms exist for testing and advanced use cases.

---

## Entry Point

```swift
// Sequence (all child parsers run in order; outputs combined into tuple)
Pegex { childA; childB; childC }

// Sequence with output transform
Pegex { name in childA; childB } transform: { (a, b) in MyNode(a, b) }

// Sequence producing a constant output
Pegex { childA; childB } output: MyConstant
```

`Pegex` is a thin wrapper around swift-parsing's `Parse`. It composes using `@ParserBuilder`.

---

## `Void` Stripping — Critical Behaviour

**`@ImplicitWhitespaceBuilder` and `@ParserBuilder` automatically remove `Void` outputs from
tuples.** This is the single most important thing to understand when reading parser output types.

```swift
// Parser with 4 children, 2 of which are Keyword (Void output)
Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")                           // → Void (stripped)
        Capture { CommaSeparated { Identifier() } } // → [String]
        Keyword("FROM")                             // → Void (stripped)
        Capture { Identifier() }                    // → String
    }
}
// Output type: ([String], String)   NOT (Void, [String], Void, String)
```

When destructuring results:
```swift
let (cols, table) = try parser.parse(&input)  // ✓ correct
let (_, cols, _, table) = ...                  // ✗ wrong — Void is not in the tuple
```

This applies to any parser returning `Void`: `Keyword`, `Skip { }`, string literals used as
exact-match parsers (e.g. `","`, `"="`), `Cut()`, whitespace parsers.

---

## Core API Reference

### Combinators

| Type | Output | Notes |
|------|--------|-------|
| `ChoiceOf { A; B; C }` | shared output type | ordered; first match wins; all branches must share one `Output` type |
| `HeterogeneousChoiceOf<Input, Output> { }` | `Output` | ordered; branches can have different types, unified by `.mapTo` / `.eraseOutput` |
| `Optionally { }` | `Output?` | zero-or-one |
| `ZeroOrMore { }` | `[Output]` | greedy |
| `OneOrMore { }` | `[Output]` | greedy; fails if zero |
| `Repeat(N) { }` | `[Output]` | exact count |
| `Repeat(n...m) { }` | `[Output]` | range |
| `Lookahead { }` | `Void` | positive; consumes nothing |
| `NegativeLookahead { }` | `Void` | negative; consumes nothing |
| `Cut()` | `Void` | commits current `ChoiceOf` branch; prevents backtrack |
| `One { }` | `Output` | exactly one; alias for the inner parser |

### Capture

| Type | Output | Notes |
|------|--------|-------|
| `Capture { }` | `Output` | extracts the inner parser's output into the result tuple |
| `TryCapture { } transform:` | `Output?` | capture with failable transform; returns `nil` on failure |
| `Reference<T>()` | — | mutable reference; subscript `captures[ref]` after parse |

### Matchers

#### `Keyword`
```swift
Keyword("SELECT")           // Void; case-insensitive; requires word boundary after
Keyword("ORDER", "BY")      // multi-word; requires whitespace between words
```

#### `Identifier` / `IdentifierToken`
```swift
Identifier()                        // standard: [a-zA-Z_][a-zA-Z0-9_]*; returns String
Identifier(style: .sql)             // full SQL/T-SQL identifier set; returns String
IdentifierToken(style: .sql)        // same, but returns ParsedIdentifier (raw, value, delimiter)
QualifiedIdentifier<Substring>(
    component: IdentifierToken(style: .sql),
    allowsOmittedComponents: true,   // allows "db..table" (omitted schema)
    maxParts: 4                      // server.database.schema.object
)                                    // returns QualifiedIdentifierValue
```

**The `.sql` style covers all Sybase/T-SQL identifier forms:**

| Form | Example |
|------|---------|
| Regular | `table_name`, `col$1` |
| `@` local variable | `@varname` |
| `@@` global variable | `@@rowcount` |
| `#` local temp | `#temp_table` |
| `##` global temp | `##global_temp` |
| `[...]` bracket-delimited | `[Order Details]`, `[SELECT]` |
| `"..."` double-quote-delimited | `"Column Name"` (with `""` escape) |

Prefix forms are sorted longest-first (`@@` before `@`, `##` before `#`) so the greedy correct
form always matches first.

#### `StringLiteral`
```swift
StringLiteral(quote: "'", escapeMode: .doubledClosingDelimiter)  // SQL '' escape
StringLiteral(quote: "\"", escape: "\\")                         // C-style \" escape
StringLiteral(quotes: ["\"", "'", "`"])                          // multi-quote
StringLiteral(delimiters: [                                      // mixed strategies
    .init(opening: "'", escapeMode: .doubledClosingDelimiter),
    .init(opening: "`", escapeMode: .none),
])
```

`EscapeMode` values: `.none`, `.character(Character)`, `.doubledClosingDelimiter`.

#### Number literals
```swift
IntegerLiteral<Substring>()   // signed Int:    42, -17, +0
FloatLiteral<Substring>()     // Double:        3.14, -1.5e10
HexLiteral<Substring>()       // Int:           0xFF
BinaryLiteral<Substring>()    // Int:           0b101
MoneyLiteral<Substring>()     // Double:        $123.45 (configurable currency symbol)
```

### Whitespace

```swift
Whitespace()                                    // skips ws + SQL comments (.standard config)
Whitespace(configuration: .horizontal())        // only space/tab
Whitespace(configuration: .commentsOnly())      // only comments, no ws chars
Whitespace(commentSyntax: myCommentSyntax)      // custom comment syntax, all whitespace

OptionalWhitespace()  // = Whitespace(); always succeeds
RequiredWhitespace()  // = OneOrMore(Whitespace()); fails on zero
```

```swift
// ImplicitWhitespace: inserts optional whitespace between each child parser
ImplicitWhitespace { childA; childB; childC }                   // .standard config
ImplicitWhitespace(commentSyntax: .sql) { ... }                 // SQL comments
ImplicitWhitespace(configuration: .horizontal()) { ... }        // no newlines
```

**`WhitespaceConfiguration` presets:**
```swift
.standard                          // all Unicode whitespace + SQL -- and /* */ comments
.horizontal(commentSyntax: ...)    // space + tab only
.commentsOnly(commentSyntax: ...)  // only comments, zero whitespace chars
.characters(["_", " "], ...)       // custom character set
```

**`CommentSyntax`:**
```swift
CommentSyntax.sql   // "--" single-line + "/* ... */" nested block comments
CommentSyntax(singleLinePrefixes: ["//"], blockDelimiters: [
    .init(opening: "/*", closing: "*/", allowsNesting: true)
])
```

`SQLComment<Input>` parses a single comment token (used internally by `Whitespace`).

### `TokenMode`
Wraps a parser with configurable surrounding whitespace:
```swift
TokenMode<Substring, _>(.skipWhitespaceAndComments, configuration: .standard) { ... }
TokenMode<Substring, _>(.character) { ... }  // no whitespace skip
```

### Convenience Parsers

| Type | Syntax matched |
|------|---------------|
| `CommaSeparated { E }` | `e1, e2, e3` |
| `Delimited(separator: "|") { E }` | `e1 \| e2 \| e3` |
| `SemicolonSeparated { E }` | `e1; e2; e3` |
| `Parenthesized { E }` | `( e )` |
| `Braced { E }` | `{ e }` |
| `Bracketed { E }` | `[ e ]` (configurable delimiters) |
| `Clause("WHERE") { E }` | `Optionally { Keyword("WHERE"); E }` |

### Output Mapping

```swift
parser.mapTo { value in MyNode(value) }     // arbitrary transform
parser.mapTo(MyNode.init)                   // constructor reference
parser.mapTo(Statement.select)              // enum case constructor
parser.eraseOutput { value in MyProto() }  // type-erase to protocol/superclass
```

`.mapTo` is preferred; use `.eraseOutput` only when the type cannot be expressed directly.

### `HeterogeneousChoiceOf`

When branches produce different output types, unify them behind an enum or protocol:

```swift
let parser = HeterogeneousChoiceOf<Substring, Statement> {
    selectParser.mapTo(Statement.select)
    insertParser.mapTo(Statement.insert)
    updateParser.mapTo(Statement.update)
}
```

Use `eraseOutput` when a closure is needed to build the common type:
```swift
selectParser.eraseOutput { col -> any StatementNode in SelectNode(column: col) }
```

---

## Recursion and Expressions

### `Recursive`
```swift
let expr = Recursive(Substring.self, Expression.self) { ref in
    PrecedenceGroup(atom: atomParser, levels: [...])
}
```
Uses a `ParserBox` indirection so the closure can reference the parser before it is constructed.
`ref` is an `AnyParser<Input, Output>` that forwards to the completed parser.

### `PrecedenceGroup` (Pratt parsing)
```swift
PrecedenceGroup(atom: atomParser) {
    PrefixLevel(precedence: 100) {
        op { Keyword("NOT") }
    } apply: { .unary(.not, $0) }

    InfixLeftLevel(precedence: 40) {
        op { ChoiceOf { "*"; "/"; "%" } }
    } apply: { .binary(.multiply, $0, $1) }

    InfixLeftLevel(precedence: 20) {
        op { ChoiceOf { "+"; "-" } }
    } apply: { .binary(.add, $0, $1) }
}
```

`InfixRightLevel` exists for right-associative operators (e.g. `**`).
`PostfixLevel` exists for suffix operators (e.g. `IS NULL`).
Levels are matched in order — lower-precedence levels listed first bind looser.

### `Memoized` / `MemoTable`

Packrat memoization: cache parse results keyed by `(ruleName, Input.Index)`.

```swift
let table = MemoTable<Substring>()   // create once per parse
let p = Memoized("expression", memoTable: table) { myExpensiveParser }
```

`MemoTable` is **not thread-safe**; create a fresh instance per parse invocation.
`Memoized` is marked `@unchecked Sendable` — safe as long as one table = one parse.

---

## Error Handling

### Error hierarchy

```swift
PEGExParseError(message)            // simple failure (thrown by internal helpers)
PEGExError                          // rich enum:
  .failure(String, at: PEGExPosition)
  .expected(String, at: PEGExPosition, underlying: Error)
  .negativeLookaheadFailed(at: PEGExPosition)
  .cutCommitted(underlying: Error)
  .recovery(message: String, skipped: PEGExPosition)
PEGExLocatedError                   // failure enriched with line/column/offset
CutError                            // internal signal from Cut() to ChoiceOf (do not catch directly)
```

`PEGExPosition` is an opaque wrapper around an `Input` value (usually `Substring`).

`pegexFailure(_ message: String, at input: Input) -> PEGExError` is the internal helper for
creating position-aware failures from inside `parse` implementations.

### `Expected`

Wraps a parser and labels its failures with a descriptive name for error messages:

```swift
Expected("column list") { CommaSeparated { Identifier() } }
// → PEGExError.expected("column list", at: ..., underlying: ...)
```

### `parseWithLocation`

Extension on `Parser where Input == Substring`:

```swift
let result = try myParser.parseWithLocation(sourceString)
// On failure: throws PEGExLocatedError with line, column, offset
```

### `PEGExDiagnostic`

```swift
let diag = PEGExDiagnostic(from: error, source: sourceString)
diag.message   // String
diag.line      // Int?
diag.column    // Int?
diag.offset    // Int?
diag.snippet   // String? — up to 20 chars before + 40 chars after the error position
print(diag.formatted)
// error: expected identifier
//   at line 3, column 12 (offset 47)
//   CREATE TABLE [   ^ <- points at error position
```

### `Recover` and `RecoveringMany`

```swift
// Skip a single failed element and continue
Recover(to: ";" as CharacterParser) { myParser } onError: { error in ... }

// Parse many elements, collecting errors on failure and seeking to recovery markers
RecoveringMany { myParser } recovery: { ";".eraseToAnyParser() }
// → RecoveringManyResult<Output> { elements: [Output], errors: [Error] }
```

### `Cut`

`Cut()` is placed inside a `ChoiceOf` branch after a discriminating token:

```swift
ChoiceOf {
    Pegex { Keyword("SELECT"); Cut(); selectBody }   // once SELECT matched, no backtrack
    Pegex { Keyword("INSERT"); Cut(); insertBody }
}
```

`Cut()` throws `CutError` when it fires after a branch failure. `ChoiceOf` catches `CutError`
and re-throws it as `PEGExError.cutCommitted` instead of trying the next alternative.
`CutContext` is a thread-local stack using `NSLock`. Do not nest `Cut()` in unexpected ways.

---

## Batch/Script Parsing

### `ScriptBatch`

```swift
public struct ScriptBatch: Equatable, Sendable {
    public let text: String          // batch SQL text
    public let repeatCount: Int?     // from "GO N"; nil means use once
    public let startOffset: Int      // character offset of batch start in original source
    public let startLine: Int        // 1-based line number of batch start
}
```

`startOffset` and `startLine` allow callers to translate batch-relative error locations to
absolute source positions.

### `BatchSplitter`

```swift
let splitter = BatchSplitter()  // default: directive="GO", case-insensitive
let splitter = BatchSplitter(configuration: .init(
    directive: "GO",
    isCaseSensitive: false,
    allowsRepeatCount: true,
    commentSyntax: .sql,
    ignoredDelimitedRegions: [
        .init(opening: "'", escapeMode: .doubledClosingDelimiter),
        .init(opening: "\"", escapeMode: .doubledClosingDelimiter),
    ]
))

let batches: [ScriptBatch] = try splitter.split(sourceString)
```

`BatchSplitter` processes the source line-by-line. State (`ParserState`) tracks whether the
current position is inside a string literal, block comment, or neutral. Correctly handles:
- `GO` inside string literals (ignored)
- Nested block comments (`/* /* inner */ outer */`)
- `GO N` repeat counts
- `\r\n`, `\r`, `\n` line endings

### `BatchedParse`

Runs a child `Parser` independently over each batch, collecting results and failures:

```swift
let result = try BatchedParse(
    configuration: .init(splitter: .init(directive: "GO"), requiresFullConsumption: true),
    child: myStatementParser
).parse(sourceString)

result.outputs    // [Output]
result.failures   // [BatchedParseFailure] — each has .batchIndex, .batch, .underlying
```

Failures from `BatchedParse` are always `PEGExLocatedError` (location translated to within the
batch text, not the full source).

---

## Thread Safety

| Component | Thread safety |
|-----------|--------------|
| All `Parser` types | Sendable; safe to share across threads |
| `ImplicitWhitespaceBuilderContext` | Uses `NSLock`; safe for concurrent builds |
| `CutContext` | Uses `NSLock`; safe for concurrent parses |
| `MemoTable` | **Not thread-safe** — create one per parse invocation |

---

## Internal Patterns

### `ImplicitWhitespaceBuilderContext`

A thread-safe stack that propagates the active `WhitespaceConfiguration` through the
`@ImplicitWhitespaceBuilder` call tree. Parsers created inside `ImplicitWhitespace { }` automatically
look up the current configuration via `ImplicitWhitespaceBuilderContext.current`.
`ImplicitWhitespaceSequence<A, B>` is the concrete parser type produced by the builder;
it runs `whitespace → A → whitespace → B` (skipping `Void` outputs from `A` or `B`).

### `PEGExRule`

A protocol for named reusable rules with a `body` property (mirrors swift-parsing's `ParserPrinter`
body-style, but for parsers only):

```swift
struct MyRule: PEGExRule {
    var body: some Parser<Substring, String> {
        Pegex { ImplicitWhitespace { Keyword("FOO"); Capture { Identifier() } } }
    }
}
```

---

## Architectural Principles

- **Keep it generic** — no hardcoded language-specific behaviour. Add configuration points instead.
- **Composable primitives** — prefer extending existing combinators over new top-level types.
- **Thin layer over swift-parsing** — all parsers conform to `Parsing.Parser`. New parsers must
  satisfy `Parser.parse(_ input: inout Input) throws -> Output`.
- **No left recursion** — use `PrecedenceGroup` for operator grammars, `Recursive` for structural
  nesting, `Memoized` when you need packrat caching to avoid exponential backtracking.
- **Heterogeneous outputs** — `ChoiceOf` when branches share a type; `HeterogeneousChoiceOf` + 
  `.mapTo` when they don't. Avoid `eraseToAnyParser` in result builders.
- **Diagnostics** — preserve position in all failures. Prefer `Expected("label") { }` at grammar
  boundaries. Use `parseWithLocation` at the top-level entry point.

---

## Testing

Tests use Swift Testing (`@Suite`, `@Test`, `#expect`). Folder mirrors `Sources/`.

```bash
swift test                              # run everything
swift test --filter "BatchSplitterTests"  # run one suite
```

**Guidelines:**
- Each public behaviour change needs a test demonstrating correct output.
- Cover failure cases (wrong input, unclosed delimiters, etc.) as well as success.
- Integration tests live in `Tests/Integration/` and combine multiple features.
- When updating `ImplicitWhitespace` or `@ImplicitWhitespaceBuilder`, check that `Void`-stripping
  tests in integration suites still match the expected output type (the most common breakage point).

---

## Adding a New Matcher

1. Create `Sources/Matchers/MyMatcher.swift`.
2. Conform to `Parser`: implement `parse(_ input: inout Input) throws -> Output`.
3. Use `pegexFailure(message, at: input)` to produce position-aware errors.
4. Add `@inlinable` to `init` and `parse` if the type has no stored state that needs hiding.
5. Add tests in `Tests/Matchers/MyMatcherTests.swift`.
6. Add the signature + example to `docs/SYNTAX.md` under the Matchers section.

## Adding a New Combinator

1. Create `Sources/Combinators/MyCombinator.swift`.
2. Follow the `@usableFromInline let upstream: Upstream` pattern.
3. If it needs to interact with `ImplicitWhitespace`, check how `Optionally` or `Repeat` do it.
4. Add tests in `Tests/Combinators/MyCombinatorTests.swift`.
5. Update `docs/SYNTAX.md`.

---

## Good Starting Files for Orientation

1. `Sources/Core/PegexParser.swift` — entry point
2. `Sources/Builders/ImplicitWhitespaceBuilder.swift` — core builder (most complex file)
3. `Sources/Combinators/HeterogeneousChoiceOf.swift` — the workhorse for typed choice
4. `Sources/Matchers/Identifier.swift` — rich matcher with `.sql` configuration
5. `Sources/Matchers/StringLiteral.swift` — escape strategies
6. `Sources/Whitespace/WhitespaceConfiguration.swift` — configuration model
7. `Sources/Rules/PrecedenceGroup.swift` — Pratt expression parser
8. `Sources/Rules/Recursive.swift` — self-referencing via `ParserBox`
9. `Sources/Convenience/BatchSplitter.swift` — batch splitting with source location tracking
10. `Sources/ErrorHandling/Diagnostic.swift` — `PEGExDiagnostic` formatting
