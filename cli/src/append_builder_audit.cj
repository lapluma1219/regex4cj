package regex_cli

import cjregex.*
import std.collection.*

func appendBuilderAudit(): Unit {
    let templates = [#"$0"#, #"$1"#, #"${x}"#, #"$2"#, #"$$"#, #"${missing}"#, #"$99999999999999999999"#, #"${x}_$2"#, #"${"#, #"tail$"#]
    let re = Regex("(?<x>a)(b)?")
    let bre = BytesRegex("(?-u)(?<x>.)(a)?")
    let texts = ["a", "ab"]
    let prefixes = ["", String([Rune(UInt32(0))]) + "前缀:"]
    for (inputId in 0..2) {
        let caps = auditRequired(re.captures(texts[inputId]))
        let raw = if (inputId == 0) { [UInt8(255)] } else { [UInt8(255), UInt8(97)] }
        let bcaps = match (bre.captures(raw)) {
            case Some(c) => c
            case None => throw Exception("expected byte captures")
        }
        for (templateId in 0..templates.size) {
            let template = templates[templateId]
            for (prefixId in 0..prefixes.size) {
                let out = StringBuilder()
                out.append(prefixes[prefixId])
                caps.expandInto(template, out)
                caps.expandInto(template, out)
                println("append-s-${inputId}-${templateId}-${prefixId}\t${hexBytes(out.toString().toArray())}")
                let bytes = ArrayList<UInt8>()
                for (b in prefixes[prefixId].toArray()) { bytes.add(b) }
                bcaps.expandInto(template.toArray(), bytes)
                bcaps.expandInto(template.toArray(), bytes)
                println("append-b-${inputId}-${templateId}-${prefixId}\t${hexBytes(bytes.toArray())}")
            }
        }
    }
    for (caseId in 0..2) {
        let patterns = ["a", "a", "z"]
        let builder = RegexSetBuilder(patterns)
        let bytes = BytesRegexSetBuilder(patterns)
        patterns[0] = "z"
        let set = builder.caseInsensitive(caseId == 1).build()
        let bset = bytes.caseInsensitive(caseId == 1).build()
        var ids = ""
        for (i in set.matches("A").indices()) {
            if (!ids.isEmpty()) { ids += "," }
            ids += "${i}"
        }
        var bids = ""
        for (i in bset.matches("A".toArray()).indices()) {
            if (!bids.isEmpty()) { bids += "," }
            bids += "${i}"
        }
        let p = set.patterns()
        let bp = bset.patterns()
        println("builder-array-s-${caseId}\t${p[0]},${p[1]},${p[2]}:${ids}")
        println("builder-array-b-${caseId}\t${bp[0]},${bp[1]},${bp[2]}:${bids}")
    }
}
