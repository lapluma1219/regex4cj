package cjregex

import std.collection.*

func buildOnePass(patterns: Array<String>): Option<OnePass> {
    try {
        Some(OnePass(patterns))
    } catch (e: Exception) {
        None<OnePass>
    }
}

func buildHybrid(patterns: Array<String>): Option<HybridDfa> {
    try {
        Some(HybridDfa(patterns, 8192, -1))
    } catch (e: Exception) {
        None<HybridDfa>
    }
}

func prefixPieces(patterns: Array<String>): Array<Array<UInt8>> {
    if (patterns.size != 1) {
        return Array<Array<UInt8>>()
    }
    try {
        let seq = extractLiterals(Hir.parse(patterns[0]))
        if (!seq.finite || seq.pieces.size == 0 || seq.pieces.size > 8) {
            return Array<Array<UInt8>>()
        }
        let kept = ArrayList<Array<UInt8>>()
        for (piece in seq.pieces) {
            if (piece.bytes.size == 0) {
                return Array<Array<UInt8>>()
            }
            kept.add(piece.bytes)
        }
        kept.toArray()
    } catch (e: Exception) {
        Array<Array<UInt8>>()
    }
}

// Meta search. One-pass is tried first. Otherwise a lazy DFA recovers the
// match, using the reverse NFA for the start. A required literal prefix skips
// positions that cannot start a match. PikeVM is the fallback. This does not
// replace Regex.find.
public class MetaRegex {
    let one: Option<OnePass>
    let hybrid: Option<HybridDfa>
    let prefixes: Array<Array<UInt8>>
    let vm: PikeVM
    public let engineName: String
    public init(pattern: String) {
        this([pattern])
    }
    public init(patterns: Array<String>) {
        one = buildOnePass(patterns)
        hybrid = match (one) {
            case Some(_) => None<HybridDfa>
            case None => buildHybrid(patterns)
        }
        prefixes = prefixPieces(patterns)
        engineName = match (one) {
            case Some(_) => "onepass"
            case None => match (hybrid) {
                case Some(_) => "hybrid"
                case None => "pikevm"
            }
        }
        vm = PikeVM(patterns)
    }
    public func memoryUsage(): Int64 {
        var total = vm.memoryUsage()
        match (hybrid) {
            case Some(engine) => total += engine.memoryUsage()
            case None => ()
        }
        total
    }
    public func search(text: String): Option<PikeMatch> {
        searchFrom(text, 0)
    }
    public func searchAll(text: String): Array<PikeMatch> {
        let found = ArrayList<PikeMatch>()
        var start: Int64 = 0
        var lastEnd: Int64 = -1
        var reading = true
        while (reading && start <= text.size) {
            match (searchFrom(text, start)) {
                case None => reading = false
                case Some(hit) =>
                    var report = hit
                    var emit = true
                    let emptyHit = hit.start() == hit.end()
                    let repeatedEnd = hit.end() == lastEnd
                    if (emptyHit && repeatedEnd) {
                        let next = nextOffset(text, hit.end())
                        if (next > text.size) {
                            reading = false
                            emit = false
                        } else {
                            match (searchFrom(text, next)) {
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
    func searchFrom(text: String, start: Int64): Option<PikeMatch> {
        let at = earliestPrefix(text, start, prefixes)
        if (at < 0) {
            return None<PikeMatch>
        }
        match (one) {
            case Some(engine) =>
                var cursor = at
                while (cursor <= text.size) {
                    match (engine.searchAnchored(text, cursor)) {
                        case Some(hit) => return Some(hit)
                        case None => cursor = nextOffset(text, cursor)
                    }
                }
                None<PikeMatch>
            case None => match (hybrid) {
                case Some(engine) => match (engine.search(SearchInput(text).span(at, text.size))) {
                    case Some(hit) =>
                        // The public result contains captures, regardless of the
                        // engine used to locate the winning pattern and start.
                        vm.search(SearchInput(text).span(hit.start, text.size).selectPattern(hit.pattern))
                    case None => None<PikeMatch>
                }
                case None => vm.search(SearchInput(text).span(at, text.size))
            }
        }
    }
}

func earliestPrefix(text: String, start: Int64, pieces: Array<Array<UInt8>>): Int64 {
    if (pieces.size == 0) {
        return start
    }
    let bytes = text.toArray()
    var at = start
    while (at < bytes.size) {
        for (piece in pieces) {
            if (bytesStart(bytes, at, piece)) {
                return at
            }
        }
        at++
    }
    -1
}

func bytesStart(bytes: Array<UInt8>, at: Int64, piece: Array<UInt8>): Bool {
    if (at + piece.size > bytes.size) {
        return false
    }
    for (i in 0..piece.size) {
        if (bytes[at + i] != piece[i]) {
            return false
        }
    }
    true
}

func nextOffset(text: String, at: Int64): Int64 {
    let bytes = text.toArray()
    var next = at + 1
    while (next < bytes.size) {
        let byte = Int64(bytes[next])
        if (byte < 128 || byte >= 192) {
            return next
        }
        next++
    }
    next
}
