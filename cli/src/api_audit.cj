package regex_cli

import cjregex.*

func auditSpan(value: Option<RegexMatch>): String {
    match (value) {
        case Some(m) => "${m.start}:${m.end}"
        case None => "none"
    }
}

func auditLocation(value: Option<CaptureSpan>): String {
    match (value) {
        case Some(m) => "${m.start}:${m.end}"
        case None => "none"
    }
}

func auditCaptures(value: Option<Captures>): String {
    match (value) {
        case Some(c) => auditSpan(Some(c.getMatch()))
        case None => "none"
    }
}

func auditRequired(value: Option<Captures>): Captures {
    match (value) {
        case Some(c) => c
        case None => throw Exception("audit requires captures")
    }
}

func auditEmit(id: String, operation: () -> String): Unit {
    try {
        println("${id}\t${operation()}")
    } catch (e: Exception) {
        println("${id}\terror:${e.toString()}")
    }
}

func apiContractAudit(): Unit {
    extendedAudit()
    let ids = ["empty", "greedy", "miss"]
    let patterns = ["", "a*", "z"]
    let texts = ["中", "a中", "中"]
    for (n in 0..ids.size) {
        let re = Regex(patterns[n])
        let it = re.findIter(texts[n])
        for (i in 0..5) {
            println("iter-${ids[n]}-${i}\t${auditSpan(it.next())}")
        }
        let caps = re.capturesIter(texts[n])
        for (i in 0..5) {
            println("capiter-${ids[n]}-${i}\t${auditCaptures(caps.next())}")
        }
    }
    let splitIds = ["empty", "unicode", "tail", "miss"]
    let splitPatterns = ["", "", "$", "z"]
    let splitTexts = ["", "中", "a", "ab"]
    for (n in 0..splitIds.size) {
        let it = Regex(splitPatterns[n]).splitIter(splitTexts[n])
        for (i in 0..5) {
            let result = match (it.next()) {
                case Some(s) => "hex:${hexText(s)}"
                case None => "none"
            }
            println("splititer-${splitIds[n]}-${i}\t${result}")
        }
    }
    let re = Regex("(a)(b)?")
    let retained = auditRequired(re.captures("ab"))
    let slots = re.captureLocations()
    re.capturesRead(slots, "ab")
    println("loc-hit\t${auditLocation(slots.get(2))}")
    re.capturesRead(slots, "a")
    println("loc-optional\t${auditLocation(slots.get(2))}")
    re.capturesRead(slots, "z")
    println("loc-miss\t${auditLocation(slots.get(0))}")
    println("retained\t${auditSpan(retained.get(2))}")
    let groups = auditRequired(re.captures("a")).iter()
    let groupText = StringBuilder()
    for (i in 0..3) {
        if (i > 0) {
            groupText.append(",")
        }
        groupText.append(auditSpan(groups.next().value))
    }
    println("groups\t${groupText.toString()}")
    let extracted = auditRequired(Regex("(a)|(b)").captures("b")).extract(1)
    println("extract\t${extracted[0]}:${extracted[1]}")
    let builder = RegexBuilder("a")
    let first = builder.build()
    builder.caseInsensitive(true)
    println("builder-snapshot\t${first.isMatch("A")}:${builder.build().isMatch("A")}")
    let setBuilder = RegexSetBuilder().pattern("a")
    let firstSet = setBuilder.build()
    setBuilder.caseInsensitive(true)
    println("set-builder-snapshot\t${firstSet.isMatch("A")}:${setBuilder.build().isMatch("A")}")
    let set = RegexSet(["a", "b"])
    let setSlots = [true, false]
    let hit = set.matchesReadAt(setSlots, "b", 0)
    println("set-slots\t${hit}:${setSlots[0]}:${setSlots[1]}")
    let missed = set.matchesReadAt(setSlots, "z", 0)
    println("set-slots-miss\t${missed}:${setSlots[0]}:${setSlots[1]}")
    let offsetIds = ["literal", "dot", "empty", "anchor", "boundary"]
    let offsetPatterns = ["a", ".", "", #"\A"#, #"\ba"#]
    for (i in 0..offsetIds.size) {
        let item = Regex(offsetPatterns[i])
        auditEmit("offset-${offsetIds[i]}", {=> auditSpan(item.findAt("中a", 1))})
        auditEmit("offset-is-${offsetIds[i]}", {=> item.isMatchAt("中a", 1).toString()})
        auditEmit("offset-cap-${offsetIds[i]}", {=> auditCaptures(item.capturesAt("中a", 1))})
        auditEmit("offset-short-${offsetIds[i]}", {
            => match (item.shortestMatchAt("中a", 1)) {
                case Some(v) => v.toString()
                case None => "none"
            }
        })
        auditEmit("offset-read-${offsetIds[i]}", {=> auditSpan(item.capturesReadAt(item.captureLocations(), "中a", 1))})
    }
    auditEmit("offset-set", {=> RegexSet(["a"]).isMatchAt("中a", 1).toString()})
    let bytesRe = BytesRegex(#"(?-u)(.)(a)?"#)
    let byteSlots = bytesRe.captureLocations()
    bytesRe.capturesReadAt(byteSlots, parseHex("ff61"), 0)
    println("bytes-loc-hit\t${auditLocation(byteSlots.get(2))}")
    bytesRe.capturesReadAt(byteSlots, parseHex("ff"), 0)
    println("bytes-loc-optional\t${auditLocation(byteSlots.get(2))}")
    bytesRe.capturesReadAt(byteSlots, parseHex(""), 0)
    println("bytes-loc-miss\t${auditLocation(byteSlots.get(0))}")
    println("bytes-replace\t${hexBytes(bytesRe.replaceAll(parseHex("ff61"), parseHex("243100ff")))}")
    println("bytes-literal\t${hexBytes(bytesRe.replaceLiteral(parseHex("ff61"), 0, parseHex("243100ff")))}")
    let callbackResult = bytesRe.replaceWith(parseHex("ff61"), 0, {
        c => match (c.get(1)) {
            case Some(m) => m.bytes
            case None => parseHex("")
        }
    })
    println("bytes-callback\t${hexBytes(callbackResult)}")
    let bytesBuilder = BytesRegexBuilder("a")
    let bytesFirst = bytesBuilder.build()
    bytesBuilder.caseInsensitive(true)
    println(
        "bytes-builder-snapshot\t${bytesFirst.isMatch(parseHex("41"))}:${bytesBuilder.build().isMatch(parseHex("41"))}")
    let bytesSetBuilder = BytesRegexSetBuilder().pattern("a")
    let bytesFirstSet = bytesSetBuilder.build()
    bytesSetBuilder.caseInsensitive(true)
    println(
        "bytes-set-builder-snapshot\t${bytesFirstSet.isMatch(parseHex("41"))}:${bytesSetBuilder.build().isMatch(parseHex("41"))}")
    let bytesSet = BytesRegexSet(["a", #"(?-u)\xff"#])
    let bytesSetSlots = [true, false]
    let byteHit = bytesSet.matchesReadAt(bytesSetSlots, parseHex("ff"), 0)
    println("bytes-set-slots\t${byteHit}:${bytesSetSlots[0]}:${bytesSetSlots[1]}")
}
