package regex_consumer

import cjregex.*

@Test
func literalsUtf8AndEarliestMatchThePinnedCorpus(): Unit {
    let seq = extractLiterals(Hir.parse("ab*c"))
    @Expect(seq.finite, true)
    @Expect(seq.pieces.size, 2)
    @Expect(seq.pieces[0].exact, false)
    @Expect(seq.pieces[0].bytes, [UInt8(0x61), UInt8(0x62)])
    @Expect(seq.pieces[1].exact, true)
    @Expect(seq.pieces[1].bytes, [UInt8(0x61), UInt8(0x63)])
    @Expect(extractLiterals(Hir.parse(".")).finite, false)
    let rows = utf8SequencesOf(0, 127)
    @Expect(rows.size, 1)
    @Expect(rows[0].text(), "[0-7F]")
    let ids = PikeVM(["\\w+", "\\d+", "\\pL+", "foo", "bar", "barfoo", "foobar"]).whichOverlapping("foobar")
    @Expect(ids, [0, 2, 3, 4, 6])
    match (PikeVM("a+").searchEarliest("aaa")) {
        case Some(hit) =>
            @Expect(hit.start(), 0)
            @Expect(hit.end(), 1)
        case None => throw Exception("earliest a+ must match")
    }
    match (PikeVM("a*").searchEarliest("aaa")) {
        case Some(hit) =>
            @Expect(hit.start(), 0)
            @Expect(hit.end(), 0)
        case None => throw Exception("earliest a* must match empty")
    }
}
