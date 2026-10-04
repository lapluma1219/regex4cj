use regex_syntax::hir::{Hir,HirKind,Class,ClassUnicode,ClassUnicodeRange,ClassBytes,ClassBytesRange,Capture,Repetition};
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
        HirKind::Concat(s)=>format!("S({})",s.iter().map(shape).collect::<Vec<_>>().join(";")),
        other=>format!("UNSUPPORTED({other:?})"),
    };
    format!("{}{{{},{}}}",value,opt(h.properties().minimum_len()),opt(h.properties().maximum_len()))
}
pub fn parse(pattern:&str,utf8:bool) {
    match regex_syntax::ParserBuilder::new().utf8(utf8).build().parse(pattern) {
        Ok(h)=>println!("{}",shape(&h)),
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
}
