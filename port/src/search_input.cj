package cjregex

import std.collection.*

// Search configuration shared by PikeVM, the bounded backtracker, the DFA, and reverse search.
// The span limits where a match may be reported. Assertions still see bytes
// outside that span. Anchor 0 is unanchored, 1 is anchored at the span start,
// and 2 selects one pattern and anchors it. An unknown pattern id is a miss.
class PreparedHaystack {
    let bytes: Array<UInt8>
    let text: String
    let utf8: Bool
    init(bytes: Array<UInt8>, text: String, utf8: Bool) {
        this.bytes = bytes
        this.text = text
        this.utf8 = utf8
    }
}

func copyBytes(bytes: Array<UInt8>): Array<UInt8> {
    Array<UInt8>(bytes.size, {i => bytes[i]})
}

func decodeUtf8(bytes: Array<UInt8>): Option<String> {
    var at: Int64 = 0
    let chars = ArrayList<Rune>()
    while (at < bytes.size) {
        match (decodeForward(bytes, at, bytes.size)) {
            case None => return None
            case Some(decoded) =>
                chars.add(decoded.char)
                at += decoded.width
        }
    }
    let text = StringBuilder()
    for (char in chars) {
        text.append(char.toString())
    }
    Some(text.toString())
}

func prepareBytes(bytes: Array<UInt8>): PreparedHaystack {
    let copied = copyBytes(bytes)
    match (decodeUtf8(copied)) {
        case Some(text) => PreparedHaystack(copied, text, true)
        case None => PreparedHaystack(copied, "", false)
    }
}

public func debugByte(byte: Int64): String {
    if (byte == 32) {
        return "' '"
    }
    if (byte == 9) {
        return "\\t"
    }
    if (byte == 10) {
        return "\\n"
    }
    if (byte == 13) {
        return "\\r"
    }
    if (byte == 39) {
        return "\\'"
    }
    if (byte == 92) {
        return "\\\\"
    }
    if (byte >= 33 && byte <= 126) {
        return String([Rune(UInt32(byte))])
    }
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    let hi = digits[byte / 16]
    let lo = digits[byte % 16]
    "\\x${hi}${lo}"
}

public class SearchInput {
    public let bytes: Array<UInt8>
    public let text: String
    public let utf8: Bool
    public let start: Int64
    public let end: Int64
    public let anchor: Int64
    public let pattern: Int64
    public let earliest: Bool
    public init(text: String) {
        this(text.toArray(), text, true, 0, text.size, 0, -1, false)
    }
    public init(bytes: Array<UInt8>) {
        this(prepareBytes(bytes))
    }
    init(prepared: PreparedHaystack) {
        this(prepared.bytes, prepared.text, prepared.utf8, 0, prepared.bytes.size, 0, -1, false)
    }
    init(bytes: Array<UInt8>, text: String, utf8: Bool, start: Int64, end: Int64, anchor: Int64, pattern: Int64,
        earliest: Bool) {
        if (start < 0 || end < start || end > bytes.size) {
            throw Exception("invalid search range")
        }
        this.bytes = bytes
        this.text = text
        this.utf8 = utf8
        this.start = start
        this.end = end
        this.anchor = anchor
        this.pattern = pattern
        this.earliest = earliest
    }
    public func span(start: Int64, end: Int64): SearchInput {
        SearchInput(bytes, text, utf8, start, end, anchor, pattern, earliest)
    }
    public func anchored(yes: Bool): SearchInput {
        SearchInput(bytes, text, utf8, start, end, if (yes) {
            1
        } else {
            0
        }, -1, earliest)
    }
    public func selectPattern(id: Int64): SearchInput {
        SearchInput(bytes, text, utf8, start, end, 2, id, earliest)
    }
    public func withEarliest(yes: Bool): SearchInput {
        SearchInput(bytes, text, utf8, start, end, anchor, pattern, yes)
    }
    public func isAnchored(): Bool {
        anchor != 0
    }
    public func selectedPattern(): Int64 {
        if (anchor == 2) {
            pattern
        } else {
            -1
        }
    }
}
