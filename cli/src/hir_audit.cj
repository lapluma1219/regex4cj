package regex_cli

import cjregex.*

func hirNumber(value: Option<UInt64>): String {
    match (value) { case Some(n) => "${n}"; case None => "-" }
}
func hirShape(h: Hir): String {
    let value = match (h.kind()) {
        case HirKind.Empty => "E"
        case HirKind.Literal(bytes) => "L(${hexBytes(bytes)})"
        case HirKind.Class(c) =>
            var ranges = ""
            for (r in c.ranges()) {
                if (!ranges.isEmpty()) { ranges += "," }
                ranges += "${r.start}-${r.end}"
            }
            (if (c.isBytes) { "B" } else { "U" }) + "(${ranges})"
        case HirKind.Repetition(r) =>
            let max = match (r.max) { case Some(n) => "${n}"; case None => "-" }
            "R(${r.min},${max},${r.greedy},${hirShape(r.sub)})"
        case HirKind.Capture(c) =>
            let name = match (c.name) { case Some(n) => hexBytes(n.toArray()); case None => "-" }
            "C(${c.index},${name},${hirShape(c.sub)})"
        case HirKind.Concat(children) =>
            var result = ""
            for (child in children) {
                if (!result.isEmpty()) { result += ";" }
                result += hirShape(child)
            }
            "S(${result})"
    }
    let props = h.properties()
    return value + "{" + hirNumber(props.minimumLen()) + "," + hirNumber(props.maximumLen()) + "}"
}
func hirConstructorAudit(): Unit {
    let base = [Hir.empty(), Hir.fail(), Hir.literal(Array<UInt8>()), Hir.literal([UInt8(0), UInt8(255)]),
        Hir.unicodeClass([HirRange(122, 97), HirRange(98, 99)]),
        Hir.unicodeClass([HirRange(0xD7FF, 0xE000)]),
        Hir.byteClass([HirRange(255, 254), HirRange(0, 1)]),
        Hir.capture(UInt32(1), Some("名字"), Hir.empty())]
    let minima: Array<UInt32> = [0, 1, 0, 2, 2, 0]
    let maxima: Array<Option<UInt32>> = [Some(0), Some(1), None, Some(3), None, Some(1)]
    for (i in 0..base.size) {
        println("base-${i}\t${hirShape(base[i])}")
        for (j in 0..minima.size) {
            for (greedy in [false, true]) {
                let rep = Hir.repetition(minima[j], maxima[j], greedy, base[i])
                println("rep-${i}-${j}-${greedy}\t${hirShape(rep)}")
                let cat = Hir.concat([Hir.literal("a".toArray()), Hir.empty(), rep,
                    Hir.concat([Hir.literal([UInt8(0xE4)]), Hir.literal([UInt8(0xB8), UInt8(0xAD)])])])
                println("concat-${i}-${j}-${greedy}\t${hirShape(cat)}")
            }
        }
    }
    var huge = Hir.literal([UInt8(97)])
    for (i in 0..4) {
        huge = Hir.repetition(UInt32(0xFFFFFFFF), Some(UInt32(0xFFFFFFFF)), true, huge)
        println("huge-${i}\t${hirShape(huge)}")
    }
    println("huge-concat\t${hirShape(Hir.concat([huge, huge]))}")
}
