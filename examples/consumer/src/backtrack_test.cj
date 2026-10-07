package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func boundedBacktrackerReportsCapturesAndBudgetErrors(): Unit {
    match (BoundedBacktracker("(a+)(b+)", 1048576).search("aaabbb")) {
        case None => throw Exception("backtracker missed aaabbb")
        case Some(caps) =>
            match (caps.get(1)) {
                case Some(group) => @Expect(group.text, "aaa")
                case None => throw Exception("missing first group")
            }
            match (caps.get(2)) {
                case Some(group) => @Expect(group.text, "bbb")
                case None => throw Exception("missing second group")
            }
    }
    match (BoundedBacktracker("a+?", 1048576).search("aaa")) {
        case Some(found) => @Expect(found.getMatch().text, "a")
        case None => throw Exception("non-greedy backtracker missed")
    }
    var rejected = false
    try {
        BoundedBacktracker("a+", 1).search("aaaa")
    } catch (e: Exception) {
        rejected = e.toString().contains("haystack of length 4 is too long")
    }
    @Expect(rejected, true)
    @Expect(BoundedBacktracker("a+", 64).maxHaystackLen() > 0, true)
}

@Test
func backtrackerReusesItsVisitedCache(): Unit {
    let engine = BoundedBacktracker(["a+", "a"])
    let cache = engine.createCache()
    match (engine.search(cache, SearchInput("aaa"))) {
        case Some(hit) =>
            @Expect(hit.pattern, 0)
            @Expect(hit.end(), 3)
        case None => throw Exception("a+ must match")
    }
    match (engine.search(cache, SearchInput("b"))) {
        case Some(_) => throw Exception("the reused cache must not keep the previous match")
        case None => ()
    }
    match (engine.search(cache, SearchInput("aaa").selectPattern(1))) {
        case Some(hit) =>
            @Expect(hit.pattern, 1)
            @Expect(hit.end(), 1)
        case None => throw Exception("the selected pattern must match")
    }
    // Invalid UTF-8 haystacks are supported; these ASCII patterns simply miss.
    @Expect(engine.search(cache, SearchInput([UInt8(255)])).isNone(), true)
}
