use regex_automata::{dfa::regex::Regex, Input, MatchError};

fn report(result: Result<Option<regex_automata::Match>, MatchError>) {
    match result {
        Err(err) => println!("error\t{err}"),
        Ok(None) => println!("none"),
        Ok(Some(found)) => println!("span\t{}\t{}", found.start(), found.end()),
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
