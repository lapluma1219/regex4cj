package regex4cj

import std.collection.*

// Prefix and suffix literal sequences from regex-syntax Extractor defaults:
// class limit 10, repeat limit 10, literal length 100, total 250.
public class LiteralPiece {
    public let exact: Bool
    public let bytes: Array<UInt8>
    public init(exact: Bool, bytes: Array<UInt8>) {
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
    public static func infinite(): LiteralSeq {
        LiteralSeq(false, Array<LiteralPiece>())
    }
    public static func of(pieces: Array<LiteralPiece>): LiteralSeq {
        LiteralSeq(true, pieces)
    }
    public func isEmpty(): Bool {
        finite && pieces.size == 0
    }
    public func isExact(): Bool {
        if (!finite) {
            return false
        }
        for (piece in pieces) {
            if (!piece.exact) {
                return false
            }
        }
        true
    }
    public func isInexact(): Bool {
        if (!finite) {
            return true
        }
        for (piece in pieces) {
            if (piece.exact) {
                return false
            }
        }
        true
    }
    public func literalCount(): Option<Int64> {
        if (finite) {
            Some(pieces.size)
        } else {
            None
        }
    }
    public func minLiteralLen(): Option<Int64> {
        if (!finite || pieces.size == 0) {
            return None
        }
        var least = pieces[0].bytes.size
        for (piece in pieces) {
            if (piece.bytes.size < least) {
                least = piece.bytes.size
            }
        }
        Some(least)
    }
    public func maxUnionLen(other: LiteralSeq): Option<Int64> {
        match (literalCount()) {
            case None => None
            case Some(left) => match (other.literalCount()) {
                case None => None
                case Some(right) => Some(saturatingAdd(left, right))
            }
        }
    }
    public func maxCrossLen(other: LiteralSeq): Option<Int64> {
        match (literalCount()) {
            case None => None
            case Some(left) => match (other.literalCount()) {
                case None => None
                case Some(right) => Some(saturatingMul(left, right))
            }
        }
    }
    public func maxLiteralLen(): Option<Int64> {
        if (!finite || pieces.size == 0) {
            return None
        }
        var most = pieces[0].bytes.size
        for (piece in pieces) {
            if (piece.bytes.size > most) {
                most = piece.bytes.size
            }
        }
        Some(most)
    }
    public func crossForward(other: LiteralSeq): LiteralSeq {
        let left = hold(this)
        let right = hold(other)
        left.crossForward(right)
        left.publish()
    }
    public func crossReverse(other: LiteralSeq): LiteralSeq {
        let left = hold(this)
        let right = hold(other)
        left.crossReverse(right)
        left.publish()
    }
    public func union(other: LiteralSeq): LiteralSeq {
        let left = hold(this)
        let right = hold(other)
        left.unionWith(right)
        left.publish()
    }
    public func unionIntoEmpty(other: LiteralSeq): LiteralSeq {
        let left = hold(this)
        let right = hold(other)
        left.unionIntoEmpty(right)
        left.publish()
    }
    public func keepFirst(len: Int64): LiteralSeq {
        if (len < 0) {
            throw Exception("literal byte limit must be nonnegative")
        }
        let seq = hold(this)
        seq.keepFirst(len)
        seq.publish()
    }
    public func keepLast(len: Int64): LiteralSeq {
        if (len < 0) {
            throw Exception("literal byte limit must be nonnegative")
        }
        let seq = hold(this)
        seq.keepLast(len)
        seq.publish()
    }
    public func minimize(): LiteralSeq {
        let seq = hold(this)
        seq.minimize(false)
        seq.publish()
    }
    public func optimizePrefix(): LiteralSeq {
        let seq = hold(this)
        seq.optimize(true)
        seq.publish()
    }
    public func optimizeSuffix(): LiteralSeq {
        let seq = hold(this)
        seq.optimize(false)
        seq.publish()
    }
    public func reversed(): LiteralSeq {
        let seq = hold(this)
        seq.reverseLiterals()
        seq.publish()
    }
    public func sorted(): LiteralSeq {
        let seq = hold(this)
        seq.sortLiterals()
        seq.publish()
    }
    public func makeInexact(): LiteralSeq {
        let seq = hold(this)
        seq.makeInexact()
        seq.publish()
    }
    public func deduped(): LiteralSeq {
        let seq = hold(this)
        seq.dedup()
        seq.publish()
    }
    public func commonPrefix(): Option<Array<UInt8>> {
        hold(this).commonPrefix()
    }
    public func commonSuffix(): Option<Array<UInt8>> {
        hold(this).commonSuffix()
    }
}

public class LiteralLimits {
    public let classLimit: Int64
    public let repeatLimit: Int64
    public let literalLen: Int64
    public let totalLimit: Int64
    public init() {
        this(10, 10, 100, 250)
    }
    public init(classLimit: Int64, repeatLimit: Int64, literalLen: Int64, totalLimit: Int64) {
        if (classLimit < 0 || repeatLimit < 0 || literalLen < 0 || totalLimit < 0) {
            throw Exception("literal limit must be nonnegative")
        }
        this.classLimit = classLimit
        this.repeatLimit = repeatLimit
        this.literalLen = literalLen
        this.totalLimit = totalLimit
    }
}

public func extractLiterals(hir: Hir): LiteralSeq {
    extractLiterals(hir, false, LiteralLimits())
}

public func extractLiterals(hir: Hir, suffix: Bool): LiteralSeq {
    extractLiterals(hir, suffix, LiteralLimits())
}

public func extractLiterals(hir: Hir, suffix: Bool, limits: LiteralLimits): LiteralSeq {
    let engine = LiteralEngine(suffix, limits)
    engine.extract(hir).publish()
}

public func formatLiterals(hir: Hir, suffix: Bool): String {
    formatLiterals(hir, suffix, LiteralLimits())
}

public func formatLiterals(hir: Hir, suffix: Bool, limits: LiteralLimits): String {
    formatLiteralSeq(extractLiterals(hir, suffix, limits))
}

func saturatingAdd(left: Int64, right: Int64): Int64 {
    if (right > 0 && left > 9223372036854775807 - right) {
        return 9223372036854775807
    }
    left + right
}

func saturatingMul(left: Int64, right: Int64): Int64 {
    if (left == 0 || right == 0) {
        return 0
    }
    if (left > 9223372036854775807 / right) {
        return 9223372036854775807
    }
    left * right
}

public func formatLiteralSeq(seq: LiteralSeq): String {
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

public func formatCommon(bytes: Option<Array<UInt8>>): String {
    match (bytes) {
        case None => "none"
        case Some(value) => "bytes\t${hexBytes(value)}"
    }
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
    func maxCross(other: HeldSeq, limit: Int64): Option<Int64> {
        match (length()) {
            case None => None
            case Some(left) => match (other.length()) {
                case None => None
                case Some(right) =>
                    if (left != 0 && limit != 0 && right > limit / left) {
                        Some(limit + 1)
                    } else if (left != 0 && limit == 0 && right > 0) {
                        Some(1)
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
    func unionIntoEmpty(other: HeldSeq): Unit {
        if (!finite) {
            other.drain()
            return
        }
        var emptyAt: Int64 = -1
        var index: Int64 = 0
        while (index < items.size) {
            if (items[index].bytes.size == 0) {
                emptyAt = index
                break
            }
            index++
        }
        if (emptyAt < 0) {
            other.drain()
            return
        }
        if (!other.finite) {
            other.drain()
            makeInfinite()
            return
        }
        let incoming = other.steal()
        var cursor: Int64 = 0
        while (cursor < items.size) {
            if (items[cursor].bytes.size == 0) {
                items.remove(at: cursor)
            } else {
                cursor++
            }
        }
        let rebuilt = ArrayList<HeldLiteral>()
        var kept: Int64 = 0
        while (kept < emptyAt && kept < items.size) {
            rebuilt.add(items[kept])
            kept++
        }
        for (item in incoming) {
            rebuilt.add(item)
        }
        while (kept < items.size) {
            rebuilt.add(items[kept])
            kept++
        }
        drain()
        for (item in rebuilt) {
            items.add(item)
        }
        dedup()
    }
    func minimize(keepExact: Bool): Unit {
        if (!finite) {
            return
        }
        let kept = ArrayList<HeldLiteral>()
        for (item in items) {
            var blocked = false
            var earlier: Int64 = 0
            while (earlier < kept.size) {
                if (bytePrefix(kept[earlier].bytes, item.bytes)) {
                    if (!keepExact) {
                        kept[earlier].exact = false
                    }
                    blocked = true
                    break
                }
                earlier++
            }
            if (!blocked) {
                kept.add(item.copy())
            }
        }
        drain()
        for (item in kept) {
            items.add(item)
        }
    }
    func allExact(): Bool {
        if (!finite) {
            return false
        }
        for (item in items) {
            if (!item.exact) {
                return false
            }
        }
        true
    }
    func poisonous(): Bool {
        if (!finite) {
            return false
        }
        for (item in items) {
            if (item.bytes.size == 0 || (item.bytes.size == 1 && rankOf(item.bytes[0]) >= 250)) {
                return true
            }
        }
        false
    }
    func shortLiterals(): Bool {
        match (minLen()) {
            case None => true
            case Some(len) => len <= 2
        }
    }
    func countTooBig(): Bool {
        match (length()) {
            case None => true
            case Some(len) => len > 64
        }
    }
    func adopt(saved: HeldSeq): Unit {
        finite = saved.finite
        drain()
        if (finite) {
            for (item in saved.items) {
                items.add(item.copy())
            }
        }
    }
    func optimize(prefix: Bool): Unit {
        if (!finite) {
            return
        }
        let originalCount = items.size
        match (minLen()) {
            case Some(len) =>
                if (len == 0) {
                    makeInfinite()
                    return
                }
            case None => ()
        }
        if (prefix) {
            minimize(true)
        }
        let fix = if (prefix) {
            commonPrefix()
        } else {
            commonSuffix()
        }
        match (fix) {
            case Some(bytes) =>
                if (prefix && originalCount > 1 && bytes.size >= 1 && bytes.size <= 3 && rankOf(bytes[0]) < 200) {
                    keepFirst(1)
                    dedup()
                    return
                }
                let fast = allExact() && items.size <= 16
                if (bytes.size > 4 || (bytes.size > 1 && !fast)) {
                    if (prefix) {
                        keepFirst(bytes.size)
                    } else {
                        keepLast(bytes.size)
                    }
                    dedup()
                }
            case None => ()
        }
        var haveExact = false
        var exactCopy = HeldSeq()
        if (allExact()) {
            exactCopy = copy()
            haveExact = true
        }
        let keeps = [5, 4, 3, 2, 1]
        let limits = [10, 10, 64, 64, 10]
        var attempt: Int64 = 0
        while (attempt < keeps.size) {
            if (!finite || items.size <= limits[attempt]) {
                break
            }
            if (prefix) {
                keepFirst(keeps[attempt])
                minimize(true)
            } else {
                keepLast(keeps[attempt])
            }
            attempt++
        }
        if (if (finite) {
            poisonous()
        } else {
            false
        }) {
            makeInfinite()
        }
        if (if (!haveExact) {
            false
        } else if (!finite) {
            true
        } else if (shortLiterals()) {
            true
        } else {
            countTooBig()
        }) {
            adopt(exactCopy)
        }
    }
    func reverseLiterals(): Unit {
        if (!finite) {
            return
        }
        for (item in items) {
            reverseBytes(item.bytes)
        }
    }
    func sortLiterals(): Unit {
        if (!finite || items.size < 2) {
            return
        }
        let ordered = Array<HeldLiteral>(items.size, {i => items[i]})
        var index: Int64 = 1
        while (index < ordered.size) {
            var cursor = index
            while (cursor > 0 && literalBefore(ordered[cursor], ordered[cursor - 1])) {
                let swap = ordered[cursor]
                ordered[cursor] = ordered[cursor - 1]
                ordered[cursor - 1] = swap
                cursor--
            }
            index++
        }
        drain()
        for (item in ordered) {
            items.add(item)
        }
    }
    func commonPrefix(): Option<Array<UInt8>> {
        if (!finite || items.size == 0) {
            return None
        }
        var len = items[0].bytes.size
        var index: Int64 = 1
        while (index < items.size) {
            let other = items[index].bytes
            var matched: Int64 = 0
            let limit = if (other.size < len) {
                other.size
            } else {
                len
            }
            while (matched < limit && other[matched] == items[0].bytes[matched]) {
                matched++
            }
            len = matched
            if (len == 0) {
                return Some(Array<UInt8>())
            }
            index++
        }
        let base = items[0].bytes
        Some(Array<UInt8>(len, {i => base[i]}))
    }
    func commonSuffix(): Option<Array<UInt8>> {
        if (!finite || items.size == 0) {
            return None
        }
        var len = items[0].bytes.size
        var index: Int64 = 1
        while (index < items.size) {
            let other = items[index].bytes
            let base = items[0].bytes
            var matched: Int64 = 0
            let limit = if (other.size < len) {
                other.size
            } else {
                len
            }
            while (matched < limit && other[other.size - 1 - matched] == base[base.size - 1 - matched]) {
                matched++
            }
            len = matched
            if (len == 0) {
                return Some(Array<UInt8>())
            }
            index++
        }
        let base = items[0].bytes
        let start = base.size - len
        Some(Array<UInt8>(len, {i => base[start + i]}))
    }
}

func hold(seq: LiteralSeq): HeldSeq {
    let out = HeldSeq()
    if (!seq.finite) {
        out.makeInfinite()
        return out
    }
    for (piece in seq.pieces) {
        let item = HeldLiteral(piece.exact)
        for (byte in piece.bytes) {
            item.bytes.add(byte)
        }
        out.items.add(item)
    }
    out
}

func bytePrefix(prefix: ArrayList<UInt8>, full: ArrayList<UInt8>): Bool {
    if (prefix.size > full.size) {
        return false
    }
    var index: Int64 = 0
    while (index < prefix.size) {
        if (prefix[index] != full[index]) {
            return false
        }
        index++
    }
    true
}

func reverseBytes(bytes: ArrayList<UInt8>): Unit {
    let copy = Array<UInt8>(bytes.size, {i => bytes[i]})
    while (bytes.size > 0) {
        bytes.remove(at: bytes.size - 1)
    }
    var index = copy.size - 1
    while (index >= 0) {
        bytes.add(copy[index])
        index--
    }
}

func literalBefore(left: HeldLiteral, right: HeldLiteral): Bool {
    let limit = if (left.bytes.size < right.bytes.size) {
        left.bytes.size
    } else {
        right.bytes.size
    }
    var index: Int64 = 0
    while (index < limit) {
        let a = Int64(left.bytes[index])
        let b = Int64(right.bytes[index])
        if (a < b) {
            return true
        }
        if (a > b) {
            return false
        }
        index++
    }
    if (left.bytes.size != right.bytes.size) {
        return left.bytes.size < right.bytes.size
    }
    if (left.exact == right.exact) {
        return false
    }
    !left.exact
}

let byteRank: Array<Int64> = [
    55,
    52,
    51,
    50,
    49,
    48,
    47,
    46,
    45,
    103,
    242,
    66,
    67,
    229,
    44,
    43,
    42,
    41,
    40,
    39,
    38,
    37,
    36,
    35,
    34,
    33,
    56,
    32,
    31,
    30,
    29,
    28,
    255,
    148,
    164,
    149,
    136,
    160,
    155,
    173,
    221,
    222,
    134,
    122,
    232,
    202,
    215,
    224,
    208,
    220,
    204,
    187,
    183,
    179,
    177,
    168,
    178,
    200,
    226,
    195,
    154,
    184,
    174,
    126,
    120,
    191,
    157,
    194,
    170,
    189,
    162,
    161,
    150,
    193,
    142,
    137,
    171,
    176,
    185,
    167,
    186,
    112,
    175,
    192,
    188,
    156,
    140,
    143,
    123,
    133,
    128,
    147,
    138,
    146,
    114,
    223,
    151,
    249,
    216,
    238,
    236,
    253,
    227,
    218,
    230,
    247,
    135,
    180,
    241,
    233,
    246,
    244,
    231,
    139,
    245,
    243,
    251,
    235,
    201,
    196,
    240,
    214,
    152,
    182,
    205,
    181,
    127,
    27,
    212,
    211,
    210,
    213,
    228,
    197,
    169,
    159,
    131,
    172,
    105,
    80,
    98,
    96,
    97,
    81,
    207,
    145,
    116,
    115,
    144,
    130,
    153,
    121,
    107,
    132,
    109,
    110,
    124,
    111,
    82,
    108,
    118,
    141,
    113,
    129,
    119,
    125,
    165,
    117,
    92,
    106,
    83,
    72,
    99,
    93,
    65,
    79,
    166,
    237,
    163,
    199,
    190,
    225,
    209,
    203,
    198,
    217,
    219,
    206,
    234,
    248,
    158,
    239,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255
]

func rankOf(byte: UInt8): Int64 {
    byteRank[Int64(byte)]
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
    let limitClass: Int64
    let limitRepeat: Int64
    let limitLiteral: Int64
    let limitTotal: Int64
    init(suffix: Bool) {
        this(suffix, LiteralLimits())
    }
    init(suffix: Bool, limits: LiteralLimits) {
        this.suffix = suffix
        limitClass = limits.classLimit
        limitRepeat = limits.repeatLimit
        limitLiteral = limits.literalLen
        limitTotal = limits.totalLimit
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
        match (seq.maxCross(other, limitTotal)) {
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
