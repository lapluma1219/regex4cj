package regex_consumer

import regex4cj.*
import std.collection.*

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
