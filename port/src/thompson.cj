package cjregex

import std.collection.*

// One Thompson graph for every pattern. Each pattern keeps its own Accept, and
// the union start prefers the earlier pattern. State numbers are local to this
// graph. Search is the ordered Pike loop: the first Accept at a position cuts
// off lower-priority threads, then the surviving threads may still lengthen it.
class NfaHit {
    let pattern: Int64
    let start: Int64
    let end: Int64
    let slots: Array<Int64>
    init(pattern: Int64, start: Int64, end: Int64, slots: Array<Int64>) {
        this.pattern = pattern
        this.start = start
        this.end = end
        this.slots = slots
    }
}

class NfaParts {
    let states: Array<State>
    let unionStart: Int64
    let patternStarts: Array<Int64>
    let patternBegins: Array<Int64>
    let patternCounts: Array<Int64>
    let groupNames: Array<Array<String>>
    let staticLens: Array<Int64>
    let unicodeWords: CharSet
    let asciiWords: CharSet
    let slotCount: Int64
    let whichCaptures: Int64
    let exprs: Array<Expr>
    init(states: Array<State>, unionStart: Int64, patternStarts: Array<Int64>, patternBegins: Array<Int64>,
        patternCounts: Array<Int64>, groupNames: Array<Array<String>>, staticLens: Array<Int64>, unicodeWords: CharSet,
        asciiWords: CharSet, slotCount: Int64, whichCaptures: Int64, exprs: Array<Expr>) {
        this.states = states
        this.unionStart = unionStart
        this.patternStarts = patternStarts
        this.patternBegins = patternBegins
        this.patternCounts = patternCounts
        this.groupNames = groupNames
        this.staticLens = staticLens
        this.unicodeWords = unicodeWords
        this.asciiWords = asciiWords
        this.slotCount = slotCount
        this.whichCaptures = whichCaptures
        this.exprs = exprs
    }
}

func trimCaptureNames(raw: Array<String>, states: ArrayList<State>, keepTrailing: Bool, whichCaptures: Int64): Array<String> {
    if (whichCaptures == 2) {
        return Array<String>()
    }
    if (whichCaptures == 1) {
        return Array<String>(1, {_ => ""})
    }
    let live = Array<Bool>(raw.size, repeat: false)
    if (live.size > 0) {
        live[0] = true
    }
    var last: Int64 = 0
    for (state in states) {
        match (state.op) {
            case Op.Save(slot) =>
                let index = slot / 2
                if (index >= 0 && index < live.size) {
                    live[index] = true
                }
                if (index > last) {
                    last = index
                }
            case _ => ()
        }
    }
    var width = last + 1
    if (keepTrailing && raw.size > width) {
        width = raw.size
    }
    Array<String>(width, {
        i => if (i < live.size && live[i] && i < raw.size) {
            raw[i]
        } else {
            ""
        }
    })
}

func compilePattern(tree: Expr, raw: Array<String>, keepTrailing: Bool, pattern: Int64, sizeLimit: Int64,
    whichCaptures: Int64, all: ArrayList<State>, starts: ArrayList<Int64>, begins: ArrayList<Int64>,
    counts: ArrayList<Int64>, namesOut: ArrayList<Array<String>>, lensOut: ArrayList<Int64>): Int64 {
    normalizeWidth(tree)
    ensureWithinSizeLimit([tree], sizeLimit, true)
    let compiler = Compiler(sizeLimit, whichCaptures)
    let accept = compiler.add(Op.Accept, -1, -1)
    let localStart = compiler.compile(tree, accept)
    compiler.states[accept].patternId = pattern
    let trimmed = trimCaptureNames(raw, compiler.states, keepTrailing, whichCaptures)
    let begin = all.size
    for (state in compiler.states) {
        var first = state.first
        var second = state.second
        if (first >= 0) {
            first += begin
        }
        if (second >= 0) {
            second += begin
        }
        let moved = State(state.op, first, second)
        moved.byteAtom = state.byteAtom
        moved.patternId = state.patternId
        all.add(moved)
    }
    starts.add(localStart + begin)
    begins.add(begin)
    counts.add(compiler.states.size)
    namesOut.add(trimmed)
    lensOut.add(match (staticExplicit(tree)) {
        case Some(count) => count + 1
        case None => -1
    })
    trimmed.size * 2
}

