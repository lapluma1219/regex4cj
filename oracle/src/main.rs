mod suite;
mod hir_audit;
mod api_audit;
mod lazy_audit;
mod pike;
mod products;
mod ast_audit;
mod literal_audit;
mod reverse_audit;
mod backtrack_audit;
mod dfa_audit;
mod cli_find;
mod cli_more;

use regex::Regex;
fn group_info(pattern: &str, bytes: bool) {
    if bytes {
        match regex::bytes::Regex::new(pattern) {
            Err(err) => println!("error\t{err}"),
            Ok(re) => print_group_info(re.captures_len(), re.static_captures_len(), re.capture_names()),
        }
    } else {
        match regex::Regex::new(pattern) {
            Err(err) => println!("error\t{err}"),
            Ok(re) => print_group_info(re.captures_len(), re.static_captures_len(), re.capture_names()),
        }
    }
}

fn print_group_info<'a>(len: usize, static_len: Option<usize>, names: impl Iterator<Item = Option<&'a str>>) {
    println!("len\t{len}");
    match static_len {
        Some(count) => println!("static\tsome\t{count}"),
        None => println!("static\tnone"),
    }
    for (index, name) in names.enumerate() {
        match name {
            Some(text) => println!("name\t{index}\t{}", hex_text(text)),
            None => println!("name\t{index}\t-"),
        }
    }
}

