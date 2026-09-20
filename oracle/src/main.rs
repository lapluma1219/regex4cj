use regex::Regex;
fn hex_text(text: &str) -> String {
    text.as_bytes().iter().map(|b| format!("{b:02x}")).collect()
}
fn print_capture_value(prefix: &str, value: Option<regex::Match<'_>>) {
    match value {
        Some(m) => println!("{}\t{}\t{}\t{}", prefix, m.start(), m.end(), hex_text(m.as_str())),
        None => println!("{}\t-", prefix),
    }
}
fn print_capture_result(re: &Regex, caps: &regex::Captures<'_>) {
    println!("match");
    for i in 0..caps.len() { print_capture_value(&format!("group\t{i}"), caps.get(i)); }
    for name in re.capture_names().flatten() {
        print_capture_value(&format!("named\t{}", hex_text(name)), caps.name(name));
    }
}
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
        Some("captures" | "capture-first") if a.len() == 3 => {
            match Regex::new(&a[1]) {
                Ok(re) => {
                    println!("groups\t{}", re.captures_len());
                    for (i, name) in re.capture_names().enumerate() {
                        if let Some(name) = name { println!("name\t{}\t{}", i, hex_text(name)); }
                    }
                    if a[0] == "captures" {
                        for caps in re.captures_iter(&a[2]) { print_capture_result(&re, &caps); }
                    } else if let Some(caps) = re.captures(&a[2]) {
                        print_capture_result(&re, &caps);
                    }
                },
                Err(e) => { eprintln!("{e}"); std::process::exit(2); }
            }
        },
        Some("capture-name") if a.len() == 4 => {
            match Regex::new(&a[1]) {
                Ok(re) => print_capture_value("value", re.captures(&a[2]).and_then(|caps| caps.name(&a[3]))),
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
        _ => { eprintln!("usage: regex-oracle escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | captures PATTERN TEXT | capture-first PATTERN TEXT | capture-name PATTERN TEXT NAME | demo"); std::process::exit(2); }
    }
}
