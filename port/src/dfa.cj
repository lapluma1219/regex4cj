package regex4cj

import std.collection.*

// Byte powerset DFA. States are ordered NFA sets with leftmost-first cutoff:
// the first Accept drops every lower-priority state, including the unanchored
// skip. Several patterns share that graph, and the winning Accept records its
// pattern id. Unicode word boundaries fail at construction. CRLF anchors are
// part of the state key. The match end comes from this DFA. The match start is
// the reverse NFA of the winning pattern. A sparse engine drops the dense byte
// tables after the ranges are built. MatchKind::All keeps every accepting
// pattern and reports overlapping half-matches (pattern id and end offset).
// Anchored::Pattern stays rejected unless pattern starts were requested.
// The state cap is a local count, not upstream's byte budget.
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
    let pattern: Int64
    let patterns: Array<Int64>
    init(ids: Array<Int64>, accept: Bool, pattern: Int64, patterns: Array<Int64>) {
        this.ids = ids
        this.accept = accept
        this.pattern = pattern
        this.patterns = patterns
    }
}

class PowState {
    let key: String
    let ids: Array<Int64>
    let absStart: Bool
    let lineStart: Bool
    let prevWord: Bool
    let prevCr: Bool
    let prevLf: Bool
    let accept: Bool
    let acceptPattern: Int64
    var next: Array<Int64>
    var lookPattern: Array<Int64>
    var eoiMatch: Bool
    var eoiPattern: Int64
    var eoiReady: Bool
    var sparseNext: ArrayList<DfaRange>
    var sparseLook: ArrayList<DfaRange>
    init(key: String, ids: Array<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool, prevCr: Bool, prevLf: Bool,
        accept: Bool, acceptPattern: Int64) {
        this.key = key
        this.ids = ids
        this.absStart = absStart
        this.lineStart = lineStart
        this.prevWord = prevWord
        this.prevCr = prevCr
        this.prevLf = prevLf
        this.accept = accept
        this.acceptPattern = acceptPattern
        next = Array<Int64>(256, repeat: -1)
        lookPattern = Array<Int64>(256, repeat: -1)
        eoiMatch = false
        eoiPattern = -1
        eoiReady = false
        sparseNext = ArrayList<DfaRange>()
        sparseLook = ArrayList<DfaRange>()
    }
}

