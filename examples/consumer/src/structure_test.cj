package regex_consumer

import regex4cj.*
import std.collection.*

@Test
func astKeepsTheGroupThatHirCollapses(): Unit {
    let pattern = "(?<id>[0-9]{6})"
    let ast = Ast.parse(pattern)
    @Expect(ast.label, "group")
    @Expect(ast.captureName, "id")
    @Expect(ast.captureIndex, 1)
    @Expect(ast.span.startOffset, 0)
    @Expect(ast.span.endColumn, 16)
    let seen = ArrayList<String>()
    ast.visit({node => seen.add(node.label)})
    @Expect(seen.size, 3)
    @Expect(seen[0], "group")
    @Expect(seen[1], "repeat")
    @Expect(seen[2], "class")
    @Expect(ast.toPattern(), pattern)
    @Expect(ast.toHir().properties().minimumLen(), Some(UInt64(6)))
    @Expect(ast.toHir().properties().maximumLen(), Some(UInt64(6)))
    @Expect(Hir.parse("(?:a)").toPattern(), "a")
    @Expect(Ast.parse("(?:a)").label, "group")
    @Expect(Ast.parse("a").label, "literal")
    @Expect(Ast.parse("[a]").label, "class")
    @Expect(Ast.parse("\\d").label, "perl")
    @Expect(Ast.parse("\\pL").label, "unicode")
    let verbose = Ast.parse("(?x: a b)")
    @Expect(verbose.subs()[0].label, "concat")
    @Expect(verbose.subs()[0].span.startOffset, 4)
    @Expect(Ast.parse("(?i:a)").toHir().toPattern(), Hir.parse("(?i:a)").toPattern())
    @Expect(Ast.parse("(?U)a?").toHir().toPattern(), Hir.parse("(?U)a?").toPattern())
    @Expect(Ast.parse("(?mR:^)").toHir().toPattern(), Hir.parse("(?mR:^)").toPattern())
    @Expect(Ast.parse("(?-u:\\w)").toHir().toPattern(), Hir.parse("(?-u:\\w)").toPattern())
    let parser = SyntaxParser()
    parser.caseInsensitive = true
    @Expect(parser.parseHir("a").toPattern(), parser.translate(parser.parseAst("a")).toPattern())
    parser.caseInsensitive = false
    parser.multiLine = true
    parser.crlf = true
    @Expect(parser.parseHir("^").toPattern(), parser.translate(parser.parseAst("^")).toPattern())
    parser.octal = true
    @Expect(parser.parseHir("\\0").toPattern(), parser.translate(parser.parseAst("\\0")).toPattern())
    @Expect(Ast.parse("[a&&b]").toHir().toPattern(), Hir.parse("[a&&b]").toPattern())
    @Expect(Ast.parse("[ab&&b]").toHir().toPattern(), Hir.parse("[ab&&b]").toPattern())
    @Expect(Ast.parse("[[:digit:]]").toHir().toPattern(), Hir.parse("[[:digit:]]").toPattern())
    @Expect(Ast.parse("[[:^alpha:]]").toPattern(), "[[:^alpha:]]")
    let order = ArrayList<String>()
    ast.walk({node => order.add("enter ${node.label}")}, {node => order.add("leave ${node.label}")})
    @Expect(order[0], "enter group")
    @Expect(order[order.size - 1], "leave group")
    let stopped = ArrayList<String>()
    let finished = Ast.parse("ab").walkUntil(
        {
            node =>
                stopped.add(node.label)
                node.label != "literal"
        },
        {node => node.label.size >= 0}
    )
    @Expect(finished, false)
    @Expect(stopped.size, 2)
    @Expect(stopped[0], "concat")
    @Expect(stopped[1], "literal")
    try {
        Regex("(")
        @Expect(false, true)
    } catch (e: RegexError) {
        @Expect(e.phase, "parse")
        @Expect(e.name, "GroupUnclosed")
        match (e.primary) {
            case Some(span) => @Expect(span.startOffset, 0)
            case None => @Expect(false, true)
        }
        match (e.auxiliary) {
            case Some(_) => @Expect(false, true)
            case None => ()
        }
    }
}

