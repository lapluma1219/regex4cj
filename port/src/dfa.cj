package cjregex

import std.collection.*

// Byte powerset DFA. States are ordered NFA sets with leftmost-first cutoff:
// the first Accept drops every lower-priority state, including the unanchored
// skip. Unicode word boundaries fail at construction. The match end comes from
// this DFA. The match start is the reverse NFA on that prefix.
// Quit bytes, multiple patterns, and overlapping matches are not implemented.
class DfaRange {
    let start: Int64
    let end: Int64
    let target: Int64
    init(start: Int64, end: Int64, target: Int64) {
        this.start = start
        this.end = end
        this.target = target
    }
}

class Eps {
    let ids: Array<Int64>
    let accept: Bool
    init(ids: Array<Int64>, accept: Bool) {
        this.ids = ids
        this.accept = accept
    }
}

class PowState {
    let key: String
    let ids: Array<Int64>
    let absStart: Bool
    let lineStart: Bool
    let prevWord: Bool
    let accept: Bool
    var next: Array<Int64>
    var lookMatch: Array<Bool>
    var eoiMatch: Bool
    var sparseNext: ArrayList<DfaRange>
    var sparseLook: ArrayList<DfaRange>
    init(key: String, ids: Array<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool, accept: Bool) {
        this.key = key
        this.ids = ids
        this.absStart = absStart
        this.lineStart = lineStart
        this.prevWord = prevWord
        this.accept = accept
        next = Array<Int64>(256, repeat: -1)
        lookMatch = Array<Bool>(256, repeat: false)
        eoiMatch = false
        sparseNext = ArrayList<DfaRange>()
        sparseLook = ArrayList<DfaRange>()
    }
}

class ByteCompiler {
    let states = ArrayList<State>()
    func add(op: Op, first: Int64, second: Int64): Int64 {
        states.add(State(op, first, second))
        return states.size - 1
    }
    func split(first: Int64, second: Int64, greedy: Bool): Int64 {
        if (greedy) {
            return add(Op.Split, first, second)
        }
        return add(Op.Split, second, first)
    }
    func compile(expr: Expr, next: Int64): Int64 {
        match (expr.kind) {
            case ExprKind.Capture => compile(expr.children[0], next)
            case ExprKind.WordBoundary | ExprKind.Begin | ExprKind.End => add(
                Op.Look(AtomMode(expr.modeKind, expr.modeTerm, expr.modeUnicode, expr.modePositive)), next, -1)
            case ExprKind.Empty => next
            case ExprKind.Literal => compileLiteral(expr, next)
            case ExprKind.CharacterClass => compileClass(expr.charset, expr.byteAtom, next)
            case ExprKind.Any => compileClass(dotSet(expr), expr.byteAtom, next)
            case ExprKind.Concat =>
                var start = next
                var index = expr.children.size
                while (index > 0) {
                    index--
                    start = compile(expr.children[index], start)
                }
                start
            case ExprKind.Alternate =>
                if (expr.children.size == 0) {
                    next
                } else {
                    var index = expr.children.size - 1
                    var start = compile(expr.children[index], next)
                    while (index > 0) {
                        index--
                        start = split(compile(expr.children[index], next), start, true)
                    }
                    start
                }
            case ExprKind.Repeat => compileRepeat(expr, next)
        }
    }
    func compileRepeat(expr: Expr, next: Int64): Int64 {
        if (expr.maximum < 0) {
            let loop = add(Op.Split, -1, -1)
            let body = compile(expr.children[0], loop)
            states[loop].first = if (expr.greedy) {
                body
            } else {
                next
            }
            states[loop].second = if (expr.greedy) {
                next
            } else {
                body
            }
            if (expr.minimum == 0) {
                return split(body, next, expr.greedy)
            }
            var start = body
            var count: Int64 = 1
            while (count < expr.minimum) {
                start = compile(expr.children[0], start)
                count++
            }
            return start
        }
        var start = next
        var optional = expr.maximum - expr.minimum
        while (optional > 0) {
            start = split(compile(expr.children[0], start), next, expr.greedy)
            optional--
        }
        var required = expr.minimum
        while (required > 0) {
            start = compile(expr.children[0], start)
            required--
        }
        start
    }
    func compileLiteral(expr: Expr, next: Int64): Int64 {
        if (expr.byteAtom) {
            return byteLiteral(Int64(UInt32(expr.ch)), next)
        }
        let bytes = utf8Of(Int64(UInt32(expr.ch)))
        var start = next
        var index = bytes.size
        while (index > 0) {
            index--
            start = byteLiteral(Int64(bytes[index]), start)
        }
        start
    }
    func compileClass(set: CharSet, bytes: Bool, next: Int64): Int64 {
        if (bytes || !set.exceedsAscii()) {
            return byteClass(set, next)
        }
        let starts = ArrayList<Int64>()
        for (i in 0..set.rangeCount()) {
            let sequences = utf8Sequences(set.rangeLow(i), set.rangeHigh(i))
            for (seq in sequences) {
                starts.add(compileSequence(seq, next))
            }
        }
        if (starts.size == 0) {
            return byteSpan(1, 0, next)
        }
        var index = starts.size - 1
        var start = starts[index]
        while (index > 0) {
            index--
            start = split(starts[index], start, true)
        }
        start
    }
    func compileSequence(seq: ArrayList<ByteSpan>, next: Int64): Int64 {
        var start = next
        var index = seq.size
        while (index > 0) {
            index--
            let range = seq[index]
            start = byteSpan(range.start, range.end, start)
        }
        start
    }
    func byteLiteral(byte: Int64, next: Int64): Int64 {
        let id = add(Op.Literal(Rune(UInt32(byte))), next, -1)
        states[id].byteAtom = true
        id
    }
    func byteSpan(low: Int64, high: Int64, next: Int64): Int64 {
        let set = CharSet()
        if (low <= high) {
            set.addRange(low, high)
        }
        byteClass(set, next)
    }
    func byteClass(set: CharSet, next: Int64): Int64 {
        let id = add(Op.CharacterClass(set), next, -1)
        states[id].byteAtom = true
        id
    }
}

