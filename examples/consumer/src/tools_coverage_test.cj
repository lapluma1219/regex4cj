package regex_consumer

import regex4cj.*
import std.collection.*

func coverageRejects(action: () -> Unit): Unit {
    var rejected = false
    try { action() } catch (_: Exception) { rejected = true }
    @Expect(rejected, true)
}

@Test
func literalSequenceEmptyInfiniteAndFiniteContracts(): Unit {
    let empty = LiteralSeq.of(Array<LiteralPiece>())
    let inf = LiteralSeq.infinite()
    let a = LiteralSeq.of([LiteralPiece(true, "ab".toArray())])
    let b = LiteralSeq.of([LiteralPiece(true, "cd".toArray())])
    @Expect(empty.isEmpty(), true)
    @Expect(inf.isEmpty(), false)
    @Expect(empty.literalCount(), Some(0))
    @Expect(inf.literalCount(), None<Int64>)
    @Expect(empty.minLiteralLen(), None<Int64>)
    @Expect(inf.maxLiteralLen(), None<Int64>)
    @Expect(a.minLiteralLen(), Some(2))
    @Expect(a.maxLiteralLen(), Some(2))
    @Expect(extractLiterals(Hir.parse("abc"), true).literalCount(), Some(1))
    @Expect(a.isExact(), true)
    @Expect(a.isInexact(), false)
    @Expect(a.makeInexact().isInexact(), true)
    @Expect(a.isExact(), true)
    @Expect(a.maxUnionLen(b), Some(2))
    @Expect(a.maxCrossLen(b), Some(1))
    @Expect(a.maxCrossLen(inf), None<Int64>)
    @Expect(a.maxUnionLen(inf), None<Int64>)
    @Expect(a.crossForward(b).pieces[0].bytes, "abcd".toArray())
    @Expect(a.crossReverse(b).pieces[0].bytes, "cdab".toArray())
    @Expect(a.union(b).literalCount(), Some(2))
    @Expect(empty.unionIntoEmpty(b).isEmpty(), true)
    let epsilon = LiteralSeq.of([LiteralPiece(true, Array<UInt8>())])
    @Expect(epsilon.unionIntoEmpty(b).pieces[0].bytes, "cd".toArray())
    @Expect(a.keepFirst(1).pieces[0].bytes, "a".toArray())
    @Expect(a.keepLast(1).pieces[0].bytes, "b".toArray())
    @Expect(a.keepFirst(0).pieces[0].bytes.size, 0)
    coverageRejects({ => a.keepFirst(-1); () })
    coverageRejects({ => a.keepLast(-1); () })
    let duplicates = LiteralSeq.of([LiteralPiece(true, "b".toArray()), LiteralPiece(true, "a".toArray()), LiteralPiece(true, "b".toArray())])
    @Expect(duplicates.sorted().pieces[0].bytes, "a".toArray())
    @Expect(duplicates.sorted().deduped().literalCount(), Some(2))
    @Expect(a.reversed().pieces[0].bytes, "ba".toArray())
    let suffix = LiteralSeq.of([LiteralPiece(true, "cat".toArray()), LiteralPiece(true, "bat".toArray())])
    @Expect(suffix.commonSuffix(), Some("at".toArray()))
    @Expect(suffix.commonPrefix(), Some(Array<UInt8>()))
    @Expect(suffix.optimizeSuffix().finite, true)
    @Expect(formatLiterals(Hir.parse("abc"), true), formatLiteralSeq(extractLiterals(Hir.parse("abc"), true)))
    @Expect(formatLiterals(Hir.parse("abc"), false, LiteralLimits()), formatLiteralSeq(extractLiterals(Hir.parse("abc"))))
}

@Test
func utf8RangesRejectInvalidScalarsAndKeepBoundaries(): Unit {
    @Expect(utf8SequenceLines(0, 127), "[0-7F]")
    @Expect(utf8SequencesOf(128, 128)[0].text(), "[C2][80]")
    @Expect(utf8SequencesOf(0x10FFFF, 0x10FFFF).size, 1)
    coverageRejects({ => utf8SequencesOf(-1, 0); () })
    coverageRejects({ => utf8SequencesOf(0, 0x110000); () })
    coverageRejects({ => utf8SequencesOf(10, 9); () })
    @Expect(debugByte(9), #"\t"#)
    @Expect(debugByte(10), #"\n"#)
    @Expect(debugByte(13), #"\r"#)
    @Expect(debugByte(32), "' '")
    @Expect(debugByte(0), #"\x00"#)
    @Expect(debugByte(255), #"\xFF"#)
    @Expect(debugByte(65), "A")
}
