package regex_consumer

import cjregex.*

func requiredMatch(value: Option<RegexMatch>): RegexMatch {
    match (value) {
        case Some(m) => return m
        case None => throw Exception("expected match")
    }
}

func requiredText(value: Option<String>): String {
    match (value) {
        case Some(text) => return text
        case None => throw Exception("expected text")
    }
}

func requiredCaptures(value: Option<Captures>): Captures {
    match (value) {
        case Some(c) => return c
        case None => throw Exception("expected captures")
    }
}

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
func nulMatchingAndEscape(): Unit {
    let nul = String([Rune(UInt32(0))])
    let text = "中" + nul + "🙂"
    let m = requiredMatch(Regex(escape(nul)).find(text))
    @Expect(m.start, 3)
    @Expect(m.end, 4)
    @Expect(m.text, nul)
    @Expect(escape(nul), nul)
    @Expect(Regex(".").findAll(text).size, 3)
    @Expect(escape("a$b"), #"a\$b"#)
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
    let result = regex.replaceWith(
        "aaa",
        2,
        {
            caps =>
                calls[0]++
                requiredMatch(caps.get(1)).text + calls[0].toString()
        }
    )
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
        regex.replaceWith(
            "aaa",
            0,
            {
                _ =>
                    calls[0]++
                    throw Exception("callback failed")
            }
        )
    } catch (_: Exception) {
        caught = true
    }
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

@Test
func searchFromOffsetAndConfiguredSyntax(): Unit {
    let anchored = Regex(#"\ba"#)
    @Expect(anchored.isMatchAt("ba", 1), false)
    @Expect(requiredMatch(Regex("a").findAt("ba", 1)).start, 1)
    @Expect(Regex("a+").shortestMatch("aaaaa"), Some(1))
    let found = Regex("a").findIter("abaca")
    var seen: Int64 = 0
    while (true) {
        match (found.next()) {
            case Some(_) => seen++
            case None => break
        }
    }
    @Expect(seen, 3)
    let parts = Regex(",").splitIter("a,b")
    @Expect(requiredText(parts.next()), "a")
    @Expect(requiredText(parts.next()), "b")
    match (parts.next()) {
        case None => ()
        case Some(_) => throw Exception("split iterator did not finish")
    }
    let dated = requiredCaptures(Regex(#"([0-9]{4})-([0-9]{2})"#).captures("2010-03"))
    let extracted = dated.extract(2)
    @Expect(extracted[0], "2010-03")
    @Expect(extracted[1], "2010")
    @Expect(extracted[2], "03")
    match (Regex("(a)|(b)").staticCapturesLen()) {
        case Some(count) => @Expect(count, 2)
        case None => throw Exception("expected a static capture count")
    }
    match (Regex("(a)|b").staticCapturesLen()) {
        case None => ()
        case Some(_) => throw Exception("capture count varies")
    }
    let locations = Regex("a").captureLocations()
    let kept = requiredMatch(Regex("a").capturesRead(locations, "a"))
    @Expect(kept.asStr(), "a")
    match (Regex("a").capturesRead(locations, "b")) {
        case None => ()
        case Some(_) => throw Exception("unexpected match")
    }
    match (locations.get(0)) {
        case Some(_) => throw Exception("failed search retained capture locations")
        case None => ()
    }
    let named = requiredCaptures(Regex("(?<名>a)").captures("a"))
    @Expect(requiredMatch(named.name("名")).text, "a")
    @Expect(Regex(#"\p{age=1.1}"#).isMatch("A"), true)
    @Expect(Regex(#"\p{gcb=cr}"#).isMatch("\r"), true)
    @Expect(Regex(#"\p{gcb=cr}"#).isMatch("a"), false)
    @Expect(requiredMatch(Regex("(?mR)^b").find("a\r\nb")).start, 3)
    @Expect(RegexBuilder(#"\101"#).octal(true).build().isMatch("A"), true)
    @Expect(RegexBuilder(#"\w"#).unicode(false).build().isMatch("a"), true)
    @Expect(RegexBuilder(#"\w"#).unicode(false).build().isMatch("Ω"), false)
    @Expect(requiredMatch(RegexBuilder("(?m)^b").lineTerminator(r'\r').build().find("a\rb")).start, 2)
    @Expect(RegexSetBuilder().unicode(false).pattern(#"\w"#).build().isMatch("Ω"), false)
    @Expect(RegexBuilder("a").dfaSizeLimit(1).build().isMatch("a"), true)
    @Expect(requiredMatch(RegexBuilder("a").dfaSizeLimit(0).build().find("xa")).start, 1)
    @Expect(requiredMatch(RegexBuilder("a").dfaSizeLimit(64).build().find("xa")).start, 1)
    var tooBig = false
    try {
        RegexBuilder(#"\w"#).sizeLimit(45000).build()
    } catch (e: RegexError) {
        tooBig = e.toString().contains("Compiled regex exceeds size limit of 45000 bytes.")
    }
    @Expect(tooBig, true)
    @Expect(RegexBuilder(#"\w"#).sizeLimit(50044).build().isMatch("a"), true)
    var syntax = false
    try {
        Regex("[z-a]")
    } catch (e: RegexError) {
        syntax = e.toString().contains("invalid character class range, the start must be <= the end")
    }
    @Expect(syntax, true)
    @Expect(RegexBuilder("a").nestLimit(0).build().isMatch("a"), true)
    var rejected = false
    try {
        RegexBuilder("ab").nestLimit(0).build()
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    @Expect(requiredMatch(Regex("a**").find("a")).asStr(), "a")
    @Expect(requiredMatch(Regex("a{ 2 }").find("aa")).asStr(), "aa")
    @Expect(requiredMatch(RegexBuilder("(?m)a$").lineTerminator(Rune(UInt32(0xE4))).build().find("a中")).asStr(), "a")
    rejected = false
    try {
        RegexBuilder(".").lineTerminator(Rune(UInt32(0xE4))).build()
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    let groups = Regex("(a)(b)?").captures("a")
    match (groups) {
        case Some(caps) =>
            let iter = caps.iter()
            let whole = iter.next()
            @Expect(whole.done, false)
            match (whole.value) {
                case Some(item) => @Expect(item.text, "a")
                case None => throw Exception("missing whole match")
            }
            let first = iter.next()
            match (first.value) {
                case Some(item) => @Expect(item.text, "a")
                case None => throw Exception("missing first group")
            }
            let second = iter.next()
            @Expect(second.done, false)
            match (second.value) {
                case None => ()
                case Some(_) => throw Exception("unmatched group should be absent")
            }
            @Expect(iter.next().done, true)
        case None => throw Exception("expected captures")
    }
    let slots = Array<Bool>(2, repeat: false)
    let set = RegexSet(["a", "b"])
    @Expect(set.matchesReadAt(slots, "a", 0), true)
    @Expect(slots[0], true)
    @Expect(set.matchesReadAt(slots, "c", 0), false)
    @Expect(slots[0], true)
    match (Regex("a").findAt("中", 1)) {
        case None => ()
        case Some(_) => throw Exception("unexpected interior-offset match")
    }
    @Expect(requiredMatch(Regex("a").findAt("中a", 1)).start, 3)
    rejected = false
    try {
        Regex(#"\p{age=na}"#)
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
}

@Test
func bytesRegexMatchesRawBytes(): Unit {
    var rejected = false
    try {
        Regex("(?-u).")
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    rejected = false
    try {
        Regex(#"(?-u)\x80"#)
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    let dot = BytesRegex("(?-u).")
    let raw = requiredBytes(dot.find([UInt8(255)]))
    @Expect(raw.start, 0)
    @Expect(raw.end, 1)
    @Expect(raw.bytes[0], UInt8(255))
    let han = BytesRegex(".").findAll([UInt8(0xE4), UInt8(0xB8), UInt8(0xAD)])
    @Expect(han.size, 1)
    @Expect(han[0].end, 3)
    let split = BytesRegex("(?-u).").findAll([UInt8(0xE4), UInt8(0xB8), UInt8(0xAD)])
    @Expect(split.size, 3)
    @Expect(split[0].end, 1)
    let built = BytesRegexBuilder("(?-u)[^a]").unicode(false).build()
    @Expect(requiredBytes(built.find([UInt8(128)])).end, 1)
    match (BytesRegex("(a)(b)?").captures([UInt8(97)])) {
        case Some(caps) =>
            @Expect(requiredBytes(caps.get(1)).bytes[0], UInt8(97))
            match (caps.get(2)) {
                case None => ()
                case Some(_) => throw Exception("optional group should be absent")
            }
        case None => throw Exception("expected bytes captures")
    }
    let replaced = BytesRegex("(?-u).").replaceAll([UInt8(255), UInt8(97)], "X".toArray())
    @Expect(replaced.size, 2)
    @Expect(replaced[0], UInt8(88))
    let parts = BytesRegex("a").split([UInt8(97), UInt8(98), UInt8(97)])
    @Expect(parts.size, 3)
    @Expect(parts[1].size, 1)
    @Expect(parts[1][0], UInt8(98))
    let set = BytesRegexSet(["(?-u).", "a"])
    let hits = set.matches([UInt8(255)])
    @Expect(hits.matched(0), true)
    @Expect(hits.matched(1), false)
}

func requiredBytes(value: Option<BytesMatch>): BytesMatch {
    match (value) {
        case Some(item) => return item
        case None => throw Exception("expected bytes match")
    }
}