fn hex_text(text: &str) -> String {
    text.as_bytes().iter().map(|b| format!("{b:02x}")).collect()
}
fn hex_bytes(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}
fn parse_hex(text: &str) -> Result<Vec<u8>, String> {
    if text.len() % 2 != 0 {
        return Err("hex text must have an even length".into());
    }
    let mut out = Vec::with_capacity(text.len() / 2);
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        let hi = hex_value(bytes[i])?;
        let lo = hex_value(bytes[i + 1])?;
        out.push((hi << 4) | lo);
        i += 2;
    }
    Ok(out)
}
fn hex_value(byte: u8) -> Result<u8, String> {
    match byte {
        b'0'..=b'9' => Ok(byte - b'0'),
        b'a'..=b'f' => Ok(byte - b'a' + 10),
        b'A'..=b'F' => Ok(byte - b'A' + 10),
        _ => Err("invalid hex digit".into()),
    }
}
fn print_capture_value(prefix: &str, value: Option<regex::Match<'_>>) {
    match value {
        Some(m) => println!("{}\t{}\t{}\t{}", prefix, m.start(), m.end(), hex_text(m.as_str())),
        None => println!("{}\t-", prefix),
    }
}
fn print_capture_result(re: &Regex, caps: &regex::Captures<'_>) {
    println!("match");
    for i in 0..caps.len() { print_capture_value(&format!("group\t{i}"), caps.get(i)); }
    for name in re.capture_names().flatten() {
        print_capture_value(&format!("named\t{}", hex_text(name)), caps.name(name));
    }
}
fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    match a.first().map(String::as_str) {
        Some("hir-constructors") if a.len()==1 => hir_audit::constructors(),
        Some("hir") if a.len()==3 => hir_audit::parse(&a[1], a[2]=="true"),
        Some("hir-print") if a.len()==3 => hir_audit::print_hir(&a[1], a[2]=="true"),
        Some("hir-props") if a.len()==3 => hir_audit::properties(&a[1], a[2]=="true"),
        Some("ast") if a.len()==2 => ast_audit::parse(&a[1]),
        Some("ast-translate") if a.len()==3 => ast_audit::ast_translate(&a[1], a[2]=="true"),
        Some("ast-octal") if a.len()==2 => ast_audit::octal(&a[1]),
        Some("ast-print") if a.len()==2 => ast_audit::ast_print(&a[1]),
        Some("syntax-error") if a.len()==2 => ast_audit::syntax_error(&a[1]),
        Some("literals") if a.len()==3 => literal_audit::literals(&a[1], &a[2]),
        Some("literals-config") if a.len()==7 => {
            literal_audit::literals_config(&a[1], &a[2], &a[3], &a[4], &a[5], &a[6]);
        }
        Some("literal-op") if a.len()>=3 => literal_audit::literal_op(&a[1..]),
        Some("utf8") if a.len()==3 => {
            let start: u32 = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: u32 = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            literal_audit::utf8(start, end);
        },
        Some("group-info") if a.len()==2 => group_info(&a[1], false),
        Some("bytes-group-info") if a.len()==2 => group_info(&a[1], true),
        Some("cli-find") if a.len()>=2 => cli_find::run(&a[1..]),
        Some("cli-half") if a.len()>=2 => cli_more::half(&a[1..]),
        Some("cli-capture") if a.len()>=2 => cli_more::capture(&a[1..]),
        Some("cli-which") if a.len()>=2 => cli_more::which(&a[1..]),
        Some("memory") if a.len()==3 => cli_more::memory(&a[1], &a[2]),
        Some("dfa-budget") if a.len()==3 => cli_more::dfa_budget(&a[1], &a[2]),
        Some("onepass") if a.len()==3 => products::onepass(&a[1], &a[2]),
        Some("meta") if a.len()==3 => products::meta(&a[1], &a[2]),
        Some("lite") if a.len()==3 => products::lite(&a[1], &a[2]),
        Some("rure") if a.len()==3 => products::rure(&a[1], &a[2]),
        Some("dfa-image") if a.len()==3 => products::dfa_image(&a[1], &a[2]),
        Some("nfa-rev") if a.len()==3 => reverse_audit::search(&a[1], &a[2]),
        Some("nfa-rev-empty") if a.len()==1 => reverse_audit::empty(),
        Some("nfa-rev-limit") if a.len()==3 => {
            let limit: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            reverse_audit::limited(limit, &a[2]);
        },
        Some("nfa-build") if a.len()==3 => {
            let limit: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            pike::nfa_build(limit, &a[2]);
        },
        Some("nfa-rev-many") if a.len()>=6 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            reverse_audit::many(start, end, &a[3], &a[4], &a[5..]);
        },
        Some("nfa-rev-query") if a.len()==6 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            reverse_audit::query(start, end, &a[3], &a[4], &a[5]);
        },
        Some("backtrack-info") if a.len()==3 => backtrack_audit::info(&a[1], &a[2]),
        Some("backtrack") if a.len()==4 => backtrack_audit::search(&a[1], &a[2], &a[3]),
        Some("backtrack-iter") if a.len()>=4 => backtrack_audit::iter(&a[1], &a[2], &a[3..]),
        Some("backtrack-iter-span") if a.len()>=6 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            backtrack_audit::iter_range(&a[1], start, end, &a[4], &a[5..]);
        },
        Some("backtrack-bytes") if a.len()>=7 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            backtrack_audit::bytes_search(&a[1], start, end, &a[4], &a[5], &a[6..]);
        },
        Some("backtrack-query") if a.len()==8 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            backtrack_audit::query(&a[1], start, end, &a[4], a[5]=="true", &a[6], &a[7]);
        },
        Some("backtrack-many") if a.len()>=8 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            backtrack_audit::many(&a[1], start, end, &a[4], a[5]=="true", &a[6], &a[7..]);
        },
        Some("hybrid") if a.len()==8 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::hybrid(&a[1], start, end, &a[4], a[5]=="true", &a[6], &a[7]);
        },
        Some("hybrid-reset") if a.len()==3 => dfa_audit::hybrid_reset(&a[1], &a[2]),
        Some("hybrid-small") if a.len()==3 => dfa_audit::hybrid_small(&a[1], &a[2]),
        Some("dfa-overlap") if a.len()>=7 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::overlap(&a[1], start, end, &a[4], &a[5], &a[6..]);
        },
        Some("dfa-pattern") if a.len()>=8 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::pattern_search(&a[1], start, end, &a[4], a[5]=="true", &a[6], &a[7..]);
        },
        Some("dfa-pattern-overlap") if a.len()>=7 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::pattern_overlap(&a[1], start, end, &a[4], &a[5], &a[6..]);
        },
        Some("dfa-bytes-pattern") if a.len()>=5 => dfa_audit::bytes_pattern(&a[1], &a[2], &a[3], &a[4..]),
        Some("dfa-many") if a.len()>=8 => {
            let start: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::many(&a[1], start, end, &a[4], a[5]=="true", &a[6], &a[7..]);
        },
        Some("dfa") if a.len()==4 => dfa_audit::search(&a[1], &a[2], &a[3]),
        Some("dfa-bytes") if a.len()==4 => dfa_audit::bytes_search(&a[1], &a[2], &a[3]),
        Some("dfa-bytes-quit") if a.len()==5 => dfa_audit::bytes_quit(&a[1], &a[2], &a[3], &a[4]),
        Some("dfa-bytes-many") if a.len()>=4 => dfa_audit::bytes_many(&a[1], &a[2], &a[3..]),
        Some("dfa-bytes-overlap") if a.len()>=4 => dfa_audit::bytes_overlap(&a[1], &a[2], &a[3..]),
        Some("dfa-query") if a.len()==9 => {
            let start: usize = a[3].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[4].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::query(&a[1], &a[2], start, end, &a[5], a[6]=="true", &a[7], &a[8]);
        },
        Some("pike-overlap") if a.len()>=3 => pike::overlapping(&a[1], &a[2..]),
        Some("pike-captures") if a.len()>=4 => pike::captures(&a[1], &a[2], &a[3..]),
        Some("backtrack-captures") if a.len()>=5 => backtrack_audit::captures(&a[1], &a[2], &a[3], &a[4..]),
        Some("pike-overlap-query") if a.len()>=7 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            pike::overlapping_query(start, end, &a[3], a[4]=="true", &a[5], &a[6..]);
        },
        Some("hybrid-many") if a.len()>=7 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::hybrid_many(start, end, &a[3], a[4]=="true", &a[5], &a[6..]);
        },
        Some("hybrid-pattern") if a.len()>=7 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            dfa_audit::hybrid_pattern(start, end, &a[3], a[4]=="true", &a[5], &a[6..]);
        },
        Some("pike-earliest") if a.len()>=3 => pike::earliest(&a[1], &a[2..]),
        Some("pike-bytes") if a.len()>=6 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            pike::bytes_search(start, end, &a[3], &a[4], &a[5..]);
        },
        Some("pike-config") if a.len()>=6 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            pike::configured(start, end, &a[3], a[4]=="true", &a[5], &a[6..]);
        },
        Some("pike") if a.len()>=5 => {
            let start: usize = a[1].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            let end: usize = a[2].parse().unwrap_or_else(|e| { eprintln!("{e}"); std::process::exit(2); });
            pike::search(start, end, a[3]=="true", &a[4], &a[5..]);
        },
        Some("api-audit") if a.len() == 1 => api_audit::run(),
        Some("set-matches-at" | "set-is-match-at") if a.len() >= 3 => {
            let start: usize = match a[2].parse() {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::RegexSet::new(&a[3..]) {
                Ok(set) => {
                    if a[0] == "set-is-match-at" { println!("{}", set.is_match_at(&a[1], start)); }
                    else {
                        let result = set.matches_at(&a[1], start);
                        println!("patterns\t{}", result.len());
                        println!("any\t{}", result.matched_any());
                        println!("all\t{}", result.matched_all());
                        for id in result.iter() { println!("hit\t{id}"); }
                    }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("set-limit") if a.len() >= 3 => {
            let limit: usize = match a[1].parse() {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::RegexSetBuilder::new(&a[3..]).size_limit(limit).build() {
                Ok(set) => {
                    let result = set.matches(&a[2]);
                    println!("patterns\t{}", result.len());
                    println!("any\t{}", result.matched_any());
                    println!("all\t{}", result.matched_all());
                    for id in result.iter() { println!("hit\t{id}"); }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("set-matches" | "set-is-match") if a.len() >= 2 => {
            match regex::RegexSet::new(&a[2..]) {
                Ok(set) => {
                    if a[0] == "set-is-match" { println!("{}", set.is_match(&a[1])); }
                    else {
                        let result = set.matches(&a[1]);
                        println!("patterns\t{}", result.len());
                        println!("any\t{}", result.matched_any());
                        println!("all\t{}", result.matched_all());
                        for id in result.iter() { println!("hit\t{id}"); }
                    }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("escape") if a.len() == 2 => println!("{}", regex::escape(&a[1])),
        Some("find") if a.len() == 3 => {
            match Regex::new(&a[1]) {
                Ok(re) => for m in re.find_iter(&a[2]) {
                    println!("{}\t{}\t{}", m.start(), m.end(), m.as_str());
                },
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("bytes-find") if a.len() == 3 => {
            let hay = match parse_hex(&a[2]) {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::bytes::Regex::new(&a[1]) {
                Ok(re) => {
                    for m in re.find_iter(&hay) {
                        println!("{}\t{}\t{}", m.start(), m.end(), hex_bytes(m.as_bytes()));
                    }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("bytes-captures") if a.len() == 3 => {
            let hay = match parse_hex(&a[2]) {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::bytes::Regex::new(&a[1]) {
                Ok(re) => {
                    println!("groups\t{}", re.captures_len());
                    for (i, name) in re.capture_names().enumerate() {
                        if let Some(name) = name {
                            println!("name\t{i}\t{}", hex_text(name));
                        }
                    }
                    if let Some(caps) = re.captures(&hay) {
                        println!("match");
                        for i in 0..caps.len() {
                            match caps.get(i) {
                                Some(m) => println!("group\t{i}\t{}\t{}\t{}", m.start(), m.end(), hex_bytes(m.as_bytes())),
                                None => println!("group\t{i}\t-"),
                            }
                        }
                    }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("bytes-replace" | "bytes-replace-all") if a.len() == 4 => {
            let hay = match parse_hex(&a[2]) {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::bytes::Regex::new(&a[1]) {
                Ok(re) => {
                    let output = if a[0] == "bytes-replace" {
                        re.replace(&hay, a[3].as_bytes())
                    } else {
                        re.replace_all(&hay, a[3].as_bytes())
                    };
                    println!("{}", hex_bytes(&output));
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("bytes-split") if a.len() == 3 => {
            let hay = match parse_hex(&a[2]) {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::bytes::Regex::new(&a[1]) {
                Ok(re) => {
                    for part in re.split(&hay) {
                        println!("{}", hex_bytes(part));
                    }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("bytes-set-matches") if a.len() >= 2 => {
            let hay = match parse_hex(&a[1]) {
                Ok(v) => v,
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            };
            match regex::bytes::RegexSet::new(&a[2..]) {
                Ok(set) => {
                    let result = set.matches(&hay);
                    println!("patterns\t{}", result.len());
                    println!("any\t{}", result.matched_any());
                    println!("all\t{}", result.matched_all());
                    for id in result.iter() { println!("hit\t{id}"); }
                }
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("find-at" | "is-match-at" | "shortest" | "shortest-at" | "static-len" | "captures-at" | "octal-find" | "term-find" | "nest-find" | "limit-find" | "dfa-find") => {
            let result = (|| -> Result<(), Box<dyn std::error::Error>> {
                let mode = a[0].as_str();
                if mode == "static-len" {
                    if a.len() != 2 { return Err("invalid argument count".into()); }
                    let re = Regex::new(&a[1])?;
                    match re.static_captures_len() {
                        Some(n) => println!("some\t{n}"),
                        None => println!("none"),
                    }
                    return Ok(());
                }
                if mode == "octal-find" {
                    if a.len() != 3 { return Err("invalid argument count".into()); }
                    let re = regex::RegexBuilder::new(&a[1]).octal(true).build()?;
                    for m in re.find_iter(&a[2]) { println!("{}\t{}\t{}", m.start(), m.end(), m.as_str()); }
                    return Ok(());
                }
                if mode == "nest-find" {
                    if a.len() != 4 { return Err("invalid argument count".into()); }
                    let limit: u32 = a[1].parse()?;
                    let re = regex::RegexBuilder::new(&a[2]).nest_limit(limit).build()?;
                    for m in re.find_iter(&a[3]) { println!("{}\t{}\t{}", m.start(), m.end(), m.as_str()); }
                    return Ok(());
                }
                if mode == "limit-find" {
                    if a.len() != 4 { return Err("invalid argument count".into()); }
                    let limit: usize = a[1].parse()?;
                    let re = regex::RegexBuilder::new(&a[2]).size_limit(limit).build()?;
                    for m in re.find_iter(&a[3]) { println!("{}\t{}\t{}", m.start(), m.end(), m.as_str()); }
                    return Ok(());
                }
                if mode == "dfa-find" {
                    if a.len() != 4 { return Err("invalid argument count".into()); }
                    let limit: usize = a[1].parse()?;
                    let re = regex::RegexBuilder::new(&a[2]).dfa_size_limit(limit).build()?;
                    for m in re.find_iter(&a[3]) { println!("{}\t{}\t{}", m.start(), m.end(), m.as_str()); }
                    return Ok(());
                }
                if mode == "term-find" {
                    if a.len() != 4 { return Err("invalid argument count".into()); }
                    let byte: u8 = a[1].parse()?;
                    let re = regex::RegexBuilder::new(&a[2]).line_terminator(byte).build()?;
                    for m in re.find_iter(&a[3]) { println!("{}\t{}\t{}", m.start(), m.end(), m.as_str()); }
                    return Ok(());
                }
                if mode == "shortest" {
                    if a.len() != 3 { return Err("invalid argument count".into()); }
                    let re = Regex::new(&a[1])?;
                    if let Some(end) = re.shortest_match(&a[2]) { println!("{end}"); }
                    return Ok(());
                }
                if a.len() != 4 { return Err("invalid argument count".into()); }
                let re = Regex::new(&a[1])?;
                let start: usize = a[3].parse()?;
                match mode {
                    "is-match-at" => println!("{}", re.is_match_at(&a[2], start)),
                    "shortest-at" => if let Some(end) = re.shortest_match_at(&a[2], start) { println!("{end}"); },
                    "find-at" => if let Some(m) = re.find_at(&a[2], start) {
                        println!("{}\t{}\t{}", m.start(), m.end(), m.as_str());
                    },
                    "captures-at" => {
                        println!("groups\t{}", re.captures_len());
                        if let Some(caps) = re.captures_at(&a[2], start) { print_capture_result(&re, &caps); }
                    }
                    _ => return Err("unknown mode".into()),
                }
                Ok(())
            })();
            if let Err(e) = result { eprintln!("{e}"); std::process::exit(2); }
        },
        Some("first" | "is-match") if a.len() == 3 => {
            match Regex::new(&a[1]) {
                Ok(re) => {
                    if a[0] == "is-match" { println!("{}", re.is_match(&a[2])); }
                    else if let Some(m) = re.find(&a[2]) {
                        println!("{}\t{}\t{}", m.start(), m.end(), m.as_str());
                    }
                },
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("captures" | "capture-first") if a.len() == 3 => {
            match Regex::new(&a[1]) {
                Ok(re) => {
                    println!("groups\t{}", re.captures_len());
                    for (i, name) in re.capture_names().enumerate() {
                        if let Some(name) = name { println!("name\t{}\t{}", i, hex_text(name)); }
                    }
                    if a[0] == "captures" {
                        for caps in re.captures_iter(&a[2]) { print_capture_result(&re, &caps); }
                    } else if let Some(caps) = re.captures(&a[2]) {
                        print_capture_result(&re, &caps);
                    }
                },
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("capture-name") if a.len() == 4 => {
            match Regex::new(&a[1]) {
                Ok(re) => print_capture_value("value", re.captures(&a[2]).and_then(|caps| caps.name(&a[3]))),
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("split" | "split-n" | "replace" | "replace-all" | "replace-n" | "replace-literal" | "replace-with" | "expand") => {
            let result = (|| -> Result<(), Box<dyn std::error::Error>> {
                let mode = a[0].as_str();
                let expected = match mode { "split" => 3, "replace-n" | "replace-literal" => 5, _ => 4 };
                if a.len() != expected { return Err("invalid argument count".into()); }
                let re = Regex::new(&a[1])?;
                match mode {
                    "split" => for part in re.split(&a[2]) { println!("{}", hex_text(part)); },
                    "split-n" => for part in re.splitn(&a[2], a[3].parse()?) { println!("{}", hex_text(part)); },
                    "expand" => if let Some(caps) = re.captures(&a[2]) {
                        let mut output = String::new(); caps.expand(&a[3], &mut output);
                        println!("{}", hex_text(&output));
                    },
                    "replace-with" => {
                        let mut calls = 0;
                        let output = re.replacen(&a[2], a[3].parse()?, |caps: &regex::Captures<'_>| {
                            calls += 1;
                            let mut value = format!("{calls}:");
                            caps.expand("<$0>[$1]", &mut value); value
                        });
                        println!("{}\n{}", hex_text(&output), calls);
                    },
                    "replace" => println!("{}", hex_text(&re.replace(&a[2], a[3].as_str()))),
                    "replace-all" => println!("{}", hex_text(&re.replace_all(&a[2], a[3].as_str()))),
                    "replace-n" => println!("{}", hex_text(&re.replacen(&a[2], a[4].parse()?, a[3].as_str()))),
                    "replace-literal" => println!("{}", hex_text(&re.replacen(&a[2], a[4].parse()?, regex::NoExpand(&a[3])))),
                    _ => unreachable!(),
                }
                Ok(())
            })();
            if let Err(e) = result { eprintln!("{e}"); std::process::exit(2); }
        },
        Some("suite-emit") if a.len() == 2 => {
            if let Err(e) = suite::emit(&a[1]) {
                eprintln!("{e}");
                std::process::exit(2);
            }
        },
        Some("demo") => {
            let text = "order=AB-123; order=CD-456";
            let re = Regex::new(r"(?P<prefix>[A-Z]{2})-(?P<number>[0-9]{3})").unwrap();
            for c in re.captures_iter(text) {
                let m = c.get(0).unwrap();
                println!("{} [{}..{}) prefix={} number={}", m.as_str(), m.start(), m.end(), &c["prefix"], &c["number"]);
            }
            println!("{}", re.replace_all(text, "${prefix}-***"));
        },
        _ => { eprintln!("usage: regex-oracle set-matches TEXT [PATTERN ...] | set-is-match TEXT [PATTERN ...] | escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | captures PATTERN TEXT | capture-first PATTERN TEXT | capture-name PATTERN TEXT NAME | split PATTERN TEXT | split-n PATTERN TEXT LIMIT | replace/replace-all/expand PATTERN TEXT TEMPLATE | replace-n/replace-literal PATTERN TEXT TEMPLATE LIMIT | replace-with PATTERN TEXT LIMIT | demo"); std::process::exit(2); }
    }
}

#[cfg(test)]
mod native_tests {
    use regex::Regex;

    #[test]
    fn nul_matching_and_escape() {
        let text = "中\0🙂";
        let m = Regex::new(&regex::escape("\0")).unwrap().find(text).unwrap();
        assert_eq!((m.start(), m.end(), m.as_str()), (3, 4, "\0"));
        assert_eq!(regex::escape("\0"), "\0");
        assert_eq!(Regex::new(".").unwrap().find_iter(text).count(), 3);
    }

    #[test]
    fn nul_replacement_split_and_expand() {
        let re = Regex::new("\0").unwrap();
        assert_eq!(re.replace_all("a\0b", "!"), "a!b");
        assert_eq!(Regex::new("a").unwrap().replace_all("a", regex::NoExpand("\0")), "\0");
        assert_eq!(re.split("\0a\0").collect::<Vec<_>>(), vec!["", "a", ""]);
        let capture_re = Regex::new("(\0)").unwrap();
        let caps = capture_re.captures("\0").unwrap();
        let mut out = String::new();
        caps.expand("$1", &mut out);
        assert_eq!(out, "\0");
    }
    #[test]
    fn set_nul_empty_and_overlap() {
        let empty = regex::RegexSet::new(Vec::<String>::new()).unwrap();
        assert!(!empty.is_match(""));
        assert!(empty.matches("").matched_all());
        let set = regex::RegexSet::new(["\0", r"\p{Han}", r"\b中\b", r"\p{Emoji}", r"\A\z"]).unwrap();
        assert_eq!(set.matches("\0中🙂").iter().collect::<Vec<_>>(), vec![0, 1, 2, 3]);
        let set = regex::RegexSet::new(["foo", "bar", "foobar", "foo", "z"]).unwrap();
        assert_eq!(set.matches("bar foobar foo").iter().collect::<Vec<_>>(), vec![0, 1, 2, 3]);
    }

}
