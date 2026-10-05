use regex_automata::nfa::thompson::{pikevm::PikeVM, NFA, WhichCaptures};
use regex_automata::{Anchored, Input, MatchKind, PatternSet};

fn hex_text(text: &str) -> String {
    text.as_bytes().iter().map(|b| format!("{b:02x}")).collect()
}

pub fn search(start: usize, end: usize, anchored: bool, text: &str, patterns: &[String]) {
    let re = match PikeVM::new_many(patterns) {
        Ok(re) => re,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let mode = if anchored { Anchored::Yes } else { Anchored::No };
    let input = Input::new(text).range(start..end).anchored(mode);
    re.search(&mut cache, &input, &mut caps);
    match caps.get_match() {
        None => println!("none"),
        Some(found) => {
            println!("pattern\t{}", found.pattern().as_usize());
            println!("span\t{}\t{}", found.start(), found.end());
            let groups = caps.group_info().group_len(found.pattern());
            for i in 0..groups {
                match caps.get_group(i) {
                    None => println!("group\t{i}\t-"),
                    Some(span) => {
                        let value = &text[span.start..span.end];
                        println!("group\t{i}\t{}\t{}\t{}", span.start, span.end, hex_text(value));
                    }
                }
            }
        }
    }
}

fn print_match(text: &str, caps: &regex_automata::util::captures::Captures) {
    match caps.get_match() {
        None => println!("none"),
        Some(found) => {
            println!("pattern\t{}", found.pattern().as_usize());
            println!("span\t{}\t{}", found.start(), found.end());
            let groups = caps.group_info().group_len(found.pattern());
            for i in 0..groups {
                match caps.get_group(i) {
                    None => println!("group\t{i}\t-"),
                    Some(span) => {
                        let value = &text[span.start..span.end];
                        println!("group\t{i}\t{}\t{}\t{}", span.start, span.end, hex_text(value));
                    }
                }
            }
        }
    }
}

pub fn configured(
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    let re = match PikeVM::new_many(patterns) {
        Ok(re) => re,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let mut input = Input::new(text).range(start..end).earliest(earliest);
    input = match mode {
        "no" => input.anchored(Anchored::No),
        "yes" => input.anchored(Anchored::Yes),
        other => {
            let id: usize = match other.parse() {
                Ok(id) => id,
                Err(err) => {
                    eprintln!("{err}");
                    std::process::exit(2);
                }
            };
            match regex_automata::PatternID::new(id) {
                Ok(pid) => input.anchored(Anchored::Pattern(pid)),
                Err(_) => {
                    println!("none");
                    return;
                }
            }
        }
    };
    re.search(&mut cache, &input, &mut caps);
    print_match(text, &caps);
}

pub fn earliest(text: &str, patterns: &[String]) {
    let re = match PikeVM::new_many(patterns) {
        Ok(re) => re,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let input = Input::new(text).earliest(true);
    re.search(&mut cache, &input, &mut caps);
    print_match(text, &caps);
}

pub fn overlapping_query(
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    let re = match PikeVM::builder()
        .configure(PikeVM::config().match_kind(MatchKind::All))
        .build_many(patterns)
    {
        Ok(re) => re,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut input = Input::new(text).range(start..end).earliest(earliest);
    input = match mode {
        "no" => input.anchored(Anchored::No),
        "yes" => input.anchored(Anchored::Yes),
        other => {
            let id: usize = match other.parse() {
                Ok(id) => id,
                Err(err) => {
                    eprintln!("{err}");
                    std::process::exit(2);
                }
            };
            match regex_automata::PatternID::new(id) {
                Ok(pid) => input.anchored(Anchored::Pattern(pid)),
                Err(_) => {
                    println!("count\t0");
                    return;
                }
            }
        }
    };
    let mut cache = re.create_cache();
    let mut patset = PatternSet::new(re.pattern_len());
    re.which_overlapping_matches(&mut cache, &input, &mut patset);
    let ids: Vec<usize> = patset.iter().map(|p| p.as_usize()).collect();
    println!("count\t{}", ids.len());
    for id in ids {
        println!("id\t{id}");
    }
}

fn which_captures(name: &str) -> WhichCaptures {
    match name {
        "all" => WhichCaptures::All,
        "implicit" => WhichCaptures::Implicit,
        "none" => WhichCaptures::None,
        _ => {
            eprintln!("capture mode must be all, implicit, or none");
            std::process::exit(2);
        }
    }
}

pub fn captures(mode: &str, text: &str, patterns: &[String]) {
    let re = match PikeVM::builder()
        .thompson(NFA::config().which_captures(which_captures(mode)))
        .build_many(patterns)
    {
        Ok(re) => re,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut cache = re.create_cache();
    println!("is-match\t{}", re.is_match(&mut cache, text));
    let mut caps = re.create_captures();
    re.captures(&mut cache, text, &mut caps);
    print_match(text, &caps);
}

fn parse_hex(text: &str) -> Vec<u8> {
    if text.len() % 2 != 0 {
        eprintln!("hex text must have an even length");
        std::process::exit(2);
    }
    let mut out = Vec::new();
    let mut i = 0;
    while i < text.len() {
        match u8::from_str_radix(&text[i..i + 2], 16) {
            Ok(byte) => out.push(byte),
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        }
        i += 2;
    }
    out
}

fn hex_bytes(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

pub fn bytes_search(start: usize, end: usize, mode: &str, hex: &str, patterns: &[String]) {
    let hay = parse_hex(hex);
    let re = match PikeVM::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let mut input = Input::new(&hay).range(start..end);
    input = match mode {
        "no" => input.anchored(Anchored::No),
        "yes" => input.anchored(Anchored::Yes),
        other => {
            let id: usize = match other.parse() {
                Ok(id) => id,
                Err(err) => {
                    eprintln!("{err}");
                    std::process::exit(2);
                }
            };
            match regex_automata::PatternID::new(id) {
                Ok(pid) => input.anchored(Anchored::Pattern(pid)),
                Err(_) => {
                    println!("none");
                    return;
                }
            }
        }
    };
    re.search(&mut cache, &input, &mut caps);
    match caps.get_match() {
        None => println!("none"),
        Some(found) => {
            println!("pattern\t{}", found.pattern().as_usize());
            println!("span\t{}\t{}", found.start(), found.end());
            let groups = caps.group_info().group_len(found.pattern());
            for i in 0..groups {
                match caps.get_group(i) {
                    None => println!("group\t{i}\t-"),
                    Some(span) => println!(
                        "group\t{i}\t{}\t{}\t{}",
                        span.start,
                        span.end,
                        hex_bytes(&hay[span.start..span.end])
                    ),
                }
            }
        }
    }
}

pub fn nfa_build(limit: usize, pattern: &str) {
    let hir = match regex_syntax::Parser::new().parse(pattern) {
        Ok(hir) => hir,
        Err(err) => {
            println!("Syntax\tparse\t{err}");
            return;
        }
    };
    match NFA::compiler()
        .configure(NFA::config().nfa_size_limit(Some(limit)))
        .build_from_hir(&hir)
    {
        Ok(_) => println!("ok"),
        Err(err) => println!("CompiledTooBig\t\t{err}"),
    }
}

pub fn overlapping(text: &str, patterns: &[String]) {
    let re = match PikeVM::builder()
        .configure(PikeVM::config().match_kind(MatchKind::All))
        .build_many(patterns)
    {
        Ok(re) => re,
        Err(e) => {
            eprintln!("{e}");
            std::process::exit(2);
        }
    };
    let mut cache = re.create_cache();
    let mut patset = PatternSet::new(re.pattern_len());
    let input = Input::new(text);
    re.which_overlapping_matches(&mut cache, &input, &mut patset);
    let ids: Vec<usize> = patset.iter().map(|p| p.as_usize()).collect();
    println!("count\t{}", ids.len());
    for id in ids {
        println!("id\t{id}");
    }
}
