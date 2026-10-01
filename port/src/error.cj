package cjregex

import std.collection.*

// regex::Error. Syntax text is regex-syntax's Formatter. CompiledTooBig uses
// the configured limit, not the measured size.
public enum RegexErrorKind {
    | Syntax
    | CompiledTooBig
}

public class RegexError <: Exception {
    public let errorKind: RegexErrorKind
    public let limit: Int64
    public let text: String
    public init(errorKind: RegexErrorKind, message: String, limit: Int64) {
        super(message)
        this.errorKind = errorKind
        this.limit = limit
        text = message
    }
    public override func toString(): String {
        text
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
func formatSyntaxError(pattern: String, start: Int64, end: Int64, message: String): String {
    formatSyntaxErrorSpans(pattern, start, end, -1, -1, message)
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
