package cjregex

import std.collection.*

// Adapted from regex-automata's Thompson compiler and ordered PikeVM.
// See docs/milestone-1.md for exact upstream symbols and representation changes.
enum Op {
    Literal(Rune) | CharacterClass(CharSet) | Any(AtomMode) | Look(AtomMode) | Split | Save(Int64) | Accept
}

class State {
    let op: Op
    var first: Int64
    var second: Int64
    init(op: Op, first: Int64, second: Int64) {
        this.op = op
        this.first = first
        this.second = second
    }
}

class Compiler {
    let states = ArrayList<State>()
    private var work: Int64 = 0
    func add(op: Op, first: Int64, second: Int64): Int64 {
        if (states.size >= 16384) {
            throw Exception("NFA exceeds 16384 states")
        }
        states.add(State(op, first, second))
        return states.size - 1
    }
    func split(first: Int64, second: Int64, greedy: Bool): Int64 {
        if (greedy) {
            return add(Op.Split, first, second)
        }
        return add(Op.Split, second, first)
    }
    // Continuation-based construction replaces Rust's fragment patch lists.
    func mode(expr: Expr): AtomMode {
        AtomMode(expr.modeKind, expr.modeTerm, expr.modeUnicode, expr.modePositive)
    }
    func compile(expr: Expr, next: Int64): Int64 {
        work++
        if (work > 65536) {
            throw Exception("regex compilation exceeds 65536 work units")
        }
        match (expr.kind) {
            case ExprKind.Capture =>
                let end = add(Op.Save(expr.captureIndex * 2 + 1), next, -1)
                let body = compile(expr.children[0], end)
                return add(Op.Save(expr.captureIndex * 2), body, -1)
            case ExprKind.WordBoundary | ExprKind.Begin | ExprKind.End => return add(Op.Look(mode(expr)), next, -1)
            case ExprKind.Empty => return next
            case ExprKind.Literal => return add(Op.Literal(expr.ch), next, -1)
            case ExprKind.CharacterClass => return add(Op.CharacterClass(expr.charset), next, -1)
            case ExprKind.Any => return add(Op.Any(mode(expr)), next, -1)
            case ExprKind.Concat =>
                var start = next
                var i = expr.children.size
                while (i > 0) {
                    i--;
                    start = compile(expr.children[i], start)
                }
                return start
            case ExprKind.Alternate =>
                var i = expr.children.size - 1
                var start = compile(expr.children[i], next)
                while (i > 0) {
                    i--
                    start = split(compile(expr.children[i], next), start, true)
                }
                return start
            case ExprKind.Repeat =>
                var start = next
                if (expr.maximum < 0) {
                    let loop = add(Op.Split, -1, -1)
                    let body = compile(expr.children[0], loop)
                    states[loop].first = if (expr.greedy) {
                        body
                    } else {
                        next
                    }
                    states[loop].second = if (expr.greedy) {
                        next
                    } else {
                        body
                    }
                    // c_at_least uses (x+)? for a nullable x*. Use uniformly.
                    if (expr.minimum == 0) {
                        return split(body, next, expr.greedy)
                    }
                    start = body
                    var i: Int64 = 1
                    while (i < expr.minimum) {
                        start = compile(expr.children[0], start)
                        i++
                    }
                    return start
                }
                // c_bounded: each optional branch exits directly to the final
                // continuation, instead of entering all later optional branches.
                var optional = expr.maximum - expr.minimum
                while (optional > 0) {
                    start = split(compile(expr.children[0], start), next, expr.greedy)
                    optional--
                }
                var required = expr.minimum
                while (required > 0) {
                    start = compile(expr.children[0], start)
                    required--
                }
                return start
        }
    }
}

// Slot arrays are immutable after publication: Save clones before modifying.
// This is simpler than upstream PikeVM's mutable slots plus restore frames.
class Thread {
    let state: Int64
    let start: Int64
    let slots: Array<Int64>
    init(state: Int64, start: Int64, slots: Array<Int64>) {
        this.state = state
        this.start = start
        this.slots = slots
    }
}

class SearchMatch {
    let start: Int64
    let end: Int64
    let slots: Array<Int64>
    init(start: Int64, end: Int64, slots: Array<Int64>) {
        this.start = start
        this.end = end
        this.slots = slots
    }
}

