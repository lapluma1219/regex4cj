package cjregex

import std.collection.*

// A deliberately restricted syntax adapter. This is not a port of the full
// regex-syntax AST/HIR API. Unsupported constructs fail before execution.
enum ExprKind {
    Empty | Literal | CharacterClass | Any | Begin | End | WordBoundary | Concat | Alternate | Repeat | Capture
}

class Expr {
    let kind: ExprKind
    let ch: Rune
    let children: Array<Expr>
    let greedy: Bool
    var minimum: Int64 = 0
    var maximum: Int64 = 0 // -1 means unbounded
    var charset = CharSet()
    var multiline = false
    var dotAll = false
    var flagOnly = false
    var captureIndex: Int64 = -1
    init(kind: ExprKind, ch: Rune, children: Array<Expr>, greedy: Bool) {
        this.kind = kind
        this.ch = ch
        this.children = children
        this.greedy = greedy
    }
}

class Parser {
    let chars = ArrayList<Rune>()
    let captureNames = ArrayList<String>()
    var pos: Int64 = 0
    var depth: Int64 = 0
    var multiline = false
    var dotAll = false
    var swapGreed = false
    init(pattern: String) {
        captureNames.add("") // group 0 denotes the entire match
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
            if (expr.flagOnly) {
                fail("repetition without an expression")
            }
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
            var greedy = !swapGreed
            if (at(r'?')) {
                greedy = !greedy
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
                let oldMultiline = multiline
                let oldDotAll = dotAll
                let oldSwapGreed = swapGreed
                depth++
                if (depth > 64) {
                    fail("group nesting exceeds 64")
                }
                var capturing = true
                var name = ""
                if (at(r'?')) {
                    pos++
                    if (at(r':')) {
                        capturing = false
                        pos++
                    } else if (at(r'<') || at(r'P')) {
                        if (at(r'P')) {
                            pos++
                        }
                        if (!at(r'<')) {
                            fail("unsupported group prefix or flags")
                        }
                        pos++
                        name = captureName()
                    } else {
                        parseFlags()
                        capturing = false
                        if (at(r')')) {
                            pos++;
                            depth--
                            let directive = leaf(ExprKind.Empty, r' ')
                            directive.flagOnly = true
                            return directive
                        }
                        pos++ // ':' begins a scoped noncapturing group
                    }
                }
                var index: Int64 = -1
                if (capturing) {
                    if (captureNames.size >= 129) {
                        fail("capture group count exceeds 128")
                    }
                    if (name != "") {
                        for (existing in captureNames) {
                            if (existing == name) {
                                fail("duplicate capture group name")
                            }
                        }
                    }
                    index = captureNames.size
                    captureNames.add(name)
                }
                let expr = alternate()
                if (!at(r')')) {
                    fail("unclosed group")
                }
                pos++
                depth--
                multiline = oldMultiline
                dotAll = oldDotAll
                swapGreed = oldSwapGreed
                if (!capturing) {
                    return expr
                }
                let group = Expr(ExprKind.Capture, r' ', [expr], true)
                group.captureIndex = index
                return group
            case r'.' =>
                let expr = leaf(ExprKind.Any, c)
                expr.dotAll = dotAll
                return expr
            case r'^' | r'$' =>
                let expr = leaf(if (c == r'^') {
                    ExprKind.Begin
                } else {
                    ExprKind.End
                }, c)
                expr.multiline = multiline
                return expr
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
    // Inline flags alter the remainder of the current group, including later
    // alternatives. Every actual group restores its outer lexical flag state.
    func parseFlags(): Unit {
        var enabled = true
        var negation = false
        var dangling = false
        let seen = ArrayList<Rune>()
        if (at(r')')) {
            fail("empty flag directive")
        }
        while (!at(r':') && !at(r')')) {
            if (pos == chars.size) {
                fail("unclosed flags")
            }
            let c = chars[pos]
            pos++
            if (c == r'-') {
                if (negation) {
                    fail("repeated flag negation")
                }
                negation = true
                enabled = false
                dangling = true
                continue
            }
            for (previous in seen) {
                if (previous == c) {
                    fail("duplicate flag")
                }
            }
            seen.add(c)
            dangling = false
            match (c) {
                case r'm' => multiline = enabled
                case r's' => dotAll = enabled
                case r'U' => swapGreed = enabled
                case _ => fail("unsupported flag (only m, s and U are implemented)")
            }
        }
        if (dangling) {
            fail("dangling flag negation")
        }
    }
    func captureName(): String {
        let name = StringBuilder()
        var first = true
        while (pos < chars.size && !at(r'>')) {
            let c = chars[pos]
            if (UInt32(c) > 127) {
                fail("Unicode capture names are not supported yet")
            }
            let alpha = (c >= r'a' && c <= r'z') || (c >= r'A' && c <= r'Z')
            let tail = (c >= r'0' && c <= r'9') || c == r'.' || c == r'[' || c == r']'
            if (!(alpha || c == r'_' || (!first && tail))) {
                fail("invalid capture group name")
            }
            name.append(c)
            pos++
            first = false
        }
        if (first) {
            fail("empty capture group name")
        }
        if (!at(r'>')) {
            fail("unclosed capture group name")
        }
        pos++
        return name.toString()
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
                match (namedClass()) {
                    case Some(named) => result.unionWith(named)
                    case None => result.unionWith(characterClass())
                }
                continue
            }
            if (at(r'\\') && pos + 1 < chars.size && shorthand(chars[pos + 1])) {
                pos++
                result.unionWith(escaped().charset)
                if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
                    fail("range endpoints must be literal characters")
                }
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
    // '[' is already consumed. Probe without advancing on failure: unknown
    // names and incomplete delimiters fall back to ordinary nested classes.
    func namedClass(): Option<CharSet> {
        if (!at(r':')) {
            return None
        }
        var cursor = pos + 1
        var negate = false
        if (cursor < chars.size && chars[cursor] == r'^') {
            negate = true
            cursor++
        }
        let name = StringBuilder()
        while (cursor < chars.size && chars[cursor] != r':') {
            name.append(chars[cursor]);
            cursor++
        }
        if (cursor + 1 >= chars.size || chars[cursor + 1] != r']') {
            return None
        }
        match (asciiClass(name.toString())) {
            case None => return None
            case Some(set) =>
                pos = cursor + 2
                return Some(if (negate) {
                    set.negated()
                } else {
                    set
                })
        }
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
            case _ => fail("range endpoints must be literal characters")
        }
    }
    // Fixed-width and braced Unicode scalar escapes share the class/literal path.
    func hexScalar(kind: Rune): Rune {
        let braced = at(r'{')
        if (braced) {
            pos++
        }
        let width: Int64 = if (kind == r'x') {
            2
        } else if (kind == r'u') {
            4
        } else {
            8
        }
        var count: Int64 = 0
        var value: Int64 = 0
        while (if (braced) {
                !at(r'}')
            } else {
                count < width
            }) {
            if (pos == chars.size) {
                fail("incomplete hexadecimal escape")
            }
            let c = chars[pos]
            var digit: Int64 = -1
            if (c >= r'0' && c <= r'9') {
                digit = Int64(UInt32(c) - UInt32(r'0'))
            } else if (c >= r'a' && c <= r'f') {
                digit = Int64(UInt32(c) - UInt32(r'a')) + 10
            } else if (c >= r'A' && c <= r'F') {
                digit = Int64(UInt32(c) - UInt32(r'A')) + 10
            }
            if (digit < 0) {
                fail("invalid hexadecimal digit")
            }
            value = value * 16 + digit
            // Check on each digit before a subsequent multiplication can overflow.
            if (value > 0x10FFFF) {
                fail("hexadecimal escape exceeds Unicode range")
            }
            pos++;
            count++
        }
        if (count == 0) {
            fail("empty hexadecimal escape")
        }
        if (braced) {
            pos++
        }
        if (value >= 0xD800 && value <= 0xDFFF) {
            fail("surrogate is not a Unicode scalar")
        }
        return Rune(UInt32(value))
    }
    func escaped(): Expr {
        if (pos == chars.size) {
            fail("trailing escape")
        }
        let c = chars[pos]
        pos++
        match (c) {
            case r'd' | r'D' | r's' | r'S' | r'w' | r'W' =>
                let lower = if (c == r'D') {
                    r'd'
                } else if (c == r'S') {
                    r's'
                } else if (c == r'W') {
                    r'w'
                } else {
                    c
                }
                let expr = leaf(ExprKind.CharacterClass, c)
                let set = unicodeClass(lower)
                expr.charset = if (lower == c) {
                    set
                } else {
                    set.negated()
                }
                return expr
            case r'x' | r'u' | r'U' => return leaf(ExprKind.Literal, hexScalar(c))
            case r'a' => return leaf(ExprKind.Literal, Rune(UInt32(7)))
            case r'f' => return leaf(ExprKind.Literal, Rune(UInt32(12)))
            case r'v' => return leaf(ExprKind.Literal, Rune(UInt32(11)))
            case r'n' => return leaf(ExprKind.Literal, r'\n')
            case r'r' => return leaf(ExprKind.Literal, r'\r')
            case r't' => return leaf(ExprKind.Literal, r'\t')
            case r'b' | r'B' => return leaf(ExprKind.WordBoundary, c)
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
                    "unsupported escape (Unicode properties, advanced boundaries and backreferences are not implemented)")
        }
    }
}

func shorthand(c: Rune): Bool {
    c == r'd' || c == r'D' || c == r's' || c == r'S' || c == r'w' || c == r'W'
}
