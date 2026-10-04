package regex_consumer

import cjregex.*

@Test
func denseAndSparseDfaReportTheSameSpan(): Unit {
    match (DenseDfa("baz[0-9]+").search("foobaz12345bar")) {
        case Some(hit) =>
            @Expect(hit.start, 3)
            @Expect(hit.end, 11)
        case None => throw Exception("dense DFA missed baz")
    }
    match (SparseDfa("a+?").search("aaa")) {
        case Some(hit) => @Expect(hit.text, "a")
        case None => throw Exception("sparse DFA missed the short match")
    }
    match (DenseDfa("^a").search("ba")) {
        case Some(_) => throw Exception("anchored DFA must miss")
        case None => ()
    }
    var rejected = false
    try {
        DenseDfa("\\bfoo")
    } catch (e: Exception) {
        rejected = e.toString().contains("Unicode word boundary")
    }
    @Expect(rejected, true)
}
