package cjregex

import std.collection.*

// Prefix and suffix literal sequences from regex-syntax Extractor defaults:
// class limit 10, repeat limit 10, literal length 100, total 250.
public class LiteralPiece {
    public let exact: Bool
    public let bytes: Array<UInt8>
    init(exact: Bool, bytes: Array<UInt8>) {
        this.exact = exact
        this.bytes = bytes
    }
}

public class LiteralSeq {
    public let finite: Bool
    public let pieces: Array<LiteralPiece>
    init(finite: Bool, pieces: Array<LiteralPiece>) {
        this.finite = finite
        this.pieces = pieces
    }
}

public func extractLiterals(hir: Hir): LiteralSeq {
    extractLiterals(hir, false)
}

public func extractLiterals(hir: Hir, suffix: Bool): LiteralSeq {
    let engine = LiteralEngine(suffix)
    engine.extract(hir).publish()
}

public func formatLiterals(hir: Hir, suffix: Bool): String {
    let seq = extractLiterals(hir, suffix)
    if (!seq.finite) {
        return "infinite"
    }
    let out = StringBuilder()
    out.append("finite\t${seq.pieces.size}")
    for (piece in seq.pieces) {
        out.append("\n")
        if (piece.exact) {
            out.append("exact\t")
        } else {
            out.append("inexact\t")
        }
        out.append(hexBytes(piece.bytes))
    }
    out.toString()
}

class HeldLiteral {
    var exact: Bool
    let bytes: ArrayList<UInt8>
    init(exact: Bool) {
        this.exact = exact
        bytes = ArrayList<UInt8>()
    }
    func copy(): HeldLiteral {
        let out = HeldLiteral(exact)
        for (byte in bytes) {
            out.bytes.add(byte)
        }
        out
    }
    func appendBytes(other: HeldLiteral): Unit {
        for (byte in other.bytes) {
            bytes.add(byte)
        }
    }
    func keepFirst(len: Int64): Unit {
        if (len >= bytes.size) {
            return
        }
        exact = false
        while (bytes.size > len) {
            bytes.remove(at: bytes.size - 1)
        }
    }
    func keepLast(len: Int64): Unit {
        if (len >= bytes.size) {
            return
        }
        exact = false
        let drop = bytes.size - len
        for (_ in 0..drop) {
            bytes.remove(at: 0)
        }
    }
}

