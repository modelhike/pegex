// PEGExBuilders - Memoization wrapper

import Parsing

/// A parser that caches results for packrat parsing.
/// Pass a fresh MemoTable per parse; do not share across concurrent parses.
public struct Memoized<Input, Output, Upstream: Parser>: Parser
where Input: Collection, Input.SubSequence == Input, Input.Index: Hashable, Upstream.Input == Input, Upstream.Output == Output {
    @usableFromInline
    let ruleName: String
    @usableFromInline
    let memoTable: MemoTable<Input>
    @usableFromInline
    let upstream: Upstream

    @inlinable
    public init(_ ruleName: String, memoTable: MemoTable<Input>, @ParserBuilder<Input> _ build: () -> Upstream) {
        self.ruleName = ruleName
        self.memoTable = memoTable
        self.upstream = build()
    }

    @inlinable
    public func parse(_ input: inout Input) throws -> Output {
        let index = input.startIndex
        if let cached = memoTable.lookup(ruleName, at: index, as: Output.self) {
            switch cached {
            case .success(let (output, newIndex)):
                input = input[newIndex...]
                return output
            case .failure(let error):
                throw error
            }
        }
        var copy = input
        let result: Result<(Output, Input.Index), Error>
        do {
            let output = try upstream.parse(&copy)
            let newIndex = copy.startIndex
            result = .success((output, newIndex))
        } catch {
            result = .failure(error)
        }
        memoTable.store(ruleName, at: index, result: result)
        switch result {
        case .success(let (output, newIndex)):
            input = input[newIndex...]
            return output
        case .failure(let error):
            throw error
        }
    }
}