class DfaEngine {
    let pattern: String
    let nfa: Array<State>
    let term: Int64
    let asciiWords: CharSet
    let reverse: ReverseNfa
    let states: ArrayList<PowState>
    let buckets: Array<ArrayList<Int64>>
    let limit: Int64 = 8192
    var startState: Int64
    init(pattern: String) {
        this.pattern = pattern
        let options = PatternOptions()
        let parser = Parser(pattern, options)
        let tree = parser.parse()
        normalizeWidth(tree)
        ensureWithinSizeLimit([tree], options.sizeLimit, false)
        let compiler = ByteCompiler()
        let accept = compiler.add(Op.Accept, -1, -1)
        var entry = compiler.compile(tree, accept)
        if (!allAnchored([tree], false)) {
            let skip = compiler.add(Op.Split, -1, -1)
            let any = CharSet()
            any.addRange(0, 255)
            let loop = compiler.add(Op.CharacterClass(any), skip, -1)
            compiler.states[loop].byteAtom = true
            compiler.states[skip].first = entry
            compiler.states[skip].second = loop
            entry = skip
        }
        nfa = compiler.states.toArray()
        var termByte: Int64 = 10
        var needAscii = false
        for (state in nfa) {
            match (state.op) {
                case Op.Look(mode) =>
                    if (mode.kind >= 6 && mode.unicode) {
                        throw Exception("unsupported regex feature for DFAs: Unicode word boundary")
                    }
                    if (mode.kind == 4 || mode.kind == 5) {
                        throw Exception("unsupported regex feature for DFAs: CRLF anchor")
                    }
                    if (mode.kind >= 6) {
                        needAscii = true
                    }
                    termByte = Int64(UInt32(mode.term))
                case _ => ()
            }
        }
        term = termByte
        asciiWords = if (needAscii) {
            match (asciiClass("word")) {
                case Some(set) => set
                case None => throw Exception("missing ASCII word class")
            }
        } else {
            CharSet()
        }
        reverse = ReverseNfa(pattern)
        states = ArrayList<PowState>()
        buckets = Array<ArrayList<Int64>>(2048, {_ => ArrayList<Int64>()})
        startState = -1
        startState = intern(close(entry, true, true, false), true, true, false)
        var queue = 0
        while (queue < states.size) {
            fill(queue)
            queue++
        }
    }
    func stateCount(): Int64 {
        states.size
    }
    func search(text: String, sparse: Bool): Option<RegexMatch> {
        let bytes = text.toArray()
        var state = startState
        var at: Int64 = 0
        var last: Int64 = -1
        var running = true
        while (running) {
            let current = states[state]
            if (current.accept) {
                last = at
            }
            if (at == bytes.size) {
                if (current.eoiMatch) {
                    last = at
                }
                running = false
            } else {
                let byte = Int64(bytes[at])
                let hit = if (sparse) {
                    sparseHas(current.sparseLook, byte)
                } else {
                    current.lookMatch[byte]
                }
                let next = if (sparse) {
                    sparseTarget(current.sparseNext, byte)
                } else {
                    current.next[byte]
                }
                if (hit) {
                    last = at
                }
                if (next < 0) {
                    running = false
                } else {
                    state = next
                    at++
                }
            }
        }
        if (last < 0) {
            return None
        }
        if (last == 0) {
            return Some(RegexMatch(0, 0, ""))
        }
        let prefix = text[0..last]
        match (reverse.search(prefix)) {
            case Some(start) => Some(RegexMatch(start, last, text[start..last]))
            case None => throw Exception("reverse search missed a forward DFA match")
        }
    }
    func fill(id: Int64): Unit {
        let state = states[id]
        var byte: Int64 = 0
        while (byte < 256) {
            let active = activate(state, byte, false)
            state.lookMatch[byte] = active.accept
            state.next[byte] = destination(active, byte)
            byte++
        }
        state.eoiMatch = activate(state, 0, true).accept
        compress(state.lookMatch, state.sparseLook)
        compressNext(state.next, state.sparseNext)
    }
    func destination(active: Eps, byte: Int64): Int64 {
        let seeds = ArrayList<Int64>()
        var stopped = false
        for (id in active.ids) {
            if (stopped) {
                break
            }
            let state = nfa[id]
            var matched = false
            match (state.op) {
                case Op.Accept => stopped = true
                case Op.Literal(c) => matched = Int64(UInt32(c)) == byte
                case Op.CharacterClass(set) => matched = set.contains(Rune(UInt32(byte)))
                case _ => ()
            }
            if (matched) {
                seeds.add(state.first)
            }
        }
        if (seeds.size == 0) {
            return -1
        }
        let opened = closeSeeds(seeds, false, byte == term, wordByte(byte))
        return intern(opened, false, byte == term, wordByte(byte))
    }
    func activate(state: PowState, byte: Int64, eoi: Bool): Eps {
        let seeds = ArrayList<Int64>()
        for (id in state.ids) {
            let current = nfa[id]
            var queued = false
            match (current.op) {
                case Op.Look(mode) =>
                    if (needsNext(mode)) {
                        if (lookPasses(mode, state.prevWord, byte, eoi)) {
                            seeds.add(current.first)
                            queued = true
                        }
                    }
                case _ => ()
            }
            if (!queued) {
                match (current.op) {
                    case Op.Look(mode) =>
                        if (!needsNext(mode)) {
                            seeds.add(id)
                        }
                    case _ => seeds.add(id)
                }
            }
        }
        closeSeeds(seeds, state.absStart, state.lineStart, state.prevWord)
    }
    func close(entry: Int64, absStart: Bool, lineStart: Bool, prevWord: Bool): Eps {
        let seeds = ArrayList<Int64>()
        seeds.add(entry)
        closeSeeds(seeds, absStart, lineStart, prevWord)
    }
    func closeSeeds(seeds: ArrayList<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool): Eps {
        let stack = ArrayList<Int64>()
        var index = seeds.size
        while (index > 0) {
            index--
            stack.add(seeds[index])
        }
        let seen = Array<Bool>(nfa.size, repeat: false)
        let out = ArrayList<Int64>()
        var accept = false
        var stop = false
        while (!stack.isEmpty() && !stop) {
            let id = stack.remove(at: stack.size - 1)
            if (id < 0 || seen[id]) {
                continue
            }
            seen[id] = true
            let state = nfa[id]
            match (state.op) {
                case Op.Split =>
                    stack.add(state.second)
                    stack.add(state.first)
                case Op.Look(mode) =>
                    if (needsNext(mode)) {
                        out.add(id)
                    } else if (lookNow(mode, absStart, lineStart, prevWord)) {
                        stack.add(state.first)
                    }
                case Op.Accept =>
                    out.add(id)
                    accept = true
                    stop = true
                case Op.Save(_) => stack.add(state.first)
                case Op.Literal(_) | Op.CharacterClass(_) => out.add(id)
                case Op.Any(_) => out.add(id)
            }
        }
        Eps(out.toArray(), accept)
    }
    func needsNext(mode: AtomMode): Bool {
        mode.kind == 1 || mode.kind == 3 || mode.kind == 5 || mode.kind == 6 || mode.kind == 7 || mode.kind == 8 ||
            mode.kind == 10
    }
    func lookNow(mode: AtomMode, absStart: Bool, lineStart: Bool, prevWord: Bool): Bool {
        match (mode.kind) {
            case 0 => absStart
            case 2 => absStart || lineStart
            case 9 => !prevWord
            case _ => false
        }
    }
    func lookPasses(mode: AtomMode, prevWord: Bool, byte: Int64, eoi: Bool): Bool {
        let nextWord = !eoi && wordByte(byte)
        match (mode.kind) {
            case 1 => eoi
            case 3 => eoi || (!eoi && byte == term)
            case 6 => (prevWord != nextWord) == mode.positive
            case 7 => !prevWord && nextWord
            case 8 => prevWord && !nextWord
            case 10 => !nextWord
            case _ => false
        }
    }
    func wordByte(byte: Int64): Bool {
        asciiWords.contains(Rune(UInt32(byte)))
    }
    func intern(eps: Eps, absStart: Bool, lineStart: Bool, prevWord: Bool): Int64 {
        if (eps.ids.size == 0) {
            return -1
        }
        let key = stateKey(eps.ids, absStart, lineStart, prevWord)
        let slot = bucket(key)
        for (id in buckets[slot]) {
            if (states[id].key == key) {
                return id
            }
        }
        if (states.size >= limit) {
            throw Exception("Compiled DFA exceeds size limit of ${limit} states.")
        }
        let id = states.size
        states.add(PowState(key, eps.ids, absStart, lineStart, prevWord, eps.accept))
        buckets[slot].add(id)
        id
    }
    func stateKey(ids: Array<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool): String {
        let text = StringBuilder()
        for (id in ids) {
            text.append(id.toString())
            text.append(",")
        }
        text.append(if (absStart) {
            "A"
        } else {
            "a"
        })
        text.append(if (lineStart) {
            "L"
        } else {
            "l"
        })
        text.append(if (prevWord) {
            "W"
        } else {
            "w"
        })
        text.toString()
    }
    func bucket(key: String): Int64 {
        var hash: Int64 = 0
        for (byte in key.toArray()) {
            hash = hash ^ Int64(byte)
            hash = ((hash & 0x7FFFFFFF) + Int64(byte)) & 0x7FFFFFFF
        }
        hash % buckets.size
    }
    func compress(flags: Array<Bool>, out: ArrayList<DfaRange>): Unit {
        var byte: Int64 = 0
        while (byte < 256) {
            if (flags[byte]) {
                var end = byte
                while (end + 1 < 256 && flags[end + 1]) {
                    end++
                }
                out.add(DfaRange(byte, end, 1))
                byte = end + 1
            } else {
                byte++
            }
        }
    }
    func compressNext(next: Array<Int64>, out: ArrayList<DfaRange>): Unit {
        var byte: Int64 = 0
        while (byte < 256) {
            let target = next[byte]
            var end = byte
            while (end + 1 < 256 && next[end + 1] == target) {
                end++
            }
            if (target >= 0) {
                out.add(DfaRange(byte, end, target))
            }
            byte = end + 1
        }
    }
    func sparseHas(ranges: ArrayList<DfaRange>, byte: Int64): Bool {
        for (range in ranges) {
            if (byte >= range.start && byte <= range.end) {
                return true
            }
        }
        false
    }
    func sparseTarget(ranges: ArrayList<DfaRange>, byte: Int64): Int64 {
        for (range in ranges) {
            if (byte >= range.start && byte <= range.end) {
                return range.target
            }
        }
        -1
    }
}

public class DenseDfa {
    let engine: DfaEngine
    public init(pattern: String) {
        engine = DfaEngine(pattern)
    }
    public func stateCount(): Int64 {
        engine.stateCount()
    }
    public func search(text: String): Option<RegexMatch> {
        engine.search(text, false)
    }
}

public class SparseDfa {
    let engine: DfaEngine
    public init(pattern: String) {
        engine = DfaEngine(pattern)
    }
    public func stateCount(): Int64 {
        engine.stateCount()
    }
    public func search(text: String): Option<RegexMatch> {
        engine.search(text, true)
    }
}
