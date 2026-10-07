package regex4cj

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

    public func iter(): SetMatchesIter {
        SetMatchesIter(hits, 0, hits.size)
    }
}

// The result owns its hit snapshot and never mutates it. Each cursor keeps
// independent bounds; no array of matching indices is collected in advance.
public class SetMatchesIter {
    private let hits: Array<Bool>
    private var front: Int64
    private var back: Int64

    init(hits: Array<Bool>, front: Int64, back: Int64) {
        this.hits = hits
        this.front = front
        this.back = back
    }

    public func next(): Option<Int64> {
        while (front < back) {
            let index = front
            front++
            if (hits[index]) {
                return Some(index)
            }
        }
        return None
    }

    public func nextBack(): Option<Int64> {
        while (front < back) {
            back--
            if (hits[back]) {
                return Some(back)
            }
        }
        return None
    }

    // Mirrors the pinned Rust iterator: bounds describe unscanned pattern
    // slots, NOT the number of remaining hits (including its lower bound).
    public func sizeHint(): (Int64, Option<Int64>) {
        let remaining = back - front
        return (remaining, Some(remaining))
    }

    public func clone(): SetMatchesIter {
        SetMatchesIter(hits, front, back)
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
        sourcePatterns = patterns.clone()
        let trees = ArrayList<Expr>()
        for (i in 0..patterns.size) {
            let tree = Parser(patterns[i], options).parse()
            normalizeWidth(tree)
            trees.add(tree)
        }
        ensureWithinSizeLimit(trees.toArray(), options.sizeLimit, false)
        let compiler = Compiler(options.sizeLimit)
        let roots = ArrayList<Int64>()
        for (i in 0..trees.size) {
            let accept = compiler.add(Op.Accept, i, -1)
            roots.add(compiler.compile(trees[i], accept))
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
    // Same as matchesAt, but sets matched slots to true and leaves the others
    // untouched. Returns whether this search matched anything.
    public func matchesReadAt(slots: Array<Bool>, text: String, start: Int64): Bool {
        let found = scan(text, start, false)
        var any = false
        for (i in 0..starts.size) {
            if (found.matched(i)) {
                if (i >= slots.size) {
                    throw Exception("match index out of bounds")
                }
                slots[i] = true
                any = true
            }
        }
        return any
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
                    case Op.CharacterClass(set) => consume = (if (pos < input.chars.size) {
                        set.contains(input.chars[pos])
                    } else {
                        false
                    })
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
