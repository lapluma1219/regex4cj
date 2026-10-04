package cjregex

import std.collection.*

// Concrete syntax. A literal, a bracket class and a non-capturing group stay
// distinct here even when their HIR forms match. Spans use byte offsets and
// 1-based scalar columns, matching regex-syntax.
public class AstSpan {
    public let startOffset: Int64
    public let startLine: Int64
    public let startColumn: Int64
    public let endOffset: Int64
    public let endLine: Int64
    public let endColumn: Int64
    public init(startOffset: Int64, startLine: Int64, startColumn: Int64, endOffset: Int64, endLine: Int64,
        endColumn: Int64) {
        this.startOffset = startOffset
        this.startLine = startLine
        this.startColumn = startColumn
        this.endOffset = endOffset
        this.endLine = endLine
        this.endColumn = endColumn
    }
    public func text(): String {
        "${startOffset}.${startLine}.${startColumn}-${endOffset}.${endLine}.${endColumn}"
    }
}

public class AstClassItem {
    public let label: String
    public let span: AstSpan
    // For a range, this is the start literal. Other items repeat span.
    public let startSpan: AstSpan
    public let origin: String
    public let endSpan: AstSpan
    public let endOrigin: String
    public let start: Int64
    public let end: Int64
    public let negated: Bool
    public let children: Array<AstClassItem>
    public let name: String
    public init(label: String, span: AstSpan, startSpan: AstSpan, origin: String, endSpan: AstSpan, endOrigin: String,
        start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String) {
        this.label = label
        this.span = span
        this.startSpan = startSpan
        this.origin = origin
        this.endSpan = endSpan
        this.endOrigin = endOrigin
        this.start = start
        this.end = end
        this.negated = negated
        this.children = children.clone()
        this.name = name
    }
    public init(label: String, start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String) {
        this(label, blankAstSpan(), blankAstSpan(), "", blankAstSpan(), "", start, end, negated, children, name)
    }
    public func text(): String {
        match (label) {
            case "Lit" => "Lit(${span.text()},${origin},${start})"
            case "Range" => "Range(${span.text()},${startSpan.text()},${origin},${start},${endSpan.text()},${endOrigin},${end})"
            case "Union" => "Union(${span.text()},${joinItemText(children)})"
            case "Empty" => "Empty(${span.text()})"
            case "Ascii" => "Ascii(${span.text()},${negated},${name})"
            case "Perl" => "Perl(${span.text()},${negated},${name})"
            case "UniLetter" => "Uni(${span.text()},${negated},OneLetter('${name}'))"
            case "UniBrace" => "Uni(${span.text()},${negated},${astPropertyKind(name)})"
            case "Nest" => "Nest(${span.text()},${negated},${children[0].text()})"
            case "Intersection" => "Op(Intersection,${span.text()},${children[0].text()},${children[1].text()})"
            case "Difference" => "Op(Difference,${span.text()},${children[0].text()},${children[1].text()})"
            case "SymmetricDifference" => "Op(SymmetricDifference,${span.text()},${children[0].text()},${children[1].text()})"
            case _ => label
        }
    }
}

func blankAstSpan(): AstSpan {
    AstSpan(0, 1, 1, 0, 1, 1)
}

func spanCover(start: AstSpan, end: AstSpan): AstSpan {
    AstSpan(start.startOffset, start.startLine, start.startColumn, end.endOffset, end.endLine, end.endColumn)
}

func joinItemText(children: Array<AstClassItem>): String {
    var body = ""
    for (child in children) {
        if (!body.isEmpty()) {
            body += ","
        }
        body += child.text()
    }
    body
}

public class Ast {
    public let label: String
    public let span: AstSpan
    public var code: Int64
    public var greedy: Bool
    public var negated: Bool
    public var captureIndex: Int64
    public var captureName: String
    public var startsWithP: Bool
    public var quantifier: String
    public var minimum: Int64
    public var maximum: Int64
    public var classItem: AstClassItem
    // Inline flag change. Bits are i, m, s, U, x, R, u. A flags node keeps the
    // change for the following siblings; a group applies it only to its body.
    public var flagMask: Int64
    public var flagValue: Int64
    public var baseCaseInsensitive: Bool
    public var baseMultiLine: Bool
    public var baseDotAll: Bool
    public var baseSwapGreed: Bool
    public var baseIgnoreWhitespace: Bool
    public var baseCrlf: Bool
    public var baseUnicode: Bool
    public var source: String
    let children: Array<Ast>
    init(label: String, span: AstSpan, children: Array<Ast>) {
        this.label = label
        this.span = span
        this.children = children.clone()
        code = 0
        greedy = true
        negated = false
        captureIndex = -1
        captureName = ""
        startsWithP = false
        quantifier = ""
        minimum = 0
        maximum = -1
        classItem = AstClassItem("Empty", 0, 0, false, [], "")
        flagMask = 0
        flagValue = 0
        baseCaseInsensitive = false
        baseMultiLine = false
        baseDotAll = false
        baseSwapGreed = false
        baseIgnoreWhitespace = false
        baseCrlf = false
        baseUnicode = true
        source = ""
    }
    public func subs(): Array<Ast> {
        children.clone()
    }
    public func visit(enter: (Ast) -> Unit): Unit {
        enter(this)
        for (child in children) {
            child.visit(enter)
        }
    }
    public func walk(enter: (Ast) -> Unit, leave: (Ast) -> Unit): Unit {
        enter(this)
        for (child in children) {
            child.walk(enter, leave)
        }
        leave(this)
    }
    // enter 返回 false 时不再访问子节点，也不调用 leave。子节点返回 false 时，后续兄弟和本节点的 leave 都不再调用。
    public func walkUntil(enter: (Ast) -> Bool, leave: (Ast) -> Bool): Bool {
        if (!enter(this)) {
            return false
        }
        for (child in children) {
            if (!child.walkUntil(enter, leave)) {
                return false
            }
        }
        leave(this)
        true
    }
    public func shape(): String {
        match (label) {
            case "empty" => "E(${span.text()})"
            case "flags" => "F(${span.text()})"
            case "literal" => "L(${span.text()},${astLiteralKind(this)},${code})"
            case "dot" => "D(${span.text()})"
            case "assert" => "A(${span.text()},${quantifier})"
            case "perl" => "P(${span.text()},${negated},${quantifier})"
            case "unicode" => "U(${span.text()},${negated},${quantifier})"
            case "class" => "B(${span.text()},${negated},${classItem.text()})"
            case "repeat" => "R(${span.text()},${greedy},${quantifier},${children[0].shape()})"
            case "group" => "G(${span.text()},${groupToken()},${children[0].shape()})"
            case "concat" => "C(${span.text()},${joinShapes()})"
            case "alt" => "O(${span.text()},${joinShapes()})"
            case _ => label
        }
    }
    public func toPattern(): String {
        let out = StringBuilder()
        astPrint(this, out)
        out.toString()
    }
    public func toHir(): Hir {
        astLower(this, astBaseFlags(this))
    }
    public static func parse(pattern: String): Ast {
        AstReader(pattern).parse()
    }
    func groupToken(): String {
        if (captureName != "") {
            let flag = if (startsWithP) {
                1
            } else {
                0
            }
            return "N${flag}:${captureIndex}:${captureName}"
        }
        if (captureIndex >= 0) {
            return "I${captureIndex}"
        }
        "X"
    }
    func joinShapes(): String {
        var body = ""
        for (child in children) {
            if (!body.isEmpty()) {
                body += ","
            }
            body += child.shape()
        }
        body
    }
}

