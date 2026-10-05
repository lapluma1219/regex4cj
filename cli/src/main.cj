package regex_cli

import cjregex.*
import std.collection.*
import std.convert.*
import std.time.*

func hexDigit(c: Rune): Int64 {
    if (c >= r'0' && c <= r'9') {
        return Int64(UInt32(c) - UInt32(r'0'))
    }
    if (c >= r'a' && c <= r'f') {
        return Int64(UInt32(c) - UInt32(r'a')) + 10
    }
    if (c >= r'A' && c <= r'F') {
        return Int64(UInt32(c) - UInt32(r'A')) + 10
    }
    throw Exception("invalid hex digit")
}

func parseHex(text: String): Array<UInt8> {
    let chars = ArrayList<Rune>()
    for (c in text.runes()) {
        chars.add(c)
    }
    if (chars.size % 2 != 0) {
        throw Exception("hex text must have an even length")
    }
    let out = ArrayList<UInt8>()
    var i: Int64 = 0
    while (i < chars.size) {
        out.add(UInt8(hexDigit(chars[i]) * 16 + hexDigit(chars[i + 1])))
        i += 2
    }
    return out.toArray()
}

func parseLiteralPiece(token: String): LiteralPiece {
    if (token.size < 2 || (!token.startsWith("E:") && !token.startsWith("I:"))) {
        throw Exception("invalid literal")
    }
    LiteralPiece(token.startsWith("E:"), parseHex(token[2..token.size]))
}

func parseLiteralSpec(spec: String): LiteralSeq {
    if (spec == "inf") {
        return LiteralSeq.infinite()
    }
    if (spec == "empty") {
        return LiteralSeq.of(Array<LiteralPiece>())
    }
    let pieces = ArrayList<LiteralPiece>()
    var buf = StringBuilder()
    for (c in spec.runes()) {
        if (c == r',') {
            pieces.add(parseLiteralPiece(buf.toString()))
            buf = StringBuilder()
        } else {
            buf.append(c)
        }
    }
    pieces.add(parseLiteralPiece(buf.toString()))
    LiteralSeq.of(pieces.toArray())
}

func applyLiteralStep(seq: LiteralSeq, step: String): LiteralSeq {
    if (step == "minimize") {
        return seq.minimize()
    }
    if (step == "reverse") {
        return seq.reversed()
    }
    if (step == "sort") {
        return seq.sorted()
    }
    if (step == "inexact") {
        return seq.makeInexact()
    }
    if (step == "dedup") {
        return seq.deduped()
    }
    if (step == "optimize-prefix") {
        return seq.optimizePrefix()
    }
    if (step == "optimize-suffix") {
        return seq.optimizeSuffix()
    }
    if (step.startsWith("keep-first:")) {
        return seq.keepFirst(Int64.parse(step[11..step.size]))
    }
    if (step.startsWith("keep-last:")) {
        return seq.keepLast(Int64.parse(step[10..step.size]))
    }
    throw Exception("unknown literal step")
}

func runLiteralOp(args: Array<String>): Int64 {
    if (args.size == 4 && (args[1] == "cross-forward" || args[1] == "cross-reverse" || args[1] == "union" || args[1] ==
        "union-empty")) {
        let left = parseLiteralSpec(args[2])
        let right = parseLiteralSpec(args[3])
        let result = if (args[1] == "cross-forward") {
            left.crossForward(right)
        } else if (args[1] == "cross-reverse") {
            left.crossReverse(right)
        } else if (args[1] == "union") {
            left.union(right)
        } else {
            left.unionIntoEmpty(right)
        }
        println(formatLiteralSeq(result))
        return 0
    }
    if (args.size == 4 && (args[1] == "keep-first" || args[1] == "keep-last")) {
        let len = Int64.parse(args[2])
        let seq = parseLiteralSpec(args[3])
        let result = if (args[1] == "keep-first") {
            seq.keepFirst(len)
        } else {
            seq.keepLast(len)
        }
        println(formatLiteralSeq(result))
        return 0
    }
    if (args.size == 3 && (args[1] == "prefix" || args[1] == "suffix")) {
        let seq = parseLiteralSpec(args[2])
        let common = if (args[1] == "prefix") {
            seq.commonPrefix()
        } else {
            seq.commonSuffix()
        }
        println(formatCommon(common))
        return 0
    }
    if (args.size == 3 && (args[1] == "minimize" || args[1] == "reverse" || args[1] == "sort" || args[1] == "inexact" ||
        args[1] == "dedup" || args[1] == "optimize-prefix" || args[1] == "optimize-suffix")) {
        println(formatLiteralSeq(applyLiteralStep(parseLiteralSpec(args[2]), args[1])))
        return 0
    }
    if (args.size == 3 && (args[1] == "finite" || args[1] == "empty" || args[1] == "exact" || args[1] == "inexact-all")) {
        let seq = parseLiteralSpec(args[2])
        let answer = if (args[1] == "finite") {
            seq.finite
        } else if (args[1] == "empty") {
            seq.isEmpty()
        } else if (args[1] == "exact") {
            seq.isExact()
        } else {
            seq.isInexact()
        }
        println(if (answer) {
            "true"
        } else {
            "false"
        })
        return 0
    }
    if (args.size == 4 && (args[1] == "max-union" || args[1] == "max-cross")) {
        let left = parseLiteralSpec(args[2])
        let right = parseLiteralSpec(args[3])
        let count = if (args[1] == "max-union") {
            left.maxUnionLen(right)
        } else {
            left.maxCrossLen(right)
        }
        match (count) {
            case None => println("none")
            case Some(value) => println(value)
        }
        return 0
    }
    if (args.size == 3 && (args[1] == "len" || args[1] == "min-len" || args[1] == "max-len")) {
        let seq = parseLiteralSpec(args[2])
        let count = if (args[1] == "len") {
            seq.literalCount()
        } else if (args[1] == "min-len") {
            seq.minLiteralLen()
        } else {
            seq.maxLiteralLen()
        }
        match (count) {
            case None => println("none")
            case Some(value) => println(value)
        }
        return 0
    }
    if (args.size == 3 && args[1] == "pipe") {
        throw Exception("literal pipe needs steps and a sequence")
    }
    if (args.size == 4 && args[1] == "pipe") {
        var seq = parseLiteralSpec(args[3])
        var buf = StringBuilder()
        let steps = ArrayList<String>()
        for (c in args[2].runes()) {
            if (c == r'|') {
                steps.add(buf.toString())
                buf = StringBuilder()
            } else {
                buf.append(c)
            }
        }
        steps.add(buf.toString())
        for (step in steps) {
            seq = applyLiteralStep(seq, step)
        }
        println(formatLiteralSeq(seq))
        return 0
    }
    throw Exception("unknown literal operation")
}

func hexBytes(bytes: Array<UInt8>): String {
    let result = StringBuilder()
    for (byte in bytes) {
        let value = Int64(byte)
        for (nibble in [value / 16, value % 16]) {
            result.append(Rune(UInt32(if (nibble < 10) {
                nibble + 48
            } else {
                nibble + 87
            })))
        }
    }
    return result.toString()
}

func parseHexBytes(text: String): Array<UInt8> {
    if (text == "-") {
        return Array<UInt8>()
    }
    if (text.size % 2 != 0) {
        throw Exception("quit bytes must be hex pairs")
    }
    let raw = text.toArray()
    Array<UInt8>(
        raw.size / 2,
        {
            i =>
                let hi = hexValue(raw[i * 2])
                let lo = hexValue(raw[i * 2 + 1])
                UInt8(hi * 16 + lo)
        }
    )
}

func hexValue(byte: UInt8): Int64 {
    let value = Int64(byte)
    if (value >= 48 && value <= 57) {
        return value - 48
    }
    if (value >= 97 && value <= 102) {
        return value - 87
    }
    if (value >= 65 && value <= 70) {
        return value - 55
    }
    throw Exception("quit bytes must be hex pairs")
}

func kindName(kind: RegexErrorKind): String {
    match (kind) {
        case RegexErrorKind.Syntax => "Syntax"
        case RegexErrorKind.CompiledTooBig => "CompiledTooBig"
    }
}

func hexRange(bytes: Array<UInt8>, start: Int64, end: Int64): String {
    let result = StringBuilder()
    var index = start
    while (index < end && index < bytes.size) {
        let value = Int64(bytes[index])
        for (nibble in [value / 16, value % 16]) {
            result.append(Rune(UInt32(if (nibble < 10) {
                nibble + 48
            } else {
                nibble + 87
            })))
        }
        index++
    }
    result.toString()
}

