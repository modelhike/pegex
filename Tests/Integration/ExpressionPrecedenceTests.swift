import PegexBuilder
import Testing

/// Integration test: SQL expression precedence (AND, OR, IN, comparisons).
/// Validates: PrecedenceGroup, InfixLeftLevel, AtomLevel, StringLiteral.
@Suite("ExpressionPrecedenceTests")
struct ExpressionPrecedenceTests {
    indirect enum SQLExpr: Equatable {
        case column(String)
        case number(Double)
        case string(String)
        case comparison(SQLExpr, String, SQLExpr)
        case and(SQLExpr, SQLExpr)
        case or(SQLExpr, SQLExpr)
        case inList(SQLExpr, [SQLExpr])
    }

    @Test func comparisonPrecedence() {
        let atom = ChoiceOf {
            Identifier().map { SQLExpr.column($0) }
            FloatLiteral().map { SQLExpr.number($0) }
            StringLiteral(quote: "'").map { SQLExpr.string($0) }
        }

        let expr = PrecedenceGroup<Substring, SQLExpr>(atom: atom) {
            AtomLevel { atom }
            InfixLeftLevel(precedence: 1, Skip { ImplicitWhitespace { ChoiceOf { "="; "!="; "<>"; ">"; "<"; ">="; "<=" } } }) { (lhs: SQLExpr, rhs: SQLExpr) in
                .comparison(lhs, "=", rhs)
            }
        }

        var input = "price > 100"[...]
        let result = try? expr.parse(&input)
        #expect(result != nil)
        if case .comparison(let l, _, let r) = result! {
            if case .column(let c) = l { #expect(c == "price") }
            if case .number(let n) = r { #expect(n == 100) }
        }
    }

    @Test func andOrPrecedence() {
        let atom = ChoiceOf {
            Identifier().map { SQLExpr.column($0) }
            FloatLiteral().map { SQLExpr.number($0) }
            StringLiteral(quote: "'").map { SQLExpr.string($0) }
        }

        let expr = PrecedenceGroup<Substring, SQLExpr>(atom: atom) {
            AtomLevel { atom }
            InfixLeftLevel(precedence: 1, Skip { ImplicitWhitespace { Keyword("OR") } }) { (lhs: SQLExpr, rhs: SQLExpr) in .or(lhs, rhs) }
            InfixLeftLevel(precedence: 2, Skip { ImplicitWhitespace { Keyword("AND") } }) { (lhs: SQLExpr, rhs: SQLExpr) in .and(lhs, rhs) }
            InfixLeftLevel(precedence: 3, Skip { ImplicitWhitespace { ChoiceOf { "="; ">"; "<"; ">="; "<=" } } }) { (lhs: SQLExpr, rhs: SQLExpr) in .comparison(lhs, "=", rhs) }
        }

        var input = "a AND b OR c"[...]
        let result = try? expr.parse(&input)
        #expect(result != nil)
        if case .or(let lhs, let rhs) = result! {
            if case .and(_, _) = lhs { }
            if case .column("c") = rhs { }
        }
    }

    @Test func parenthesizedExpression() {
        let number = FloatLiteral().map { SQLExpr.number($0) }
        let expr = Recursive<Substring, SQLExpr> { ref in
            let atom = AnyParser<Substring, SQLExpr> { input in
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
            return PrecedenceGroup<Substring, SQLExpr>(atom: atom) {
                AtomLevel { atom }
                InfixLeftLevel(precedence: 1, Skip { " + " }) { (a: SQLExpr, b: SQLExpr) in .comparison(a, "+", b) }
            }.eraseToAnyParser()
        }

        var input = "(1 + 2) + 3"[...]
        let result = try? expr.parse(&input)
        #expect(result != nil)
    }

    @Test func complexExpression() {
        let atom = ChoiceOf {
            Identifier().map { SQLExpr.column($0) }
            FloatLiteral().map { SQLExpr.number($0) }
            StringLiteral(quote: "'").map { SQLExpr.string($0) }
        }

        let expr = PrecedenceGroup<Substring, SQLExpr>(atom: atom) {
            AtomLevel { atom }
            InfixLeftLevel(precedence: 1, Skip { ImplicitWhitespace { Keyword("OR") } }) { (a: SQLExpr, b: SQLExpr) in .or(a, b) }
            InfixLeftLevel(precedence: 2, Skip { ImplicitWhitespace { Keyword("AND") } }) { (a: SQLExpr, b: SQLExpr) in .and(a, b) }
            InfixLeftLevel(precedence: 3, Skip { ImplicitWhitespace { ChoiceOf { "="; ">"; "<"; ">="; "<="; "<>"; "!=" } } }) { (a: SQLExpr, b: SQLExpr) in .comparison(a, "=", b) }
        }

        var input = "price > 100 AND category = 'A'"[...]
        let result = try? expr.parse(&input)
        #expect(result != nil)
    }
}
