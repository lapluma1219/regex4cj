use regex::{Regex, RegexBuilder, RegexSet, RegexSetBuilder};
use crate::hex_bytes;
fn span(m: Option<regex::Match<'_>>) -> String {
    m.map(|m| format!("{}:{}", m.start(), m.end())).unwrap_or("none".into())
}
fn loc(m: Option<(usize,usize)>) -> String {
    m.map(|(a,b)|format!("{a}:{b}")).unwrap_or("none".into())
}
pub fn run() {
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
