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
    if (args.size != 2 || args[0] != "escape") {
        eprintln("usage: cjregex escape TEXT")
        return 2
    }
    println(escape(args[1]))
    return 0
}
