package cjregex

import std.collection.*

// Public HIR, separate from the matching engine's mutable Expr tree.
// Nodes are built only through smart constructors, which apply the same
// simplifications as the pinned regex-syntax Hir constructors.
public class HirUnsupportedError <: Exception {
    public init(message: String) {
        super(message)
    }
}

public class HirRange {
    public let start: Int64
    public let end: Int64
    public init(start: Int64, end: Int64) {
        this.start = if (start <= end) {
            start
        } else {
            end
        }
        this.end = if (start <= end) {
            end
        } else {
            start
        }
    }
}

public class HirClass {
    public let isBytes: Bool
    private let items: Array<HirRange>
    init(isBytes: Bool, items: Array<HirRange>) {
        this.isBytes = isBytes
        this.items = items.clone()
    }
    public func ranges(): Array<HirRange> {
        items.clone()
    }
    public func isEmpty(): Bool {
        items.isEmpty()
    }
    public func union(other: HirClass): Hir {
        hirClassCombine(this, other, 0)
    }
    public func intersect(other: HirClass): Hir {
        hirClassCombine(this, other, 1)
    }
    public func difference(other: HirClass): Hir {
        hirClassCombine(this, other, 2)
    }
    public func negate(): Hir {
        if (isBytes) {
            let kept = ArrayList<HirRange>()
            var cursor: Int64 = 0
            for (range in items) {
                if (cursor < range.start) {
                    kept.add(HirRange(cursor, range.start - 1))
                }
                cursor = range.end + 1
            }
            if (cursor <= 255) {
                kept.add(HirRange(cursor, 255))
            }
            return Hir.byteClass(kept.toArray())
        }
        let set = CharSet()
        for (range in items) {
            set.addRange(range.start, range.end)
        }
        return hirFromCharSet(false, set.negated())
    }
    public func caseFold(): Hir {
        let set = CharSet()
        for (range in items) {
            set.addRange(range.start, range.end)
        }
        if (isBytes) {
            set.caseFoldAscii()
        } else {
            set.caseFoldSimple()
        }
        return hirFromCharSet(isBytes, set)
    }
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

public enum HirLook {
    Start
    | End
    | StartLF
    | EndLF
    | StartCRLF
    | EndCRLF
    | WordAscii
    | WordAsciiNegate
    | WordUnicode
    | WordUnicodeNegate
    | WordStartAscii
    | WordEndAscii
    | WordStartUnicode
    | WordEndUnicode
    | WordStartHalfAscii
    | WordEndHalfAscii
    | WordStartHalfUnicode
    | WordEndHalfUnicode
}

public enum HirDot {
    AnyChar | AnyByte | AnyCharExceptLF | AnyCharExceptCRLF | AnyByteExceptLF | AnyByteExceptCRLF
}

public enum HirKind {
    Empty
    | Literal(Array<UInt8>)
    | Class(HirClass)
    | Look(HirLook)
    | Repetition(HirRepetition)
    | Capture(HirCapture)
    | Concat(Array<Hir>)
    | Alternation(Array<Hir>)
}

public class HirProperties {
    private let minimum: Option<UInt64>
    private let maximum: Option<UInt64>
    private let utf8: Bool
    private let explicitCaptures: Int64
    private let staticCaptures: Option<Int64>
    private let literal: Bool
    private let alternationLiteral: Bool
    private let looks: UInt64
    private let lookPrefix: UInt64
    private let lookPrefixAny: UInt64
    private let lookSuffix: UInt64
    private let lookSuffixAny: UInt64
    init(minimum: Option<UInt64>, maximum: Option<UInt64>, utf8: Bool, explicitCaptures: Int64,
        staticCaptures: Option<Int64>, literal: Bool, alternationLiteral: Bool, looks: UInt64, lookPrefix: UInt64,
        lookPrefixAny: UInt64, lookSuffix: UInt64, lookSuffixAny: UInt64) {
        this.minimum = minimum
        this.maximum = maximum
        this.utf8 = utf8
        this.explicitCaptures = explicitCaptures
        this.staticCaptures = staticCaptures
        this.literal = literal
        this.alternationLiteral = alternationLiteral
        this.looks = looks
        this.lookPrefix = lookPrefix
        this.lookPrefixAny = lookPrefixAny
        this.lookSuffix = lookSuffix
        this.lookSuffixAny = lookSuffixAny
    }
    public func minimumLen(): Option<UInt64> {
        minimum
    }
    public func maximumLen(): Option<UInt64> {
        maximum
    }
    public func isUtf8(): Bool {
        utf8
    }
    public func explicitCapturesLen(): Int64 {
        explicitCaptures
    }
    public func staticExplicitCapturesLen(): Option<Int64> {
        staticCaptures
    }
    public func isLiteral(): Bool {
        literal
    }
    public func isAlternationLiteral(): Bool {
        alternationLiteral
    }
    public func lookSet(): UInt64 {
        looks
    }
    public func lookSetPrefix(): UInt64 {
        lookPrefix
    }
    public func lookSetPrefixAny(): UInt64 {
        lookPrefixAny
    }
    public func lookSetSuffix(): UInt64 {
        lookSuffix
    }
    public func lookSetSuffixAny(): UInt64 {
        lookSuffixAny
    }
}

public class Hir {
    private let node: HirKind
    private let props: HirProperties
    private init(node: HirKind, minimum: Option<UInt64>, maximum: Option<UInt64>) {
        this.node = node
        props = hirProperties(node, minimum, maximum)
    }
    // Arrays returned through the public model cannot mutate stored nodes.
    public func kind(): HirKind {
        match (node) {
            case HirKind.Literal(bytes) => HirKind.Literal(bytes.clone())
            case HirKind.Concat(children) => HirKind.Concat(children.clone())
            case HirKind.Alternation(children) => HirKind.Alternation(children.clone())
            case other => other
        }
    }
    public func properties(): HirProperties {
        props
    }
    public func subs(): Array<Hir> {
        match (node) {
            case HirKind.Concat(children) => children.clone()
            case HirKind.Alternation(children) => children.clone()
            case HirKind.Repetition(rep) => [rep.sub]
            case HirKind.Capture(cap) => [cap.sub]
            case _ => Array<Hir>()
        }
    }
    public func visit(enter: (Hir) -> Unit): Unit {
        enter(this)
        match (node) {
            case HirKind.Concat(children) => for (child in children) {
                child.visit(enter)
            }
            case HirKind.Alternation(children) => for (child in children) {
                child.visit(enter)
            }
            case HirKind.Repetition(rep) => rep.sub.visit(enter)
            case HirKind.Capture(cap) => cap.sub.visit(enter)
            case _ => ()
        }
    }
    public func walk(enter: (Hir) -> Unit, leave: (Hir) -> Unit): Unit {
        enter(this)
        match (node) {
            case HirKind.Concat(children) => for (child in children) {
                child.walk(enter, leave)
            }
            case HirKind.Alternation(children) => for (child in children) {
                child.walk(enter, leave)
            }
            case HirKind.Repetition(rep) => rep.sub.walk(enter, leave)
            case HirKind.Capture(cap) => cap.sub.walk(enter, leave)
            case _ => ()
        }
        leave(this)
    }
    public func walkUntil(enter: (Hir) -> Bool, leave: (Hir) -> Bool): Bool {
        if (!enter(this)) {
            return false
        }
        let children = subs()
        for (child in children) {
            if (!child.walkUntil(enter, leave)) {
                return false
            }
        }
        leave(this)
        true
    }
    public func toPattern(): String {
        let out = StringBuilder()
        hirPrint(this, out)
        out.toString()
    }
    public static func empty(): Hir {
        Hir(HirKind.Empty, Some(UInt64(0)), Some(UInt64(0)))
    }
    public static func fail(): Hir {
        Hir(HirKind.Class(HirClass(true, Array<HirRange>())), None, None)
    }
    public static func literal(bytes: Array<UInt8>): Hir {
        if (bytes.isEmpty()) {
            return empty()
        }
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
            let limit: Int64 = if (bytes) {
                255
            } else {
                0x10FFFF
            }
            if (range.start < 0 || range.end > limit || (!bytes && ((range.start >= 0xD800 && range.start <= 0xDFFF) || (range
                .end >= 0xD800 && range.end <= 0xDFFF)))) {
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
        if (normalized.isEmpty()) {
            return fail()
        }
        if (normalized.size == 1 && normalized[0].start == normalized[0].end) {
            let value = normalized[0].start
            return literal(if (bytes) {
                [UInt8(value)]
            } else {
                String([Rune(UInt32(value))]).toArray()
            })
        }
        let minimum = if (bytes) {
            UInt64(1)
        } else {
            hirUtf8Width(normalized[0].start)
        }
        let maximum = if (bytes) {
            UInt64(1)
        } else {
            hirUtf8Width(normalized[normalized.size - 1].end)
        }
        return Hir(HirKind.Class(HirClass(bytes, normalized.toArray())), Some(minimum), Some(maximum))
    }
    public static func capture(index: UInt32, name: Option<String>, sub: Hir): Hir {
        Hir(HirKind.Capture(HirCapture(index, name, sub)), sub.props.minimumLen(), sub.props.maximumLen())
    }
    public static func repetition(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir): Hir {
        var minimum = min
        var maximum = max
        if (sub.props.maximumLen() == Some(UInt64(0))) {
            minimum = if (min > 1) {
                UInt32(1)
            } else {
                min
            }
            maximum = match (max) {
                case Some(n) => Some(if (n > 1) {
                    UInt32(1)
                } else {
                    n
                })
                case None => Some(UInt32(1))
            }
        }
        if (minimum == 0 && maximum == Some(UInt32(0))) {
            return empty()
        }
        if (minimum == 1 && maximum == Some(UInt32(1))) {
            return sub
        }
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
                case HirKind.Concat(subs) => for (sub in subs) {
                    flat.add(sub)
                }
                case _ => flat.add(child)
            }
        }
        let result = ArrayList<Hir>()
        var bytes = ArrayList<UInt8>()
        for (child in flat) {
            match (child.node) {
                case HirKind.Empty => ()
                case HirKind.Literal(lit) => for (b in lit) {
                    bytes.add(b)
                }
                case _ =>
                    if (!bytes.isEmpty()) {
                        result.add(literal(bytes.toArray()))
                        bytes = ArrayList<UInt8>()
                    }
                    result.add(child)
            }
        }
        if (!bytes.isEmpty()) {
            result.add(literal(bytes.toArray()))
        }
        if (result.isEmpty()) {
            return empty()
        }
        if (result.size == 1) {
            return result[0]
        }
        var minimum: Option<UInt64> = Some(UInt64(0))
        var maximum: Option<UInt64> = Some(UInt64(0))
        for (child in result) {
            minimum = hirAdd(minimum, child.props.minimumLen(), true)
            maximum = hirAdd(maximum, child.props.maximumLen(), false)
        }
        return Hir(HirKind.Concat(result.toArray()), minimum, maximum)
    }
    public static func look(look: HirLook): Hir {
        Hir(HirKind.Look(look), Some(UInt64(0)), Some(UInt64(0)))
    }
    public static func dot(dot: HirDot): Hir {
        match (dot) {
            case HirDot.AnyChar => unicodeClass([HirRange(0, 0x10FFFF)])
            case HirDot.AnyByte => byteClass([HirRange(0, 255)])
            case HirDot.AnyCharExceptLF => unicodeClass([HirRange(0, 9), HirRange(11, 0x10FFFF)])
            case HirDot.AnyCharExceptCRLF => unicodeClass([HirRange(0, 9), HirRange(11, 12), HirRange(14, 0x10FFFF)])
            case HirDot.AnyByteExceptLF => byteClass([HirRange(0, 9), HirRange(11, 255)])
            case HirDot.AnyByteExceptCRLF => byteClass([HirRange(0, 9), HirRange(11, 12), HirRange(14, 255)])
        }
    }
    public static func dotExcept(bytes: Bool, excluded: Int64): Hir {
        hirExcept(bytes, excluded)
    }
    public static func alternation(subs: Array<Hir>): Hir {
        let flat = ArrayList<Hir>()
        for (sub in subs) {
            match (sub.kind()) {
                case HirKind.Alternation(inner) => for (item in inner) {
                    flat.add(item)
                }
                case _ => flat.add(sub)
            }
        }
        if (flat.isEmpty()) {
            return fail()
        }
        if (flat.size == 1) {
            return flat[0]
        }
        let nodes = flat.toArray()
        match (hirSingletonChars(nodes)) {
            case Some(chars) => return unicodeClass(Array<HirRange>(chars.size, {i => HirRange(chars[i], chars[i])}))
            case None => ()
        }
        match (hirSingletonBytes(nodes)) {
            case Some(values) => return byteClass(Array<HirRange>(values.size, {i => HirRange(values[i], values[i])}))
            case None => ()
        }
        match (hirClassUnion(nodes, false)) {
            case Some(merged) => return merged
            case None => ()
        }
        match (hirClassUnion(nodes, true)) {
            case Some(merged) => return merged
            case None => ()
        }
        match (hirLiftPrefix(nodes)) {
            case Some(lifted) => return lifted
            case None => ()
        }
        var minimum: Option<UInt64> = None
        var maximum: Option<UInt64> = None
        var sawMin = false
        var sawMax = false
        var minPoison = false
        var maxPoison = false
        for (child in nodes) {
            if (!minPoison) {
                match (child.properties().minimumLen()) {
                    case Some(n) =>
                        if (!sawMin || match (minimum) {
                            case Some(m) => n < m;
                            case None => false
                        }) {
                            minimum = Some(n)
                            sawMin = true
                        }
                    case None =>
                        minimum = None
                        minPoison = true
                }
            }
            if (!maxPoison) {
                match (child.properties().maximumLen()) {
                    case Some(n) =>
                        if (!sawMax || match (maximum) {
                            case Some(m) => n > m;
                            case None => false
                        }) {
                            maximum = Some(n)
                            sawMax = true
                        }
                    case None =>
                        maximum = None
                        maxPoison = true
                }
            }
        }
        return Hir(HirKind.Alternation(nodes), minimum, maximum)
    }
    public static func parse(pattern: String): Hir {
        parse(pattern, true)
    }
    public static func parse(pattern: String, utf8: Bool): Hir {
        let options = PatternOptions()
        options.utf8 = utf8
        let parser = Parser(pattern, options)
        return hirFromExpr(parser.parse(), parser.captureNames.toArray())
    }
}

