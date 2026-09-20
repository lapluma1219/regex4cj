package cjregex

// Capture index 0 is the whole match. Unmatched groups are None; empty groups
// are Some(RegexMatch) whose start equals end. Results own their string slices.
public class Captures {
    private let groups: Array<Option<RegexMatch>>
    private let names: Array<String>
    public let size: Int64
    init(groups: Array<Option<RegexMatch>>, names: Array<String>) {
        this.groups = groups
        this.names = names
        this.size = groups.size
    }
    public func get(index: Int64): Option<RegexMatch> {
        if (index < 0 || index >= size) {
            return None
        }
        return groups[index]
    }
    public func name(value: String): Option<RegexMatch> {
        if (value == "") {
            return None
        }
        for (i in 1..names.size) {
            if (names[i] == value) {
                return groups[i]
            }
        }
        return None
    }
    // Returns expanded text; unlike Rust expand, no mutable destination is needed.
    public func expand(template: String): String {
        let chars = Input(template).chars
        let out = StringBuilder()
        var i: Int64 = 0
        while (i < chars.size) {
            if (chars[i] != r'$') {
                out.append(chars[i]);
                i++;
                continue
            }
            if (i + 1 < chars.size && chars[i + 1] == r'$') {
                out.append(r'$');
                i += 2
                continue
            }
            var begin = i + 1
            var end = begin
            let braced = begin < chars.size && chars[begin] == r'{'
            if (braced) {
                begin++;
                end = begin
                while (end < chars.size && chars[end] != r'}') {
                    end++
                }
                if (end == chars.size) {
                    out.append(r'$');
                    i++;
                    continue
                }
            } else {
                while (end < chars.size && referenceLetter(chars[end])) {
                    end++
                }
                if (end == begin) {
                    out.append(r'$');
                    i++;
                    continue
                }
            }
            let name = StringBuilder()
            for (j in begin..end) {
                name.append(chars[j])
            }
            let ref = name.toString()
            var digit = begin
            if (digit < end && chars[digit] == r'+') {
                digit++
            }
            var numeric = digit < end
            var index: Int64 = 0
            while (digit < end) {
                let c = chars[digit]
                if (c < r'0' || c > r'9') {
                    numeric = false
                    break
                }
                // Any number above the capture count is absent. Saturation
                // avoids overflow even for arbitrarily long numeric references.
                if (index <= size) {
                    index = index * 10 + Int64(UInt32(c) - 48)
                }
                digit++
            }
            let value = if (numeric) {
                get(index)
            } else {
                this.name(ref)
            }
            match (value) {
                case Some(m) => out.append(m.text)
                case None => ()
            }
            i = if (braced) {
                end + 1
            } else {
                end
            }
        }
        return out.toString()
    }
}

func referenceLetter(c: Rune): Bool {
    (c >= r'a' && c <= r'z') || (c >= r'A' && c <= r'Z') || (c >= r'0' && c <= r'9') || c == r'_'
}
