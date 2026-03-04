import PegexBuilder
import Parsing
import Testing

@Suite("PrecedenceGroupTests")
struct PrecedenceGroupTests {
    @Test func arithmeticPrecedence() {
        let number = Prefix { $0.isNumber }.map { Int(String($0))! }
        let levels: [AnyPrecedenceLevel<Substring, Int>] = [
            AtomLevel { number }.eraseToPrecedenceLevel(),
            InfixLeftLevel(precedence: 1, Skip { " + " }) { (a: Int, b: Int) in a + b }.eraseToPrecedenceLevel(),
            InfixLeftLevel(precedence: 1, Skip { " - " }) { (a: Int, b: Int) in a - b }.eraseToPrecedenceLevel(),
            InfixLeftLevel(precedence: 2, Skip { " * " }) { (a: Int, b: Int) in a * b }.eraseToPrecedenceLevel(),
            InfixLeftLevel(precedence: 2, Skip { " / " }) { (a: Int, b: Int) in a / b }.eraseToPrecedenceLevel(),
        ]
        let parser = PrecedenceGroup<Substring, Int>(atom: number, levels: levels)
        var input = "1 + 2 * 3"[...]
        let result = try? parser.parse(&input)
        #expect(result == 7)  // 1 + (2 * 3)
    }

    @Test func arithmeticWithBuilder() {
        let number = Prefix { $0.isNumber }.map { Int(String($0))! }
        let parser = PrecedenceGroup(atom: number) {
            AtomLevel { number }
            InfixLeftLevel(precedence: 1, Skip { " + " }) { (a: Int, b: Int) in a + b }
            InfixLeftLevel(precedence: 2, Skip { " * " }) { (a: Int, b: Int) in a * b }
        }
        var input = "10 * 2 + 1"[...]
        let result = try? parser.parse(&input)
        #expect(result == 21)  // (10 * 2) + 1
    }

    @Test func prefixNegation() {
        let number = Prefix { $0.isNumber }.map { Int(String($0))! }
        let parser = PrecedenceGroup(atom: number) {
            AtomLevel { number }
            PrefixLevel(precedence: 3, Skip { "-" }) { (x: Int) in -x }
            InfixLeftLevel(precedence: 1, Skip { " + " }) { (a: Int, b: Int) in a + b }
        }
        var input = "-5"[...]
        let result = try? parser.parse(&input)
        #expect(result == -5)
    }

    @Test func nestedParentheses() {
        let number = Prefix { $0.isNumber }.map { Int(String($0))! }
        let expr = Recursive<Substring, Int> { ref in
            let atom = Parsing.AnyParser<Substring, Int> { (input: inout Substring) in
                var copy = input
                do {
                    _ = try "(".parse(&copy)
                    let inner = try ref.parse(&copy)
                    _ = try ")".parse(&copy)
                    input = copy
                    return inner
                } catch {
                    let result = try number.parse(&copy)
                    input = copy
                    return result
                }
            }
            return PrecedenceGroup(atom: atom) {
                AtomLevel { atom }
                InfixLeftLevel(precedence: 1, Skip { " + " }) { (a: Int, b: Int) in a + b }
                InfixLeftLevel(precedence: 2, Skip { " * " }) { (a: Int, b: Int) in a * b }
            }.eraseToAnyParser()
        }
        var input = "(1 + 2) * 3"[...]
        let result = try? expr.parse(&input)
        #expect(result == 9)
    }
}
