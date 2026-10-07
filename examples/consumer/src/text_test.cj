package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func nulReplacementAndSplit(): Unit {
    let nul = String([Rune(UInt32(0))])
    let regex = Regex(nul)
    @Expect(regex.replaceAll("a" + nul + "b", "!"), "a!b")
    @Expect(Regex("a").replaceLiteral("a", 0, nul), nul)
    let parts = regex.split(nul + "a" + nul)
    @Expect(parts.size, 3)
    @Expect(parts[0], "")
    @Expect(parts[1], "a")
    @Expect(parts[2], "")
    let caps = requiredCaptures(Regex("(" + nul + ")").captures(nul))
    @Expect(caps.expand("$1"), nul)
}

@Test
func callbackLimitAndNoMatch(): Unit {
    let calls = [0]
    let regex = Regex("(a)")
    let result = regex.replaceWith(
        "aaa",
        2,
        {
            caps =>
                calls[0]++
                requiredMatch(caps.get(1)).text + calls[0].toString()
        }
    )
    @Expect(result, "a1a2a")
    @Expect(calls[0], 2)
    @Expect(regex.replaceWith("bbb", 0, { _ => calls[0]++; "!" }), "bbb")
    @Expect(calls[0], 2)
}

@Test
func callbackExceptionAndReuse(): Unit {
    let regex = Regex("a")
    let calls = [0]
    var caught = false
    try {
        regex.replaceWith(
            "aaa",
            0,
            {
                _ =>
                    calls[0]++
                    throw Exception("callback failed")
            }
        )
    } catch (_: Exception) {
        caught = true
    }
    @Expect(caught, true)
    @Expect(calls[0], 1)
    @Expect(regex.replaceAll("aa", "!"), "!!")
}

@Test
func callbackCanReuseSameRegex(): Unit {
    let regex = Regex("(a)")
    @Expect(regex.replaceWith("aa", 0, { caps =>
        regex.replace("a", "b") + requiredMatch(caps.get(1)).text
    }), "baba")
}

@Test
func lazySplitLimitsAndByteCaptureMetadata(): Unit {
    var rejected = false
    try {
        Regex(",").splitNIter("a,b", -1)
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    rejected = false
    try {
        BytesRegex(",").splitNIter("a,b".toArray(), -1)
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
    match (Regex(",").splitNIter("a,b", 0).next()) {
        case None => ();
        case Some(_) => throw Exception("zero limit yielded a part")
    }
    @Expect(requiredText(Regex(",").splitNIter("a,b", 1).next()), "a,b")
    let re = BytesRegex("(a)?")
    match (re.staticCapturesLen()) {
        case None => ();
        case Some(_) => throw Exception("optional group is not static")
    }
    match (re.captures("".toArray())) {
        case Some(c) =>
            @Expect(c.getMatch().isEmpty(), true)
            @Expect(c.getMatch().len(), 0)
            let groups = c.iter()
            @Expect(groups.next().done, false)
            let missing = groups.next()
            @Expect(missing.done, false)
            match (missing.value) {
                case None => ();
                case Some(_) => throw Exception("optional group participated")
            }
            @Expect(groups.next().done, true)
            @Expect(groups.next().done, true)
            rejected = false
            try {
                c.extract(1)
            } catch (_: Exception) {
                rejected = true
            }
            @Expect(rejected, true)
        case None => throw Exception("expected empty match")
    }
}

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
