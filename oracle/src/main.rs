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
        Some("split" | "split-n" | "replace" | "replace-all" | "replace-n" | "replace-literal" | "replace-with" | "expand") => {
            let result = (|| -> Result<(), Box<dyn std::error::Error>> {
                let mode = a[0].as_str();
                let expected = match mode { "split" => 3, "replace-n" | "replace-literal" => 5, _ => 4 };
                if a.len() != expected { return Err("invalid argument count".into()); }
                let re = Regex::new(&a[1])?;
                match mode {
                    "split" => for part in re.split(&a[2]) { println!("{}", hex_text(part)); },
                    "split-n" => for part in re.splitn(&a[2], a[3].parse()?) { println!("{}", hex_text(part)); },
                    "expand" => if let Some(caps) = re.captures(&a[2]) {
                        let mut output = String::new(); caps.expand(&a[3], &mut output);
                        println!("{}", hex_text(&output));
                    },
                    "replace-with" => {
                        let mut calls = 0;
                        let output = re.replacen(&a[2], a[3].parse()?, |caps: &regex::Captures<'_>| {
                            calls += 1;
                            let mut value = format!("{calls}:");
                            caps.expand("<$0>[$1]", &mut value); value
                        });
                        println!("{}\n{}", hex_text(&output), calls);
                    },
                    "replace" => println!("{}", hex_text(&re.replace(&a[2], a[3].as_str()))),
                    "replace-all" => println!("{}", hex_text(&re.replace_all(&a[2], a[3].as_str()))),
                    "replace-n" => println!("{}", hex_text(&re.replacen(&a[2], a[4].parse()?, a[3].as_str()))),
                    "replace-literal" => println!("{}", hex_text(&re.replacen(&a[2], a[4].parse()?, regex::NoExpand(&a[3])))),
                    _ => unreachable!(),
                }
                Ok(())
            })();
            if let Err(e) = result { eprintln!("{e}"); std::process::exit(2); }
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
        _ => { eprintln!("usage: regex-oracle escape TEXT | find PATTERN TEXT | first PATTERN TEXT | is-match PATTERN TEXT | captures PATTERN TEXT | capture-first PATTERN TEXT | capture-name PATTERN TEXT NAME | split PATTERN TEXT | split-n PATTERN TEXT LIMIT | replace/replace-all/expand PATTERN TEXT TEMPLATE | replace-n/replace-literal PATTERN TEXT TEMPLATE LIMIT | replace-with PATTERN TEXT LIMIT | demo"); std::process::exit(2); }
    }
}
