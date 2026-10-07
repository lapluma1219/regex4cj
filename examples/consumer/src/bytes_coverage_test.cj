package regex_consumer

import regex4cj.*

@Test
func byteConvenienceMethodsRetainOffsetsAndNames(): Unit {
    let regex = BytesRegex("(?<id>a+)")
    let text = "zaaa ba".toArray()
    @Expect(regex.shortestMatch(text), Some(2))
    @Expect(regex.shortestMatchAt(text, 3), Some(4))
    @Expect(regex.shortestMatchAt(text, text.size), None<Int64>)
    let locations = regex.captureLocations()
    match (regex.capturesRead(locations, text)) {
        case Some(hit) => @Expect(hit.start, 1); @Expect(hit.end, 4)
        case None => throw Exception("expected capture")
    }
    match (regex.captures(text)) {
        case Some(caps) =>
            match (caps.name("id")) {
                case Some(hit) => @Expect(hit.bytes, "aaa".toArray())
                case None => throw Exception("expected named capture")
            }
            @Expect(caps.name("missing").isNone(), true)
            @Expect(caps.name("").isNone(), true)
        case None => throw Exception("expected capture")
    }
    let split = BytesRegex(",")
    @Expect(split.splitN("a,b,c".toArray(), 2), ["a".toArray(), "b,c".toArray()])
    @Expect(split.splitN(text, 0).size, 0)
    @Expect(BytesRegexSet(["a", "b"]).len(), 2)
    @Expect(BytesRegexSet(Array<String>()).len(), 0)
}

@Test
func clonedByteIteratorsKeepIndependentCursors(): Unit {
    let captures = BytesRegex("a").capturesIter("aba".toArray())
    @Expect(captures.next().isSome(), true)
    let copied = captures.clone()
    @Expect(captures.next().isSome(), true)
    @Expect(captures.next().isNone(), true)
    match (copied.next()) {
        case Some(caps) => @Expect(caps.getMatch().start, 2)
        case None => throw Exception("clone lost cursor")
    }
    @Expect(copied.next().isNone(), true)
    let split = BytesRegex(",").splitIter("a,b,c".toArray())
    @Expect(split.next(), Some("a".toArray()))
    let duplicate = split.clone()
    @Expect(split.next(), Some("b".toArray()))
    @Expect(split.next(), Some("c".toArray()))
    @Expect(split.next().isNone(), true)
    @Expect(duplicate.next(), Some("b".toArray()))
    @Expect(duplicate.next(), Some("c".toArray()))
    @Expect(duplicate.next().isNone(), true)
}