func hirUtf8Width(code: Int64): UInt64 {
    if (code <= 0x7F) {
        return 1
    }
    if (code <= 0x7FF) {
        return 2
    }
    if (code <= 0xFFFF) {
        return 3
    }
    return 4
}

func hirLimit(): UInt64 {
    (UInt64(0xFFFFFFFF) << 32) | UInt64(0xFFFFFFFF)
}

func hirMultiply(a: Option<UInt64>, b: Option<UInt64>, saturate: Bool): Option<UInt64> {
    match ((a, b)) {
        case (Some(x), Some(y)) =>
            if (y != 0 && x > hirLimit() / y) {
                return if (saturate) {
                    Some(hirLimit())
                } else {
                    None
                }
            }
            return Some(x * y)
        case _ => return None
    }
}

func hirAdd(a: Option<UInt64>, b: Option<UInt64>, saturate: Bool): Option<UInt64> {
    match ((a, b)) {
        case (Some(x), Some(y)) =>
            if (x > hirLimit() - y) {
                return if (saturate) {
                    Some(hirLimit())
                } else {
                    None
                }
            }
            return Some(x + y)
        case _ => return None
    }
}

func hirProperties(node: HirKind, minimum: Option<UInt64>, maximum: Option<UInt64>): HirProperties {
    match (node) {
        case HirKind.Empty => hirPropertyValue(minimum, maximum, true, 0, Some(0), false, false, 0, 0, 0, 0, 0)
        case HirKind.Literal(bytes) => hirPropertyValue(minimum, maximum, hirBytesAreUtf8(bytes), 0, Some(0), true, true,
            0, 0, 0, 0, 0)
        case HirKind.Class(klass) => hirPropertyValue(minimum, maximum, hirClassUtf8(klass), 0, Some(0), false, false, 0,
            0, 0, 0, 0)
        case HirKind.Look(look) =>
            let bit = hirLookBit(look)
            hirPropertyValue(minimum, maximum, true, 0, Some(0), false, false, bit, bit, bit, bit, bit)
        case HirKind.Repetition(rep) => hirRepetitionProperties(rep, minimum, maximum)
        case HirKind.Capture(cap) => hirCaptureProperties(cap, minimum, maximum)
        case HirKind.Concat(children) => hirConcatProperties(children, minimum, maximum)
        case HirKind.Alternation(children) => hirUnionProperties(children, minimum, maximum)
    }
}

