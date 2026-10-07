package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func invalidPatternAndNegativeLimit(): Unit {
    var badPattern = false
    try {
        Regex("(")
    } catch (_: Exception) {
        badPattern = true
    }
    @Expect(badPattern, true)
    var badLimit = false
    try {
        Regex("a").replaceN("a", -1, "b")
    } catch (_: Exception) {
        badLimit = true
    }
    @Expect(badLimit, true)
}

@Test
func multilineAndDotAllFlags(): Unit {
    let regex = Regex("(?m)^a$")
    let matches = regex.findAll("a\na\r\na")
    @Expect(matches.size, 2)
    @Expect(matches[0].start, 0)
    @Expect(matches[1].start, 5)
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex("(?s)^...$").isMatch("中\n" + nul), true)
    @Expect(Regex("(?s:.).").isMatch("\n\n"), false)
}

@Test
func scopedGreedAndAbsoluteAnchors(): Unit {
    @Expect(requiredMatch(Regex("(?U)a+").find("aaa")).text, "a")
    @Expect(requiredMatch(Regex("(?U)a+?").find("aaa")).text, "aaa")
    @Expect(Regex(#"(?m)\Aa\z"#).isMatch("a\na"), false)
    @Expect(Regex("((?s).)." ).isMatch("\n\n"), false)
    @Expect(Regex("(?m)^a$").replaceAll("a\na", "b"), "b\nb")
}

@Test
func escapedNulAndUnicodeScalars(): Unit {
    let nul = String([Rune(UInt32(0))])
    @Expect(Regex(#"\x00"#).isMatch(nul), true)
    @Expect(Regex(#"\u0000"#).replaceAll(nul, "!"), "!")
    @Expect(Regex(#"[\U00000000]"#).split(nul).size, 2)
    @Expect(Regex(#"\x{0}"#).isMatch(nul), true)
    @Expect(requiredMatch(Regex(#"\xFF"#).find("ÿ")).end, 2)
}
