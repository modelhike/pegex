# PegexBuilder — Recommended Patterns

Opinionated guidance for composing PegexBuilder parsers in readable, maintainable ways. Use this document for recommended defaults and common workflows. Use `SYNTAX.md` for the exhaustive API reference.

---

## How To Use This Guide

- Start here when you know what you want to parse but not which combinators compose best.
- Prefer the patterns below unless you have a clear reason to reach for a lower-level primitive.
- See `SYNTAX.md` when you need the exact signature or every supported overload.

---

## Recommended Defaults

- Use `Substring` as the parser input unless you have a strong reason not to.
- Use `Pegex { ... }` as the outer entry point.
- Use `ImplicitWhitespace { ... }` for token-based languages.
- Use `Keyword(...)` for case-insensitive language keywords.
- Use `Identifier(configuration:)` instead of custom ad hoc identifier parsing.
- Use `StringLiteral(quote: "'", escapeMode: .doubledClosingDelimiter)` for SQL-style strings.
- Use `QualifiedIdentifier` instead of manually stitching dotted identifiers.
- Use `PrecedenceGroup` for expressions instead of trying to model native left recursion.

---

## Building AST Nodes

Prefer shaping parser output so the final mapping step is small and obvious.

```swift
struct SelectNode {
    let column: String
}

let parser = Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")
        Capture { Identifier() }
    }
}
.map { _, column in
    SelectNode(column: column)
}
```

Why:
- keyword and punctuation stay declarative
- captures make the semantic payload explicit
- the final transform is easy to read

### Prefer captures over manual tuple surgery

```swift
let parser = Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")
        Capture { Identifier() }
        Keyword("FROM")
        Capture { Identifier() }
    }
}
.map { _, column, _, table in
    (column, table)
}
```

Avoid building parsers that capture everything and then untangle a large tuple later.

---

## Heterogeneous Choice

When alternatives produce different concrete node types, unify them behind an enum or protocol and use `HeterogeneousChoiceOf`.

### Prefer enums when you own the AST

```swift
enum Statement {
    case select(String)
    case insert(String)
}

let parser = HeterogeneousChoiceOf<Substring, Statement> {
    Pegex {
        ImplicitWhitespace {
            Keyword("SELECT")
            Capture { Identifier() }
        }
    }
    .mapTo(Statement.select)

    Pegex {
        ImplicitWhitespace {
            Keyword("INSERT")
            Capture { Identifier() }
        }
    }
    .mapTo(Statement.insert)
}
```

Why:
- exhaustive matching later
- no existential casts
- concise call sites with `mapTo`

### Use protocols when consumers need polymorphism

```swift
protocol StatementNode {
    var kind: String { get }
}

struct SelectNode: StatementNode {
    let kind = "select"
    let column: String
}

struct InsertNode: StatementNode {
    let kind = "insert"
    let table: String
}

let parser = HeterogeneousChoiceOf<Substring, any StatementNode> {
    Pegex {
        ImplicitWhitespace {
            Keyword("SELECT")
            Capture { Identifier() }
        }
    }
    .mapTo { column -> any StatementNode in
        SelectNode(column: column)
    }

    Pegex {
        ImplicitWhitespace {
            Keyword("INSERT")
            Capture { Identifier() }
        }
    }
    .mapTo { table -> any StatementNode in
        InsertNode(table: table)
    }
}
```

### Prefer `mapTo`, keep `eraseOutput` for low-level cases

- Use `mapTo(...)` when you are constructing a node, enum case, or model value.
- Use `eraseOutput(...)` when you explicitly want to erase and transform at a lower level.

### Builder form vs array form

Prefer the builder form when alternatives are declared inline:

```swift
let parser = HeterogeneousChoiceOf<Substring, Statement> {
    selectParser
    insertParser
}
```

Use the array form when alternatives are assembled dynamically:

```swift
let parser = HeterogeneousChoiceOf<Substring, Statement>([
    selectParser,
    insertParser,
])
```

---

## Whitespace Strategy

