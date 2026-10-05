use regex_automata::dfa::onepass::DFA;
use regex_automata::meta::Regex as Meta;
use regex_automata::{dfa::regex::Regex as DfaRegex, Input};

pub fn onepass(pattern: &str, text: &str) {
    let dfa = match DFA::new(pattern) {
        Ok(dfa) => dfa,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    let mut cache = dfa.create_cache();
    let mut caps = dfa.create_captures();
    let input = Input::new(text).anchored(regex_automata::Anchored::Yes);
    if let Err(err) = dfa.try_search(&mut cache, &input, &mut caps) {
        println!("error\t{err}");
        return;
    }
    match caps.get_match() {
        None => println!("none"),
        Some(found) => println!("span\t{}\t{}", found.start(), found.end()),
    }
}

pub fn meta(pattern: &str, text: &str) {
    let re = match Meta::new(pattern) {
        Ok(re) => re,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    match re.find(text) {
        None => println!("none"),
        Some(found) => println!("span\t{}\t{}", found.start(), found.end()),
    }
}

pub fn lite(pattern: &str, text: &str) {
    let re = match regex_lite::Regex::new(pattern) {
        Ok(re) => re,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    match re.find(text) {
        None => println!("none"),
        Some(found) => println!("span\t{}\t{}", found.start(), found.end()),
    }
}

pub fn rure(pattern: &str, text: &str) {
    let re = match regex::Regex::new(pattern) {
        Ok(re) => re,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    println!("is-match\t{}", re.is_match(text));
    match re.find(text) {
        None => println!("none"),
        Some(found) => println!("span\t{}\t{}", found.start(), found.end()),
    }
}

pub fn dfa_image(pattern: &str, text: &str) {
    let re = match DfaRegex::new(pattern) {
        Ok(re) => re,
        Err(err) => {
            println!("error\t{err}");
            return;
        }
    };
    match re.find(text) {
        None => println!("none"),
        Some(found) => println!("span\t{}\t{}", found.start(), found.end()),
    }
}
