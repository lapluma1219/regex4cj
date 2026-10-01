use regex_test::{MatchKind, RegexTest, RegexTests, SearchKind};
use std::path::Path;

const FILES: &[&str] = &[
    "anchored",
    "bytes",
    "crazy",
    "crlf",
    "earliest",
    "empty",
    "expensive",
    "flags",
    "iter",
    "leftmost-all",
    "line-terminator",
    "misc",
    "multiline",
    "no-unicode",
    "overlapping",
    "regression",
    "set",
    "substring",
    "unicode",
    "utf8",
    "word-boundary",
    "word-boundary-special",
    "fowler/basic",
    "fowler/nullsubexpr",
    "fowler/repetition",
];

pub fn emit(dir: &str) -> regex_test::anyhow::Result<()> {
    let dir = Path::new(dir);
    let mut tests = RegexTests::new();
    for name in FILES {
        let path = dir.join(format!("{name}.toml"));
        let data = std::fs::read(&path)?;
        tests.load_slice(name, &data)?;
    }
    for test in tests.iter() {
        if string_applicable(test) {
            emit_one(test, "string")?;
        }
        if bytes_applicable(test) {
            emit_one(test, "bytes")?;
        }
        if string_set_applicable(test) {
            emit_set(test, "string-set")?;
        }
        if bytes_set_applicable(test) {
            emit_set(test, "bytes-set")?;
        }
    }
    Ok(())
}

fn full_hay(test: &RegexTest) -> bool {
    let bounds = test.bounds();
    bounds.start == 0 && bounds.end == test.haystack().len()
}

fn string_applicable(test: &RegexTest) -> bool {
    test.compiles()
        && test.regexes().len() == 1
        && matches!(test.search_kind(), SearchKind::Leftmost)
        && matches!(test.match_kind(), MatchKind::LeftmostFirst)
        && !(test.anchored() && test.match_limit() != Some(1))
        && full_hay(test)
        && test.utf8()
}

fn bytes_applicable(test: &RegexTest) -> bool {
    test.compiles()
        && test.regexes().len() == 1
        && matches!(test.search_kind(), SearchKind::Leftmost)
        && matches!(test.match_kind(), MatchKind::LeftmostFirst)
        && !(test.anchored() && test.match_limit() != Some(1))
        && full_hay(test)
        && !test.utf8()
}

fn string_set_applicable(test: &RegexTest) -> bool {
    test.compiles()
        && matches!(test.search_kind(), SearchKind::Overlapping)
        && matches!(test.match_kind(), MatchKind::All)
        && !test.anchored()
        && full_hay(test)
        && test.utf8()
}

fn bytes_set_applicable(test: &RegexTest) -> bool {
    test.compiles()
        && matches!(test.search_kind(), SearchKind::Overlapping)
        && matches!(test.match_kind(), MatchKind::All)
        && !test.anchored()
        && full_hay(test)
        && !test.utf8()
}

fn emit_one(test: &RegexTest, api: &str) -> regex_test::anyhow::Result<()> {
    let limit = test.match_limit();
    let (code, find_out, caps_out, matched) = match api {
        "string" => {
            let hay = std::str::from_utf8(test.haystack()).unwrap_or("");
            match build_string(test) {
                Ok(re) => {
                    if hay.is_empty() && !std::str::from_utf8(test.haystack()).is_ok() {
                        (2, String::new(), String::new(), false)
                    } else {
                        let matched = re.is_match(hay);
                        (0, find_string(&re, hay, limit), caps_string(&re, hay, limit), matched)
                    }
                }
                Err(_) => (2, String::new(), String::new(), false),
            }
        }
        "bytes" => {
            let hay = test.haystack();
            match build_bytes(test) {
                Ok(re) => {
                    let matched = re.is_match(hay);
                    (0, find_bytes(&re, hay, limit), caps_bytes(&re, hay, limit), matched)
                }
                Err(_) => (2, String::new(), String::new(), false),
            }
        }
        _ => unreachable!(),
    };
    write_record(test, api, "is-match", if code == 0 { format!("{matched}\n") } else { String::new() }, code);
    write_record(test, api, "find", find_out, code);
    write_record(test, api, "captures", caps_out, code);
    Ok(())
}

fn emit_set(test: &RegexTest, api: &str) -> regex_test::anyhow::Result<()> {
    let (code, which_out, matched) = match api {
        "string-set" => {
            let hay = match std::str::from_utf8(test.haystack()) {
                Ok(hay) => hay,
                Err(_) => {
                    write_record(test, api, "is-match", String::new(), 2);
                    write_record(test, api, "which", String::new(), 2);
                    return Ok(());
                }
            };
            match build_string_set(test) {
                Ok(set) => (0, which_string(&set, hay), set.is_match(hay)),
                Err(_) => (2, String::new(), false),
            }
        }
        "bytes-set" => {
            let hay = test.haystack();
            match build_bytes_set(test) {
                Ok(set) => (0, which_bytes(&set, hay), set.is_match(hay)),
                Err(_) => (2, String::new(), false),
            }
        }
        _ => unreachable!(),
    };
    write_record(test, api, "is-match", if code == 0 { format!("{matched}\n") } else { String::new() }, code);
    write_record(test, api, "which", which_out, code);
    Ok(())
}

fn build_string(test: &RegexTest) -> Result<regex::Regex, regex::Error> {
    regex::RegexBuilder::new(&test.regexes()[0])
        .case_insensitive(test.case_insensitive())
        .unicode(test.unicode())
        .line_terminator(test.line_terminator())
        .build()
}

