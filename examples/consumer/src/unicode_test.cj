package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func simpleCaseFoldingKeepsOriginalText(): Unit {
    let folded = Regex("(?i)a")
    let matchA = requiredMatch(folded.find("A"))
    @Expect(matchA.text, "A")
    @Expect(matchA.start, 0)
    @Expect(matchA.end, 1)
    @Expect(folded.isMatch("b"), false)
    @Expect(Regex("(?i)ß").isMatch("SS"), false)
    @Expect(Regex("(?i)ß").isMatch("ẞ"), true)
    @Expect(Regex("(?i)[^k]").isMatch("K"), false)
    @Expect(Regex("(?i)[^k]").isMatch("a"), true)
    @Expect(Regex("(?i)[a-z--c]").isMatch("C"), false)
    @Expect(Regex("(?i)[a-z--c]").isMatch("D"), true)
    @Expect(Regex("(?i)(?-i:a)").isMatch("A"), false)
    @Expect(Regex("a(?i)b").isMatch("aB"), true)
    @Expect(Regex("a(?i)b").isMatch("Ab"), false)
    let kelvin = String([Rune(UInt32(0x212A))])
    @Expect(Regex("(?i)K").isMatch(kelvin), true)
    let caps = requiredCaptures(Regex("(?i)(?<n>a)").captures("A"))
    @Expect(requiredMatch(caps.name("n")).text, "A")
    @Expect(caps.expand(#"${n}"#), "A")
}

@Test
func posixClassesWithNul(): Unit {
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex("[[:ascii:]]").isMatch(nul), true)
    @Expect(Regex("[[:cntrl:]]").isMatch(nul), true)
    @Expect(Regex("[[:print:]]").isMatch(nul), false)
    @Expect(Regex("[[:^ascii:]]").isMatch(nul), false)
    @Expect(Regex("[[:^digit:]]").isMatch(nul), true)
}

@Test
func posixClassesAreAsciiAndNamesCanFallBack(): Unit {
    @Expect(Regex("[[:digit:]]").isMatch("٣４"), false)
    @Expect(Regex("[[:alpha:]]").isMatch("中é"), false)
    @Expect(Regex("[[:^ascii:]]+").replaceAll("a中🙂b", "!"), "a!b")
    @Expect(Regex("[[:digitt:]]").isMatch(":"), true)
    @Expect(Regex("[[:space:]--[:blank:]]").isMatch("\n"), true)
}

@Test
func unicodeShorthandsAndNul(): Unit {
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex(#"\D\W\S"#).isMatch(nul + nul + nul), true)
    @Expect(Regex(#"[\d\s\w]"#).isMatch(nul), false)
    @Expect(Regex(#"\d+"#).replaceAll("a３٣b", "!"), "a!b")
    @Expect(Regex(#"\w+"#).isMatch("中文"), true)
    @Expect(Regex(#"\w"#).isMatch("🙂"), false)
}

@Test
func unicodeWordBoundaries(): Unit {
    let nul = String([Rune(UInt32(0))])
    let text = "中" + nul + "a"
    let hits = Regex(#"\b"#).findAll(text)
    @Expect(hits.size, 4)
    @Expect(hits[1].start, 3)
    @Expect(hits[2].start, 4)
    @Expect(Regex(#"\B"#).isMatch(""), true)
    @Expect(Regex(#"\b"#).isMatch(""), false)
    @Expect(Regex(#"\b"#).replaceAll("中文", "|"), "|中文|")
}

@Test
func unicodeGeneralCategories(): Unit {
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex(#"\p{Control}"#).isMatch(nul), true)
    @Expect(Regex(#"\p{Any}"#).isMatch(nul), true)
    @Expect(Regex(#"\p{gc=Nd}"#).isMatch("٣"), true)
    @Expect(Regex(#"\P{gc!=L}+"#).replaceAll("中文3", "!"), "!3")
    @Expect(Regex(#"[\p{L}--\p{Lu}]+"#).isMatch("é中"), true)
    @Expect(Regex(#"\p{Unassigned}"#).isMatch(String([Rune(UInt32(0x0378))])), true)
}

@Test
func unicodeScripts(): Unit {
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex(#"\p{sc=Common}"#).isMatch(nul), true)
    @Expect(Regex(#"\p{scx=Common}"#).isMatch(nul), true)
    @Expect(Regex(#"\p{sc=Hira}"#).isMatch("ー"), false)
    @Expect(Regex(#"\p{scx=Hira}"#).isMatch("ー"), true)
    @Expect(Regex(#"\p{scx=Kana}"#).isMatch("ー"), true)
    @Expect(Regex(#"\p{Han}+"#).replaceAll("a中文b", "!"), "a!b")
    @Expect(Regex(#"[\p{scx=Hira}--\p{sc=Hira}]"#).isMatch("ー"), true)
}

@Test
func unicodeBinaryProperties(): Unit {
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex(#"\P{Alphabetic}"#).isMatch(nul), true)
    @Expect(Regex(#"\p{Alphabetic}"#).isMatch(nul), false)
    @Expect(Regex(#"\p{Alphabetic}"#).isMatch("ͅ"), true)
    @Expect(Regex(#"\pL"#).isMatch("ͅ"), false)
    @Expect(Regex(#"\p{Uppercase}"#).isMatch("Ⅰ"), true)
    @Expect(Regex(#"\p{Lu}"#).isMatch("Ⅰ"), false)
    @Expect(Regex(#"\p{Emoji}+"#).replaceAll("a1🙂b", "!"), "a!b")
    @Expect(Regex(#"[\p{White_Space}~~\s]"#).isMatch(" "), false)
}