### Default token mode

```swift
let parser = Pegex {
    ImplicitWhitespace {
        Keyword("SELECT")
        Capture { Identifier() }
        Keyword("FROM")
        Capture { Identifier() }
    }
}
```

Use this for most SQL-like and config-like grammars.

### Horizontal whitespace only

```swift
let parser = ImplicitWhitespace(configuration: .horizontal(commentSyntax: .sql)) {
    Keyword("SELECT")
    Keyword("FROM")
}
```

Use this when newlines are significant.

### Comments-only gaps

```swift
let parser = ImplicitWhitespace(configuration: .commentsOnly(commentSyntax: .sql)) {
    Keyword("SELECT")
    Keyword("FROM")
}
```

Use this when tokens may be adjacent except for comments.

### Leading token skipping without full implicit gaps

```swift
let parser = TokenMode<Substring, _>(
    .skipWhitespaceAndComments,
    configuration: .commentsOnly(commentSyntax: .sql)
) {
    Keyword("SELECT")
}
```

Use `TokenMode` when you only want leading skipping behavior.

### Raw character mode

```swift
let parser = TokenMode<Substring, _>(.character) {
    "SELECT"
}
```

Use `.character` when spacing is significant or when you are writing scanners rather than token grammars.

---

## Identifier Configuration

Prefer library configuration over handwritten parser branches.

```swift
let identifier = Identifier(configuration: .init(
    regularForm: .init(
        additionalContinuingCharacters: Set(["$", "@", "#"])
    ),
    prefixedForms: [
        .init(prefix: "@@", body: .init(
            additionalStartCharacters: Set(["#"]),
            additionalContinuingCharacters: Set(["@", "#", "$"])
        )),
        .init(prefix: "@", body: .init(
            additionalStartCharacters: Set(["#"]),
            additionalContinuingCharacters: Set(["@", "#", "$"])
        ))
    ],
    delimitedForms: [
        .init(opening: "[", closing: "]"),
        .init(opening: "\"", escapeStrategy: .doubledClosingDelimiter)
    ]
))
```

Use:
- `prefixedForms` for things like `@name`, `@@global`, `$$macro`
- `delimitedForms` for bracketed or quoted identifiers
- `QualifiedIdentifier` for multipart names such as `database..object`

### Keep raw and normalized identifier text when needed

```swift
let token = try IdentifierToken(configuration: .init(
    regularForm: nil,
    delimitedForms: [.init(opening: "\"", escapeStrategy: .doubledClosingDelimiter)]
)).parse(&input)

token.raw        // "\"Table\"\"Name\""
token.value      // "Table\"Name"
token.delimiter  // delimiter metadata
```

---

## String Literals

Prefer explicit delimiter/escape configuration instead of building string parsing manually.

### SQL-style single quotes

```swift
let parser = StringLiteral(quote: "'", escapeMode: .doubledClosingDelimiter)
```

### Multiple quoting styles

```swift
let parser = StringLiteral(delimiters: [
    .init(opening: "'", escapeMode: .doubledClosingDelimiter),
    .init(opening: "\"", escapeMode: .character("\\"))
])
```

### No-escape mode

```swift
let parser = StringLiteral(quote: "'", escapeMode: .none)
```

Use this when the delimiter should close immediately and doubled delimiters are not special.

---

## Batch-Oriented Parsing

### Only split batches

```swift
let batches = try BatchSplitter().split(source)
```

Use this when your app wants to drive parsing itself.

### Parse each batch and keep going

```swift
let parser = BatchedParse(
    configuration: .init(splitter: .init(directive: "GO"))
) {
    Int.parser().pullback(\.utf8)
}

let result = try parser.parse(source)
```

Use this when you want:
- successful outputs for good batches
- failures collected per batch
- location-aware errors for bad batches

### Custom batch directives

```swift
let parser = BatchedParse(
    configuration: .init(
        splitter: .init(directive: "END", isCaseSensitive: true)
    )
) {
    Int.parser().pullback(\.utf8)
}
```

