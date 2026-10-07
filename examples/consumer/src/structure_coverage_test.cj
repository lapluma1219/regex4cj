package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func syntaxSpansAndErrorsRetainCoordinates(): Unit {
    @Expect(HirUnsupportedError("unsupported node").toString().contains("unsupported node"), true)
    let span = RegexErrorSpan(1, 1, 2, 4, 1, 3)
    @Expect(span.text(), "1.1.2-4.1.3")
    let error = RegexError(RegexErrorKind.Syntax, "bad", -1, "parse", "Example", Some(span), Some(span))
    @Expect(error.toString(), "bad")
    @Expect(error.structure(), "parse\tExample\nspan\t1.1.2-4.1.3\naux\t1.1.2-4.1.3")
    @Expect(RegexError(RegexErrorKind.CompiledTooBig, "limit", 3).structure(), "\t\nspan\t-\naux\t-")
    @Expect(AstSpan(1, 1, 2, 4, 1, 3).text(), span.text())
    let leaves = [AstClassItem("Lit", 97, 97, false, Array<AstClassItem>(), "")]
    let union = AstClassItem("Union", 0, 0, false, leaves, "")
    leaves[0] = AstClassItem("Empty", 0, 0, false, Array<AstClassItem>(), "")
    @Expect(union.children[0].label, "Lit")
    @Expect(union.text().contains("Lit"), true)
}

func classOf(hir: Hir): HirClass {
    match (hir.kind()) {
        case HirKind.Class(value) => value
        case _ => throw Exception("expected a class")
    }
}

@Test
func hirClassAlgebraChecksMembershipAndEmptyResults(): Unit {
    let a = classOf(Hir.parse("[a-c]"))
    let b = classOf(Hir.parse("[b-d]"))
    @Expect(PikeVM(a.union(b)).searchAll("abcdz").size, 4)
    @Expect(PikeVM(a.intersect(b)).searchAll("abcdz").size, 2)
    @Expect(PikeVM(a.difference(b)).searchAll("abcdz").size, 1)
    @Expect(PikeVM(a.negate()).searchAll("abc🙂z").size, 2)
    @Expect(PikeVM(a.caseFold()).searchAll("aBcD").size, 3)
    @Expect(PikeVM(a.difference(a)).search("a").isNone(), true)
    @Expect(PikeVM(Hir.dotExcept(false, 10)).search("\n").isNone(), true)
    @Expect(PikeVM(Hir.dotExcept(true, 10)).search("A").isSome(), true)
}

@Test
func hirTraversalVisitsEnterLeaveAndHonorsBothStops(): Unit {
    let tree = Hir.parse("(a|b)c")
    let enter = ArrayList<String>()
    let leave = ArrayList<String>()
    tree.walk({h => enter.add(h.toPattern())}, {h => leave.add(h.toPattern())})
    @Expect(enter.size, leave.size)
    @Expect(enter[0], leave[leave.size - 1])
    let count = [0]
    @Expect(tree.walkUntil({h => count[0]++; false}, {h => true}), false)
    @Expect(count[0], 1)
    count[0] = 0
    @Expect(tree.walkUntil({h => true}, {h => count[0]++; false}), false)
    @Expect(count[0], 1)
    @Expect(tree.walkUntil({h => true}, {h => true}), true)
    let ast = Ast.parse("[a-c]")
    @Expect(ast.shape().contains("Range"), true)
    let leaves = [0]
    @Expect(ast.walkUntil({h => true}, {h => leaves[0]++; false}), false)
    @Expect(leaves[0], 1)
}
