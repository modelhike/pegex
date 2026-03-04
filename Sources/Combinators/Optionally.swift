// PEGExBuilders - Optional parser (re-exports swift-parsing's Optionally)

import Parsing

/// A parser that runs the inner parser and succeeds with nil if it fails.
/// Re-exports Parsing.Optionally for PEGEx API consistency.
public typealias Optionally<Input, Wrapped: Parser> = Parsing.Optionally<Input, Wrapped>
where Wrapped.Input == Input