### Allow trailing input inside a batch

```swift
let parser = BatchedParse(
    configuration: .init(
        splitter: .init(directive: "GO"),
        requiresFullConsumption: false,
        trailingWhitespace: nil
    )
) {
    Int.parser().pullback(\.utf8)
}
```

---

## Error Recovery

### Recover once and throw

```swift
var errors: [Error] = []
let parser = Recover(
    upstream: { "good" },
    recovery: { ";" },
    onError: { error, _ in errors.append(error) }
)
```

Use this when you need one local recovery hook.

### Recover repeatedly and continue

```swift
let element = Pegex {
    Capture { Prefix(1...) { $0.isLetter } }
    ";"
}

let parser = RecoveringMany(
    element: { element },
    recovery: { "RESYNC;" }
)
```

Use this when you want a partial parse result with both:
- successful elements
- recorded errors

### `Recover` vs `RecoveringMany`

- Use `Recover` when the parser should still fail overall, but you want one local resync hook.
- Use `RecoveringMany` when partial success is the goal and you want a result object containing successes plus errors.

---

## Diagnostics

### Add labels at grammar boundaries

```swift
let parser = Expected("identifier") {
    Identifier()
}
```

Use `Expected` around user-facing grammar units so failures mention domain concepts instead of raw internals.

### Parse full source with locations

```swift
do {
    let value = try parser.parseWithLocation(source)
    print(value)
} catch let error as PEGExLocatedError {
    print(error.location.line)
    print(error.location.column)
    print(error.location.offset)
}
```

### Convert any failure into a printable diagnostic

```swift
do {
    try parser.parse(&input)
} catch {
    let diagnostic = PEGExDiagnostic(from: error, source: source)
    print(diagnostic.formatted)
}
```

---

## Recursion And Expressions

### Native left recursion is not supported

Do not try to encode rules like:

```text
expr <- expr "+" term | term
```

### Preferred workaround: `PrecedenceGroup`

```swift
let number = Prefix { $0.isNumber }.map { Int(String($0))! }
let expr = PrecedenceGroup(atom: number) {
    AtomLevel { number }
    InfixLeftLevel(precedence: 1, Skip { " + " }) { $0 + $1 }
    InfixLeftLevel(precedence: 2, Skip { " * " }) { $0 * $1 }
}
```

### Use `Recursive` for nesting, not for left recursion

```swift
let expr = Recursive<Substring, Int> { ref in
    AnyParser { input in
        var copy = input
        do {
            _ = try "(".parse(&copy)
            let value = try ref.parse(&copy)
            _ = try ")".parse(&copy)
            input = copy
            return value
        } catch {
            return try number.parse(&input)
        }
    }
}
```

### Add `Memoized` when recursion or backtracking gets expensive

```swift
let memoTable = MemoTable<Substring>()
let parser = Memoized("expr", memoTable: memoTable) {
    exprBody
}
```

Create a fresh `MemoTable` per parse. Treat it as request-local state rather than a shared singleton.

---

## End-To-End Mini Language

This example shows a small but realistic style for a statement-oriented language with expressions and heterogeneous AST nodes.

```swift
enum Expr {
    case identifier(String)
    case integer(Int)
    case add(Expr, Expr)
}

enum Statement {
    case print(Expr)
    case letBinding(String, Expr)
}

let identifier = Identifier()
let integer = Prefix(1...) { $0.isNumber }.map { Expr.integer(Int(String($0))!) }

let expr = Recursive<Substring, Expr> { ref in
    let atom = HeterogeneousChoiceOf<Substring, Expr> {
        identifier.mapTo(Expr.identifier)
        integer
        Parenthesized { ref }.eraseOutput { $0 }
    }

    return PrecedenceGroup(atom: atom) {
        AtomLevel { atom }
        InfixLeftLevel(precedence: 1, Skip { ImplicitWhitespace { "+" } }) { .add($0, $1) }
    }
    .eraseToAnyParser()
}

let statement = HeterogeneousChoiceOf<Substring, Statement> {
    Pegex {
        ImplicitWhitespace {
            Keyword("PRINT")
            Capture { expr }
        }
    }
    .mapTo(Statement.print)

    Pegex {
        ImplicitWhitespace {
            Keyword("LET")
            Capture { identifier }
            "="
            Capture { expr }
        }
    }
    .eraseOutput { _, name, _, value in
        Statement.letBinding(name, value)
    }
}
```