func byteQuery(bytes: Array<UInt8>, start: Int64, end: Int64, mode: String, earliest: Bool): SearchInput {
    var query = SearchInput(bytes).span(start, end).withEarliest(earliest)
    if (mode == "yes") {
        query = query.anchored(true)
    } else if (mode != "no") {
        query = query.selectPattern(Int64.parse(mode))
    }
    query
}

func printByteMatch(hit: PikeMatch, bytes: Array<UInt8>): Unit {
    println("pattern\t${hit.pattern}")
    println("span\t${hit.start()}\t${hit.end()}")
    for (i in 0..hit.captures.size) {
        match (hit.captures.get(i)) {
            case Some(group) => println(
                "group\t${i}\t${group.start}\t${group.end}\t${hexRange(bytes, group.start, group.end)}")
            case None => println("group\t${i}\t-")
        }
    }
}

func searchQuery(text: String, start: Int64, end: Int64, mode: String, earliest: Bool): SearchInput {
    var query = SearchInput(text).span(start, end).withEarliest(earliest)
    if (mode == "yes") {
        query = query.anchored(true)
    } else if (mode != "no") {
        query = query.selectPattern(Int64.parse(mode))
    }
    query
}

func captureMode(name: String): Int64 {
    if (name == "all") {
        return 0
    }
    if (name == "implicit") {
        return 1
    }
    if (name == "none") {
        return 2
    }
    throw Exception("capture mode must be all, implicit, or none")
}

func printPikeMatch(hit: PikeMatch): Unit {
    println("pattern\t${hit.pattern}")
    println("span\t${hit.start()}\t${hit.end()}")
    for (i in 0..hit.captures.size) {
        match (hit.captures.get(i)) {
            case Some(group) => println("group\t${i}\t${group.start}\t${group.end}\t${hexText(group.asStr())}")
            case None => println("group\t${i}\t-")
        }
    }
}

func plainException(e: Exception): String {
    let text = e.toString()
    let prefix = "Exception: "
    if (text.startsWith(prefix)) {
        return text[prefix.size..]
    }
    return text
}

func printBacktrack(caps: Captures): Unit {
    println("pattern\t0")
    let whole = caps.getMatch()
    println("span\t${whole.start}\t${whole.end}")
    for (i in 0..caps.size) {
        match (caps.get(i)) {
            case Some(group) => println("group\t${i}\t${group.start}\t${group.end}\t${hexText(group.asStr())}")
            case None => println("group\t${i}\t-")
        }
    }
}

func escapeCliText(text: String): String {
    let out = StringBuilder()
    let digits = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    for (ch in text.runes()) {
        let code = UInt32(ch)
        if (code < 0x80) {
            let byte = Int64(code)
            if ((byte >= 0x21 && byte <= 0x5B) || (byte >= 0x5D && byte <= 0x7E)) {
                out.append(ch)
            } else if (byte == 0) {
                out.append("\\0")
            } else if (byte == 10) {
                out.append("\\n")
            } else if (byte == 13) {
                out.append("\\r")
            } else if (byte == 9) {
                out.append("\\t")
            } else if (byte == 92) {
                out.append("\\\\")
            } else {
                out.append("\\x${digits[byte / 16]}${digits[byte % 16]}")
            }
        } else {
            out.append(ch)
        }
    }
    out.toString()
}

func printBacktrackFind(engine: BoundedBacktracker, text: String): Int64 {
    try {
        let hits = engine.searchAll(text)
        for (hit in hits) {
            let piece = text[hit.start()..hit.end()]
            println("${hit.pattern}:${hit.start()}:${hit.end()}:${escapeCliText(piece)}")
        }
        return hits.size
    } catch (e: Exception) {
        let message = plainException(e)
        if (message.startsWith("haystack of length ") || message.startsWith("visited capacity")) {
            println("error\t${message}")
            return 0
        }
        throw e
    }
}

func printDenseFind(patterns: Array<String>, text: String): Int64 {
    let engine = DenseDfa(patterns)
    var matched: Int64 = 0
    var start: Int64 = 0
    var lastEnd: Int64 = -1
    var reading = true
    while (reading && start <= text.size) {
        match (engine.search(SearchInput(text).span(start, text.size))) {
            case None => reading = false
            case Some(hit) =>
                var report = hit
                var emit = true
                if (hit.start == hit.end && hit.end == lastEnd) {
                    let next = hit.end + 1
                    if (next > text.size) {
                        reading = false
                        emit = false
                    } else {
                        match (engine.search(SearchInput(text).span(next, text.size))) {
                            case None =>
                                reading = false
                                emit = false
                            case Some(again) => report = again
                        }
                    }
                }
                if (emit) {
                    matched++
                    println("${report.pattern}:${report.start}:${report.end}:${escapeCliText(report.text)}")
                    lastEnd = report.end
                    start = report.end
                }
        }
    }
    matched
}

func printSparseFind(patterns: Array<String>, text: String): Int64 {
    let engine = SparseDfa(patterns)
    var matched: Int64 = 0
    var start: Int64 = 0
    var lastEnd: Int64 = -1
    var reading = true
    while (reading && start <= text.size) {
        match (engine.search(SearchInput(text).span(start, text.size))) {
            case None => reading = false
            case Some(hit) =>
                var report = hit
                var emit = true
                if (hit.start == hit.end && hit.end == lastEnd) {
                    let next = hit.end + 1
                    if (next > text.size) {
                        reading = false
                        emit = false
                    } else {
                        match (engine.search(SearchInput(text).span(next, text.size))) {
                            case None =>
                                reading = false
                                emit = false
                            case Some(again) => report = again
                        }
                    }
                }
                if (emit) {
                    matched++
                    println("${report.pattern}:${report.start}:${report.end}:${escapeCliText(report.text)}")
                    lastEnd = report.end
                    start = report.end
                }
        }
    }
    matched
}

func printHybridFind(patterns: Array<String>, text: String): Int64 {
    let engine = HybridDfa(patterns, 8192, -1)
    var matched: Int64 = 0
    var start: Int64 = 0
    var lastEnd: Int64 = -1
    var reading = true
    while (reading && start <= text.size) {
        match (engine.search(SearchInput(text).span(start, text.size))) {
            case None => reading = false
            case Some(hit) =>
                var report = hit
                var emit = true
                if (hit.start == hit.end && hit.end == lastEnd) {
                    let next = hit.end + 1
                    if (next > text.size) {
                        reading = false
                        emit = false
                    } else {
                        match (engine.search(SearchInput(text).span(next, text.size))) {
                            case None =>
                                reading = false
                                emit = false
                            case Some(again) => report = again
                        }
                    }
                }
                if (emit) {
                    matched++
                    println("${report.pattern}:${report.start}:${report.end}:${escapeCliText(report.text)}")
                    lastEnd = report.end
                    start = report.end
                }
        }
    }
    matched
}

func printRegexFind(patterns: Array<String>, text: String): Int64 {
    let re = Regex(patterns[0])
    let hits = re.findAll(text)
    for (hit in hits) {
        println("0:${hit.start}:${hit.end}:${escapeCliText(hit.text)}")
    }
    hits.size
}

func printPikeFind(patterns: Array<String>, text: String): Int64 {
    let vm = PikeVM(patterns)
    let hits = vm.searchAll(text)
    for (hit in hits) {
        let piece = text[hit.start()..hit.end()]
        println("${hit.pattern}:${hit.start()}:${hit.end()}:${escapeCliText(piece)}")
    }
    hits.size
}

func runMemory(engine: String, pattern: String): Int64 {
    if (engine == "pikevm") {
        println(PikeVM(pattern).memoryUsage())
    } else if (engine == "backtrack") {
        println(BoundedBacktracker(pattern).memoryUsage())
    } else if (engine == "dense") {
        println(DenseDfa(pattern).memoryUsage())
    } else if (engine == "meta") {
        println(MetaRegex(pattern).memoryUsage())
    } else {
        eprintln("unrecognized command '${engine}'")
        return 1
    }
    0
}

func runDfaBudget(limitText: String, pattern: String): Int64 {
    let limit = Int64.parse(limitText)
    try {
        let built = DenseDfa([pattern], limit)
        println("ok\t${built.memoryUsage()}")
    } catch (e: Exception) {
        println("error\t${plainException(e)}")
    }
    0
}