class AstMark {
    let offset: Int64
    let line: Int64
    let column: Int64
    init(offset: Int64, line: Int64, column: Int64) {
        this.offset = offset
        this.line = line
        this.column = column
    }
}

class AstReader {
    let chars: Array<Rune>
    let source: String
    var pos: Int64 = 0
    var offset: Int64 = 0
    var line: Int64 = 1
    var column: Int64 = 1
    var nextCapture: Int64 = 1
    var repeatMinimum: Int64 = 0
    var repeatMaximum: Int64 = -1
    var scope: AstFlagState
    var octal = false
    let whitespace: CharSet
    init(pattern: String) {
        let collected = ArrayList<Rune>()
        for (ch in pattern.runes()) {
            collected.add(ch)
        }
        chars = collected.toArray()
        source = pattern
        scope = AstFlagState()
        whitespace = binaryWhite_Space()
    }
    func parse(): Ast {
        if (chars.isEmpty()) {
            return leaf("empty", span(mark()), 0)
        }
        let result = alternate()
        if (pos != chars.size) {
            throw Exception("unopened group")
        }
        result.baseCaseInsensitive = scope.caseInsensitive
        result.baseMultiLine = scope.multiline
        result.baseDotAll = scope.dotAll
        result.baseSwapGreed = scope.swapGreed
        result.baseIgnoreWhitespace = scope.ignoreWhitespace
        result.baseCrlf = scope.crlf
        result.baseUnicode = scope.unicode
        result.source = source
        result
    }
    func alternate(): Ast {
        let start = mark()
        let parts = ArrayList<Ast>()
        parts.add(concat())
        while (eat(r'|')) {
            parts.add(concat())
        }
        if (parts.size == 1) {
            return parts[0]
        }
        node("alt", span(start), parts.toArray())
    }
    func concat(): Ast {
        let start = mark()
        let parts = ArrayList<Ast>()
        while (pos < chars.size && !at(r'|') && !at(r')')) {
            skipLayout()
            if (pos >= chars.size || at(r'|') || at(r')')) {
                break
            }
            parts.add(repetition())
        }
        if (parts.isEmpty()) {
            return leaf("empty", span(start), 0)
        }
        if (parts.size == 1) {
            return parts[0]
        }
        node("concat", span(start), parts.toArray())
    }
    func repetition(): Ast {
        let start = mark()
        let body = atom()
        skipLayout()
        if (!(at(r'*') || at(r'+') || at(r'?') || at(r'{'))) {
            return body
        }
        let op = chars[pos]
        bump()
        var token = ""
        match (op) {
            case r'*' => token = "ZeroOrMore"
            case r'+' => token = "OneOrMore"
            case r'?' => token = "ZeroOrOne"
            case _ => token = counted()
        }
        var greedy = true
        if (eat(r'?')) {
            greedy = false
        }
        let result = node("repeat", span(start), [body])
        result.greedy = greedy
        result.quantifier = token
        match (op) {
            case r'*' =>
                result.minimum = 0
                result.maximum = -1
            case r'+' =>
                result.minimum = 1
                result.maximum = -1
            case r'?' =>
                result.minimum = 0
                result.maximum = 1
            case _ =>
                result.minimum = repeatMinimum
                result.maximum = repeatMaximum
        }
        result
    }
    func counted(): String {
        skipLayout()
        let minimum = number()
        skipLayout()
        var maximum = minimum
        var token = "Range(Exactly(${minimum}))"
        if (eat(r',')) {
            skipLayout()
            if (at(r'}')) {
                maximum = -1
                token = "Range(AtLeast(${minimum}))"
            } else {
                maximum = number()
                skipLayout()
                token = "Range(Bounded(${minimum}, ${maximum}))"
            }
        }
        if (!eat(r'}')) {
            throw Exception("unclosed counted repetition")
        }
        repeatMinimum = minimum
        repeatMaximum = maximum
        token
    }
    func number(): Int64 {
        if (pos >= chars.size || chars[pos] < r'0' || chars[pos] > r'9') {
            throw Exception("repetition quantifier expects a valid decimal")
        }
        var value: Int64 = 0
        while (pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'9') {
            value = value * 10 + Int64(UInt32(chars[pos]) - UInt32(r'0'))
            bump()
        }
        value
    }
    func atom(): Ast {
        let start = mark()
        let ch = chars[pos]
        bump()
        match (ch) {
            case r'(' => group(start)
            case r'[' => bracket(start)
            case r'.' => leaf("dot", span(start), 0)
            case r'^' => assertion(start, "StartLine")
            case r'$' => assertion(start, "EndLine")
            case r'\\' => escaped(start)
            case _ => literal(start, ch)
        }
    }
    func group(start: AstMark): Ast {
        if (eat(r'?')) {
            if (eat(r':')) {
                return finishGroup(start, false, "", false)
            }
            if (at(r'<') || at(r'P')) {
                let withP = eat(r'P')
                if (!eat(r'<')) {
                    throw Exception("unrecognized flag")
                }
                let name = captureName()
                if (!eat(r'>')) {
                    throw Exception("unclosed capture name")
                }
                return finishGroup(start, true, name, withP)
            }
            let read = readFlags()
            if (eat(r')')) {
                scope.apply(read[0], read[1])
                return flagNode(start, read[0], read[1])
            }
            if (!eat(r':')) {
                throw Exception("unrecognized flag")
            }
            let saved = scope.copy()
            scope.apply(read[0], read[1])
            let result = finishGroup(start, false, "", false)
            scope.restore(saved)
            result.flagMask = read[0]
            result.flagValue = read[1]
            return result
        }
        finishGroup(start, true, "", false)
    }
    func finishGroup(start: AstMark, capturing: Bool, name: String, withP: Bool): Ast {
        let body = alternate()
        if (!eat(r')')) {
            throw Exception("unclosed group")
        }
        let result = node("group", span(start), [body])
        if (capturing) {
            result.captureIndex = nextCapture
            nextCapture++
            result.captureName = name
            result.startsWithP = withP
        }
        result
    }
    func captureName(): String {
        let out = StringBuilder()
        while (pos < chars.size && chars[pos] != r'>') {
            out.append(chars[pos])
            bump()
        }
        out.toString()
    }
    func readFlags(): Array<Int64> {
        var enabled = true
        var mask: Int64 = 0
        var value: Int64 = 0
        while (pos < chars.size && !at(r':') && !at(r')')) {
            if (eat(r'-')) {
                enabled = false
                continue
            }
            let bit = astFlagBit(chars[pos])
            bump()
            if (bit == 0) {
                throw Exception("unrecognized flag")
            }
            mask = mask | bit
            if (enabled) {
                value = value | bit
            }
        }
        [mask, value]
    }
    func flagNode(start: AstMark, mask: Int64, value: Int64): Ast {
        let result = leaf("flags", span(start), 0)
        result.flagMask = mask
        result.flagValue = value
        result
    }
    func skipLayout(): Unit {
        if (!scope.ignoreWhitespace) {
            return
        }
        while (pos < chars.size) {
            let ch = chars[pos]
            if (whitespace.contains(ch)) {
                bump()
                continue
            }
            if (ch != r'#') {
                break
            }
            bump()
            while (pos < chars.size) {
                let comment = chars[pos]
                bump()
                if (comment == r'\n') {
                    break
                }
            }
        }
    }
    func bracket(start: AstMark): Ast {
        let negated = eat(r'^')
        let item = classExpression()
        if (!eat(r']')) {
            throw Exception("unclosed character class")
        }
        let result = leaf("class", span(start), 0)
        result.negated = negated
        result.classItem = item
        result
    }
    func classExpression(): AstClassItem {
        var left = classUnion()
        while (classOperator()) {
            let op = chars[pos]
            bump()
            bump()
            let right = classUnion()
            let kind = if (op == r'&') {
                "Intersection"
            } else if (op == r'-') {
                "Difference"
            } else {
                "SymmetricDifference"
            }
            let covered = spanCover(left.span, right.span)
            left = classNode(kind, covered, 0, 0, false, [left, right], "")
        }
        left
    }
    func classUnion(): AstClassItem {
        let items = ArrayList<AstClassItem>()
        while (pos < chars.size) {
            skipLayout()
            if (pos >= chars.size || at(r']') || classOperator()) {
                break
            }
            items.add(classPiece())
        }
        match (items.size) {
            case 0 =>
                let here = mark()
                classNode("Empty", span(here), 0, 0, false, [], "")
            case 1 => items[0]
            case _ =>
                let covered = spanCover(items[0].span, items[items.size - 1].span)
                classNode("Union", covered, 0, 0, false, items.toArray(), "")
        }
    }
    func classPiece(): AstClassItem {
        let start = mark()
        if (at(r'[')) {
            bump()
            match (classAsciiItem(start)) {
                case Some(item) => return item
                case None => ()
            }
            let negated = eat(r'^')
            let inner = classExpression()
            if (!eat(r']')) {
                throw Exception("unclosed character class")
            }
            return classNode("Nest", span(start), 0, 0, negated, [inner], "")
        }
        if (at(r'\\')) {
            bump()
            return classEscapeItem(start)
        }
        let begin = chars[pos]
        bump()
        let beginSpan = span(start)
        skipLayout()
        if (at(r'-') && pos + 1 < chars.size && chars[pos + 1] != r']' && chars[pos + 1] != r'-') {
            bump()
            skipLayout()
            if (pos >= chars.size) {
                throw Exception("unclosed character class")
            }
            let endStart = mark()
            let end = chars[pos]
            bump()
            return classRange(span(start), beginSpan, "Verbatim", Int64(UInt32(begin)), span(endStart), "Verbatim",
                Int64(UInt32(end)))
        }
        classLit(beginSpan, "Verbatim", Int64(UInt32(begin)))
    }
    func classEscapeItem(start: AstMark): AstClassItem {
        if (pos >= chars.size) {
            throw Exception("incomplete escape sequence")
        }
        let ch = chars[pos]
        bump()
        match (ch) {
            case r'd' | r'D' => classNode("Perl", span(start), 0, 0, ch == r'D', [], "Digit")
            case r's' | r'S' => classNode("Perl", span(start), 0, 0, ch == r'S', [], "Space")
            case r'w' | r'W' => classNode("Perl", span(start), 0, 0, ch == r'W', [], "Word")
            case r'p' | r'P' => classUnicodeItem(start, ch == r'P')
            case r'n' => classLit(span(start), "Special(LineFeed)", 10)
            case r'r' => classLit(span(start), "Special(CarriageReturn)", 13)
            case r't' => classLit(span(start), "Special(Tab)", 9)
            case r'a' => classLit(span(start), "Special(Bell)", 7)
            case r'f' => classLit(span(start), "Special(FormFeed)", 12)
            case r'v' => classLit(span(start), "Special(VerticalTab)", 11)
            case r'x' | r'u' | r'U' =>
                let node = hexLiteral(start, ch)
                classLit(node.span, node.quantifier, node.code)
            case _ =>
                let origin = if (astMeta(ch)) {
                    "Meta"
                } else {
                    "Superfluous"
                }
                classLit(span(start), origin, Int64(UInt32(ch)))
        }
    }
    func classUnicodeItem(start: AstMark, negated: Bool): AstClassItem {
        if (eat(r'{')) {
            let text = StringBuilder()
            while (pos < chars.size && !at(r'}')) {
                text.append(chars[pos])
                bump()
            }
            if (!eat(r'}')) {
                throw Exception("unclosed Unicode property")
            }
            return classNode("UniBrace", span(start), 0, 0, negated, [], text.toString())
        }
        if (pos >= chars.size) {
            throw Exception("incomplete escape sequence")
        }
        let letter = chars[pos]
        bump()
        classNode("UniLetter", span(start), 0, 0, negated, [], String([letter]))
    }
    func classAsciiItem(start: AstMark): Option<AstClassItem> {
        if (!at(r':')) {
            return None<AstClassItem>
        }
        var cursor = pos + 1
        var negated = false
        if (cursor < chars.size && chars[cursor] == r'^') {
            negated = true
            cursor++
        }
        let text = StringBuilder()
        while (cursor < chars.size && chars[cursor] != r':') {
            text.append(chars[cursor])
            cursor++
        }
        if (cursor + 1 >= chars.size || chars[cursor + 1] != r']') {
            return None<AstClassItem>
        }
        let kind = astAsciiKind(text.toString())
        if (kind.isEmpty()) {
            return None<AstClassItem>
        }
        let steps = cursor + 2 - pos
        var left = steps
        while (left > 0) {
            bump()
            left--
        }
        Some(classNode("Ascii", span(start), 0, 0, negated, [], kind))
    }
    func classNode(label: String, itemSpan: AstSpan, start: Int64, end: Int64, negated: Bool,
        children: Array<AstClassItem>, name: String): AstClassItem {
        let blank = blankAstSpan()
        AstClassItem(label, itemSpan, itemSpan, "", blank, "", start, end, negated, children, name)
    }
    func classLit(itemSpan: AstSpan, origin: String, code: Int64): AstClassItem {
        let blank = blankAstSpan()
        AstClassItem("Lit", itemSpan, itemSpan, origin, blank, "", code, code, false, [], "")
    }
    func classRange(itemSpan: AstSpan, startSpan: AstSpan, origin: String, start: Int64, endSpan: AstSpan,
        endOrigin: String, end: Int64): AstClassItem {
        AstClassItem("Range", itemSpan, startSpan, origin, endSpan, endOrigin, start, end, false, [], "")
    }
    func classOperator(): Bool {
        if (pos + 1 >= chars.size || chars[pos] != chars[pos + 1]) {
            return false
        }
        at(r'&') || at(r'-') || at(r'~')
    }
    func escaped(start: AstMark): Ast {
        if (pos >= chars.size) {
            throw Exception("incomplete escape sequence")
        }
        let ch = chars[pos]
        bump()
        match (ch) {
            case r'A' => assertion(start, "StartText")
            case r'z' => assertion(start, "EndText")
            case r'b' => wordAssertion(start)
            case r'<' => assertion(start, "WordBoundaryStartAngle")
            case r'>' => assertion(start, "WordBoundaryEndAngle")
            case r'B' => assertion(start, "NotWordBoundary")
            case r'd' | r'D' => perlClass(start, ch == r'D', "Digit")
            case r's' | r'S' => perlClass(start, ch == r'S', "Space")
            case r'w' | r'W' => perlClass(start, ch == r'W', "Word")
            case r'n' => literalKind(start, r'\n', "Special(LineFeed)")
            case r'r' => literalKind(start, r'\r', "Special(CarriageReturn)")
            case r't' => literalKind(start, r'\t', "Special(Tab)")
            case r'a' => literalKind(start, Rune(UInt32(7)), "Special(Bell)")
            case r'f' => literalKind(start, Rune(UInt32(12)), "Special(FormFeed)")
            case r'v' => literalKind(start, Rune(UInt32(11)), "Special(VerticalTab)")
            case r'x' | r'u' | r'U' => hexLiteral(start, ch)
            case r'p' | r'P' => unicodePropertyNode(start, ch == r'P')
            case r'0' | r'1' | r'2' | r'3' | r'4' | r'5' | r'6' | r'7' =>
                if (!octal) {
                    throw Exception("backreferences are not supported")
                }
                var value = Int64(UInt32(ch) - UInt32(r'0'))
                var digits: Int64 = 1
                while (digits < 3 && pos < chars.size && chars[pos] >= r'0' && chars[pos] <= r'7') {
                    value = value * 8 + Int64(UInt32(chars[pos]) - UInt32(r'0'))
                    bump()
                    digits++
                }
                literalKind(start, Rune(UInt32(value)), "Octal")
            case _ =>
                let kind = if (astMeta(ch)) {
                    "Meta"
                } else {
                    "Superfluous"
                }
                literalKind(start, ch, kind)
        }
    }
    func perlClass(start: AstMark, negated: Bool, name: String): Ast {
        let result = leaf("perl", span(start), 0)
        result.negated = negated
        result.quantifier = name
        result
    }
    func unicodePropertyNode(start: AstMark, negated: Bool): Ast {
        if (eat(r'{')) {
            let text = StringBuilder()
            while (pos < chars.size && !at(r'}')) {
                text.append(chars[pos])
                bump()
            }
            if (!eat(r'}')) {
                throw Exception("unclosed Unicode property")
            }
            return unicodeNode(start, negated, text.toString(), astPropertyKind(text.toString()))
        }
        if (pos >= chars.size) {
            throw Exception("incomplete escape sequence")
        }
        let letter = chars[pos]
        bump()
        unicodeNode(start, negated, String([letter]), "OneLetter('${letter}')")
    }
    func unicodeNode(start: AstMark, negated: Bool, name: String, kind: String): Ast {
        let result = leaf("unicode", span(start), 0)
        result.negated = negated
        result.captureName = name
        result.quantifier = kind
        result
    }
    func hexLiteral(start: AstMark, kind: Rune): Ast {
        let kindName = if (kind == r'x') {
            "X"
        } else if (kind == r'u') {
            "UnicodeShort"
        } else {
            "UnicodeLong"
        }
        if (eat(r'{')) {
            var value: Int64 = 0
            while (!at(r'}')) {
                value = value * 16 + astHexDigit(chars[pos])
                bump()
            }
            if (!eat(r'}')) {
                throw Exception("unclosed hexadecimal literal")
            }
            return literalKind(start, Rune(UInt32(value)), "HexBrace(${kindName})")
        }
        let width = if (kind == r'x') {
            2
        } else if (kind == r'u') {
            4
        } else {
            8
        }
        var value: Int64 = 0
        var left = width
        while (left > 0) {
            value = value * 16 + astHexDigit(chars[pos])
            bump()
            left--
        }
        literalKind(start, Rune(UInt32(value)), "HexFixed(${kindName})")
    }
    func wordAssertion(start: AstMark): Ast {
        if (!at(r'{') || pos + 1 >= chars.size || chars[pos + 1] < r'a' || chars[pos + 1] > r'z') {
            return assertion(start, "WordBoundary")
        }
        bump()
        let name = StringBuilder()
        while (pos < chars.size && !at(r'}')) {
            name.append(chars[pos]);
            bump()
        }
        if (!eat(r'}')) {
            throw Exception("unclosed special word boundary")
        }
        let kind = match (name.toString()) {
            case "start" => "WordBoundaryStart"
            case "end" => "WordBoundaryEnd"
            case "start-half" => "WordBoundaryStartHalf"
            case "end-half" => "WordBoundaryEndHalf"
            case _ => throw Exception("unknown special word boundary")
        }
        assertion(start, kind)
    }
    func assertion(start: AstMark, kind: String): Ast {
        let result = leaf("assert", span(start), 0)
        result.quantifier = kind
        result
    }
    func literal(start: AstMark, ch: Rune): Ast {
        leaf("literal", span(start), Int64(UInt32(ch)))
    }
    func literalKind(start: AstMark, ch: Rune, kind: String): Ast {
        let result = literal(start, ch)
        result.quantifier = kind
        result
    }
    func leaf(label: String, span: AstSpan, code: Int64): Ast {
        let result = Ast(label, span, [])
        result.code = code
        result
    }
    func node(label: String, span: AstSpan, children: Array<Ast>): Ast {
        Ast(label, span, children)
    }
    func mark(): AstMark {
        AstMark(offset, line, column)
    }
    func span(start: AstMark): AstSpan {
        AstSpan(start.offset, start.line, start.column, offset, line, column)
    }
    func at(ch: Rune): Bool {
        pos < chars.size && chars[pos] == ch
    }
    func eat(ch: Rune): Bool {
        if (!at(ch)) {
            return false
        }
        bump()
        true
    }
    func bump(): Unit {
        let ch = chars[pos]
        if (ch == r'\n') {
            line++
            column = 1
        } else {
            column++
        }
        let code = UInt32(ch)
        offset += if (code < 0x80) {
            1
        } else if (code < 0x800) {
            2
        } else if (code < 0x10000) {
            3
        } else {
            4
        }
        pos++
    }
}

