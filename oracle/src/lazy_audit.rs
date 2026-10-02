use regex::{Regex, RegexBuilder, RegexSetBuilder};
use crate::hex_bytes;
fn bs(m: Option<regex::bytes::Match<'_>>) -> String { m.map(|m|format!("{}:{}:{}",m.start(),m.end(),hex_bytes(m.as_bytes()))).unwrap_or("none".into()) }
fn part(m: Option<&[u8]>) -> String {m.map(|s|format!("hex:{}",hex_bytes(s))).unwrap_or("none".into())}
pub fn run() {
    let patterns=["", "(?-u).", "(a)?", "$", "z"];
    let texts: [&[u8];4]=[b"", b"a\xff", "中a".as_bytes(), b"a\0b"];
    for (p,pattern) in patterns.iter().enumerate() { for (t,text) in texts.iter().enumerate() {
        let re=regex::bytes::Regex::new(pattern).unwrap();let mut it=re.find_iter(text);let mut ci=re.captures_iter(text);let mut si=re.split(text);
        for i in 0..7 {
            println!("byte-iter-{p}-{t}-{i}\t{}",bs(it.next()));
            println!("byte-capiter-{p}-{t}-{i}\t{}",bs(ci.next().map(|c|c.get_match())));
            println!("byte-splititer-{p}-{t}-{i}\t{}",part(si.next()));
        }
        for limit in [0,1,2,5] {let mut it=re.splitn(text,limit);for i in 0..7 {println!("byte-splitn-{p}-{t}-{limit}-{i}\t{}",part(it.next()));}}
        for start in 0..=text.len() {
            println!("byte-at-{p}-{t}-{start}\t{}",bs(re.find_at(text,start)));
            println!("byte-isat-{p}-{t}-{start}\t{}",re.is_match_at(text,start));
            println!("byte-capat-{p}-{t}-{start}\t{}",bs(re.captures_at(text,start).map(|c|c.get_match())));
            let set=regex::bytes::RegexSet::new([*pattern,"a"]).unwrap();
            println!("byte-setat-{p}-{t}-{start}\t{}:{}:{}",set.is_match_at(text,start),set.matches_at(text,start).matched(0),set.matches_at(text,start).matched(1));
        }
    }}
    for (p,pattern) in ["",",","a*","$","z"].iter().enumerate() { for (t,text) in ["","a,b,c","中a"].iter().enumerate() {for limit in [0,1,2,5] {
        let re=Regex::new(pattern).unwrap();let mut it=re.splitn(text,limit);for i in 0..7 {println!("string-splitn-{p}-{t}-{limit}-{i}\t{}",part(it.next().map(str::as_bytes)));}
    }}}
    let re=regex::bytes::Regex::new("(?<name>a)|(b)").unwrap();
    println!("byte-meta\t{}:{}:{}",re.as_str(),re.captures_len(),re.static_captures_len().unwrap());
    for (i,n) in re.capture_names().enumerate(){println!("byte-name-{i}\t{}",n.unwrap_or("none"));}
    let c=re.captures(b"b").unwrap();let (whole,[group])=c.extract::<1>();println!("byte-extract\t{}:{}",hex_bytes(whole),hex_bytes(group));
    for (i,m) in c.iter().enumerate(){println!("byte-group-{i}\t{}",bs(m));}
    let m=c.get_match();println!("byte-match-meta\t{}:{}",m.is_empty(),m.len());
    for config in 0..16 { for (pi,pattern) in ["a+", "(?m)^a.$", "\\141+", "a # comment\n b", "\\w+", "."].iter().enumerate() {
        let mut b=RegexBuilder::new(pattern);
        b.case_insensitive(config & 1 != 0).multi_line(config & 2 != 0).dot_matches_new_line(config & 4 != 0).swap_greed(config & 8 != 0)
            .unicode(config % 3 != 0).ignore_whitespace(config % 2 == 0).crlf(config % 3 == 1).octal(config % 2 == 1)
            .line_terminator(if config % 4 == 0 {b'!'} else {b'\n'}).nest_limit(if config==14 {0} else {250})
            .size_limit(if config==15 {1} else {10*1024*1024}).dfa_size_limit(if config % 2==0 {0} else {128});
        let output=match b.build(){Ok(re)=>format!("{}:{}", re.is_match("A!ab\r\naZ\n"),re.is_match("中")),Err(_)=>"error".into()};
        println!("builder-s-{config}-{pi}\t{output}");
    }}
    for config in 0..16 { for (pi,pattern) in ["a+", "(?m)^a.$", "\\141+", "a # comment\n b", "\\w+", "."].iter().enumerate() {
        let mut b=RegexSetBuilder::new([*pattern,"z"]);
        b.case_insensitive(config & 1 != 0).multi_line(config & 2 != 0).dot_matches_new_line(config & 4 != 0).swap_greed(config & 8 != 0)
            .unicode(config % 3 != 0).ignore_whitespace(config % 2 == 0).crlf(config % 3 == 1).octal(config % 2 == 1)
            .line_terminator(if config % 4 == 0 {b'!'} else {b'\n'}).nest_limit(if config==14 {0} else {250})
            .size_limit(if config==15 {1} else {10*1024*1024}).dfa_size_limit(if config % 2==0 {0} else {128});
        let output=match b.build(){Ok(re)=>format!("{}:{}", re.is_match("A!ab\r\naZ\n"),re.is_match("中")),Err(_)=>"error".into()};
        println!("builder-ss-{config}-{pi}\t{output}");
    }}
    for config in 0..16 { for (pi,pattern) in ["a+", "(?m)^a.$", "\\141+", "a # comment\n b", "\\w+", "."].iter().enumerate() {
        let mut b=regex::bytes::RegexBuilder::new(pattern);
        b.case_insensitive(config & 1 != 0).multi_line(config & 2 != 0).dot_matches_new_line(config & 4 != 0).swap_greed(config & 8 != 0)
            .unicode(config % 3 != 0).ignore_whitespace(config % 2 == 0).crlf(config % 3 == 1).octal(config % 2 == 1)
            .line_terminator(if config % 4 == 0 {b'!'} else {b'\n'}).nest_limit(if config==14 {0} else {250})
            .size_limit(if config==15 {1} else {10*1024*1024}).dfa_size_limit(if config % 2==0 {0} else {128});
        let output=match b.build(){Ok(re)=>format!("{}:{}", re.is_match(b"A!ab\r\naZ\n"),re.is_match("中".as_bytes())),Err(_)=>"error".into()};
        println!("builder-b-{config}-{pi}\t{output}");
    }}
    for config in 0..16 { for (pi,pattern) in ["a+", "(?m)^a.$", "\\141+", "a # comment\n b", "\\w+", "."].iter().enumerate() {
        let mut b=regex::bytes::RegexSetBuilder::new([*pattern,"z"]);
        b.case_insensitive(config & 1 != 0).multi_line(config & 2 != 0).dot_matches_new_line(config & 4 != 0).swap_greed(config & 8 != 0)
            .unicode(config % 3 != 0).ignore_whitespace(config % 2 == 0).crlf(config % 3 == 1).octal(config % 2 == 1)
            .line_terminator(if config % 4 == 0 {b'!'} else {b'\n'}).nest_limit(if config==14 {0} else {250})
            .size_limit(if config==15 {1} else {10*1024*1024}).dfa_size_limit(if config % 2==0 {0} else {128});
        let output=match b.build(){Ok(re)=>format!("{}:{}", re.is_match(b"A!ab\r\naZ\n"),re.is_match("中".as_bytes())),Err(_)=>"error".into()};
        println!("builder-bs-{config}-{pi}\t{output}");
    }}
}
