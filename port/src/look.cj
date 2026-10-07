package regex4cj

import std.collection.*

// Look and dot kinds snapshotted onto each atom. Numbers stay stable because
// both the single-pattern and set executors share these predicates.
// 0 text start, 1 text end, 2 line start, 3 line end, 4 CRLF start, 5 CRLF end,
// 6 word, 7 word start, 8 word end, 9 half start, 10 half end.
// Dot: 0 except one terminator, 1 any scalar, 2 except CR and LF.

class AtomMode {
    let kind: Int64
    let term: Rune
    let unicode: Bool
    let positive: Bool
    init(kind: Int64, term: Rune, unicode: Bool, positive: Bool) {
        this.kind = kind
        this.term = term
        this.unicode = unicode
        this.positive = positive
    }
}

func wordAt(chars: ArrayList<Rune>, index: Int64, unicode: Bool, unicodeWords: CharSet, asciiWords: CharSet): Bool {
    if (index < 0 || index >= chars.size) {
        return false
    }
    let words = if (unicode) {
        unicodeWords
    } else {
        asciiWords
    }
    return words.contains(chars[index])
}

func passesDot(mode: AtomMode, char: Rune): Bool {
    match (mode.kind) {
        case 1 => true
        case 2 => char != r'\r' && char != r'\n'
        case _ => char != mode.term
    }
}

func utf8First(char: Rune): Int64 {
    let code = UInt32(char)
    if (code < 0x80) {
        return Int64(code)
    }
    if (code < 0x800) {
        return Int64(0xC0 + (code >> 6))
    }
    if (code < 0x10000) {
        return Int64(0xE0 + (code >> 12))
    }
    return Int64(0xF0 + (code >> 18))
}

func utf8Last(char: Rune): Int64 {
    let code = UInt32(char)
    if (code < 0x80) {
        return Int64(code)
    }
    return Int64(0x80 + (code & 0x3F))
}

class DecodedScalar {
    let char: Rune
    let width: Int64
    init(char: Rune, width: Int64) {
        this.char = char
        this.width = width
    }
}

// Decode one scalar starting at `at`, without reading at or after `end`.
func decodeForward(bytes: Array<UInt8>, at: Int64, end: Int64): Option<DecodedScalar> {
    if (at < 0 || at >= end || end > bytes.size) {
        return None
    }
    let b0 = Int64(bytes[at])
    if (b0 < 0x80) {
        return Some(DecodedScalar(Rune(UInt32(b0)), 1))
    }
    var need: Int64 = 0
    var value: Int64 = 0
    var min: Int64 = 0
    if (b0 >= 0xC2 && b0 <= 0xDF) {
        need = 2
        value = b0 & 0x1F
        min = 0x80
    } else if (b0 >= 0xE0 && b0 <= 0xEF) {
        need = 3
        value = b0 & 0x0F
        min = 0x800
    } else if (b0 >= 0xF0 && b0 <= 0xF4) {
        need = 4
        value = b0 & 0x07
        min = 0x10000
    } else {
        return None
    }
    if (at + need > end) {
        return None
    }
    var i: Int64 = 1
    while (i < need) {
        let b = Int64(bytes[at + i])
        if ((b & 0xC0) != 0x80) {
            return None
        }
        value = (value << 6) | (b & 0x3F)
        i++
    }
    if (value < min || value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
        return None
    }
    return Some(DecodedScalar(Rune(UInt32(value)), need))
}

// Last scalar in bytes[0..at), matching regex-automata utf8::decode_last.
func decodeLast(bytes: Array<UInt8>, at: Int64): Option<Rune> {
    if (at <= 0) {
        return None
    }
    var start = at - 1
    let limit = if (at > 4) {
        at - 4
    } else {
        0
    }
    while (start > limit && (Int64(bytes[start]) & 0xC0) == 0x80) {
        start--
    }
    match (decodeForward(bytes, start, at)) {
        case Some(decoded) => return Some(decoded.char)
        case None => return None
    }
}

