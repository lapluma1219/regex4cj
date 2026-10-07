package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func hybridOverlapBuildsTransitionsAndCanBeReused(): Unit {
    let engine = HybridDfa.overlap(["a+", "a"])
    for (_ in 0..2) {
        let halves = engine.searchOverlapping("aaa")
        @Expect(halves.size, 6)
        @Expect(halves[0].pattern, 0)
        @Expect(halves[0].end, 1)
        @Expect(halves[5].pattern, 1)
        @Expect(halves[5].end, 3)
        engine.reset()
    }
}

@Test
func dfaImagesNeverSilentlyDropConfiguration(): Unit {
    let patterns = ["a"]
    let engine = DenseDfa(patterns)
    patterns[0] = "b"
    match (DenseDfa.fromImage(engine.toImage()).search("a")) {
        case Some(hit) => @Expect(hit.text, "a")
        case None => throw Exception("Image must retain the compiled pattern")
    }
    for (configured in [DenseDfa("a", [UInt8(0)]), DenseDfa.overlap(["a"]), DenseDfa(["a"], Array<UInt8>(), false, true)]) {
        var rejected = false
        try {
            configured.toImage()
        } catch (e: Exception) {
            rejected = e.toString().contains("default search configuration only")
        }
        @Expect(rejected, true)
    }
}

@Test
func denseAndSparseDfaReportTheSameSpan(): Unit {
    match (DenseDfa("baz[0-9]+").search("foobaz12345bar")) {
        case Some(hit) =>
            @Expect(hit.start, 3)
            @Expect(hit.end, 11)
        case None => throw Exception("dense DFA missed baz")
    }
    match (SparseDfa("a+?").search("aaa")) {
        case Some(hit) => @Expect(hit.text, "a")
        case None => throw Exception("sparse DFA missed the short match")
    }
    match (DenseDfa("^a").search("ba")) {
        case Some(_) => throw Exception("anchored DFA must miss")
        case None => ()
    }
    var rejected = false
    try {
        DenseDfa("\\bfoo")
    } catch (e: Exception) {
        rejected = e.toString().contains("Unicode word boundary")
    }
    @Expect(rejected, true)
    @Expect(DenseDfa("a+").retainsDenseTable(), true)
    @Expect(SparseDfa("a+").retainsDenseTable(), false)
    match (DenseDfa("(?mR)^a").search("b\r\na")) {
        case Some(hit) =>
            @Expect(hit.start, 3)
            @Expect(hit.text, "a")
        case None => throw Exception("CRLF line start must match")
    }
    match (SparseDfa("(?mR)a$").search("a\r\nb")) {
        case Some(hit) => @Expect(hit.start, 0)
        case None => throw Exception("CRLF line end must match before CR")
    }
}

@Test
func multiPatternDfaPrefersTheEarlierRule(): Unit {
    match (DenseDfa(["a+", "a"]).search("aaa")) {
        case Some(hit) =>
            @Expect(hit.pattern, 0)
            @Expect(hit.start, 0)
            @Expect(hit.end, 3)
        case None => throw Exception("dense multi DFA missed a+")
    }
    match (SparseDfa(["b", "ab"]).search("xab")) {
        case Some(hit) =>
            @Expect(hit.pattern, 1)
            @Expect(hit.start, 1)
            @Expect(hit.text, "ab")
        case None => throw Exception("sparse multi DFA missed ab")
    }
    let halves = DenseDfa.overlap(["a+", "a"]).searchOverlapping("aaa")
    @Expect(halves.size, 6)
    @Expect(halves[0].pattern, 0)
    @Expect(halves[0].end, 1)
    @Expect(halves[1].pattern, 1)
    @Expect(halves[5].end, 3)
    let hybrid = HybridDfa("baz[0-9]+")
    match (hybrid.search("foobaz12345bar")) {
        case Some(hit) =>
            @Expect(hit.start, 3)
            @Expect(hit.end, 11)
        case None => throw Exception("lazy DFA missed baz")
    }
    let cached = hybrid.stateCount()
    hybrid.reset()
    @Expect(hybrid.stateCount() < cached, true)
    match (hybrid.search("foobaz12345bar")) {
        case Some(hit) => @Expect(hit.text, "baz12345")
        case None => throw Exception("lazy DFA missed baz after reset")
    }
    var tooSmall = false
    try {
        HybridDfa(["a+"], 1, 0)
    } catch (e: Exception) {
        tooSmall = e.toString().contains("smaller than minimum required")
    }
    @Expect(tooSmall, true)
}

@Test
func dfaReverseRecoveryRetainsPriorityAndContext(): Unit {
    match (DenseDfa("a|ba").search("ba")) {
        case Some(hit) => @Expect(hit.start, 0)
        case None => throw Exception("DFA missed an alternative")
    }
    match (SparseDfa(#"(?-u:a\B)"#).search("ab")) {
        case Some(hit) => @Expect(hit.text, "a")
        case None => throw Exception("DFA lost assertion context")
    }
    @Expect(DenseDfa("^[a&&b]").search("a").isNone(), true)
    match (DenseDfa(#"(?-u:\b\bfoo)"#).search(" foo")) {
        case Some(hit) => @Expect(hit.start, 1)
        case None => throw Exception("DFA missed consecutive assertions")
    }
}
