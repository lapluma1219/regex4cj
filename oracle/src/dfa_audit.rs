use regex_automata::dfa::dense;
use regex_automata::{dfa::regex::Regex, Anchored, Input, MatchError};

fn report(result: Result<Option<regex_automata::Match>, MatchError>) {
    match result {
        Err(err) => println!("error\t{err}"),
        Ok(None) => println!("none"),
        Ok(Some(found)) => println!("span\t{}\t{}", found.start(), found.end()),
    }
}

fn parse_hex_bytes(text: &str) -> Result<Vec<u8>, String> {
    if text.len() % 2 != 0 {
        return Err("hex text must have an even length".into());
    }
    let mut out = Vec::with_capacity(text.len() / 2);
    let bytes = text.as_bytes();
    let mut index = 0;
    while index < bytes.len() {
        let pair = std::str::from_utf8(&bytes[index..index + 2]).map_err(|err| err.to_string())?;
        let byte = u8::from_str_radix(pair, 16).map_err(|err| err.to_string())?;
        out.push(byte);
        index += 2;
    }
    Ok(out)
}

pub fn bytes_search(kind: &str, hex_text: &str, pattern: &str) {
    let bytes = match parse_hex_bytes(hex_text) {
        Ok(bytes) => bytes,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let input = Input::new(&bytes);
    match kind {
        "dense" => match Regex::new(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match Regex::new_sparse(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "hybrid" => match regex_automata::hybrid::regex::Regex::new(pattern) {
            Ok(re) => {
                let mut cache = re.create_cache();
                report(re.try_search(&mut cache, &input));
            }
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense, sparse, or hybrid");
            std::process::exit(2);
        }
    }
}

pub fn bytes_quit(kind: &str, quit_hex: &str, hex_text: &str, pattern: &str) {
    let bytes = match parse_hex_bytes(hex_text) {
        Ok(bytes) => bytes,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let input = Input::new(&bytes);
    let config = quit_config(quit_hex);
    let mut builder = Regex::builder();
    builder.dense(config);
    match kind {
        "dense" => match builder.build(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match builder.build_sparse(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

pub fn search(kind: &str, pattern: &str, text: &str) {
    let input = Input::new(text);
    match kind {
        "dense" => match Regex::new(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match Regex::new_sparse(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

fn quit_config(hex_bytes: &str) -> dense::Config {
    let mut config = dense::Config::new();
    if hex_bytes == "-" {
        return config;
    }
    if hex_bytes.len() % 2 != 0 {
        eprintln!("quit bytes must be hex pairs");
        std::process::exit(2);
    }
    let bytes = hex_bytes.as_bytes();
    let mut index = 0;
    while index < bytes.len() {
        let text = &hex_bytes[index..index + 2];
        let byte = match u8::from_str_radix(text, 16) {
            Ok(byte) => byte,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        };
        config = config.quit(byte, true);
        index += 2;
    }
    config
}

fn configure_input<'h>(text: &'h str, start: usize, end: usize, mode: &str, earliest: bool) -> Input<'h> {
    let mut input = Input::new(text).range(start..end).earliest(earliest);
    input = match mode {
        "no" => input.anchored(Anchored::No),
        "yes" => input.anchored(Anchored::Yes),
        other => {
            let id: usize = other.parse().unwrap_or_else(|err| {
                eprintln!("{err}");
                std::process::exit(2);
            });
            match regex_automata::PatternID::new(id) {
                Ok(pid) => input.anchored(Anchored::Pattern(pid)),
                Err(_) => input,
            }
        }
    };
    input
}

fn report_pattern(result: Result<Option<regex_automata::Match>, MatchError>) {
    match result {
        Err(err) => println!("error\t{err}"),
        Ok(None) => println!("none"),
        Ok(Some(found)) => println!(
            "pattern\t{}\t{}\t{}",
            found.pattern().as_usize(),
            found.start(),
            found.end()
        ),
    }
}

fn report_overlap<A: regex_automata::dfa::Automaton>(dfa: &A, input: &regex_automata::Input<'_>) {
    use regex_automata::dfa::OverlappingState;
    let mut state = OverlappingState::start();
    let mut hits = Vec::new();
    loop {
        if let Err(err) = dfa.try_search_overlapping_fwd(input, &mut state) {
            println!("error\t{err}");
            return;
        }
        match state.get_match() {
            None => break,
            Some(hit) => hits.push((hit.pattern().as_usize(), hit.offset())),
        }
    }
    println!("count\t{}", hits.len());
    for (pattern, offset) in hits {
        println!("half\t{pattern}\t{offset}");
    }
}

pub fn overlap(kind: &str, start: usize, end: usize, mode: &str, text: &str, patterns: &[String]) {
    use regex_automata::dfa::dense;
    use regex_automata::MatchKind;
    let input = if mode != "no" && mode != "yes" {
        match mode.parse::<usize>() {
            Ok(id) => match regex_automata::PatternID::new(id) {
                Ok(_) => configure_input(text, start, end, mode, false),
                Err(_) => {
                    println!("count\t0");
                    return;
                }
            },
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        }
    } else {
        configure_input(text, start, end, mode, false)
    };
    let config = dense::Config::new().match_kind(MatchKind::All);
    match kind {
        "dense" => match dense::Builder::new().configure(config).build_many(patterns) {
            Ok(dfa) => report_overlap(&dfa, &input),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match dense::Builder::new()
            .configure(config)
            .build_many(patterns)
            .and_then(|dfa| dfa.to_sparse())
        {
            Ok(dfa) => report_overlap(&dfa, &input),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

fn hybrid_config(hex_bytes: &str) -> regex_automata::hybrid::dfa::Config {
    let mut config = regex_automata::hybrid::dfa::Config::new();
    if hex_bytes == "-" {
        return config;
    }
    if hex_bytes.len() % 2 != 0 {
        eprintln!("quit bytes must be hex pairs");
        std::process::exit(2);
    }
    let mut index = 0;
    while index < hex_bytes.len() {
        let text = &hex_bytes[index..index + 2];
        let byte = match u8::from_str_radix(text, 16) {
            Ok(byte) => byte,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        };
        config = config.quit(byte, true);
        index += 2;
    }
    config
}

pub fn hybrid_many(
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    use regex_automata::hybrid::regex::Regex;
    let input = configure_input(text, start, end, mode, earliest);
    let mut builder = Regex::builder();
    builder.dfa(hybrid_config("-"));
    match builder.build_many(patterns) {
        Ok(re) => {
            let mut cache = re.create_cache();
            report_pattern(re.try_search(&mut cache, &input));
        }
        Err(err) => println!("error\t{err}"),
    }
}

pub fn hybrid_pattern(
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    use regex_automata::hybrid::regex::Regex;
    let input = configure_input(text, start, end, mode, earliest);
    let mut builder = Regex::builder();
    builder.dfa(
        regex_automata::hybrid::dfa::Config::new().starts_for_each_pattern(true),
    );
    match builder.build_many(patterns) {
        Ok(re) => {
            let mut cache = re.create_cache();
            report_pattern(re.try_search(&mut cache, &input));
        }
        Err(err) => println!("error\t{err}"),
    }
}

pub fn hybrid(
    quit_hex: &str,
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    pattern: &str,
) {
    use regex_automata::hybrid::regex::Regex;
    let input = configure_input(text, start, end, mode, earliest);
    let mut builder = Regex::builder();
    builder.dfa(hybrid_config(quit_hex));
    match builder.build(pattern) {
        Ok(re) => {
            let mut cache = re.create_cache();
            report(re.try_search(&mut cache, &input));
        }
        Err(err) => println!("error\t{err}"),
    }
}

pub fn hybrid_reset(text: &str, pattern: &str) {
    use regex_automata::hybrid::regex::Regex;
    let re = match Regex::new(pattern) {
        Ok(re) => re,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    let mut cache = re.create_cache();
    let input = regex_automata::Input::new(text);
    report(re.try_search(&mut cache, &input));
    re.reset_cache(&mut cache);
    report(re.try_search(&mut cache, &input));
}

pub fn hybrid_small(text: &str, pattern: &str) {
    use regex_automata::hybrid::{dfa::DFA, regex::Regex};
    let mut builder = Regex::builder();
    builder.dfa(
        DFA::config()
            .skip_cache_capacity_check(true)
            .cache_capacity(0)
            .minimum_cache_clear_count(Some(0)),
    );
    match builder.build(pattern) {
        Ok(re) => {
            let mut cache = re.create_cache();
            report(re.try_search(&mut cache, &regex_automata::Input::new(text)));
        }
        Err(err) => println!("error\t{err}"),
    }
}

pub fn bytes_many(kind: &str, hex_text: &str, patterns: &[String]) {
    let bytes = match parse_hex_bytes(hex_text) {
        Ok(bytes) => bytes,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let input = Input::new(&bytes);
    let builder = Regex::builder();
    match kind {
        "dense" => match builder.build_many(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match builder.build_many_sparse(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

pub fn bytes_overlap(kind: &str, hex_text: &str, patterns: &[String]) {
    use regex_automata::dfa::dense;
    use regex_automata::MatchKind;
    let bytes = match parse_hex_bytes(hex_text) {
        Ok(bytes) => bytes,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let input = Input::new(&bytes);
    let config = dense::Config::new().match_kind(MatchKind::All);
    match kind {
        "dense" => match dense::Builder::new().configure(config).build_many(patterns) {
            Ok(dfa) => report_overlap(&dfa, &input),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match dense::Builder::new()
            .configure(config)
            .build_many(patterns)
            .and_then(|dfa| dfa.to_sparse())
        {
            Ok(dfa) => report_overlap(&dfa, &input),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

fn pattern_input<'h>(
    text: &'h str,
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
) -> Option<Input<'h>> {
    if mode != "no" && mode != "yes" {
        match mode.parse::<usize>() {
            Ok(id) => match regex_automata::PatternID::new(id) {
                Ok(_) => Some(configure_input(text, start, end, mode, earliest)),
                Err(_) => {
                    println!("none");
                    None
                }
            },
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        }
    } else {
        Some(configure_input(text, start, end, mode, earliest))
    }
}

pub fn pattern_search(
    kind: &str,
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    let Some(input) = pattern_input(text, start, end, mode, earliest) else {
        return;
    };
    let config = dense::Config::new().starts_for_each_pattern(true);
    let mut builder = Regex::builder();
    builder.dense(config);
    match kind {
        "dense" => match builder.build_many(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match builder.build_many_sparse(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

pub fn pattern_overlap(
    kind: &str,
    start: usize,
    end: usize,
    mode: &str,
    text: &str,
    patterns: &[String],
) {
    use regex_automata::MatchKind;
    let input = if mode != "no" && mode != "yes" {
        match mode.parse::<usize>() {
            Ok(id) => match regex_automata::PatternID::new(id) {
                Ok(_) => configure_input(text, start, end, mode, false),
                Err(_) => {
                    println!("count\t0");
                    return;
                }
            },
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        }
    } else {
        configure_input(text, start, end, mode, false)
    };
    let config = dense::Config::new()
        .match_kind(MatchKind::All)
        .starts_for_each_pattern(true);
    match kind {
        "dense" => match dense::Builder::new().configure(config).build_many(patterns) {
            Ok(dfa) => report_overlap(&dfa, &input),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match dense::Builder::new()
            .configure(config)
            .build_many(patterns)
            .and_then(|dfa| dfa.to_sparse())
        {
            Ok(dfa) => report_overlap(&dfa, &input),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

pub fn bytes_pattern(kind: &str, hex_text: &str, mode: &str, patterns: &[String]) {
    let bytes = match parse_hex_bytes(hex_text) {
        Ok(bytes) => bytes,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let id: usize = match mode.parse() {
        Ok(id) => id,
        Err(err) => {
            eprintln!("{err}");
            std::process::exit(2);
        }
    };
    let Some(pid) = regex_automata::PatternID::new(id).ok() else {
        println!("none");
        return;
    };
    let mut input = Input::new(&bytes);
    input.set_anchored(Anchored::Pattern(pid));
    let config = dense::Config::new().starts_for_each_pattern(true);
    let mut builder = Regex::builder();
    builder.dense(config);
    match kind {
        "dense" => match builder.build_many(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match builder.build_many_sparse(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

pub fn many(
    kind: &str,
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    let input = if mode != "no" && mode != "yes" {
        match mode.parse::<usize>() {
            Ok(id) => match regex_automata::PatternID::new(id) {
                Ok(_) => configure_input(text, start, end, mode, earliest),
                Err(_) => {
                    println!("none");
                    return;
                }
            },
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        }
    } else {
        configure_input(text, start, end, mode, earliest)
    };
    let builder = Regex::builder();
    match kind {
        "dense" => match builder.build_many(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match builder.build_many_sparse(patterns) {
            Ok(re) => report_pattern(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}

pub fn query(
    kind: &str,
    quit_hex: &str,
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    pattern: &str,
    text: &str,
) {
    let config = quit_config(quit_hex);
    let input = if mode != "no" && mode != "yes" {
        match mode.parse::<usize>() {
            Ok(id) => match regex_automata::PatternID::new(id) {
                Ok(_) => configure_input(text, start, end, mode, earliest),
                Err(_) => {
                    println!("none");
                    return;
                }
            },
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        }
    } else {
        configure_input(text, start, end, mode, earliest)
    };
    let mut builder = Regex::builder();
    builder.dense(config);
    match kind {
        "dense" => match builder.build(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        "sparse" => match builder.build_sparse(pattern) {
            Ok(re) => report(re.try_search(&input)),
            Err(err) => println!("error\t{err}"),
        },
        _ => {
            eprintln!("dfa kind must be dense or sparse");
            std::process::exit(2);
        }
    }
}
