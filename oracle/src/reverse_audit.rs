use regex_automata::nfa::thompson;
use regex_automata::{dfa::{dense::DFA, Automaton}, Anchored, Input};

pub fn search(pattern: &str, text: &str) {
    let config = thompson::Config::new()
        .reverse(true)
        .which_captures(thompson::WhichCaptures::None);
    match DFA::builder().thompson(config).build(pattern) {
        Err(err) => println!("error\t{err}"),
        Ok(dfa) => match dfa.try_search_rev(&Input::new(text)) {
            Err(err) => println!("error\t{err}"),
            Ok(None) => println!("none"),
            Ok(Some(hm)) => println!("offset\t{}", hm.offset()),
        },
    }
}

pub fn empty() {
    let config = thompson::Config::new()
        .reverse(true)
        .which_captures(thompson::WhichCaptures::None);
    let dfa = match DFA::builder().thompson(config).build_many(&[] as &[String]) {
        Err(err) => {
            println!("error\t{err}");
            return;
        }
        Ok(dfa) => dfa,
    };
    match dfa.try_search_rev(&Input::new("ab")) {
        Err(err) => println!("error\t{err}"),
        Ok(None) => println!("none"),
        Ok(Some(found)) => println!("offset\t{}", found.offset()),
    }
}

pub fn limited(limit: usize, pattern: &str) {
    let config = thompson::Config::new()
        .reverse(true)
        .which_captures(thompson::WhichCaptures::None)
        .nfa_size_limit(Some(limit));
    match DFA::builder().thompson(config).build(pattern) {
        Err(err) => println!("error\t{err}"),
        Ok(_) => println!("ok"),
    }
}

pub fn many(start: usize, end: usize, mode: &str, text: &str, patterns: &[String]) {
    use regex_automata::dfa::dense::Config;
    let config = thompson::Config::new()
        .reverse(true)
        .which_captures(thompson::WhichCaptures::None);
    let dfa = match DFA::builder()
        .configure(Config::new().starts_for_each_pattern(true))
        .thompson(config)
        .build_many(patterns)
    {
        Err(err) => {
            println!("error\t{err}");
            return;
        }
        Ok(dfa) => dfa,
    };
    let mut input = Input::new(text).range(start..end);
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
    match dfa.try_search_rev(&input) {
        Err(err) => println!("error\t{err}"),
        Ok(None) => println!("none"),
        Ok(Some(found)) => {
            println!("pattern\t{}\toffset\t{}", found.pattern().as_usize(), found.offset())
        }
    }
}

pub fn query(start: usize, end: usize, mode: &str, pattern: &str, text: &str) {
    let config = thompson::Config::new()
        .reverse(true)
        .which_captures(thompson::WhichCaptures::None);
    let dfa = match DFA::builder().thompson(config).build(pattern) {
        Err(err) => {
            println!("error\t{err}");
            return;
        }
        Ok(dfa) => dfa,
    };
    let mut input = Input::new(text).range(start..end);
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
    match dfa.try_search_rev(&input) {
        Err(err) => println!("error\t{err}"),
        Ok(None) => println!("none"),
        Ok(Some(hm)) => println!("offset\t{}", hm.offset()),
    }
}
