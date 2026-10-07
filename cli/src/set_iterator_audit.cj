package regex_cli

import regex4cj.*

func setIterValue(value: Option<Int64>): String {
    match (value) {
        case Some(n) => "${n}"
        case None => "none"
    }
}

func setIteratorProbe(family: String, mask: Int64, result: SetMatches): Unit {
    for (mode in 0..3) {
        let it = result.iter()
        var trace = ""
        for (step in 0..7) {
            let value = if (mode == 1 || (mode == 2 && step % 2 == 1)) { it.nextBack() } else { it.next() }
            if (step > 0) { trace += "," }
            let (lower, upper) = it.sizeHint()
            trace += setIterValue(value) + ":(${lower}, Some(${setIterValue(upper)}))"
        }
        println("set-iter-${family}-${mask}-${mode}\t${trace}")
    }
    let it = result.iter()
    it.next()
    let copy = it.clone()
    var trace = ""
    for (step in 0..6) {
        if (step > 0) { trace += "," }
        trace += setIterValue(it.nextBack()) + "," + setIterValue(copy.next())
    }
    println("set-iter-${family}-${mask}-clone\t${trace}")
}

func setIteratorAudit(): Unit {
    let patterns = ["a", "b", "c", "d"]
    let stringSet = RegexSet(patterns)
    let byteSet = BytesRegexSet(patterns)
    for (mask in 0..16) {
        var text = ""
        var divisor: Int64 = 1
        for (i in 0..4) {
            if (mask / divisor % 2 == 1) { text += patterns[i] }
            divisor *= 2
        }
        setIteratorProbe("s", mask, stringSet.matches(text))
        setIteratorProbe("b", mask, byteSet.matches(text.toArray()))
    }
}
