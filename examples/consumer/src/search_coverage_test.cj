package regex_consumer

import regex4cj.*

@Test
func textConvenienceMethodsAndClonedCapturesPreserveContract(): Unit {
    let regex = Regex("a+")
    @Expect(regex.asStr(), "a+")
    let hit = requiredMatch(regex.find("zaaa"))
    @Expect(hit.isEmpty(), false)
    @Expect(hit.len(), 3)
    @Expect(requiredMatch(Regex("").find("")).isEmpty(), true)
    match (regex.searchEarliest("zaaa")) {
        case Some(caps) => @Expect(caps.getMatch().start, 1); @Expect(caps.getMatch().end, 2)
        case None => throw Exception("expected earliest capture")
    }
    match (regex.searchWindow("zaaa", 2, 3, true)) {
        case Some(caps) => @Expect(caps.getMatch().start, 2); @Expect(caps.getMatch().end, 3)
        case None => throw Exception("expected bounded capture")
    }
    coverageRejects({ => regex.searchWindow("abc", 2, 1, false); () })
    let iter = regex.capturesIter("aa ba")
    @Expect(iter.next().isSome(), true)
    let copy = iter.clone()
    @Expect(iter.next().isSome(), true)
    @Expect(iter.next().isNone(), true)
    match (copy.next()) {
        case Some(caps) => @Expect(caps.getMatch().start, 4)
        case None => throw Exception("capture clone lost position")
    }
    @Expect(copy.next().isNone(), true)
}