func parseQuery(args: Array<String>): (String, Array<String>, String) {
    let engine = args[1]
    let patterns = ArrayList<String>()
    var hay = ""
    var haveHay = false
    var index: Int64 = 2
    while (index < args.size) {
        if (args[index] == "-p" && index + 1 < args.size) {
            patterns.add(args[index + 1])
            index += 2
        } else if (args[index] == "-y" && index + 1 < args.size) {
            hay = args[index + 1]
            haveHay = true
            index += 2
        } else {
            throw Exception("unrecognized argument '${args[index]}'")
        }
    }
    if (!haveHay || patterns.size == 0) {
        throw Exception("missing pattern or haystack")
    }
    (engine, patterns.toArray(), hay)
}

func printCapture(pattern: Int64, caps: Captures, text: String): Unit {
    let line = StringBuilder()
    line.append("${pattern}:{ ")
    for (i in 0..caps.size) {
        if (i > 0) {
            line.append(", ")
        }
        let name = caps.groupName(i)
        if (name != "") {
            line.append("${i}/${name}: ")
        } else {
            line.append("${i}: ")
        }
        match (caps.get(i)) {
            case None => line.append("NONE")
            case Some(span) =>
                let piece = text[span.start..span.end]
                line.append("${span.start}..${span.end}/${escapeCliText(piece)}")
        }
    }
    line.append(" }")
    println(line.toString())
}

func printHalf(engine: String, patterns: Array<String>, text: String): Unit {
    var start: Int64 = 0
    var lastEnd: Int64 = -1
    var reading = true
    while (reading && start <= text.size) {
        let query = SearchInput(text).span(start, text.size)
        let found = if (engine == "sparse") {
            SparseDfa(patterns).search(query)
        } else if (engine == "hybrid") {
            HybridDfa(patterns, 8192, -1).search(query)
        } else {
            DenseDfa(patterns).search(query)
        }
        match (found) {
            case None => reading = false
            case Some(hit) =>
                var report = hit
                var emit = true
                if (hit.start == hit.end && hit.end == lastEnd) {
                    let next = hit.end + 1
                    if (next > text.size) {
                        reading = false
                        emit = false
                    } else {
                        let againQuery = SearchInput(text).span(next, text.size)
                        let again = if (engine == "sparse") {
                            SparseDfa(patterns).search(againQuery)
                        } else if (engine == "hybrid") {
                            HybridDfa(patterns, 8192, -1).search(againQuery)
                        } else {
                            DenseDfa(patterns).search(againQuery)
                        }
                        match (again) {
                            case None =>
                                reading = false
                                emit = false
                            case Some(nextHit) => report = nextHit
                        }
                    }
                }
                if (emit) {
                    println("${report.pattern}:${report.end}")
                    lastEnd = report.end
                    start = report.end
                }
        }
    }
}

func runCliHalf(args: Array<String>): Int64 {
    try {
        let (engine, patterns, hay) = parseQuery(args)
        if (engine != "dense" && engine != "sparse" && engine != "hybrid") {
            eprintln("unrecognized command '${engine}'")
            return 1
        }
        printHalf(engine, patterns, hay)
        0
    } catch (e: Exception) {
        eprintln(plainException(e))
        1
    }
}

func runCliCapture(args: Array<String>): Int64 {
    try {
        let (engine, patterns, hay) = parseQuery(args)
        if (engine == "pikevm" || engine == "meta") {
            for (hit in PikeVM(patterns).searchAll(hay)) {
                printCapture(hit.pattern, hit.captures, hay)
            }
        } else if (engine == "backtrack") {
            for (hit in BoundedBacktracker(patterns).searchAll(hay)) {
                printCapture(hit.pattern, hit.captures, hay)
            }
        } else if (engine == "lite") {
            if (patterns.size != 1) {
                eprintln("regex-lite accepts one pattern")
                return 1
            }
            for (hit in LiteRegex(patterns[0]).searchAll(hay)) {
                printCapture(hit.pattern, hit.captures, hay)
            }
        } else if (engine == "regex") {
            if (patterns.size != 1) {
                eprintln("the top-level regex engine accepts one pattern")
                return 1
            }
            let re = Regex(patterns[0])
            for (caps in re.capturesAll(hay)) {
                printCapture(0, caps, hay)
            }
        } else {
            eprintln("unrecognized command '${engine}'")
            return 1
        }
        0
    } catch (e: RegexError) {
        eprintln(e.toString())
        1
    } catch (e: Exception) {
        eprintln(plainException(e))
        1
    }
}

func runCliWhich(args: Array<String>): Int64 {
    try {
        let (engine, patterns, hay) = parseQuery(args)
        let flags = Array<Bool>(patterns.size, repeat: false)
        if (engine == "pikevm" || engine == "meta") {
            for (id in PikeVM(patterns).whichOverlapping(hay)) {
                if (id >= 0 && id < flags.size) {
                    flags[id] = true
                }
            }
        } else if (engine == "hybrid") {
            for (i in 0..patterns.size) {
                match (HybridDfa(patterns[i]).search(hay)) {
                    case Some(_) => flags[i] = true
                    case None => ()
                }
            }
        } else if (engine == "dense" || engine == "sparse") {
            let halves = if (engine == "sparse") {
                SparseDfa.overlap(patterns).searchOverlapping(hay)
            } else {
                DenseDfa.overlap(patterns).searchOverlapping(hay)
            }
            for (hit in halves) {
                if (hit.pattern >= 0 && hit.pattern < flags.size) {
                    flags[hit.pattern] = true
                }
            }
        } else {
            eprintln("unrecognized command '${engine}'")
            return 1
        }
        for (i in 0..flags.size) {
            println("${i}:${flags[i]}")
        }
        0
    } catch (e: Exception) {
        eprintln(plainException(e))
        1
    }
}

func runCliFind(args: Array<String>): Int64 {
    let engine = args[1]
    if (engine != "pikevm" && engine != "backtrack" && engine != "onepass" && engine != "meta" && engine != "lite" &&
        engine != "dense" && engine != "sparse" && engine != "hybrid" && engine != "regex") {
        eprintln("unrecognized command '${engine}'")
        return 1
    }
    let patterns = ArrayList<String>()
    var hay = ""
    var haveHay = false
    var table = false
    var index: Int64 = 2
    while (index < args.size) {
        if (args[index] == "--table") {
            table = true
            index += 1
        } else if (args[index] == "-p" && index + 1 < args.size) {
            patterns.add(args[index + 1])
            index += 2
        } else if (args[index] == "-y" && index + 1 < args.size) {
            hay = args[index + 1]
            haveHay = true
            index += 2
        } else {
            eprintln("unrecognized argument '${args[index]}'")
            return 1
        }
    }
    if (!haveHay || patterns.size == 0) {
        eprintln("missing pattern or haystack")
        return 1
    }
    let compiled = patterns.toArray()
    try {
        let started = MonoTime.now()
        var matchCount: Int64 = 0
        if (engine == "pikevm") {
            matchCount = printPikeFind(compiled, hay)
        } else if (engine == "backtrack") {
            matchCount = printBacktrackFind(BoundedBacktracker(compiled), hay)
        } else if (engine == "onepass") {
            let built = OnePass(compiled)
            if (built.engineName.size >= 0) {
                eprintln("unanchored searches are not supported or enabled")
                return 1
            }
        } else if (engine == "meta") {
            matchCount = printPikeMatches(MetaRegex(compiled).searchAll(hay), hay)
        } else if (engine == "lite") {
            if (compiled.size != 1) {
                eprintln("regex-lite accepts one pattern")
                return 1
            }
            matchCount = printPikeMatches(LiteRegex(compiled[0]).searchAll(hay), hay)
        } else if (engine == "dense") {
            matchCount = printDenseFind(compiled, hay)
        } else if (engine == "sparse") {
            matchCount = printSparseFind(compiled, hay)
        } else if (engine == "hybrid") {
            matchCount = printHybridFind(compiled, hay)
        } else if (engine == "regex") {
            if (compiled.size != 1) {
                eprintln("the top-level regex engine accepts one pattern")
                return 1
            }
            matchCount = printRegexFind(compiled, hay)
        } else {
            eprintln("unrecognized command '${engine}'")
            return 1
        }
        if (table) {
            let elapsed = (MonoTime.now() - started).toNanoseconds()
            println("search time:\t${elapsed}ns")
            println("total matches:\t${matchCount}")
        }
        return 0
    } catch (e: RegexError) {
        eprintln(e.toString())
        return 1
    } catch (e: Exception) {
        eprintln(plainException(e))
        return 1
    }
}

