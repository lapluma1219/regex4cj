package regex_consumer

import cjregex.*

@Test
func liteMatchesScalarsWithAsciiClasses(): Unit {
    match (LiteRegex(".").search("中a")) {
        case Some(hit) => @Expect(hit.end(), 3)
        case None => throw Exception("Lite dot must accept Unicode scalars")
    }
    @Expect(LiteRegex("[^a]").isMatch("中"), true)
    @Expect(LiteRegex("\\w").isMatch("中"), false)
    @Expect(LiteRegex("(?i:é)").isMatch("É"), false)
    @Expect(LiteRegex("(?-u:.)").isMatch("中"), true)
    let all = LiteRegex("").searchAll("中a")
    @Expect(all.size, 3)
    @Expect(all[1].start(), 3)
}

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
func metaKeepsCapturesWhenUsingHybrid(): Unit {
    let engine = MetaRegex("(?<n>a*a)")
    @Expect(engine.engineName, "hybrid")
    match (engine.search("zaaa")) {
        case Some(hit) => match (hit.captures.name("n")) {
            case Some(group) => @Expect(group.text, "aaa")
            case None => throw Exception("Meta must retain named captures")
        }
        case None => throw Exception("Meta must match")
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