class HeldSeq {
    var finite: Bool = true
    let items = ArrayList<HeldLiteral>()
    func publish(): LiteralSeq {
        if (!finite) {
            return LiteralSeq(false, Array<LiteralPiece>())
        }
        let pieces = Array<LiteralPiece>(
            items.size,
            {
                i =>
                    let item = items[i]
                    LiteralPiece(item.exact, item.bytes.toArray())
            }
        )
        LiteralSeq(true, pieces)
    }
    func copy(): HeldSeq {
        let out = HeldSeq()
        out.finite = finite
        if (finite) {
            for (item in items) {
                out.items.add(item.copy())
            }
        }
        out
    }
    func drain(): Unit {
        while (items.size > 0) {
            items.remove(at: items.size - 1)
        }
    }
    func makeInexact(): Unit {
        if (!finite) {
            return
        }
        for (item in items) {
            item.exact = false
        }
    }
    func makeInfinite(): Unit {
        finite = false
        drain()
    }
    func isInexact(): Bool {
        if (!finite) {
            return true
        }
        for (item in items) {
            if (item.exact) {
                return false
            }
        }
        true
    }
    func minLen(): Option<Int64> {
        if (!finite || items.size == 0) {
            return None
        }
        var least = items[0].bytes.size
        for (item in items) {
            if (item.bytes.size < least) {
                least = item.bytes.size
            }
        }
        Some(least)
    }
    func length(): Option<Int64> {
        if (!finite) {
            None
        } else {
            Some(items.size)
        }
    }
    func maxUnion(other: HeldSeq): Option<Int64> {
        match (length()) {
            case None => None
            case Some(left) => match (other.length()) {
                case None => None
                case Some(right) => Some(left + right)
            }
        }
    }
    func maxCross(other: HeldSeq): Option<Int64> {
        match (length()) {
            case None => None
            case Some(left) => match (other.length()) {
                case None => None
                case Some(right) =>
                    if (left != 0 && right > 250 / left) {
                        Some(251)
                    } else {
                        Some(left * right)
                    }
            }
        }
    }
    func keepFirst(len: Int64): Unit {
        if (finite) {
            for (item in items) {
                item.keepFirst(len)
            }
        }
    }
    func keepLast(len: Int64): Unit {
        if (finite) {
            for (item in items) {
                item.keepLast(len)
            }
        }
    }
    func dedup(): Unit {
        if (!finite) {
            return
        }
        var index: Int64 = 0
        while (index + 1 < items.size) {
            if (sameBytes(items[index], items[index + 1])) {
                if (items[index].exact != items[index + 1].exact) {
                    items[index].exact = false
                    items[index + 1].exact = false
                }
                items.remove(at: index + 1)
            } else {
                index++
            }
        }
    }
    func steal(): Array<HeldLiteral> {
        let old = Array<HeldLiteral>(items.size, {i => items[i]})
        drain()
        old
    }
    func preamble(other: HeldSeq): Bool {
        if (!other.finite) {
            match (minLen()) {
                case Some(len) =>
                    if (len == 0) {
                        makeInfinite()
                    } else {
                        makeInexact()
                    }
                case None => makeInexact()
            }
            return false
        }
        if (!finite) {
            other.drain()
            return false
        }
        true
    }
    func crossForward(other: HeldSeq): Unit {
        if (!preamble(other)) {
            return
        }
        let mine = steal()
        for (selfLit in mine) {
            if (!selfLit.exact) {
                items.add(selfLit.copy())
            } else {
                for (otherLit in other.items) {
                    let created = selfLit.copy()
                    created.appendBytes(otherLit)
                    if (!otherLit.exact) {
                        created.exact = false
                    }
                    items.add(created)
                }
            }
        }
        other.drain()
        dedup()
    }
    func crossReverse(other: HeldSeq): Unit {
        if (!preamble(other)) {
            return
        }
        let mine = steal()
        var index: Int64 = 0
        for (otherLit in other.items) {
            for (selfLit in mine) {
                if (!selfLit.exact) {
                    if (index == 0) {
                        items.add(selfLit.copy())
                    }
                } else {
                    let created = otherLit.copy()
                    created.appendBytes(selfLit)
                    if (!otherLit.exact) {
                        created.exact = false
                    }
                    items.add(created)
                }
            }
            index++
        }
        other.drain()
        dedup()
    }
    func unionWith(other: HeldSeq): Unit {
        if (!other.finite) {
            makeInfinite()
            return
        }
        if (!finite) {
            other.drain()
            return
        }
        for (item in other.items) {
            items.add(item.copy())
        }
        other.drain()
        dedup()
    }
}

func sameBytes(left: HeldLiteral, right: HeldLiteral): Bool {
    if (left.bytes.size != right.bytes.size) {
        return false
    }
    for (i in 0..left.bytes.size) {
        if (left.bytes[i] != right.bytes[i]) {
            return false
        }
    }
    true
}

