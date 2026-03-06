// PEGExBuilders - Commit / no-backtrack marker

import Foundation
import Parsing

@usableFromInline
final class CutContextState {
    @usableFromInline
    var didCommit = false
    @usableFromInline
    var position: PEGExPosition?
}

@usableFromInline
enum CutContext {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var stack: [CutContextState] = []

    @usableFromInline
    static func push() -> CutContextState {
        lock.lock()
        defer { lock.unlock() }
        let state = CutContextState()
        stack.append(state)
        return state
    }

    @usableFromInline
    static func pop() {
        lock.lock()
        defer { lock.unlock() }
        _ = stack.popLast()
    }

    @usableFromInline
    static func commit(at position: PEGExPosition) {
        lock.lock()
        defer { lock.unlock() }
        guard let state = stack.last else { return }
        state.didCommit = true
        state.position = position
    }
}

/// A parser that succeeds immediately without consuming input.
/// When used inside ChoiceOf, signals that backtracking should be disabled -
/// if parsing fails after Cut, the error propagates instead of trying alternatives.
public struct Cut<Input: Collection>: Parser
where Input.SubSequence == Input {
    public typealias Output = Void

    @inlinable
    public init() {}

    @inlinable
    public func parse(_ input: inout Input) throws -> Void {
        CutContext.commit(at: PEGExPosition(input))
    }
}
