# AGENTS.md

## Project Overview

`PegexBuilder` is a Swift package that provides a RegexBuilder-like DSL for building PEG parsers on top of [swift-parsing](https://github.com/pointfreeco/swift-parsing).

The package exposes:
- parser entry points like `Pegex`
- PEG-style combinators like `ChoiceOf`, `Cut`, `Recursive`, `Memoized`
- token/language helpers like `ImplicitWhitespace`, `Keyword`, `Identifier`, `StringLiteral`
- higher-level utilities like `BatchSplitter`, `BatchedParse`, `RecoveringMany`

Primary package metadata lives in `Package.swift`.

## Key Docs

- Project intro: `README.md`
- Full API reference: `docs/SYNTAX.md`
- Recommended usage and best practices: `docs/PATTERNS.md`

When modifying behavior or adding public APIs:
- update `docs/SYNTAX.md` with signatures and examples
- update `docs/PATTERNS.md` when the change affects recommended usage or adds a new workflow
- add tests that demonstrate both correctness and intended usage style

## Source Layout

The package is organized by concern under `Sources/`:

- `Builders/`
  - builder/result-builder infrastructure such as `ImplicitWhitespaceBuilder`, `PrecedenceBuilder`
- `Capture/`
  - capture-related APIs like `Capture`, `TryCapture`, `Reference`, `CaptureAs`
- `Combinators/`
  - PEG combinators like `ChoiceOf`, `HeterogeneousChoiceOf`, `Cut`, `Lookahead`, `NegativeLookahead`, `Repeat`
- `Convenience/`
  - language-oriented helpers like `Clause`, `Delimited`, `Parenthesized`, `BatchSplitter`, `BatchedParse`
- `Core/`
  - foundational types like `PEGExError`, `PEGExRule`, quantifier behavior, parser helpers
- `ErrorHandling/`
  - `Expected`, `Recover`, `RecoveringMany`, diagnostics, `parseWithLocation`
- `Matchers/`
  - lexical primitives like `Keyword`, `Identifier`, `StringLiteral`, number and character parsers
- `Rules/`
  - recursion, precedence, memoization, atom/precedence levels
- `Whitespace/`
  - `Whitespace`, `ImplicitWhitespace`, `TokenMode`, comment handling, whitespace configuration

Tests live under `Tests/` and are similarly grouped by feature area.

## Architectural Principles

- Keep the library generic.
  - Do not hardcode language-specific behavior for Sybase or any other downstream consumer.
  - Add reusable primitives/configuration points instead.
- Favor composable parser building blocks over special-case APIs.
- Prefer small API surface additions unless a larger abstraction clearly improves usability.
- Keep public APIs ergonomic, but not magical.
  - `HeterogeneousChoiceOf` + `mapTo` is preferred over creating a domain-specific DSL.
- If behavior changes, align tests and docs in the same change.

## Preferred Patterns

Default recommendations are documented in `docs/PATTERNS.md`. In general:

- Use `Substring` for parsing string-based sources.
- Use `Pegex { ... }` as the outer parser entry point.
- Use `ImplicitWhitespace { ... }` for token-based grammars.
- Use `WhitespaceConfiguration` instead of inventing custom ad hoc whitespace behavior.
- Use `Keyword(...)` for language keywords.
- Use `Identifier(configuration:)`, `IdentifierToken`, and `QualifiedIdentifier` rather than hand-rolled identifier parsing.
- Use `StringLiteral(...)` with explicit delimiter/escape configuration for string grammars.
- Use `HeterogeneousChoiceOf` when alternatives need to return different concrete types unified behind an enum or protocol.
- Prefer `mapTo(...)` for readable node construction.
- Use `PrecedenceGroup` for expressions.

## Important Constraints

### Left recursion

Native left recursion is not supported.

Do not try to encode rules like:

```text
expr <- expr "+" term | term
```

Preferred workaround:
- use `PrecedenceGroup` for expression grammars
- use `Recursive` for nesting
- use `Memoized` when recursion/backtracking needs packrat-style caching

This is documented in:
- `docs/SYNTAX.md`
- `docs/PATTERNS.md`

### Heterogeneous outputs

Use:
- `ChoiceOf` when all branches already share one output type
- `HeterogeneousChoiceOf` when branches need unification behind an enum/protocol

Preferred style:

```swift
let parser = HeterogeneousChoiceOf<Substring, Statement> {
    selectParser.mapTo(Statement.select)
    insertParser.mapTo(Statement.insert)
}
```

Keep `eraseOutput(...)` for lower-level or more explicit output erasure.

### Whitespace and tokenization

Do not hardcode SQL-like whitespace/comment assumptions into new parsers.

Use:
- `ImplicitWhitespace(configuration:)`
- `Whitespace(configuration:)`
- `TokenMode(..., configuration:)`
- `CommentSyntax`
- `WhitespaceConfiguration`

### Diagnostics and recovery

When adding or changing parse failures:
- preserve position information where possible
- prefer `Expected(...)` for user-facing grammar boundaries
- use `parseWithLocation(_:)` when parsing a full source string for diagnostics
- keep recovery workflows generic via `Recover` and `RecoveringMany`

## Testing Expectations

Every meaningful public change should include tests.

Testing guidelines:
- place tests in the feature-appropriate folder under `Tests/`
- cover both correctness and intended usage ergonomics
- add examples for new overloads/helpers, not just bare success/failure
- when docs show a new “recommended” style, add a test that proves it works

Common command:

```bash
swift test
```

## Documentation Expectations

If you add or change a public API:

- update `docs/SYNTAX.md`
  - signatures
  - behavior notes
  - at least one focused example
- update `docs/PATTERNS.md` if the change affects:
  - recommended defaults
  - parser composition style
  - recovery/batching workflows
  - AST-building patterns

`SYNTAX.md` is the exhaustive reference.
`PATTERNS.md` is the opinionated cookbook.

## Change Guidance For Future Agents

- Prefer extending existing abstractions before inventing new top-level ones.
- Keep names construction-oriented and readable.
  - Example: `mapTo(...)` is preferred to a larger custom node DSL.
- If a feature cannot be implemented cleanly with `swift-parsing` as a thin layer, say so explicitly rather than forcing an awkward abstraction.
- For downstream language support, provide primitives and configuration points, not embedded grammar policies.

## Good Starting Files

For orientation, start with:

- `README.md`
- `docs/SYNTAX.md`
- `docs/PATTERNS.md`
- `Sources/Combinators/HeterogeneousChoiceOf.swift`
- `Sources/Whitespace/ImplicitWhitespace.swift`
- `Sources/Whitespace/WhitespaceConfiguration.swift`
- `Sources/Matchers/Identifier.swift`
- `Sources/Matchers/StringLiteral.swift`
- `Sources/Convenience/BatchSplitter.swift`
- `Sources/Convenience/BatchedParse.swift`
- `Sources/ErrorHandling/RecoveringMany.swift`
- `Sources/Rules/PrecedenceGroup.swift`
- `Sources/Rules/Recursive.swift`
- `Sources/Rules/Memoized.swift`

## Summary

When in doubt:
- keep it generic
- prefer composable primitives
- follow the documented recommended patterns
- test the public-facing usage style
- update both reference docs and patterns docs
