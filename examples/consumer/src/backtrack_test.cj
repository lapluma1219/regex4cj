package regex_consumer

import cjregex.*

@Test
func boundedBacktrackerReportsCapturesAndBudgetErrors(): Unit {
    match (BoundedBacktracker("(a+)(b+)", 1048576).search("aaabbb")) {
        case None => throw Exception("backtracker missed aaabbb")
        case Some(caps) =>
            match (caps.get(1)) {
                case Some(group) => @Expect(group.text, "aaa")
                case None => throw Exception("missing first group")
            }
            match (caps.get(2)) {
                case Some(group) => @Expect(group.text, "bbb")
                case None => throw Exception("missing second group")
            }
    }
    match (BoundedBacktracker("a+?", 1048576).search("aaa")) {
        case Some(found) => @Expect(found.getMatch().text, "a")
        case None => throw Exception("non-greedy backtracker missed")
    }
    var rejected = false
    try {
        BoundedBacktracker("a+", 1).search("aaaa")
    } catch (e: Exception) {
        rejected = e.toString().contains("haystack of length 4 is too long")
    }
    @Expect(rejected, true)
    @Expect(BoundedBacktracker("a+", 64).maxHaystackLen() > 0, true)
}
