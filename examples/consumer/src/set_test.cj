package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func setBuilderArrayConstructionAndErrors(): Unit {
    @Expect(RegexSetBuilder(Array<String>()).build().isEmpty(), true)
    @Expect(BytesRegexSetBuilder(Array<String>()).build().isEmpty(), true)
    let patterns = ["a", "a"]
    let builder = RegexSetBuilder(patterns)
    let bytes = BytesRegexSetBuilder(patterns)
    patterns[0] = "z"
    let first = builder.build()
    builder.pattern("b")
    bytes.pattern("b")
    @Expect(first.len(), 2)
    @Expect(first.matches("a").matchedAll(), true)
    @Expect(builder.build().len(), 3)
    @Expect(bytes.build().matches("a".toArray()).indices().size, 2)
    let invalid = RegexSetBuilder(["("])
    let invalidBytes = BytesRegexSetBuilder(["("])
    var rejected = false
    try { invalid.build() } catch (_: RegexError) { rejected = true }
    @Expect(rejected, true)
    rejected = false
    try { invalidBytes.build() } catch (_: RegexError) { rejected = true }
    @Expect(rejected, true)
}

@Test
func setSizeHintTracksSlotsNotHits(): Unit {
    let it = RegexSet(["a", "b", "c", "d"]).matches("b").iter()
    let (start, _) = it.sizeHint()
    @Expect(start, 4)
    @Expect(it.next(), Some(1))
    let (after, upper) = it.sizeHint()
    @Expect(after, 2)
    @Expect(upper, Some(2))
    let copy = it.clone()
    @Expect(it.nextBack(), None)
    let (end, _) = it.sizeHint()
    @Expect(end, 0)
    let (saved, _) = copy.sizeHint()
    @Expect(saved, 2)
    let empty = BytesRegexSet(Array<String>()).matches(Array<UInt8>()).iter()
    let (zero, zu) = empty.sizeHint()
    @Expect(zero, 0)
    @Expect(zu, Some(0))
}

@Test
func emptySetAndEmptyMatches(): Unit {
    let set = RegexSet(Array<String>())
    @Expect(set.isEmpty(), true)
    @Expect(set.len(), 0)
    @Expect(set.isMatch("abc"), false)
    let result = set.matches("")
    @Expect(result.len(), 0)
    @Expect(result.matchedAny(), false)
    @Expect(result.matchedAll(), true)
    @Expect(result.indices().size, 0)
    @Expect(RegexSet(["", "^$", "a*"]).matches("").matchedAll(), true)
}

@Test
func setOverlapDuplicatesAndOrdering(): Unit {
    let result = RegexSet(["foo", "bar", "foobar", "foo", "z"]).matches("bar foobar foo")
    @Expect(result.len(), 5)
    @Expect(result.indices().size, 4)
    for (i in 0..4) {
        @Expect(result.indices()[i], i)
    }
    @Expect(result.matched(4), false)
    @Expect(result.matchedAll(), false)
    @Expect(result.matchedAny(), true)
}

@Test
func setResultsAndPatternsAreIndependent(): Unit {
    let patterns = ["a", "b"]
    let set = RegexSet(patterns)
    patterns[0] = "z"
    let copy = set.patterns()
    copy[1] = "z"
    let first = set.matches("a")
    let second = set.matches("b")
    let ids = first.indices()
    ids[0] = 1
    @Expect(set.patterns()[0], "a")
    @Expect(set.patterns()[1], "b")
    @Expect(first.matched(0), true)
    @Expect(first.matched(1), false)
    @Expect(first.indices()[0], 0)
    @Expect(second.matched(1), true)
}

@Test
func setNulAndUnicode(): Unit {
    let nul = String([Rune(UInt32(0))])
    let set = RegexSet([nul, #"\p{Han}"#, #"\b中\b"#, #"\p{Emoji}"#, #"\A\z"#])
    let result = set.matches(nul + "中🙂")
    for (i in 0..4) {
        @Expect(result.matched(i), true)
    }
    @Expect(result.matched(4), false)
    @Expect(set.isMatch(nul), true)
}

@Test
func setAgreesWithIndependentRegexes(): Unit {
    let patterns = ["", "a|ab", "(a?)*", "a+b", "(?m)^a$", "(?s).+", "a{2,3}?", #"\Aab\z"#, #"\bcat\b"#, #"\B"#,
        #"[a-z&&[^aeiou]]"#, #"\p{Han}+"#, #"\p{Alphabetic}"#, "(?<id>a+)", "(?U)a+", "$"]
    let set = RegexSet(patterns)
    for (text in ["", "a", "ab", "aaaa", "x\na\ny", "cat cats", "中文🙂", "123", "\n"]) {
        let result = set.matches(text)
        var any = false
        for (i in 0..patterns.size) {
            let hit = Regex(patterns[i]).isMatch(text)
            @Expect(result.matched(i), hit)
            any = any || hit
        }
        @Expect(set.isMatch(text), any)
    }
}

@Test
func setInvalidIndexAndConstruction(): Unit {
    let result = RegexSet(["a"]).matches("a")
    for (index in [-1, 1]) {
        var rejected = false
        try {
            result.matched(index)
        } catch (_: Exception) {
            rejected = true
        }
        @Expect(rejected, true)
    }
    for (pattern in ["(", "(?=a)"]) {
        var rejected = false
        try {
            RegexSet(["ok", pattern])
        } catch (_: Exception) {
            rejected = true
        }
        @Expect(rejected, true)
    }
    let many = RegexSet(Array<String>(257, {_ => "a"}))
    @Expect(many.len(), 257)
    @Expect(many.isMatch("a"), true)
}

@Test
func setIteratorDirectionsCloneAndLifetime(): Unit {
    let result = RegexSet(["a", "z", "a", "b"]).matches("ab")
    let it = result.iter()
    @Expect(it.next(), Some(0))
    let copy = it.clone()
    @Expect(it.nextBack(), Some(3))
    @Expect(copy.next(), Some(2))
    @Expect(it.next(), Some(2))
    @Expect(copy.nextBack(), Some(3))
    for (_ in 0..3) {
        @Expect(it.next(), None)
        @Expect(it.nextBack(), None)
        @Expect(copy.next(), None)
        @Expect(copy.nextBack(), None)
    }
    let exhausted = it.clone()
    @Expect(exhausted.nextBack(), None)
    let ids = result.indices()
    ids[0] = 99
    @Expect(result.iter().next(), Some(0))
    let temporary = RegexSet(["a"]).matches("a").iter()
    @Expect(temporary.nextBack(), Some(0))
    @Expect(temporary.next(), None)
    let empty = RegexSet(Array<String>()).matches("").iter()
    @Expect(empty.next(), None)
    @Expect(empty.nextBack(), None)
    let raw = BytesRegexSet(["(?-u)\\xFF", "a", "(?-u)\\xFF"]).matches([UInt8(255)]).iter()
    @Expect(raw.next(), Some(0))
    @Expect(raw.nextBack(), Some(2))
    @Expect(raw.next(), None)
}
