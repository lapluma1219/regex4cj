use regex_syntax::hir::literal::{ExtractKind, Extractor};
use regex_syntax::utf8::Utf8Sequences;

fn hex_bytes(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

pub fn literals(kind: &str, pattern: &str) {
    let hir = match regex_syntax::Parser::new().parse(pattern) {
        Ok(hir) => hir,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let mut extractor = Extractor::new();
    if kind == "suffix" {
        extractor.kind(ExtractKind::Suffix);
    } else if kind != "prefix" {
        eprintln!("literal kind must be prefix or suffix");
        std::process::exit(2);
    }
    let seq = extractor.extract(&hir);
    match seq.literals() {
        None => println!("infinite"),
        Some(lits) => {
            println!("finite\t{}", lits.len());
            for lit in lits {
                let tag = if lit.is_exact() { "exact" } else { "inexact" };
                println!("{tag}\t{}", hex_bytes(lit.as_bytes()));
            }
        }
    }
}

pub fn utf8(start: u32, end: u32) {
    let Some(from) = char::from_u32(start) else {
        eprintln!("invalid scalar range");
        std::process::exit(2);
    };
    let Some(to) = char::from_u32(end) else {
        eprintln!("invalid scalar range");
        std::process::exit(2);
    };
    if from > to {
        eprintln!("invalid scalar range");
        std::process::exit(2);
    }
    let mut first = true;
    let mut out = String::new();
    for seq in Utf8Sequences::new(from, to) {
        if !first {
            out.push('\n');
        }
        first = false;
        out.push_str(&format!("{seq:?}"));
    }
    println!("{out}");
}
