package regex4cj

import std.collection.*

// regex::Error. Syntax text is regex-syntax's Formatter. CompiledTooBig uses
// the configured limit, not the measured size.
public enum RegexErrorKind {
    | Syntax
    | CompiledTooBig
}

// Byte offset plus 1-based line and scalar column, matching regex-syntax Position.
public class RegexErrorSpan {
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

public class RegexError <: Exception {
    public let errorKind: RegexErrorKind
    public let limit: Int64
    public let text: String
    // "parse" or "translate" for a syntax error. Empty for CompiledTooBig.
    public let phase: String
    // regex-syntax ErrorKind variant name, without its payload.
    public let name: String
    public let primary: Option<RegexErrorSpan>
    public let auxiliary: Option<RegexErrorSpan>
    public init(errorKind: RegexErrorKind, message: String, limit: Int64) {
        this(errorKind, message, limit, "", "", None<RegexErrorSpan>, None<RegexErrorSpan>)
    }
    public init(errorKind: RegexErrorKind, message: String, limit: Int64, phase: String, name: String,
        primary: Option<RegexErrorSpan>, auxiliary: Option<RegexErrorSpan>) {
        super(message)
        this.errorKind = errorKind
        this.limit = limit
        text = message
        this.phase = phase
        this.name = name
        this.primary = primary
        this.auxiliary = auxiliary
    }
    public override func toString(): String {
        text
    }
    public func structure(): String {
        let spanText = match (primary) {
            case Some(span) => span.text()
            case None => "-"
        }
        let auxText = match (auxiliary) {
            case Some(span) => span.text()
            case None => "-"
        }
        "${phase}\t${name}\nspan\t${spanText}\naux\t${auxText}"
    }
}

func compiledTooBig(limit: Int64): RegexError {
    RegexError(RegexErrorKind.CompiledTooBig, "Compiled regex exceeds size limit of ${limit} bytes.", limit)
}

class SourcePoint {
    let line: Int64
    let column: Int64
    init(line: Int64, column: Int64) {
        this.line = line
        this.column = column
    }
}

class SourceSpan {
    let start: SourcePoint
    let end: SourcePoint
    init(start: SourcePoint, end: SourcePoint) {
        this.start = start
        this.end = end
    }
    func oneLine(): Bool {
        start.line == end.line
    }
}

// Column is a 1-based scalar index on the line, matching regex-syntax Position.
func translateError(pattern: String, span: AstSpan, message: String): RegexError {
    let start = scalarAt(pattern, span.startOffset)
    let end = scalarAt(pattern, span.endOffset)
    let display = formatSyntaxErrorSpans(pattern, start, end, -1, -1, message)
    let classified = classifySyntax(message)
    let primary = RegexErrorSpan(span.startOffset, span.startLine, span.startColumn, span.endOffset, span.endLine,
        span.endColumn)
    RegexError(RegexErrorKind.Syntax, display, -1, classified[0], classified[1], Some(primary), None<RegexErrorSpan>)
}

func scalarAt(pattern: String, byteOffset: Int64): Int64 {
    var offset: Int64 = 0
    var index: Int64 = 0
    for (ch in pattern.runes()) {
        if (offset >= byteOffset) {
            return index
        }
        offset += utf8Width(ch)
        index++
    }
    index
}

func syntaxError(pattern: String, start: Int64, end: Int64, auxStart: Int64, auxEnd: Int64, message: String): RegexError {
    let display = formatSyntaxErrorSpans(pattern, start, end, auxStart, auxEnd, message)
    let classified = classifySyntax(message)
    let primary = Some(locateSyntax(pattern, start, end))
    let auxiliary = if (auxStart < 0) {
        None<RegexErrorSpan>
    } else {
        Some(locateSyntax(pattern, auxStart, auxEnd))
    }
    RegexError(RegexErrorKind.Syntax, display, -1, classified[0], classified[1], primary, auxiliary)
}

func classifySyntax(message: String): Array<String> {
    if (message == "Unicode not allowed here") {
        return ["translate", "UnicodeNotAllowed"]
    }
    if (message == "pattern can match invalid UTF-8") {
        return ["translate", "InvalidUtf8"]
    }
    if (message == "invalid line terminator, must be ASCII") {
        return ["translate", "InvalidLineTerminator"]
    }
    if (message == "Unicode property not found") {
        return ["translate", "UnicodePropertyNotFound"]
    }
    if (message == "Unicode property value not found") {
        return ["translate", "UnicodePropertyValueNotFound"]
    }
    let name = match (message) {
        case "invalid escape sequence found in character class" => "ClassEscapeInvalid"
        case "invalid character class range, the start must be <= the end" => "ClassRangeInvalid"
        case "invalid range boundary, must be a literal" => "ClassRangeLiteral"
        case "unclosed character class" => "ClassUnclosed"
        case "decimal literal empty" => "DecimalEmpty"
        case "decimal literal invalid" => "DecimalInvalid"
        case "hexadecimal literal empty" => "EscapeHexEmpty"
        case "hexadecimal literal is not a Unicode scalar value" => "EscapeHexInvalid"
        case "invalid hexadecimal digit" => "EscapeHexInvalidDigit"
        case "incomplete escape sequence, reached end of pattern prematurely" => "EscapeUnexpectedEof"
        case "unrecognized escape sequence" => "EscapeUnrecognized"
        case "dangling flag negation operator" => "FlagDanglingNegation"
        case "duplicate flag" => "FlagDuplicate"
        case "flag negation operator repeated" => "FlagRepeatedNegation"
        case "expected flag but got end of regex" => "FlagUnexpectedEof"
        case "unrecognized flag" => "FlagUnrecognized"
        case "duplicate capture group name" => "GroupNameDuplicate"
        case "empty capture group name" => "GroupNameEmpty"
        case "invalid capture group character" => "GroupNameInvalid"
        case "unclosed capture group name" => "GroupNameUnexpectedEof"
        case "unclosed group" => "GroupUnclosed"
        case "unopened group" => "GroupUnopened"
        case "invalid repetition count range, the start must be <= the end" => "RepetitionCountInvalid"
        case "repetition quantifier expects a valid decimal" => "RepetitionCountDecimalEmpty"
        case "unclosed counted repetition" => "RepetitionCountUnclosed"
        case "repetition operator missing expression" => "RepetitionMissing"
        case "special word boundary assertion is either unclosed or contains an invalid character" => "SpecialWordBoundaryUnclosed"
        case "unrecognized special word boundary assertion, valid choices are: start, end, start-half or end-half" => "SpecialWordBoundaryUnrecognized"
        case "found either the beginning of a special word boundary or a bounded repetition on a \\b with an opening brace, but no closing brace" => "SpecialWordOrRepetitionUnexpectedEof"
        case "invalid Unicode character class" => "UnicodeClassInvalid"
        case "backreferences are not supported" => "UnsupportedBackreference"
        case "look-around, including look-ahead and look-behind, is not supported" => "UnsupportedLookAround"
        case _ =>
            if (message.startsWith("exceed the maximum number of nested parentheses/brackets")) {
                "NestLimitExceeded"
            } else {
                ""
            }
    }
    ["parse", name]
}

func locateSyntax(pattern: String, start: Int64, end: Int64): RegexErrorSpan {
    let chars = ArrayList<Rune>()
    for (c in pattern.runes()) {
        chars.add(c)
    }
    let offsets = Array<Int64>(chars.size + 1, repeat: 0)
    let lines = Array<Int64>(chars.size + 1, repeat: 1)
    let columns = Array<Int64>(chars.size + 1, repeat: 1)
    var offset: Int64 = 0
    var line: Int64 = 1
    var column: Int64 = 1
    for (i in 0..chars.size) {
        offsets[i] = offset
        lines[i] = line
        columns[i] = column
        offset += utf8Width(chars[i])
        if (chars[i] == r'\n') {
            line++
            column = 1
        } else {
            column++
        }
    }
    offsets[chars.size] = offset
    lines[chars.size] = line
    columns[chars.size] = column
    let last = chars.size
    let a = if (start < 0) {
        0
    } else if (start > last) {
        last
    } else {
        start
    }
    let b = if (end < a) {
        a
    } else if (end > last) {
        last
    } else {
        end
    }
    RegexErrorSpan(offsets[a], lines[a], columns[a], offsets[b], lines[b], columns[b])
}

func utf8Width(ch: Rune): Int64 {
    let code = UInt32(ch)
    if (code < 0x80) {
        return 1
    }
    if (code < 0x800) {
        return 2
    }
    if (code < 0x10000) {
        return 3
    }
    4
}

func formatSyntaxErrorSpans(pattern: String, start: Int64, end: Int64, auxStart: Int64, auxEnd: Int64, message: String): String {
    let chars = ArrayList<Rune>()
    for (c in pattern.runes()) {
        chars.add(c)
    }
    let lines = ArrayList<StringBuilder>()
    lines.add(StringBuilder())
    let lineOf = Array<Int64>(chars.size + 1, repeat: 0)
    let columnOf = Array<Int64>(chars.size + 1, repeat: 1)
    var line: Int64 = 0
    var column: Int64 = 1
    for (i in 0..chars.size) {
        lineOf[i] = line
        columnOf[i] = column
        if (chars[i] == r'\n') {
            lines.add(StringBuilder())
            line++
            column = 1
        } else {
            lines[line].append(chars[i])
            column++
        }
    }
    lineOf[chars.size] = line
    columnOf[chars.size] = column
    let spans = ArrayList<SourceSpan>()
    spans.add(spanAt(lineOf, columnOf, start, end))
    if (auxStart >= 0) {
        spans.add(spanAt(lineOf, columnOf, auxStart, auxEnd))
    }
    let multi = patternHasNewline(chars)
    let width = if (lines.size <= 1) {
        0
    } else {
        digitCount(lines.size)
    }
    let out = StringBuilder()
    out.append("regex parse error:\n")
    if (multi) {
        appendChar(out, r'~', 79)
        out.append("\n")
    }
    let notes = ArrayList<String>()
    for (i in 0..lines.size) {
        if (width > 0) {
            appendPad(out, width - digitCount(i + 1))
            out.append("${i + 1}: ")
        } else {
            out.append("    ")
        }
        out.append(lines[i].toString())
        out.append("\n")
        let carets = caretLine(spans, i, width)
        match (carets) {
            case Some(text) =>
                out.append(text)
                out.append("\n")
            case None => ()
        }
    }
    for (span in spans) {
        if (!span.oneLine()) {
            let last = span.end.column - 1
            notes.add(
                "on line ${span.start.line} (column ${span.start.column}) through line ${span.end.line} (column ${last})")
        }
    }
    if (multi) {
        appendChar(out, r'~', 79)
        out.append("\n")
        if (notes.size > 0) {
            for (i in 0..notes.size) {
                if (i > 0) {
                    out.append("\n")
                }
                out.append(notes[i])
            }
            out.append("\n")
        }
    }
    out.append("error: ${message}")
    out.toString()
}

func spanAt(lineOf: Array<Int64>, columnOf: Array<Int64>, start: Int64, end: Int64): SourceSpan {
    let a = if (start < 0) {
        0
    } else if (start > lineOf.size - 1) {
        lineOf.size - 1
    } else {
        start
    }
    let b = if (end < a) {
        a
    } else if (end > lineOf.size - 1) {
        lineOf.size - 1
    } else {
        end
    }
    SourceSpan(SourcePoint(lineOf[a] + 1, columnOf[a]), SourcePoint(lineOf[b] + 1, columnOf[b]))
}

func patternHasNewline(chars: ArrayList<Rune>): Bool {
    for (c in chars) {
        if (c == r'\n') {
            return true
        }
    }
    false
}

func digitCount(value: Int64): Int64 {
    var n = value
    var count: Int64 = 1
    while (n >= 10) {
        n = n / 10
        count++
    }
    count
}

func appendPad(out: StringBuilder, count: Int64): Unit {
    var i: Int64 = 0
    while (i < count) {
        out.append(r' ')
        i++
    }
}

func appendChar(out: StringBuilder, c: Rune, count: Int64): Unit {
    var i: Int64 = 0
    while (i < count) {
        out.append(c)
        i++
    }
}

func caretLine(spans: ArrayList<SourceSpan>, lineIndex: Int64, width: Int64): Option<String> {
    let row = ArrayList<SourceSpan>()
    for (span in spans) {
        if (span.oneLine() && span.start.line == lineIndex + 1) {
            row.add(span)
        }
    }
    if (row.size == 0) {
        return None
    }
    var i: Int64 = 1
    while (i < row.size) {
        var j = i
        while (j > 0 && row[j - 1].start.column > row[j].start.column) {
            let tmp = row[j - 1]
            row[j - 1] = row[j]
            row[j] = tmp
            j--
        }
        i++
    }
    let out = StringBuilder()
    let pad = if (width == 0) {
        4
    } else {
        2 + width
    }
    appendPad(out, pad)
    var pos: Int64 = 0
    for (span in row) {
        while (pos < span.start.column - 1) {
            out.append(r' ')
            pos++
        }
        var marks = span.end.column - span.start.column
        if (marks < 1) {
            marks = 1
        }
        appendChar(out, r'^', marks)
        pos += marks
    }
    Some(out.toString())
}
