package regex_consumer

import cjregex.*

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

@Test
func setSizeHintTracksSlotsNotHits(): Unit {
    let it = RegexSet(["a", "b", "c", "d"]).matches("b").iter()
    let (start, _) = it.sizeHint()
    @Expect(start, 4)
    @Expect(it.next(), Some(1))
    let (after, upper) = it.sizeHint()
    @Expect(after, 2)
    @Expect(upper, Some(2))
    let copy = it.clone()
    @Expect(it.nextBack(), None)
    let (end, _) = it.sizeHint()
    @Expect(end, 0)
    let (saved, _) = copy.sizeHint()
    @Expect(saved, 2)
    let empty = BytesRegexSet(Array<String>()).matches(Array<UInt8>()).iter()
    let (zero, zu) = empty.sizeHint()
    @Expect(zero, 0)
    @Expect(zu, Some(0))
}