func hirPropertyValue(minimum: Option<UInt64>, maximum: Option<UInt64>, utf8: Bool, explicitCaptures: Int64,
    staticCaptures: Option<Int64>, literal: Bool, alternationLiteral: Bool, looks: UInt64, lookPrefix: UInt64,
    lookPrefixAny: UInt64, lookSuffix: UInt64, lookSuffixAny: UInt64): HirProperties {
    HirProperties(minimum, maximum, utf8, explicitCaptures, staticCaptures, literal, alternationLiteral, looks,
        lookPrefix, lookPrefixAny, lookSuffix, lookSuffixAny)
}

func hirRepetitionProperties(rep: HirRepetition, minimum: Option<UInt64>, maximum: Option<UInt64>): HirProperties {
    let child = rep.sub.properties()
    var prefix: UInt64 = 0
    var suffix: UInt64 = 0
    if (rep.min > 0) {
        prefix = child.lookSetPrefix()
        suffix = child.lookSetSuffix()
    }
    var staticCaptures = child.staticExplicitCapturesLen()
    let positive = match (staticCaptures) {
        case Some(count) => count > 0
        case None => false
    }
    if (rep.min == 0 && positive) {
        staticCaptures = match (rep.max) {
            case Some(limit) =>
                if (limit == 0) {
                    Some(0)
                } else {
                    None<Int64>
                }
            case None => None<Int64>
        }
    }
    hirPropertyValue(minimum, maximum, child.isUtf8(), child.explicitCapturesLen(), staticCaptures, false, false,
        child.lookSet(), prefix, child.lookSetPrefixAny(), suffix, child.lookSetSuffixAny())
}

