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
