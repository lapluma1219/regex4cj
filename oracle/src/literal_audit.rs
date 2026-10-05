use regex_syntax::hir::literal::{ExtractKind, Extractor, Literal, Seq};
use regex_syntax::utf8::Utf8Sequences;

fn parse_limit(text: &str) -> usize {
    text.parse().unwrap_or_else(|err| {
        eprintln!("{err}");
        std::process::exit(2);
    })
}

fn hex_bytes(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

pub fn literals(kind: &str, pattern: &str) {
    literals_config("10", "10", "100", "250", kind, pattern);
}

pub fn literals_config(class: &str, repeat: &str, len: &str, total: &str, kind: &str, pattern: &str) {
    let class = parse_limit(class);
    let repeat = parse_limit(repeat);
    let len = parse_limit(len);
    let total = parse_limit(total);
    let hir = match regex_syntax::Parser::new().parse(pattern) {
        Ok(hir) => hir,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let mut extractor = Extractor::new();
    extractor
        .limit_class(class)
        .limit_repeat(repeat)
        .limit_literal_len(len)
        .limit_total(total);
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

fn die(message: &str) -> ! {
    eprintln!("{message}");
    std::process::exit(2);
}

fn hex_value(byte: u8) -> Result<u8, String> {
    match byte {
        b'0'..=b'9' => Ok(byte - b'0'),
        b'a'..=b'f' => Ok(byte - b'a' + 10),
        b'A'..=b'F' => Ok(byte - b'A' + 10),
        _ => Err("invalid hex digit".into()),
    }
}

fn parse_hex_bytes(text: &str) -> Vec<u8> {
    if text.len() % 2 != 0 {
        die("hex text must have an even length");
    }
    let raw = text.as_bytes();
    let mut out = Vec::with_capacity(text.len() / 2);
    let mut i = 0;
    while i < raw.len() {
        let hi = hex_value(raw[i]).unwrap_or_else(|err| die(&err));
        let lo = hex_value(raw[i + 1]).unwrap_or_else(|err| die(&err));
        out.push((hi << 4) | lo);
        i += 2;
    }
    out
}

fn parse_piece(token: &str) -> Literal {
    let Some((tag, hex)) = token.split_once(':') else {
        die("invalid literal");
    };
    let bytes = parse_hex_bytes(hex);
    match tag {
        "E" => Literal::exact(bytes),
        "I" => Literal::inexact(bytes),
        _ => die("invalid literal"),
    }
}

fn parse_seq(spec: &str) -> Seq {
    if spec == "inf" {
        return Seq::infinite();
    }
    if spec == "empty" {
        return Seq::empty();
    }
    let mut seq = Seq::empty();
    for token in spec.split(',') {
        seq.push(parse_piece(token));
    }
    seq
}

fn print_seq(seq: &Seq) {
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

fn print_common(bytes: Option<&[u8]>) {
    match bytes {
        None => println!("none"),
        Some(value) => println!("bytes\t{}", hex_bytes(value)),
    }
}

fn print_len(len: Option<usize>) {
    match len {
        None => println!("none"),
        Some(value) => println!("{value}"),
    }
}

fn apply_step(seq: &mut Seq, step: &str) {
    if step == "minimize" {
        seq.minimize_by_preference();
        return;
    }
    if step == "reverse" {
        seq.reverse_literals();
        return;
    }
    if step == "sort" {
        seq.sort();
        return;
    }
    if step == "inexact" {
        seq.make_inexact();
        return;
    }
    if step == "dedup" {
        seq.dedup();
        return;
    }
    if step == "optimize-prefix" {
        seq.optimize_for_prefix_by_preference();
        return;
    }
    if step == "optimize-suffix" {
        seq.optimize_for_suffix_by_preference();
        return;
    }
    if let Some(len) = step.strip_prefix("keep-first:") {
        let len = len.parse().unwrap_or_else(|err| die(&format!("{err}")));
        seq.keep_first_bytes(len);
        return;
    }
    if let Some(len) = step.strip_prefix("keep-last:") {
        let len = len.parse().unwrap_or_else(|err| die(&format!("{err}")));
        seq.keep_last_bytes(len);
        return;
    }
    die("unknown literal step");
}

pub fn literal_op(args: &[String]) {
    let op = args.first().map(String::as_str).unwrap_or("");
    match op {
        "cross-forward" | "cross-reverse" | "union" | "union-empty" if args.len() == 3 => {
            let mut left = parse_seq(&args[1]);
            let mut right = parse_seq(&args[2]);
            match op {
                "cross-forward" => left.cross_forward(&mut right),
                "cross-reverse" => left.cross_reverse(&mut right),
                "union" => left.union(&mut right),
                "union-empty" => left.union_into_empty(&mut right),
                _ => unreachable!(),
            }
            print_seq(&left);
        }
        "keep-first" | "keep-last" if args.len() == 3 => {
            let len = args[1].parse().unwrap_or_else(|err| die(&format!("{err}")));
            let mut seq = parse_seq(&args[2]);
            if op == "keep-first" {
                seq.keep_first_bytes(len);
            } else {
                seq.keep_last_bytes(len);
            }
            print_seq(&seq);
        }
        "prefix" | "suffix" if args.len() == 2 => {
            let seq = parse_seq(&args[1]);
            if op == "prefix" {
                print_common(seq.longest_common_prefix());
            } else {
                print_common(seq.longest_common_suffix());
            }
        }
        "minimize" | "reverse" | "sort" | "inexact" | "dedup" | "optimize-prefix" | "optimize-suffix"
            if args.len() == 2 => {
            let mut seq = parse_seq(&args[1]);
            apply_step(&mut seq, op);
            print_seq(&seq);
        }
        "finite" | "empty" | "exact" | "inexact-all" if args.len() == 2 => {
            let seq = parse_seq(&args[1]);
            let answer = match op {
                "finite" => seq.is_finite(),
                "empty" => seq.is_empty(),
                "exact" => seq.is_exact(),
                "inexact-all" => seq.is_inexact(),
                _ => unreachable!(),
            };
            println!("{answer}");
        }
        "max-union" | "max-cross" if args.len() == 3 => {
            let left = parse_seq(&args[1]);
            let right = parse_seq(&args[2]);
            let count = if op == "max-union" {
                left.max_union_len(&right)
            } else {
                left.max_cross_len(&right)
            };
            print_len(count);
        }
        "len" | "min-len" | "max-len" if args.len() == 2 => {
            let seq = parse_seq(&args[1]);
            let count = match op {
                "len" => seq.len(),
                "min-len" => seq.min_literal_len(),
                "max-len" => seq.max_literal_len(),
                _ => unreachable!(),
            };
            print_len(count);
        }
        "pipe" if args.len() == 3 => {
            let mut seq = parse_seq(&args[2]);
            for step in args[1].split('|') {
                apply_step(&mut seq, step);
            }
            print_seq(&seq);
        }
        _ => die("unknown literal operation"),
    }
}