let AST_FLAG_I: Int64 = 1
let AST_FLAG_M: Int64 = 2
let AST_FLAG_S: Int64 = 4
let AST_FLAG_SWAP: Int64 = 8
let AST_FLAG_X: Int64 = 16
let AST_FLAG_R: Int64 = 32
let AST_FLAG_UNICODE: Int64 = 64

class AstFlagState {
    var caseInsensitive: Bool = false
    var multiline: Bool = false
    var dotAll: Bool = false
    var swapGreed: Bool = false
    var ignoreWhitespace: Bool = false
    var crlf: Bool = false
    var unicode: Bool = true
    var utf8: Bool = true
    var pattern: String = ""
    init() {}
    func apply(mask: Int64, value: Int64): Unit {
        if ((mask & AST_FLAG_I) != 0) {
            caseInsensitive = (value & AST_FLAG_I) != 0
        }
        if ((mask & AST_FLAG_M) != 0) {
            multiline = (value & AST_FLAG_M) != 0
        }
        if ((mask & AST_FLAG_S) != 0) {
            dotAll = (value & AST_FLAG_S) != 0
        }
        if ((mask & AST_FLAG_SWAP) != 0) {
            swapGreed = (value & AST_FLAG_SWAP) != 0
        }
        if ((mask & AST_FLAG_X) != 0) {
            ignoreWhitespace = (value & AST_FLAG_X) != 0
        }
        if ((mask & AST_FLAG_R) != 0) {
            crlf = (value & AST_FLAG_R) != 0
        }
        if ((mask & AST_FLAG_UNICODE) != 0) {
            unicode = (value & AST_FLAG_UNICODE) != 0
        }
    }
    func copy(): AstFlagState {
        let next = AstFlagState()
        next.restore(this)
        next
    }
    func restore(saved: AstFlagState): Unit {
        caseInsensitive = saved.caseInsensitive
        multiline = saved.multiline
        dotAll = saved.dotAll
        swapGreed = saved.swapGreed
        ignoreWhitespace = saved.ignoreWhitespace
        crlf = saved.crlf
        unicode = saved.unicode
        utf8 = saved.utf8
        pattern = saved.pattern
    }
}

