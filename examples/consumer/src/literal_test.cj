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
    @Expect(extractLiterals(Hir.parse("[abc]"), false, LiteralLimits(2, 10, 100, 250)).finite, false)
    @Expect(extractLiterals(Hir.parse("[abc]"), false, LiteralLimits(10, 10, 100, 250)).pieces.size, 3)
    var rejected = false
    try {
        LiteralLimits(-1, 10, 100, 250)
    } catch (e: Exception) {
        rejected = e.toString().contains("nonnegative")
    }
    @Expect(rejected, true)
    let sam = LiteralSeq.of(
        [
            LiteralPiece(true, [UInt8(0x73), UInt8(0x61), UInt8(0x6d)]),
            LiteralPiece(true, [UInt8(0x73), UInt8(0x61), UInt8(0x6d), UInt8(0x77), UInt8(0x69), UInt8(0x73),
                UInt8(0x65)])
        ]
    ).minimize()
    @Expect(sam.finite, true)
    @Expect(sam.pieces.size, 1)
    @Expect(sam.pieces[0].exact, false)
    @Expect(sam.pieces[0].bytes, [UInt8(0x73), UInt8(0x61), UInt8(0x6d)])
    let crossed = LiteralSeq.of(
        [
            LiteralPiece(true, [UInt8(0x66), UInt8(0x6f), UInt8(0x6f)]),
            LiteralPiece(false, [UInt8(0x62), UInt8(0x61), UInt8(0x72)])
        ]
    ).crossForward(
        LiteralSeq.of(
            [
                LiteralPiece(false, [UInt8(0x71), UInt8(0x75), UInt8(0x75), UInt8(0x78)]),
                LiteralPiece(true, [UInt8(0x62), UInt8(0x61), UInt8(0x7a)])
            ]
        )
    )
    @Expect(crossed.pieces.size, 3)
    @Expect(crossed.pieces[0].exact, false)
    @Expect(crossed.pieces[1].exact, true)
    @Expect(crossed.pieces[2].exact, false)
    match (LiteralSeq.of(
        [
            LiteralPiece(true, [UInt8(0x66), UInt8(0x6f), UInt8(0x6f)]),
            LiteralPiece(true, [UInt8(0x66), UInt8(0x6f), UInt8(0x6f), UInt8(0x62), UInt8(0x61), UInt8(0x72)]),
            LiteralPiece(true, [UInt8(0x66), UInt8(0x6f)])
        ]
    ).commonPrefix()) {
        case Some(prefix) => @Expect(prefix, [UInt8(0x66), UInt8(0x6f)])
        case None => throw Exception("foo/foobar/fo must share a prefix")
    }
    @Expect(formatCommon(LiteralSeq.infinite().commonPrefix()), "none")
    let optimized = LiteralSeq.of(
        [
            LiteralPiece(true,
                [UInt8(0x73), UInt8(0x61), UInt8(0x6d), UInt8(0x61), UInt8(0x6e), UInt8(0x74), UInt8(0x68), UInt8(0x61)]),
            LiteralPiece(true, [UInt8(0x73), UInt8(0x61), UInt8(0x6d)]),
            LiteralPiece(true, [UInt8(0x73), UInt8(0x61), UInt8(0x6d), UInt8(0x77), UInt8(0x69), UInt8(0x73),
                UInt8(0x65)]),
            LiteralPiece(true, [UInt8(0x66), UInt8(0x72), UInt8(0x6f), UInt8(0x64), UInt8(0x6f)])
        ]
    ).optimizePrefix()
    @Expect(optimized.pieces.size, 3)
    @Expect(optimized.pieces[1].exact, true)
    @Expect(optimized.pieces[1].bytes, [UInt8(0x73), UInt8(0x61), UInt8(0x6d)])
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