func printPikeMatches(matches: Array<PikeMatch>, text: String): Int64 {
    for (hit in matches) {
        let piece = text[hit.start()..hit.end()]
        println("${hit.pattern}:${hit.start()}:${hit.end()}:${escapeCliText(piece)}")
    }
    matches.size
}

func printGroupInfo(len: Int64, staticLen: Option<Int64>, names: Array<Option<String>>): Unit {
    println("len\t${len}")
    match (staticLen) {
        case Some(count) => println("static\tsome\t${count}")
        case None => println("static\tnone")
    }
    for (i in 0..names.size) {
        match (names[i]) {
            case Some(name) => println("name\t${i}\t${hexText(name)}")
            case None => println("name\t${i}\t-")
        }
    }
}

func hexText(text: String): String {
    let result = StringBuilder()
    for (byte in text.toArray()) {
        let value = Int64(byte)
        for (nibble in [value / 16, value % 16]) {
            result.append(Rune(UInt32(if (nibble < 10) {
                nibble + 48
            } else {
                nibble + 87
            })))
        }
    }
    return result.toString()
}

func printCaptureValue(prefix: String, value: Option<RegexMatch>): Unit {
    match (value) {
        case Some(m) => println("${prefix}\t${m.start}\t${m.end}\t${hexText(m.text)}")
        case None => println("${prefix}\t-")
    }
}

func utf8Text(bytes: Array<UInt8>): String {
    let result = StringBuilder()
    var i: Int64 = 0
    while (i < bytes.size) {
        let b0 = Int64(bytes[i])
        var value: Int64 = 0
        var width: Int64 = 1
        if (b0 < 0x80) {
            value = b0
        } else if (b0 < 0xE0) {
            width = 2
            value = b0 & 0x1F
        } else if (b0 < 0xF0) {
            width = 3
            value = b0 & 0x0F
        } else if (b0 < 0xF8) {
            width = 4
            value = b0 & 0x07
        } else {
            throw Exception("haystack is not valid UTF-8")
        }
        if (i + width > bytes.size) {
            throw Exception("haystack is not valid UTF-8")
        }
        var j: Int64 = 1
        while (j < width) {
            let next = Int64(bytes[i + j])
            if (next < 0x80 || next > 0xBF) {
                throw Exception("haystack is not valid UTF-8")
            }
            value = value * 64 + (next & 0x3F)
            j++
        }
        let minimum = if (width == 2) {
            0x80
        } else if (width == 3) {
            0x800
        } else if (width == 4) {
            0x10000
        } else {
            0
        }
        if (value < minimum || value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
            throw Exception("haystack is not valid UTF-8")
        }
        result.append(Rune(UInt32(value)))
        i += width
    }
    return result.toString()
}

func cappedCount(size: Int64, limit: Int64): Int64 {
    if (limit < 0 || limit > size) {
        return size
    }
    limit
}

func runSuite(api: String, op: String, unicodeOn: Bool, casei: Bool, term: Rune, limit: Int64, hay: Array<UInt8>,
    patterns: Array<String>): Unit {
    if (api == "string") {
        let text = utf8Text(hay)
        var builder = RegexBuilder(patterns[0])
        builder = builder.unicode(unicodeOn)
        builder = builder.caseInsensitive(casei)
        builder = builder.lineTerminator(term)
        let regex = builder.build()
        if (op == "is-match") {
            println(regex.isMatch(text))
        } else if (op == "find") {
            let found = regex.findAll(text)
            for (i in 0..cappedCount(found.size, limit)) {
                let m = found[i]
                println("${m.start}\t${m.end}\t${hexText(m.text)}")
            }
        } else if (op == "captures") {
            println("groups\t${regex.capturesLen()}")
            let names = regex.captureNames()
            for (i in 0..names.size) {
                match (names[i]) {
                    case Some(name) => println("name\t${i}\t${hexText(name)}")
                    case None => ()
                }
            }
            let found = regex.capturesAll(text)
            for (i in 0..cappedCount(found.size, limit)) {
                println("match")
                let caps = found[i]
                for (g in 0..caps.size) {
                    match (caps.get(g)) {
                        case Some(m) => println("group\t${g}\t${m.start}\t${m.end}\t${hexText(m.text)}")
                        case None => println("group\t${g}\t-")
                    }
                }
            }
        } else {
            throw Exception("unknown suite operation")
        }
        return
    }
    if (api == "bytes") {
        var builder = BytesRegexBuilder(patterns[0])
        builder = builder.unicode(unicodeOn)
        builder = builder.caseInsensitive(casei)
        builder = builder.lineTerminator(term)
        let regex = builder.build()
        if (op == "is-match") {
            println(regex.isMatch(hay))
        } else if (op == "find") {
            let found = regex.findAll(hay)
            for (i in 0..cappedCount(found.size, limit)) {
                let m = found[i]
                println("${m.start}\t${m.end}\t${hexBytes(m.bytes)}")
            }
        } else if (op == "captures") {
            println("groups\t${regex.capturesLen()}")
            let names = regex.captureNames()
            for (i in 0..names.size) {
                match (names[i]) {
                    case Some(name) => println("name\t${i}\t${hexText(name)}")
                    case None => ()
                }
            }
            let found = regex.capturesAll(hay)
            for (i in 0..cappedCount(found.size, limit)) {
                println("match")
                let caps = found[i]
                for (g in 0..caps.size) {
                    match (caps.get(g)) {
                        case Some(m) => println("group\t${g}\t${m.start}\t${m.end}\t${hexBytes(m.bytes)}")
                        case None => println("group\t${g}\t-")
                    }
                }
            }
        } else {
            throw Exception("unknown suite operation")
        }
        return
    }
    if (api == "string-set") {
        let text = utf8Text(hay)
        var builder = RegexSetBuilder()
        builder = builder.unicode(unicodeOn)
        builder = builder.caseInsensitive(casei)
        builder = builder.lineTerminator(term)
        for (i in 0..patterns.size) {
            builder = builder.pattern(patterns[i])
        }
        let set = builder.build()
        if (op == "is-match") {
            println(set.isMatch(text))
        } else if (op == "which") {
            let result = set.matches(text)
            println("patterns\t${result.len()}")
            println("any\t${result.matchedAny()}")
            println("all\t${result.matchedAll()}")
            for (id in result.indices()) {
                println("hit\t${id}")
            }
        } else {
            throw Exception("unknown suite operation")
        }
        return
    }
    if (api == "bytes-set") {
        var builder = BytesRegexSetBuilder()
        builder = builder.unicode(unicodeOn)
        builder = builder.caseInsensitive(casei)
        builder = builder.lineTerminator(term)
        for (i in 0..patterns.size) {
            builder = builder.pattern(patterns[i])
        }
        let set = builder.build()
        if (op == "is-match") {
            println(set.isMatch(hay))
        } else if (op == "which") {
            let result = set.matches(hay)
            println("patterns\t${result.len()}")
            println("any\t${result.matchedAny()}")
            println("all\t${result.matchedAll()}")
            for (id in result.indices()) {
                println("hit\t${id}")
            }
        } else {
            throw Exception("unknown suite operation")
        }
        return
    }
    throw Exception("unknown suite api")
}

func printCaptureResult(regex: Regex, caps: Captures): Unit {
    println("match")
    for (i in 0..caps.size) {
        printCaptureValue("group\t${i}", caps.get(i))
    }
    let names = regex.captureNames()
    for (name in names) {
        match (name) {
            case Some(value) => printCaptureValue("named\t${hexText(value)}", caps.name(value))
            case None => ()
        }
    }
}

