package cjregex

import std.collection.*

// Reverse Thompson search. The graph comes from the shared byte compiler in
// backward mode, the same compiler the forward DFA uses. Captures are omitted.
// This is not a reversed string and not a reversal of the scalar Pike graph.
public class ReverseMatch {
    public let pattern: Int64
    public let offset: Int64
    public init(pattern: Int64, offset: Int64) {
        this.pattern = pattern
        this.offset = offset
    }
}

public class ReverseNfa {
    let states: Array<State>
    let startState: Int64
    let patternEntries: Array<Int64>
    let patternStartsEnabled: Bool
    let anchored: Bool
    let unicodeWords: CharSet
    let asciiWords: CharSet
    var matchedPattern: Int64
    public init(pattern: String) {
        this([pattern], false)
    }
    public init(patterns: Array<String>) {
        this(patterns, false)
    }
    public init(patterns: Array<String>, patternStarts: Bool) {
        this(patterns, patternStarts, 10485760)
    }
    public init(patterns: Array<String>, patternStarts: Bool, sizeLimit: Int64) {
        if (sizeLimit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        if (patterns.size == 0) {
            states = Array<State>()
            startState = -1
            patternEntries = Array<Int64>()
            patternStartsEnabled = patternStarts
            anchored = false
            unicodeWords = CharSet()
            asciiWords = CharSet()
            matchedPattern = 0
            return
        }
        let options = PatternOptions()
        let trees = ArrayList<Expr>()
        for (pattern in patterns) {
            let parser = Parser(pattern, options)
            trees.add(parser.parse())
        }
        let parsed = trees.toArray()
        ensureWithinSizeLimit(parsed, sizeLimit, false)
        let compiler = ByteCompiler(true)
        let starts = ArrayList<Int64>()
        for (i in 0..parsed.size) {
            let accept = compiler.add(Op.Accept, -1, -1)
            compiler.states[accept].patternId = i
            starts.add(compiler.compile(parsed[i], accept))
        }
        var union = starts[starts.size - 1]
        if (starts.size > 1) {
            var index = starts.size - 1
            while (index > 0) {
                index--
                union = compiler.split(starts[index], union, true)
            }
        }
        states = compiler.states.toArray()
        startState = union
        patternEntries = starts.toArray()
        patternStartsEnabled = patternStarts
        anchored = allAnchored(parsed, true)
        matchedPattern = 0
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
    public func search(text: String): Option<Int64> {
        match (searchImpl(text.toArray(), text.size, false, 0, false, startState)) {
            case Some(offset) => Some(offset)
            case None => None
        }
    }
    public func search(input: SearchInput): Option<Int64> {
        match (find(input)) {
            case Some(hit) => Some(hit.offset)
            case None => None
        }
    }
    public func find(input: SearchInput): Option<ReverseMatch> {
        let entry = entryFor(input)
        if (entry < 0) {
            return None
        }
        match (searchImpl(input.bytes, input.end, false, input.start, input.anchor != 0, entry)) {
            case Some(offset) => Some(ReverseMatch(matchedPattern, offset))
            case None => None
        }
    }
    // Recover the leftmost start for a known forward end. Retain all context
    // for assertions and explore all reverse alternatives, regardless of greed.
    func searchEndingAt(bytes: Array<UInt8>, end: Int64, floor: Int64): Option<Int64> {
        searchImpl(bytes, end, true, floor, false, startState)
    }
    func entryFor(input: SearchInput): Int64 {
        if (input.anchor != 2) {
            return startState
        }
        if (!patternStartsEnabled) {
            throw Exception("anchored searches for a specific pattern (${input.pattern}) are not supported or enabled")
        }
        if (input.pattern < 0 || input.pattern >= patternEntries.size) {
            return -1
        }
        patternEntries[input.pattern]
    }
    func searchImpl(bytes: Array<UInt8>, limit: Int64, longest: Bool, floor: Int64, inputAnchored: Bool, entry: Int64): Option<Int64> {
        if (entry < 0) {
            return None
        }
        if (limit < 0 || floor < 0 || floor > limit || limit > bytes.size) {
            throw Exception("invalid search range")
        }
        var pos = limit
        var current = ArrayList<Thread>()
        var best = -1
        var found = false
        var reading = true
        let tieEnd = anchored || inputAnchored || longest
        while (reading) {
            if (!found && (!tieEnd || pos == limit)) {
                let seen = Array<Bool>(states.size, repeat: false)
                closure(current, seen, entry, pos, bytes)
            }
            let next = ArrayList<Thread>()
            let nextSeen = Array<Bool>(states.size, repeat: false)
            var halt = false
            for (thread in current) {
                if (halt) {
                    break
                }
                let state = states[thread.state]
                match (state.op) {
                    case Op.Accept =>
                        best = pos
                        found = true
                        matchedPattern = state.patternId
                        halt = !longest
                    case Op.Literal(_) =>
                        if (byteMatches(state, bytes, pos)) {
                            closure(next, nextSeen, state.first, pos - 1, bytes)
                        }
                    case Op.CharacterClass(_) =>
                        if (byteMatches(state, bytes, pos)) {
                            closure(next, nextSeen, state.first, pos - 1, bytes)
                        }
                    case _ => ()
                }
            }
            if (found && next.size == 0) {
                return Some(best)
            }
            if (pos == floor) {
                reading = false
            } else {
                current = next
                pos--
            }
        }
        if (best >= 0) {
            Some(best)
        } else {
            None
        }
    }
    func byteMatches(state: State, bytes: Array<UInt8>, pos: Int64): Bool {
        if (pos <= 0) {
            return false
        }
        let byte = bytes[pos - 1]
        match (state.op) {
            case Op.Literal(c) => Int64(byte) == Int64(UInt32(c))
            case Op.CharacterClass(set) => set.contains(Rune(UInt32(byte)))
            case _ => false
        }
    }
    func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, pos: Int64, bytes: Array<UInt8>): Unit {
        let stack = ArrayList<Thread>()
        let slots = Array<Int64>()
        stack.add(Thread(state, pos, slots))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            let id = frame.state
            if (seen[id]) {
                continue
            }
            seen[id] = true
            let current = states[id]
            match (current.op) {
                case Op.Split =>
                    stack.add(Thread(current.second, pos, slots))
                    stack.add(Thread(current.first, pos, slots))
                case Op.Look(mode) =>
                    if (passesLookBytes(mode, pos, bytes, unicodeWords, asciiWords)) {
                        stack.add(Thread(current.first, pos, slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
}
