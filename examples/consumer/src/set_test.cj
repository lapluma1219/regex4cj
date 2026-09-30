package regex_consumer

import cjregex.*

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
    for (pattern in ["(", "(?x)a"]) {
        var rejected = false
        try {
            RegexSet(["ok", pattern])
        } catch (_: Exception) {
            rejected = true
        }
        @Expect(rejected, true)
    }
    var rejected = false
    try {
        RegexSet(Array<String>(257, {_ => "a"}))
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
}