fn build_bytes(test: &RegexTest) -> Result<regex::bytes::Regex, regex::Error> {
    regex::bytes::RegexBuilder::new(&test.regexes()[0])
        .case_insensitive(test.case_insensitive())
        .unicode(test.unicode())
        .line_terminator(test.line_terminator())
        .build()
}

fn build_string_set(test: &RegexTest) -> Result<regex::RegexSet, regex::Error> {
    regex::RegexSetBuilder::new(test.regexes())
        .case_insensitive(test.case_insensitive())
        .unicode(test.unicode())
        .line_terminator(test.line_terminator())
        .build()
}

fn build_bytes_set(test: &RegexTest) -> Result<regex::bytes::RegexSet, regex::Error> {
    regex::bytes::RegexSetBuilder::new(test.regexes())
        .case_insensitive(test.case_insensitive())
        .unicode(test.unicode())
        .line_terminator(test.line_terminator())
        .build()
}

fn take_limit(limit: Option<usize>) -> usize {
    limit.unwrap_or(usize::MAX)
}

fn find_string(re: &regex::Regex, hay: &str, limit: Option<usize>) -> String {
    let mut out = String::new();
    for m in re.find_iter(hay).take(take_limit(limit)) {
        out.push_str(&format!("{}\t{}\t{}\n", m.start(), m.end(), hex(m.as_str().as_bytes())));
    }
    out
}

fn caps_string(re: &regex::Regex, hay: &str, limit: Option<usize>) -> String {
    let mut out = format!("groups\t{}\n", re.captures_len());
    for (i, name) in re.capture_names().enumerate() {
        if let Some(name) = name {
            out.push_str(&format!("name\t{i}\t{}\n", hex(name.as_bytes())));
        }
    }
    for caps in re.captures_iter(hay).take(take_limit(limit)) {
        out.push_str("match\n");
        for i in 0..caps.len() {
            match caps.get(i) {
                Some(m) => out.push_str(&format!(
                    "group\t{i}\t{}\t{}\t{}\n",
                    m.start(),
                    m.end(),
                    hex(m.as_str().as_bytes())
                )),
                None => out.push_str(&format!("group\t{i}\t-\n")),
            }
        }
    }
    out
}

fn find_bytes(re: &regex::bytes::Regex, hay: &[u8], limit: Option<usize>) -> String {
    let mut out = String::new();
    for m in re.find_iter(hay).take(take_limit(limit)) {
        out.push_str(&format!("{}\t{}\t{}\n", m.start(), m.end(), hex(m.as_bytes())));
    }
    out
}

fn caps_bytes(re: &regex::bytes::Regex, hay: &[u8], limit: Option<usize>) -> String {
    let mut out = format!("groups\t{}\n", re.captures_len());
    for (i, name) in re.capture_names().enumerate() {
        if let Some(name) = name {
            out.push_str(&format!("name\t{i}\t{}\n", hex(name.as_bytes())));
        }
    }
    for caps in re.captures_iter(hay).take(take_limit(limit)) {
        out.push_str("match\n");
        for i in 0..caps.len() {
            match caps.get(i) {
                Some(m) => out.push_str(&format!(
                    "group\t{i}\t{}\t{}\t{}\n",
                    m.start(),
                    m.end(),
                    hex(m.as_bytes())
                )),
                None => out.push_str(&format!("group\t{i}\t-\n")),
            }
        }
    }
    out
}

fn which_string(set: &regex::RegexSet, hay: &str) -> String {
    let result = set.matches(hay);
    let mut out = format!(
        "patterns\t{}\nany\t{}\nall\t{}\n",
        result.len(),
        result.matched_any(),
        result.matched_all()
    );
    for id in result.iter() {
        out.push_str(&format!("hit\t{id}\n"));
    }
    out
}

fn which_bytes(set: &regex::bytes::RegexSet, hay: &[u8]) -> String {
    let result = set.matches(hay);
    let mut out = format!(
        "patterns\t{}\nany\t{}\nall\t{}\n",
        result.len(),
        result.matched_any(),
        result.matched_all()
    );
    for id in result.iter() {
        out.push_str(&format!("hit\t{id}\n"));
    }
    out
}

fn write_record(test: &RegexTest, api: &str, op: &str, out: String, code: i32) {
    let limit = match test.match_limit() {
        Some(n) => n.to_string(),
        None => "null".into(),
    };
    let mut patterns = String::from("[");
    for (i, pattern) in test.regexes().iter().enumerate() {
        if i > 0 {
            patterns.push(',');
        }
        patterns.push('"');
        patterns.push_str(&json_escape(pattern));
        patterns.push('"');
    }
    patterns.push(']');
    println!(
        "{{\"name\":\"{}\",\"api\":\"{api}\",\"op\":\"{op}\",\"unicode\":{},\"casei\":{},\"term\":{},\"limit\":{limit},\"hay\":\"{}\",\"patterns\":{patterns},\"code\":{code},\"out\":\"{}\"}}",
        json_escape(&format!("{}/{}", test.full_name(), op)),
        test.unicode(),
        test.case_insensitive(),
        test.line_terminator(),
        hex(test.haystack()),
        json_escape(&out),
    );
}

fn hex(bytes: &[u8]) -> String {
    const HEX: &[u8; 16] = b"0123456789abcdef";
    let mut out = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        out.push(HEX[(byte >> 4) as usize] as char);
        out.push(HEX[(byte & 0xf) as usize] as char);
    }
    out
}

fn json_escape(text: &str) -> String {
    let mut out = String::new();
    for ch in text.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out
}
