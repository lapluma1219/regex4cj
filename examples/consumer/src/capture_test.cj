package regex_consumer

import regex4cj.*
import std.collection.*

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
func groupCursorCopiesHaveIndependentPositions(): Unit {
    let it = requiredCaptures(Regex("(a)(b)?").captures("a")).iter()
    @Expect(it.len(), 3)
    it.next()
    let copy = it.clone()
    @Expect(copy.len(), 2)
    it.next()
    @Expect(it.len(), 1)
    @Expect(copy.len(), 2)
    let missing = it.next()
    @Expect(missing.done, false)
    @Expect(missing.value.isNone(), true)
    @Expect(it.len(), 0)
    @Expect(it.next().done, true)
    @Expect(it.clone().next().done, true)
    let (lower, upper) = it.sizeHint()
    @Expect(lower, 0)
    @Expect(upper, Some(0))
    @Expect(copy.next().done, false)
    @Expect(copy.len(), 1)
    let b = match (BytesRegex("(?-u:(.))(a)?").captures([UInt8(255)])) {
        case Some(c) => c.iter()
        case None => throw Exception("expected captures")
    }
    b.next()
    let bc = b.clone()
    b.next()
    @Expect(b.len(), 1)
    @Expect(bc.len(), 2)
    @Expect(b.next().value.isNone(), true)
    @Expect(b.next().done, true)
    let (bl, bu) = bc.sizeHint()
    @Expect(bl, 2)
    @Expect(bu, Some(2))
}
