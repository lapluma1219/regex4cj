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
    var modeKind: Int64 = 0
    var modeTerm: Rune = r'\n'
    var modeUnicode: Bool = true
    var modePositive: Bool = true
    init(kind: ExprKind, ch: Rune, children: Array<Expr>, greedy: Bool) {
        this.kind = kind
        this.ch = ch
        this.children = children
        this.greedy = greedy
    }
}

// Shared by Regex and RegexSet. Defaults match Regex(pattern): Unicode on,
// octal off, LF line terminator, and the historical nest limit of 64.
class PatternOptions {
    var caseInsensitive = false
    var multiLine = false
    var dotAll = false
    var swapGreed = false
    var ignoreWhitespace = false
    var crlf = false
    var unicode = true
    var octal = false
    var lineTerminator: Rune = r'\n'
    var nestLimit: Int64 = 64
}

class Parser {
    let chars = ArrayList<Rune>()
    let captureNames = ArrayList<String>()
    let whitespace = binaryWhite_Space()
    var pos: Int64 = 0
    var depth: Int64 = 0
    var multiline = false
    var dotAll = false
    var swapGreed = false
    var caseInsensitive = false
    var ignoreWhitespace = false
    var crlf = false
    var unicode = true
    var octal = false
    var lineTerminator: Rune = r'\n'
    var nestLimit: Int64 = 64
    var nameReady = false
    var alphabetic = CharSet()
    var nameNumbers = CharSet()
    init(pattern: String) {
        this(pattern, PatternOptions())
    }
    init(pattern: String, options: PatternOptions) {
        captureNames.add("") // group 0 denotes the entire match
        if (pattern.size > 4096) {
            throw Exception("pattern exceeds 4096 UTF-8 bytes")
        }
        if (UInt32(options.lineTerminator) > 127) {
            throw Exception("line terminator must be an ASCII byte in string mode")
        }
        if (options.nestLimit < 1) {
            throw Exception("nest limit must be positive")
        }
        multiline = options.multiLine
        dotAll = options.dotAll
        swapGreed = options.swapGreed
        caseInsensitive = options.caseInsensitive
        ignoreWhitespace = options.ignoreWhitespace
        crlf = options.crlf
        unicode = options.unicode
        octal = options.octal
        lineTerminator = options.lineTerminator
        nestLimit = options.nestLimit
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
    // x mode ignores Unicode White_Space and # comments through the newline.
    // Callers must not use this between a backslash and its escaped character,
    // or inside capture names, flag letters, or hexadecimal digits.
    func skipSpace(): Unit {
        if (!ignoreWhitespace) {
            return
        }
        while (pos < chars.size) {
            let c = chars[pos]
            if (whitespace.contains(c)) {
                pos++
                continue
            }
            if (c != r'#') {
                break
            }
            pos++
            while (pos < chars.size) {
                let comment = chars[pos]
                pos++
                if (comment == r'\n') {
                    break
                }
            }
        }
    }
    func leaf(kind: ExprKind, ch: Rune): Expr {
        Expr(kind, ch, [], true)
    }
    func stamp(expr: Expr, kind: Int64): Expr {
        expr.modeKind = kind
        expr.modeTerm = lineTerminator
        expr.modeUnicode = unicode
        expr.modePositive = true
        return expr
    }
    func parse(): Expr {
        let result = alternate()
        skipSpace()
        if (pos != chars.size) {
            fail("unexpected closing parenthesis")
        }
        return result
    }
    func alternate(): Expr {
        let parts = ArrayList<Expr>()
        parts.add(concat())
        while (true) {
            skipSpace()
            if (!at(r'|')) {
                break
            }
            pos++
            parts.add(concat())
        }
        return Expr(ExprKind.Alternate, r' ', parts.toArray(), true)
    }
    func concat(): Expr {
        let parts = ArrayList<Expr>()
        while (true) {
            skipSpace()
            if (pos >= chars.size || at(r'|') || at(r')')) {
                break
            }
            parts.add(repetition())
        }
        return Expr(ExprKind.Concat, r' ', parts.toArray(), true)
    }
    func repetition(): Expr {
        var expr = atom()
        skipSpace()
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
            skipSpace()
            if (at(r'?')) {
                greedy = !greedy
                pos++
            }
            expr = Expr(ExprKind.Repeat, quantifier, [expr], greedy)
            expr.minimum = minimum
            expr.maximum = maximum
            skipSpace()
            if (at(r'*') || at(r'+') || at(r'?') || at(r'{')) {
                fail("stacked repetitions are not supported; use explicit groups")
            }
        }
        return expr
    }
    func decimal(): Int64 {
        skipSpace()
        if (pos == chars.size || chars[pos] < r'0' || chars[pos] > r'9') {
            fail("expected an ASCII repetition count")
        }
        var value: Int64 = 0
        while (pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'9') {
            value = value * 10 + Int64(UInt32(chars[pos]) - UInt32(r'0'))
            if (value > 10000) {
                fail("repetition count exceeds 10000")
            }
            pos++
            skipSpace()
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
                let oldCaseInsensitive = caseInsensitive
                let oldIgnoreWhitespace = ignoreWhitespace
                let oldCrlf = crlf
                let oldUnicode = unicode
                depth++
                if (depth > nestLimit) {
                    fail("group nesting exceeds ${nestLimit}")
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
                caseInsensitive = oldCaseInsensitive
                ignoreWhitespace = oldIgnoreWhitespace
                crlf = oldCrlf
                unicode = oldUnicode
                if (!capturing) {
                    return expr
                }
                let group = Expr(ExprKind.Capture, r' ', [expr], true)
                group.captureIndex = index
                return group
            case r'.' => return dot()
            case r'^' | r'$' => return anchor(c == r'^')
            case r'\\' =>
                let expr = escaped()
                match (expr.kind) {
                    case ExprKind.Literal => return finishLiteral(expr.ch)
                    case _ => return expr
                }
            case r'[' =>
                let expr = leaf(ExprKind.CharacterClass, c)
                expr.charset = characterClass()
                return expr
            case r'{' => fail("repetition without an expression")
            case r'*' | r'+' | r'?' => fail("repetition without an expression")
            case _ => return finishLiteral(c)
        }
    }
    func dot(): Expr {
        if (!unicode) {
            fail("pattern can match invalid UTF-8")
        }
        var kind: Int64 = 0
        if (dotAll) {
            kind = 1
        } else if (crlf) {
            kind = 2
        }
        return stamp(leaf(ExprKind.Any, r'.'), kind)
    }
    func anchor(begin: Bool): Expr {
        var kind: Int64 = if (begin) {
            0
        } else {
            1
        }
        if (multiline) {
            if (crlf) {
                kind = if (begin) {
                    4
                } else {
                    5
                }
            } else {
                kind = if (begin) {
                    2
                } else {
                    3
                }
            }
        }
        let expr = stamp(leaf(if (begin) {
            ExprKind.Begin
        } else {
            ExprKind.End
        }, if (begin) {
            r'^'
        } else {
            r'$'
        }), kind)
        expr.multiline = multiline
        return expr
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
                case r'i' => caseInsensitive = enabled
                case r'm' => multiline = enabled
                case r's' => dotAll = enabled
                case r'U' => swapGreed = enabled
                case r'x' => ignoreWhitespace = enabled
                case r'R' => crlf = enabled
                case r'u' => unicode = enabled
                case _ => fail("unsupported flag (only i, m, s, U, x, R and u are implemented)")
            }
        }
        if (dangling) {
            fail("dangling flag negation")
        }
    }
    func ensureNameClasses(): Unit {
        if (nameReady) {
            return
        }
        alphabetic = binaryAlphabetic()
        nameNumbers = generalCategory("nd")
        nameNumbers.unionWith(generalCategory("nl"))
        nameNumbers.unionWith(generalCategory("no"))
        nameReady = true
    }
    func captureChar(c: Rune, first: Bool): Bool {
        ensureNameClasses()
        if (first) {
            return c == r'_' || alphabetic.contains(c)
        }
        return c == r'_' || c == r'.' || c == r'[' || c == r']' || alphabetic.contains(c) || nameNumbers.contains(c)
    }
    func captureName(): String {
        let name = StringBuilder()
        var first = true
        while (pos < chars.size && !at(r'>')) {
            let c = chars[pos]
            if (!captureChar(c, first)) {
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
        if (depth > nestLimit) {
            fail("group/class nesting exceeds ${nestLimit}")
        }
        skipSpace()
        var negate = false
        if (at(r'^')) {
            negate = true
            pos++
            skipSpace()
        }
        var first = CharSet()
        var hasLeadingHyphen = false
        while (at(r'-')) {
            first.addRange(45, 45)
            hasLeadingHyphen = true
            pos++
            skipSpace()
        }
        if (!hasLeadingHyphen && at(r']')) {
            first.addRange(93, 93);
            pos++
            skipSpace()
        }
        first.unionWith(classUnion())
        while (classOperator()) {
            let op = chars[pos]
            pos += 2
            let rhs = classUnion()
            // Fold each operand before intersection or difference. Folding only
            // the final set would drop equivalents that the other side removed.
            foldClass(first)
            foldClass(rhs)
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
        foldClass(first)
        let folded = if (negate) {
            first.negated()
        } else {
            first
        }
        return finishAsciiClass(folded)
    }
    func foldClass(set: CharSet): Unit {
        if (!caseInsensitive) {
            return
        }
        if (unicode) {
            set.caseFoldSimple()
        } else {
            set.caseFoldAscii()
        }
    }
    func finishAsciiClass(set: CharSet): CharSet {
        if (!unicode && set.exceedsAscii()) {
            fail("pattern can match invalid UTF-8")
        }
        return set
    }
    func rejectClassScalar(c: Rune): Unit {
        if (!unicode && UInt32(c) > 127) {
            fail("Unicode not allowed here")
        }
    }
    func finishLiteral(c: Rune): Expr {
        if (!caseInsensitive || (!unicode && UInt32(c) > 127)) {
            return leaf(ExprKind.Literal, c)
        }
        let code = Int64(UInt32(c))
        let set = CharSet()
        set.addRange(code, code)
        if (unicode) {
            set.caseFoldSimple()
        } else {
            set.caseFoldAscii()
        }
        if (set.isOnly(code)) {
            return leaf(ExprKind.Literal, c)
        }
        let expr = leaf(ExprKind.CharacterClass, c)
        expr.charset = set
        return expr
    }
    func classUnion(): CharSet {
        let result = CharSet()
        while (true) {
            skipSpace()
            if (pos >= chars.size || at(r']') || classOperator()) {
                break
            }
            if (at(r'[')) {
                pos++
                match (namedClass()) {
                    case Some(named) => result.unionWith(named)
                    case None => result.unionWith(characterClass())
                }
                continue
            }
            if (at(r'\\') && pos + 1 < chars.size && classEscape(chars[pos + 1])) {
                pos++
                result.unionWith(escaped().charset)
                skipSpace()
                if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
                    fail("range endpoints must be literal characters")
                }
                continue
            }
            let low = classLiteral()
            var high = low
            skipSpace()
            if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
                pos++
                skipSpace()
                high = classLiteral()
                if (low > high) {
                    fail("character class range is reversed")
                }
            }
            rejectClassScalar(low)
            rejectClassScalar(high)
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
                foldClass(set)
                let folded = if (negate) {
                    set.negated()
                } else {
                    set
                }
                return Some(finishAsciiClass(folded))
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
    func propertyClass(negated: Bool): Expr {
        let name = StringBuilder()
        if (at(r'{')) {
            pos++
            while (pos < chars.size && !at(r'}')) {
                name.append(chars[pos]);
                pos++
            }
            if (!at(r'}')) {
                fail("unclosed Unicode property")
            }
            pos++
        } else {
            if (pos == chars.size) {
                fail("missing Unicode property")
            }
            name.append(chars[pos]);
            pos++
        }
        if (!unicode) {
            fail("Unicode not allowed here")
        }
        let expr = leaf(ExprKind.CharacterClass, r' ')
        expr.charset = unicodeProperty(name.toString(), negated, caseInsensitive)
        return expr
    }
    func escaped(): Expr {
        if (pos == chars.size) {
            fail("trailing escape")
        }
        let c = chars[pos]
        pos++
        match (c) {
            case r'd' | r'D' | r's' | r'S' | r'w' | r'W' => return perlClass(c)
            case r'0' | r'1' | r'2' | r'3' | r'4' | r'5' | r'6' | r'7' | r'8' | r'9' => return numberEscape(c)
            case r'x' | r'u' | r'U' => return leaf(ExprKind.Literal, hexScalar(c))
            case r'a' => return leaf(ExprKind.Literal, Rune(UInt32(7)))
            case r'f' => return leaf(ExprKind.Literal, Rune(UInt32(12)))
            case r'v' => return leaf(ExprKind.Literal, Rune(UInt32(11)))
            case r'n' => return leaf(ExprKind.Literal, r'\n')
            case r'r' => return leaf(ExprKind.Literal, r'\r')
            case r't' => return leaf(ExprKind.Literal, r'\t')
            case r'p' | r'P' => return propertyClass(c == r'P')
            case r'b' => return wordBoundary(true)
            case r'B' => return wordBoundary(false)
            case r'<' => return stamp(leaf(ExprKind.WordBoundary, c), 7)
            case r'>' => return stamp(leaf(ExprKind.WordBoundary, c), 8)
            case r'A' => return stamp(leaf(ExprKind.Begin, c), 0)
            case r'z' => return stamp(leaf(ExprKind.End, c), 1)
            case _ =>
                let n = UInt32(c)
                let alpha = (c >= r'a' && c <= r'z') || (c >= r'A' && c <= r'Z')
                let digit = c >= r'0' && c <= r'9'
                if (n >= 32 && n <= 126 && !alpha && !digit) {
                    return leaf(ExprKind.Literal, c)
                }
                fail("unsupported escape")
        }
    }
    func perlClass(c: Rune): Expr {
        let lower = if (c == r'D') {
            r'd'
        } else if (c == r'S') {
            r's'
        } else if (c == r'W') {
            r'w'
        } else {
            c
        }
        let set = if (unicode) {
            unicodeClass(lower)
        } else {
            let name = if (lower == r'd') {
                "digit"
            } else if (lower == r's') {
                "space"
            } else {
                "word"
            }
            match (asciiClass(name)) {
                case Some(value) => value
                case None => fail("missing ASCII class")
            }
        }
        let expr = leaf(ExprKind.CharacterClass, c)
        expr.charset = finishAsciiClass(if (lower == c) {
            set
        } else {
            set.negated()
        })
        return expr
    }
    func numberEscape(c: Rune): Expr {
        if (!octal || c > r'7') {
            fail("unsupported backreference")
        }
        var value = Int64(UInt32(c) - UInt32(r'0'))
        var digits: Int64 = 1
        while (digits < 3 && pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'7') {
            value = value * 8 + Int64(UInt32(chars[pos]) - UInt32(r'0'))
            pos++
            digits++
        }
        return finishLiteral(Rune(UInt32(value)))
    }
    func wordNameChar(c: Rune): Bool {
        (c >= r'A' && c <= r'Z') || (c >= r'a' && c <= r'z') || c == r'-'
    }
    func wordBoundary(positive: Bool): Expr {
        let expr = stamp(leaf(ExprKind.WordBoundary, if (positive) {
            r'b'
        } else {
            r'B'
        }), 6)
        expr.modePositive = positive
        if (!positive || !at(r'{')) {
            return expr
        }
        let saved = pos
        pos++
        skipSpace()
        if (pos >= chars.size || !wordNameChar(chars[pos])) {
            pos = saved
            return expr
        }
        let name = StringBuilder()
        while (pos < chars.size && wordNameChar(chars[pos])) {
            name.append(chars[pos])
            pos++
            skipSpace()
        }
        if (!at(r'}')) {
            fail("unclosed word boundary")
        }
        pos++
        match (name.toString()) {
            case "start" => expr.modeKind = 7
            case "end" => expr.modeKind = 8
            case "start-half" => expr.modeKind = 9
            case "end-half" => expr.modeKind = 10
            case _ => fail("unrecognized word boundary")
        }
        return expr
    }
}

func classEscape(c: Rune): Bool {
    c == r'p' || c == r'P' || c == r'd' || c == r'D' || c == r's' || c == r'S' || c == r'w' || c == r'W'
}