func passesLookBytes(mode: AtomMode, pos: Int64, bytes: Array<UInt8>, unicodeWords: CharSet, asciiWords: CharSet): Bool {
    let last = bytes.size
    let term = Int64(UInt32(mode.term))
    match (mode.kind) {
        case 0 => return pos == 0
        case 1 => return pos == last
        case 2 => return pos == 0 || Int64(bytes[pos - 1]) == term
        case 3 => return pos == last || Int64(bytes[pos]) == term
        case 4 => return pos == 0 || bytes[pos - 1] == UInt8(10) || (bytes[pos - 1] == UInt8(13) && (pos == last ||
            bytes[pos] != UInt8(10)))
        case 5 => return pos == last || bytes[pos] == UInt8(13) || (bytes[pos] == UInt8(10) && (pos == 0 ||
            bytes[pos - 1] != UInt8(13)))
        case _ =>
            let before = wordByteBefore(mode, pos, bytes, unicodeWords, asciiWords)
            let after = wordByteAfter(mode, pos, bytes, unicodeWords, asciiWords)
            if (mode.kind == 6 && !mode.positive && mode.unicode) {
                if (pos > 0) {
                    match (decodeLast(bytes, pos)) {
                        case None => return false
                        case Some(_) => ()
                    }
                }
                if (pos < last) {
                    match (decodeForward(bytes, pos, last)) {
                        case None => return false
                        case Some(_) => ()
                    }
                }
            }
            match (mode.kind) {
                case 6 => return (before != after) == mode.positive
                case 7 => return !before && after
                case 8 => return before && !after
                case 9 => return !before
                case _ => return !after
            }
    }
}

func wordByteBefore(mode: AtomMode, pos: Int64, bytes: Array<UInt8>, unicodeWords: CharSet, asciiWords: CharSet): Bool {
    if (pos <= 0) {
        return false
    }
    if (!mode.unicode) {
        return asciiWords.contains(Rune(UInt32(bytes[pos - 1])))
    }
    match (decodeLast(bytes, pos)) {
        case Some(char) => return unicodeWords.contains(char)
        case None => return false
    }
}

func wordByteAfter(mode: AtomMode, pos: Int64, bytes: Array<UInt8>, unicodeWords: CharSet, asciiWords: CharSet): Bool {
    if (pos >= bytes.size) {
        return false
    }
    if (!mode.unicode) {
        return asciiWords.contains(Rune(UInt32(bytes[pos])))
    }
    match (decodeForward(bytes, pos, bytes.size)) {
        case Some(decoded) => return unicodeWords.contains(decoded.char)
        case None => return false
    }
}

func passesLook(mode: AtomMode, pos: Int64, chars: ArrayList<Rune>, unicodeWords: CharSet, asciiWords: CharSet): Bool {
    let last = chars.size
    let term = Int64(UInt32(mode.term))
    match (mode.kind) {
        case 0 => pos == 0
        case 1 => pos == last
        case 2 => pos == 0 || utf8Last(chars[pos - 1]) == term
        case 3 => pos == last || utf8First(chars[pos]) == term
        case 4 => pos == 0 || chars[pos - 1] == r'\n' || (chars[pos - 1] == r'\r' && (pos == last || chars[pos] != r'\n'))
        case 5 => pos == last || chars[pos] == r'\r' || (chars[pos] == r'\n' && (pos == 0 || chars[pos - 1] != r'\r'))
        case _ =>
            let before = wordAt(chars, pos - 1, mode.unicode, unicodeWords, asciiWords)
            let after = wordAt(chars, pos, mode.unicode, unicodeWords, asciiWords)
            match (mode.kind) {
                case 6 => (before != after) == mode.positive
                case 7 => !before && after
                case 8 => before && !after
                case 9 => !before
                case _ => !after
            }
    }
}
