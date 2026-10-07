package regex_consumer

import regex4cj.*

@Test
func dfaImagesRejectEveryTruncationAndCorruptHeader(): Unit {
    let original = DenseDfa(["ab+", "中"])
    let image = original.toImage()
    for (length in 0..image.size) {
        let prefix = Array<UInt8>(length, {i => image[i]})
        coverageRejects({ => DenseDfa.fromImage(prefix); () })
    }
    for (index in [0, 4, 8, 12]) {
        let corrupt = Array<UInt8>(image.size, {i => image[i]})
        corrupt[index] = corrupt[index] ^ UInt8(0x80)
        coverageRejects({ => DenseDfa.fromImage(corrupt); () })
    }
    let trailing = Array<UInt8>(image.size + 1, {i => if (i < image.size) { image[i] } else { UInt8(0) }})
    coverageRejects({ => DenseDfa.fromImage(trailing); () })
    let loaded = DenseDfa.fromImage(image)
    @Expect(loaded.stateCount(), original.stateCount())
    for (text in ["", "zzz", "zabbb", "a中"]) {
        let before = original.search(text)
        let after = loaded.search(text)
        @Expect(before.isSome(), after.isSome())
        match ((before, after)) {
            case (Some(a), Some(b)) =>
                @Expect(a.pattern, b.pattern)
                @Expect(a.start, b.start)
                @Expect(a.end, b.end)
                @Expect(a.text, b.text)
            case _ => ()
        }
    }
}

@Test
func dfaQuitBytesAbortAndCacheResetPreservesResults(): Unit {
    coverageRejects({ => DenseDfa("a", [UInt8(33)]).search("!a"); () })
    coverageRejects({ => SparseDfa("a", [UInt8(33)]).search("!a"); () })
    coverageRejects({ => HybridDfa("a", [UInt8(33)]).search("!a"); () })
    let denseMany = DenseDfa(["a", "b"], [UInt8(33)])
    let sparseMany = SparseDfa(["a", "b"], [UInt8(33)])
    coverageRejects({ => denseMany.search("!b"); () })
    coverageRejects({ => sparseMany.search("!b"); () })
    match (denseMany.search("zb")) {
        case Some(hit) => @Expect(hit.pattern, 1); @Expect(hit.start, 1)
        case None => throw Exception("dense multi-pattern quit configuration lost match")
    }
    match (sparseMany.search("zb")) {
        case Some(hit) => @Expect(hit.pattern, 1); @Expect(hit.start, 1)
        case None => throw Exception("sparse multi-pattern quit configuration lost match")
    }
    let sparse = SparseDfa.overlap(["a+", "a"])
    @Expect(sparse.searchOverlapping(SearchInput("aa")).size, 4)
    @Expect(sparse.memoryUsage() > 0, true)
    @Expect(sparse.stateCount() > 0, true)
    let hybrid = HybridDfa(["a+"], 65536, 10, true)
    for (_ in 0..3) {
        match (hybrid.search(SearchInput("zaaa").span(1, 4).selectPattern(0))) {
            case Some(hit) => @Expect(hit.start, 1); @Expect(hit.end, 4)
            case None => throw Exception("cache reuse lost match")
        }
        @Expect(hybrid.memoryUsage() > 0, true)
        hybrid.reset()
    }
}

@Test
func captureModesRejectUnknownValuesAcrossEngines(): Unit {
    for (mode in [-1, 3]) {
        coverageRejects({ => ThompsonNfa(["a"], mode); () })
        coverageRejects({ => ThompsonNfa(["a"], mode, false); () })
        coverageRejects({ => BoundedBacktracker(["a"], 1024, mode); () })
        coverageRejects({ => BoundedBacktracker("a", 1024, mode); () })
    }
}