func hirCaptureProperties(cap: HirCapture, minimum: Option<UInt64>, maximum: Option<UInt64>): HirProperties {
    let child = cap.sub.properties()
    let staticCaptures = match (child.staticExplicitCapturesLen()) {
        case Some(count) => Some(hirCountAdd(count, 1))
        case None => None<Int64>
    }
    hirPropertyValue(minimum, maximum, child.isUtf8(), hirCountAdd(child.explicitCapturesLen(), 1), staticCaptures,
        false, false, child.lookSet(), child.lookSetPrefix(), child.lookSetPrefixAny(), child.lookSetSuffix(),
        child.lookSetSuffixAny())
}

func hirConcatProperties(children: Array<Hir>, minimum: Option<UInt64>, maximum: Option<UInt64>): HirProperties {
    var looks: UInt64 = 0
    var utf8 = true
    var explicit: Int64 = 0
    var staticCaptures = Some(0)
    var literal = true
    var alternationLiteral = true
    for (child in children) {
        let props = child.properties()
        looks = looks | props.lookSet()
        utf8 = utf8 && props.isUtf8()
        explicit = hirCountAdd(explicit, props.explicitCapturesLen())
        staticCaptures = hirCountAddOpt(staticCaptures, props.staticExplicitCapturesLen())
        literal = literal && props.isLiteral()
        alternationLiteral = alternationLiteral && props.isAlternationLiteral()
    }
    var prefix: UInt64 = 0
    var prefixAny: UInt64 = 0
    var index: Int64 = 0
    while (index < children.size) {
        let props = children[index].properties()
        prefix = prefix | props.lookSetPrefix()
        prefixAny = prefixAny | props.lookSetPrefixAny()
        let stop = match (props.maximumLen()) {
            case Some(length) => length > 0
            case None => true
        }
        if (stop) {
            break
        }
        index++
    }
    var suffix: UInt64 = 0
    var suffixAny: UInt64 = 0
    index = children.size
    while (index > 0) {
        index--
        let props = children[index].properties()
        suffix = suffix | props.lookSetSuffix()
        suffixAny = suffixAny | props.lookSetSuffixAny()
        let stop = match (props.maximumLen()) {
            case Some(length) => length > 0
            case None => true
        }
        if (stop) {
            break
        }
    }
    hirPropertyValue(minimum, maximum, utf8, explicit, staticCaptures, literal, alternationLiteral, looks, prefix,
        prefixAny, suffix, suffixAny)
}

func hirUnionProperties(children: Array<Hir>, minimum: Option<UInt64>, maximum: Option<UInt64>): HirProperties {
    let full: UInt64 = 0xFFFFFFFF
    var looks: UInt64 = 0
    var prefix = if (children.isEmpty()) {
        UInt64(0)
    } else {
        full
    }
    var suffix = prefix
    var prefixAny: UInt64 = 0
    var suffixAny: UInt64 = 0
    var utf8 = true
    var explicit: Int64 = 0
    var staticCaptures = if (children.isEmpty()) {
        Some(0)
    } else {
        children[0].properties().staticExplicitCapturesLen()
    }
    var alternationLiteral = true
    for (child in children) {
        let props = child.properties()
        looks = looks | props.lookSet()
        prefix = prefix & props.lookSetPrefix()
        suffix = suffix & props.lookSetSuffix()
        prefixAny = prefixAny | props.lookSetPrefixAny()
        suffixAny = suffixAny | props.lookSetSuffixAny()
        utf8 = utf8 && props.isUtf8()
        explicit = hirCountAdd(explicit, props.explicitCapturesLen())
        if (!hirSameCount(staticCaptures, props.staticExplicitCapturesLen())) {
            staticCaptures = None<Int64>
        }
        alternationLiteral = alternationLiteral && props.isLiteral()
    }
    hirPropertyValue(minimum, maximum, utf8, explicit, staticCaptures, false, alternationLiteral, looks, prefix,
        prefixAny, suffix, suffixAny)
}

func hirCountAdd(left: Int64, right: Int64): Int64 {
    let limit = Int64.Max
    if (left > limit - right) {
        return limit
    }
    left + right
}

func hirSameCount(left: Option<Int64>, right: Option<Int64>): Bool {
    match ((left, right)) {
        case (Some(a), Some(b)) => a == b
        case (None, None) => true
        case _ => false
    }
}

func hirCountAddOpt(left: Option<Int64>, right: Option<Int64>): Option<Int64> {
    match ((left, right)) {
        case (Some(a), Some(b)) => Some(hirCountAdd(a, b))
        case _ => None<Int64>
    }
}