This pattern combines:
- `Identifier`
- `HeterogeneousChoiceOf`
- `mapTo`
- `Recursive`
- `PrecedenceGroup`
- `ImplicitWhitespace`

It is a good default shape for small interpreters, DSLs, and query languages.

---

## Practical Heuristics

- Use `ChoiceOf` when all branches already have the same output type.
- Use `HeterogeneousChoiceOf` when branches need unification behind an enum/protocol.
- Use `Capture` for semantic values; don’t manually pluck raw tuple pieces unless you have to.
- Use `mapTo` for readable node construction.
- Use `Expected` around user-facing grammar boundaries to improve diagnostics.
- Use `parseWithLocation(_:)` when parsing a full source string for diagnostics.
- Use `BatchSplitter`/`BatchedParse` at the script level, not inside statement grammars.

---

## Less Common APIs

These APIs are still supported and useful, but they are less central than the default patterns above. Reach for them when you have a specific need rather than as a first choice.

### `Optionally`

Use when a parser should produce an optional semantic value.

```swift
let whereClause = Optionally {
    Clause("WHERE") {
        Identifier()
        "="
        IntegerLiteral()
    }
}
```

Good for optional grammar branches that should become `Output?`.

### `Repeat`

Use when you need a bounded repetition instead of open-ended `OneOrMore`/`ZeroOrMore`.

```swift
let hexByte = Repeat(count: 2) { Char.hexDigit }
let oneToThreeLetters = Repeat(1...3) { Char.letter }
```

### `Lookahead` and `NegativeLookahead`

Use when you need zero-width assertions.

```swift
let parser = Pegex {
    Lookahead { Keyword("SELECT") }
    Keyword("SELECT")
}

let nonKeywordIdentifier = Pegex {
    NegativeLookahead { Keyword("SELECT") }
    Identifier()
}
```

Prefer them for boundary checks and exclusions, not for building the main grammar shape.

### `TryCapture`

Use when parsing succeeds syntactically but semantic conversion can still fail.

```swift
let positiveInt = TryCapture(transform: { $0 > 0 ? $0 : nil }) {
    IntegerLiteral()
}
```

### `Reference` and `CaptureAs`

Use when you need named side captures instead of positional tuple extraction.

```swift
let tableRef = Reference<String>()

let parser = Pegex {
    Keyword("FROM")
    CaptureAs(as: tableRef, transform: { $0 }) {
        Identifier()
    }
}
```

This is niche, but useful when large tuples would otherwise become awkward.

### `Recover`

Use when you want a one-shot local recovery hook but still want the overall parse to fail.

```swift
var errors: [Error] = []
let parser = Recover(
    upstream: { "good" },
    recovery: { ";" },
    onError: { error, _ in errors.append(error) }
)
```

If you want partial success as the main result, prefer `RecoveringMany`.

### `Memoized`

Use when recursive or backtracking-heavy grammars need packrat-style caching.

```swift
let memoTable = MemoTable<Substring>()
let parser = Memoized("expr", memoTable: memoTable) {
    exprBody
}
```

Create a fresh `MemoTable` per parse.

### `Cut`

Use when an alternative should commit and prevent fallback to later alternatives after a certain point.

```swift
let parser = ChoiceOf {
    Pegex({ _ in "select" }) {
        "SE"
        Cut()
        "LECT"
    }
    Pegex({ _ in "set" }) {
        "SET"
    }
}
```

This is most useful in ambiguous grammars where later alternatives would hide a more meaningful failure.

---

## See Also

- `SYNTAX.md` for the full element-by-element API reference.
