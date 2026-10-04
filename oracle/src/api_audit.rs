use regex::{Regex, RegexBuilder, RegexSet, RegexSetBuilder};
use crate::hex_bytes;
fn span(m: Option<regex::Match<'_>>) -> String {
    m.map(|m| format!("{}:{}", m.start(), m.end())).unwrap_or("none".into())
}
fn loc(m: Option<(usize,usize)>) -> String {
    m.map(|(a,b)|format!("{a}:{b}")).unwrap_or("none".into())
}
pub fn run() {
    append_builder_audit();
    set_iterator_audit();
    group_cursor_audit();
    crate::lazy_audit::run();
    for (id, pattern, text) in [("empty", "", "中"), ("greedy", "a*", "a中"), ("miss", "z", "中")] {
        let re=Regex::new(pattern).unwrap(); let mut it=re.find_iter(text);
        for i in 0..5 { println!("iter-{id}-{i}\t{}",span(it.next())); }
        let mut it=re.captures_iter(text);
        for i in 0..5 { println!("capiter-{id}-{i}\t{}",span(it.next().map(|c|c.get_match()))); }
    }
    for (id, pattern, text) in [("empty", "", ""), ("unicode", "", "中"), ("tail", "$", "a"), ("miss", "z", "ab")] {
        let re=Regex::new(pattern).unwrap(); let mut it=re.split(text);
        for i in 0..5 { println!("splititer-{id}-{i}\t{}",it.next().map(|s|format!("hex:{}",hex_bytes(s.as_bytes()))).unwrap_or("none".into())); }
    }
    let re=Regex::new("(a)(b)?").unwrap(); let retained=re.captures("ab").unwrap(); let mut slots=re.capture_locations();
    re.captures_read(&mut slots,"ab"); println!("loc-hit\t{}",loc(slots.get(2)));
    re.captures_read(&mut slots,"a"); println!("loc-optional\t{}",loc(slots.get(2)));
    re.captures_read(&mut slots,"z"); println!("loc-miss\t{}",loc(slots.get(0)));
    println!("retained\t{}",span(retained.get(2)));
    let mut groups=re.captures("a").unwrap().iter().map(|m|span(m)).collect::<Vec<_>>();
    println!("groups\t{}",groups.drain(..).collect::<Vec<_>>().join(","));
    let re=Regex::new("(a)|(b)").unwrap(); let (whole, [part])=re.captures("b").unwrap().extract::<1>(); println!("extract\t{whole}:{part}");
    let mut builder=RegexBuilder::new("a"); let first=builder.build().unwrap(); builder.case_insensitive(true); println!("builder-snapshot\t{}:{}",first.is_match("A"),builder.build().unwrap().is_match("A"));
    let mut builder=RegexSetBuilder::new(["a"]); let first=builder.build().unwrap(); builder.case_insensitive(true); println!("set-builder-snapshot\t{}:{}",first.is_match("A"),builder.build().unwrap().is_match("A"));
    let set=RegexSet::new(["a","b"]).unwrap(); let mut slots=[true,false]; let hit=set.matches_read_at(&mut slots,"b",0); println!("set-slots\t{hit}:{}:{}",slots[0],slots[1]);
    let hit=set.matches_read_at(&mut slots,"z",0); println!("set-slots-miss\t{hit}:{}:{}",slots[0],slots[1]);
    for (id,pattern) in [("literal","a"),("dot","."),("empty",""),("anchor",r"\A"),("boundary",r"\ba")] {
        let re=Regex::new(pattern).unwrap(); println!("offset-{id}\t{}",span(re.find_at("中a",1)));
        println!("offset-is-{id}\t{}",re.is_match_at("中a",1));
        println!("offset-cap-{id}\t{}",span(re.captures_at("中a",1).map(|c|c.get_match())));
        println!("offset-short-{id}\t{}",re.shortest_match_at("中a",1).map(|v|v.to_string()).unwrap_or("none".into()));
        let mut locations=re.capture_locations(); println!("offset-read-{id}\t{}",span(re.captures_read_at(&mut locations,"中a",1)));
    }
    println!("offset-set\t{}",RegexSet::new(["a"]).unwrap().is_match_at("中a",1));
    let re=regex::bytes::Regex::new(r"(?-u)(.)(a)?").unwrap(); let mut slots=re.capture_locations();
    re.captures_read(&mut slots,b"\xffa"); println!("bytes-loc-hit\t{}",loc(slots.get(2)));
    re.captures_read(&mut slots,b"\xff"); println!("bytes-loc-optional\t{}",loc(slots.get(2)));
    re.captures_read(&mut slots,b""); println!("bytes-loc-miss\t{}",loc(slots.get(0)));
    println!("bytes-replace\t{}",hex_bytes(&re.replace_all(b"\xffa", &b"$1\0\xff"[..])));
    println!("bytes-literal\t{}",hex_bytes(&re.replace_all(b"\xffa", regex::bytes::NoExpand(b"$1\0\xff"))));
    println!("bytes-callback\t{}",hex_bytes(&re.replace_all(b"\xffa",|c:&regex::bytes::Captures<'_>| c.get(1).unwrap().as_bytes().to_vec())));
    let mut builder=regex::bytes::RegexBuilder::new("a");let first=builder.build().unwrap();builder.case_insensitive(true);println!("bytes-builder-snapshot\t{}:{}",first.is_match(b"A"),builder.build().unwrap().is_match(b"A"));
    let mut builder=regex::bytes::RegexSetBuilder::new(["a"]);let first=builder.build().unwrap();builder.case_insensitive(true);println!("bytes-set-builder-snapshot\t{}:{}",first.is_match(b"A"),builder.build().unwrap().is_match(b"A"));
    let set=regex::bytes::RegexSet::new(["a",r"(?-u)\xff"]).unwrap();let mut slots=[true,false];let hit=set.matches_read_at(&mut slots,b"\xff",0);println!("bytes-set-slots\t{hit}:{}:{}",slots[0],slots[1]);
}

fn set_iterator_audit() {
    macro_rules! probe {
        ($family:expr, $matches:expr, $mask:expr) => {{
            let result = $matches;
            for mode in 0..3 {
                let mut it = result.iter();
                let mut trace = Vec::new();
                for step in 0..7 {
                    let value = if mode == 1 || (mode == 2 && step % 2 == 1) { it.next_back() } else { it.next() };
                    trace.push(format!("{}:{:?}", value.map(|n|n.to_string()).unwrap_or("none".into()), it.size_hint()));
                }
                println!("set-iter-{}-{}-{}\t{}", $family, $mask, mode, trace.join(","));
            }
            let mut it = result.iter();
            let _ = it.next();
            let mut copy = it.clone();
            let mut trace = Vec::new();
            for _ in 0..6 {
                trace.push(it.next_back().map(|n|n.to_string()).unwrap_or("none".into()));
                trace.push(copy.next().map(|n|n.to_string()).unwrap_or("none".into()));
            }
            println!("set-iter-{}-{}-clone\t{}", $family, $mask, trace.join(","));
        }};
    }
    let string = RegexSet::new(["a", "b", "c", "d"]).unwrap();
    let bytes = regex::bytes::RegexSet::new(["a", "b", "c", "d"]).unwrap();
    for mask in 0..16 {
        let text: String = (0..4).filter(|i| mask & (1 << i) != 0).map(|i| (b'a'+i) as char).collect();
        probe!("s", string.matches(&text), mask);
        probe!("b", bytes.matches(text.as_bytes()), mask);
    }
}

fn append_builder_audit() {
    let templates = ["$0", "$1", "${x}", "$2", "$$", "${missing}", "$99999999999999999999", "${x}_$2", "${", "tail$"];
    let re = Regex::new("(?<x>a)(b)?").unwrap();
    let bre = regex::bytes::Regex::new(r"(?-u)(?<x>.)(a)?").unwrap();
    for (input_id, text) in ["a", "ab"].iter().enumerate() {
        let caps = re.captures(text).unwrap();
        let raw = if input_id == 0 { &b"\xff"[..] } else { &b"\xffa"[..] };
        let bcaps = bre.captures(raw).unwrap();
        for (template_id, template) in templates.iter().enumerate() {
            for (prefix_id, prefix) in ["", "\0前缀:"].iter().enumerate() {
                let mut out = prefix.to_string();
                caps.expand(template, &mut out);
                caps.expand(template, &mut out);
                println!("append-s-{input_id}-{template_id}-{prefix_id}\t{}", hex_bytes(out.as_bytes()));
                let mut out = prefix.as_bytes().to_vec();
                bcaps.expand(template.as_bytes(), &mut out);
                bcaps.expand(template.as_bytes(), &mut out);
                println!("append-b-{input_id}-{template_id}-{prefix_id}\t{}", hex_bytes(&out));
            }
        }
    }
    for case in 0..2 {
        let mut patterns = vec!["a".to_string(), "a".to_string(), "z".to_string()];
        let mut builder = RegexSetBuilder::new(&patterns);
        let mut bytes = regex::bytes::RegexSetBuilder::new(&patterns);
        patterns[0] = "z".into();
        builder.case_insensitive(case == 1); bytes.case_insensitive(case == 1);
        let set = builder.build().unwrap(); let bset = bytes.build().unwrap();
        println!("builder-array-s-{case}\t{}:{}", set.patterns().join(","), set.matches("A").iter().map(|n|n.to_string()).collect::<Vec<_>>().join(","));
        println!("builder-array-b-{case}\t{}:{}", bset.patterns().join(","), bset.matches(b"A").iter().map(|n|n.to_string()).collect::<Vec<_>>().join(","));
    }
}

fn group_cursor_audit() {
    macro_rules! probe {
        ($family:expr, $id:expr, $caps:expr) => {{
            let caps = $caps;
            for skip in 0..6 {
                let mut it = caps.iter();
                for _ in 0..skip { it.next(); }
                let mut copy = it.clone();
                let mut trace = Vec::new();
                for _ in 0..6 {
                    trace.push(format!("{}:{:?}", it.len(), it.size_hint()));
                    trace.push(format!("{}:{:?}", copy.len(), copy.size_hint()));
                    trace.push(format!("{:?}", it.next().map(|v|v.map(|m|(m.start(),m.end())))));
                    trace.push(format!("{:?}", copy.next().map(|v|v.map(|m|(m.start(),m.end())))));
                    copy.next();
                }
                println!("group-cursor-{}-{}-{}\t{}", $family, $id, skip, trace.join("|"));
            }
        }};
    }
    for (id,(pattern,text)) in [("", ""), ("(a)(b)?", "a"), ("(?<x>中)(a)?", "中a"), ("(a)|(b)", "b")].iter().enumerate() {
        let re=Regex::new(pattern).unwrap();
        let bre=regex::bytes::Regex::new(pattern).unwrap();
        probe!("s",id,re.captures(text).unwrap());
        probe!("b",id,bre.captures(text.as_bytes()).unwrap());
    }
    let re=regex::bytes::Regex::new(r"(?-u:(.))(a)?").unwrap();
    probe!("b",4,re.captures(b"\xff").unwrap());
}