class LiteralEngine {
    let suffix: Bool
    let limitClass: Int64 = 10
    let limitRepeat: Int64 = 10
    let limitLiteral: Int64 = 100
    let limitTotal: Int64 = 250
    init(suffix: Bool) {
        this.suffix = suffix
    }
    func extract(hir: Hir): HeldSeq {
        match (hir.kind()) {
            case HirKind.Empty => blank()
            case HirKind.Look(_) => blank()
            case HirKind.Literal(bytes) =>
                let seq = fromBytes(bytes)
                enforce(seq)
                seq
            case HirKind.Class(cls) => extractClass(cls)
            case HirKind.Repetition(rep) => extractRepetition(rep)
            case HirKind.Capture(cap) => extract(cap.sub)
            case HirKind.Concat(nodes) => extractConcat(nodes)
            case HirKind.Alternation(nodes) => extractAlternation(nodes)
        }
    }
    func extractConcat(nodes: Array<Hir>): HeldSeq {
        var seq = blank()
        if (suffix) {
            var index = nodes.size - 1
            while (index >= 0) {
                if (seq.isInexact()) {
                    break
                }
                let next = extract(nodes[index])
                seq = cross(seq, next)
                index--
            }
        } else {
            for (node in nodes) {
                if (seq.isInexact()) {
                    break
                }
                seq = cross(seq, extract(node))
            }
        }
        seq
    }
    func extractAlternation(nodes: Array<Hir>): HeldSeq {
        var seq = HeldSeq()
        for (node in nodes) {
            if (!seq.finite) {
                break
            }
            seq = union(seq, extract(node))
        }
        seq
    }
    func extractRepetition(rep: HirRepetition): HeldSeq {
        let subseq = extract(rep.sub)
        if (rep.min == 0) {
            var bounded = false
            match (rep.max) {
                case Some(max) => bounded = max == 1
                case None => ()
            }
            if (!bounded) {
                subseq.makeInexact()
            }
            let empty = blank()
            if (rep.greedy) {
                union(subseq, empty)
            } else {
                union(empty, subseq)
            }
        } else {
            var fixed = false
            match (rep.max) {
                case Some(max) => fixed = rep.min == max
                case None => ()
            }
            let times = if (Int64(rep.min) < limitRepeat) {
                Int64(rep.min)
            } else {
                limitRepeat
            }
            var seq = blank()
            for (_ in 0..times) {
                if (seq.isInexact()) {
                    break
                }
                seq = cross(seq, subseq.copy())
            }
            if (!fixed || Int64(rep.min) > limitRepeat) {
                seq.makeInexact()
            }
            seq
        }
    }
    func extractClass(cls: HirClass): HeldSeq {
        if (classOverLimit(cls)) {
            return infinite()
        }
        let seq = HeldSeq()
        for (range in cls.ranges()) {
            var code = range.start
            while (code <= range.end) {
                if (cls.isBytes) {
                    let lit = HeldLiteral(true)
                    lit.bytes.add(UInt8(code))
                    seq.items.add(lit)
                } else {
                    seq.items.add(fromScalar(code))
                }
                code++
            }
        }
        enforce(seq)
        seq
    }
    func classOverLimit(cls: HirClass): Bool {
        var count: Int64 = 0
        for (range in cls.ranges()) {
            if (count > limitClass) {
                return true
            }
            let span = range.end - range.start + 1
            if (span > limitClass) {
                return true
            }
            count += span
        }
        count > limitClass
    }
    func cross(seq: HeldSeq, other: HeldSeq): HeldSeq {
        match (seq.maxCross(other)) {
            case Some(len) =>
                if (len > limitTotal) {
                    other.makeInfinite()
                }
            case None => ()
        }
        if (suffix) {
            seq.crossReverse(other)
        } else {
            seq.crossForward(other)
        }
        enforce(seq)
        seq
    }
    func union(seq: HeldSeq, other: HeldSeq): HeldSeq {
        var over = false
        match (seq.maxUnion(other)) {
            case Some(len) => over = len > limitTotal
            case None => ()
        }
        if (over) {
            if (suffix) {
                seq.keepLast(4)
                other.keepLast(4)
            } else {
                seq.keepFirst(4)
                other.keepFirst(4)
            }
            seq.dedup()
            other.dedup()
            match (seq.maxUnion(other)) {
                case Some(len) =>
                    if (len > limitTotal) {
                        other.makeInfinite()
                    }
                case None => ()
            }
        }
        seq.unionWith(other)
        seq
    }
    func enforce(seq: HeldSeq): Unit {
        if (suffix) {
            seq.keepLast(limitLiteral)
        } else {
            seq.keepFirst(limitLiteral)
        }
    }
}

func blank(): HeldSeq {
    let seq = HeldSeq()
    seq.items.add(HeldLiteral(true))
    seq
}

func infinite(): HeldSeq {
    let seq = HeldSeq()
    seq.makeInfinite()
    seq
}

func fromBytes(bytes: Array<UInt8>): HeldSeq {
    let seq = HeldSeq()
    let lit = HeldLiteral(true)
    for (byte in bytes) {
        lit.bytes.add(byte)
    }
    seq.items.add(lit)
    seq
}

func fromScalar(code: Int64): HeldLiteral {
    let lit = HeldLiteral(true)
    for (byte in utf8Of(code)) {
        lit.bytes.add(byte)
    }
    lit
}

func hexBytes(bytes: Array<UInt8>): String {
    let digits = [r'0', r'1', r'2', r'3', r'4', r'5', r'6', r'7', r'8', r'9', r'a', r'b', r'c', r'd', r'e', r'f']
    let out = StringBuilder()
    for (byte in bytes) {
        let value = Int64(byte)
        out.append(digits[(value >> 4) & 15])
        out.append(digits[value & 15])
    }
    out.toString()
}
