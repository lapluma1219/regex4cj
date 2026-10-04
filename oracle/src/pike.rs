use regex_automata::{nfa::thompson::pikevm::PikeVM, Anchored, Input};

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
