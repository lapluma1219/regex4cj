package cjregex

import std.collection.*

// Explicit forward search over one or more Thompson NFAs. This is the PikeVM
// entry point: callers pass the full haystack plus a search range, and anchors
// still observe text outside that range. Match spans are absolute byte offsets.
public class PikeCache {
    var pattern: Int64 = -1
    let starts = ArrayList<Int64>()
    let ends = ArrayList<Int64>()
    let threads = ArrayList<Int64>()
    var seen = Array<Bool>(0, repeat: false)
    var nextSeen = Array<Bool>(0, repeat: false)
    // Capture slots live here for the duration of a Pike search. Threads hold
    // a row from this pool and copy it before a Save writes. reset keeps the
    // rows so the next search can reuse them.
    let slotRows = ArrayList<Array<Int64>>()
    var slotUsed: Int64 = 0
    public func reset(): Unit {
        pattern = -1
        for (i in 0..starts.size) {
            starts[i] = -1
            ends[i] = -1
        }
        while (!threads.isEmpty()) {
            threads.remove(at: threads.size - 1)
        }
        slotUsed = 0
    }
    public func captureWorkspace(): Int64 {
        slotRows.size
    }
    func beginSlots(): Unit {
        slotUsed = 0
    }
    func takeRow(width: Int64): Array<Int64> {
        if (slotUsed < slotRows.size) {
            let row = slotRows[slotUsed]
            slotUsed++
            if (row.size == width) {
                return row
            }
            let fresh = Array<Int64>(width, repeat: -1)
            slotRows[slotUsed - 1] = fresh
            return fresh
        }
        let fresh = Array<Int64>(width, repeat: -1)
        slotRows.add(fresh)
        slotUsed++
        fresh
    }
    func borrowSlots(width: Int64): Array<Int64> {
        if (width <= 0) {
            return Array<Int64>()
        }
        let row = takeRow(width)
        for (i in 0..row.size) {
            row[i] = -1
        }
        row
    }
    func copySlots(source: Array<Int64>): Array<Int64> {
        if (source.size == 0) {
            return source
        }
        let row = takeRow(source.size)
        for (i in 0..source.size) {
            row[i] = source[i]
        }
        row
    }
    public func activeThreads(): Int64 {
        threads.size
    }
    func noteThreads(current: ArrayList<Thread>): Unit {
        while (!threads.isEmpty()) {
            threads.remove(at: threads.size - 1)
        }
        for (thread in current) {
            threads.add(thread.state)
        }
    }
    func prepareSeen(width: Int64): Unit {
        if (seen.size != width) {
            seen = Array<Bool>(width, repeat: false)
            nextSeen = Array<Bool>(width, repeat: false)
        } else {
            var index: Int64 = 0
            while (index < width) {
                seen[index] = false
                nextSeen[index] = false
                index++
            }
        }
    }
    func clearNextSeen(): Unit {
        var index: Int64 = 0
        while (index < nextSeen.size) {
            nextSeen[index] = false
            index++
        }
    }
    func swapSeen(): Unit {
        let previous = seen
        seen = nextSeen
        nextSeen = previous
    }
    public func hasMatch(): Bool {
        pattern >= 0
    }
    public func patternId(): Int64 {
        pattern
    }
    public func groupStart(index: Int64): Int64 {
        if (index < 0 || index >= starts.size) {
            -1
        } else {
            starts[index]
        }
    }
    public func groupEnd(index: Int64): Int64 {
        if (index < 0 || index >= ends.size) {
            -1
        } else {
            ends[index]
        }
    }
    func remember(pattern: Int64, captures: Captures): Unit {
        this.pattern = pattern
        while (starts.size < captures.size) {
            starts.add(-1)
            ends.add(-1)
        }
        for (i in 0..starts.size) {
            if (i >= captures.size) {
                starts[i] = -1
                ends[i] = -1
            } else {
                match (captures.get(i)) {
                    case Some(hit) =>
                        starts[i] = hit.start
                        ends[i] = hit.end
                    case None =>
                        starts[i] = -1
                        ends[i] = -1
                }
            }
        }
    }
}

public class PikeMatch {
    public let pattern: Int64
    public let captures: Captures
    public init(pattern: Int64, captures: Captures) {
        this.pattern = pattern
        this.captures = captures
    }
    public func start(): Int64 {
        match (captures.get(0)) {
            case Some(hit) => hit.start
            case None => throw Exception("missing match span")
        }
    }
    public func end(): Int64 {
        match (captures.get(0)) {
            case Some(hit) => hit.end
            case None => throw Exception("missing match span")
        }
    }
}

public class PikeVM {
    let nfa: ThompsonNfa
    public let cache: PikeCache
    public init(pattern: String) {
        this([pattern])
    }
    public init(patterns: Array<String>) {
        this(patterns, 0)
    }
    public init(patterns: Array<String>, whichCaptures: Int64) {
        nfa = ThompsonNfa(patterns, whichCaptures)
        cache = PikeCache()
    }
    public init(hir: Hir) {
        this([hir])
    }
    public init(hirs: Array<Hir>) {
        nfa = ThompsonNfa(hirs)
        cache = PikeCache()
    }
    public func patternCount(): Int64 {
        nfa.patternCount()
    }
    public func memoryUsage(): Int64 {
        nfa.memoryUsage() + cache.captureWorkspace() * 8
    }
    public func reset(): Unit {
        cache.reset()
    }
    public func graph(): ThompsonNfa {
        nfa
    }
    public func stateCount(pattern: Int64): Int64 {
        nfa.patternStateCount(pattern)
    }
    public func startState(pattern: Int64): Int64 {
        nfa.startState(pattern)
    }
    public func opName(pattern: Int64, state: Int64): String {
        nfa.opName(pattern, state)
    }
    public func opNext(pattern: Int64, state: Int64): Int64 {
        nfa.opNext(pattern, state)
    }
    public func opAlternate(pattern: Int64, state: Int64): Int64 {
        nfa.opAlternate(pattern, state)
    }
    public func whichOverlapping(text: String): Array<Int64> {
        nfa.whichOverlapping(text)
    }
    public func whichOverlapping(input: SearchInput): Array<Int64> {
        nfa.whichOverlapping(input)
    }
    public func searchEarliest(text: String): Option<PikeMatch> {
        search(text, 0, text.size, false, true)
    }
    public func search(text: String): Option<PikeMatch> {
        search(text, 0, text.size, false, false)
    }
    public func search(text: String, start: Int64, end: Int64, anchored: Bool): Option<PikeMatch> {
        search(text, start, end, anchored, false)
    }
    public func search(input: SearchInput): Option<PikeMatch> {
        nfa.search(input, cache)
    }
    public func isMatch(input: SearchInput): Bool {
        nfa.isMatch(input, cache)
    }
    // Non-overlapping matches. An empty match is reported once, then the next
    // search starts one byte later, matching regex-automata's Searcher.
    public func searchAll(text: String): Array<PikeMatch> {
        let found = ArrayList<PikeMatch>()
        var start: Int64 = 0
        var lastEnd: Int64 = -1
        var reading = true
        while (reading && start <= text.size) {
            match (search(SearchInput(text).span(start, text.size))) {
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
                            match (search(SearchInput(text).span(next, text.size))) {
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
    func search(text: String, start: Int64, end: Int64, anchored: Bool, earliest: Bool): Option<PikeMatch> {
        var query = SearchInput(text).span(start, end)
        if (anchored) {
            query = query.anchored(true)
        }
        if (earliest) {
            query = query.withEarliest(true)
        }
        nfa.search(query, cache)
    }
}
