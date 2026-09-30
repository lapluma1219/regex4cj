package cjregex

import std.collection.*

// Builders only expose options the scalar engine actually implements.
// Byte-budget and DFA limits are rejected instead of being stored and ignored.
public class RegexBuilder {
    private let options = PatternOptions()
    private var pattern: String = ""
    public init(pattern: String) {
        this.pattern = pattern
    }
    public func build(): Regex {
        Regex(pattern, options)
    }
    public func caseInsensitive(yes: Bool): RegexBuilder {
        options.caseInsensitive = yes
        return this
    }
    public func multiLine(yes: Bool): RegexBuilder {
        options.multiLine = yes
        return this
    }
    public func dotMatchesNewLine(yes: Bool): RegexBuilder {
        options.dotAll = yes
        return this
    }
    public func swapGreed(yes: Bool): RegexBuilder {
        options.swapGreed = yes
        return this
    }
    public func ignoreWhitespace(yes: Bool): RegexBuilder {
        options.ignoreWhitespace = yes
        return this
    }
    public func crlf(yes: Bool): RegexBuilder {
        options.crlf = yes
        return this
    }
    public func unicode(yes: Bool): RegexBuilder {
        options.unicode = yes
        return this
    }
    public func octal(yes: Bool): RegexBuilder {
        options.octal = yes
        return this
    }
    public func lineTerminator(byte: Rune): RegexBuilder {
        if (UInt32(byte) > 127) {
            throw Exception("line terminator must be an ASCII byte in string mode")
        }
        options.lineTerminator = byte
        return this
    }
    public func nestLimit(limit: Int64): RegexBuilder {
        if (limit < 1) {
            throw Exception("nest limit must be positive")
        }
        options.nestLimit = limit
        return this
    }
    public func sizeLimit(limit: Int64): RegexBuilder {
        throw Exception("size_limit is a byte budget; this build caps NFA states instead and does not accept ${limit}")
    }
    public func dfaSizeLimit(limit: Int64): RegexBuilder {
        throw Exception("dfa_size_limit is not supported; this build has no lazy DFA (${limit})")
    }
}

public class RegexSetBuilder {
    private let options = PatternOptions()
    private let patterns = ArrayList<String>()
    public init() {}
    public func pattern(value: String): RegexSetBuilder {
        patterns.add(value)
        return this
    }
    public func build(): RegexSet {
        RegexSet(patterns.toArray(), options)
    }
    public func caseInsensitive(yes: Bool): RegexSetBuilder {
        options.caseInsensitive = yes
        return this
    }
    public func multiLine(yes: Bool): RegexSetBuilder {
        options.multiLine = yes
        return this
    }
    public func dotMatchesNewLine(yes: Bool): RegexSetBuilder {
        options.dotAll = yes
        return this
    }
    public func swapGreed(yes: Bool): RegexSetBuilder {
        options.swapGreed = yes
        return this
    }
    public func ignoreWhitespace(yes: Bool): RegexSetBuilder {
        options.ignoreWhitespace = yes
        return this
    }
    public func crlf(yes: Bool): RegexSetBuilder {
        options.crlf = yes
        return this
    }
    public func unicode(yes: Bool): RegexSetBuilder {
        options.unicode = yes
        return this
    }
    public func octal(yes: Bool): RegexSetBuilder {
        options.octal = yes
        return this
    }
    public func lineTerminator(byte: Rune): RegexSetBuilder {
        if (UInt32(byte) > 127) {
            throw Exception("line terminator must be an ASCII byte in string mode")
        }
        options.lineTerminator = byte
        return this
    }
    public func nestLimit(limit: Int64): RegexSetBuilder {
        if (limit < 1) {
            throw Exception("nest limit must be positive")
        }
        options.nestLimit = limit
        return this
    }
    public func sizeLimit(limit: Int64): RegexSetBuilder {
        throw Exception("size_limit is a byte budget; this build caps NFA states instead and does not accept ${limit}")
    }
    public func dfaSizeLimit(limit: Int64): RegexSetBuilder {
        throw Exception("dfa_size_limit is not supported; this build has no lazy DFA (${limit})")
    }
}
