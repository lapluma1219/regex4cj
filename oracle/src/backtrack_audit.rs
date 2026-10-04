use regex_automata::{nfa::thompson::backtrack::BoundedBacktracker, Input};

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
