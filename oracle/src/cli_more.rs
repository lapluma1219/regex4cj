use regex_automata::dfa::Automaton;
use regex_automata::nfa::thompson::backtrack::BoundedBacktracker;
use regex_automata::nfa::thompson::pikevm::PikeVM;
use regex_automata::util::iter::Searcher;
use regex_automata::{Anchored, Input, MatchKind, PatternID, PatternSet};

use crate::cli_find::escape_text;

pub fn half(args: &[String]) {
    let (engine, patterns, text) = parse(args);
    match engine.as_str() {
        "dense" => {
            let re = build_dense(&patterns);
            print_ends(&text, re.find_iter(&text));
        }
        "sparse" => {
            let re = build_sparse(&patterns);
            print_ends(&text, re.find_iter(&text));
        }
        "hybrid" => {
            let re = build_hybrid(&patterns);
            let mut cache = re.create_cache();
            print_ends(&text, re.find_iter(&mut cache, &text));
        }
        other => {
            eprintln!("unrecognized command '{other}'");
            std::process::exit(1);
        }
    }
}

pub fn capture(args: &[String]) {
    let (engine, patterns, text) = parse(args);
    match engine.as_str() {
        "pikevm" | "meta" => print_pike_captures(&patterns, &text),
        "backtrack" => print_backtrack_captures(&patterns, &text),
        "lite" => {
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
            for caps in re.captures_iter(&text) {
                print_lite(&text, &caps);
            }
        }
        "regex" => {
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
            for caps in re.captures_iter(&text) {
                print_regex(&text, &caps);
            }
        }
        other => {
            eprintln!("unrecognized command '{other}'");
            std::process::exit(1);
        }
    }
}

pub fn which(args: &[String]) {
    let (engine, patterns, text) = parse(args);
    let mut flags = vec![false; patterns.len()];
    match engine.as_str() {
        "pikevm" | "meta" => {
            let re = match PikeVM::builder()
                .configure(PikeVM::config().match_kind(MatchKind::All))
                .build_many(&patterns)
            {
                Ok(re) => re,
                Err(err) => {
                    eprintln!("{err}");
                    std::process::exit(1);
                }
            };
            let mut cache = re.create_cache();
            let mut set = PatternSet::new(re.pattern_len());
            re.which_overlapping_matches(&mut cache, &Input::new(&text), &mut set);
            for id in set.iter() {
                flags[id.as_usize()] = true;
            }
        }
        "dense" => mark_dense(&patterns, &text, &mut flags),
        "sparse" => mark_sparse(&patterns, &text, &mut flags),
        "hybrid" => mark_hybrid(&patterns, &text, &mut flags),
        other => {
            eprintln!("unrecognized command '{other}'");
            std::process::exit(1);
        }
    }
    for (index, hit) in flags.iter().enumerate() {
        println!("{index}:{hit}");
    }
}

pub fn memory(engine: &str, pattern: &str) {
    match engine {
        "pikevm" => {
            let re = PikeVM::new(pattern).unwrap_or_else(|err| {
                eprintln!("{err}");
                std::process::exit(1);
            });
            println!("{}", re.get_nfa().memory_usage());
        }
        "backtrack" => {
            let re = BoundedBacktracker::new(pattern).unwrap_or_else(|err| {
                eprintln!("{err}");
                std::process::exit(1);
            });
            println!("{}", re.get_nfa().memory_usage());
        }
        "dense" => {
            let re = regex_automata::dfa::dense::DFA::new(pattern).unwrap_or_else(|err| {
                eprintln!("{err}");
                std::process::exit(1);
            });
            println!("{}", re.memory_usage());
        }
        "meta" => {
            let re = regex_automata::meta::Regex::new(pattern).unwrap_or_else(|err| {
                eprintln!("{err}");
                std::process::exit(1);
            });
            println!("{}", re.memory_usage());
        }
        other => {
            eprintln!("unrecognized command '{other}'");
            std::process::exit(1);
        }
    }
}

pub fn dfa_budget(limit_text: &str, pattern: &str) {
    let limit: usize = limit_text.parse().unwrap_or_else(|err| {
        eprintln!("{err}");
        std::process::exit(1);
    });
    let built = regex_automata::dfa::dense::Builder::new()
        .configure(regex_automata::dfa::dense::Config::new().dfa_size_limit(Some(limit)))
        .build(pattern);
    match built {
        Ok(dfa) => println!("ok\t{}", dfa.memory_usage()),
        Err(err) => println!("error\t{err}"),
    }
}

fn print_ends<'a>(text: &str, matches: impl Iterator<Item = regex_automata::Match>) {
    let _ = text;
    for found in matches {
        println!("{}:{}", found.pattern().as_usize(), found.end());
    }
}

fn print_pike_captures(patterns: &[String], text: &str) {
    let re = match PikeVM::new_many(patterns) {
        Ok(re) => re,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let mut it = Searcher::new(Input::new(text));
    loop {
        let advanced = it.try_advance(|input| {
            re.search(&mut cache, input, &mut caps);
            Ok(caps.get_match())
        });
        match advanced {
            Ok(Some(_)) => print_automata_caps(text, &caps),
            Ok(None) => break,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(1);
            }
        }
    }
}

fn print_backtrack_captures(patterns: &[String], text: &str) {
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
    loop {
        let advanced = it.try_advance(|input| {
            re.try_search(&mut cache, input, &mut caps)?;
            Ok(caps.get_match())
        });
        match advanced {
            Ok(Some(_)) => print_automata_caps(text, &caps),
            Ok(None) => break,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(1);
            }
        }
    }
}

