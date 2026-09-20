package cjregex

import std.collection.*

// A deliberately restricted syntax adapter. This is not a port of the full
// regex-syntax AST/HIR API. Unsupported constructs fail before execution.
enum ExprKind {
    Empty | Literal | CharacterClass | Any | Begin | End | Concat | Alternate | Repeat
}

class Expr {
    let kind: ExprKind
    let ch: Rune
    let children: Array<Expr>
    let greedy: Bool
    var minimum: Int64 = 0
    var maximum: Int64 = 0 // -1 means unbounded
    var charset = CharSet()
    init(kind: ExprKind, ch: Rune, children: Array<Expr>, greedy: Bool) {
        this.kind = kind
        this.ch = ch
        this.children = children
        this.greedy = greedy
    }
}

class Parser {
    let chars = ArrayList<Rune>()
    var pos: Int64 = 0
    var depth: Int64 = 0
    init(pattern: String) {
        if (pattern.size > 4096) {
            throw Exception("pattern exceeds 4096 UTF-8 bytes")
        }
        for (c in pattern.runes()) {
            chars.add(c)
        }
    }
    func fail(message: String): Nothing {
        throw Exception("pattern scalar ${pos}: ${message}")
    }
    func at(c: Rune): Bool {
        pos < chars.size && chars[pos] == c
    }
    func leaf(kind: ExprKind, ch: Rune): Expr {
        Expr(kind, ch, [], true)
    }
    func parse(): Expr {
        let result = alternate()
        if (pos != chars.size) {
            fail("unexpected closing parenthesis")
        }
        return result
    }
    func alternate(): Expr {
        let parts = ArrayList<Expr>()
        parts.add(concat())
        while (at(r'|')) {
            pos++
            parts.add(concat())
        }
        return Expr(ExprKind.Alternate, r' ', parts.toArray(), true)
    }
    func concat(): Expr {
        let parts = ArrayList<Expr>()
        while (pos < chars.size && !at(r'|') && !at(r')')) {
            parts.add(repetition())
        }
        return Expr(ExprKind.Concat, r' ', parts.toArray(), true)
    }
    func repetition(): Expr {
        var expr = atom()
        if (at(r'*') || at(r'+') || at(r'?') || at(r'{')) {
            let quantifier = chars[pos]
            pos++
            var minimum: Int64 = 0
            var maximum: Int64 = -1
            match (quantifier) {
                case r'+' => minimum = 1
                case r'?' => maximum = 1
                case r'{' =>
                    minimum = decimal()
                    maximum = minimum
                    if (at(r',')) {
                        pos++
                        maximum = if (at(r'}')) {
                            -1
                        } else {
                            decimal()
                        }
                    }
                    if (!at(r'}')) {
                        fail("unclosed or malformed counted repetition")
                    }
                    pos++
                    if (maximum >= 0 && minimum > maximum) {
                        fail("repetition minimum exceeds maximum")
                    }
                case _ => ()
            }
            var greedy = true
            if (at(r'?')) {
                greedy = false
                pos++
            }
            expr = Expr(ExprKind.Repeat, quantifier, [expr], greedy)
            expr.minimum = minimum
            expr.maximum = maximum
            if (at(r'*') || at(r'+') || at(r'?') || at(r'{')) {
                fail("stacked repetitions are not supported; use explicit groups")
            }
        }
        return expr
    }
    func decimal(): Int64 {
        if (pos == chars.size || chars[pos] < r'0' || chars[pos] > r'9') {
            fail("expected an ASCII repetition count (whitespace is not supported)")
        }
        var value: Int64 = 0
        while (pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'9') {
            value = value * 10 + Int64(UInt32(chars[pos]) - UInt32(r'0'))
            if (value > 10000) {
                fail("repetition count exceeds 10000")
            }
            pos++
        }
        return value
    }
    func atom(): Expr {
        let c = chars[pos]
        pos++
        match (c) {
            case r'(' =>
                depth++
                if (depth > 64) {
                    fail("group nesting exceeds 64")
                }
                if (at(r'?')) {
                    pos++
                    if (!at(r':')) {
                        fail("only (?:...) group prefixes are supported")
                    }
                    pos++
                }
                let expr = alternate()
                if (!at(r')')) {
                    fail("unclosed group")
                }
                pos++
                depth--
                return expr
            case r'.' => return leaf(ExprKind.Any, c)
            case r'^' => return leaf(ExprKind.Begin, c)
            case r'$' => return leaf(ExprKind.End, c)
            case r'\\' => return escaped()
            case r'[' =>
                let expr = leaf(ExprKind.CharacterClass, c)
                expr.charset = characterClass()
                return expr
            case r'{' => fail("repetition without an expression")
            case r'*' | r'+' | r'?' => fail("repetition without an expression")
            case _ => return leaf(ExprKind.Literal, c)
        }
    }
    func classOperator(): Bool {
        if (pos + 1 >= chars.size || chars[pos] != chars[pos + 1]) {
            return false
        }
        return at(r'&') || at(r'-') || at(r'~')
    }
    // Opening '[' has already been consumed. Class operators are left associative;
    // union (juxtaposition) binds more tightly, as in regex-syntax's class stack.
    func characterClass(): CharSet {
        depth++
        if (depth > 64) {
            fail("group/class nesting exceeds 64")
        }
        var negate = false
        if (at(r'^')) {
            negate = true
            pos++
        }
        var first = CharSet()
        var hasLeadingHyphen = false
        while (at(r'-')) {
            first.addRange(45, 45)
            hasLeadingHyphen = true
            pos++
        }
        if (!hasLeadingHyphen && at(r']')) {
            first.addRange(93, 93);
            pos++
        }
        first.unionWith(classUnion())
        while (classOperator()) {
            let op = chars[pos]
            pos += 2
            let rhs = classUnion()
            match (op) {
                case r'&' => first = first.intersect(rhs)
                case r'-' => first = first.difference(rhs)
                case _ => first = first.symmetricDifference(rhs)
            }
        }
        if (!at(r']')) {
            fail("unclosed character class")
        }
        pos++
        depth--
        return if (negate) {
            first.negated()
        } else {
            first
        }
    }
    func classUnion(): CharSet {
        let result = CharSet()
        while (pos < chars.size && !at(r']') && !classOperator()) {
            if (at(r'[')) {
                pos++
                if (at(r':')) {
                    fail("POSIX named classes are not supported yet")
                }
                result.unionWith(characterClass())
                continue
            }
            let low = classLiteral()
            var high = low
            if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
                pos++
                high = classLiteral()
                if (low > high) {
                    fail("character class range is reversed")
                }
            }
            result.addRange(Int64(UInt32(low)), Int64(UInt32(high)))
        }
        return result
    }
    func classLiteral(): Rune {
        if (pos == chars.size) {
            fail("unclosed character class")
        }
        let c = chars[pos]
        pos++
        if (c == r'[' || c == r']') {
            fail("range endpoints must be literal characters")
        }
        if (c != r'\\') {
            return c
        }
        let expr = escaped()
        match (expr.kind) {
            case ExprKind.Literal => return expr.ch
            case _ => fail("assertions cannot be used inside character classes")
        }
    }
    func escaped(): Expr {
        if (pos == chars.size) {
            fail("trailing escape")
        }
        let c = chars[pos]
        pos++
        match (c) {
            case r'n' => return leaf(ExprKind.Literal, r'\n')
            case r'r' => return leaf(ExprKind.Literal, r'\r')
            case r't' => return leaf(ExprKind.Literal, r'\t')
            case r'A' => return leaf(ExprKind.Begin, c)
            case r'z' => return leaf(ExprKind.End, c)
            case _ =>
                let n = UInt32(c)
                let alpha = (c >= r'a' && c <= r'z') || (c >= r'A' && c <= r'Z')
                let digit = c >= r'0' && c <= r'9'
                if (n >= 32 && n <= 126 && !alpha && !digit) {
                    return leaf(ExprKind.Literal, c)
                }
                fail(
                    "unsupported escape (Unicode classes, boundaries, hex escapes and backreferences are not implemented)")
        }
    }
}
