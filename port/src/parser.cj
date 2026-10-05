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
    var nestNode = false
    var classNest: Int64 = 0
    var spanStart: Int64 = 0
    var spanEnd: Int64 = 0
    var spanMarked: Bool = false
    var byteAtom = false
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

// Shared by Regex and RegexSet. Defaults match Regex::new: Unicode on,
// octal off, LF line terminator, nest limit 250, NFA budget 10 MiB.
class PatternOptions {
    var lite: Bool = false
    var caseInsensitive = false
    var multiLine = false
    var dotAll = false
    var swapGreed = false
    var ignoreWhitespace = false
    var crlf = false
    var unicode = true
    var octal = false
    var lineTerminator: Rune = r'\n'
    var nestLimit: Int64 = 250
    var sizeLimit: Int64 = 10485760
    var dfaSizeLimit: Int64 = 2097152
    var utf8 = true
}

class Parser {
    let lite: Bool
    let source: String
    let chars = ArrayList<Rune>()
    let captureNames = ArrayList<String>()
    let captureStarts = ArrayList<Int64>()
    let captureEnds = ArrayList<Int64>()
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
    var nestLimit: Int64 = 250
    var utf8 = true
    // Syntax-only validation is used before building the concrete AST.
    // It preserves grammar checks while deferring Unicode/UTF-8 semantics.
    var syntaxOnly = false
    var literalByte = false
    var lastClassNest: Int64 = 0
    var openClassLevel: Int64 = 0
    var openClassPeak: Int64 = 0
    var openClassItems: Int64 = 0
    var classDepth: Int64 = 0
    var sealedClass: Expr = Expr(ExprKind.Empty, r' ', [], true)
    var pieceNodes = ArrayList<Expr>()
    var pieceFrom: Int64 = -1
    var pieceTo: Int64 = -1
    var pieceCount: Int64 = 0
    var escapeStart: Int64 = 0
    var repeatOrigin: Int64 = 0
    var nameReady = false
    var alphabetic = CharSet()
    var nameNumbers = CharSet()
    init(pattern: String) {
        this(pattern, PatternOptions())
    }
    init(pattern: String, options: PatternOptions) {
        source = pattern
        lite = options.lite
        captureNames.add("") // group 0 denotes the entire match
        captureStarts.add(0)
        captureEnds.add(0)
        if (UInt32(options.lineTerminator) > 255) {
            throw Exception("line terminator must be a byte")
        }
        if (options.nestLimit < 0) {
            throw Exception("nest limit must be nonnegative")
        }
        if (options.sizeLimit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        if (options.dfaSizeLimit < 0) {
            throw Exception("dfa size limit must be nonnegative")
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
        utf8 = options.utf8
        for (c in pattern.runes()) {
            chars.add(c)
        }
    }
    func fail(message: String): Nothing {
        let start = if (pos < chars.size) {
            pos
        } else if (pos > 0) {
            pos - 1
        } else {
            0
        }
        let end = if (start < chars.size) {
            start + 1
        } else {
            start
        }
        failAt(start, end, message)
    }
    func failAt(start: Int64, end: Int64, message: String): Nothing {
        throw syntaxError(source, start, end, -1, -1, message)
    }
    func failAux(start: Int64, end: Int64, auxStart: Int64, auxEnd: Int64, message: String): Nothing {
        throw syntaxError(source, start, end, auxStart, auxEnd, message)
    }
    func located(expr: Expr, start: Int64, end: Int64): Expr {
        expr.spanStart = start
        expr.spanEnd = end
        expr.spanMarked = true
        expr
    }
    func resetPieces(): Unit {
        pieceNodes = ArrayList<Expr>()
        pieceFrom = -1
        pieceTo = -1
        pieceCount = 0
    }
    func isClassNode(node: Expr): Bool {
        match (node.kind) {
            case ExprKind.CharacterClass => true
            case _ => false
        }
    }
    func notePiece(start: Int64, end: Int64, node: Expr): Unit {
        if (pieceFrom < 0 || start < pieceFrom) {
            pieceFrom = start
        }
        if (end > pieceTo) {
            pieceTo = end
        }
        pieceCount++
        if (node.nestNode || isClassNode(node)) {
            pieceNodes.add(node)
        }
    }
    func pieceSet(): Expr {
        if (pieceCount >= 2) {
            let node = Expr(ExprKind.Concat, r' ', pieceNodes.toArray(), true)
            node.nestNode = true
            return located(node, pieceFrom, pieceTo)
        }
        if (pieceNodes.size == 1) {
            return pieceNodes[0]
        }
        leaf(ExprKind.Empty, r' ')
    }
    func lookaroundPrefix(): Bool {
        if (pos + 1 < chars.size && chars[pos] == r'?' && (chars[pos + 1] == r'=' || chars[pos + 1] == r'!')) {
            pos += 2
            return true
        }
        if (pos + 2 < chars.size && chars[pos] == r'?' && chars[pos + 1] == r'<' && (chars[pos + 2] == r'=' ||
            chars[pos + 2] == r'!')) {
            pos += 3
            return true
        }
        false
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
            failAt(pos, pos + 1, "unopened group")
        }
        checkNest(result, 0)
        return result
    }
    func checkNest(expr: Expr, depth: Int64): Unit {
        var next = depth
        match (expr.kind) {
            case ExprKind.Concat | ExprKind.Alternate =>
                if (expr.children.size >= 2 || expr.nestNode) {
                    next = depth + 1
                }
            case ExprKind.Repeat | ExprKind.Capture => next = depth + 1
            case ExprKind.CharacterClass =>
                let bracket = depth + 1
                if (bracket > nestLimit) {
                    failAt(expr.spanStart, expr.spanEnd,
                        "exceed the maximum number of nested parentheses/brackets (${nestLimit})")
                }
                for (child in expr.children) {
                    checkNest(child, bracket)
                }
                return
            case _ => ()
        }
        if (next > nestLimit) {
            failAt(expr.spanStart, expr.spanEnd,
                "exceed the maximum number of nested parentheses/brackets (${nestLimit})")
        }
        for (child in expr.children) {
            checkNest(child, next)
        }
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
        let expr = Expr(ExprKind.Alternate, r' ', parts.toArray(), true)
        if (parts.size > 0) {
            expr.spanStart = parts[0].spanStart
            expr.spanEnd = parts[parts.size - 1].spanEnd
            expr.spanMarked = true
        }
        return expr
    }
    func concat(): Expr {
        let parts = ArrayList<Expr>()
        while (true) {
            skipSpace()
            if ((if (pos >= chars.size) {
                true
            } else {
                (if (at(r'|')) {
                    true
                } else {
                    at(r')')
                })
            })) {
                break
            }
            parts.add(repetition())
        }
        let expr = Expr(ExprKind.Concat, r' ', parts.toArray(), true)
        if (parts.size > 0) {
            expr.spanStart = parts[0].spanStart
            expr.spanEnd = parts[parts.size - 1].spanEnd
            expr.spanMarked = true
        }
        return expr
    }
    func repetition(): Expr {
        var expr = atom()
        while (true) {
            skipSpace()
            if (!((pos < chars.size && (chars[pos] == r'*' || chars[pos] == r'+' || chars[pos] == r'?' || chars[pos] ==
                r'{')))) {
                break
            }
            if (expr.flagOnly) {
                failAt(pos, pos, "repetition operator missing expression")
            }
            let quantifierAt = pos
            repeatOrigin = pos
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
                        failAt(quantifierAt, pos, "unclosed counted repetition")
                    }
                    pos++
                    if (maximum >= 0 && minimum > maximum) {
                        failAt(quantifierAt, pos, "invalid repetition count range, the start must be <= the end")
                    }
                case _ => ()
            }
            var greedy = !swapGreed
            skipSpace()
            if (at(r'?')) {
                greedy = !greedy
                pos++
            }
            let repeated = Expr(ExprKind.Repeat, quantifier, [expr], greedy)
            repeated.minimum = minimum
            repeated.maximum = maximum
            repeated.spanStart = expr.spanStart
            repeated.spanEnd = pos
            repeated.spanMarked = true
            expr = repeated
        }
        return expr
    }
    // Count braces trim Unicode whitespace even when x is off. Comments and
    // whitespace between digits are skipped only while x is on.
    func skipCountSpace(): Unit {
        while ((if (pos < chars.size) {
                whitespace.contains(chars[pos])
            } else {
                false
            })) {
            pos++
        }
    }
    func decimal(): Int64 {
        skipCountSpace()
        if (pos == chars.size) {
            failAt(repeatOrigin, pos, "unclosed counted repetition")
        }
        if (chars[pos] < r'0' || chars[pos] > r'9') {
            failAt(pos, pos, "repetition quantifier expects a valid decimal")
        }
        let digits = pos
        var value: Int64 = 0
        while (pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'9') {
            let digit = Int64(UInt32(chars[pos]) - UInt32(r'0'))
            if (value > 429496729 || (value == 429496729 && digit > 5)) {
                while (pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'9') {
                    pos++
                }
                failAt(digits, pos, "decimal literal invalid")
            }
            value = value * 10 + digit
            pos++
            if (ignoreWhitespace) {
                skipSpace()
            }
        }
        skipCountSpace()
        return value
    }
    func atom(): Expr {
        let c = chars[pos]
        pos++
        match (c) {
            case r'(' =>
                let open = pos - 1
                let oldMultiline = multiline
                let oldDotAll = dotAll
                let oldSwapGreed = swapGreed
                let oldCaseInsensitive = caseInsensitive
                let oldIgnoreWhitespace = ignoreWhitespace
                let oldCrlf = crlf
                let oldUnicode = unicode
                depth++
                var capturing = true
                var name = ""
                var nameStart: Int64 = 0
                var nameEnd: Int64 = 0
                if (at(r'?')) {
                    if (lookaroundPrefix()) {
                        failAt(open, pos, "look-around, including look-ahead and look-behind, is not supported")
                    }
                    let question = pos
                    pos++
                    if (at(r':')) {
                        capturing = false
                        pos++
                    } else if ((if (at(r'<')) {
                        true
                    } else {
                        at(r'P')
                    })) {
                        if (at(r'P')) {
                            pos++
                        }
                        if (!at(r'<')) {
                            failAt(pos, pos + 1, "unrecognized flag")
                        }
                        pos++
                        nameStart = pos
                        name = captureName()
                        nameEnd = pos - 1
                    } else {
                        if (at(r')')) {
                            failAt(question, question, "repetition operator missing expression")
                        }
                        if (pos == chars.size) {
                            failAt(open, open + 1, "unclosed group")
                        }
                        parseFlags()
                        capturing = false
                        if (at(r')')) {
                            pos++;
                            depth--
                            let directive = leaf(ExprKind.Empty, r' ')
                            directive.flagOnly = true
                            return located(directive, open, pos)
                        }
                        pos++ // ':' begins a scoped noncapturing group
                    }
                }
                var index: Int64 = -1
                if (capturing) {
                    if (name != "") {
                        var existingIndex: Int64 = 0
                        for (existing in captureNames) {
                            if (existing == name) {
                                failAux(nameStart, nameEnd, captureStarts[existingIndex], captureEnds[existingIndex],
                                    "duplicate capture group name")
                            }
                            existingIndex++
                        }
                    }
                    index = captureNames.size
                    captureNames.add(name)
                    captureStarts.add(nameStart)
                    captureEnds.add(nameEnd)
                }
                let expr = alternate()
                if (!at(r')')) {
                    failAt(open, open + 1, "unclosed group")
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
                    let wrap = Expr(ExprKind.Concat, r' ', [expr], true)
                    wrap.nestNode = true
                    return located(wrap, open, pos)
                }
                let group = Expr(ExprKind.Capture, r' ', [expr], true)
                group.captureIndex = index
                return located(group, open, pos)
            case r'.' => return located(dot(), pos - 1, pos)
            case r'^' | r'$' => return located(anchor(c == r'^'), pos - 1, pos)
            case r'\\' =>
                let slash = pos - 1
                let expr = escaped()
                match (expr.kind) {
                    case ExprKind.Literal =>
                        if (expr.byteAtom) {
                            return located(expr, slash, pos)
                        }
                        return located(finishLiteral(expr.ch), slash, pos)
                    case _ => return located(expr, slash, pos)
                }
            case r'[' =>
                let open = pos - 1
                let charset = characterClass()
                let expr = Expr(ExprKind.CharacterClass, c, sealedClass.children, true)
                expr.modeUnicode = unicode // Preserve class kind for the public HIR adapter.
                expr.charset = charset
                expr.classNest = lastClassNest
                expr.byteAtom = !unicode && !utf8
                return located(expr, open, pos)
            case r'{' => failAt(pos - 1, pos - 1, "repetition operator missing expression")
            case r'*' | r'+' | r'?' => failAt(pos - 1, pos - 1, "repetition operator missing expression")
            case _ => return located(finishLiteral(c), pos - 1, pos)
        }
    }
    func dot(): Expr {
        if (utf8 && (!unicode || UInt32(lineTerminator) > 127)) {
            failAt(pos - 1, pos, "pattern can match invalid UTF-8")
        }
        if (!utf8 && unicode && !dotAll && !crlf && UInt32(lineTerminator) > 127) {
            failAt(pos - 1, pos, "invalid line terminator, must be ASCII")
        }
        var kind: Int64 = 0
        if (dotAll) {
            kind = 1
        } else if (crlf) {
            kind = 2
        }
        let expr = stamp(leaf(ExprKind.Any, r'.'), kind)
        expr.byteAtom = !unicode
        return expr
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
        var negationAt: Int64 = -1
        let seen = ArrayList<Rune>()
        let seenAt = ArrayList<Int64>()
        while ((if (!at(r':')) {
                !at(r')')
            } else {
                false
            })) {
            if (pos == chars.size) {
                failAt(pos, pos, "expected flag but got end of regex")
            }
            let here = pos
            let c = chars[pos]
            pos++
            if (c == r'-') {
                if (negation) {
                    failAux(here, here + 1, negationAt, negationAt + 1, "flag negation operator repeated")
                }
                negation = true
                enabled = false
                negationAt = here
                continue
            }
            var previous: Int64 = 0
            while (previous < seen.size) {
                if (seen[previous] == c) {
                    failAux(here, here + 1, seenAt[previous], seenAt[previous] + 1, "duplicate flag")
                }
                previous++
            }
            seen.add(c)
            seenAt.add(here)
            negation = false
            negationAt = -1
            match (c) {
                case r'i' => caseInsensitive = enabled
                case r'm' => multiline = enabled
                case r's' => dotAll = enabled
                case r'U' => swapGreed = enabled
                case r'x' => ignoreWhitespace = enabled
                case r'R' => crlf = enabled
                case r'u' =>
                    if (!lite) {
                        unicode = enabled
                    }
                case _ => failAt(here, here + 1, "unrecognized flag")
            }
        }
        if (negationAt >= 0) {
            failAt(negationAt, negationAt + 1, "dangling flag negation operator")
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
            return (if (c == r'_') {
                true
            } else {
                alphabetic.contains(c)
            })
        }
        return (if (c == r'_') {
            true
        } else {
            (if (c == r'.') {
                true
            } else {
                (if (c == r'[') {
                    true
                } else {
                    (if (c == r']') {
                        true
                    } else {
                        (if (alphabetic.contains(c)) {
                            true
                        } else {
                            nameNumbers.contains(c)
                        })
                    })
                })
            })
        })
    }
    func captureName(): String {
        let name = StringBuilder()
        var first = true
        while ((if (pos < chars.size) {
                !at(r'>')
            } else {
                false
            })) {
            let c = chars[pos]
            if (!captureChar(c, first)) {
                failAt(pos, pos + 1, "invalid capture group character")
            }
            name.append(c)
            pos++
            first = false
        }
        if (first) {
            failAt(pos, pos, "empty capture group name")
        }
        if (!at(r'>')) {
            failAt(pos, pos, "unclosed capture group name")
        }
        pos++
        return name.toString()
    }
    func classOperator(): Bool {
        if (pos + 1 >= chars.size || chars[pos] != chars[pos + 1]) {
            return false
        }
        return (if (at(r'&')) {
            true
        } else {
            (if (at(r'-')) {
                true
            } else {
                at(r'~')
            })
        })
    }
    // Opening '[' has already been consumed. Class operators are left associative;
    // union (juxtaposition) binds more tightly, as in regex-syntax's class stack.
    func noteClassItem(): Unit {
        openClassItems++
        if (openClassItems == 2) {
            openClassLevel++
            if (openClassLevel > openClassPeak) {
                openClassPeak = openClassLevel
            }
        }
    }
    func noteClassOp(): Unit {
        openClassLevel++
        openClassItems = 0
        if (openClassLevel > openClassPeak) {
            openClassPeak = openClassLevel
        }
    }
    func characterClass(): CharSet {
        let start = if (pos > 0) {
            pos - 1
        } else {
            0
        }
        classDepth++
        let savedLevel = openClassLevel
        let savedPeak = openClassPeak
        let savedItems = openClassItems
        let savedNodes = pieceNodes
        let savedFrom = pieceFrom
        let savedTo = pieceTo
        let savedCount = pieceCount
        openClassLevel = 1
        openClassPeak = 1
        openClassItems = 0
        resetPieces()
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
            let hyphen = pos
            first.addRange(45, 45)
            noteClassItem()
            notePiece(hyphen, hyphen + 1, leaf(ExprKind.Empty, r' '))
            hasLeadingHyphen = true
            pos++
            skipSpace()
        }
        if ((if (!hasLeadingHyphen) {
            at(r']')
        } else {
            false
        })) {
            let bracket = pos
            first.addRange(93, 93)
            noteClassItem()
            notePiece(bracket, bracket + 1, leaf(ExprKind.Empty, r' '))
            pos++
            skipSpace()
        }
        first.unionWith(classUnion())
        var setNode = pieceSet()
        var setFrom = pieceFrom
        while (classOperator()) {
            let op = chars[pos]
            pos += 2
            noteClassOp()
            let leftNode = setNode
            let leftFrom = setFrom
            resetPieces()
            let rhs = classUnion()
            let rightNode = pieceSet()
            let kids = ArrayList<Expr>()
            if (leftNode.nestNode || isClassNode(leftNode)) {
                kids.add(leftNode)
            }
            if (rightNode.nestNode || isClassNode(rightNode)) {
                kids.add(rightNode)
            }
            let combined = Expr(ExprKind.Concat, r' ', kids.toArray(), true)
            combined.nestNode = true
            let opStart = if (leftFrom >= 0) {
                leftFrom
            } else {
                pieceFrom
            }
            setNode = located(combined, opStart, pieceTo)
            setFrom = setNode.spanStart
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
            classDepth--
            if (pos == start + 2 && chars[start + 1] == r']') {
                failAt(start, pos, "unclosed character class")
            }
            failAt(start, start + 1, "unclosed character class")
        }
        pos++
        classDepth--
        let nestKids = if (setNode.nestNode || isClassNode(setNode)) {
            [setNode]
        } else {
            Array<Expr>()
        }
        sealedClass = located(Expr(ExprKind.CharacterClass, r'[', nestKids, true), start, pos)
        pieceNodes = savedNodes
        pieceFrom = savedFrom
        pieceTo = savedTo
        pieceCount = savedCount
        let mine = openClassPeak
        openClassLevel = savedLevel
        openClassPeak = savedPeak
        openClassItems = savedItems
        lastClassNest = mine
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
        if (unicode && !lite) {
            set.caseFoldSimple()
        } else {
            set.caseFoldAscii()
        }
    }
    func finishAsciiClass(set: CharSet): CharSet {
        if (!unicode && set.exceedsAscii()) {
            if (utf8) {
                failAt(pos - 1, pos, "pattern can match invalid UTF-8")
            }
            let bytes = CharSet()
            bytes.addRange(0, 255)
            return set.intersect(bytes)
        }
        return set
    }
    func rejectClassScalar(c: Rune): Unit {
        if (!syntaxOnly && !unicode && UInt32(c) > 127) {
            failAt(pos - 1, pos, "Unicode not allowed here")
        }
    }
    func finishLiteral(c: Rune): Expr {
        if (!caseInsensitive || (!unicode && UInt32(c) > 127)) {
            return leaf(ExprKind.Literal, c)
        }
        let code = Int64(UInt32(c))
        let set = CharSet()
        set.addRange(code, code)
        if (unicode && !lite) {
            set.caseFoldSimple()
        } else {
            set.caseFoldAscii()
        }
        if (set.isOnly(code)) {
            return leaf(ExprKind.Literal, c)
        }
        let expr = leaf(ExprKind.CharacterClass, c)
        expr.modeUnicode = unicode // Preserve class kind for the public HIR adapter.
        expr.charset = set
        return expr
    }
    func classUnion(): CharSet {
        let result = CharSet()
        while (true) {
            skipSpace()
            if ((if (pos >= chars.size) {
                true
            } else {
                (if (at(r']')) {
                    true
                } else {
                    classOperator()
                })
            })) {
                break
            }
            if (at(r'[')) {
                let bracket = pos
                pos++
                match (namedClass()) {
                    case Some(named) =>
                        noteClassItem()
                        notePiece(bracket, pos, leaf(ExprKind.Empty, r' '))
                        result.unionWith(named)
                    case None =>
                        let nested = characterClass()
                        let nestedNode = sealedClass
                        let combined = openClassLevel + lastClassNest
                        if (combined > openClassPeak) {
                            openClassPeak = combined
                        }
                        noteClassItem()
                        notePiece(nestedNode.spanStart, nestedNode.spanEnd, nestedNode)
                        result.unionWith(nested)
                }
                continue
            }
            if ((if (at(r'\\')) {
                (if (pos + 1 < chars.size) {
                    classEscape(chars[pos + 1])
                } else {
                    false
                })
            } else {
                false
            })) {
                let slash = pos
                pos++
                noteClassItem()
                result.unionWith(escaped().charset)
                notePiece(slash, pos, leaf(ExprKind.Empty, r' '))
                skipSpace()
                if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
                    failAt(pos - 1, pos, "invalid range boundary, must be a literal")
                }
                continue
            }
            let rangeStart = pos
            let low = classLiteral()
            var lowByte = literalByte
            var high = low
            var highByte = lowByte
            skipSpace()
            if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
                pos++
                skipSpace()
                high = classLiteral()
                highByte = literalByte
                if (low > high) {
                    failAt(rangeStart, pos, "invalid character class range, the start must be <= the end")
                }
            }
            if (!lowByte) {
                rejectClassScalar(low)
            }
            if (!highByte) {
                rejectClassScalar(high)
            }
            noteClassItem()
            notePiece(rangeStart, pos, leaf(ExprKind.Empty, r' '))
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
            failAt(pos, pos, "unclosed character class")
        }
        literalByte = false
        let c = chars[pos]
        pos++
        if (c == r'[' || c == r']') {
            failAt(pos - 1, pos, "invalid range boundary, must be a literal")
        }
        if (c != r'\\') {
            return c
        }
        let slash = pos - 1
        let expr = escaped()
        match (expr.kind) {
            case ExprKind.Literal =>
                literalByte = expr.byteAtom
                return expr.ch
            case _ => failAt(slash, pos, "invalid escape sequence found in character class")
        }
    }
    // Fixed-width and braced Unicode scalar escapes share the class/literal path.
    func hexDigitValue(c: Rune): Int64 {
        if (c >= r'0' && c <= r'9') {
            return Int64(UInt32(c) - UInt32(r'0'))
        }
        if (c >= r'a' && c <= r'f') {
            return Int64(UInt32(c) - UInt32(r'a')) + 10
        }
        if (c >= r'A' && c <= r'F') {
            return Int64(UInt32(c) - UInt32(r'A')) + 10
        }
        -1
    }
    func hexScalar(kind: Rune): Rune {
        if (pos == chars.size) {
            failAt(pos, pos, "incomplete escape sequence, reached end of pattern prematurely")
        }
        if (at(r'{')) {
            let brace = pos
            pos++
            let digits = pos
            var count: Int64 = 0
            var value: Int64 = 0
            var invalid = false
            while (!at(r'}')) {
                if (pos == chars.size) {
                    failAt(brace, pos, "incomplete escape sequence, reached end of pattern prematurely")
                }
                let digit = hexDigitValue(chars[pos])
                if (digit < 0) {
                    failAt(pos, pos + 1, "invalid hexadecimal digit")
                }
                if (value > 0x10FFFF / 16) {
                    invalid = true
                }
                value = value * 16 + digit
                pos++
                count++
            }
            let digitEnd = pos
            pos++
            if (count == 0) {
                failAt(brace, pos, "hexadecimal literal empty")
            }
            if (invalid || value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
                failAt(digits, digitEnd, "hexadecimal literal is not a Unicode scalar value")
            }
            return Rune(UInt32(value))
        }
        let width: Int64 = if (kind == r'x') {
            2
        } else if (kind == r'u') {
            4
        } else {
            8
        }
        let digits = pos
        var count: Int64 = 0
        var value: Int64 = 0
        while (count < width) {
            if (pos == chars.size) {
                failAt(pos, pos, "incomplete escape sequence, reached end of pattern prematurely")
            }
            let digit = hexDigitValue(chars[pos])
            if (digit < 0) {
                failAt(pos, pos + 1, "invalid hexadecimal digit")
            }
            value = value * 16 + digit
            pos++
            count++
        }
        if (value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
            failAt(digits, pos, "hexadecimal literal is not a Unicode scalar value")
        }
        return Rune(UInt32(value))
    }
    func propertyClass(negated: Bool): Expr {
        let name = StringBuilder()
        if (at(r'{')) {
            pos++
            while ((if (pos < chars.size) {
                    !at(r'}')
                } else {
                    false
                })) {
                name.append(chars[pos]);
                pos++
            }
            if (!at(r'}')) {
                failAt(pos, pos, "incomplete escape sequence, reached end of pattern prematurely")
            }
            pos++
        } else {
            if (pos == chars.size) {
                failAt(pos, pos, "incomplete escape sequence, reached end of pattern prematurely")
            }
            name.append(chars[pos]);
            pos++
        }
        if (syntaxOnly) {
            return leaf(ExprKind.CharacterClass, r' ')
        }
        if (!unicode) {
            failAt(escapeStart, pos, "Unicode not allowed here")
        }
        let expr = leaf(ExprKind.CharacterClass, r' ')
        expr.modeUnicode = unicode // Preserve class kind for the public HIR adapter.
        try {
            expr.charset = unicodeProperty(name.toString(), negated, caseInsensitive)
        } catch (e: Exception) {
            let text = e.toString()
            if (text.contains("value not found")) {
                failAt(escapeStart, pos, "Unicode property value not found")
            }
            failAt(escapeStart, pos, "Unicode property not found")
        }
        return expr
    }
    func escaped(): Expr {
        if (pos == chars.size) {
            failAt(pos, pos, "incomplete escape sequence, reached end of pattern prematurely")
        }
        escapeStart = pos - 1
        let c = chars[pos]
        pos++
        match (c) {
            case r'd' | r'D' | r's' | r'S' | r'w' | r'W' => return perlClass(c)
            case r'0' | r'1' | r'2' | r'3' | r'4' | r'5' | r'6' | r'7' | r'8' | r'9' => return numberEscape(c)
            case r'x' | r'u' | r'U' =>
                let fixedByte = (if (c == r'x') {
                    !at(r'{')
                } else {
                    false
                })
                let scalar = hexScalar(c)
                let expr = leaf(ExprKind.Literal, scalar)
                if (fixedByte && !unicode && UInt32(scalar) > 127) {
                    if (utf8) {
                        failAt(escapeStart, pos, "pattern can match invalid UTF-8")
                    }
                    expr.byteAtom = true
                }
                return expr
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
                failAt(escapeStart, pos, "unrecognized escape sequence")
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
        let set = if (unicode && !lite) {
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
        expr.modeUnicode = unicode // Preserve class kind for the public HIR adapter.
        expr.charset = finishAsciiClass(if (lower == c) {
            set
        } else {
            set.negated()
        })
        expr.byteAtom = !unicode && !utf8
        return expr
    }
    func numberEscape(c: Rune): Expr {
        if (!octal || c > r'7') {
            failAt(pos - 2, pos, "backreferences are not supported")
        }
        var value = Int64(UInt32(c) - UInt32(r'0'))
        var digits: Int64 = 1
        while (digits < 3 && pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'7') {
            value = value * 8 + Int64(UInt32(chars[pos]) - UInt32(r'0'))
            pos++
            digits++
        }
        // Folding belongs to the enclosing literal or completed class. Returning
        // a folded class here makes classLiteral reject a valid octal endpoint.
        return leaf(ExprKind.Literal, Rune(UInt32(value)))
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
        if (lite) {
            expr.modeUnicode = false
        }
        if ((if (!positive) {
            true
        } else {
            !at(r'{')
        })) {
            return expr
        }
        let brace = pos
        pos++
        skipSpace()
        if (pos >= chars.size) {
            failAt(escapeStart, pos,
                "found either the beginning of a special word boundary or a bounded repetition on a \\b with an opening brace, but no closing brace")
        }
        if (!wordNameChar(chars[pos])) {
            pos = brace
            return expr
        }
        let nameStart = pos
        let name = StringBuilder()
        while (pos < chars.size) {
            if (!wordNameChar(chars[pos])) {
                break
            }
            name.append(chars[pos])
            pos++
            skipSpace()
        }
        let nameEnd = pos
        if (!at(r'}')) {
            failAt(brace, pos, "special word boundary assertion is either unclosed or contains an invalid character")
        }
        pos++
        match (name.toString()) {
            case "start" => expr.modeKind = 7
            case "end" => expr.modeKind = 8
            case "start-half" => expr.modeKind = 9
            case "end-half" => expr.modeKind = 10
            case _ => failAt(nameStart, nameEnd,
                "unrecognized special word boundary assertion, valid choices are: start, end, start-half or end-half")
        }
        return expr
    }
}

func classEscape(c: Rune): Bool {
    c == r'p' || c == r'P' || c == r'd' || c == r'D' || c == r's' || c == r'S' || c == r'w' || c == r'W'
}