func assemble(trees: ArrayList<Expr>, raws: ArrayList<Array<String>>, keepTrailing: Bool, sizeLimit: Int64,
    whichCaptures: Int64): NfaParts {
    let all = ArrayList<State>()
    let starts = ArrayList<Int64>()
    let begins = ArrayList<Int64>()
    let counts = ArrayList<Int64>()
    let names = ArrayList<Array<String>>()
    let lens = ArrayList<Int64>()
    var slots: Int64 = 0
    for (i in 0..trees.size) {
        let needed = compilePattern(trees[i], raws[i], keepTrailing, i, sizeLimit, whichCaptures, all, starts, begins,
            counts, names, lens)
        if (needed > slots) {
            slots = needed
        }
    }
    var union = if (starts.size == 0) {
        -1
    } else {
        starts[starts.size - 1]
    }
    if (starts.size > 1) {
        var index = starts.size - 1
        while (index > 0) {
            index--
            all.add(State(Op.Split, starts[index], union))
            union = all.size - 1
        }
    }
    var needUnicode = false
    var needAscii = false
    for (state in all) {
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
    let unicodeWords = if (needUnicode) {
        unicodeClass(r'w')
    } else {
        CharSet()
    }
    let asciiWords = if (needAscii) {
        match (asciiClass("word")) {
            case Some(set) => set
            case None => throw Exception("missing ASCII word class")
        }
    } else {
        CharSet()
    }
    NfaParts(all.toArray(), union, starts.toArray(), begins.toArray(), counts.toArray(), names.toArray(), lens.toArray(),
        unicodeWords, asciiWords, slots, whichCaptures, trees.toArray())
}

func buildPatternsUnicode(patterns: Array<String>, whichCaptures: Int64, unicode: Bool): NfaParts {
    let options = PatternOptions()
    options.unicode = unicode
    let trees = ArrayList<Expr>()
    let raws = ArrayList<Array<String>>()
    for (pattern in patterns) {
        let parser = Parser(pattern, options)
        trees.add(parser.parse())
        raws.add(Array<String>(parser.captureNames.size, {i => parser.captureNames[i]}))
    }
    assemble(trees, raws, false, options.sizeLimit, whichCaptures)
}

func buildPatterns(patterns: Array<String>, whichCaptures: Int64): NfaParts {
    let options = PatternOptions()
    let trees = ArrayList<Expr>()
    let raws = ArrayList<Array<String>>()
    for (pattern in patterns) {
        let parser = Parser(pattern, options)
        trees.add(parser.parse())
        raws.add(Array<String>(parser.captureNames.size, {i => parser.captureNames[i]}))
    }
    assemble(trees, raws, false, options.sizeLimit, whichCaptures)
}

func buildHirs(hirs: Array<Hir>, sizeLimit: Int64): NfaParts {
    let trees = ArrayList<Expr>()
    let raws = ArrayList<Array<String>>()
    for (hir in hirs) {
        trees.add(exprFromHir(hir))
        raws.add(hirCaptureNames(hir))
    }
    assemble(trees, raws, true, sizeLimit, 0)
}

func buildLitePattern(pattern: String): NfaParts {
    let options = PatternOptions()
    options.lite = true
    let parser = Parser(pattern, options)
    let trees = ArrayList<Expr>()
    trees.add(parser.parse())
    let names = ArrayList<Array<String>>()
    names.add(Array<String>(parser.captureNames.size, {i => parser.captureNames[i]}))
    assemble(trees, names, false, options.sizeLimit, 0)
}

public class ThompsonNfa {
    let parts: NfaParts
    var compiledBytes: Option<ByteEngine> = None<ByteEngine>
    public init(patterns: Array<String>) {
        this(patterns, 0)
    }
    public init(patterns: Array<String>, whichCaptures: Int64) {
        parts = buildPatterns(patterns, whichCaptures)
        compiledBytes = None<ByteEngine>
    }
    public init(hirs: Array<Hir>) {
        this(hirs, 10485760)
    }
    public init(patterns: Array<String>, whichCaptures: Int64, unicode: Bool) {
        parts = buildPatternsUnicode(patterns, whichCaptures, unicode)
        compiledBytes = None<ByteEngine>
    }
    public init(hirs: Array<Hir>, sizeLimit: Int64) {
        if (sizeLimit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        parts = buildHirs(hirs, sizeLimit)
        compiledBytes = None<ByteEngine>
    }
    init(parts: NfaParts) {
        this.parts = parts
    }
    func ensureByte(): ByteEngine {
        match (compiledBytes) {
            case Some(engine) => return engine
            case None => ()
        }
        let engine = ByteEngine(parts.exprs, parts.groupNames, parts.staticLens, parts.whichCaptures)
        compiledBytes = Some(engine)
        engine
    }
    func expressionList(): Array<Expr> {
        parts.exprs
    }
    func nameList(): Array<Array<String>> {
        parts.groupNames
    }
    func lengthList(): Array<Int64> {
        parts.staticLens
    }
    public func stateCount(): Int64 {
        parts.states.size
    }
    public func memoryUsage(): Int64 {
        var total = parts.states.size * 32
        for (state in parts.states) {
            match (state.op) {
                case Op.CharacterClass(set) => total += set.rangeCount() * 16
                case _ => ()
            }
        }
        total
    }
    public func patternCount(): Int64 {
        parts.patternStarts.size
    }
    public func patternStateCount(pattern: Int64): Int64 {
        parts.patternCounts[checked(pattern)]
    }
    public func startState(pattern: Int64): Int64 {
        let index = checked(pattern)
        parts.patternStarts[index] - parts.patternBegins[index]
    }
    public func opName(pattern: Int64, state: Int64): String {
        match (at(pattern, state).op) {
            case Op.Literal(_) => "literal"
            case Op.CharacterClass(_) => "class"
            case Op.Any(_) => "any"
            case Op.Look(_) => "look"
            case Op.Split => "split"
            case Op.Save(_) => "save"
            case Op.Accept => "accept"
        }
    }
    public func opNext(pattern: Int64, state: Int64): Int64 {
        localEdge(pattern, at(pattern, state).first)
    }
    public func opAlternate(pattern: Int64, state: Int64): Int64 {
        localEdge(pattern, at(pattern, state).second)
    }
    public func whichOverlapping(text: String): Array<Int64> {
        whichOverlapping(SearchInput(text))
    }
    // One MatchKind::All scan. The anchored pattern body is added again at every
    // position, including an anchored search, while any thread is still active.
    // earliest stops after the first position, so only an empty match there counts.
    public func whichOverlapping(input: SearchInput): Array<Int64> {
        if (!input.utf8) {
            return ensureByte().whichOverlapping(input)
        }
        let ids = ArrayList<Int64>()
        if (parts.unionStart < 0 || parts.patternStarts.size == 0) {
            return ids.toArray()
        }
        let anchored = input.anchor != 0
        var begin: Int64 = 0
        var end = parts.patternStarts.size
        if (input.anchor == 2) {
            if (input.pattern < 0 || input.pattern >= parts.patternStarts.size) {
                return ids.toArray()
            }
            begin = input.pattern
            end = input.pattern + 1
        }
        let decoded = Input(input.text)
        let from = decoded.boundary(input.start)
        var until = decoded.boundary(input.end)
        if (decoded.offsets[until] != input.end) {
            until--
        }
        if (from > until || (anchored && decoded.offsets[from] != input.start)) {
            return ids.toArray()
        }
        let reported = Array<Bool>(parts.patternStarts.size, repeat: false)
        let unused = PikeCache()
        unused.prepareSeen(parts.states.size)
        unused.beginSlots()
        let slots = unused.borrowSlots(0)
        var current = ArrayList<Thread>()
        var pos = from
        var scanning = true
        while (scanning && pos <= until) {
            if (current.isEmpty() && anchored && pos > from) {
                scanning = false
            } else {
                var index = begin
                while (index < end) {
                    closure(current, unused.seen, parts.patternStarts[index], pos, slots, pos, decoded, unused)
                    index++
                }
                let next = ArrayList<Thread>()
                unused.clearNextSeen()
                for (thread in current) {
                    let state = parts.states[thread.state]
                    match (state.op) {
                        case Op.Accept =>
                            if (state.patternId >= 0 && state.patternId < reported.size) {
                                reported[state.patternId] = true
                            }
                        case Op.Literal(char) =>
                            if (pos < until && decoded.chars[pos] == char) {
                                closure(next, unused.nextSeen, state.first, thread.start, thread.slots, pos + 1, decoded,
                                    unused)
                            }
                        case Op.CharacterClass(set) =>
                            if (if (pos < until) {
                                set.contains(decoded.chars[pos])
                            } else {
                                false
                            }) {
                                closure(next, unused.nextSeen, state.first, thread.start, thread.slots, pos + 1, decoded,
                                    unused)
                            }
                        case Op.Any(mode) =>
                            if (pos < until && passesDot(mode, decoded.chars[pos])) {
                                closure(next, unused.nextSeen, state.first, thread.start, thread.slots, pos + 1, decoded,
                                    unused)
                            }
                        case _ => ()
                    }
                }
                if (input.earliest) {
                    scanning = false
                } else {
                    current = next
                    unused.swapSeen()
                    pos++
                }
            }
        }
        for (i in 0..reported.size) {
            if (reported[i]) {
                ids.add(i)
            }
        }
        ids.toArray()
    }
    public func search(input: SearchInput, cache: PikeCache): Option<PikeMatch> {
        if (!input.utf8) {
            cache.reset()
            return ensureByte().search(input)
        }
        if (parts.unionStart < 0) {
            cache.reset()
            return None
        }
        var entry = parts.unionStart
        var anchored = input.anchor != 0
        if (input.anchor == 2) {
            if (input.pattern < 0 || input.pattern >= parts.patternStarts.size) {
                cache.reset()
                return None
            }
            entry = parts.patternStarts[input.pattern]
        }
        let decoded = Input(input.text)
        let from = decoded.boundary(input.start)
        var until = decoded.boundary(input.end)
        if (decoded.offsets[until] != input.end) {
            until--
        }
        if (from > until || (anchored && decoded.offsets[from] != input.start)) {
            cache.reset()
            return None
        }
        match (run(decoded, from, until, anchored, parts.whichCaptures != 2, input.earliest, entry, true, cache)) {
            case Some(hit) =>
                if (parts.whichCaptures == 2) {
                    cache.reset()
                    return None
                }
                let found = capturesOf(input.text, decoded, hit)
                cache.remember(hit.pattern, found)
                Some(PikeMatch(hit.pattern, found))
            case None =>
                cache.reset()
                None
        }
    }
    public func isMatch(input: SearchInput, cache: PikeCache): Bool {
        if (!input.utf8) {
            cache.reset()
            return ensureByte().isMatch(input)
        }
        if (parts.unionStart < 0) {
            cache.reset()
            return false
        }
        var entry = parts.unionStart
        let anchored = input.anchor != 0
        if (input.anchor == 2) {
            if (input.pattern < 0 || input.pattern >= parts.patternStarts.size) {
                cache.reset()
                return false
            }
            entry = parts.patternStarts[input.pattern]
        }
        let decoded = Input(input.text)
        let from = decoded.boundary(input.start)
        var until = decoded.boundary(input.end)
        if (decoded.offsets[until] != input.end) {
            until--
        }
        if (from > until || (anchored && decoded.offsets[from] != input.start)) {
            cache.reset()
            return false
        }
        match (run(decoded, from, until, anchored, false, input.earliest, entry, true, cache)) {
            case Some(_) => true
            case None =>
                cache.reset()
                false
        }
    }
    func rawStates(): Array<State> {
        parts.states
    }
    func rawUnion(): Int64 {
        parts.unionStart
    }
    func rawPatternStart(pattern: Int64): Int64 {
        parts.patternStarts[checked(pattern)]
    }
    func rawNames(pattern: Int64): Array<String> {
        parts.groupNames[checked(pattern)]
    }
    func rawStatic(pattern: Int64): Int64 {
        parts.staticLens[checked(pattern)]
    }
    func rawSlotCount(): Int64 {
        parts.slotCount
    }
    func checked(pattern: Int64): Int64 {
        if (pattern < 0 || pattern >= parts.patternBegins.size) {
            throw Exception("pattern index out of bounds")
        }
        pattern
    }
    func at(pattern: Int64, state: Int64): State {
        let index = checked(pattern)
        if (state < 0 || state >= parts.patternCounts[index]) {
            throw Exception("state index out of bounds")
        }
        parts.states[parts.patternBegins[index] + state]
    }
    func localEdge(pattern: Int64, absolute: Int64): Int64 {
        if (absolute < 0) {
            return -1
        }
        let begin = parts.patternBegins[pattern]
        let end = begin + parts.patternCounts[pattern]
        if (absolute < begin || absolute >= end) {
            return -1
        }
        absolute - begin
    }
    func capturesOf(text: String, input: Input, hit: NfaHit): Captures {
        let names = parts.groupNames[hit.pattern]
        let groups = Array<Option<RegexMatch>>(names.size, repeat: None)
        let start = input.offsets[hit.start]
        let end = input.offsets[hit.end]
        groups[0] = Some(RegexMatch(start, end, text[start..end]))
        for (i in 1..names.size) {
            let a = hit.slots[i * 2]
            let b = hit.slots[i * 2 + 1]
            if (a >= 0 && b >= 0) {
                let left = input.offsets[a]
                let right = input.offsets[b]
                groups[i] = Some(RegexMatch(left, right, text[left..right]))
            }
        }
        Captures(groups, names, parts.staticLens[hit.pattern])
    }
    func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, start: Int64, slots: Array<Int64>, pos: Int64,
        input: Input, cache: PikeCache): Unit {
        let stack = ArrayList<Thread>()
        stack.add(Thread(state, start, slots))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            let id = frame.state
            if (id < 0 || seen[id]) {
                continue
            }
            seen[id] = true
            let s = parts.states[id]
            match (s.op) {
                case Op.Split =>
                    stack.add(Thread(s.second, start, frame.slots))
                    stack.add(Thread(s.first, start, frame.slots))
                case Op.Save(slot) =>
                    if (frame.slots.size == 0) {
                        stack.add(Thread(s.first, start, frame.slots))
                    } else {
                        let updated = cache.copySlots(frame.slots)
                        updated[slot] = pos
                        stack.add(Thread(s.first, start, updated))
                    }
                case Op.Look(mode) =>
                    if (passesLook(mode, pos, input.chars, parts.unicodeWords, parts.asciiWords)) {
                        stack.add(Thread(s.first, start, frame.slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
    func run(input: Input, from: Int64, until: Int64, anchored: Bool, capture: Bool, earliest: Bool, entry: Int64,
        record: Bool, cache: PikeCache): Option<NfaHit> {
        var current = ArrayList<Thread>()
        cache.prepareSeen(parts.states.size)
        cache.beginSlots()
        var best: Option<NfaHit> = None
        var found = false
        var pos = from
        let slots = cache.borrowSlots(if (capture) {
            parts.slotCount
        } else {
            0
        })
        while (pos <= until) {
            if (!found && (!anchored || pos == from)) {
                closure(current, cache.seen, entry, pos, slots, pos, input, cache)
            }
            if (anchored && pos != from && current.isEmpty()) {
                return best
            }
            if (record) {
                cache.noteThreads(current)
            }
            let next = ArrayList<Thread>()
            cache.clearNextSeen()
            for (thread in current) {
                let s = parts.states[thread.state]
                var consume = false
                match (s.op) {
                    case Op.Accept =>
                        let hit = NfaHit(s.patternId, thread.start, pos, thread.slots)
                        if (earliest) {
                            return Some(hit)
                        }
                        best = Some(hit)
                        found = true
                        break
                    case Op.Literal(c) => consume = pos < until && input.chars[pos] == c
                    case Op.CharacterClass(set) => consume = if (pos < until) {
                        set.contains(input.chars[pos])
                    } else {
                        false
                    }
                    case Op.Any(mode) => consume = pos < until && passesDot(mode, input.chars[pos])
                    case _ => ()
                }
                if (consume) {
                    closure(next, cache.nextSeen, s.first, thread.start, thread.slots, pos + 1, input, cache)
                }
            }
            if (found && next.isEmpty()) {
                return best
            }
            current = next
            cache.swapSeen()
            pos++
        }
        best
    }
}
