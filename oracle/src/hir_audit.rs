use regex_syntax::hir::{Hir,HirKind,Class,ClassUnicode,ClassUnicodeRange,ClassBytes,ClassBytesRange,Capture,Repetition,Look,Dot};
use crate::hex_bytes;
fn opt(n:Option<usize>)->String {n.map(|x|x.to_string()).unwrap_or("-".into())}
pub fn shape(h:&Hir)->String {
    let value=match h.kind() {
        HirKind::Empty=>"E".into(),
        HirKind::Literal(l)=>format!("L({})",hex_bytes(&l.0)),
        HirKind::Class(c)=>match c {
            Class::Unicode(c)=>format!("U({})",c.iter().map(|r|format!("{}-{}",r.start() as u32,r.end() as u32)).collect::<Vec<_>>().join(",")),
            Class::Bytes(c)=>format!("B({})",c.iter().map(|r|format!("{}-{}",r.start(),r.end())).collect::<Vec<_>>().join(","))},
        HirKind::Repetition(r)=>format!("R({},{},{},{})",r.min,r.max.map(|n|n.to_string()).unwrap_or("-".into()),r.greedy,shape(&r.sub)),
        HirKind::Capture(c)=>format!("C({},{},{})",c.index,c.name.as_ref().map(|n|hex_bytes(n.as_bytes())).unwrap_or("-".into()),shape(&c.sub)),
        HirKind::Look(l)=>format!("K({l:?})"),
        HirKind::Concat(s)=>format!("S({})",s.iter().map(shape).collect::<Vec<_>>().join(";")),
        HirKind::Alternation(s)=>format!("A({})",s.iter().map(shape).collect::<Vec<_>>().join(";")),
    };
    format!("{}{{{},{}}}",value,opt(h.properties().minimum_len()),opt(h.properties().maximum_len()))
}
pub fn parse(pattern:&str,utf8:bool) {
    match regex_syntax::ParserBuilder::new().utf8(utf8).build().parse(pattern) {
        Ok(h)=>println!("{}",shape(&h)),
        Err(e)=>{eprintln!("{e}");std::process::exit(2);}
    }
}
pub fn properties(pattern:&str,utf8:bool) {
    match regex_syntax::ParserBuilder::new().utf8(utf8).build().parse(pattern) {
        Ok(h)=>{
            let p=h.properties();
            let static_len=p.static_explicit_captures_len().map(|n|n.to_string()).unwrap_or("-".into());
            println!("utf8\t{}\tcaptures\t{}\tstatic\t{}\tliteral\t{}\talt\t{}\tlook\t{}\tpre\t{}\tpany\t{}\tsuf\t{}\tsany\t{}",
                if p.is_utf8(){1}else{0}, p.explicit_captures_len(), static_len,
                if p.is_literal(){1}else{0}, if p.is_alternation_literal(){1}else{0},
                p.look_set().bits, p.look_set_prefix().bits, p.look_set_prefix_any().bits,
                p.look_set_suffix().bits, p.look_set_suffix_any().bits);
        }
        Err(e)=>{eprintln!("{e}");std::process::exit(2);}
    }
}
pub fn print_hir(pattern:&str,utf8:bool) {
    match regex_syntax::ParserBuilder::new().utf8(utf8).build().parse(pattern) {
        Ok(h)=>println!("{h}"),
        Err(e)=>{eprintln!("{e}");std::process::exit(2);}
    }
}
pub fn constructors() {
    let base=vec![Hir::empty(),Hir::fail(),Hir::literal([]),Hir::literal([0,255]),
        Hir::class(Class::Unicode(ClassUnicode::new([ClassUnicodeRange::new('z','a'),ClassUnicodeRange::new('b','c')]))),
        Hir::class(Class::Unicode(ClassUnicode::new([ClassUnicodeRange::new('\u{D7FF}','\u{E000}')]))),
        Hir::class(Class::Bytes(ClassBytes::new([ClassBytesRange::new(255,254),ClassBytesRange::new(0,1)]))),
        Hir::capture(Capture{index:1,name:Some("名字".into()),sub:Box::new(Hir::empty())})];
    for (i,h) in base.iter().enumerate() {
        println!("base-{i}\t{}",shape(h));
        for (j,(min,max)) in [(0,Some(0)),(1,Some(1)),(0,None),(2,Some(3)),(2,None),(0,Some(1))].iter().enumerate() {
            for greedy in [false,true] {
                let rep=Hir::repetition(Repetition{min:*min,max:*max,greedy,sub:Box::new(h.clone())});
                println!("rep-{i}-{j}-{greedy}\t{}",shape(&rep));
                let cat=Hir::concat(vec![Hir::literal("a".as_bytes()),Hir::empty(),rep,Hir::concat(vec![Hir::literal([0xE4]),Hir::literal([0xB8,0xAD])])]);
                println!("concat-{i}-{j}-{greedy}\t{}",shape(&cat));
            }
        }
    }
    let mut huge=Hir::literal([97]);
    for i in 0..4 {
        huge=Hir::repetition(Repetition{min:u32::MAX,max:Some(u32::MAX),greedy:true,sub:Box::new(huge)});
        println!("huge-{i}\t{}",shape(&huge));
    }
    println!("huge-concat\t{}",shape(&Hir::concat(vec![huge.clone(),huge])));
    for look in [Look::Start,Look::End,Look::StartLF,Look::EndLF,Look::StartCRLF,Look::EndCRLF,
        Look::WordAscii,Look::WordAsciiNegate,Look::WordUnicode,Look::WordUnicodeNegate,
        Look::WordStartAscii,Look::WordEndAscii,Look::WordStartUnicode,Look::WordEndUnicode,
        Look::WordStartHalfAscii,Look::WordEndHalfAscii,Look::WordStartHalfUnicode,Look::WordEndHalfUnicode] {
        println!("look-{look:?}\t{}",shape(&Hir::look(look)));
    }
    for (name,dot) in [("AnyChar",Dot::AnyChar),("AnyByte",Dot::AnyByte),("AnyCharExceptLF",Dot::AnyCharExceptLF),
        ("AnyCharExceptCRLF",Dot::AnyCharExceptCRLF),("AnyByteExceptLF",Dot::AnyByteExceptLF),
        ("AnyByteExceptCRLF",Dot::AnyByteExceptCRLF)] {
        println!("dot-{name}\t{}",shape(&Hir::dot(dot)));
    }
    println!("dot-except-char\t{}",shape(&Hir::dot(Dot::AnyCharExcept('!'))));
    println!("dot-except-byte\t{}",shape(&Hir::dot(Dot::AnyByteExcept(255u8))));
    println!("alt-chars\t{}",shape(&Hir::alternation(vec![Hir::literal("a".as_bytes()),Hir::literal("b".as_bytes())])));
    println!("alt-keep\t{}",shape(&Hir::alternation(vec![Hir::literal("a".as_bytes()),Hir::literal("ab".as_bytes())])));
    let upper=Hir::class(Class::Unicode(ClassUnicode::new([ClassUnicodeRange::new('A','Z')])));
    let lower=Hir::class(Class::Unicode(ClassUnicode::new([ClassUnicodeRange::new('a','z')])));
    println!("alt-prefix\t{}",shape(&Hir::alternation(vec![
        Hir::concat(vec![Hir::literal("abc".as_bytes()),upper]),
        Hir::concat(vec![Hir::literal("abc".as_bytes()),lower]),
    ])));
    println!("alt-bytes\t{}",shape(&Hir::alternation(vec![
        Hir::class(Class::Bytes(ClassBytes::new([ClassBytesRange::new(200,201)]))),
        Hir::class(Class::Bytes(ClassBytes::new([ClassBytesRange::new(202,210)]))),
    ])));
}
