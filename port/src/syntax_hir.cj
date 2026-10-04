package cjregex

import std.collection.*

// Public HIR slice, separate from the matching engine's mutable Expr tree.
// Look/Alternation, AST, printing and the complete Properties API are not yet
// exposed. The adapter rejects these nodes instead of silently dropping them.
public class HirUnsupportedError <: Exception {
    public init(message: String) { super(message) }
}

public class HirRange {
    public let start: Int64
    public let end: Int64
    public init(start: Int64, end: Int64) {
        this.start = if (start <= end) { start } else { end }
        this.end = if (start <= end) { end } else { start }
    }
}

public class HirClass {
    public let isBytes: Bool
    private let items: Array<HirRange>
    init(isBytes: Bool, items: Array<HirRange>) {
        this.isBytes = isBytes
        this.items = items.clone()
    }
    public func ranges(): Array<HirRange> { items.clone() }
}

public class HirRepetition {
    public let min: UInt32
    public let max: Option<UInt32>
    public let greedy: Bool
    public let sub: Hir
    init(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir) {
        this.min = min
        this.max = max
        this.greedy = greedy
        this.sub = sub
    }
}

public class HirCapture {
    public let index: UInt32
    public let name: Option<String>
    public let sub: Hir
    init(index: UInt32, name: Option<String>, sub: Hir) {
        this.index = index
        this.name = name
        this.sub = sub
    }
}

public enum HirKind {
    Empty | Literal(Array<UInt8>) | Class(HirClass) | Repetition(HirRepetition) | Capture(HirCapture) | Concat(Array<Hir>)
}

public class HirProperties {
    private let minimum: Option<UInt64>
    private let maximum: Option<UInt64>
    init(minimum: Option<UInt64>, maximum: Option<UInt64>) {
        this.minimum = minimum
        this.maximum = maximum
    }
    public func minimumLen(): Option<UInt64> { minimum }
    public func maximumLen(): Option<UInt64> { maximum }
}

public class Hir {
    private let node: HirKind
    private let props: HirProperties
    private init(node: HirKind, minimum: Option<UInt64>, maximum: Option<UInt64>) {
        this.node = node
        props = HirProperties(minimum, maximum)
    }
    // Arrays returned through the public model cannot mutate stored nodes.
    public func kind(): HirKind {
        match (node) {
            case HirKind.Literal(bytes) => HirKind.Literal(bytes.clone())
            case HirKind.Concat(children) => HirKind.Concat(children.clone())
            case other => other
        }
    }
    public func properties(): HirProperties { props }
    public func subs(): Array<Hir> {
        match (node) {
            case HirKind.Concat(children) => children.clone()
            case HirKind.Repetition(rep) => [rep.sub]
            case HirKind.Capture(cap) => [cap.sub]
            case _ => Array<Hir>()
        }
    }
    public static func empty(): Hir {
        Hir(HirKind.Empty, Some(UInt64(0)), Some(UInt64(0)))
    }
    public static func fail(): Hir {
        Hir(HirKind.Class(HirClass(true, Array<HirRange>())), None, None)
    }
    public static func literal(bytes: Array<UInt8>): Hir {
        if (bytes.isEmpty()) { return empty() }
        let size = Some(UInt64(bytes.size))
        return Hir(HirKind.Literal(bytes.clone()), size, size)
    }
    public static func unicodeClass(ranges: Array<HirRange>): Hir {
        makeClass(false, ranges)
    }
    public static func byteClass(ranges: Array<HirRange>): Hir {
        makeClass(true, ranges)
    }
    private static func makeClass(bytes: Bool, ranges: Array<HirRange>): Hir {
        let set = CharSet()
        for (range in ranges) {
            let limit: Int64 = if (bytes) { 255 } else { 0x10FFFF }
            if (range.start < 0 || range.end > limit || (!bytes &&
                ((range.start >= 0xD800 && range.start <= 0xDFFF) ||
                 (range.end >= 0xD800 && range.end <= 0xDFFF)))) {
                throw Exception("invalid HIR character range")
            }
            set.addRange(range.start, range.end)
        }
        let normalized = ArrayList<HirRange>()
        for (i in 0..set.rangeCount()) {
            let low = set.rangeLow(i)
            let high = set.rangeHigh(i)
            // Scalar ranges can span the surrogate hole, as Rust char ranges do.
            if (!bytes && !normalized.isEmpty() && normalized[normalized.size - 1].end == 0xD7FF && low == 0xE000) {
                let previous = normalized[normalized.size - 1]
                normalized[normalized.size - 1] = HirRange(previous.start, high)
            } else {
                normalized.add(HirRange(low, high))
            }
        }
        if (normalized.isEmpty()) { return fail() }
        if (normalized.size == 1 && normalized[0].start == normalized[0].end) {
            let value = normalized[0].start
            return literal(if (bytes) { [UInt8(value)] } else { String([Rune(UInt32(value))]).toArray() })
        }
        let minimum = if (bytes) { UInt64(1) } else { hirUtf8Width(normalized[0].start) }
        let maximum = if (bytes) { UInt64(1) } else { hirUtf8Width(normalized[normalized.size - 1].end) }
        return Hir(HirKind.Class(HirClass(bytes, normalized.toArray())), Some(minimum), Some(maximum))
    }
    public static func capture(index: UInt32, name: Option<String>, sub: Hir): Hir {
        Hir(HirKind.Capture(HirCapture(index, name, sub)), sub.props.minimumLen(), sub.props.maximumLen())
    }
    public static func repetition(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir): Hir {
        var minimum = min
        var maximum = max
        if (sub.props.maximumLen() == Some(UInt64(0))) {
            minimum = if (min > 1) { UInt32(1) } else { min }
            maximum = match (max) {
                case Some(n) => Some(if (n > 1) { UInt32(1) } else { n })
                case None => Some(UInt32(1))
            }
        }
        if (minimum == 0 && maximum == Some(UInt32(0))) { return empty() }
        if (minimum == 1 && maximum == Some(UInt32(1))) { return sub }
        let low = hirMultiply(sub.props.minimumLen(), Some(UInt64(minimum)), true)
        let high = hirMultiply(sub.props.maximumLen(), match (maximum) {
            case Some(n) => Some(UInt64(n))
            case None => None
        }, false)
        return Hir(HirKind.Repetition(HirRepetition(minimum, maximum, greedy, sub)), low, high)
    }
    public static func concat(children: Array<Hir>): Hir {
        let flat = ArrayList<Hir>()
        for (child in children) {
            match (child.node) {
                case HirKind.Concat(subs) => for (sub in subs) { flat.add(sub) }
                case _ => flat.add(child)
            }
        }
        let result = ArrayList<Hir>()
        var bytes = ArrayList<UInt8>()
        for (child in flat) {
            match (child.node) {
                case HirKind.Empty => ()
                case HirKind.Literal(lit) => for (b in lit) { bytes.add(b) }
                case _ =>
                    if (!bytes.isEmpty()) {
                        result.add(literal(bytes.toArray()))
                        bytes = ArrayList<UInt8>()
                    }
                    result.add(child)
            }
        }
        if (!bytes.isEmpty()) { result.add(literal(bytes.toArray())) }
        if (result.isEmpty()) { return empty() }
        if (result.size == 1) { return result[0] }
        var minimum: Option<UInt64> = Some(UInt64(0))
        var maximum: Option<UInt64> = Some(UInt64(0))
        for (child in result) {
            minimum = hirAdd(minimum, child.props.minimumLen(), true)
            maximum = hirAdd(maximum, child.props.maximumLen(), false)
        }
        return Hir(HirKind.Concat(result.toArray()), minimum, maximum)
    }
    public static func parse(pattern: String): Hir { parse(pattern, true) }
    public static func parse(pattern: String, utf8: Bool): Hir {
        let options = PatternOptions()
        options.utf8 = utf8
        let parser = Parser(pattern, options)
        return hirFromExpr(parser.parse(), parser.captureNames.toArray())
    }
}