func hirClassUtf8(klass: HirClass): Bool {
    if (!klass.isBytes) {
        return true
    }
    let ranges = klass.ranges()
    if (ranges.isEmpty()) {
        return true
    }
    ranges[ranges.size - 1].end <= 127
}

func hirBytesAreUtf8(bytes: Array<UInt8>): Bool {
    var index: Int64 = 0
    while (index < bytes.size) {
        let first = Int64(bytes[index])
        if (first < 0x80) {
            index++
            continue
        }
        let width = if ((first & 0xE0) == 0xC0) {
            2
        } else if ((first & 0xF0) == 0xE0) {
            3
        } else if ((first & 0xF8) == 0xF0) {
            4
        } else {
            return false
        }
        if (index + width > bytes.size) {
            return false
        }
        var value = first & if (width == 2) {
            0x1F
        } else if (width == 3) {
            0x0F
        } else {
            0x07
        }
        var next = index + 1
        while (next < index + width) {
            let cont = Int64(bytes[next])
            if ((cont & 0xC0) != 0x80) {
                return false
            }
            value = value * 64 + (cont & 0x3F)
            next++
        }
        let minimum = if (width == 2) {
            0x80
        } else if (width == 3) {
            0x800
        } else {
            0x10000
        }
        if (value < minimum || value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
            return false
        }
        index += width
    }
    true
}

func hirLookBit(look: HirLook): UInt64 {
    match (look) {
        case HirLook.Start => 0x1
        case HirLook.End => 0x2
        case HirLook.StartLF => 0x4
        case HirLook.EndLF => 0x8
        case HirLook.StartCRLF => 0x10
        case HirLook.EndCRLF => 0x20
        case HirLook.WordAscii => 0x40
        case HirLook.WordAsciiNegate => 0x80
        case HirLook.WordUnicode => 0x100
        case HirLook.WordUnicodeNegate => 0x200
        case HirLook.WordStartAscii => 0x400
        case HirLook.WordEndAscii => 0x800
        case HirLook.WordStartUnicode => 0x1000
        case HirLook.WordEndUnicode => 0x2000
        case HirLook.WordStartHalfAscii => 0x4000
        case HirLook.WordEndHalfAscii => 0x8000
        case HirLook.WordStartHalfUnicode => 0x10000
        case HirLook.WordEndHalfUnicode => 0x20000
    }
}

func hirFromExpr(expr: Expr, names: Array<String>): Hir {
    match (expr.kind) {
        case ExprKind.Empty => Hir.empty()
        case ExprKind.Literal => Hir.literal(if (expr.byteAtom) {
            [UInt8(UInt32(expr.ch))]
        } else {
            String([expr.ch]).toArray()
        })
        case ExprKind.CharacterClass =>
            let ranges = Array<HirRange>(expr.charset.rangeCount(), {
                i => HirRange(expr.charset.rangeLow(i), expr.charset.rangeHigh(i))
            })
            if (!expr.modeUnicode) {
                Hir.byteClass(ranges)
            } else {
                Hir.unicodeClass(ranges)
            }
        case ExprKind.Alternate => Hir.alternation(
            Array<Hir>(expr.children.size, {i => hirFromExpr(expr.children[i], names)}))
        case ExprKind.Concat => Hir.concat(Array<Hir>(expr.children.size, {i => hirFromExpr(expr.children[i], names)}))
        case ExprKind.Any => hirDotFromExpr(expr)
        case ExprKind.Begin | ExprKind.End => Hir.look(hirAnchorLook(expr))
        case ExprKind.WordBoundary => Hir.look(hirWordLook(expr))
        case ExprKind.Capture => Hir.capture(UInt32(expr.captureIndex), if (names[expr.captureIndex].isEmpty()) {
            None
        } else {
            Some(names[expr.captureIndex])
        }, hirFromExpr(expr.children[0], names))
        case ExprKind.Repeat => Hir.repetition(UInt32(expr.minimum), if (expr.maximum < 0) {
            None
        } else {
            Some(UInt32(expr.maximum))
        }, expr.greedy, hirFromExpr(expr.children[0], names))
    }
}

func hirFromCharSet(bytes: Bool, set: CharSet): Hir {
    let ranges = ArrayList<HirRange>()
    for (i in 0..set.rangeCount()) {
        let low = set.rangeLow(i)
        let high = set.rangeHigh(i)
        if (bytes && low > 255) {
            continue
        }
        let end = if (bytes && high > 255) {
            255
        } else {
            high
        }
        if (low <= end) {
            ranges.add(HirRange(low, end))
        }
    }
    if (bytes) {
        Hir.byteClass(ranges.toArray())
    } else {
        Hir.unicodeClass(ranges.toArray())
    }
}

func hirClassCombine(left: HirClass, right: HirClass, op: Int64): Hir {
    if (left.isBytes != right.isBytes) {
        throw Exception("cannot mix Unicode and byte classes")
    }
    let a = CharSet()
    let b = CharSet()
    for (range in left.ranges()) {
        a.addRange(range.start, range.end)
    }
    for (range in right.ranges()) {
        b.addRange(range.start, range.end)
    }
    let set = match (op) {
        case 1 => a.intersect(b)
        case 2 => a.difference(b)
        case _ =>
            a.unionWith(b)
            a
    }
    hirFromCharSet(left.isBytes, set)
}

func hirExcept(bytes: Bool, excluded: Int64): Hir {
    let ranges = ArrayList<HirRange>()
    let limit: Int64 = if (bytes) {
        255
    } else {
        0x10FFFF
    }
    if (excluded > 0) {
        ranges.add(HirRange(0, excluded - 1))
    }
    if (excluded < limit) {
        ranges.add(HirRange(excluded + 1, limit))
    }
    if (bytes) {
        Hir.byteClass(ranges.toArray())
    } else {
        Hir.unicodeClass(ranges.toArray())
    }
}

