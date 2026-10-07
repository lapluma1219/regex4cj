package regex_consumer

import regex4cj.*
import std.collection.*

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
func clonedIteratorsKeepIndependentCursors(): Unit {
    let found = Regex("a").findIter("abaca")
    @Expect(requiredMatch(found.next()).start, 0)
    let copy = found.clone()
    @Expect(requiredMatch(found.next()).start, 2)
    @Expect(requiredMatch(copy.next()).start, 2)
    @Expect(requiredMatch(found.next()).start, 4)
    @Expect(requiredMatch(copy.next()).start, 4)
    let parts = Regex("a").splitNIter("abaca", 3)
    match (parts.next()) {
        case Some(part) => @Expect(part, "")
        case None => throw Exception("missing split part")
    }
    let splitCopy = parts.clone()
    match (parts.next()) {
        case Some(part) => @Expect(part, "b")
        case None => throw Exception("missing original split part")
    }
    match (splitCopy.next()) {
        case Some(part) => @Expect(part, "b")
        case None => throw Exception("missing cloned split part")
    }
    let bytes = [UInt8(97), UInt8(98), UInt8(97)]
    let byteIter = BytesRegex("a").findIter(bytes)
    @Expect(requiredBytes(byteIter.next()).start, 0)
    let byteCopy = byteIter.clone()
    @Expect(requiredBytes(byteIter.next()).start, 2)
    @Expect(requiredBytes(byteCopy.next()).start, 2)
}