func hirUtf8Width(code: Int64): UInt64 {
    if (code <= 0x7F) { return 1 }
    if (code <= 0x7FF) { return 2 }
    if (code <= 0xFFFF) { return 3 }
    return 4
}
func hirLimit(): UInt64 { (UInt64(0xFFFFFFFF) << 32) | UInt64(0xFFFFFFFF) }
func hirMultiply(a: Option<UInt64>, b: Option<UInt64>, saturate: Bool): Option<UInt64> {
    match ((a, b)) {
        case (Some(x), Some(y)) =>
            if (y != 0 && x > hirLimit() / y) { return if (saturate) { Some(hirLimit()) } else { None } }
            return Some(x * y)
        case _ => return None
    }
}
func hirAdd(a: Option<UInt64>, b: Option<UInt64>, saturate: Bool): Option<UInt64> {
    match ((a, b)) {
        case (Some(x), Some(y)) =>
            if (x > hirLimit() - y) { return if (saturate) { Some(hirLimit()) } else { None } }
            return Some(x + y)
        case _ => return None
    }
}
func hirFromExpr(expr: Expr, names: Array<String>): Hir {
    match (expr.kind) {
        case ExprKind.Empty => Hir.empty()
        case ExprKind.Literal => Hir.literal(if (expr.byteAtom) {
            [UInt8(UInt32(expr.ch))]
        } else { String([expr.ch]).toArray() })
        case ExprKind.CharacterClass =>
            let ranges = Array<HirRange>(expr.charset.rangeCount(), {i =>
                HirRange(expr.charset.rangeLow(i), expr.charset.rangeHigh(i))})
            if (!expr.modeUnicode) { Hir.byteClass(ranges) } else { Hir.unicodeClass(ranges) }
        case ExprKind.Alternate =>
            if (expr.children.size == 1) { hirFromExpr(expr.children[0], names) }
            else { throw HirUnsupportedError("public HIR slice does not yet support alternation") }
        case ExprKind.Concat => Hir.concat(Array<Hir>(expr.children.size, {i => hirFromExpr(expr.children[i], names)}))
        case ExprKind.Capture => Hir.capture(UInt32(expr.captureIndex),
            if (names[expr.captureIndex].isEmpty()) { None } else { Some(names[expr.captureIndex]) },
            hirFromExpr(expr.children[0], names))
        case ExprKind.Repeat => Hir.repetition(UInt32(expr.minimum),
            if (expr.maximum < 0) { None } else { Some(UInt32(expr.maximum)) },
            expr.greedy, hirFromExpr(expr.children[0], names))
        case _ => throw HirUnsupportedError("public HIR slice does not yet support alternation, dot or look assertions")
    }
}
