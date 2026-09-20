use regex::Regex;
fn main() {
    let a: Vec<String> = std::env::args().skip(1).collect();
    match a.first().map(String::as_str) {
        Some("escape") if a.len() == 2 => println!("{}", regex::escape(&a[1])),
        Some("find") if a.len() == 3 => {
            match Regex::new(&a[1]) {
                Ok(re) => for m in re.find_iter(&a[2]) {
                    println!("{}\t{}\t{}", m.start(), m.end(), m.as_str());
                },
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("first" | "is-match") if a.len() == 3 => {
            match Regex::new(&a[1]) {
                Ok(re) => {
                    if a[0] == "is-match" { println!("{}", re.is_match(&a[2])); }
                    else if let Some(m) = re.find(&a[2]) {
                        println!("{}\t{}\t{}", m.start(), m.end(), m.as_str());
                    }
                },
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("demo") => {
            let text = "order=AB-123; order=CD-456";
            let re = Regex::new(r"(?P<prefix>[A-Z]{2})-(?P<number>[0-9]{3})").unwrap();
            for c in re.captures_iter(text) {
                let m = c.get(0).unwrap();
                println!("{} [{}..{}) prefix={} number={}", m.as_str(), m.start(), m.end(), &c["prefix"], &c["number"]);
            }
            println!("{}", re.replace_all(text, "${prefix}-***"));
        },
        _ => { eprintln!("usage: regex-oracle escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | demo"); std::process::exit(2); }
    }
}
