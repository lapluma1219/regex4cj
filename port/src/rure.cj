package regex4cj

// The callable shape of regex-capi's rure_compile / rure_is_match / rure_find.
// The Cangjie package is a static library with mangled names, so this type is
// the running entry. capi/rure.h names the corresponding C functions.
public class Rure {
    let compiled: Regex
    public init(pattern: String) {
        compiled = Regex(pattern)
    }
    public func isMatch(text: String): Bool {
        compiled.isMatch(text)
    }
    public func find(text: String): Option<RegexMatch> {
        compiled.find(text)
    }
    public func findAt(text: String, at: Int64): Option<RegexMatch> {
        compiled.findAt(text, at)
    }
}