func hirDotFromExpr(expr: Expr): Hir {
    let bytes = expr.byteAtom
    match (expr.modeKind) {
        case 1 =>
            if (bytes) {
                Hir.dot(HirDot.AnyByte)
            } else {
                Hir.dot(HirDot.AnyChar)
            }
        case 2 =>
            if (bytes) {
                Hir.dot(HirDot.AnyByteExceptCRLF)
            } else {
                Hir.dot(HirDot.AnyCharExceptCRLF)
            }
        case _ =>
            let term = Int64(UInt32(expr.modeTerm))
            if (term == 10) {
                if (bytes) {
                    Hir.dot(HirDot.AnyByteExceptLF)
                } else {
                    Hir.dot(HirDot.AnyCharExceptLF)
                }
            } else {
                hirExcept(bytes, term)
            }
    }
}

func hirAnchorLook(expr: Expr): HirLook {
    match (expr.modeKind) {
        case 0 => HirLook.Start
        case 1 => HirLook.End
        case 2 => HirLook.StartLF
        case 3 => HirLook.EndLF
        case 4 => HirLook.StartCRLF
        case 5 => HirLook.EndCRLF
        case _ => throw HirUnsupportedError("public HIR cannot represent this expression")
    }
}

func hirWordLook(expr: Expr): HirLook {
    let unicode = expr.modeUnicode
    match (expr.modeKind) {
        case 7 =>
            if (unicode) {
                HirLook.WordStartUnicode
            } else {
                HirLook.WordStartAscii
            }
        case 8 =>
            if (unicode) {
                HirLook.WordEndUnicode
            } else {
                HirLook.WordEndAscii
            }
        case 9 =>
            if (unicode) {
                HirLook.WordStartHalfUnicode
            } else {
                HirLook.WordStartHalfAscii
            }
        case 10 =>
            if (unicode) {
                HirLook.WordEndHalfUnicode
            } else {
                HirLook.WordEndHalfAscii
            }
        case _ =>
            if (expr.modePositive) {
                if (unicode) {
                    HirLook.WordUnicode
                } else {
                    HirLook.WordAscii
                }
            } else {
                if (unicode) {
                    HirLook.WordUnicodeNegate
                } else {
                    HirLook.WordAsciiNegate
                }
            }
    }
}

func hirSameBound(left: Option<UInt32>, right: Option<UInt32>): Bool {
    match ((left, right)) {
        case (Some(a), Some(b)) => a == b
        case (None, None) => true
        case _ => false
    }
}

func hirSameName(left: Option<String>, right: Option<String>): Bool {
    match ((left, right)) {
        case (Some(a), Some(b)) => a == b
        case (None, None) => true
        case _ => false
    }
}

func hirBytesEqual(left: Array<UInt8>, right: Array<UInt8>): Bool {
    if (left.size != right.size) {
        return false
    }
    for (i in 0..left.size) {
        if (left[i] != right[i]) {
            return false
        }
    }
    true
}

func hirSame(left: Hir, right: Hir): Bool {
    match (left.kind()) {
        case HirKind.Empty => match (right.kind()) {
            case HirKind.Empty => true;
            case _ => false
        }
        case HirKind.Look(a) => match (right.kind()) {
            case HirKind.Look(b) => hirLookName(a) == hirLookName(b);
            case _ => false
        }
        case HirKind.Literal(a) => match (right.kind()) {
            case HirKind.Literal(b) => hirBytesEqual(a, b);
            case _ => false
        }
        case HirKind.Class(a) => match (right.kind()) {
            case HirKind.Class(b) =>
                if (a.isBytes != b.isBytes || a.ranges().size != b.ranges().size) {
                    return false
                }
                let leftRanges = a.ranges()
                let rightRanges = b.ranges()
                for (i in 0..leftRanges.size) {
                    if (leftRanges[i].start != rightRanges[i].start || leftRanges[i].end != rightRanges[i].end) {
                        return false
                    }
                }
                true
            case _ => false
        }
        case HirKind.Repetition(a) => match (right.kind()) {
            case HirKind.Repetition(b) => (if (a.min == b.min) {
                (if (hirSameBound(a.max, b.max)) {
                    (if (a.greedy == b.greedy) {
                        hirSame(a.sub, b.sub)
                    } else {
                        false
                    })
                } else {
                    false
                })
            } else {
                false
            })
            case _ => false
        }
        case HirKind.Capture(a) => match (right.kind()) {
            case HirKind.Capture(b) => (if (a.index == b.index) {
                (if (hirSameName(a.name, b.name)) {
                    hirSame(a.sub, b.sub)
                } else {
                    false
                })
            } else {
                false
            })
            case _ => false
        }
        case HirKind.Concat(a) => match (right.kind()) {
            case HirKind.Concat(b) => hirSameList(a, b)
            case _ => false
        }
        case HirKind.Alternation(a) => match (right.kind()) {
            case HirKind.Alternation(b) => hirSameList(a, b)
            case _ => false
        }
    }
}

func hirSameList(left: Array<Hir>, right: Array<Hir>): Bool {
    if (left.size != right.size) {
        return false
    }
    for (i in 0..left.size) {
        if (!hirSame(left[i], right[i])) {
            return false
        }
    }
    true
}

func hirDecodeText(bytes: Array<UInt8>): Option<Array<Int64>> {
    let chars = ArrayList<Int64>()
    var i: Int64 = 0
    while (i < bytes.size) {
        var width: Int64 = 1
        let first = Int64(bytes[i])
        if (first >= 0x80) {
            if (first < 0xC2) {
                return None
            } else if (first <= 0xDF) {
                width = 2
            } else if (first <= 0xEF) {
                width = 3
            } else if (first <= 0xF4) {
                width = 4
            } else {
                return None
            }
        }
        if (i + width > bytes.size) {
            return None
        }
        let origin = i
        let slice = Array<UInt8>(width, {j => bytes[origin + j]})
        match (hirOneScalar(slice)) {
            case Some(ch) => chars.add(ch)
            case None => return None
        }
        i += width
    }
    Some(chars.toArray())
}

