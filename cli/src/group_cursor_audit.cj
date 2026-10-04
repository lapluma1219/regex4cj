package regex_cli

import cjregex.*

func groupCursorValue(item: GroupItem): String {
    if (item.done) { return "None" }
    match (item.value) {
        case Some(m) => "Some(Some((${m.start}, ${m.end})))"
        case None => "Some(None)"
    }
}
func byteGroupCursorValue(item: BytesGroupItem): String {
    if (item.done) { return "None" }
    match (item.value) {
        case Some(m) => "Some(Some((${m.start}, ${m.end})))"
        case None => "Some(None)"
    }
}
func groupCursorProbe(id: Int64, caps: Captures): Unit {
    for (skip in 0..6) {
        let it = caps.iter()
        for (_ in 0..skip) { it.next() }
        let copy = it.clone()
        var trace = ""
        for (step in 0..6) {
            if (step > 0) { trace += "|" }
            let (low, high) = it.sizeHint()
            let (clow, chigh) = copy.sizeHint()
            trace += "${it.len()}:(${low}, Some(${setIterValue(high)}))|"
            trace += "${copy.len()}:(${clow}, Some(${setIterValue(chigh)}))|"
            trace += groupCursorValue(it.next()) + "|" + groupCursorValue(copy.next())
            copy.next()
        }
        println("group-cursor-s-${id}-${skip}\t${trace}")
    }
}
func byteGroupCursorProbe(id: Int64, caps: BytesCaptures): Unit {
    for (skip in 0..6) {
        let it = caps.iter()
        for (_ in 0..skip) { it.next() }
        let copy = it.clone()
        var trace = ""
        for (step in 0..6) {
            if (step > 0) { trace += "|" }
            let (low, high) = it.sizeHint()
            let (clow, chigh) = copy.sizeHint()
            trace += "${it.len()}:(${low}, Some(${setIterValue(high)}))|"
            trace += "${copy.len()}:(${clow}, Some(${setIterValue(chigh)}))|"
            trace += byteGroupCursorValue(it.next()) + "|" + byteGroupCursorValue(copy.next())
            copy.next()
        }
        println("group-cursor-b-${id}-${skip}\t${trace}")
    }
}
func groupCursorAudit(): Unit {
    let patterns = ["", "(a)(b)?", "(?<x>中)(a)?", "(a)|(b)"]
    let texts = ["", "a", "中a", "b"]
    for (id in 0..patterns.size) {
        groupCursorProbe(id, auditRequired(Regex(patterns[id]).captures(texts[id])))
        let caps = match (BytesRegex(patterns[id]).captures(texts[id].toArray())) {
            case Some(c) => c
            case None => throw Exception("expected captures")
        }
        byteGroupCursorProbe(id, caps)
    }
    let caps = match (BytesRegex("(?-u:(.))(a)?").captures([UInt8(255)])) {
        case Some(c) => c
        case None => throw Exception("expected captures")
    }
    byteGroupCursorProbe(4, caps)
}