func astPrint(ast: Ast, out: StringBuilder): Unit {
    match (ast.label) {
        case "empty" => ()
        case "flags" =>
            out.append("(?")
            out.append(astFlagText(ast))
            out.append(")")
        case "literal" => astPrintLiteral(out, ast)
        case "dot" => out.append(".")
        case "assert" => out.append(astAssert(ast.quantifier))
        case "perl" => astPrintPerl(out, ast)
        case "unicode" => astPrintUnicode(out, ast)
        case "class" => astPrintClass(ast, out)
        case "repeat" =>
            astPrint(ast.children[0], out)
            out.append(astQuantifier(ast))
        case "group" =>
            out.append("(")
            if (ast.captureName != "") {
                out.append(if (ast.startsWithP) {
                    "?P<"
                } else {
                    "?<"
                })
                out.append(ast.captureName)
                out.append(">")
            } else if (ast.captureIndex < 0) {
                let flags = astFlagText(ast)
                if (flags.isEmpty()) {
                    out.append("?:")
                } else {
                    out.append("?${flags}:")
                }
            }
            astPrint(ast.children[0], out)
            out.append(")")
        case "concat" => for (child in ast.children) {
            astPrint(child, out)
        }
        case "alt" =>
            var first = true
            for (child in ast.children) {
                if (!first) {
                    out.append("|")
                }
                first = false
                astPrint(child, out)
            }
        case _ => ()
    }
}

