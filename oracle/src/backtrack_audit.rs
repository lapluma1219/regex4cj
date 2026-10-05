use regex_automata::nfa::thompson::backtrack::BoundedBacktracker;
use regex_automata::nfa::thompson::{NFA, WhichCaptures};
use regex_automata::util::iter::Searcher;
use regex_automata::{Anchored, Input};

fn hex_text(text: &str) -> String {
    text.as_bytes().iter().map(|b| format!("{b:02x}")).collect()
}

fn build(capacity: &str, pattern: &str) -> Result<BoundedBacktracker, String> {
    let mut builder = BoundedBacktracker::builder();
    if capacity != "default" {
        let cap: usize = capacity
            .parse()
            .map_err(|err: std::num::ParseIntError| err.to_string())?;
        builder.configure(BoundedBacktracker::config().visited_capacity(cap));
    }
    builder.build(pattern).map_err(|err| err.to_string())
}

fn fail(err: String) -> ! {
    eprintln!("{err}");
    std::process::exit(2);
}

pub fn info(capacity: &str, pattern: &str) {
    let re = match build(capacity, pattern) {
        Ok(re) => re,
        Err(err) => fail(err),
    };
    println!("states\t{}", re.get_nfa().states().len());
    println!("max\t{}", re.max_haystack_len());
}

pub fn captures(capacity: &str, mode: &str, text: &str, patterns: &[String]) {
    let which = match mode {
        "all" => WhichCaptures::All,
        "implicit" => WhichCaptures::Implicit,
        "none" => WhichCaptures::None,
        _ => {
            eprintln!("capture mode must be all, implicit, or none");
            std::process::exit(2);
        }
    };
    let mut builder = BoundedBacktracker::builder();
    if capacity != "default" {
        let cap: usize = match capacity.parse() {
            Ok(cap) => cap,
            Err(err) => {
                eprintln!("{err}");
                std::process::exit(2);
            }
        };
        builder.configure(BoundedBacktracker::config().visited_capacity(cap));
    }
    builder.thompson(NFA::config().which_captures(which));
    let re = match builder.build_many(patterns) {
        Ok(re) => re,
        Err(err) => fail(err.to_string()),
    };
    let mut cache = re.create_cache();
    match re.try_is_match(&mut cache, text) {
        Ok(yes) => println!("is-match\t{yes}"),
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    }
    let mut caps = re.create_captures();
    if let Err(err) = re.try_captures(&mut cache, text, &mut caps) {
        println!("error\t{err}");
        return;
    }
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

pub fn iter(capacity: &str, text: &str, patterns: &[String]) {
    iter_range(capacity, 0, text.len(), text, patterns);
}

pub fn iter_range(capacity: &str, start: usize, end: usize, text: &str, patterns: &[String]) {
    let mut builder = BoundedBacktracker::builder();
    if capacity != "default" {
        let cap: usize = match capacity.parse() {
            Ok(cap) => cap,
            Err(err) => fail(err.to_string()),
        };
        builder.configure(BoundedBacktracker::config().visited_capacity(cap));
    }
    let re = match builder.build_many(patterns) {
        Ok(re) => re,
        Err(err) => fail(err.to_string()),
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    let input = Input::new(text).range(start..end);
    let mut finder = Searcher::new(input);
    loop {
        let advanced = finder.try_advance(|input| {
            re.try_search(&mut cache, input, &mut caps)?;
            Ok(caps.get_match())
        });
        match advanced {
            Ok(Some(found)) => {
                let piece = &text[found.start()..found.end()];
                println!(
                    "{}:{}:{}:{}",
                    found.pattern().as_usize(),
                    found.start(),
                    found.end(),
                    crate::cli_find::escape_text(piece)
                );
            }
            Ok(None) => break,
            Err(err) => {
                println!("error\t{err}");
                break;
            }
        }
    }
}

pub fn bytes_search(capacity: &str, start: usize, end: usize, mode: &str, hex: &str, patterns: &[String]) {
    let hay = {
        if hex.len() % 2 != 0 {
            eprintln!("hex text must have an even length");
            std::process::exit(2);
        }
        let mut out = Vec::new();
        let mut i = 0;
        while i < hex.len() {
            match u8::from_str_radix(&hex[i..i + 2], 16) {
                Ok(byte) => out.push(byte),
                Err(err) => {
                    eprintln!("{err}");
                    std::process::exit(2);
                }
            }
            i += 2;
        }
        out
    };
    let mut builder = BoundedBacktracker::builder();
    if capacity != "default" {
        let cap: usize = match capacity.parse() {
            Ok(cap) => cap,
            Err(err) => fail(err.to_string()),
        };
        builder.configure(BoundedBacktracker::config().visited_capacity(cap));
    }
    let re = match builder.build_many(patterns) {
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
                Err(err) => fail(err.to_string()),
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
    match re.try_search(&mut cache, &input, &mut caps) {
        Err(err) => println!("error\t{err}"),
        Ok(()) => match caps.get_match() {
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
                            hay[span.start..span.end]
                                .iter()
                                .map(|b| format!("{b:02x}"))
                                .collect::<String>()
                        ),
                    }
                }
            }
        },
    }
}

pub fn search(capacity: &str, pattern: &str, text: &str) {
    let re = match build(capacity, pattern) {
        Ok(re) => re,
        Err(err) => fail(err),
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    match re.try_search(&mut cache, &Input::new(text), &mut caps) {
        Err(err) => println!("error\t{err}"),
        Ok(()) => match caps.get_match() {
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
                            println!(
                                "group\t{i}\t{}\t{}\t{}",
                                span.start,
                                span.end,
                                hex_text(value)
                            );
                        }
                    }
                }
            }
        },
    }
}

fn configure_input<'h>(text: &'h str, start: usize, end: usize, mode: &str, earliest: bool) -> Option<Input<'h>> {
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
                Err(_) => return None,
            }
        }
    };
    Some(input)
}

fn report_caps(text: &str, caps: &regex_automata::util::captures::Captures) {
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
                        println!(
                            "group\t{i}\t{}\t{}\t{}",
                            span.start,
                            span.end,
                            hex_text(value)
                        );
                    }
                }
            }
        }
    }
}

pub fn query(capacity: &str, start: usize, end: usize, mode: &str, earliest: bool, text: &str, pattern: &str) {
    let re = match build(capacity, pattern) {
        Ok(re) => re,
        Err(err) => fail(err),
    };
    let Some(input) = configure_input(text, start, end, mode, earliest) else {
        println!("none");
        return;
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    match re.try_search(&mut cache, &input, &mut caps) {
        Err(err) => println!("error\t{err}"),
        Ok(()) => report_caps(text, &caps),
    }
}

pub fn many(
    capacity: &str,
    start: usize,
    end: usize,
    mode: &str,
    earliest: bool,
    text: &str,
    patterns: &[String],
) {
    let mut builder = BoundedBacktracker::builder();
    if capacity != "default" {
        let cap: usize = match capacity.parse() {
            Ok(cap) => cap,
            Err(err) => fail(err.to_string()),
        };
        builder.configure(BoundedBacktracker::config().visited_capacity(cap));
    }
    let re = match builder.build_many(patterns) {
        Ok(re) => re,
        Err(err) => fail(err.to_string()),
    };
    let Some(input) = configure_input(text, start, end, mode, earliest) else {
        println!("none");
        return;
    };
    let mut cache = re.create_cache();
    let mut caps = re.create_captures();
    match re.try_search(&mut cache, &input, &mut caps) {
        Err(err) => println!("error\t{err}"),
        Ok(()) => report_caps(text, &caps),
    }
}
