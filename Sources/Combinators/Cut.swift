// PEGExBuilders - Commit / no-backtrack marker

import Parsing

/// A parser that succeeds immediately without consuming input.
/// When used inside ChoiceOf, signals that backtracking should be disabled -
/// if parsing fails after Cut, the error propagates instead of trying alternatives.
/// Note: Full Cut semantics require ChoiceOf integration; this is a placeholder.
public struct Cut<Input: Collection>: Parser
where Input.SubSequence == Input {
    public typealias Output = Void

    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws -> Void {
        // Succeed without consuming - Cut is a zero-width commit marker
    }
}