func astPrintClass(ast: Ast, out: StringBuilder): Unit {
    out.append("[")
    if (ast.negated) {
        out.append("^")
    }
    astPrintItem(ast.classItem, out)
    out.append("]")
}

func astPrintItem(item: AstClassItem, out: StringBuilder): Unit {
    match (item.label) {
        case "Lit" => astPrintChar(out, Rune(UInt32(item.start)))
        case "Range" =>
            astPrintChar(out, Rune(UInt32(item.start)))
            out.append("-")
            astPrintChar(out, Rune(UInt32(item.end)))
        case "Union" => for (child in item.children) {
            astPrintItem(child, out)
        }
        case "Ascii" =>
            out.append("[:")
            if (item.negated) {
                out.append("^")
            }
            out.append(astAsciiName(item.name))
            out.append(":]")
        case "Perl" =>
            let letter = match (item.name) {
                case "Digit" =>
                    if (item.negated) {
                        "D"
                    } else {
                        "d"
                    }
                case "Space" =>
                    if (item.negated) {
                        "S"
                    } else {
                        "s"
                    }
                case _ =>
                    if (item.negated) {
                        "W"
                    } else {
                        "w"
                    }
            }
            out.append("\\${letter}")
        case "UniLetter" =>
            out.append(if (item.negated) {
                "\\P"
            } else {
                "\\p"
            })
            out.append(item.name)
        case "UniBrace" =>
            out.append(if (item.negated) {
                "\\P{"
            } else {
                "\\p{"
            })
            out.append(item.name)
            out.append("}")
        case "Nest" =>
            out.append("[")
            if (item.negated) {
                out.append("^")
            }
            astPrintItem(item.children[0], out)
            out.append("]")
        case "Intersection" =>
            astPrintItem(item.children[0], out)
            out.append("&&")
            astPrintItem(item.children[1], out)
        case "Difference" =>
            astPrintItem(item.children[0], out)
            out.append("--")
            astPrintItem(item.children[1], out)
        case "SymmetricDifference" =>
            astPrintItem(item.children[0], out)
            out.append("~~")
            astPrintItem(item.children[1], out)
        case _ => ()
    }
}

func astPrintChar(out: StringBuilder, ch: Rune): Unit {
    if (hirMeta(ch)) {
        out.append("\\")
    }
    out.append(String([ch]))
}

func astAssert(kind: String): String {
    match (kind) {
        case "StartLine" => "^"
        case "EndLine" => "$"
        case "StartText" => "\\A"
        case "EndText" => "\\z"
        case "WordBoundary" => "\\b"
        case "NotWordBoundary" => "\\B"
        case "WordBoundaryStart" => "\\b{start}"
        case "WordBoundaryEnd" => "\\b{end}"
        case "WordBoundaryStartAngle" => "\\<"
        case "WordBoundaryEndAngle" => "\\>"
        case "WordBoundaryStartHalf" => "\\b{start-half}"
        case "WordBoundaryEndHalf" => "\\b{end-half}"
        case _ => ""
    }
}

func astDropSpaces(text: String): String {
    let out = StringBuilder()
    for (c in text.runes()) {
        if (c != r' ') {
            out.append(c)
        }
    }
    out.toString()
}

