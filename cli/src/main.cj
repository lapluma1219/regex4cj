package regex_cli

import cjregex.*
import std.convert.*
import std.time.*

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
        eprintln(
            "usage: cjregex set-matches TEXT [PATTERN ...] | set-is-match TEXT [PATTERN ...] | escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | captures PATTERN TEXT | capture-first PATTERN TEXT | capture-name PATTERN TEXT NAME | split PATTERN TEXT | split-n PATTERN TEXT LIMIT | replace/replace-all/expand PATTERN TEXT TEMPLATE | replace-n/replace-literal PATTERN TEXT TEMPLATE LIMIT | replace-with PATTERN TEXT LIMIT")
        return 2
    } catch (e: Exception) {
        eprintln(e.toString())
        return 2
    }
}
