package cjregex

import std.collection.*

// Bounded backtracking over the Thompson NFA. A visited bit records each
// (state, byte offset) pair so a failing path is not explored twice.
// The bit table is sized from the haystack. If it cannot cover every state at
// every byte boundary, search throws. That is not a failed match.
// Default capacity is 256 KiB, matching regex-automata's BoundedBacktracker.
enum BackFrame {
    Step(Int64, Int64) | Restore(Int64, Int64)
}

public class BoundedBacktracker {
    let states: Array<State>
    let startState: Int64
    let unicodeWords: CharSet
    let asciiWords: CharSet
    let groupNames: Array<String>
    let staticLen: Int64
    let patternStarts: Array<Int64>
    let patternNames: Array<Array<String>>
    let staticLens: Array<Int64>
    let slotWidth: Int64
    let visitedCapacity: Int64
    let whichCaptures: Int64
    let sourceExprs: Array<Expr>
    let sourceNames: Array<Array<String>>
    let sourceLens: Array<Int64>
    var byteEngine: Option<ByteEngine> = None<ByteEngine>
    let workspace: BacktrackCache
    var matchedPattern: Int64
    var matchedFrom: Int64
    var matchedTo: Int64
    var sawMatch: Bool
    public init(pattern: String) {
        this(pattern, 256 * 1024)
    }
    public init(pattern: String, visitedCapacity: Int64) {
        this(pattern, visitedCapacity, 0)
    }
    public init(pattern: String, visitedCapacity: Int64, whichCaptures: Int64) {
        if (visitedCapacity < 0) {
            throw Exception("visited capacity must be nonnegative")
        }
        this.visitedCapacity = visitedCapacity
        this.whichCaptures = whichCaptures
        let options = PatternOptions()
        let parser = Parser(pattern, options)
        let tree = parser.parse()
        normalizeWidth(tree)
        ensureWithinSizeLimit([tree], options.sizeLimit, true)
        staticLen = match (staticExplicit(tree)) {
            case Some(count) => count + 1
            case None => -1
        }
        let compiler = Compiler(options.sizeLimit, whichCaptures)
        let accept = compiler.add(Op.Accept, -1, -1)
        startState = compiler.compile(tree, accept)
        states = compiler.states.toArray()
        let live = Array<Bool>(parser.captureNames.size, repeat: false)
        if (whichCaptures != 2 && live.size > 0) {
            live[0] = true
        }
        var last: Int64 = 0
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
                case Op.Save(slot) =>
                    let index = slot / 2
                    live[index] = true
                    if (index > last) {
                        last = index
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
        groupNames = if (whichCaptures == 2) {
            Array<String>()
        } else if (whichCaptures == 1) {
            Array<String>(1, {_ => ""})
        } else {
            Array<String>(last + 1, {
                i => if (i < live.size && live[i]) {
                    parser.captureNames[i]
                } else {
                    ""
                }
            })
        }
        patternStarts = [startState]
        patternNames = [groupNames]
        staticLens = [staticLen]
        sourceExprs = [tree]
        sourceNames = [groupNames]
        sourceLens = [staticLen]
        byteEngine = None<ByteEngine>
        slotWidth = groupNames.size * 2
        workspace = BacktrackCache()
        matchedPattern = 0
        matchedFrom = 0
        matchedTo = 0
        sawMatch = false
    }
    public init(patterns: Array<String>) {
        this(patterns, 256 * 1024)
    }
    public init(patterns: Array<String>, visitedCapacity: Int64) {
        this(patterns, visitedCapacity, 0)
    }
    public init(patterns: Array<String>, visitedCapacity: Int64, whichCaptures: Int64) {
        if (visitedCapacity < 0) {
            throw Exception("visited capacity must be nonnegative")
        }
        this.visitedCapacity = visitedCapacity
        this.whichCaptures = whichCaptures
        let graph = ThompsonNfa(patterns, whichCaptures)
        states = graph.rawStates()
        startState = graph.rawUnion()
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
        patternStarts = Array<Int64>(patterns.size, {i => graph.rawPatternStart(i)})
        patternNames = Array<Array<String>>(patterns.size, {i => graph.rawNames(i)})
        staticLens = Array<Int64>(patterns.size, {i => graph.rawStatic(i)})
        groupNames = if (patterns.size == 0) {
            Array<String>(1, {_ => ""})
        } else {
            patternNames[0]
        }
        staticLen = if (patterns.size == 0) {
            -1
        } else {
            staticLens[0]
        }
        slotWidth = graph.rawSlotCount()
        sourceExprs = graph.expressionList()
        sourceNames = graph.nameList()
        sourceLens = graph.lengthList()
        byteEngine = None<ByteEngine>
        workspace = BacktrackCache()
        matchedPattern = 0
        matchedFrom = 0
        matchedTo = 0
        sawMatch = false
    }
    public func stateCount(): Int64 {
        states.size
    }
    public func memoryUsage(): Int64 {
        var total = states.size * 32 + visitedCapacity
        for (state in states) {
            match (state.op) {
                case Op.CharacterClass(set) => total += set.rangeCount() * 16
                case _ => ()
            }
        }
        total
    }
    // Same formula as BoundedBacktracker::max_haystack_len. The bit capacity
    // is rounded up to 64-bit blocks. The count is this NFA's state count.
    public func maxHaystackLen(): Int64 {
        let bitsAvailable = bitCapacity()
        let blocks = if (bitsAvailable <= 0) {
            0
        } else {
            (bitsAvailable + 63) / 64
        }
        let real = blocks * 64
        if (states.size <= 0 || real < states.size) {
            return 0
        }
        return real / states.size - 1
    }
    public func createCache(): BacktrackCache {
        BacktrackCache()
    }
    public func searchAll(text: String): Array<PikeMatch> {
        searchAll(SearchInput(text))
    }
    // Non-overlapping matches inside the input span. An anchored input reports
    // at most one match. An empty match is reported once, then the next search
    // starts one byte later, matching regex-automata's Searcher.
    public func searchAll(input: SearchInput): Array<PikeMatch> {
        let found = ArrayList<PikeMatch>()
        let cache = createCache()
        if (input.anchor != 0) {
            match (search(cache, input)) {
                case Some(hit) => found.add(hit)
                case None => ()
            }
            return found.toArray()
        }
        var start = input.start
        var lastEnd: Int64 = -1
        var reading = true
        while (reading && start <= input.end) {
            match (search(cache, input.span(start, input.end))) {
                case None => reading = false
                case Some(hit) =>
                    var report = hit
                    var emit = true
                    let emptyHit = hit.start() == hit.end()
                    let repeatedEnd = hit.end() == lastEnd
                    if (emptyHit && repeatedEnd) {
                        let next = hit.end() + 1
                        if (next > input.end) {
                            reading = false
                            emit = false
                        } else {
                            match (search(cache, input.span(next, input.end))) {
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
    public func search(text: String): Option<Captures> {
        match (search(workspace, SearchInput(text))) {
            case Some(hit) => Some(hit.captures)
            case None => None
        }
    }
    public func isMatch(input: SearchInput): Bool {
        match (search(workspace, input)) {
            case Some(_) => true
            case None => sawMatch
        }
    }
    func ensureBytes(): ByteEngine {
        match (byteEngine) {
            case Some(engine) => return engine
            case None => ()
        }
        let engine = ByteEngine(sourceExprs, sourceNames, sourceLens, whichCaptures)
        byteEngine = Some(engine)
        engine
    }
    func ensureFits(stateCount: Int64, byteLen: Int64): Unit {
        if (byteLen < 0) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let nextStride = byteLen + 1
        if (stateCount > 0 && nextStride > 1152921504606846975 / stateCount) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let needed = stateCount * nextStride
        if (needed > bitCapacity()) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
    }
    public func search(cache: BacktrackCache, input: SearchInput): Option<PikeMatch> {
        sawMatch = false
        if (!input.utf8) {
            let engine = ensureBytes()
            ensureFits(engine.stateCount(), input.bytes.size)
            if (whichCaptures == 2) {
                sawMatch = engine.isMatch(input)
                return None
            }
            match (engine.search(input)) {
                case Some(hit) =>
                    sawMatch = true
                    return Some(hit)
                case None => return None
            }
        }
        if (startState < 0) {
            return None
        }
        var entry = startState
        var anchored = input.anchor != 0
        if (input.anchor == 2) {
            if (input.pattern < 0 || input.pattern >= patternStarts.size) {
                return None
            }
            entry = patternStarts[input.pattern]
        }
        let decoded = Input(input.text)
        let byteLen = decoded.offsets[decoded.offsets.size - 1]
        resetVisited(cache, byteLen)
        let from = decoded.boundary(input.start)
        var until = decoded.boundary(input.end)
        if (decoded.offsets[until] != input.end) {
            until--
        }
        if (from > until || (anchored && decoded.offsets[from] != input.start)) {
            return None
        }
        let slots = Array<Int64>(slotWidth, repeat: -1)
        var origin = from
        let stop = if (anchored) {
            from
        } else {
            until
        }
        while (origin <= stop && origin <= until) {
            if (step(cache, decoded, origin, slots, entry, until)) {
                sawMatch = true
                if (whichCaptures == 2) {
                    return None
                }
                return Some(PikeMatch(matchedPattern, captureResult(input.text, decoded, slots)))
            }
            if (anchored) {
                break
            }
            origin++
        }
        None
    }
    private func bitCapacity(): Int64 {
        if (visitedCapacity > 1152921504606846975) {
            throw Exception("visited capacity is too large")
        }
        return visitedCapacity * 8
    }
    private func resetVisited(cache: BacktrackCache, byteLen: Int64): Unit {
        if (byteLen < 0) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let nextStride = byteLen + 1
        if (states.size > 0 && nextStride > 1152921504606846975 / states.size) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let needed = states.size * nextStride
        if (needed > bitCapacity()) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let blocks = if (needed <= 0) {
            0
        } else {
            (needed + 63) / 64
        }
        if (cache.bits.size < blocks) {
            cache.bits = Array<UInt64>(blocks, repeat: UInt64(0))
        } else {
            var index: Int64 = 0
            while (index < blocks) {
                cache.bits[index] = UInt64(0)
                index++
            }
        }
        cache.stride = nextStride
    }
    private func markVisited(cache: BacktrackCache, sid: Int64, byteAt: Int64): Bool {
        let index = sid * cache.stride + byteAt
        let block = index / 64
        let mask = UInt64(1) << UInt64(index % 64)
        if ((cache.bits[block] & mask) != UInt64(0)) {
            return false
        }
        cache.bits[block] = cache.bits[block] | mask
        return true
    }
    private func step(cache: BacktrackCache, input: Input, origin: Int64, slots: Array<Int64>, entry: Int64,
        until: Int64): Bool {
        let stack = ArrayList<BackFrame>()
        stack.add(BackFrame.Step(entry, origin))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            match (frame) {
                case BackFrame.Restore(slot, old) => slots[slot] = old
                case BackFrame.Step(sid0, at0) =>
                    if (walk(cache, stack, input, sid0, at0, origin, slots, until)) {
                        return true
                    }
            }
        }
        return false
    }
    private func walk(cache: BacktrackCache, stack: ArrayList<BackFrame>, input: Input, sid0: Int64, at0: Int64,
        origin: Int64, slots: Array<Int64>, until: Int64): Bool {
        var sid = sid0
        var at = at0
        var walking = true
        while (walking) {
            if (!markVisited(cache, sid, input.offsets[at])) {
                walking = false
            } else {
                let state = states[sid]
                match (state.op) {
                    case Op.Accept =>
                        matchedPattern = state.patternId
                        matchedFrom = origin
                        matchedTo = at
                        return true
                    case Op.Split =>
                        stack.add(BackFrame.Step(state.second, at))
                        sid = state.first
                    case Op.Save(slot) =>
                        stack.add(BackFrame.Restore(slot, slots[slot]))
                        slots[slot] = at
                        sid = state.first
                    case Op.Look(mode) =>
                        if (passesLook(mode, at, input.chars, unicodeWords, asciiWords)) {
                            sid = state.first
                        } else {
                            walking = false
                        }
                    case Op.Literal(c) =>
                        if (at < until && at < input.chars.size && input.chars[at] == c) {
                            sid = state.first
                            at++
                        } else {
                            walking = false
                        }
                    case Op.CharacterClass(set) =>
                        if ((if (at < until && at < input.chars.size) {
                            set.contains(input.chars[at])
                        } else {
                            false
                        })) {
                            sid = state.first
                            at++
                        } else {
                            walking = false
                        }
                    case Op.Any(mode) =>
                        if (at < until && at < input.chars.size && passesDot(mode, input.chars[at])) {
                            sid = state.first
                            at++
                        } else {
                            walking = false
                        }
                }
            }
        }
        return false
    }
    private func captureResult(text: String, input: Input, slots: Array<Int64>): Captures {
        let names = if (matchedPattern >= 0 && matchedPattern < patternNames.size) {
            patternNames[matchedPattern]
        } else {
            groupNames
        }
        let groups = Array<Option<RegexMatch>>(names.size, repeat: None)
        let start = input.offsets[matchedFrom]
        let end = input.offsets[matchedTo]
        groups[0] = Some(RegexMatch(start, end, text[start..end]))
        for (i in 1..names.size) {
            let a = slots[i * 2]
            let b = slots[i * 2 + 1]
            if (a >= 0 && b >= 0) {
                let left = input.offsets[a]
                let right = input.offsets[b]
                groups[i] = Some(RegexMatch(left, right, text[left..right]))
            }
        }
        let frozen = if (matchedPattern >= 0 && matchedPattern < staticLens.size) {
            staticLens[matchedPattern]
        } else {
            staticLen
        }
        return Captures(groups, names, frozen)
    }
}

public class BacktrackCache {
    var bits: Array<UInt64>
    var stride: Int64
    public init() {
        bits = Array<UInt64>(0, repeat: UInt64(0))
        stride = 0
    }
}
