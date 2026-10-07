package regex_consumer

import regex4cj.*

@Test
func searchInputConfigurationPreservesSourceAndRejectsRanges(): Unit {
    let bytes = "a中b".toArray()
    let original = SearchInput(bytes)
    bytes[0] = 122
    @Expect(original.bytes[0], UInt8(97))
    let changed = original.span(1, 4).selectPattern(2).withEarliest(true)
    @Expect(original.start, 0)
    @Expect(original.end, 5)
    @Expect(original.isAnchored(), false)
    @Expect(original.selectedPattern(), -1)
    @Expect(changed.start, 1)
    @Expect(changed.end, 4)
    @Expect(changed.isAnchored(), true)
    @Expect(changed.selectedPattern(), 2)
    @Expect(changed.earliest, true)
    @Expect(changed.anchored(false).selectedPattern(), -1)
    coverageRejects({ => original.span(-1, 1); () })
    coverageRejects({ => original.span(4, 3); () })
    coverageRejects({ => original.span(0, 6); () })
    @Expect(SearchInput([UInt8(255)]).utf8, false)
    @Expect(PikeVM(".").search(changed.selectPattern(0)).isSome(), true)
}

@Test
func pikeCacheResetsCapturedStateAfterMiss(): Unit {
    let nfa = ThompsonNfa(["(?<x>a)", "b"], 0, true)
    let cache = PikeCache()
    @Expect(cache.patternId(), -1)
    @Expect(cache.groupStart(-1), -1)
    @Expect(cache.groupEnd(0), -1)
    @Expect(nfa.search(SearchInput("za"), cache).isSome(), true)
    @Expect(cache.hasMatch(), true)
    @Expect(cache.patternId(), 0)
    @Expect(cache.groupStart(1), 1)
    @Expect(cache.groupEnd(1), 2)
    @Expect(nfa.search(SearchInput("z"), cache).isNone(), true)
    @Expect(cache.hasMatch(), false)
    @Expect(cache.patternId(), -1)
    @Expect(cache.groupStart(1), -1)
    @Expect(cache.groupEnd(1), -1)
    cache.reset()
    @Expect(cache.activeThreads(), 0)
}

@Test
func graphInspectionChecksIndicesAndReachableAccept(): Unit {
    let re = Regex("a|bc")
    @Expect(re.nfaStateCount() > 0, true)
    @Expect(re.nfaStart() >= 0, true)
    var accepts = 0
    for (i in 0..re.nfaStateCount()) {
        if (re.nfaOp(i) == "accept") { accepts++ }
        @Expect(re.nfaNext(i) < re.nfaStateCount(), true)
        @Expect(re.nfaAlternate(i) < re.nfaStateCount(), true)
    }
    @Expect(accepts, 1)
    coverageRejects({ => re.nfaOp(-1); () })
    coverageRejects({ => re.nfaNext(re.nfaStateCount()); () })
    coverageRejects({ => re.nfaAlternate(-1); () })
    let vm = PikeVM(["a", "b"])
    @Expect(vm.patternCount(), 2)
    @Expect(vm.memoryUsage() > 0, true)
    for (p in 0..2) {
        @Expect(vm.startState(p) >= 0, true)
        for (i in 0..vm.stateCount(p)) {
            @Expect(vm.opName(p, i).size > 0, true)
            vm.opNext(p, i)
            vm.opAlternate(p, i)
        }
    }
    coverageRejects({ => vm.startState(-1); () })
    coverageRejects({ => vm.opName(0, vm.stateCount(0)); () })
    @Expect(vm.whichOverlapping(SearchInput("ab")), [0, 1])
    @Expect(vm.isMatch(SearchInput("z")), false)
    @Expect(vm.searchAll("aba").size, 3)
    @Expect(ThompsonNfa(Array<String>()).patternCount(), 0)
}
