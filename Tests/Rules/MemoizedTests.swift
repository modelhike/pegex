import PegexBuilder
import Parsing
import Testing

@Suite("MemoizedTests")
struct MemoizedTests {
    @Test func memoizedParsesSuccessfully() {
        let memoTable = MemoTable()
        let parser = Memoized("num", memoTable: memoTable) {
            Int.parser().pullback(\.utf8)
        }
        var input = "42"[...]
        let result = try? parser.parse(&input)
        #expect(result == 42)
        #expect(input.isEmpty)
    }

    @Test func memoizedWithinRecursion() {
        let memoTable = MemoTable()
        let numberParser = Prefix { $0.isNumber }.map { Int(String($0))! }
        let expr = Recursive<Substring, Int> { ref in
            let memoized = Memoized("expr", memoTable: memoTable) {
                Parsing.AnyParser { (input: inout Substring) in
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
            return memoized.eraseToAnyParser()
        }
        var input = "((7))"[...]
        let result = try? expr.parse(&input)
        #expect(result == 7)
    }

    @Test func memoizedWithPrefix() {
        let memoTable = MemoTable()
        let parser = Memoized("digit", memoTable: memoTable) {
            Prefix(1) { $0.isNumber }.map { Int(String($0))! }
        }
        var input = "5"[...]
        let result = try? parser.parse(&input)
        #expect(result == 5)
        #expect(input.isEmpty)
    }
}
