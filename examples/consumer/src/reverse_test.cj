package regex_consumer

import cjregex.*

@Test
func reverseSearchReportsTheMatchStart(): Unit {
    match (ReverseNfa("baz[0-9]+").search("foobaz12345bar")) {
        case Some(offset) => @Expect(offset, 3)
        case None => throw Exception("reverse search missed baz")
    }
    match (ReverseNfa("中").search("a中b")) {
        case Some(offset) => @Expect(offset, 1)
        case None => throw Exception("reverse search missed the scalar")
    }
    match (ReverseNfa("a+?").search("aaa")) {
        case Some(offset) => @Expect(offset, 2)
        case None => throw Exception("non-greedy reverse search missed")
    }
    match (ReverseNfa("^a").search("ba")) {
        case Some(_) => throw Exception("anchored reverse search must miss")
        case None => ()
    }
}
