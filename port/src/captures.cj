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
}