func hirOneScalar(bytes: Array<UInt8>): Option<Int64> {
    if (bytes.isEmpty() || bytes.size > 4) {
        return None
    }
    let first = Int64(bytes[0])
    if (first < 0x80) {
        return if (bytes.size == 1) {
            Some(first)
        } else {
            None
        }
    }
    var need: Int64 = 0
    var value: Int64 = 0
    if (first >= 0xC2 && first <= 0xDF && bytes.size == 2) {
        need = 1
        value = first & 0x1F
    } else if (first >= 0xE0 && first <= 0xEF && bytes.size == 3) {
        need = 2
        value = first & 0x0F
    } else if (first >= 0xF0 && first <= 0xF4 && bytes.size == 4) {
        need = 3
        value = first & 0x07
    } else {
        return None
    }
    for (i in 1..bytes.size) {
        let next = Int64(bytes[i])
        if (next < 0x80 || next > 0xBF) {
            return None
        }
        value = (value << 6) | (next & 0x3F)
    }
    if (need == 2 && value < 0x800) {
        return None
    }
    if (need == 3 && value < 0x10000) {
        return None
    }
    if (value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
        return None
    }
    Some(value)
}

func hirSingletonChars(nodes: Array<Hir>): Option<Array<Int64>> {
    let chars = ArrayList<Int64>()
    for (node in nodes) {
        match (node.kind()) {
            case HirKind.Literal(bytes) => match (hirOneScalar(bytes)) {
                case Some(ch) => chars.add(ch)
                case None => return None
            }
            case _ => return None
        }
    }
    Some(chars.toArray())
}

func hirSingletonBytes(nodes: Array<Hir>): Option<Array<Int64>> {
    let values = ArrayList<Int64>()
    for (node in nodes) {
        match (node.kind()) {
            case HirKind.Literal(bytes) =>
                if (bytes.size != 1) {
                    return None
                }
                values.add(Int64(bytes[0]))
            case _ => return None
        }
    }
    Some(values.toArray())
}

func hirClassAscii(value: HirClass): Bool {
    for (range in value.ranges()) {
        if (range.end > 127) {
            return false
        }
    }
    true
}

func hirClassUnion(nodes: Array<Hir>, wantBytes: Bool): Option<Hir> {
    let ranges = ArrayList<HirRange>()
    for (node in nodes) {
        match (node.kind()) {
            case HirKind.Class(value) =>
                if (wantBytes) {
                    if (!value.isBytes && !hirClassAscii(value)) {
                        return None
                    }
                } else if (value.isBytes && !hirClassAscii(value)) {
                    return None
                }
                for (range in value.ranges()) {
                    ranges.add(range)
                }
            case _ => return None
        }
    }
    Some(if (wantBytes) {
        Hir.byteClass(ranges.toArray())
    } else {
        Hir.unicodeClass(ranges.toArray())
    })
}

func hirLiftPrefix(nodes: Array<Hir>): Option<Hir> {
    if (nodes.size <= 1) {
        return None
    }
    var prefix = Array<Hir>()
    match (nodes[0].kind()) {
        case HirKind.Concat(children) =>
            if (children.isEmpty()) {
                return None
            }
            prefix = children
        case _ => return None
    }
    for (i in 1..nodes.size) {
        match (nodes[i].kind()) {
            case HirKind.Concat(children) =>
                var count: Int64 = 0
                while ((if (count < prefix.size) {
                        (if (count < children.size) {
                            hirSame(prefix[count], children[count])
                        } else {
                            false
                        })
                    } else {
                        false
                    })) {
                    count++
                }
                if (count == 0) {
                    return None
                }
                let trimmed = ArrayList<Hir>()
                for (j in 0..count) {
                    trimmed.add(prefix[j])
                }
                prefix = trimmed.toArray()
            case _ => return None
        }
    }
    let width = prefix.size
    let suffixes = Array<Hir>(nodes.size, {
        i => match (nodes[i].kind()) {
            case HirKind.Concat(children) => Hir.concat(Array<Hir>(children.size - width, {j => children[width + j]}))
            case _ => Hir.empty()
        }
    })
    let parts = ArrayList<Hir>()
    for (part in prefix) {
        parts.add(part)
    }
    parts.add(Hir.alternation(suffixes))
    Some(Hir.concat(parts.toArray()))
}

func hirMeta(ch: Rune): Bool {
    match (ch) {
        case r'\\' | r'.' | r'+' | r'*' | r'?' | r'(' | r')' | r'|' | r'[' | r']' | r'{' | r'}' | r'^' | r'$' | r'#'
            | r'&' | r'-' | r'~' => true
        case _ => false
    }
}

func hirHex(value: Int64): String {
    let digits = "0123456789ABCDEF"
    let high = (value >> 4) & 15
    let low = value & 15
    "${digits[high..high + 1]}${digits[low..low + 1]}"
}

func hirPrintChar(out: StringBuilder, ch: Rune): Unit {
    if (hirMeta(ch)) {
        out.append("\\")
    }
    out.append(String([ch]))
}

func hirPrintByte(out: StringBuilder, value: Int64, inClass: Bool): Unit {
    if (value > 0x20 && value < 0x7F) {
        hirPrintChar(out, Rune(UInt32(value)))
    } else if (inClass) {
        out.append("\\x${hirHex(value)}")
    } else {
        out.append("(?-u:\\x${hirHex(value)})")
    }
}

