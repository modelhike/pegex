// PEGExBuilders - Packrat memoization cache

import Parsing

/// Thread-unsafe memoization cache for packrat parsing.
/// Create a fresh instance per parse; do not share across concurrent parses.
public final class MemoTable<Input: Collection>: @unchecked Sendable
where Input.Index: Hashable {
    private var storage: [String: [Input.Index: Result<(Any, Input.Index), Error>]] = [:]

    public init() {}

    public func lookup<Output>(_ ruleName: String, at index: Input.Index, as outputType: Output.Type) -> Result<(Output, Input.Index), Error>? {
        guard let entry = storage[ruleName]?[index] else { return nil }
        return entry.map { pair in (pair.0 as! Output, pair.1) }
    }

    public func store<Output>(_ ruleName: String, at index: Input.Index, result: Result<(Output, Input.Index), Error>) {
        if storage[ruleName] == nil { storage[ruleName] = [:] }
        storage[ruleName]![index] = result.map { ($0 as Any, $1) }
    }
}
