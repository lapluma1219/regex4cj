package cjregex

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

func passesLook(mode: AtomMode, pos: Int64, chars: ArrayList<Rune>, unicodeWords: CharSet, asciiWords: CharSet): Bool {
    let last = chars.size
    match (mode.kind) {
        case 0 => pos == 0
        case 1 => pos == last
        case 2 => pos == 0 || chars[pos - 1] == mode.term
        case 3 => pos == last || chars[pos] == mode.term
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