// Byte Thompson compiler shared by the forward DFA and the reverse NFA.
// backward writes concatenation and UTF-8 bytes so the start state is the
// last byte. It does not reverse a finished scalar ThompsonNfa: Pike still
// walks scalars, and match-start recovery needs this byte graph.
class ByteCompiler {
    let states = ArrayList<State>()
    let backward: Bool
    let whichCaptures: Int64
    init() {
        backward = false
        whichCaptures = 2
    }
    init(backward: Bool) {
        this.backward = backward
        whichCaptures = 2
    }
    init(backward: Bool, whichCaptures: Int64) {
        this.backward = backward
        this.whichCaptures = whichCaptures
    }
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
            case ExprKind.Capture =>
                if (whichCaptures == 2 || (whichCaptures == 1 && expr.captureIndex != 0)) {
                    compile(expr.children[0], next)
                } else {
                    let end = add(Op.Save(expr.captureIndex * 2 + 1), next, -1)
                    let body = compile(expr.children[0], end)
                    add(Op.Save(expr.captureIndex * 2), body, -1)
                }
            case ExprKind.WordBoundary | ExprKind.Begin | ExprKind.End => add(
                Op.Look(AtomMode(expr.modeKind, expr.modeTerm, expr.modeUnicode, expr.modePositive)), next, -1)
            case ExprKind.Empty => next
            case ExprKind.Literal => compileLiteral(expr, next)
            case ExprKind.CharacterClass => compileClass(expr.charset, expr.byteAtom, next)
            case ExprKind.Any => compileClass(dotSet(expr), expr.byteAtom, next)
            case ExprKind.Concat =>
                if (backward) {
                    var start = next
                    for (child in expr.children) {
                        start = compile(child, start)
                    }
                    start
                } else {
                    var start = next
                    var index = expr.children.size
                    while (index > 0) {
                        index--
                        start = compile(expr.children[index], start)
                    }
                    start
                }
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
        if (backward) {
            var start = next
            for (byte in bytes) {
                start = byteLiteral(Int64(byte), start)
            }
            return start
        }
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
        if (backward) {
            var end = next
            for (range in seq) {
                end = byteSpan(range.start, range.end, end)
            }
            return end
        }
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
    let nfa: Array<State>
    let term: Int64
    let asciiWords: CharSet
    let reverses: Array<ReverseNfa>
    var states: ArrayList<PowState>
    var buckets: Array<ArrayList<Int64>>
    let lazy: Bool
    let cacheLimit: Int64
    let clearLimit: Int64
    var clearCount: Int64
    var lazyAt: Int64
    var restarting: Bool
    let limit: Int64 = 8192
    let byteLimit: Int64
    let retainDense: Bool
    let bodyEntry: Int64
    let openEntry: Int64
    let patternEntries: Array<Int64>
    let patternStartsEnabled: Bool
    let sourcePatterns: Array<String>
    let quit: Array<Bool>
    let matchAll: Bool
    var startState: Int64
    init(pattern: String) {
        this([pattern], true, Array<UInt8>())
    }
    init(pattern: String, retainDense: Bool) {
        this([pattern], retainDense, Array<UInt8>())
    }
    init(pattern: String, retainDense: Bool, quitBytes: Array<UInt8>) {
        this([pattern], retainDense, quitBytes)
    }
    init(patterns: Array<String>, retainDense: Bool, quitBytes: Array<UInt8>) {
        this(patterns, retainDense, quitBytes, false)
    }
    init(patterns: Array<String>, retainDense: Bool, quitBytes: Array<UInt8>, matchAll: Bool) {
        this(patterns, retainDense, quitBytes, matchAll, false, 8192, -1)
    }
    init(patterns: Array<String>, retainDense: Bool, quitBytes: Array<UInt8>, matchAll: Bool, lazy: Bool,
        cacheLimit: Int64, clearLimit: Int64) {
        this(patterns, retainDense, quitBytes, matchAll, lazy, cacheLimit, clearLimit, false)
    }
    init(patterns: Array<String>, retainDense: Bool, quitBytes: Array<UInt8>, matchAll: Bool, lazy: Bool,
        cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool) {
        this(patterns, retainDense, quitBytes, matchAll, lazy, cacheLimit, clearLimit, patternStarts, -1)
    }
    init(patterns: Array<String>, retainDense: Bool, quitBytes: Array<UInt8>, matchAll: Bool, lazy: Bool,
        cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool, byteLimit: Int64) {
        if (patterns.size == 0) {
            throw Exception("no patterns")
        }
        sourcePatterns = Array<String>(patterns.size, {i => patterns[i]})
        this.byteLimit = byteLimit
        this.retainDense = retainDense
        this.matchAll = matchAll
        this.lazy = lazy
        this.cacheLimit = cacheLimit
        this.clearLimit = clearLimit
        clearCount = 0
        lazyAt = 0
        restarting = false
        let options = PatternOptions()
        let trees = ArrayList<Expr>()
        for (pattern in patterns) {
            let parser = Parser(pattern, options)
            let tree = parser.parse()
            normalizeWidth(tree)
            trees.add(tree)
        }
        let parsed = trees.toArray()
        ensureWithinSizeLimit(parsed, options.sizeLimit, false)
        let compiler = ByteCompiler()
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
        var entry = union
        if (!allAnchored(parsed, false)) {
            let skip = compiler.add(Op.Split, -1, -1)
            let any = CharSet()
            any.addRange(0, 255)
            let loop = compiler.add(Op.CharacterClass(any), skip, -1)
            compiler.states[loop].byteAtom = true
            compiler.states[skip].first = union
            compiler.states[skip].second = loop
            entry = skip
        }
        bodyEntry = union
        openEntry = entry
        patternEntries = starts.toArray()
        patternStartsEnabled = patternStarts
        let flags = Array<Bool>(256, repeat: false)
        for (byte in quitBytes) {
            flags[Int64(byte)] = true
        }
        quit = flags
        nfa = compiler.states.toArray()
        var termByte: Int64 = 10
        var needAscii = false
        for (state in nfa) {
            match (state.op) {
                case Op.Look(mode) =>
                    if (mode.kind >= 6 && mode.unicode) {
                        if (lazy) {
                            throw Exception(
                                "unsupported regex feature for DFAs: cannot build lazy DFAs for regexes with Unicode word boundaries; switch to ASCII word boundaries, or heuristically enable Unicode word boundaries or use a different regex engine")
                        }
                        throw Exception("unsupported regex feature for DFAs: Unicode word boundary")
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
        let built = ArrayList<ReverseNfa>()
        for (pattern in patterns) {
            built.add(ReverseNfa(pattern))
        }
        reverses = built.toArray()
        states = ArrayList<PowState>()
        buckets = Array<ArrayList<Int64>>(2048, {_ => ArrayList<Int64>()})
        startState = -1
        startState = seedAll()
        if (lazy && states.size > cacheLimit) {
            throw Exception("given cache capacity (${cacheLimit}) is smaller than minimum required (${states.size})")
        }
        if (!lazy) {
            var queue = 0
            while (queue < states.size) {
                fill(queue)
                queue++
            }
        }
        if (!lazy && !retainDense) {
            for (state in states) {
                state.next = Array<Int64>(0, repeat: -1)
                state.lookPattern = Array<Int64>(0, repeat: -1)
            }
        }
    }
    func retainsDenseTable(): Bool {
        if (states.size == 0) {
            return retainDense
        }
        states[0].next.size == 256
    }
    func stateCount(): Int64 {
        states.size
    }
    func memoryUsage(): Int64 {
        var total = states.size * 32
        for (state in states) {
            total += state.next.size * 4
            total += state.sparseNext.size * 8
            total += state.ids.size * 8
        }
        total
    }
    func patternCount(): Int64 {
        sourcePatterns.size
    }
    func imagePatterns(): Array<String> {
        sourcePatterns
    }
    func seedAll(): Int64 {
        let seeded = seedEntry(openEntry)
        if (bodyEntry != openEntry) {
            seedEntry(bodyEntry)
        }
        if (patternStartsEnabled) {
            for (entry in patternEntries) {
                seedEntry(entry)
            }
        }
        seeded
    }
    func searchEntry(query: SearchInput): Int64 {
        if (query.anchor == 2) {
            if (!patternStartsEnabled) {
                throw Exception(
                    "anchored searches for a specific pattern (${query.pattern}) are not supported or enabled")
            }
            if (query.pattern < 0 || query.pattern >= patternEntries.size) {
                return -1
            }
            return patternEntries[query.pattern]
        }
        if (query.anchor != 0) {
            return bodyEntry
        }
        openEntry
    }
    func seedEntry(entry: Int64): Int64 {
        let primary = intern(close(entry, true, true, false, false, false), true, true, false, false, false)
        var line: Int64 = 0
        while (line < 2) {
            var word: Int64 = 0
            while (word < 2) {
                let lineStart = line == 1
                let prevWord = word == 1
                intern(close(entry, false, lineStart, prevWord, false, false), false, lineStart, prevWord, false, false)
                intern(close(entry, false, lineStart, prevWord, true, false), false, lineStart, prevWord, true, false)
                intern(close(entry, false, lineStart, prevWord, false, true), false, lineStart, prevWord, false, true)
                word++
            }
            line++
        }
        primary
    }
    func contextStart(entry: Int64, bytes: Array<UInt8>, at: Int64): Int64 {
        let absStart = at == 0
        let prev = if (at > 0) {
            Int64(bytes[at - 1])
        } else {
            0
        }
        let line = at == 0 || prev == term
        let word = at > 0 && wordByte(prev)
        let cr = at > 0 && prev == 13
        let lf = at > 0 && prev == 10
        intern(close(entry, absStart, line, word, cr, lf), absStart, line, word, cr, lf)
    }
    func search(text: String, sparse: Bool): Option<DfaMatch> {
        search(SearchInput(text), sparse)
    }
    func search(query: SearchInput, sparse: Bool): Option<DfaMatch> {
        if (!lazy) {
            return searchOnce(query, sparse)
        }
        var tries = 0
        while (tries < 8) {
            tries++
            restarting = false
            try {
                return searchOnce(query, false)
            } catch (e: Exception) {
                if (!restarting) {
                    throw e
                }
                rebuildLazy()
            }
        }
        throw Exception("gave up searching at offset ${lazyAt}")
    }
    func searchOnce(query: SearchInput, sparse: Bool): Option<DfaMatch> {
        if (matchAll) {
            throw Exception("leftmost search requires match kind LeftmostFirst")
        }
        let bytes = query.bytes
        let entry = searchEntry(query)
        if (entry < 0) {
            return None
        }
        var state = contextStart(entry, bytes, query.start)
        if (state < 0) {
            return None
        }
        var at = query.start
        lazyAt = at
        var last: Int64 = -1
        var lastPattern: Int64 = -1
        var running = true
        while (running) {
            let current = states[state]
            if (current.accept) {
                last = at
                lastPattern = current.acceptPattern
                if (query.earliest) {
                    running = false
                    continue
                }
            }
            lazyAt = at
            if (at == query.end) {
                if (query.end == bytes.size) {
                    if (lazy) {
                        ensureEoi(state)
                    }
                    if (states[state].eoiMatch) {
                        last = at
                        lastPattern = states[state].eoiPattern
                    }
                } else {
                    // A span end is not end-of-input. Assertions still inspect
                    // the following byte, without consuming outside the span.
                    let byte = Int64(bytes[at])
                    if (quit[byte]) {
                        throw Exception("quit search after observing byte ${debugByte(byte)} at offset ${at}")
                    }
                    let boundary = activate(current, byte, false)
                    if (boundary.accept) {
                        last = at
                        lastPattern = boundary.pattern
                    }
                }
                running = false
            } else {
                let byte = Int64(bytes[at])
                if (quit[byte]) {
                    throw Exception("quit search after observing byte ${debugByte(byte)} at offset ${at}")
                }
                if (lazy) {
                    ensure(state, byte)
                }
                let seen = if (lazy) {
                    states[state].lookPattern[byte]
                } else if (sparse) {
                    sparseTarget(current.sparseLook, byte)
                } else {
                    current.lookPattern[byte]
                }
                let next = if (lazy) {
                    states[state].next[byte]
                } else if (sparse) {
                    sparseTarget(current.sparseNext, byte)
                } else {
                    current.next[byte]
                }
                if (seen >= 0) {
                    last = at
                    lastPattern = seen
                    if (query.earliest) {
                        running = false
                        continue
                    }
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
        if (query.anchor != 0 || last == query.start) {
            return Some(DfaMatch(lastPattern, query.start, last, matchedText(query, query.start, last)))
        }
        match (reverses[lastPattern].searchEndingAt(bytes, last, query.start)) {
            case Some(start) => Some(DfaMatch(lastPattern, start, last, matchedText(query, start, last)))
            case None => throw Exception("reverse search missed a forward DFA match")
        }
    }
    func ensure(id: Int64, byte: Int64): Unit {
        let current = states[id]
        if (current.next[byte] != -2) {
            return
        }
        let active = activate(current, byte, false)
        current.lookPattern[byte] = if (active.accept) {
            active.pattern
        } else {
            -1
        }
        current.next[byte] = destination(active, byte)
    }
    func ensureEoi(id: Int64): Unit {
        let current = states[id]
        if (current.eoiReady) {
            return
        }
        let ending = activate(current, 0, true)
        current.eoiMatch = ending.accept
        current.eoiPattern = if (ending.accept) {
            ending.pattern
        } else {
            -1
        }
        current.eoiReady = true
    }
    func resetLazy(): Unit {
        clearCount = 0
        rebuildLazy()
    }
    func rebuildLazy(): Unit {
        states = ArrayList<PowState>()
        buckets = Array<ArrayList<Int64>>(2048, {_ => ArrayList<Int64>()})
        restarting = false
        startState = -1
        startState = seedAll()
    }
    func searchOverlapping(query: SearchInput, sparse: Bool): Array<DfaHalf> {
        if (!lazy) {
            return overlapOnce(query, sparse)
        }
        var tries: Int64 = 0
        while (tries < 8) {
            tries++
            restarting = false
            try {
                return overlapOnce(query, false)
            } catch (e: Exception) {
                if (!restarting) {
                    throw e
                }
                rebuildLazy()
            }
        }
        throw Exception("gave up searching at offset ${lazyAt}")
    }
    func overlapOnce(query: SearchInput, sparse: Bool): Array<DfaHalf> {
        if (!matchAll) {
            throw Exception("overlapping search requires match kind All")
        }
        let bytes = query.bytes
        let entry = searchEntry(query)
        var state = if (entry < 0) {
            -1
        } else {
            contextStart(entry, bytes, query.start)
        }
        let found = ArrayList<DfaHalf>()
        if (state < 0) {
            return found.toArray()
        }
        var at = query.start
        var reading = true
        while (reading && at < query.end) {
            let current = states[state]
            let byte = Int64(bytes[at])
            if (quit[byte]) {
                throw Exception("quit search after observing byte ${debugByte(byte)} at offset ${at}")
            }
            if (lazy) {
                lazyAt = at
                ensure(state, byte)
            }
            for (id in activate(current, byte, false).patterns) {
                found.add(DfaHalf(id, at))
            }
            let next = if (sparse) {
                sparseTarget(current.sparseNext, byte)
            } else {
                current.next[byte]
            }
            if (next < 0) {
                reading = false
            } else {
                state = next
                at++
            }
        }
        if (reading) {
            let current = states[state]
            if (query.end < bytes.size) {
                let byte = Int64(bytes[query.end])
                if (quit[byte]) {
                    throw Exception("quit search after observing byte ${debugByte(byte)} at offset ${query.end}")
                }
                for (id in activate(current, byte, false).patterns) {
                    found.add(DfaHalf(id, query.end))
                }
            } else {
                for (id in activate(current, 0, true).patterns) {
                    found.add(DfaHalf(id, query.end))
                }
            }
        }
        found.toArray()
    }
    func fill(id: Int64): Unit {
        let state = states[id]
        var byte: Int64 = 0
        while (byte < 256) {
            let active = activate(state, byte, false)
            state.lookPattern[byte] = if (active.accept) {
                active.pattern
            } else {
                -1
            }
            state.next[byte] = destination(active, byte)
            byte++
        }
        let ending = activate(state, 0, true)
        state.eoiMatch = ending.accept
        state.eoiPattern = if (ending.accept) {
            ending.pattern
        } else {
            -1
        }
        state.eoiReady = true
        compressLook(state.lookPattern, state.sparseLook)
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
                case Op.Accept =>
                    if (!matchAll) {
                        stopped = true
                    }
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
        let opened = closeSeeds(seeds, false, byte == term, wordByte(byte), byte == 13, byte == 10)
        return intern(opened, false, byte == term, wordByte(byte), byte == 13, byte == 10)
    }
    func activate(state: PowState, byte: Int64, eoi: Bool): Eps {
        let seeds = ArrayList<Int64>()
        for (id in state.ids) {
            seeds.add(id)
        }
        closeContext(seeds, state.absStart, state.lineStart, state.prevWord, state.prevCr, state.prevLf, true, byte, eoi)
    }
    func close(entry: Int64, absStart: Bool, lineStart: Bool, prevWord: Bool, prevCr: Bool, prevLf: Bool): Eps {
        let seeds = ArrayList<Int64>()
        seeds.add(entry)
        closeSeeds(seeds, absStart, lineStart, prevWord, prevCr, prevLf)
    }
    func closeSeeds(seeds: ArrayList<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool, prevCr: Bool, prevLf: Bool): Eps {
        closeContext(seeds, absStart, lineStart, prevWord, prevCr, prevLf, false, 0, false)
    }
    func closeContext(seeds: ArrayList<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool, prevCr: Bool,
        prevLf: Bool, resolve: Bool, byte: Int64, eoi: Bool): Eps {
        let stack = ArrayList<Int64>()
        var index = seeds.size
        while (index > 0) {
            index--
            stack.add(seeds[index])
        }
        let seen = Array<Bool>(nfa.size, repeat: false)
        let out = ArrayList<Int64>()
        let found = ArrayList<Int64>()
        var accept = false
        var pattern: Int64 = -1
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
                    if (mode.kind == 4 && !prevCr) {
                        if (absStart || prevLf) {
                            stack.add(state.first)
                        }
                    } else if (needsNext(mode) || mode.kind == 4) {
                        if (!resolve) {
                            out.add(id)
                        } else if (lookPasses(mode, prevWord, prevCr, byte, eoi)) {
                            stack.add(state.first)
                        }
                    } else if (lookNow(mode, absStart, lineStart, prevWord)) {
                        stack.add(state.first)
                    }
                case Op.Accept =>
                    out.add(id)
                    accept = true
                    if (pattern < 0) {
                        pattern = state.patternId
                    }
                    if (matchAll) {
                        found.add(state.patternId)
                    }
                    if (!matchAll) {
                        stop = true
                    }
                case Op.Save(_) => stack.add(state.first)
                case Op.Literal(_) | Op.CharacterClass(_) => out.add(id)
                case Op.Any(_) => out.add(id)
            }
        }
        let accepted = if (matchAll) {
            found.toArray()
        } else {
            Array<Int64>()
        }
        Eps(out.toArray(), accept, pattern, accepted)
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
    func lookPasses(mode: AtomMode, prevWord: Bool, prevCr: Bool, byte: Int64, eoi: Bool): Bool {
        let nextWord = !eoi && wordByte(byte)
        match (mode.kind) {
            case 1 => eoi
            case 3 => eoi || (!eoi && byte == term)
            case 4 => eoi || byte != 10
            case 5 => eoi || byte == 13 || (byte == 10 && !prevCr)
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
    func intern(eps: Eps, absStart: Bool, lineStart: Bool, prevWord: Bool, prevCr: Bool, prevLf: Bool): Int64 {
        if (eps.ids.size == 0) {
            return -1
        }
        let key = stateKey(eps.ids, absStart, lineStart, prevWord, prevCr, prevLf)
        let slot = bucket(key)
        for (id in buckets[slot]) {
            if (states[id].key == key) {
                return id
            }
        }
        if (lazy && startState >= 0 && states.size >= cacheLimit) {
            if (clearLimit >= 0 && clearCount >= clearLimit) {
                throw Exception("gave up searching at offset ${lazyAt}")
            }
            clearCount++
            restarting = true
            throw Exception("lazy dfa cache restart")
        }
        if (states.size >= limit) {
            throw Exception("Compiled DFA exceeds size limit of ${limit} states.")
        }
        if (byteLimit >= 0 && (states.size + 1) * 1024 > byteLimit) {
            throw Exception("DFA exceeded size limit of ${byteLimit} during determinization")
        }
        let id = states.size
        let created = PowState(key, eps.ids, absStart, lineStart, prevWord, prevCr, prevLf, eps.accept, eps.pattern)
        if (lazy) {
            created.next = Array<Int64>(256, repeat: -2)
        }
        states.add(created)
        buckets[slot].add(id)
        id
    }
    func stateKey(ids: Array<Int64>, absStart: Bool, lineStart: Bool, prevWord: Bool, prevCr: Bool, prevLf: Bool): String {
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
        text.append(if (prevCr) {
            "C"
        } else {
            "c"
        })
        text.append(if (prevLf) {
            "F"
        } else {
            "f"
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
    func compressLook(patterns: Array<Int64>, out: ArrayList<DfaRange>): Unit {
        var byte: Int64 = 0
        while (byte < 256) {
            let pattern = patterns[byte]
            if (pattern >= 0) {
                var end = byte
                while (end + 1 < 256 && patterns[end + 1] == pattern) {
                    end++
                }
                out.add(DfaRange(byte, end, pattern))
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
    func sparseTarget(ranges: ArrayList<DfaRange>, byte: Int64): Int64 {
        for (range in ranges) {
            if (byte >= range.start && byte <= range.end) {
                return range.target
            }
        }
        -1
    }
}

func matchedText(query: SearchInput, start: Int64, end: Int64): String {
    if (query.utf8) {
        return query.text[start..end]
    }
    let piece = Array<UInt8>(end - start, {i => query.bytes[start + i]})
    match (decodeUtf8(piece)) {
        case Some(text) => text
        case None =>
            let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
            let out = StringBuilder()
            for (byte in piece) {
                let value = Int64(byte)
                out.append("\\x${digits[value / 16]}${digits[value % 16]}")
            }
            out.toString()
    }
}

public class DfaHalf {
    public let pattern: Int64
    public let end: Int64
    public init(pattern: Int64, end: Int64) {
        this.pattern = pattern
        this.end = end
    }
}

public class DfaMatch {
    public let pattern: Int64
    public let start: Int64
    public let end: Int64
    public let text: String
    public init(pattern: Int64, start: Int64, end: Int64, text: String) {
        this.pattern = pattern
        this.start = start
        this.end = end
        this.text = text
    }
}

public class DenseDfa {
    let engine: DfaEngine
    public init(pattern: String) {
        engine = DfaEngine(pattern, true, Array<UInt8>())
    }
    public init(pattern: String, quit: Array<UInt8>) {
        engine = DfaEngine(pattern, true, quit)
    }
    public init(patterns: Array<String>) {
        engine = DfaEngine(patterns, true, Array<UInt8>())
    }
    public init(patterns: Array<String>, quit: Array<UInt8>) {
        engine = DfaEngine(patterns, true, quit)
    }
    public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool) {
        engine = DfaEngine(patterns, true, quit, matchAll)
    }
    public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool, patternStarts: Bool) {
        engine = DfaEngine(patterns, true, quit, matchAll, false, 8192, -1, patternStarts)
    }
    public init(patterns: Array<String>, byteLimit: Int64) {
        engine = DfaEngine(patterns, true, Array<UInt8>(), false, false, 8192, -1, false, byteLimit)
    }
    public static func overlap(patterns: Array<String>): DenseDfa {
        DenseDfa(patterns, Array<UInt8>(), true)
    }
    public func stateCount(): Int64 {
        engine.stateCount()
    }
    public func memoryUsage(): Int64 {
        engine.memoryUsage()
    }
    public func retainsDenseTable(): Bool {
        engine.retainsDenseTable()
    }
    public func search(text: String): Option<DfaMatch> {
        engine.search(text, false)
    }
    public func search(input: SearchInput): Option<DfaMatch> {
        engine.search(input, false)
    }
    public func searchOverlapping(text: String): Array<DfaHalf> {
        engine.searchOverlapping(SearchInput(text), false)
    }
    public func searchOverlapping(input: SearchInput): Array<DfaHalf> {
        engine.searchOverlapping(input, false)
    }
    // Image of the patterns this DFA was built from. Reloading recompiles the
    // same automaton and checks the state count. This is not regex-automata's
    // transition-table wire format; state numbers are local.
    public func toImage(): Array<UInt8> {
        // CJD1 has no configuration fields. Never silently discard them.
        if (engine.matchAll || engine.patternStartsEnabled) {
            throw Exception("DFA image supports default search configuration only")
        }
        for (enabled in engine.quit) {
            if (enabled) {
                throw Exception("DFA image supports default search configuration only")
            }
        }
        let out = ArrayList<UInt8>()
        out.add(UInt8(0x43))
        out.add(UInt8(0x4A))
        out.add(UInt8(0x44))
        out.add(UInt8(0x31))
        pushImageInt(out, engine.patternCount())
        pushImageInt(out, engine.stateCount())
        for (pattern in engine.imagePatterns()) {
            let bytes = pattern.toArray()
            pushImageInt(out, bytes.size)
            for (byte in bytes) {
                out.add(byte)
            }
        }
        out.toArray()
    }
    public static func fromImage(bytes: Array<UInt8>): DenseDfa {
        if (bytes.size < 12 || bytes[0] != UInt8(0x43) || bytes[1] != UInt8(0x4A) || bytes[2] != UInt8(0x44) ||
            bytes[3] != UInt8(0x31)) {
            throw Exception("invalid DFA serialization")
        }
        var at: Int64 = 4
        let count = readImageInt(bytes, at)
        at += 4
        let states = readImageInt(bytes, at)
        at += 4
        let patterns = ArrayList<String>()
        for (_ in 0..count) {
            let length = readImageInt(bytes, at)
            at += 4
            if (length < 0 || at + length > bytes.size) {
                throw Exception("invalid DFA serialization")
            }
            let origin = at
            let slice = Array<UInt8>(length, {i => bytes[origin + i]})
            match (decodeUtf8(slice)) {
                case Some(text) => patterns.add(text)
                case None => throw Exception("invalid DFA serialization")
            }
            at += length
        }
        if (at != bytes.size) {
            throw Exception("invalid DFA serialization")
        }
        let loaded = DenseDfa(patterns.toArray())
        if (loaded.stateCount() != states) {
            throw Exception("invalid DFA serialization")
        }
        loaded
    }
}

func pushImageInt(out: ArrayList<UInt8>, value: Int64): Unit {
    var rest = value
    for (_ in 0..4) {
        out.add(UInt8(rest % 256))
        rest = rest / 256
    }
}

func readImageInt(bytes: Array<UInt8>, at: Int64): Int64 {
    if (at < 0 || at + 4 > bytes.size) {
        throw Exception("invalid DFA serialization")
    }
    Int64(bytes[at]) + Int64(bytes[at + 1]) * 256 + Int64(bytes[at + 2]) * 65536 + Int64(bytes[at + 3]) * 16777216
}

public class SparseDfa {
    let engine: DfaEngine
    public init(pattern: String) {
        engine = DfaEngine(pattern, false, Array<UInt8>())
    }
    public init(pattern: String, quit: Array<UInt8>) {
        engine = DfaEngine(pattern, false, quit)
    }
    public init(patterns: Array<String>) {
        engine = DfaEngine(patterns, false, Array<UInt8>())
    }
    public init(patterns: Array<String>, quit: Array<UInt8>) {
        engine = DfaEngine(patterns, false, quit)
    }
    public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool) {
        engine = DfaEngine(patterns, false, quit, matchAll)
    }
    public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool, patternStarts: Bool) {
        engine = DfaEngine(patterns, false, quit, matchAll, false, 8192, -1, patternStarts)
    }
    public static func overlap(patterns: Array<String>): SparseDfa {
        SparseDfa(patterns, Array<UInt8>(), true)
    }
    public func stateCount(): Int64 {
        engine.stateCount()
    }
    public func memoryUsage(): Int64 {
        engine.memoryUsage()
    }
    public func retainsDenseTable(): Bool {
        engine.retainsDenseTable()
    }
    public func search(text: String): Option<DfaMatch> {
        engine.search(text, true)
    }
    public func search(input: SearchInput): Option<DfaMatch> {
        engine.search(input, true)
    }
    public func searchOverlapping(text: String): Array<DfaHalf> {
        engine.searchOverlapping(SearchInput(text), true)
    }
    public func searchOverlapping(input: SearchInput): Array<DfaHalf> {
        engine.searchOverlapping(input, true)
    }
}

public class HybridDfa {
    let engine: DfaEngine
    public init(pattern: String) {
        this([pattern], 8192, -1)
    }
    public init(pattern: String, quit: Array<UInt8>) {
        engine = DfaEngine([pattern], true, quit, false, true, 8192, -1)
    }
    public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64) {
        engine = DfaEngine(patterns, true, Array<UInt8>(), false, true, cacheLimit, clearLimit)
    }
    public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool) {
        engine = DfaEngine(patterns, true, Array<UInt8>(), false, true, cacheLimit, clearLimit, patternStarts)
    }
    public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool, matchAll: Bool) {
        engine = DfaEngine(patterns, true, Array<UInt8>(), matchAll, true, cacheLimit, clearLimit, patternStarts)
    }
    public static func overlap(patterns: Array<String>): HybridDfa {
        HybridDfa(patterns, 8192, -1, false, true)
    }
    public func stateCount(): Int64 {
        engine.stateCount()
    }
    public func memoryUsage(): Int64 {
        engine.memoryUsage()
    }
    public func reset(): Unit {
        engine.resetLazy()
    }
    public func search(text: String): Option<DfaMatch> {
        engine.search(text, false)
    }
    public func searchOverlapping(text: String): Array<DfaHalf> {
        engine.searchOverlapping(SearchInput(text), false)
    }
    public func search(input: SearchInput): Option<DfaMatch> {
        engine.search(input, false)
    }
}
