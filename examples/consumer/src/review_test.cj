package regex_consumer

import cjregex.*

@Test
func reviewedAstUnicodeAndBoundaryRoundTrips(): Unit {
    for (pattern in ["(?-u:é)", "(?i-u:中)", #"\b{start}"#, #"\b{end-half}"#, #"\<"#]) {
        @Expect(Ast.parse(pattern).toHir().toPattern(), Hir.parse(pattern).toPattern())
    }
    @Expect(Ast.parse(#"\x{4e2d}"#).toPattern(), #"\x{4E2D}"#)
    @Expect(Ast.parse(#"\u{0001}"#).toPattern(), #"\u{1}"#)
}

@Test
func reviewedPikeByteRangesAndEmptyPatternSet(): Unit {
    let vm = PikeVM("a")
    match (vm.search("中a", 1, 4, false)) {
        case Some(hit) => @Expect(hit.start(), 3)
        case None => throw Exception("search must resume at the next scalar boundary")
    }
    @Expect(vm.search("中a", 1, 4, true).isNone(), true)
    @Expect(vm.cache.hasMatch(), false)
    @Expect(PikeVM(".").search("中a", 0, 2, false).isNone(), true)
    let empty = PikeVM(Array<String>())
    @Expect(empty.patternCount(), 0)
    @Expect(empty.search("中a").isNone(), true)
    @Expect(PikeVM(Array<Hir>()).search("").isNone(), true)
}
