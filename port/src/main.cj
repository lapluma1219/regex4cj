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
        eprintln("usage: cjregex escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT")
        return 2
    } catch (e: Exception) {
        eprintln(e.toString())
        return 2
    }
}