func astQuantifier(ast: Ast): String {
    let suffix = if (ast.greedy) {
        ""
    } else {
        "?"
    }
    match (ast.quantifier) {
        case "ZeroOrOne" => "?${suffix}"
        case "ZeroOrMore" => "*${suffix}"
        case "OneOrMore" => "+${suffix}"
        case _ =>
            if (ast.quantifier.startsWith("Range(Exactly(")) {
                let digits = ast.quantifier[14..ast.quantifier.size - 2]
                "{${digits}}${suffix}"
            } else if (ast.quantifier.startsWith("Range(AtLeast(")) {
                let digits = ast.quantifier[14..ast.quantifier.size - 2]
                "{${digits},}${suffix}"
            } else {
                let body = astDropSpaces(ast.quantifier[14..ast.quantifier.size - 2])
                "{${body}}${suffix}"
            }
    }
}

func astLower(ast: Ast, flags: AstFlagState): Hir {
    match (ast.label) {
        case "empty" => Hir.empty()
        case "flags" =>
            flags.apply(ast.flagMask, ast.flagValue)
            Hir.empty()
        case "literal" => astLiteral(ast, flags)
        case "dot" => astDot(ast, flags)
        case "assert" => Hir.look(astLook(ast.quantifier, flags))
        case "perl" => astPerl(ast, flags)
        case "unicode" => hirFromCharSet(false, astUnicodeSet(ast.span, ast.captureName, ast.negated, flags))
        case "class" => astClass(ast, flags)
        case "repeat" =>
            let child = astLower(ast.children[0], flags)
            let maximum = if (ast.maximum < 0) {
                None<UInt32>
            } else {
                Some<UInt32>(UInt32(ast.maximum))
            }
            let greedy = if (flags.swapGreed) {
                !ast.greedy
            } else {
                ast.greedy
            }
            Hir.repetition(UInt32(ast.minimum), maximum, greedy, child)
        case "group" =>
            let saved = flags.copy()
            flags.apply(ast.flagMask, ast.flagValue)
            let child = astLower(ast.children[0], flags)
            flags.restore(saved)
            if (ast.captureIndex >= 0) {
                let name = if (ast.captureName.isEmpty()) {
                    None<String>
                } else {
                    Some<String>(ast.captureName)
                }
                Hir.capture(UInt32(ast.captureIndex), name, child)
            } else {
                child
            }
        case "concat" | "alt" =>
            let parts = ArrayList<Hir>()
            for (child in ast.children) {
                parts.add(astLower(child, flags))
            }
            if (ast.label == "alt") {
                Hir.alternation(parts.toArray())
            } else {
                Hir.concat(parts.toArray())
            }
        case _ => Hir.empty()
    }
}

func astLiteral(ast: Ast, flags: AstFlagState): Hir {
    let code = ast.code
    let unicode = flags.unicode
    let byteEscape = ast.quantifier == "HexFixed(X)"
    // A non-ASCII \xNN byte can match invalid UTF-8. Source characters stay UTF-8.
    if (!unicode && byteEscape && code > 127 && flags.utf8) {
        throw translateError(flags.pattern, ast.span, "pattern can match invalid UTF-8")
    }
    if (!unicode && code >= 128 && !byteEscape) {
        return Hir.literal(String([Rune(UInt32(code))]).toArray())
    }
    if (!flags.caseInsensitive) {
        return if (unicode || code < 128) {
            Hir.literal(String([Rune(UInt32(code))]).toArray())
        } else {
            Hir.literal([UInt8(code)])
        }
    }
    let set = CharSet()
    set.addRange(code, code)
    if (unicode) {
        set.caseFoldSimple()
    } else {
        set.caseFoldAscii()
    }
    astRejectUtf8(ast.span, flags, set)
    hirFromCharSet(!unicode, set)
}

func astClass(ast: Ast, flags: AstFlagState): Hir {
    var set = astItemSet(ast.classItem, flags)
    astFold(set, flags)
    if (ast.negated) {
        set = set.negated()
    }
    if (!flags.unicode) {
        set = astFinishAscii(set)
    }
    astRejectUtf8(ast.span, flags, set)
    hirFromCharSet(!flags.unicode, set)
}

func astFold(set: CharSet, flags: AstFlagState): Unit {
    if (!flags.caseInsensitive) {
        return
    }
    if (flags.unicode) {
        set.caseFoldSimple()
    } else {
        set.caseFoldAscii()
    }
}

func astPerl(ast: Ast, flags: AstFlagState): Hir {
    let set = astPerlSet(ast.quantifier, ast.negated, flags)
    astRejectUtf8(ast.span, flags, set)
    hirFromCharSet(!flags.unicode, set)
}

func astBaseFlags(ast: Ast): AstFlagState {
    let flags = AstFlagState()
    flags.caseInsensitive = ast.baseCaseInsensitive
    flags.multiline = ast.baseMultiLine
    flags.dotAll = ast.baseDotAll
    flags.swapGreed = ast.baseSwapGreed
    flags.ignoreWhitespace = ast.baseIgnoreWhitespace
    flags.crlf = ast.baseCrlf
    flags.unicode = ast.baseUnicode
    flags.utf8 = true
    flags.pattern = ast.source
    flags
}

func astRejectUtf8(span: AstSpan, flags: AstFlagState, set: CharSet): Unit {
    if (flags.utf8 && !flags.unicode && set.exceedsAscii()) {
        throw translateError(flags.pattern, span, "pattern can match invalid UTF-8")
    }
}

func astUnicodeSet(span: AstSpan, name: String, negated: Bool, flags: AstFlagState): CharSet {
    if (!flags.unicode) {
        throw translateError(flags.pattern, span, "Unicode not allowed here")
    }
    try {
        unicodeProperty(name, negated, flags.caseInsensitive)
    } catch (e: RegexError) {
        throw e
    } catch (e: Exception) {
        let text = e.toString()
        if (text.contains("value not found")) {
            throw translateError(flags.pattern, span, "Unicode property value not found")
        }
        throw translateError(flags.pattern, span, "Unicode property not found")
    }
}

func astDot(ast: Ast, flags: AstFlagState): Hir {
    if (flags.utf8 && !flags.unicode) {
        throw translateError(flags.pattern, ast.span, "pattern can match invalid UTF-8")
    }
    if (flags.dotAll) {
        return if (flags.unicode) {
            Hir.dot(HirDot.AnyChar)
        } else {
            Hir.dot(HirDot.AnyByte)
        }
    }
    if (flags.crlf) {
        return if (flags.unicode) {
            Hir.dot(HirDot.AnyCharExceptCRLF)
        } else {
            Hir.dot(HirDot.AnyByteExceptCRLF)
        }
    }
    if (flags.unicode) {
        Hir.dot(HirDot.AnyCharExceptLF)
    } else {
        Hir.dot(HirDot.AnyByteExceptLF)
    }
}

func astFinishAscii(set: CharSet): CharSet {
    if (!set.exceedsAscii()) {
        return set
    }
    let bytes = CharSet()
    bytes.addRange(0, 255)
    set.intersect(bytes)
}