@Test
func syntaxValidationKeepsTranslationSeparate(): Unit {
    for (pattern in ["*", "a{3,2}", #"\q"#, "(?ii:a)", "(?<x>a)(?<x>b)"]) {
        var rejected = false
        try {
            Ast.parse(pattern)
        } catch (_: RegexError) {
            rejected = true
        }
        @Expect(rejected, true)
    }
    let parser = SyntaxParser()
    parser.nestLimit = 1
    var rejected = false
    try {
        parser.parseAst("((a))")
    } catch (_: RegexError) {
        rejected = true
    }
    @Expect(rejected, true)
    // These are valid syntax; their semantics are checked by translation.
    let ast = Ast.parse(#"(?-u:\xFF)"#)
    parser.utf8 = false
    @Expect(parser.translate(ast).properties().isUtf8(), false)
}

@Test
func octalAstClassesKeepTheirValueAndSpelling(): Unit {
    let parser = SyntaxParser()
    parser.octal = true
    for (pattern in [#"\123"#, #"[\123]"#, #"[\0-\7]"#, #"[\377-\777]"#]) {
        let ast = parser.parseAst(pattern)
        @Expect(ast.toPattern(), pattern)
        @Expect(parser.translate(ast).toPattern(), parser.parseHir(pattern).toPattern())
    }
    @Expect(parser.translate(parser.parseAst(#"[\123]"#)).toPattern(), "S")
    @Expect(RegexBuilder(#"(?i:[\141-\172])"#).octal(true).build().isMatch("Z"), true)
    var rejected = false
    try { Ast.parse(#"[\123]"#) } catch (_: RegexError) { rejected = true }
    @Expect(rejected, true)
}

@Test
func hirExposesSixDigitStructure(): Unit {
    let h = Hir.parse("[0-9]{6}")
    @Expect(h.properties().minimumLen(), Some(UInt64(6)))
    @Expect(h.properties().maximumLen(), Some(UInt64(6)))
    match (h.kind()) {
        case HirKind.Repetition(rep) =>
            @Expect(rep.min, UInt32(6))
            @Expect(rep.max, Some(UInt32(6)))
            @Expect(rep.greedy, true)
            match (rep.sub.kind()) {
                case HirKind.Class(c) =>
                    @Expect(c.isBytes, false)
                    @Expect(c.ranges().size, 1)
                    @Expect(c.ranges()[0].start, 48)
                    @Expect(c.ranges()[0].end, 57)
                case _ => throw Exception("expected digit class")
            }
        case _ => throw Exception("expected repetition")
    }
    @Expect(h.subs().size, 1)
    @Expect(Hir.parse("中文").properties().minimumLen(), Some(UInt64(6)))
}

@Test
func hirSmartConstructorsPreserveSnapshots(): Unit {
    let bytes = [UInt8(97)]
    let h = Hir.literal(bytes)
    bytes[0] = UInt8(98)
    match (h.kind()) {
        case HirKind.Literal(out) =>
            @Expect(out[0], UInt8(97))
            out[0] = UInt8(99)
        case _ => throw Exception("expected literal")
    }
    match (h.kind()) {
        case HirKind.Literal(out) => @Expect(out[0], UInt8(97))
        case _ => throw Exception("expected literal")
    }
    let merged = Hir.concat([h, Hir.empty(), Hir.concat([Hir.literal("b".toArray()), Hir.literal("中".toArray())])])
    match (merged.kind()) {
        case HirKind.Literal(out) => @Expect(out.size, 5)
        case _ => throw Exception("adjacent literals must merge")
    }
    let c = Hir.unicodeClass([HirRange(122, 97), HirRange(98, 100)])
    match (c.kind()) {
        case HirKind.Class(value) =>
            let ranges = value.ranges()
            @Expect(ranges.size, 1)
            ranges[0] = HirRange(0, 1)
            @Expect(value.ranges()[0].start, 97)
        case _ => throw Exception("expected normalized class")
    }
    let nodes = [h, c]
    let cat = Hir.concat(nodes)
    nodes[0] = Hir.empty()
    let children = cat.subs()
    children[0] = Hir.empty()
    @Expect(cat.subs()[0].properties().minimumLen(), Some(UInt64(1)))
}

@Test
func hirLengthOverflowAndEmptyAreDistinctFromFailure(): Unit {
    @Expect(Hir.empty().properties().minimumLen(), Some(UInt64(0)))
    @Expect(Hir.fail().properties().minimumLen(), None)
    @Expect(Hir.repetition(0, Some(UInt32(0)), true, Hir.fail()).properties().maximumLen(), Some(UInt64(0)))
    var huge = Hir.literal([UInt8(97)])
    for (_ in 0..3) {
        huge = Hir.repetition(UInt32(0xFFFFFFFF), Some(UInt32(0xFFFFFFFF)), true, huge)
    }
    @Expect(huge.properties().minimumLen(), Some((UInt64(0xFFFFFFFF) << 32) | UInt64(0xFFFFFFFF)))
    @Expect(huge.properties().maximumLen(), None)
    @Expect(Hir.parse("a*").properties().maximumLen(), None)
}

@Test
func hirRejectsUnimplementedStructuresExplicitly(): Unit {
    match (Hir.parse("a|bc").kind()) {
        case HirKind.Alternation(parts) => @Expect(parts.size, 2)
        case _ => throw Exception("expected alternation")
    }
    @Expect(Hir.parse(".").toPattern().contains("["), true)
    var invalid = false
    try {
        Hir.parse("(")
    } catch (_: RegexError) {
        invalid = true
    }
    @Expect(invalid, true)
    var badRange = false
    try {
        Hir.byteClass([HirRange(0, 256)])
    } catch (_: Exception) {
        badRange = true
    }
    @Expect(badRange, true)
    let raw = Hir.parse(#"(?-u:\xFF)"#, false)
    match (raw.kind()) {
        case HirKind.Literal(bytes) => @Expect(bytes[0], UInt8(255))
        case _ => throw Exception("expected byte literal")
    }
}

@Test
func reviewedAstUnicodeAndBoundaryRoundTrips(): Unit {
    for (pattern in ["(?-u:é)", "(?i-u:中)", #"\b{start}"#, #"\b{end-half}"#, #"\<"#]) {
        @Expect(Ast.parse(pattern).toHir().toPattern(), Hir.parse(pattern).toPattern())
    }
    @Expect(Ast.parse(#"\x{4e2d}"#).toPattern(), #"\x{4E2D}"#)
    @Expect(Ast.parse(#"\u{0001}"#).toPattern(), #"\u{1}"#)
}
