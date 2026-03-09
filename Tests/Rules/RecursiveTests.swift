import PegexBuilder
import Testing

@Suite("RecursiveTests")
struct RecursiveTests {
    private var numberParser: AnyParser<Substring, Int> {
        Prefix { $0.isNumber }.map { Int(String($0))! }.eraseToAnyParser()
    }

    @Test func recursiveNestedParentheses() {
        let expr = Recursive<Substring, Int> { ref in
            AnyParser { (input: inout Substring) in
                var copy = input
                do {
                    _ = try "(".parse(&copy)
                    let inner = try ref.parse(&copy)
                    _ = try ")".parse(&copy)
                    input = copy
                    return inner
                } catch {
                    let result = try self.numberParser.parse(&copy)
                    input = copy
                    return result
                }
            }
        }
        var input = "((42))"[...]
        let result = try? expr.parse(&input)
        #expect(result == 42)
    }

    @Test func recursiveSingleNumber() {
        let expr = Recursive<Substring, Int> { ref in
            AnyParser { (input: inout Substring) in
                var copy = input
                do {
                    _ = try "(".parse(&copy)
                    let inner = try ref.parse(&copy)
                    _ = try ")".parse(&copy)
                    input = copy
                    return inner
                } catch {
                    let result = try self.numberParser.parse(&copy)
                    input = copy
                    return result
                }
            }
        }
        var input = "99"[...]
        let result = try? expr.parse(&input)
        #expect(result == 99)
    }

    @Test func recursiveRightAssociative() {
        let expr = Recursive<Substring, Int> { ref in
            AnyParser { (input: inout Substring) in
                var copy = input
                let n = try self.numberParser.parse(&copy)
                do {
                    _ = try " + ".parse(&copy)
                    let rest = try ref.parse(&copy)
                    input = copy
                    return n + rest
                } catch {
                    input = copy
                    return n
                }
            }
        }
        var input = "1 + 2 + 3"[...]
        let result = try? expr.parse(&input)
        #expect(result == 6)
    }
}
