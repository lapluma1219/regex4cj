package regex_consumer

import cjregex.*

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
func dfaReverseRecoveryRetainsPriorityAndContext(): Unit {
    match (DenseDfa("a|ba").search("ba")) {
        case Some(hit) => @Expect(hit.start, 0)
        case None => throw Exception("DFA missed an alternative")
    }
    match (SparseDfa(#"(?-u:a\B)"#).search("ab")) {
        case Some(hit) => @Expect(hit.text, "a")
        case None => throw Exception("DFA lost assertion context")
    }
    @Expect(DenseDfa("^[a&&b]").search("a").isNone(), true)
    match (DenseDfa(#"(?-u:\b\bfoo)"#).search(" foo")) {
        case Some(hit) => @Expect(hit.start, 1)
        case None => throw Exception("DFA missed consecutive assertions")
    }
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
