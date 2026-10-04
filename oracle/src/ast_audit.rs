use regex_syntax::ast::{self, Ast, Position, Span};

fn pos(p: &Position) -> String {
    format!("{}.{}.{}", p.offset, p.line, p.column)
}
fn sp(s: &Span) -> String {
    format!("{}-{}", pos(&s.start), pos(&s.end))
}
fn shape(ast: &Ast) -> String {
    match ast {
        Ast::Empty(s) => format!("E({})", sp(s)),
        Ast::Flags(f) => format!("F({})", sp(&f.span)),
        Ast::Literal(l) => format!("L({},{:?},{})", sp(&l.span), l.kind, u32::from(l.c)),
        Ast::Dot(s) => format!("D({})", sp(s)),
        Ast::Assertion(a) => format!("A({},{:?})", sp(&a.span), a.kind),
        Ast::ClassPerl(c) => format!("P({},{},{:?})", sp(&c.span), c.negated, c.kind),
        Ast::ClassUnicode(c) => format!("U({},{},{:?})", sp(&c.span), c.negated, c.kind),
        Ast::ClassBracketed(c) => format!("B({},{},{})", sp(&c.span), c.negated, set(&c.kind)),
        Ast::Repetition(r) => format!("R({},{},{:?},{})", sp(&r.span), r.greedy, r.op.kind, shape(&r.ast)),
        Ast::Group(g) => format!("G({},{},{})", sp(&g.span), group(&g.kind), shape(&g.ast)),
        Ast::Concat(c) => format!(
            "C({},{})",
            sp(&c.span),
            c.asts.iter().map(shape).collect::<Vec<_>>().join(",")
        ),
        Ast::Alternation(a) => format!(
            "O({},{})",
            sp(&a.span),
            a.asts.iter().map(shape).collect::<Vec<_>>().join(",")
        ),
    }
}
fn group(kind: &ast::GroupKind) -> String {
    match kind {
        ast::GroupKind::CaptureIndex(i) => format!("I{i}"),
        ast::GroupKind::CaptureName { starts_with_p, name } => {
            format!("N{}:{}:{}", if *starts_with_p { 1 } else { 0 }, name.index, name.name)
        }
        ast::GroupKind::NonCapturing(_) => "X".into(),
    }
}
fn set(kind: &ast::ClassSet) -> String {
    match kind {
        ast::ClassSet::Item(item) => item_shape(item),
        ast::ClassSet::BinaryOp(op) => format!("Op({:?},{},{},{})", op.kind, sp(&op.span), set(&op.lhs), set(&op.rhs)),
    }
}
fn item_shape(item: &ast::ClassSetItem) -> String {
    match item {
        ast::ClassSetItem::Empty(span) => format!("Empty({})", sp(span)),
        ast::ClassSetItem::Literal(l) => format!("Lit({},{:?},{})", sp(&l.span), l.kind, u32::from(l.c)),
        ast::ClassSetItem::Range(r) => format!(
            "Range({},{},{:?},{},{},{:?},{})",
            sp(&r.span),
            sp(&r.start.span),
            r.start.kind,
            u32::from(r.start.c),
            sp(&r.end.span),
            r.end.kind,
            u32::from(r.end.c)
        ),
        ast::ClassSetItem::Union(u) => format!(
            "Union({},{})",
            sp(&u.span),
            u.items.iter().map(item_shape).collect::<Vec<_>>().join(",")
        ),
        ast::ClassSetItem::Perl(c) => format!("Perl({},{},{:?})", sp(&c.span), c.negated, c.kind),
        ast::ClassSetItem::Unicode(c) => format!("Uni({},{},{:?})", sp(&c.span), c.negated, c.kind),
        ast::ClassSetItem::Bracketed(c) => format!("Nest({},{},{})", sp(&c.span), c.negated, set(&c.kind)),
        ast::ClassSetItem::Ascii(c) => format!("Ascii({},{},{:?})", sp(&c.span), c.negated, c.kind),
    }
}
fn ast_kind(kind: &ast::ErrorKind) -> &'static str {
    use ast::ErrorKind::*;
    match kind {
        CaptureLimitExceeded => "CaptureLimitExceeded",
        ClassEscapeInvalid => "ClassEscapeInvalid",
        ClassRangeInvalid => "ClassRangeInvalid",
        ClassRangeLiteral => "ClassRangeLiteral",
        ClassUnclosed => "ClassUnclosed",
        DecimalEmpty => "DecimalEmpty",
        DecimalInvalid => "DecimalInvalid",
        EscapeHexEmpty => "EscapeHexEmpty",
        EscapeHexInvalid => "EscapeHexInvalid",
        EscapeHexInvalidDigit => "EscapeHexInvalidDigit",
        EscapeUnexpectedEof => "EscapeUnexpectedEof",
        EscapeUnrecognized => "EscapeUnrecognized",
        FlagDanglingNegation => "FlagDanglingNegation",
        FlagDuplicate { .. } => "FlagDuplicate",
        FlagRepeatedNegation { .. } => "FlagRepeatedNegation",
        FlagUnexpectedEof => "FlagUnexpectedEof",
        FlagUnrecognized => "FlagUnrecognized",
        GroupNameDuplicate { .. } => "GroupNameDuplicate",
        GroupNameEmpty => "GroupNameEmpty",
        GroupNameInvalid => "GroupNameInvalid",
        GroupNameUnexpectedEof => "GroupNameUnexpectedEof",
        GroupUnclosed => "GroupUnclosed",
        GroupUnopened => "GroupUnopened",
        NestLimitExceeded(_) => "NestLimitExceeded",
        RepetitionCountInvalid => "RepetitionCountInvalid",
        RepetitionCountDecimalEmpty => "RepetitionCountDecimalEmpty",
        RepetitionCountUnclosed => "RepetitionCountUnclosed",
        RepetitionMissing => "RepetitionMissing",
        SpecialWordBoundaryUnclosed => "SpecialWordBoundaryUnclosed",
        SpecialWordBoundaryUnrecognized => "SpecialWordBoundaryUnrecognized",
        SpecialWordOrRepetitionUnexpectedEof => "SpecialWordOrRepetitionUnexpectedEof",
        UnicodeClassInvalid => "UnicodeClassInvalid",
        UnsupportedBackreference => "UnsupportedBackreference",
        UnsupportedLookAround => "UnsupportedLookAround",
        _ => "Unknown",
    }
}
fn hir_kind(kind: &regex_syntax::hir::ErrorKind) -> &'static str {
    use regex_syntax::hir::ErrorKind::*;
    match kind {
        UnicodeNotAllowed => "UnicodeNotAllowed",
        InvalidUtf8 => "InvalidUtf8",
        InvalidLineTerminator => "InvalidLineTerminator",
        UnicodePropertyNotFound => "UnicodePropertyNotFound",
        UnicodePropertyValueNotFound => "UnicodePropertyValueNotFound",
        UnicodePerlClassNotFound => "UnicodePerlClassNotFound",
        UnicodeCaseUnavailable => "UnicodeCaseUnavailable",
        _ => "Unknown",
    }
}
pub fn syntax_error(pattern: &str) {
    match regex_syntax::ParserBuilder::new().build().parse(pattern) {
        Ok(_) => println!("ok"),
        Err(regex_syntax::Error::Parse(err)) => {
            println!("parse\t{}", ast_kind(err.kind()));
            println!("span\t{}", sp(err.span()));
            match err.auxiliary_span() {
                Some(span) => println!("aux\t{}", sp(span)),
                None => println!("aux\t-"),
            }
        }
        Err(regex_syntax::Error::Translate(err)) => {
            println!("translate\t{}", hir_kind(err.kind()));
            println!("span\t{}", sp(err.span()));
            println!("aux\t-");
        }
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    }
}
pub fn ast_translate(pattern: &str, utf8: bool) {
    let tree = match ast::parse::Parser::new().parse(pattern) {
        Ok(tree) => tree,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut translator = regex_syntax::hir::translate::TranslatorBuilder::new()
        .utf8(utf8)
        .build();
    match translator.translate(pattern, &tree) {
        Ok(hir) => println!("{}", crate::hir_audit::shape(&hir)),
        Err(err) => {
            println!("translate\t{}", hir_kind(err.kind()));
            println!("span\t{}", sp(err.span()));
            println!("aux\t-");
        }
    }
}
pub fn ast_print(pattern: &str) {
    match ast::parse::Parser::new().parse(pattern) {
        Ok(tree) => println!("{tree}"),
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    }
}
pub fn parse(pattern: &str) {
    match ast::parse::Parser::new().parse(pattern) {
        Ok(tree) => println!("{}", shape(&tree)),
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    }
}
