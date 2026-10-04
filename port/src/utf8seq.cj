package cjregex

import std.collection.*

// Public view of the UTF-8 byte ranges already produced for Thompson accounting.
// The debug text matches regex-syntax Utf8Sequence.
public class Utf8Sequence {
    public let starts: Array<Int64>
    public let ends: Array<Int64>
    init(starts: Array<Int64>, ends: Array<Int64>) {
        this.starts = starts
        this.ends = ends
    }
    public func text(): String {
        let out = StringBuilder()
        for (i in 0..starts.size) {
            out.append("[")
            out.append(utf8HexByte(starts[i]))
            if (starts[i] != ends[i]) {
                out.append("-")
                out.append(utf8HexByte(ends[i]))
            }
            out.append("]")
        }
        out.toString()
    }
}

public func utf8SequenceLines(start: Int64, end: Int64): String {
    let rows = utf8SequencesOf(start, end)
    let out = StringBuilder()
    for (i in 0..rows.size) {
        if (i > 0) {
            out.append("\n")
        }
        out.append(rows[i].text())
    }
    out.toString()
}

public func utf8SequencesOf(start: Int64, end: Int64): Array<Utf8Sequence> {
    if (start < 0 || end > 0x10FFFF || start > end || utf8Surrogate(start) || utf8Surrogate(end)) {
        throw Exception("invalid scalar range")
    }
    let rows = utf8Sequences(start, end)
    Array<Utf8Sequence>(
        rows.size,
        {
            i =>
                let spans = rows[i]
                let starts = Array<Int64>(spans.size, {j => spans[j].start})
                let ends = Array<Int64>(spans.size, {j => spans[j].end})
                Utf8Sequence(starts, ends)
        }
    )
}

func utf8Surrogate(code: Int64): Bool {
    code >= 0xD800 && code <= 0xDFFF
}

func utf8HexByte(value: Int64): String {
    let digits = [r'0', r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9', r'A', r'B', r'C', r'D', r'E', r'F']
    let out = StringBuilder()
    let high = (value >> 4) & 15
    if (high != 0) {
        out.append(digits[high])
    }
    out.append(digits[value & 15])
    out.toString()
}
