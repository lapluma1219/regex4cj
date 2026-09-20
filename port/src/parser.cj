package cjregex

import std.collection.*

// A deliberately restricted syntax adapter. This is not a port of the full
// regex-syntax AST/HIR API. Unsupported constructs fail before execution.
enum ExprKind {
    Empty | Literal | Any | Begin | End | Concat | Alternate | Repeat
}

class Expr {
    let kind: ExprKind
    let ch: Rune
    let children: Array<Expr>
    let greedy: Bool
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
        if (at(r'*') || at(r'+') || at(r'?')) {
            let quantifier = chars[pos]
            pos++
            var greedy = true
            if (at(r'?')) {
                greedy = false
                pos++
            }
            expr = Expr(ExprKind.Repeat, quantifier, [expr], greedy)
            if (at(r'*') || at(r'+') || at(r'?')) {
                fail("stacked repetitions are not supported; use explicit groups")
            }
        }
        return expr
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
            case r'[' | r']' | r'{' | r'}' => fail("character classes and counted repetitions are not supported")
            case r'*' | r'+' | r'?' => fail("repetition without an expression")
            case _ => return leaf(ExprKind.Literal, c)
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
