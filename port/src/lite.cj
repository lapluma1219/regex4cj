package cjregex

import std.collection.*

// regex-lite: ASCII Perl classes and ASCII word boundaries, no Unicode
// properties. Search is the same leftmost-first Pike loop, built with Unicode
// scalar mode on. ASCII classes and folding are selected independently.
public class LiteRegex {
    let nfa: ThompsonNfa
    let cache: PikeCache
    public init(pattern: String) {
        rejectUnicodeClass(pattern)
        nfa = ThompsonNfa(buildLitePattern(pattern))
        cache = PikeCache()
    }
    public func search(text: String): Option<PikeMatch> {
        nfa.search(SearchInput(text), cache)
    }
    public func isMatch(text: String): Bool {
        nfa.isMatch(SearchInput(text), cache)
    }
    public func searchAll(text: String): Array<PikeMatch> {
        let found = ArrayList<PikeMatch>()
        var start: Int64 = 0
        var lastEnd: Int64 = -1
        var reading = true
        while (reading && start <= text.size) {
            match (nfa.search(SearchInput(text).span(start, text.size), cache)) {
                case None => reading = false
                case Some(hit) =>
                    var report = hit
                    var emit = true
                    let emptyHit = hit.start() == hit.end()
                    let repeatedEnd = hit.end() == lastEnd
                    if (emptyHit && repeatedEnd) {
                        let next = hit.end() + 1
                        if (next > text.size) {
                            reading = false
                            emit = false
                        } else {
                            match (nfa.search(SearchInput(text).span(next, text.size), cache)) {
                                case None =>
                                    reading = false
                                    emit = false
                                case Some(again) => report = again
                            }
                        }
                    }
                    if (emit) {
                        found.add(report)
                        lastEnd = report.end()
                        start = report.end()
                    }
            }
        }
        found.toArray()
    }
}

func rejectUnicodeClass(pattern: String): Unit {
    var escaped = false
    for (char in pattern.runes()) {
        if (escaped) {
            if (char == r'p' || char == r'P') {
                throw Exception("Unicode character classes are not supported")
            }
            escaped = false
        } else if (UInt32(char) == 92) {
            escaped = true
        }
    }
}