fn print_automata_caps(text: &str, caps: &regex_automata::util::captures::Captures) {
    let pid = caps.pattern().unwrap();
    let mut line = format!("{}:{{ ", pid.as_usize());
    let names: Vec<Option<&str>> = caps.group_info().pattern_names(pid).collect();
    for (index, name) in names.iter().enumerate() {
        if index > 0 {
            line.push_str(", ");
        }
        if let Some(name) = name {
            line.push_str(&format!("{index}/{name}: "));
        } else {
            line.push_str(&format!("{index}: "));
        }
        match caps.get_group(index) {
            None => line.push_str("NONE"),
            Some(span) => {
                let piece = escape_text(&text[span.start..span.end]);
                line.push_str(&format!("{}..{}/{}", span.start, span.end, piece));
            }
        }
    }
    line.push_str(" }");
    println!("{line}");
}

fn print_regex(_text: &str, caps: &regex::Captures) {
    let mut line = String::from("0:{ ");
    for index in 0..caps.len() {
        if index > 0 {
            line.push_str(", ");
        }
        line.push_str(&format!("{index}: "));
        match caps.get(index) {
            None => line.push_str("NONE"),
            Some(span) => {
                let piece = escape_text(span.as_str());
                line.push_str(&format!("{}..{}/{}", span.start(), span.end(), piece));
            }
        }
    }
    line.push_str(" }");
    println!("{line}");
}

fn print_lite(_text: &str, caps: &regex_lite::Captures) {
    let mut line = String::from("0:{ ");
    for index in 0..caps.len() {
        if index > 0 {
            line.push_str(", ");
        }
        line.push_str(&format!("{index}: "));
        match caps.get(index) {
            None => line.push_str("NONE"),
            Some(span) => {
                let piece = escape_text(span.as_str());
                line.push_str(&format!("{}..{}/{}", span.start(), span.end(), piece));
            }
        }
    }
    line.push_str(" }");
    println!("{line}");
}

fn mark_dense(patterns: &[String], text: &str, flags: &mut [bool]) {
    let dfa = match regex_automata::dfa::dense::Builder::new()
        .configure(regex_automata::dfa::dense::Config::new().match_kind(MatchKind::All))
        .build_many(patterns)
    {
        Ok(dfa) => dfa,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    mark_automaton(&dfa, text, flags);
}

fn mark_sparse(patterns: &[String], text: &str, flags: &mut [bool]) {
    let dense = match regex_automata::dfa::dense::Builder::new()
        .configure(regex_automata::dfa::dense::Config::new().match_kind(MatchKind::All))
        .build_many(patterns)
    {
        Ok(dfa) => dfa,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let dfa = match dense.to_sparse() {
        Ok(dfa) => dfa,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    mark_automaton(&dfa, text, flags);
}

fn mark_hybrid(patterns: &[String], text: &str, flags: &mut [bool]) {
    let dfa = match regex_automata::hybrid::dfa::DFA::builder()
        .configure(regex_automata::hybrid::dfa::DFA::config().match_kind(MatchKind::All))
        .build_many(patterns)
    {
        Ok(dfa) => dfa,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(1);
        }
    };
    let mut cache = dfa.create_cache();
    let mut set = PatternSet::new(dfa.pattern_len());
    let input = Input::new(text).anchored(Anchored::No);
    if let Err(err) = dfa.try_which_overlapping_matches(&mut cache, &input, &mut set) {
        eprintln!("{err}");
        std::process::exit(1);
    }
    for id in set.iter() {
        flags[id.as_usize()] = true;
    }
}

fn mark_automaton<A: Automaton>(dfa: &A, text: &str, flags: &mut [bool]) {
    let mut set = PatternSet::new(dfa.pattern_len());
    if let Err(err) = dfa.try_which_overlapping_matches(&Input::new(text), &mut set) {
        eprintln!("{err}");
        std::process::exit(1);
    }
    for id in set.iter() {
        flags[id.as_usize()] = true;
    }
}

fn build_dense(patterns: &[String]) -> regex_automata::dfa::regex::Regex {
    regex_automata::dfa::regex::Regex::new_many(patterns).unwrap_or_else(|err| {
        eprintln!("{err}");
        std::process::exit(1);
    })
}

fn build_sparse(
    patterns: &[String],
) -> regex_automata::dfa::regex::Regex<regex_automata::dfa::sparse::DFA<Vec<u8>>> {
    regex_automata::dfa::regex::Regex::new_many_sparse(patterns).unwrap_or_else(|err| {
        eprintln!("{err}");
        std::process::exit(1);
    })
}

fn build_hybrid(patterns: &[String]) -> regex_automata::hybrid::regex::Regex {
    regex_automata::hybrid::regex::Regex::new_many(patterns).unwrap_or_else(|err| {
        eprintln!("{err}");
        std::process::exit(1);
    })
}

fn parse(args: &[String]) -> (String, Vec<String>, String) {
    if args.is_empty() {
        eprintln!("unrecognized command ''");
        std::process::exit(1);
    }
    let engine = args[0].clone();
    let mut patterns = Vec::new();
    let mut hay = None;
    let mut index = 1;
    while index < args.len() {
        match args[index].as_str() {
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
    let _ = PatternID::ZERO;
    (engine, patterns, text)
}