// Input scalar positions map to UTF-8 offsets once per public operation.
class Input {
    let chars = ArrayList<Rune>()
    let offsets = ArrayList<Int64>()
    init(text: String) {
        var offset: Int64 = 0
        offsets.add(offset)
        for (c in text.runes()) {
            chars.add(c)
            let code = UInt32(c)
            offset += if (code < 0x80) {
                1
            } else if (code < 0x800) {
                2
            } else if (code < 0x10000) {
                3
            } else {
                4
            }
            offsets.add(offset)
        }
    }
    func boundary(byteOffset: Int64): Int64 {
        let limit = offsets[offsets.size - 1]
        if (byteOffset < 0 || byteOffset > limit) {
            throw Exception("search start is outside the haystack")
        }
        var lo: Int64 = 0
        var hi = offsets.size
        while (lo < hi) {
            let mid = (lo + hi) / 2
            if (offsets[mid] < byteOffset) {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        if (lo >= offsets.size || offsets[lo] != byteOffset) {
            throw Exception("search start is not a char boundary")
        }
        return lo
    }
}

func staticExplicit(expr: Expr): Option<Int64> {
    match (expr.kind) {
        case ExprKind.Capture => match (staticExplicit(expr.children[0])) {
            case Some(count) => return Some(count + 1)
            case None => return None
        }
        case ExprKind.Concat =>
            var sum: Int64 = 0
            for (child in expr.children) {
                match (staticExplicit(child)) {
                    case Some(count) => sum += count
                    case None => return None
                }
            }
            return Some(sum)
        case ExprKind.Alternate =>
            if (expr.children.size == 0) {
                return Some(0)
            }
            var expected: Int64 = -1
            for (child in expr.children) {
                match (staticExplicit(child)) {
                    case None => return None
                    case Some(count) =>
                        if (expected < 0) {
                            expected = count
                        } else if (count != expected) {
                            return None
                        }
                }
            }
            return Some(expected)
        case ExprKind.Repeat => match (staticExplicit(expr.children[0])) {
            case None => return None
            case Some(count) =>
                if (expr.minimum == 0 && count > 0) {
                    return if (expr.maximum == 0) {
                        Some(0)
                    } else {
                        None
                    }
                }
                return Some(count)
        }
        case _ => return Some(0)
    }
}

public class RegexMatch {
    public let start: Int64
    public let end: Int64
    public let text: String
    init(start: Int64, end: Int64, text: String) {
        this.start = start
        this.end = end
        this.text = text
    }
    public func isEmpty(): Bool {
        start == end
    }
    public func len(): Int64 {
        end - start
    }
    public func asStr(): String {
        text
    }
}

public class Regex {
    private let source: String
    private let states: Array<State>
    private let startState: Int64
    private let unicodeWords: CharSet
    private let asciiWords: CharSet
    private let groupNames: Array<String>
    private let staticLen: Int64
    public init(pattern: String) {
        this(pattern, PatternOptions())
    }
    init(pattern: String, options: PatternOptions) {
        source = pattern
        let parser = Parser(pattern, options)
        let tree = parser.parse()
        normalizeWidth(tree)
        staticLen = match (staticExplicit(tree)) {
            case Some(count) => count + 1
            case None => -1
        }
        let compiler = Compiler()
        let accept = compiler.add(Op.Accept, -1, -1)
        startState = compiler.compile(tree, accept)
        states = compiler.states.toArray()
        // HIR removes groups underneath {0}. Keep surviving original indices,
        // including holes, but omit trailing removed groups and their names.
        let live = Array<Bool>(parser.captureNames.size, repeat: false)
        live[0] = true
        var last: Int64 = 0
        var needUnicode = false
        var needAscii = false
        for (state in states) {
            match (state.op) {
                case Op.Look(mode) =>
                    if (mode.kind >= 6) {
                        if (mode.unicode) {
                            needUnicode = true
                        } else {
                            needAscii = true
                        }
                    }
                case Op.Save(slot) =>
                    let index = slot / 2
                    live[index] = true
                    if (index > last) {
                        last = index
                    }
                case _ => ()
            }
        }
        unicodeWords = if (needUnicode) {
            unicodeClass(r'w')
        } else {
            CharSet()
        }
        asciiWords = if (needAscii) {
            match (asciiClass("word")) {
                case Some(set) => set
                case None => throw Exception("missing ASCII word class")
            }
        } else {
            CharSet()
        }
        groupNames = Array<String>(last + 1, {
            i => if (live[i]) {
                parser.captureNames[i]
            } else {
                ""
            }
        })
    }
    public func asStr(): String {
        source
    }
    public func staticCapturesLen(): Option<Int64> {
        if (staticLen < 0) {
            None
        } else {
            Some(staticLen)
        }
    }
    // Iterative ordered closure. The first path to a state wins, including slots.
    private func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, start: Int64, slots: Array<Int64>,
        pos: Int64, input: Input): Unit {
        let stack = ArrayList<Thread>()
        stack.add(Thread(state, start, slots))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            let id = frame.state
            if (seen[id]) {
                continue
            }
            seen[id] = true
            let s = states[id]
            match (s.op) {
                case Op.Split =>
                    stack.add(Thread(s.second, start, frame.slots))
                    stack.add(Thread(s.first, start, frame.slots))
                case Op.Save(slot) =>
                    if (frame.slots.size == 0) {
                        stack.add(Thread(s.first, start, frame.slots))
                    } else {
                        let updated = frame.slots.clone()
                        updated[slot] = pos
                        stack.add(Thread(s.first, start, updated))
                    }
                case Op.Look(mode) =>
                    if (passesLook(mode, pos, input.chars, unicodeWords, asciiWords)) {
                        stack.add(Thread(s.first, start, frame.slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
    private func search(input: Input, from: Int64, capture: Bool, earliest: Bool): Option<SearchMatch> {
        var current = ArrayList<Thread>()
        var seen = Array<Bool>(states.size, repeat: false)
        var best: Option<SearchMatch> = None
        var found = false
        var pos = from
        let slots = Array<Int64>(if (capture) {
            groupNames.size * 2
        } else {
            0
        }, repeat: -1)
        while (pos <= input.chars.size) {
            if (!found) {
                closure(current, seen, startState, pos, slots, pos, input)
            }
            let next = ArrayList<Thread>()
            let nextSeen = Array<Bool>(states.size, repeat: false)
            for (thread in current) {
                let s = states[thread.state]
                var consume = false
                match (s.op) {
                    case Op.Accept =>
                        let hit = SearchMatch(thread.start, pos, thread.slots)
                        if (earliest) {
                            return Some(hit)
                        }
                        best = Some(hit)
                        found = true
                        break
                    case Op.Literal(c) => consume = pos < input.chars.size && input.chars[pos] == c
                    case Op.CharacterClass(set) => consume = pos < input.chars.size && set.contains(input.chars[pos])
                    case Op.Any(mode) => consume = pos < input.chars.size && passesDot(mode, input.chars[pos])
                    case _ => ()
                }
                if (consume) {
                    closure(next, nextSeen, s.first, thread.start, thread.slots, pos + 1, input)
                }
            }
            if (found && next.isEmpty()) {
                return best
            }
            current = next
            seen = nextSeen
            pos++
        }
        return best
    }
    public func find(text: String): Option<RegexMatch> {
        let input = Input(text)
        match (search(input, 0, false, false)) {
            case Some(hit) =>
                let start = hit.start
                let end = hit.end
                let a = input.offsets[start]
                let b = input.offsets[end]
                return Some(RegexMatch(a, b, text[a..b]))
            case None => return None
        }
    }
    public func isMatch(text: String): Bool {
        match (find(text)) {
            case Some(_) => true;
            case None => false
        }
    }
    private func matched(text: String, input: Input, hit: SearchMatch): RegexMatch {
        let a = input.offsets[hit.start]
        let b = input.offsets[hit.end]
        RegexMatch(a, b, text[a..b])
    }
    public func findAt(text: String, start: Int64): Option<RegexMatch> {
        let input = Input(text)
        let from = input.boundary(start)
        match (search(input, from, false, false)) {
            case Some(hit) => return Some(matched(text, input, hit))
            case None => return None
        }
    }
    public func isMatchAt(text: String, start: Int64): Bool {
        match (findAt(text, start)) {
            case Some(_) => true
            case None => false
        }
    }
    public func shortestMatch(text: String): Option<Int64> {
        shortestMatchAt(text, 0)
    }
    public func shortestMatchAt(text: String, start: Int64): Option<Int64> {
        let input = Input(text)
        let from = input.boundary(start)
        match (search(input, from, false, true)) {
            case Some(hit) => Some(input.offsets[hit.end])
            case None => None
        }
    }
    public func capturesAt(text: String, start: Int64): Option<Captures> {
        let input = Input(text)
        let from = input.boundary(start)
        checkCaptureWorkspace()
        match (search(input, from, true, false)) {
            case Some(hit) => Some(captureResult(text, input, hit))
            case None => None
        }
    }
    public func findIter(text: String): MatchIter {
        let input = Input(text)
        let cursor = [0]
        let previousEnd = [-1]
        MatchIter(
            {
                =>
                    while (cursor[0] <= input.chars.size) {
                        match (search(input, cursor[0], false, false)) {
                            case None => return None
                            case Some(hit) =>
                                if (hit.start == hit.end && hit.end == previousEnd[0]) {
                                    cursor[0] = hit.end + 1
                                    continue
                                }
                                previousEnd[0] = hit.end
                                cursor[0] = hit.end
                                return Some(matched(text, input, hit))
                        }
                    }
                    return None
            }
        )
    }
    public func capturesIter(text: String): CaptureIter {
        checkCaptureWorkspace()
        let input = Input(text)
        let cursor = [0]
        let previousEnd = [-1]
        CaptureIter(
            {
                =>
                    while (cursor[0] <= input.chars.size) {
                        match (search(input, cursor[0], true, false)) {
                            case None => return None
                            case Some(hit) =>
                                if (hit.start == hit.end && hit.end == previousEnd[0]) {
                                    cursor[0] = hit.end + 1
                                    continue
                                }
                                previousEnd[0] = hit.end
                                cursor[0] = hit.end
                                return Some(captureResult(text, input, hit))
                        }
                    }
                    return None
            }
        )
    }
    public func splitIter(text: String): SplitIter {
        let input = Input(text)
        let cursor = [0]
        let previousEnd = [-1]
        let lastByte = [0]
        let done = [0]
        SplitIter(
            {
                =>
                    if (done[0] == 2) {
                        return None
                    }
                    while (done[0] == 0 && cursor[0] <= input.chars.size) {
                        match (search(input, cursor[0], false, false)) {
                            case None =>
                                done[0] = 1
                                break
                            case Some(hit) =>
                                if (hit.start == hit.end && hit.end == previousEnd[0]) {
                                    cursor[0] = hit.end + 1
                                    continue
                                }
                                let part = text[lastByte[0]..input.offsets[hit.start]]
                                lastByte[0] = input.offsets[hit.end]
                                previousEnd[0] = hit.end
                                cursor[0] = hit.end
                                return Some(part)
                        }
                    }
                    if (done[0] == 1) {
                        done[0] = 2
                        return Some(text[lastByte[0]..text.size])
                    }
                    return None
            }
        )
    }
    public func captureLocations(): CaptureLocations {
        CaptureLocations(groupNames.size)
    }
    public func capturesRead(locations: CaptureLocations, text: String): Option<RegexMatch> {
        capturesReadAt(locations, text, 0)
    }
    public func capturesReadAt(locations: CaptureLocations, text: String, start: Int64): Option<RegexMatch> {
        if (locations.size != groupNames.size) {
            throw Exception("capture locations were not created by this regex")
        }
        let input = Input(text)
        let from = input.boundary(start)
        checkCaptureWorkspace()
        match (search(input, from, true, false)) {
            case None => return None
            case Some(hit) =>
                locations.write(0, input.offsets[hit.start], input.offsets[hit.end])
                for (i in 1..groupNames.size) {
                    let a = hit.slots[i * 2]
                    let b = hit.slots[i * 2 + 1]
                    if (a >= 0 && b >= 0) {
                        locations.write(i, input.offsets[a], input.offsets[b])
                    } else {
                        locations.clear(i)
                    }
                }
                return Some(matched(text, input, hit))
        }
    }
    public func findAll(text: String): Array<RegexMatch> {
        let input = Input(text)
        let result = ArrayList<RegexMatch>()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        while (cursor <= input.chars.size) {
            match (search(input, cursor, false, false)) {
                case None => break
                case Some(hit) =>
                    let start = hit.start
                    let end = hit.end
                    if (start == end && end == previousEnd) {
                        cursor = end + 1
                        continue
                    }
                    let a = input.offsets[start]
                    let b = input.offsets[end]
                    result.add(RegexMatch(a, b, text[a..b]))
                    previousEnd = end
                    cursor = end
            }
        }
        return result.toArray()
    }
    public func capturesLen(): Int64 {
        groupNames.size
    }
    public func captureNames(): Array<Option<String>> {
        Array<Option<String>>(groupNames.size, {
            i => if (groupNames[i] == "") {
                None
            } else {
                Some(groupNames[i])
            }
        })
    }
    private func checkCaptureWorkspace(): Unit {
        if (states.size * groupNames.size * 2 > 1048576) {
            throw Exception("capture workspace exceeds 1048576 state-slot units")
        }
    }
    private func captureResult(text: String, input: Input, hit: SearchMatch): Captures {
        let groups = Array<Option<RegexMatch>>(groupNames.size, repeat: None)
        let start = input.offsets[hit.start]
        let end = input.offsets[hit.end]
        groups[0] = Some(RegexMatch(start, end, text[start..end]))
        for (i in 1..groupNames.size) {
            let a = hit.slots[i * 2]
            let b = hit.slots[i * 2 + 1]
            if (a >= 0 && b >= 0) {
                let left = input.offsets[a]
                let right = input.offsets[b]
                groups[i] = Some(RegexMatch(left, right, text[left..right]))
            }
        }
        return Captures(groups, groupNames, staticLen)
    }
    public func captures(text: String): Option<Captures> {
        checkCaptureWorkspace()
        let input = Input(text)
        match (search(input, 0, true, false)) {
            case Some(hit) => return Some(captureResult(text, input, hit))
            case None => return None
        }
    }
    public func capturesAll(text: String): Array<Captures> {
        checkCaptureWorkspace()
        let input = Input(text)
        let result = ArrayList<Captures>()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        while (cursor <= input.chars.size) {
            match (search(input, cursor, true, false)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    result.add(captureResult(text, input, hit))
                    previousEnd = hit.end
                    cursor = hit.end
            }
        }
        return result.toArray()
    }
    public func replace(text: String, replacement: String): String {
        replaceN(text, 1, replacement)
    }
    public func replaceAll(text: String, replacement: String): String {
        replaceN(text, 0, replacement)
    }
    // A zero limit means unlimited replacements, as in Rust replacen.
    public func replaceN(text: String, limit: Int64, replacement: String): String {
        var expansion = false
        for (c in replacement.runes()) {
            if (c == r'$') {
                expansion = true
                break
            }
        }
        if (!expansion) {
            return replaceLiteral(text, limit, replacement)
        }
        return replaceWith(text, limit, {caps => caps.expand(replacement)})
    }
    public func replaceLiteral(text: String, limit: Int64, replacement: String): String {
        replaceImpl(text, limit, false, {_, _ => replacement})
    }
    public func replaceWith(text: String, limit: Int64, replacer: (Captures) -> String): String {
        replaceImpl(text, limit, true, {input, hit => replacer(captureResult(text, input, hit))})
    }
    private func replaceImpl(text: String, limit: Int64, capture: Bool, render: (Input, SearchMatch) -> String): String {
        if (limit < 0) {
            throw Exception("replacement limit must be nonnegative")
        }
        if (capture) {
            checkCaptureWorkspace()
        }
        let input = Input(text)
        let out = StringBuilder()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        var lastByte: Int64 = 0
        var count: Int64 = 0
        while (cursor <= input.chars.size && (limit == 0 || count < limit)) {
            match (search(input, cursor, capture, false)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    out.append(text[lastByte..input.offsets[hit.start]])
                    out.append(render(input, hit))
                    lastByte = input.offsets[hit.end]
                    previousEnd = hit.end
                    cursor = hit.end
                    count++
            }
        }
        out.append(text[lastByte..text.size])
        return out.toString()
    }
    public func split(text: String): Array<String> {
        splitImpl(text, 0, false)
    }
    // Unlike replaceN, splitN(0) returns zero fields and splitN(1) the input.
    public func splitN(text: String, limit: Int64): Array<String> {
        if (limit < 0) {
            throw Exception("split limit must be nonnegative")
        }
        splitImpl(text, limit, true)
    }
    private func splitImpl(text: String, limit: Int64, bounded: Bool): Array<String> {
        let result = ArrayList<String>()
        if (bounded && limit == 0) {
            return result.toArray()
        }
        if (bounded && limit == 1) {
            result.add(text);
            return result.toArray()
        }
        let input = Input(text)
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        var lastByte: Int64 = 0
        while (cursor <= input.chars.size && (!bounded || result.size < limit - 1)) {
            match (search(input, cursor, false, false)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    result.add(text[lastByte..input.offsets[hit.start]])
                    lastByte = input.offsets[hit.end]
                    previousEnd = hit.end
                    cursor = hit.end
            }
        }
        result.add(text[lastByte..text.size])
        return result.toArray()
    }
}

public class MatchIter {
    private let pull: () -> Option<RegexMatch>
    public init(pull: () -> Option<RegexMatch>) {
        this.pull = pull
    }
    public func next(): Option<RegexMatch> {
        pull()
    }
}

public class CaptureIter {
    private let pull: () -> Option<Captures>
    public init(pull: () -> Option<Captures>) {
        this.pull = pull
    }
    public func next(): Option<Captures> {
        pull()
    }
}

public class SplitIter {
    private let pull: () -> Option<String>
    public init(pull: () -> Option<String>) {
        this.pull = pull
    }
    public func next(): Option<String> {
        pull()
    }
}
