package regex_consumer

import std.collection.*
import cjregex.*

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
