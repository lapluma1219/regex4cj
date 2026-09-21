package cjregex

// regex-syntax symbolic_name_normalize: ASCII case/space/underscore/hyphen
// folding, initial 'is' removal and the special 'isc' alias exception.
func normalizePropertyName(text: String): String {
    let chars = Input(text).chars
    var from: Int64 = 0
    if (chars.size >= 2 && (chars[0] == r'i' || chars[0] == r'I') && (chars[1] == r's' || chars[1] == r'S')) {
        from = 2
    }
    let out = StringBuilder()
    for (i in from..chars.size) {
        let c = chars[i]
        if (UInt32(c) > 127 || c == r' ' || c == r'_' || c == r'-') {
            continue
        }
        if (c >= r'A' && c <= r'Z') {
            out.append(Rune(UInt32(c) + 32))
        } else {
            out.append(c)
        }
    }
    let result = out.toString()
    return if (from == 2 && result == "c") {
        "isc"
    } else {
        result
    }
}

func unicodeProperty(text: String, negated: Bool): CharSet {
    let chars = Input(text).chars
    // Operator precedence follows the AST parser: != before : before =.
    var notEqual: Int64 = -1
    var colon: Int64 = -1
    var equal: Int64 = -1
    for (i in 0..chars.size) {
        if (chars[i] == r'!' && i + 1 < chars.size && chars[i + 1] == r'=' && notEqual < 0) {
            notEqual = i
        }
        if (chars[i] == r':' && colon < 0) {
            colon = i
        }
        if (chars[i] == r'=' && equal < 0) {
            equal = i
        }
    }
    let split = if (notEqual >= 0) {
        notEqual
    } else if (colon >= 0) {
        colon
    } else {
        equal
    }
    var name = text
    var invert = negated
    if (split >= 0) {
        let property = StringBuilder()
        let value = StringBuilder()
        for (i in 0..split) {
            property.append(chars[i])
        }
        let start = split + if (notEqual >= 0) {
            2
        } else {
            1
        }
        for (i in start..chars.size) {
            value.append(chars[i])
        }
        let key = normalizePropertyName(property.toString())
        if (key != "gc" && key != "generalcategory") {
            throw Exception("unsupported Unicode property: " + key)
        }
        name = value.toString()
        if (notEqual >= 0) {
            invert = !invert
        }
    }
    let set = generalCategory(normalizePropertyName(name))
    return if (invert) {
        set.negated()
    } else {
        set
    }
}
