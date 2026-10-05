use regex_automata::nfa::thompson::backtrack::BoundedBacktracker;
use regex_automata::nfa::thompson::pikevm::PikeVM;
use regex_automata::util::iter::Searcher;
use regex_automata::Input;

pub fn run(args: &[String]) {
    if args.is_empty() {
        eprintln!("unrecognized command ''");
        std::process::exit(1);
    }
    let engine = args[0].as_str();
    match engine {
        "pikevm" | "backtrack" | "onepass" | "meta" | "lite" | "dense" | "sparse" | "hybrid" | "regex" => {}
        _ => {
            eprintln!("unrecognized command '{engine}'");
            std::process::exit(1);
        }
    }
    let (patterns, text, table) = parse_find(&args[1..]);
    let started = std::time::Instant::now();
    let count = match engine {
        "pikevm" => run_pikevm(&patterns, &text),
        "backtrack" => run_backtrack(&patterns, &text),
        "onepass" => run_onepass(&patterns, &text),
        "meta" => run_meta(&patterns, &text),
        "lite" => run_lite(&patterns, &text),
        "dense" => run_dense(&patterns, &text),
        "sparse" => run_sparse(&patterns, &text),
        "hybrid" => run_hybrid(&patterns, &text),
        "regex" => run_regex(&patterns, &text),
        _ => unreachable!(),
    };
    if table {
        let elapsed = started.elapsed().as_nanos();
        println!("search time:\t{elapsed}ns");
        println!("total matches:\t{count}");
    }
}

fn parse_find(args: &[String]) -> (Vec<String>, String, bool) {
    let mut patterns = Vec::new();
    let mut hay = None;
    let mut table = false;
    let mut index = 0;
    while index < args.len() {
        match args[index].as_str() {
            "--table" => {
                table = true;
                index += 1;
            }
            "-p" if index + 1 < args.len() => {
                patterns.push(args[index + 1].clone());
                index += 2;
            }
            "-y" if index + 1 < args.len() => {
                hay = Some(args[index + 1].clone());
                index += 2;
            }
            other => {
                eprintln!("unrecognized argument '{other}'");
                std::process::exit(1);
            }
        }
    }
    let Some(text) = hay else {
        eprintln!("missing pattern or haystack");
        std::process::exit(1);
    };
    if patterns.is_empty() {
        eprintln!("missing pattern or haystack");
        std::process::exit(1);
    }
    (patterns, text, table)
}

fn run_pikevm(patterns: &[String], text: &str) -> usize {
    for pattern in patterns {
        if let Err(err) = regex::Regex::new(pattern) {
            eprintln!("{err}");
            std::process::exit(1);
        }
    }
    let re = match PikeVM::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let input = Input::new(text);
    let mut it = Searcher::new(input);
    let mut count = 0;
    loop {
        let advanced = it.try_advance(|input| {
            re.search(&mut cache, input, &mut caps);
            Ok(caps.get_match())
        });
        match advanced {
            Ok(Some(found)) => {
                print_match(text, found.pattern().as_usize(), found.start(), found.end());
                count += 1;
            }
            Ok(None) => return count,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(1);
            }
        }
    }
}

fn run_backtrack(patterns: &[String], text: &str) -> usize {
    let re = match BoundedBacktracker::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let mut it = Searcher::new(Input::new(text));
    let mut count = 0;
    loop {
        let advanced = it.try_advance(|input| {
            re.try_search(&mut cache, input, &mut caps)?;
            Ok(caps.get_match())
        });
        match advanced {
            Ok(Some(found)) => {
                print_match(text, found.pattern().as_usize(), found.start(), found.end());
                count += 1;
            }
            Ok(None) => return count,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(1);
            }
        }
    }
}

fn run_onepass(patterns: &[String], text: &str) -> usize {
    let dfa = match regex_automata::dfa::onepass::DFA::new_many(patterns) {
        Ok(dfa) => dfa,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut cache = dfa.create_cache();
    let mut caps = dfa.create_captures();
    let mut it = Searcher::new(Input::new(text));
    let mut count = 0;
    loop {
        let advanced = it.try_advance(|input| {
            dfa.try_search(&mut cache, input, &mut caps)?;
            Ok(caps.get_match())
        });
        match advanced {
            Ok(Some(found)) => {
                print_match(text, found.pattern().as_usize(), found.start(), found.end());
                count += 1;
            }
            Ok(None) => return count,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(1);
            }
        }
    }
}

fn run_meta(patterns: &[String], text: &str) -> usize {
    let re = match regex_automata::meta::Regex::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut count = 0;
    for found in re.find_iter(text) {
        print_match(text, found.pattern().as_usize(), found.start(), found.end());
        count += 1;
    }
    count
}

fn run_lite(patterns: &[String], text: &str) -> usize {
    if patterns.len() != 1 {
        eprintln!("regex-lite accepts one pattern");
        std::process::exit(1);
    }
    let re = match regex_lite::Regex::new(&patterns[0]) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut count = 0;
    for found in re.find_iter(text) {
        print_match(text, 0, found.start(), found.end());
        count += 1;
    }
    count
}

fn run_dense(patterns: &[String], text: &str) -> usize {
    let re = match regex_automata::dfa::regex::Regex::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut count = 0;
    for found in re.find_iter(text) {
        print_match(text, found.pattern().as_usize(), found.start(), found.end());
        count += 1;
    }
    count
}

fn run_sparse(patterns: &[String], text: &str) -> usize {
    let re = match regex_automata::dfa::regex::Regex::new_many_sparse(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut count = 0;
    for found in re.find_iter(text) {
        print_match(text, found.pattern().as_usize(), found.start(), found.end());
        count += 1;
    }
    count
}

fn run_hybrid(patterns: &[String], text: &str) -> usize {
    let re = match regex_automata::hybrid::regex::Regex::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut cache = re.create_cache();
    let mut count = 0;
    for found in re.find_iter(&mut cache, text) {
        print_match(text, found.pattern().as_usize(), found.start(), found.end());
        count += 1;
    }
    count
}

fn run_regex(patterns: &[String], text: &str) -> usize {
    if patterns.len() != 1 {
        eprintln!("the top-level regex engine accepts one pattern");
        std::process::exit(1);
    }
    let re = match regex::Regex::new(&patterns[0]) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut count = 0;
    for found in re.find_iter(text) {
        print_match(text, 0, found.start(), found.end());
        count += 1;
    }
    count
}

fn print_match(text: &str, pattern: usize, start: usize, end: usize) {
    println!(
        "{}:{}:{}:{}",
        pattern,
        start,
        end,
        escape_text(&text[start..end])
    );
}

pub fn escape_text(text: &str) -> String {
    let mut out = String::new();
    for ch in text.chars() {
        if ch.is_ascii() {
            let byte = ch as u8;
            match byte {
                0x21..=0x5B | 0x5D..=0x7E => out.push(ch),
                0 => out.push_str("\\0"),
                b'\n' => out.push_str("\\n"),
                b'\r' => out.push_str("\\r"),
                b'\t' => out.push_str("\\t"),
                b'\\' => out.push_str("\\\\"),
                _ => out.push_str(&format!("\\x{byte:02X}")),
            }
        } else {
            out.push(ch);
        }
    }
    out
}