func astItemSet(item: AstClassItem, flags: AstFlagState): CharSet {
    match (item.label) {
        case "Lit" | "Range" =>
            let set = CharSet()
            set.addRange(item.start, item.end)
            set
        case "Union" =>
            let set = CharSet()
            for (child in item.children) {
                set.unionWith(astItemSet(child, flags))
            }
            set
        case "Ascii" => astAsciiSet(item.name, item.negated, flags)
        case "Perl" => astPerlSet(item.name, item.negated, flags)
        case "UniLetter" | "UniBrace" => astUnicodeSet(item.span, item.name, item.negated, flags)
        case "Nest" =>
            var inner = astItemSet(item.children[0], flags)
            astFold(inner, flags)
            if (!flags.unicode) {
                inner = astFinishAscii(inner)
            }
            if (item.negated) {
                inner.negated()
            } else {
                inner
            }
        case "Intersection" | "Difference" | "SymmetricDifference" =>
            let left = astItemSet(item.children[0], flags)
            let right = astItemSet(item.children[1], flags)
            astFold(left, flags)
            astFold(right, flags)
            match (item.label) {
                case "Intersection" => left.intersect(right)
                case "Difference" => left.difference(right)
                case _ => left.symmetricDifference(right)
            }
        case _ => CharSet()
    }
}

func astAsciiSet(name: String, negated: Bool, flags: AstFlagState): CharSet {
    let key = match (name) {
        case "Alnum" => "alnum"
        case "Alpha" => "alpha"
        case "Ascii" => "ascii"
        case "Blank" => "blank"
        case "Cntrl" => "cntrl"
        case "Digit" => "digit"
        case "Graph" => "graph"
        case "Lower" => "lower"
        case "Print" => "print"
        case "Punct" => "punct"
        case "Space" => "space"
        case "Upper" => "upper"
        case "Word" => "word"
        case _ => "xdigit"
    }
    var set = match (asciiClass(key)) {
        case Some(value) => value
        case None => CharSet()
    }
    astFold(set, flags)
    if (negated) {
        set = set.negated()
    }
    if (!flags.unicode) {
        set = astFinishAscii(set)
    }
    set
}

func astAsciiName(kind: String): String {
    match (kind) {
        case "Alnum" => "alnum"
        case "Alpha" => "alpha"
        case "Ascii" => "ascii"
        case "Blank" => "blank"
        case "Cntrl" => "cntrl"
        case "Digit" => "digit"
        case "Graph" => "graph"
        case "Lower" => "lower"
        case "Print" => "print"
        case "Punct" => "punct"
        case "Space" => "space"
        case "Upper" => "upper"
        case "Word" => "word"
        case _ => "xdigit"
    }
}

func astAsciiKind(name: String): String {
    match (name) {
        case "alnum" => "Alnum"
        case "alpha" => "Alpha"
        case "ascii" => "Ascii"
        case "blank" => "Blank"
        case "cntrl" => "Cntrl"
        case "digit" => "Digit"
        case "graph" => "Graph"
        case "lower" => "Lower"
        case "print" => "Print"
        case "punct" => "Punct"
        case "space" => "Space"
        case "upper" => "Upper"
        case "word" => "Word"
        case "xdigit" => "Xdigit"
        case _ => ""
    }
}

func astPerlSet(name: String, negated: Bool, flags: AstFlagState): CharSet {
    let lower = match (name) {
        case "Digit" => r'd'
        case "Space" => r's'
        case _ => r'w'
    }
    var set = if (flags.unicode) {
        unicodeClass(lower)
    } else {
        let ascii = match (name) {
            case "Digit" => "digit"
            case "Space" => "space"
            case _ => "word"
        }
        match (asciiClass(ascii)) {
            case Some(value) => value
            case None => throw Exception("missing ASCII class")
        }
    }
    if (negated) {
        set = set.negated()
    }
    if (!flags.unicode) {
        set = astFinishAscii(set)
    }
    set
}

func astLook(kind: String, flags: AstFlagState): HirLook {
    match (kind) {
        case "StartLine" => astLineLook(true, flags)
        case "EndLine" => astLineLook(false, flags)
        case "StartText" => HirLook.Start
        case "EndText" => HirLook.End
        case "WordBoundary" =>
            if (flags.unicode) {
                HirLook.WordUnicode
            } else {
                HirLook.WordAscii
            }
        case "NotWordBoundary" =>
            if (flags.unicode) {
                HirLook.WordUnicodeNegate
            } else {
                HirLook.WordAsciiNegate
            }
        case "WordBoundaryStart" | "WordBoundaryStartAngle" =>
            if (flags.unicode) {
                HirLook.WordStartUnicode
            } else {
                HirLook.WordStartAscii
            }
        case "WordBoundaryEnd" | "WordBoundaryEndAngle" =>
            if (flags.unicode) {
                HirLook.WordEndUnicode
            } else {
                HirLook.WordEndAscii
            }
        case "WordBoundaryStartHalf" =>
            if (flags.unicode) {
                HirLook.WordStartHalfUnicode
            } else {
                HirLook.WordStartHalfAscii
            }
        case "WordBoundaryEndHalf" =>
            if (flags.unicode) {
                HirLook.WordEndHalfUnicode
            } else {
                HirLook.WordEndHalfAscii
            }
        case _ => throw Exception("unknown AST assertion")
    }
}

func astLineLook(begin: Bool, flags: AstFlagState): HirLook {
    if (!flags.multiline) {
        return if (begin) {
            HirLook.Start
        } else {
            HirLook.End
        }
    }
    if (flags.crlf) {
        return if (begin) {
            HirLook.StartCRLF
        } else {
            HirLook.EndCRLF
        }
    }
    if (begin) {
        HirLook.StartLF
    } else {
        HirLook.EndLF
    }
}

func astFlagBit(ch: Rune): Int64 {
    match (ch) {
        case r'i' => AST_FLAG_I
        case r'm' => AST_FLAG_M
        case r's' => AST_FLAG_S
        case r'U' => AST_FLAG_SWAP
        case r'x' => AST_FLAG_X
        case r'R' => AST_FLAG_R
        case r'u' => AST_FLAG_UNICODE
        case _ => 0
    }
}

func astMeta(ch: Rune): Bool {
    match (ch) {
        case r'\\' | r'.' | r'+' | r'*' | r'?' | r'(' | r')' | r'|' | r'[' | r']' | r'{' | r'}' | r'^' | r'$' => true
        case _ => false
    }
}

func astHexDigit(ch: Rune): Int64 {
    let code = UInt32(ch)
    if (ch >= r'0' && ch <= r'9') {
        return Int64(code - UInt32(r'0'))
    }
    if (ch >= r'a' && ch <= r'f') {
        return Int64(code - UInt32(r'a') + 10)
    }
    if (ch >= r'A' && ch <= r'F') {
        return Int64(code - UInt32(r'A') + 10)
    }
    throw Exception("invalid hexadecimal digit")
}

