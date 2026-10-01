package cjregex

import std.collection.*

// Capture index 0 is the whole match. Unmatched groups are None; empty groups
// are Some(RegexMatch) whose start equals end. Results own their string slices.
public class CaptureSpan {
    public let start: Int64
    public let end: Int64
    init(start: Int64, end: Int64) {
        this.start = start
        this.end = end
    }
}

public class CaptureLocations {
    public let size: Int64
    private let starts: Array<Int64>
    private let ends: Array<Int64>
    init(size: Int64) {
        this.size = size
        starts = Array<Int64>(size, repeat: -1)
        ends = Array<Int64>(size, repeat: -1)
    }
    public func get(index: Int64): Option<CaptureSpan> {
        if (index < 0 || index >= size || starts[index] < 0 || ends[index] < 0) {
            return None
        }
        return Some(CaptureSpan(starts[index], ends[index]))
    }
    func write(index: Int64, start: Int64, end: Int64): Unit {
        starts[index] = start
        ends[index] = end
    }
    func clear(index: Int64): Unit {
        starts[index] = -1
        ends[index] = -1
    }
}

public class Captures {
    private let groups: Array<Option<RegexMatch>>
    private let names: Array<String>
    private let staticLen: Int64
    public let size: Int64
    init(groups: Array<Option<RegexMatch>>, names: Array<String>, staticLen: Int64) {
        this.groups = groups
        this.names = names
        this.staticLen = staticLen
        this.size = groups.size
    }
    public func getMatch(): RegexMatch {
        match (get(0)) {
            case Some(item) => item
            case None => throw Exception("capture has no match")
        }
    }
    // Index 0 is the whole match. The remaining count strings are the groups
    // that participated, in index order. count must equal staticCapturesLen() - 1.
    public func extract(count: Int64): Array<String> {
        if (staticLen < 0) {
            throw Exception("the number of capture groups can vary in a match")
        }
        if (count != staticLen - 1) {
            throw Exception("extract asked for ${count} groups, but must ask for ${staticLen - 1}")
        }
        let whole = getMatch()
        let matched = ArrayList<String>()
        for (i in 1..size) {
            match (get(i)) {
                case Some(item) => matched.add(item.text)
                case None => ()
            }
        }
        if (matched.size < count) {
            throw Exception("too few matching groups")
        }
        return Array<String>(count + 1, {
            i => if (i == 0) {
                whole.text
            } else {
                matched[i - 1]
            }
        })
    }
    public func iter(): GroupIter {
        GroupIter(groups)
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

// One step of Captures::iter. done means the iterator is finished.
// value is None when that group did not participate.
public class GroupItem {
    public let done: Bool
    public let value: Option<RegexMatch>
    init(done: Bool, value: Option<RegexMatch>) {
        this.done = done
        this.value = value
    }
}

public class GroupIter {
    private let groups: Array<Option<RegexMatch>>
    private var index: Int64 = 0
    init(groups: Array<Option<RegexMatch>>) {
        this.groups = groups
    }
    public func next(): GroupItem {
        if (index >= groups.size) {
            return GroupItem(true, None)
        }
        let value = groups[index]
        index++
        return GroupItem(false, value)
    }
}
