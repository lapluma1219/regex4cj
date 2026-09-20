package cjregex

// Ported from regex-syntax/src/lib.rs at 72d650cb0a880a01ab6dc2137c0888e8f89740f7.
// Upstream copyright and license: see repository-root LICENSE-MIT and LICENSE-APACHE.
public func isMetaCharacter(c: Rune): Bool {
    match (c) {
        case r'\\' | r'.' | r'+' | r'*' | r'?' | r'(' | r')' | r'|' | r'[' | r']' | r'{' | r'}' | r'^' | r'$' | r'#'
            | r'&' | r'-' | r'~' => true
        case _ => false
    }
}

public func escape(text: String): String {
    let buf = StringBuilder()
    for (c in text.runes()) {
        if (isMetaCharacter(c)) {
            buf.append(r'\\')
        }
        buf.append(c)
    }
    return buf.toString()
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
        eprintln(
            "usage: cjregex escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | captures PATTERN TEXT | capture-first PATTERN TEXT | capture-name PATTERN TEXT NAME")
        return 2
    } catch (e: Exception) {
        eprintln(e.toString())
        return 2
    }
}
