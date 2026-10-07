package regex_consumer

import regex4cj.*

@Test
func adaptersRespectAnchorsAndIterationResults(): Unit {
    let one = OnePass("a+")
    @Expect(one.search("zaa").isNone(), true)
    match (one.searchAnchored("zaa", 1)) {
        case Some(hit) => @Expect(hit.start(), 1); @Expect(hit.end(), 3)
        case None => throw Exception("expected anchored match")
    }
    @Expect(one.searchAll("aa").size, 1)
    @Expect(one.searchAll("zaa").size, 0)
    coverageRejects({ => OnePass(Array<String>()); () })
    let meta = MetaRegex("a+")
    @Expect(meta.memoryUsage() > 0, true)
    @Expect(meta.searchAll("aa za").size, 2)
    let rure = Rure("a+")
    @Expect(rure.isMatch("zzz"), false)
    @Expect(requiredMatch(rure.find("zaa")).text, "aa")
    @Expect(requiredMatch(rure.findAt("aa za", 2)).start, 4)
}

@Test
func backtrackerEmptyMatchesAndCacheArguments(): Unit {
    let engine = BoundedBacktracker("a")
    @Expect(engine.stateCount() > 0, true)
    @Expect(engine.memoryUsage() > 0, true)
    @Expect(engine.isMatch(SearchInput("ba")), true)
    @Expect(engine.isMatch(SearchInput("bb")), false)
    @Expect(engine.searchAll("aba").size, 2)
    @Expect(engine.searchAll(SearchInput("aba").span(1, 3)).size, 1)
    @Expect(BoundedBacktracker("").searchAll("中").size, 2)
    coverageRejects({ => BoundedBacktracker("a", -1); () })
    coverageRejects({ => BoundedBacktracker("a", 100, 3); () })
    let reverse = ReverseNfa(["a", "b"])
    match (reverse.find(SearchInput("za"))) {
        case Some(hit) => @Expect(hit.pattern, 0); @Expect(hit.offset, 1)
        case None => throw Exception("expected reverse match")
    }
    @Expect(reverse.search(SearchInput("zz")), None<Int64>)
}
