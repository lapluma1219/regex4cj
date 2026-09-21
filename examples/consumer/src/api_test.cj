package regex_consumer

import cjregex.*

func requiredMatch(value: Option<RegexMatch>): RegexMatch {
    match (value) {
        case Some(m) => return m
        case None => throw Exception("expected match")
    }
}
func requiredCaptures(value: Option<Captures>): Captures {
    match (value) {
        case Some(c) => return c
        case None => throw Exception("expected captures")
    }
}

@Test
func nulMatchingAndEscape(): Unit {
    let nul = String([Rune(UInt32(0))])
    let text = "中" + nul + "🙂"
    let m = requiredMatch(Regex(escape(nul)).find(text))
    @Expect(m.start, 3)
    @Expect(m.end, 4)
    @Expect(m.text, nul)
    @Expect(escape(nul), nul)
    @Expect(Regex(".").findAll(text).size, 3)
    @Expect(isMetaCharacter(r'$'), true)
    @Expect(isMetaCharacter(Rune(UInt32(0))), false)
}

@Test
func nulReplacementAndSplit(): Unit {
    let nul = String([Rune(UInt32(0))])
    let regex = Regex(nul)
    @Expect(regex.replaceAll("a" + nul + "b", "!"), "a!b")
    @Expect(Regex("a").replaceLiteral("a", 0, nul), nul)
    let parts = regex.split(nul + "a" + nul)
    @Expect(parts.size, 3)
    @Expect(parts[0], "")
    @Expect(parts[1], "a")
    @Expect(parts[2], "")
    let caps = requiredCaptures(Regex("(" + nul + ")").captures(nul))
    @Expect(caps.expand("$1"), nul)
}

@Test
func captureAbsenceAndBounds(): Unit {
    let caps = requiredCaptures(Regex("(?<optional>a)?(b*)").captures(""))
    @Expect(caps.size, 3)
    @Expect(caps.get(-1).isNone(), true)
    @Expect(caps.get(3).isNone(), true)
    @Expect(caps.get(1).isNone(), true)
    @Expect(caps.name("optional").isNone(), true)
    @Expect(caps.name("").isNone(), true)
    @Expect(caps.name("unknown").isNone(), true)
    @Expect(requiredMatch(caps.get(2)).text, "")
}

@Test
func captureResultsAndMetadataAreIndependent(): Unit {
    let regex = Regex("(?<x>a|b)")
    let names = regex.captureNames()
    names[1] = Some("changed")
    let first = requiredCaptures(regex.captures("a"))
    let second = requiredCaptures(regex.captures("b"))
    @Expect(requiredMatch(first.name("x")).text, "a")
    @Expect(requiredMatch(second.name("x")).text, "b")
    @Expect(first.name("changed").isNone(), true)
    @Expect(regex.captureNames()[1], Some("x"))
    @Expect(regex.capturesLen(), 2)
}

@Test
func retainedCaptureAndTemplateExpansion(): Unit {
    let caps = requiredCaptures(Regex("(a(b)?)+").captures("aba"))
    @Expect(requiredMatch(caps.get(2)).text, "b")
    @Expect(caps.expand(#"$1x|${1}x|$$|$2"#), "|ax|$|b")
}

@Test
func callbackLimitAndNoMatch(): Unit {
    let calls = [0]
    let regex = Regex("(a)")
    let result = regex.replaceWith("aaa", 2, { caps =>
        calls[0]++
        requiredMatch(caps.get(1)).text + calls[0].toString()
    })
    @Expect(result, "a1a2a")
    @Expect(calls[0], 2)
    @Expect(regex.replaceWith("bbb", 0, { _ => calls[0]++; "!" }), "bbb")
    @Expect(calls[0], 2)
}

@Test
func callbackExceptionAndReuse(): Unit {
    let regex = Regex("a")
    let calls = [0]
    var caught = false
    try {
        regex.replaceWith("aaa", 0, { _ =>
            calls[0]++
            throw Exception("callback failed")
        })
    } catch (_: Exception) { caught = true }
    @Expect(caught, true)
    @Expect(calls[0], 1)
    @Expect(regex.replaceAll("aa", "!"), "!!")
}

@Test
func callbackCanReuseSameRegex(): Unit {
    let regex = Regex("(a)")
    @Expect(regex.replaceWith("aa", 0, { caps =>
        regex.replace("a", "b") + requiredMatch(caps.get(1)).text
    }), "baba")
}

@Test
func zeroWidthUnicodeAndLimits(): Unit {
    let regex = Regex("")
    @Expect(regex.replaceAll("中🙂", "-"), "-中-🙂-")
    let parts = regex.split("中🙂")
    @Expect(parts.size, 4)
    @Expect(parts[1], "中")
    @Expect(parts[2], "🙂")
    @Expect(regex.splitN("中🙂", 0).size, 0)
    @Expect(regex.splitN("中🙂", 1)[0], "中🙂")
    @Expect(Regex(",").splitN("a,b,c", 2)[1], "b,c")
}

@Test
func invalidPatternAndNegativeLimit(): Unit {
    var badPattern = false
    try { Regex("(") } catch (_: Exception) { badPattern = true }
    @Expect(badPattern, true)
    var badLimit = false
    try { Regex("a").replaceN("a", -1, "b") } catch (_: Exception) { badLimit = true }
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
