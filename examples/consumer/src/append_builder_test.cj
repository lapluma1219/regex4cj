package regex_consumer

import cjregex.*
import std.collection.*

@Test
func appendExpansionPreservesBuffers(): Unit {
    let caps = requiredCaptures(Regex("(?<x>a)(b)?").captures("a"))
    let out = StringBuilder()
    out.append("prefix:")
    caps.expandInto(#"${x}/$2/$$"#, out)
    caps.expandInto("", out)
    caps.expandInto(#"$0"#, out)
    @Expect(out.toString(), #"prefix:a//$a"#)
    @Expect(caps.expand(#"${x}/$2/$$"#), #"a//$"#)
    let raw = ArrayList<UInt8>()
    raw.add(UInt8(0))
    let bcaps = match (BytesRegex("(?-u)(.)").captures([UInt8(255)])) {
        case Some(c) => c
        case None => throw Exception("expected capture")
    }
    bcaps.expandInto(#"$1"#.toArray(), raw)
    bcaps.expandInto(Array<UInt8>(), raw)
    bcaps.expandInto(#"$$"#.toArray(), raw)
    @Expect(raw.size, 3)
    @Expect(raw[0], UInt8(0))
    @Expect(raw[1], UInt8(255))
    @Expect(raw[2], UInt8(36))
}

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
