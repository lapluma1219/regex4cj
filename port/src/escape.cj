package cjregex

// Ported from regex-syntax/src/lib.rs at 72d650cb0a880a01ab6dc2137c0888e8f89740f7.
// Upstream copyright and license: see repository-root LICENSE-MIT and LICENSE-APACHE.
func isMetaCharacter(c: Rune): Bool {
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
