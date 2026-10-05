package regex_consumer

import cjregex.*

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
