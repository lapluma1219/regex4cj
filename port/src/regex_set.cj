package cjregex

import std.collection.*

// Snapshot of pattern membership. len() is the number of original patterns,
// NOT the number of hits (matching Rust SetMatches::len).
public class SetMatches {
    private let hits: Array<Bool>
    init(hits: Array<Bool>) {
        this.hits = hits.clone()
    }
    public func len(): Int64 {
        hits.size
    }
    public func matched(index: Int64): Bool {
        if (index < 0 || index >= hits.size) {
            throw Exception("pattern index out of bounds")
        }
        return hits[index]
    }
    public func matchedAny(): Bool {
        for (hit in hits) {
            if (hit) {
                return true
            }
        }
        return false
    }
    public func matchedAll(): Bool {
        for (hit in hits) {
            if (!hit) {
                return false
            }
        }
        return true
    }
    public func indices(): Array<Int64> {
        let out = ArrayList<Int64>()
        for (i in 0..hits.size) {
            if (hits[i]) {
                out.add(i)
            }
        }
        return out.toArray()
    }
}

// A single scalar scan over a shared state arena. Each pattern gets its own
// Accept state, whose first field records its original index. No captures are
// collected: Save states are epsilon transitions here.
public class RegexSet {
    private let sourcePatterns: Array<String>
    private let states: Array<State>
    private let starts: Array<Int64>
    private let unicodeWords: CharSet
    private let asciiWords: CharSet

    public init(patterns: Array<String>) {
        this(patterns, PatternOptions())
    }
    init(patterns: Array<String>, options: PatternOptions) {
        if (patterns.size > 256) {
            throw Exception("RegexSet exceeds 256 patterns")
        }
        var bytes: Int64 = 0
        for (pattern in patterns) {
            bytes += pattern.size
        }
        if (bytes > 65536) {
            throw Exception("RegexSet exceeds 65536 pattern bytes")
        }
        sourcePatterns = patterns.clone()
        let compiler = Compiler()
        let roots = ArrayList<Int64>()
        for (i in 0..patterns.size) {
            try {
                let tree = Parser(patterns[i], options).parse()
                normalizeWidth(tree)
                let accept = compiler.add(Op.Accept, i, -1)
                roots.add(compiler.compile(tree, accept))
            } catch (e: Exception) {
                throw Exception("pattern ${i}: " + e.toString())
            }
        }
        states = compiler.states.toArray()
        starts = roots.toArray()
        var needUnicode = false
        var needAscii = false
        for (state in states) {
            match (state.op) {
                case Op.Look(mode) =>
                    if (mode.kind >= 6) {
                        if (mode.unicode) {
                            needUnicode = true
                        } else {
                            needAscii = true
                        }
                    }
                case _ => ()
            }
        }
        unicodeWords = if (needUnicode) {
            unicodeClass(r'w')
        } else {
            CharSet()
        }
        asciiWords = if (needAscii) {
            match (asciiClass("word")) {
                case Some(set) => set
                case None => throw Exception("missing ASCII word class")
            }
        } else {
            CharSet()
        }
    }
    public func len(): Int64 {
        sourcePatterns.size
    }
    public func isEmpty(): Bool {
        sourcePatterns.isEmpty()
    }
    public func patterns(): Array<String> {
        sourcePatterns.clone()
    }
    public func isMatch(text: String): Bool {
        scan(text, 0, true).matchedAny()
    }
    public func isMatchAt(text: String, start: Int64): Bool {
        scan(text, start, true).matchedAny()
    }
    public func matches(text: String): SetMatches {
        scan(text, 0, false)
    }
    public func matchesAt(text: String, start: Int64): SetMatches {
        scan(text, start, false)
    }

    private func closure(out: ArrayList<Int64>, seen: Array<Bool>, root: Int64, pos: Int64, input: Input): Unit {
        let stack = ArrayList<Int64>()
        stack.add(root)
        while (!stack.isEmpty()) {
            let id = stack.remove(at: stack.size - 1)
            if (seen[id]) {
                continue
            }
            seen[id] = true
            let state = states[id]
            match (state.op) {
                case Op.Split =>
                    stack.add(state.second)
                    stack.add(state.first)
                case Op.Save(_) => stack.add(state.first)
                case Op.Look(mode) =>
                    if (passesLook(mode, pos, input.chars, unicodeWords, asciiWords)) {
                        stack.add(state.first)
                    }
                case _ => out.add(id)
            }
        }
    }
    private func scan(text: String, start: Int64, stopAtFirst: Bool): SetMatches {
        let hits = Array<Bool>(starts.size, repeat: false)
        if (starts.isEmpty()) {
            return SetMatches(hits)
        }
        let input = Input(text)
        let from = input.boundary(start)
        var current = ArrayList<Int64>()
        var seen = Array<Bool>(states.size, repeat: false)
        var count: Int64 = 0
        for (pos in from..input.chars.size + 1) {
            for (i in 0..starts.size) {
                if (!hits[i]) {
                    closure(current, seen, starts[i], pos, input)
                }
            }
            let next = ArrayList<Int64>()
            let nextSeen = Array<Bool>(states.size, repeat: false)
            for (id in current) {
                let state = states[id]
                var consume = false
                match (state.op) {
                    case Op.Accept =>
                        if (!hits[state.first]) {
                            hits[state.first] = true
                            count++
                            if (stopAtFirst || count == starts.size) {
                                return SetMatches(hits)
                            }
                        }
                    case Op.Literal(c) => consume = pos < input.chars.size && input.chars[pos] == c
                    case Op.CharacterClass(set) => consume = pos < input.chars.size && set.contains(input.chars[pos])
                    case Op.Any(mode) => consume = pos < input.chars.size && passesDot(mode, input.chars[pos])
                    case _ => ()
                }
                if (consume) {
                    closure(next, nextSeen, state.first, pos + 1, input)
                }
            }
            current = next
            seen = nextSeen
        }
        return SetMatches(hits)
    }
}
