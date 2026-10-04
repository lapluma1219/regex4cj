package cjregex

import std.collection.*

// Explicit forward search over one or more Thompson NFAs. This is the PikeVM
// entry point: callers pass the full haystack plus a search range, and anchors
// still observe text outside that range. Match spans are absolute byte offsets.
public class PikeCache {
    var pattern: Int64 = -1
    let starts = ArrayList<Int64>()
    let ends = ArrayList<Int64>()
    public func reset(): Unit {
        pattern = -1
        for (i in 0..starts.size) {
            starts[i] = -1
            ends[i] = -1
        }
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
    let engines: Array<Regex>
    public let cache: PikeCache
    public init(pattern: String) {
        this([pattern])
    }
    public init(patterns: Array<String>) {
        if (patterns.isEmpty()) {
            throw Exception("at least one pattern is required")
        }
        engines = Array<Regex>(patterns.size, {i => Regex(patterns[i])})
        cache = PikeCache()
    }
    public init(hir: Hir) {
        this([hir])
    }
    public init(hirs: Array<Hir>) {
        if (hirs.isEmpty()) {
            throw Exception("at least one pattern is required")
        }
        engines = Array<Regex>(hirs.size, {i => Regex(hirs[i])})
        cache = PikeCache()
    }
    public func patternCount(): Int64 {
        engines.size
    }
    public func reset(): Unit {
        cache.reset()
    }
    public func stateCount(pattern: Int64): Int64 {
        engine(pattern).nfaStateCount()
    }
    public func startState(pattern: Int64): Int64 {
        engine(pattern).nfaStart()
    }
    public func opName(pattern: Int64, state: Int64): String {
        engine(pattern).nfaOp(state)
    }
    public func opNext(pattern: Int64, state: Int64): Int64 {
        engine(pattern).nfaNext(state)
    }
    public func opAlternate(pattern: Int64, state: Int64): Int64 {
        engine(pattern).nfaAlternate(state)
    }
    public func search(text: String): Option<PikeMatch> {
        search(text, 0, text.size, false)
    }
    public func search(text: String, start: Int64, end: Int64, anchored: Bool): Option<PikeMatch> {
        var bestPattern: Int64 = -1
        var bestStart: Int64 = 0
        var best: Option<Captures> = None
        for (i in 0..engines.size) {
            match (engines[i].searchWindow(text, start, end, anchored)) {
                case None => ()
                case Some(found) =>
                    let at = match (found.get(0)) {
                        case Some(hit) => hit.start
                        case None => start
                    }
                    if (bestPattern < 0 || at < bestStart) {
                        bestPattern = i
                        bestStart = at
                        best = Some(found)
                    }
            }
        }
        match (best) {
            case Some(found) =>
                cache.remember(bestPattern, found)
                Some(PikeMatch(bestPattern, found))
            case None =>
                cache.reset()
                None
        }
    }
    func engine(pattern: Int64): Regex {
        if (pattern < 0 || pattern >= engines.size) {
            throw Exception("pattern index out of bounds")
        }
        engines[pattern]
    }
}
