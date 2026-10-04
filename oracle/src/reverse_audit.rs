use regex_automata::nfa::thompson;
use regex_automata::{dfa::{dense::DFA, Automaton}, Input};

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