func hirPrint(h: Hir, out: StringBuilder): Unit {
    match (h.kind()) {
        case HirKind.Empty => out.append("(?:)")
        case HirKind.Literal(bytes) =>
            let text = hirDecodeText(bytes)
            let count = match (text) {
                case Some(value) => value.size
                case None => bytes.size
            }
            if (count > 1) {
                out.append("(?:")
            }
            match (text) {
                case Some(chars) => for (ch in chars) {
                    hirPrintChar(out, Rune(UInt32(ch)))
                }
                case None => for (b in bytes) {
                    hirPrintByte(out, Int64(b), false)
                }
            }
            if (count > 1) {
                out.append(")")
            }
        case HirKind.Class(value) =>
            if (value.isEmpty()) {
                out.append("[a&&b]")
            } else if (value.isBytes) {
                out.append("(?-u:[")
                hirPrintRanges(out, value, true)
                out.append("])")
            } else {
                out.append("[")
                hirPrintRanges(out, value, false)
                out.append("]")
            }
        case HirKind.Look(look) => out.append(hirLookPattern(look))
        case HirKind.Repetition(rep) =>
            hirPrint(rep.sub, out)
            hirPrintRepeat(out, rep)
        case HirKind.Capture(cap) =>
            out.append("(")
            match (cap.name) {
                case Some(name) => out.append("?P<${name}>")
                case None => ()
            }
            hirPrint(cap.sub, out)
            out.append(")")
        case HirKind.Concat(children) =>
            out.append("(?:")
            for (child in children) {
                hirPrint(child, out)
            }
            out.append(")")
        case HirKind.Alternation(children) =>
            out.append("(?:")
            var first = true
            for (child in children) {
                if (!first) {
                    out.append("|")
                }
                first = false
                hirPrint(child, out)
            }
            out.append(")")
    }
}

func hirPrintRanges(out: StringBuilder, value: HirClass, bytes: Bool): Unit {
    for (range in value.ranges()) {
        if (range.start == range.end) {
            if (bytes) {
                hirPrintByte(out, range.start, true)
            } else {
                hirPrintChar(out, Rune(UInt32(range.start)))
            }
        } else if (range.start + 1 == range.end) {
            if (bytes) {
                hirPrintByte(out, range.start, true)
                hirPrintByte(out, range.end, true)
            } else {
                hirPrintChar(out, Rune(UInt32(range.start)))
                hirPrintChar(out, Rune(UInt32(range.end)))
            }
        } else {
            if (bytes) {
                hirPrintByte(out, range.start, true)
            } else {
                hirPrintChar(out, Rune(UInt32(range.start)))
            }
            out.append("-")
            if (bytes) {
                hirPrintByte(out, range.end, true)
            } else {
                hirPrintChar(out, Rune(UInt32(range.end)))
            }
        }
    }
}

func hirPrintRepeat(out: StringBuilder, rep: HirRepetition): Unit {
    let min = rep.min
    match (rep.max) {
        case Some(max) =>
            if (min == 0 && max == 1) {
                out.append("?")
            } else if (min == 1 && max == 1) {
                return
            } else if (min == max) {
                out.append("{${min}}")
                return
            } else {
                out.append("{${min},${max}}")
            }
        case None =>
            if (min == 0) {
                out.append("*")
            } else if (min == 1) {
                out.append("+")
            } else {
                out.append("{${min},}")
            }
    }
    if (!rep.greedy) {
        out.append("?")
    }
}

public func hirLookName(look: HirLook): String {
    match (look) {
        case HirLook.Start => "Start"
        case HirLook.End => "End"
        case HirLook.StartLF => "StartLF"
        case HirLook.EndLF => "EndLF"
        case HirLook.StartCRLF => "StartCRLF"
        case HirLook.EndCRLF => "EndCRLF"
        case HirLook.WordAscii => "WordAscii"
        case HirLook.WordAsciiNegate => "WordAsciiNegate"
        case HirLook.WordUnicode => "WordUnicode"
        case HirLook.WordUnicodeNegate => "WordUnicodeNegate"
        case HirLook.WordStartAscii => "WordStartAscii"
        case HirLook.WordEndAscii => "WordEndAscii"
        case HirLook.WordStartUnicode => "WordStartUnicode"
        case HirLook.WordEndUnicode => "WordEndUnicode"
        case HirLook.WordStartHalfAscii => "WordStartHalfAscii"
        case HirLook.WordEndHalfAscii => "WordEndHalfAscii"
        case HirLook.WordStartHalfUnicode => "WordStartHalfUnicode"
        case HirLook.WordEndHalfUnicode => "WordEndHalfUnicode"
    }
}

func hirLookPattern(look: HirLook): String {
    match (look) {
        case HirLook.Start => "\\A"
        case HirLook.End => "\\z"
        case HirLook.StartLF => "(?m:^)"
        case HirLook.EndLF => "(?m:$)"
        case HirLook.StartCRLF => "(?mR:^)"
        case HirLook.EndCRLF => "(?mR:$)"
        case HirLook.WordAscii => "(?-u:\\b)"
        case HirLook.WordAsciiNegate => "(?-u:\\B)"
        case HirLook.WordUnicode => "\\b"
        case HirLook.WordUnicodeNegate => "\\B"
        case HirLook.WordStartAscii => "(?-u:\\b{start})"
        case HirLook.WordEndAscii => "(?-u:\\b{end})"
        case HirLook.WordStartUnicode => "\\b{start}"
        case HirLook.WordEndUnicode => "\\b{end}"
        case HirLook.WordStartHalfAscii => "(?-u:\\b{start-half})"
        case HirLook.WordEndHalfAscii => "(?-u:\\b{end-half})"
        case HirLook.WordStartHalfUnicode => "\\b{start-half}"
        case HirLook.WordEndHalfUnicode => "\\b{end-half}"
    }
}