func astLiteralKind(ast: Ast): String {
    if (ast.quantifier.isEmpty()) {
        "Verbatim"
    } else {
        ast.quantifier
    }
}

func astPropertyKind(text: String): String {
    let chars = ArrayList<Rune>()
    for (ch in text.runes()) {
        chars.add(ch)
    }
    var notEqual: Int64 = -1
    var colon: Int64 = -1
    var equal: Int64 = -1
    for (i in 0..chars.size) {
        if (chars[i] == r'!' && i + 1 < chars.size && chars[i + 1] == r'=' && notEqual < 0) {
            notEqual = i
        }
        if (chars[i] == r':' && colon < 0) {
            colon = i
        }
        if (chars[i] == r'=' && equal < 0 && (i == 0 || chars[i - 1] != r'!')) {
            equal = i
        }
    }
    let split = if (notEqual >= 0) {
        notEqual
    } else if (colon >= 0) {
        colon
    } else {
        equal
    }
    if (split < 0) {
        return "Named(\"${text}\")"
    }
    let op = if (notEqual >= 0) {
        "NotEqual"
    } else if (colon >= 0) {
        "Colon"
    } else {
        "Equal"
    }
    let skip = if (notEqual >= 0) {
        2
    } else {
        1
    }
    let name = astRunes(chars, 0, split)
    let value = astRunes(chars, split + skip, chars.size)
    "NamedValue { op: ${op}, name: \"${name}\", value: \"${value}\" }"
}

func astRunes(chars: ArrayList<Rune>, start: Int64, end: Int64): String {
    let out = StringBuilder()
    for (i in start..end) {
        out.append(chars[i])
    }
    out.toString()
}

func astFlagText(ast: Ast): String {
    let names = ["i", "m", "s", "U", "x", "R", "u"]
    let bits = [AST_FLAG_I, AST_FLAG_M, AST_FLAG_S, AST_FLAG_SWAP, AST_FLAG_X, AST_FLAG_R, AST_FLAG_UNICODE]
    var enabled = ""
    var disabled = ""
    for (i in 0..names.size) {
        if ((ast.flagMask & bits[i]) == 0) {
            continue
        }
        if ((ast.flagValue & bits[i]) != 0) {
            enabled = enabled + names[i]
        } else {
            disabled = disabled + names[i]
        }
    }
    if (disabled.isEmpty()) {
        enabled
    } else if (enabled.isEmpty()) {
        "-${disabled}"
    } else {
        "${enabled}-${disabled}"
    }
}

func astPrintLiteral(out: StringBuilder, ast: Ast): Unit {
    match (ast.quantifier) {
        case "Special(LineFeed)" => out.append("\\n")
        case "Special(CarriageReturn)" => out.append("\\r")
        case "Special(Tab)" => out.append("\\t")
        case "Special(Bell)" => out.append("\\a")
        case "Special(FormFeed)" => out.append("\\f")
        case "Special(VerticalTab)" => out.append("\\v")
        case "Meta" | "Superfluous" =>
            out.append("\\")
            out.append(String([Rune(UInt32(ast.code))]))
        case "HexFixed(X)" =>
            out.append("\\x")
            out.append(astHex(ast.code, 2))
        case "HexFixed(UnicodeShort)" =>
            out.append("\\u")
            out.append(astHex(ast.code, 4))
        case "HexFixed(UnicodeLong)" =>
            out.append("\\U")
            out.append(astHex(ast.code, 8))
        case "HexBrace(X)" =>
            out.append("\\x{")
            out.append(astHex(ast.code, 1))
            out.append("}")
        case "HexBrace(UnicodeShort)" =>
            out.append("\\u{")
            out.append(astHex(ast.code, 1))
            out.append("}")
        case "HexBrace(UnicodeLong)" =>
            out.append("\\U{")
            out.append(astHex(ast.code, 1))
            out.append("}")
        case _ => astPrintChar(out, Rune(UInt32(ast.code)))
    }
}

func astHex(code: Int64, width: Int64): String {
    let digits = "0123456789ABCDEF"
    var value = code
    var out = ""
    var left = width
    while (left > 0 || value > 0) {
        let index = value % 16
        out = digits[index..index + 1] + out
        value = value / 16
        left--
    }
    out
}

func astPrintPerl(out: StringBuilder, ast: Ast): Unit {
    let letter = match (ast.quantifier) {
        case "Digit" =>
            if (ast.negated) {
                "D"
            } else {
                "d"
            }
        case "Space" =>
            if (ast.negated) {
                "S"
            } else {
                "s"
            }
        case _ =>
            if (ast.negated) {
                "W"
            } else {
                "w"
            }
    }
    out.append("\\${letter}")
}

public class SyntaxParser {
    public var caseInsensitive = false
    public var multiLine = false
    public var dotAll = false
    public var swapGreed = false
    public var ignoreWhitespace = false
    public var crlf = false
    public var unicode = true
    public var utf8 = true
    public var octal = false
    public var nestLimit: Int64 = 250
    public init() {}
    public func parseAst(pattern: String): Ast {
        let reader = AstReader(pattern)
        reader.scope.caseInsensitive = caseInsensitive
        reader.scope.multiline = multiLine
        reader.scope.dotAll = dotAll
        reader.scope.swapGreed = swapGreed
        reader.scope.ignoreWhitespace = ignoreWhitespace
        reader.scope.crlf = crlf
        reader.scope.unicode = unicode
        reader.octal = octal
        reader.parse()
    }
    public func parseHir(pattern: String): Hir {
        let options = syntaxOptions(this)
        let parser = Parser(pattern, options)
        hirFromExpr(parser.parse(), parser.captureNames.toArray())
    }
    public func translate(ast: Ast): Hir {
        let flags = AstFlagState()
        flags.caseInsensitive = caseInsensitive
        flags.multiline = multiLine
        flags.dotAll = dotAll
        flags.swapGreed = swapGreed
        flags.ignoreWhitespace = ignoreWhitespace
        flags.crlf = crlf
        flags.unicode = unicode
        flags.utf8 = utf8
        flags.pattern = ast.source
        astLower(ast, flags)
    }
}

func syntaxOptions(parser: SyntaxParser): PatternOptions {
    let options = PatternOptions()
    options.caseInsensitive = parser.caseInsensitive
    options.multiLine = parser.multiLine
    options.dotAll = parser.dotAll
    options.swapGreed = parser.swapGreed
    options.ignoreWhitespace = parser.ignoreWhitespace
    options.crlf = parser.crlf
    options.unicode = parser.unicode
    options.utf8 = parser.utf8
    options.octal = parser.octal
    options.nestLimit = parser.nestLimit
    options
}

func astPrintUnicode(out: StringBuilder, ast: Ast): Unit {
    out.append(if (ast.negated) {
        "\\P"
    } else {
        "\\p"
    })
    if (ast.quantifier.startsWith("OneLetter(")) {
        out.append(ast.captureName)
    } else {
        out.append("{")
        out.append(ast.captureName)
        out.append("}")
    }
}