main(args: Array<String>): Int64 {
    try {
        if (args.size == 1 && args[0] == "hir-constructors") {
            hirConstructorAudit()
            return 0
        }
        if (args.size == 3 && args[0] == "hir") {
            println(hirShape(Hir.parse(args[1], args[2] == "true")))
            return 0
        }
        if (args.size == 3 && args[0] == "demo") {
            let ast = Ast.parse(args[1])
            println("ast\t${ast.shape()}")
            println("hir\t${hirShape(ast.toHir())}")
            println("print\t${ast.toPattern()}")
            match (PikeVM(args[1]).search(args[2])) {
                case None => println("match\tnone")
                case Some(hit) =>
                    println("match\t${hit.pattern}\t${hit.start()}\t${hit.end()}")
                    for (i in 0..hit.captures.size) {
                        match (hit.captures.get(i)) {
                            case Some(group) => println("group\t${i}\t${group.start}\t${group.end}\t${group.asStr()}")
                            case None => println("group\t${i}\t-")
                        }
                    }
            }
            return 0
        }
        if (args.size == 2 && args[0] == "syntax-error") {
            try {
                Regex(args[1])
                println("ok")
            } catch (e: RegexError) {
                println(e.structure())
            }
            return 0
        }
        if (args.size == 2 && args[0] == "ast-octal") {
            let parser = SyntaxParser()
            parser.octal = true
            let ast = parser.parseAst(args[1])
            println(ast.shape())
            println(ast.toPattern())
            try {
                println(hirShape(parser.translate(ast)))
            } catch (e: RegexError) {
                println(e.structure())
            }
            return 0
        }
        if (args.size == 2 && args[0] == "ast") {
            println(Ast.parse(args[1]).shape())
            return 0
        }
        if (args.size == 3 && args[0] == "ast-translate") {
            let ast = Ast.parse(args[1])
            let parser = SyntaxParser()
            parser.utf8 = args[2] == "true"
            try {
                println(hirShape(parser.translate(ast)))
            } catch (e: RegexError) {
                println(e.structure())
            }
            return 0
        }
        if (args.size == 2 && args[0] == "ast-hir") {
            println(hirShape(Ast.parse(args[1]).toHir()))
            return 0
        }
        if (args.size == 2 && args[0] == "ast-print") {
            println(Ast.parse(args[1]).toPattern())
            return 0
        }
        if (args.size == 3 && args[0] == "hir-props") {
            println(hirPropertyLine(Hir.parse(args[1], args[2] == "true")))
            return 0
        }
        if (args.size == 3 && args[0] == "hir-print") {
            println(Hir.parse(args[1], args[2] == "true").toPattern())
            return 0
        }
        if (args.size >= 2 && args[0] == "cli-find") {
            return runCliFind(args)
        }
        if (args.size >= 2 && args[0] == "cli-half") {
            return runCliHalf(args)
        }
        if (args.size >= 2 && args[0] == "cli-capture") {
            return runCliCapture(args)
        }
        if (args.size >= 2 && args[0] == "cli-which") {
            return runCliWhich(args)
        }
        if (args.size == 3 && args[0] == "memory") {
            return runMemory(args[1], args[2])
        }
        if (args.size == 3 && args[0] == "dfa-budget") {
            return runDfaBudget(args[1], args[2])
        }
        if (args.size == 3 && args[0] == "nfa-rev") {
            match (ReverseNfa(args[1]).search(args[2])) {
                case Some(offset) => println("offset\t${offset}")
                case None => println("none")
            }
            return 0
        }
        if (args.size == 1 && args[0] == "nfa-rev-empty") {
            match (ReverseNfa(Array<String>()).search("ab")) {
                case Some(offset) => println("offset\t${offset}")
                case None => println("none")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "nfa-rev-limit") {
            try {
                let graph = ReverseNfa([args[2]], false, Int64.parse(args[1]))
                match (graph.search("")) {
                    case Some(_) => println("ok")
                    case None => println("ok")
                }
            } catch (e: RegexError) {
                println("error\t${e}")
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "nfa-build") {
            try {
                let hir = Hir.parse(args[2])
                let graph = ThompsonNfa([hir], Int64.parse(args[1]))
                if (graph.patternCount() < 0) {
                    println("error")
                } else {
                    println("ok")
                }
            } catch (e: RegexError) {
                println("${kindName(e.errorKind)}\t${e.phase}\t${e}")
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "onepass") {
            try {
                match (OnePass(args[1]).search(args[2])) {
                    case Some(hit) => println("span\t${hit.start()}\t${hit.end()}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "meta") {
            try {
                let engine = MetaRegex(args[1])
                match (engine.search(args[2])) {
                    case Some(hit) => println("span\t${hit.start()}\t${hit.end()}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "lite") {
            try {
                match (LiteRegex(args[1]).search(args[2])) {
                    case Some(hit) => println("span\t${hit.start()}\t${hit.end()}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "rure") {
            try {
                let set = Rure(args[1])
                println("is-match\t${set.isMatch(args[2])}")
                match (set.find(args[2])) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "dfa-image") {
            try {
                let image = DenseDfa(args[1]).toImage()
                match (DenseDfa.fromImage(image).search(args[2])) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 1 && args[0] == "dfa-image-bad") {
            try {
                let loaded = DenseDfa.fromImage([UInt8(1), UInt8(2), UInt8(3)])
                println("states\t${loaded.stateCount()}")
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 6 && args[0] == "nfa-rev-many") {
            let patterns = Array<String>(args.size - 5, {i => args[i + 5]})
            let query = searchQuery(args[4], Int64.parse(args[1]), Int64.parse(args[2]), args[3], false)
            try {
                match (ReverseNfa(patterns, true).find(query)) {
                    case Some(hit) => println("pattern\t${hit.pattern}\toffset\t${hit.offset}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 6 && args[0] == "nfa-rev-query") {
            let query = searchQuery(args[5], Int64.parse(args[1]), Int64.parse(args[2]), args[3], false)
            try {
                match (ReverseNfa(args[4]).search(query)) {
                    case Some(offset) => println("offset\t${offset}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "literals") {
            if (args[1] != "prefix" && args[1] != "suffix") {
                throw Exception("literal kind must be prefix or suffix")
            }
            println(formatLiterals(Hir.parse(args[2]), args[1] == "suffix"))
            return 0
        }
        if (args.size == 7 && args[0] == "literals-config") {
            if (args[5] != "prefix" && args[5] != "suffix") {
                throw Exception("literal kind must be prefix or suffix")
            }
            let limits = LiteralLimits(Int64.parse(args[1]), Int64.parse(args[2]), Int64.parse(args[3]),
                Int64.parse(args[4]))
            println(formatLiterals(Hir.parse(args[6]), args[5] == "suffix", limits))
            return 0
        }
        if (args.size >= 3 && args[0] == "literal-op") {
            return runLiteralOp(args)
        }
        if (args.size == 3 && args[0] == "utf8") {
            println(utf8SequenceLines(Int64.parse(args[1]), Int64.parse(args[2])))
            return 0
        }
        if (args.size >= 7 && args[0] == "pike-overlap-query") {
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let query = searchQuery(args[5], Int64.parse(args[1]), Int64.parse(args[2]), args[3], args[4] == "true")
            let ids = PikeVM(patterns).whichOverlapping(query)
            println("count\t${ids.size}")
            for (id in ids) {
                println("id\t${id}")
            }
            return 0
        }
        if (args.size >= 4 && args[0] == "pike-captures") {
            let mode = captureMode(args[1])
            let patterns = Array<String>(args.size - 3, {i => args[i + 3]})
            let engine = PikeVM(patterns, mode)
            let query = SearchInput(args[2])
            let matched = engine.isMatch(query)
            println("is-match\t${matched}")
            match (engine.search(query)) {
                case Some(hit) => printPikeMatch(hit)
                case None => println("none")
            }
            return 0
        }
        if (args.size >= 3 && args[0] == "pike-overlap") {
            let patterns = Array<String>(args.size - 2, {i => args[i + 2]})
            let ids = PikeVM(patterns).whichOverlapping(args[1])
            println("count\t${ids.size}")
            for (id in ids) {
                println("id\t${id}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "hybrid-reset") {
            let engine = HybridDfa(args[2])
            for (_ in 0..2) {
                match (engine.search(args[1])) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
                engine.reset()
            }
            return 0
        }
        if (args.size == 5 && args[0] == "hybrid-small") {
            try {
                let engine = HybridDfa([args[4]], Int64.parse(args[1]), Int64.parse(args[2]))
                match (engine.search(args[3])) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 7 && args[0] == "hybrid-many") {
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let query = searchQuery(args[5], Int64.parse(args[1]), Int64.parse(args[2]), args[3], args[4] == "true")
            try {
                match (HybridDfa(patterns, 8192, -1).search(query)) {
                    case Some(hit) => println("pattern\t${hit.pattern}\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 7 && args[0] == "hybrid-pattern") {
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let query = searchQuery(args[5], Int64.parse(args[1]), Int64.parse(args[2]), args[3], args[4] == "true")
            try {
                match (HybridDfa(patterns, 8192, -1, true).search(query)) {
                    case Some(hit) => println("pattern\t${hit.pattern}\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 8 && args[0] == "hybrid") {
            let quit = parseHexBytes(args[1])
            let query = searchQuery(args[6], Int64.parse(args[2]), Int64.parse(args[3]), args[4], args[5] == "true")
            try {
                match (HybridDfa(args[7], quit).search(query)) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 7 && args[0] == "dfa-overlap") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let query = searchQuery(args[5], Int64.parse(args[2]), Int64.parse(args[3]), args[4], false)
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa.overlap(patterns).searchOverlapping(query)
                } else {
                    SparseDfa.overlap(patterns).searchOverlapping(query)
                }
                println("count\t${found.size}")
                for (hit in found) {
                    println("half\t${hit.pattern}\t${hit.end}")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 8 && args[0] == "dfa-pattern") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 7, {i => args[i + 7]})
            let query = searchQuery(args[6], Int64.parse(args[2]), Int64.parse(args[3]), args[4], args[5] == "true")
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(patterns, Array<UInt8>(), false, true).search(query)
                } else {
                    SparseDfa(patterns, Array<UInt8>(), false, true).search(query)
                }
                match (found) {
                    case Some(hit) => println("pattern\t${hit.pattern}\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 7 && args[0] == "dfa-pattern-overlap") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let query = searchQuery(args[5], Int64.parse(args[2]), Int64.parse(args[3]), args[4], false)
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(patterns, Array<UInt8>(), true, true).searchOverlapping(query)
                } else {
                    SparseDfa(patterns, Array<UInt8>(), true, true).searchOverlapping(query)
                }
                println("count\t${found.size}")
                for (hit in found) {
                    println("half\t${hit.pattern}\t${hit.end}")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 8 && args[0] == "dfa-many") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 7, {i => args[i + 7]})
            let query = searchQuery(args[6], Int64.parse(args[2]), Int64.parse(args[3]), args[4], args[5] == "true")
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(patterns).search(query)
                } else {
                    SparseDfa(patterns).search(query)
                }
                match (found) {
                    case Some(hit) => println("pattern\t${hit.pattern}\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 9 && args[0] == "dfa-query") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let quit = parseHexBytes(args[2])
            let query = searchQuery(args[8], Int64.parse(args[3]), Int64.parse(args[4]), args[5], args[6] == "true")
            try {
                let engineQuit = quit
                let found = if (args[1] == "dense") {
                    DenseDfa(args[7], engineQuit).search(query)
                } else {
                    SparseDfa(args[7], engineQuit).search(query)
                }
                match (found) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "dfa-bytes") {
            if (args[1] != "dense" && args[1] != "sparse" && args[1] != "hybrid") {
                throw Exception("dfa kind must be dense, sparse, or hybrid")
            }
            let query = SearchInput(parseHex(args[2]))
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(args[3]).search(query)
                } else if (args[1] == "sparse") {
                    SparseDfa(args[3]).search(query)
                } else {
                    HybridDfa(args[3]).search(query)
                }
                match (found) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 5 && args[0] == "dfa-bytes-quit") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let query = SearchInput(parseHex(args[3]))
            let quit = parseHexBytes(args[2])
            try {
                let engineQuit = quit
                let found = if (args[1] == "dense") {
                    DenseDfa(args[4], engineQuit).search(query)
                } else {
                    SparseDfa(args[4], engineQuit).search(query)
                }
                match (found) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 5 && args[0] == "dfa-bytes-pattern") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 4, {i => args[i + 4]})
            let query = SearchInput(parseHex(args[2])).selectPattern(Int64.parse(args[3]))
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(patterns, Array<UInt8>(), false, true).search(query)
                } else {
                    SparseDfa(patterns, Array<UInt8>(), false, true).search(query)
                }
                match (found) {
                    case Some(hit) => println("pattern\t${hit.pattern}\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 4 && args[0] == "dfa-bytes-many") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 3, {i => args[i + 3]})
            let query = SearchInput(parseHex(args[2]))
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(patterns).search(query)
                } else {
                    SparseDfa(patterns).search(query)
                }
                match (found) {
                    case Some(hit) => println("pattern\t${hit.pattern}\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 4 && args[0] == "dfa-bytes-overlap") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            let patterns = Array<String>(args.size - 3, {i => args[i + 3]})
            let query = SearchInput(parseHex(args[2]))
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa.overlap(patterns).searchOverlapping(query)
                } else {
                    SparseDfa.overlap(patterns).searchOverlapping(query)
                }
                println("count\t${found.size}")
                for (hit in found) {
                    println("half\t${hit.pattern}\t${hit.end}")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "dfa") {
            if (args[1] != "dense" && args[1] != "sparse") {
                throw Exception("dfa kind must be dense or sparse")
            }
            try {
                let found = if (args[1] == "dense") {
                    DenseDfa(args[2]).search(args[3])
                } else {
                    SparseDfa(args[2]).search(args[3])
                }
                match (found) {
                    case Some(hit) => println("span\t${hit.start}\t${hit.end}")
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 5 && args[0] == "backtrack-captures") {
            let mode = captureMode(args[2])
            let patterns = Array<String>(args.size - 4, {i => args[i + 4]})
            let engine = if (args[1] == "default") {
                BoundedBacktracker(patterns, 256 * 1024, mode)
            } else {
                BoundedBacktracker(patterns, Int64.parse(args[1]), mode)
            }
            let query = SearchInput(args[3])
            let matched = engine.isMatch(query)
            println("is-match\t${matched}")
            match (engine.search(engine.createCache(), query)) {
                case Some(hit) => printPikeMatch(hit)
                case None => println("none")
            }
            return 0
        }
        if (args.size >= 6 && args[0] == "backtrack-iter-span") {
            let patterns = Array<String>(args.size - 5, {i => args[i + 5]})
            let engine = if (args[1] == "default") {
                BoundedBacktracker(patterns)
            } else {
                BoundedBacktracker(patterns, Int64.parse(args[1]))
            }
            let query = SearchInput(args[4]).span(Int64.parse(args[2]), Int64.parse(args[3]))
            try {
                for (hit in engine.searchAll(query)) {
                    let piece = args[4][hit.start()..hit.end()]
                    println("${hit.pattern}:${hit.start()}:${hit.end()}:${escapeCliText(piece)}")
                }
            } catch (e: Exception) {
                let message = plainException(e)
                if (message.startsWith("haystack of length ") || message.startsWith("visited capacity")) {
                    println("error\t${message}")
                    return 0
                }
                throw e
            }
            return 0
        }
        if (args.size >= 4 && args[0] == "backtrack-iter") {
            let patterns = Array<String>(args.size - 3, {i => args[i + 3]})
            let engine = if (args[1] == "default") {
                BoundedBacktracker(patterns)
            } else {
                BoundedBacktracker(patterns, Int64.parse(args[1]))
            }
            printBacktrackFind(engine, args[2])
            return 0
        }
        if (args.size == 3 && args[0] == "backtrack-info") {
            let engine = if (args[1] == "default") {
                BoundedBacktracker(args[2])
            } else {
                BoundedBacktracker(args[2], Int64.parse(args[1]))
            }
            println("states\t${engine.stateCount()}")
            println("max\t${engine.maxHaystackLen()}")
            return 0
        }
        if (args.size >= 7 && args[0] == "backtrack-bytes") {
            let bytes = parseHex(args[5])
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let engine = if (args[1] == "default") {
                BoundedBacktracker(patterns)
            } else {
                BoundedBacktracker(patterns, Int64.parse(args[1]))
            }
            let query = byteQuery(bytes, Int64.parse(args[2]), Int64.parse(args[3]), args[4], false)
            try {
                match (engine.search(engine.createCache(), query)) {
                    case Some(hit) => printByteMatch(hit, bytes)
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size == 8 && args[0] == "backtrack-query") {
            let engine = if (args[1] == "default") {
                BoundedBacktracker(args[7])
            } else {
                BoundedBacktracker(args[7], Int64.parse(args[1]))
            }
            let query = searchQuery(args[6], Int64.parse(args[2]), Int64.parse(args[3]), args[4], args[5] == "true")
            try {
                match (engine.search(engine.createCache(), query)) {
                    case None => println("none")
                    case Some(hit) => printPikeMatch(hit)
                }
            } catch (e: Exception) {
                let text = plainException(e)
                if (!text.startsWith("haystack of length ")) {
                    throw e
                }
                println("error\t${text}")
            }
            return 0
        }
        if (args.size >= 8 && args[0] == "backtrack-many") {
            let patterns = Array<String>(args.size - 7, {i => args[i + 7]})
            let engine = if (args[1] == "default") {
                BoundedBacktracker(patterns)
            } else {
                BoundedBacktracker(patterns, Int64.parse(args[1]))
            }
            let query = searchQuery(args[6], Int64.parse(args[2]), Int64.parse(args[3]), args[4], args[5] == "true")
            try {
                match (engine.search(engine.createCache(), query)) {
                    case None => println("none")
                    case Some(hit) => printPikeMatch(hit)
                }
            } catch (e: Exception) {
                let text = plainException(e)
                if (!text.startsWith("haystack of length ")) {
                    throw e
                }
                println("error\t${text}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "backtrack") {
            let engine = if (args[1] == "default") {
                BoundedBacktracker(args[2])
            } else {
                BoundedBacktracker(args[2], Int64.parse(args[1]))
            }
            try {
                match (engine.search(args[3])) {
                    case None => println("none")
                    case Some(caps) => printBacktrack(caps)
                }
            } catch (e: Exception) {
                let text = plainException(e)
                if (!text.startsWith("haystack of length ")) {
                    throw e
                }
                println("error\t${text}")
            }
            return 0
        }
        if (args.size >= 3 && args[0] == "pike-earliest") {
            let patterns = Array<String>(args.size - 2, {i => args[i + 2]})
            match (PikeVM(patterns).searchEarliest(args[1])) {
                case None => println("none")
                case Some(hit) =>
                    println("pattern\t${hit.pattern}")
                    println("span\t${hit.start()}\t${hit.end()}")
                    for (i in 0..hit.captures.size) {
                        match (hit.captures.get(i)) {
                            case Some(group) => println(
                                "group\t${i}\t${group.start}\t${group.end}\t${hexText(group.asStr())}")
                            case None => println("group\t${i}\t-")
                        }
                    }
            }
            return 0
        }
        if (args.size >= 6 && args[0] == "pike-bytes") {
            let bytes = parseHex(args[4])
            let patterns = Array<String>(args.size - 5, {i => args[i + 5]})
            try {
                let query = byteQuery(bytes, Int64.parse(args[1]), Int64.parse(args[2]), args[3], false)
                match (PikeVM(patterns).search(query)) {
                    case Some(hit) => printByteMatch(hit, bytes)
                    case None => println("none")
                }
            } catch (e: Exception) {
                println("error\t${plainException(e)}")
            }
            return 0
        }
        if (args.size >= 6 && args[0] == "pike-config") {
            let patterns = Array<String>(args.size - 6, {i => args[i + 6]})
            let query = searchQuery(args[5], Int64.parse(args[1]), Int64.parse(args[2]), args[3], args[4] == "true")
            match (PikeVM(patterns).search(query)) {
                case None => println("none")
                case Some(hit) => printPikeMatch(hit)
            }
            return 0
        }
        if (args.size >= 5 && (args[0] == "pike" || args[0] == "pike-hir")) {
            let start = Int64.parse(args[1])
            let end = Int64.parse(args[2])
            let vm = if (args[0] == "pike-hir") {
                let hirs = Array<Hir>(args.size - 5, {i => Hir.parse(args[i + 5])})
                PikeVM(hirs)
            } else {
                let patterns = Array<String>(args.size - 5, {i => args[i + 5]})
                PikeVM(patterns)
            }
            match (vm.search(args[4], start, end, args[3] == "true")) {
                case None => println("none")
                case Some(hit) =>
                    println("pattern\t${hit.pattern}")
                    println("span\t${hit.start()}\t${hit.end()}")
                    for (i in 0..hit.captures.size) {
                        match (hit.captures.get(i)) {
                            case Some(group) => println(
                                "group\t${i}\t${group.start}\t${group.end}\t${hexText(group.asStr())}")
                            case None => println("group\t${i}\t-")
                        }
                    }
            }
            return 0
        }
        if (args.size == 1 && args[0] == "api-audit") {
            apiContractAudit()
            return 0
        }
        // Set protocol: TEXT followed by zero or more PATTERN arguments.
        if (args.size >= 3 && (args[0] == "set-matches-at" || args[0] == "set-is-match-at")) {
            let patterns = Array<String>(args.size - 3, {i => args[i + 3]})
            let set = RegexSet(patterns)
            let start = Int64.parse(args[2])
            if (args[0] == "set-is-match-at") {
                println(set.isMatchAt(args[1], start))
            } else {
                let result = set.matchesAt(args[1], start)
                println("patterns\t${result.len()}")
                println("any\t${result.matchedAny()}")
                println("all\t${result.matchedAll()}")
                for (id in result.indices()) {
                    println("hit\t${id}")
                }
            }
            return 0
        }
        if (args.size >= 2 && (args[0] == "set-matches" || args[0] == "set-is-match")) {
            let patterns = Array<String>(args.size - 2, {i => args[i + 2]})
            let set = RegexSet(patterns)
            if (args[0] == "set-is-match") {
                println(set.isMatch(args[1]))
            } else {
                let result = set.matches(args[1])
                println("patterns\t${result.len()}")
                println("any\t${result.matchedAny()}")
                println("all\t${result.matchedAll()}")
                for (id in result.indices()) {
                    println("hit\t${id}")
                }
            }
            return 0
        }
        if (args.size == 2 && args[0] == "escape") {
            println(escape(args[1]))
            return 0
        }
        if (args.size == 3 && args[0] == "find") {
            let regex = Regex(args[1])
            for (m in regex.findAll(args[2])) {
                println("${m.start}\t${m.end}\t${m.text}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "repeat-find") {
            let times = Int64.parse(args[3])
            if (times < 1) {
                throw Exception("repeat count must be positive")
            }
            let beforeCompile = MonoTime.now()
            let regex = Regex(args[1])
            let afterCompile = MonoTime.now()
            var line = ""
            let beforeSearch = MonoTime.now()
            for (_ in 0..times) {
                match (regex.find(args[2])) {
                    case Some(m) => line = "${m.start}\t${m.end}\t${m.text}"
                    case None => line = ""
                }
            }
            let afterSearch = MonoTime.now()
            if (!line.isEmpty()) {
                println(line)
            }
            println("compile_ns\t${(afterCompile - beforeCompile).toNanoseconds()}")
            println("search_ns\t${(afterSearch - beforeSearch).toNanoseconds()}")
            println("repeats\t${times}")
            return 0
        }
        if (args.size == 3 && args[0] == "first") {
            match (Regex(args[1]).find(args[2])) {
                case Some(m) => println("${m.start}\t${m.end}\t${m.text}")
                case None => ()
            }
            return 0
        }
        if (args.size == 3 && args[0] == "is-match") {
            println(Regex(args[1]).isMatch(args[2]))
            return 0
        }
        if (args.size == 4 && (args[0] == "find-at" || args[0] == "is-match-at" || args[0] == "shortest-at")) {
            let regex = Regex(args[1])
            let start = Int64.parse(args[3])
            if (args[0] == "is-match-at") {
                println(regex.isMatchAt(args[2], start))
            } else if (args[0] == "shortest-at") {
                match (regex.shortestMatchAt(args[2], start)) {
                    case Some(end) => println(end)
                    case None => ()
                }
            } else {
                match (regex.findAt(args[2], start)) {
                    case Some(m) => println("${m.start}\t${m.end}\t${m.text}")
                    case None => ()
                }
            }
            return 0
        }
        if (args.size == 3 && args[0] == "shortest") {
            match (Regex(args[1]).shortestMatch(args[2])) {
                case Some(end) => println(end)
                case None => ()
            }
            return 0
        }
        if (args.size == 2 && args[0] == "static-len") {
            match (Regex(args[1]).staticCapturesLen()) {
                case Some(count) => println("some\t${count}")
                case None => println("none")
            }
            return 0
        }
        if (args.size == 2 && args[0] == "group-info") {
            let regex = Regex(args[1])
            printGroupInfo(regex.capturesLen(), regex.staticCapturesLen(), regex.captureNames())
            return 0
        }
        if (args.size == 2 && args[0] == "bytes-group-info") {
            let regex = BytesRegex(args[1])
            printGroupInfo(regex.capturesLen(), regex.staticCapturesLen(), regex.captureNames())
            return 0
        }
        if (args.size == 4 && args[0] == "captures-at") {
            let regex = Regex(args[1])
            println("groups\t${regex.capturesLen()}")
            match (regex.capturesAt(args[2], Int64.parse(args[3]))) {
                case Some(caps) => printCaptureResult(regex, caps)
                case None => ()
            }
            return 0
        }
        if (args.size == 3 && args[0] == "octal-find") {
            let regex = RegexBuilder(args[1]).octal(true).build()
            for (m in regex.findAll(args[2])) {
                println("${m.start}\t${m.end}\t${m.text}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "nest-find") {
            let regex = RegexBuilder(args[2]).nestLimit(Int64.parse(args[1])).build()
            for (m in regex.findAll(args[3])) {
                println("${m.start}\t${m.end}\t${m.text}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "limit-find") {
            let regex = RegexBuilder(args[2]).sizeLimit(Int64.parse(args[1])).build()
            for (m in regex.findAll(args[3])) {
                println("${m.start}\t${m.end}\t${m.text}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "dfa-find") {
            let regex = RegexBuilder(args[2]).dfaSizeLimit(Int64.parse(args[1])).build()
            for (m in regex.findAll(args[3])) {
                println("${m.start}\t${m.end}\t${m.text}")
            }
            return 0
        }
        if (args.size >= 3 && args[0] == "set-limit") {
            var setBuilder = RegexSetBuilder().sizeLimit(Int64.parse(args[1]))
            for (i in 3..args.size) {
                setBuilder = setBuilder.pattern(args[i])
            }
            let set = setBuilder.build()
            let result = set.matches(args[2])
            println("patterns\t${result.len()}")
            println("any\t${result.matchedAny()}")
            println("all\t${result.matchedAll()}")
            for (id in result.indices()) {
                println("hit\t${id}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "bytes-find") {
            let regex = BytesRegex(args[1])
            for (m in regex.findAll(parseHex(args[2]))) {
                println("${m.start}\t${m.end}\t${hexBytes(m.bytes)}")
            }
            return 0
        }
        if (args.size == 3 && args[0] == "bytes-captures") {
            let regex = BytesRegex(args[1])
            let haystack = parseHex(args[2])
            println("groups\t${regex.capturesLen()}")
            let names = regex.captureNames()
            for (i in 0..names.size) {
                match (names[i]) {
                    case Some(name) => println("name\t${i}\t${hexText(name)}")
                    case None => ()
                }
            }
            match (regex.captures(haystack)) {
                case Some(caps) =>
                    println("match")
                    for (i in 0..caps.size) {
                        match (caps.get(i)) {
                            case Some(m) => println("group\t${i}\t${m.start}\t${m.end}\t${hexBytes(m.bytes)}")
                            case None => println("group\t${i}\t-")
                        }
                    }
                case None => ()
            }
            return 0
        }
        if (args.size == 4 && (args[0] == "bytes-replace" || args[0] == "bytes-replace-all")) {
            let regex = BytesRegex(args[1])
            let haystack = parseHex(args[2])
            let template = args[3].toArray()
            let output = if (args[0] == "bytes-replace") {
                regex.replace(haystack, template)
            } else {
                regex.replaceAll(haystack, template)
            }
            println(hexBytes(output))
            return 0
        }
        if (args.size == 3 && args[0] == "bytes-split") {
            let regex = BytesRegex(args[1])
            for (part in regex.split(parseHex(args[2]))) {
                println(hexBytes(part))
            }
            return 0
        }
        if (args.size >= 2 && args[0] == "bytes-set-matches") {
            let patterns = Array<String>(args.size - 2, {i => args[i + 2]})
            let set = BytesRegexSet(patterns)
            let result = set.matches(parseHex(args[1]))
            println("patterns\t${result.len()}")
            println("any\t${result.matchedAny()}")
            println("all\t${result.matchedAll()}")
            for (id in result.indices()) {
                println("hit\t${id}")
            }
            return 0
        }
        if (args.size == 4 && args[0] == "term-find") {
            let regex = RegexBuilder(args[2]).lineTerminator(Rune(UInt32(Int64.parse(args[1])))).build()
            for (m in regex.findAll(args[3])) {
                println("${m.start}\t${m.end}\t${m.text}")
            }
            return 0
        }
        if (args.size == 3 && (args[0] == "captures" || args[0] == "capture-first")) {
            let regex = Regex(args[1])
            var results = Array<Captures>()
            if (args[0] == "captures") {
                results = regex.capturesAll(args[2])
            } else {
                match (regex.captures(args[2])) {
                    case Some(caps) => results = [caps]
                    case None => ()
                }
            }
            println("groups\t${regex.capturesLen()}")
            let names = regex.captureNames()
            for (i in 0..names.size) {
                match (names[i]) {
                    case Some(name) => println("name\t${i}\t${hexText(name)}")
                    case None => ()
                }
            }
            for (caps in results) {
                printCaptureResult(regex, caps)
            }
            return 0
        }
        if (args.size == 4 && args[0] == "capture-name") {
            match (Regex(args[1]).captures(args[2])) {
                case Some(caps) => printCaptureValue("value", caps.name(args[3]))
                case None => printCaptureValue("value", None)
            }
            return 0
        }
        if (args.size == 3 && args[0] == "split") {
            for (part in Regex(args[1]).split(args[2])) {
                println(hexText(part))
            }
            return 0
        }
        if (args.size == 4 && args[0] == "split-n") {
            for (part in Regex(args[1]).splitN(args[2], Int64.parse(args[3]))) {
                println(hexText(part))
            }
            return 0
        }
        if (args.size == 4 && args[0] == "replace-with") {
            let calls = [0]
            let output = Regex(args[1]).replaceWith(
                args[2],
                Int64.parse(args[3]),
                {
                    caps =>
                        calls[0]++
                        "${calls[0]}:" + caps.expand("<$0>[$1]")
                }
            )
            println(hexText(output))
            println(calls[0])
            return 0
        }
        if (args.size == 4 && args[0] == "expand") {
            match (Regex(args[1]).captures(args[2])) {
                case Some(caps) => println(hexText(caps.expand(args[3])))
                case None => ()
            }
            return 0
        }
        if (args.size == 4 && (args[0] == "replace" || args[0] == "replace-all")) {
            let regex = Regex(args[1])
            let output = if (args[0] == "replace") {
                regex.replace(args[2], args[3])
            } else {
                regex.replaceAll(args[2], args[3])
            }
            println(hexText(output))
            return 0
        }
        if (args.size == 5 && (args[0] == "replace-n" || args[0] == "replace-literal")) {
            let regex = Regex(args[1])
            let limit = Int64.parse(args[4])
            let output = if (args[0] == "replace-n") {
                regex.replaceN(args[2], limit, args[3])
            } else {
                regex.replaceLiteral(args[2], limit, args[3])
            }
            println(hexText(output))
            return 0
        }
        if (args.size >= 8 && args[0] == "suite-run") {
            let unicodeOn = args[3] == "1"
            let casei = args[4] == "1"
            let term = Rune(UInt32(Int64.parse(args[5])))
            let limit = if (args[6] == "-") {
                -1
            } else {
                Int64.parse(args[6])
            }
            let hay = parseHex(args[7])
            let patterns = Array<String>(args.size - 8, {i => args[i + 8]})
            runSuite(args[1], args[2], unicodeOn, casei, term, limit, hay, patterns)
            return 0
        }
        eprintln(
            "usage: cjregex set-matches TEXT [PATTERN ...] | set-is-match TEXT [PATTERN ...] | escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | captures PATTERN TEXT | capture-first PATTERN TEXT | capture-name PATTERN TEXT NAME | split PATTERN TEXT | split-n PATTERN TEXT LIMIT | replace/replace-all/expand PATTERN TEXT TEMPLATE | replace-n/replace-literal PATTERN TEXT TEMPLATE LIMIT | replace-with PATTERN TEXT LIMIT")
        return 2
    } catch (e: Exception) {
        eprintln(e.toString())
        return 2
    }
}
