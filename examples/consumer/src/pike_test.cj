package regex_consumer

import cjregex.*

@Test
func pikeReportsPatternSpanAndCaptures(): Unit {
    let vm = PikeVM("(?<id>[0-9]{6})")
    match (vm.search("id=123456")) {
        case Some(hit) =>
            @Expect(hit.pattern, 0)
            @Expect(hit.start(), 3)
            @Expect(hit.end(), 9)
            match (hit.captures.get(1)) {
                case Some(group) => @Expect(group.asStr(), "123456")
                case None => throw Exception("missing capture")
            }
        case None => throw Exception("expected a match")
    }
    @Expect(vm.cache.hasMatch(), true)
    @Expect(vm.cache.groupStart(1), 3)
    vm.reset()
    @Expect(vm.cache.hasMatch(), false)
    @Expect(vm.cache.groupStart(1), -1)
    match (vm.search("plain")) {
        case Some(_) => throw Exception("stale match leaked")
        case None => @Expect(vm.cache.groupStart(1), -1)
    }
    let fromHir = PikeVM(Hir.parse("(?<id>[0-9]{6})"))
    match (fromHir.search("id=123456")) {
        case Some(hit) =>
            @Expect(hit.pattern, 0)
            @Expect(hit.start(), 3)
            @Expect(hit.end(), 9)
            match (hit.captures.get(1)) {
                case Some(group) => @Expect(group.asStr(), "123456")
                case None => throw Exception("missing capture from HIR")
            }
        case None => throw Exception("HIR search missed")
    }
    let both = PikeVM(["(?<id>[0-9]{6})", "id"])
    match (both.search("id=123456")) {
        case Some(hit) =>
            @Expect(hit.pattern, 1)
            @Expect(hit.start(), 0)
            @Expect(hit.end(), 2)
        case None => throw Exception("the earlier literal must win")
    }
}

@Test
func pikeAnchoredSearchSeesTextOutsideTheRange(): Unit {
    let vm = PikeVM("\\b123\\b")
    match (vm.search("foo123bar", 3, 6, true)) {
        case Some(_) => throw Exception("letters outside the range still break the boundary")
        case None => ()
    }
    match (vm.search("foo123bar", 3, 6, false)) {
        case Some(_) => throw Exception("unanchored search uses the same surrounding text")
        case None => ()
    }
    @Expect(vm.stateCount(0) > 0, true)
    var sawAccept = false
    for (i in 0..vm.stateCount(0)) {
        if (vm.opName(0, i) == "accept") {
            sawAccept = true
        }
    }
    @Expect(sawAccept, true)
    var rejected = false
    try {
        vm.search("ab", 2, 1, false)
    } catch (_: Exception) {
        rejected = true
    }
    @Expect(rejected, true)
}

@Test
func anchoredSearchIsNotTheSameAsACaret(): Unit {
    let vm = PikeVM("(?m)^a")
    match (vm.search("b\na", 0, 3, false)) {
        case Some(hit) => @Expect(hit.start(), 2)
        case None => throw Exception("multiline caret can match after a newline")
    }
    match (vm.search("b\na", 0, 3, true)) {
        case Some(_) => throw Exception("anchored search starts only at the range start")
        case None => ()
    }
}
