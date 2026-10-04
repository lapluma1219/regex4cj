package regex_consumer

import cjregex.*

@Test
func hirExposesSixDigitStructure(): Unit {
    let h = Hir.parse("[0-9]{6}")
    @Expect(h.properties().minimumLen(), Some(UInt64(6)))
    @Expect(h.properties().maximumLen(), Some(UInt64(6)))
    match (h.kind()) {
        case HirKind.Repetition(rep) =>
            @Expect(rep.min, UInt32(6))
            @Expect(rep.max, Some(UInt32(6)))
            @Expect(rep.greedy, true)
            match (rep.sub.kind()) {
                case HirKind.Class(c) =>
                    @Expect(c.isBytes, false)
                    @Expect(c.ranges().size, 1)
                    @Expect(c.ranges()[0].start, 48)
                    @Expect(c.ranges()[0].end, 57)
                case _ => throw Exception("expected digit class")
            }
        case _ => throw Exception("expected repetition")
    }
    @Expect(h.subs().size, 1)
    @Expect(Hir.parse("中文").properties().minimumLen(), Some(UInt64(6)))
}

@Test
func hirSmartConstructorsPreserveSnapshots(): Unit {
    let bytes = [UInt8(97)]
    let h = Hir.literal(bytes)
    bytes[0] = UInt8(98)
    match (h.kind()) {
        case HirKind.Literal(out) =>
            @Expect(out[0], UInt8(97))
            out[0] = UInt8(99)
        case _ => throw Exception("expected literal")
    }
    match (h.kind()) {
        case HirKind.Literal(out) => @Expect(out[0], UInt8(97))
        case _ => throw Exception("expected literal")
    }
    let merged = Hir.concat([h, Hir.empty(), Hir.concat([Hir.literal("b".toArray()), Hir.literal("中".toArray())])])
    match (merged.kind()) {
        case HirKind.Literal(out) => @Expect(out.size, 5)
        case _ => throw Exception("adjacent literals must merge")
    }
    let c = Hir.unicodeClass([HirRange(122, 97), HirRange(98, 100)])
    match (c.kind()) {
        case HirKind.Class(value) =>
            let ranges = value.ranges()
            @Expect(ranges.size, 1)
            ranges[0] = HirRange(0, 1)
            @Expect(value.ranges()[0].start, 97)
        case _ => throw Exception("expected normalized class")
    }
    let nodes = [h, c]
    let cat = Hir.concat(nodes)
    nodes[0] = Hir.empty()
    let children = cat.subs()
    children[0] = Hir.empty()
    @Expect(cat.subs()[0].properties().minimumLen(), Some(UInt64(1)))
}

@Test
func hirLengthOverflowAndEmptyAreDistinctFromFailure(): Unit {
    @Expect(Hir.empty().properties().minimumLen(), Some(UInt64(0)))
    @Expect(Hir.fail().properties().minimumLen(), None)
    @Expect(Hir.repetition(0, Some(UInt32(0)), true, Hir.fail()).properties().maximumLen(), Some(UInt64(0)))
    var huge = Hir.literal([UInt8(97)])
    for (_ in 0..3) {
        huge = Hir.repetition(UInt32(0xFFFFFFFF), Some(UInt32(0xFFFFFFFF)), true, huge)
    }
    @Expect(huge.properties().minimumLen(), Some((UInt64(0xFFFFFFFF) << 32) | UInt64(0xFFFFFFFF)))
    @Expect(huge.properties().maximumLen(), None)
    @Expect(Hir.parse("a*").properties().maximumLen(), None)
}

@Test
func hirRejectsUnimplementedStructuresExplicitly(): Unit {
    match (Hir.parse("a|bc").kind()) {
        case HirKind.Alternation(parts) => @Expect(parts.size, 2)
        case _ => throw Exception("expected alternation")
    }
    @Expect(Hir.parse(".").toPattern().contains("["), true)
    var invalid = false
    try {
        Hir.parse("(")
    } catch (_: RegexError) {
        invalid = true
    }
    @Expect(invalid, true)
    var badRange = false
    try {
        Hir.byteClass([HirRange(0, 256)])
    } catch (_: Exception) {
        badRange = true
    }
    @Expect(badRange, true)
    let raw = Hir.parse(#"(?-u:\xFF)"#, false)
    match (raw.kind()) {
        case HirKind.Literal(bytes) => @Expect(bytes[0], UInt8(255))
        case _ => throw Exception("expected byte literal")
    }
}
