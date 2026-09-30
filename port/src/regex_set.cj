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
    private let wordCharacters: CharSet

    public init(patterns: Array<String>) {
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
                let tree = Parser(patterns[i]).parse()
                normalizeWidth(tree)
                let accept = compiler.add(Op.Accept, i, -1)
                roots.add(compiler.compile(tree, accept))
            } catch (e: Exception) {
                throw Exception("pattern ${i}: " + e.toString())
            }
        }
        states = compiler.states.toArray()
        starts = roots.toArray()
        var hasBoundary = false
        for (state in states) {
            match (state.op) {
                case Op.WordBoundary(_) => hasBoundary = true
                case _ => ()
            }
        }
        wordCharacters = if (hasBoundary) {
            unicodeClass(r'w')
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
        scan(text, true).matchedAny()
    }
    public func matches(text: String): SetMatches {
        scan(text, false)
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
                case Op.Begin(multiline) =>
                    if (pos == 0 || (multiline && input.chars[pos - 1] == r'\n')) {
                        stack.add(state.first)
                    }
                case Op.End(multiline) =>
                    if (pos == input.chars.size || (multiline && input.chars[pos] == r'\n')) {
                        stack.add(state.first)
                    }
                case Op.WordBoundary(positive) =>
                    let before = pos > 0 && wordCharacters.contains(input.chars[pos - 1])
                    let after = pos < input.chars.size && wordCharacters.contains(input.chars[pos])
                    if ((before != after) == positive) {
                        stack.add(state.first)
                    }
                case _ => out.add(id)
            }
        }
    }
    private func scan(text: String, stopAtFirst: Bool): SetMatches {
        let hits = Array<Bool>(starts.size, repeat: false)
        if (starts.isEmpty()) {
            return SetMatches(hits)
        }
        let input = Input(text)
        var current = ArrayList<Int64>()
        var seen = Array<Bool>(states.size, repeat: false)
        var count: Int64 = 0
        for (pos in 0..input.chars.size + 1) {
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
                    case Op.Any(dotAll) => consume = pos < input.chars.size && (dotAll || input.chars[pos] != r'\n')
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
