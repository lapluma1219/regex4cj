package regex4cj

import std.collection.*

// Builders expose the same options as the pinned regex string builders.
// dfaSizeLimit is the string search cache budget. Below 128 the PikeVM runs
// as before. At or above 128 a bounded step cache is used. Match text stays
// the same. This is not the upstream lazy DFA. Bytes search ignores it.
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
        if (UInt32(byte) > 255) {
            throw Exception("line terminator must be a byte")
        }
        options.lineTerminator = byte
        return this
    }
    public func nestLimit(limit: Int64): RegexBuilder {
        if (limit < 0) {
            throw Exception("nest limit must be nonnegative")
        }
        options.nestLimit = limit
        return this
    }
    public func sizeLimit(limit: Int64): RegexBuilder {
        if (limit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        options.sizeLimit = limit
        return this
    }
    public func dfaSizeLimit(limit: Int64): RegexBuilder {
        if (limit < 0) {
            throw Exception("dfa size limit must be nonnegative")
        }
        options.dfaSizeLimit = limit
        return this
    }
}

public class RegexSetBuilder {
    private let options = PatternOptions()
    private let patterns = ArrayList<String>()
    public init() {}
    public init(patterns: Array<String>) {
        for (pattern in patterns) { this.patterns.add(pattern) }
    }
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
        if (UInt32(byte) > 255) {
            throw Exception("line terminator must be a byte")
        }
        options.lineTerminator = byte
        return this
    }
    public func nestLimit(limit: Int64): RegexSetBuilder {
        if (limit < 0) {
            throw Exception("nest limit must be nonnegative")
        }
        options.nestLimit = limit
        return this
    }
    public func sizeLimit(limit: Int64): RegexSetBuilder {
        if (limit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        options.sizeLimit = limit
        return this
    }
    public func dfaSizeLimit(limit: Int64): RegexSetBuilder {
        if (limit < 0) {
            throw Exception("dfa size limit must be nonnegative")
        }
        options.dfaSizeLimit = limit
        return this
    }
}

// Bytes builder. utf8 is always off, so a pattern may match raw bytes.
public class BytesRegexBuilder {
    private let options = PatternOptions()
    private var pattern: String = ""
    public init(pattern: String) {
        this.pattern = pattern
        options.utf8 = false
    }
    public func build(): BytesRegex {
        options.utf8 = false
        return BytesRegex(pattern, options)
    }
    public func caseInsensitive(yes: Bool): BytesRegexBuilder {
        options.caseInsensitive = yes
        return this
    }
    public func multiLine(yes: Bool): BytesRegexBuilder {
        options.multiLine = yes
        return this
    }
    public func dotMatchesNewLine(yes: Bool): BytesRegexBuilder {
        options.dotAll = yes
        return this
    }
    public func swapGreed(yes: Bool): BytesRegexBuilder {
        options.swapGreed = yes
        return this
    }
    public func ignoreWhitespace(yes: Bool): BytesRegexBuilder {
        options.ignoreWhitespace = yes
        return this
    }
    public func crlf(yes: Bool): BytesRegexBuilder {
        options.crlf = yes
        return this
    }
    public func unicode(yes: Bool): BytesRegexBuilder {
        options.unicode = yes
        return this
    }
    public func octal(yes: Bool): BytesRegexBuilder {
        options.octal = yes
        return this
    }
    public func lineTerminator(byte: Rune): BytesRegexBuilder {
        if (UInt32(byte) > 255) {
            throw Exception("line terminator must be a byte")
        }
        options.lineTerminator = byte
        return this
    }
    public func nestLimit(limit: Int64): BytesRegexBuilder {
        if (limit < 0) {
            throw Exception("nest limit must be nonnegative")
        }
        options.nestLimit = limit
        return this
    }
    public func sizeLimit(limit: Int64): BytesRegexBuilder {
        if (limit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        options.sizeLimit = limit
        return this
    }
    public func dfaSizeLimit(limit: Int64): BytesRegexBuilder {
        if (limit < 0) {
            throw Exception("dfa size limit must be nonnegative")
        }
        options.dfaSizeLimit = limit
        return this
    }
}

public class BytesRegexSetBuilder {
    private let options = PatternOptions()
    private let patterns = ArrayList<String>()
    public init() {
        options.utf8 = false
    }
    public init(patterns: Array<String>) {
        options.utf8 = false
        for (pattern in patterns) { this.patterns.add(pattern) }
    }
    public func pattern(value: String): BytesRegexSetBuilder {
        patterns.add(value)
        return this
    }
    public func build(): BytesRegexSet {
        options.utf8 = false
        return BytesRegexSet(patterns.toArray(), options)
    }
    public func caseInsensitive(yes: Bool): BytesRegexSetBuilder {
        options.caseInsensitive = yes
        return this
    }
    public func multiLine(yes: Bool): BytesRegexSetBuilder {
        options.multiLine = yes
        return this
    }
    public func dotMatchesNewLine(yes: Bool): BytesRegexSetBuilder {
        options.dotAll = yes
        return this
    }
    public func swapGreed(yes: Bool): BytesRegexSetBuilder {
        options.swapGreed = yes
        return this
    }
    public func ignoreWhitespace(yes: Bool): BytesRegexSetBuilder {
        options.ignoreWhitespace = yes
        return this
    }
    public func crlf(yes: Bool): BytesRegexSetBuilder {
        options.crlf = yes
        return this
    }
    public func unicode(yes: Bool): BytesRegexSetBuilder {
        options.unicode = yes
        return this
    }
    public func octal(yes: Bool): BytesRegexSetBuilder {
        options.octal = yes
        return this
    }
    public func lineTerminator(byte: Rune): BytesRegexSetBuilder {
        if (UInt32(byte) > 255) {
            throw Exception("line terminator must be a byte")
        }
        options.lineTerminator = byte
        return this
    }
    public func nestLimit(limit: Int64): BytesRegexSetBuilder {
        if (limit < 0) {
            throw Exception("nest limit must be nonnegative")
        }
        options.nestLimit = limit
        return this
    }
    public func sizeLimit(limit: Int64): BytesRegexSetBuilder {
        if (limit < 0) {
            throw Exception("size limit must be nonnegative")
        }
        options.sizeLimit = limit
        return this
    }
    public func dfaSizeLimit(limit: Int64): BytesRegexSetBuilder {
        if (limit < 0) {
            throw Exception("dfa size limit must be nonnegative")
        }
        options.dfaSizeLimit = limit
        return this
    }
}
