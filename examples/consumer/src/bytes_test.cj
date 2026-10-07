package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func bytesRegexMatchesRawBytes(): Unit {
    var rejected = false
    try {
        Regex("(?-u).")
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    rejected = false
    try {
        Regex(#"(?-u)\x80"#)
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    let dot = BytesRegex("(?-u).")
    let raw = requiredBytes(dot.find([UInt8(255)]))
    @Expect(raw.start, 0)
    @Expect(raw.end, 1)
    @Expect(raw.bytes[0], UInt8(255))
    let han = BytesRegex(".").findAll([UInt8(0xE4), UInt8(0xB8), UInt8(0xAD)])
    @Expect(han.size, 1)
    @Expect(han[0].end, 3)
    let split = BytesRegex("(?-u).").findAll([UInt8(0xE4), UInt8(0xB8), UInt8(0xAD)])
    @Expect(split.size, 3)
    @Expect(split[0].end, 1)
    let built = BytesRegexBuilder("(?-u)[^a]").unicode(false).build()
    @Expect(requiredBytes(built.find([UInt8(128)])).end, 1)
    match (BytesRegex("(a)(b)?").captures([UInt8(97)])) {
        case Some(caps) =>
            @Expect(requiredBytes(caps.get(1)).bytes[0], UInt8(97))
            match (caps.get(2)) {
                case None => ()
                case Some(_) => throw Exception("optional group should be absent")
            }
        case None => throw Exception("expected bytes captures")
    }
    let replaced = BytesRegex("(?-u).").replaceAll([UInt8(255), UInt8(97)], "X".toArray())
    @Expect(replaced.size, 2)
    @Expect(replaced[0], UInt8(88))
    let parts = BytesRegex("a").split([UInt8(97), UInt8(98), UInt8(97)])
    @Expect(parts.size, 3)
    @Expect(parts[1].size, 1)
    @Expect(parts[1][0], UInt8(98))
    let set = BytesRegexSet(["(?-u).", "a"])
    let hits = set.matches([UInt8(255)])
    @Expect(hits.matched(0), true)
    @Expect(hits.matched(1), false)
}

@Test
func byteIteratorsSnapshotAndKeepIndependentCursors(): Unit {
    let input = [UInt8(97), UInt8(98), UInt8(97)]
    let re = BytesRegex("(a)")
    let first = re.findIter(input)
    let second = re.findIter(input)
    let captures = re.capturesIter(input)
    let parts = re.splitNIter(input, 2)
    input[0] = UInt8(120)
    let saved = requiredBytes(first.next())
    @Expect(saved.start, 0)
    saved.bytes[0] = UInt8(121)
    @Expect(requiredBytes(first.next()).start, 2)
    @Expect(requiredBytes(second.next()).start, 0)
    match (captures.next()) {
        case Some(c) => @Expect(requiredBytes(c.get(1)).bytes[0], UInt8(97))
        case None => throw Exception("missing snapshot capture")
    }
    match (parts.next()) {
        case Some(p) => @Expect(p.size, 0)
        case None => throw Exception("missing empty leading part")
    }
    match (parts.next()) {
        case Some(p) =>
            @Expect(p.size, 2)
            @Expect(p[0], UInt8(98))
            @Expect(p[1], UInt8(97))
        case None => throw Exception("missing remainder")
    }
    for (_ in 0..3) {
        match (first.next()) {
            case None => ();
            case Some(_) => throw Exception("iterator not exhausted")
        }
        match (parts.next()) {
            case None => ();
            case Some(_) => throw Exception("split iterator not exhausted")
        }
    }
}
