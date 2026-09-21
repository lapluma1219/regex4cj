package cjregex

import std.collection.*

// Adapted from regex-automata's Thompson compiler and ordered PikeVM.
// See docs/milestone-1.md for exact upstream symbols and representation changes.
enum Op {
    Literal(Rune) | CharacterClass(CharSet) | Any(Bool) | Begin(Bool) | End(Bool) | WordBoundary(Bool) | Split | Save(
        Int64) | Accept
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
            case ExprKind.WordBoundary => return add(Op.WordBoundary(expr.ch == r'b'), next, -1)
            case ExprKind.Empty => return next
            case ExprKind.Literal => return add(Op.Literal(expr.ch), next, -1)
            case ExprKind.CharacterClass => return add(Op.CharacterClass(expr.charset), next, -1)
            case ExprKind.Any => return add(Op.Any(expr.dotAll), next, -1)
            case ExprKind.Begin => return add(Op.Begin(expr.multiline), next, -1)
            case ExprKind.End => return add(Op.End(expr.multiline), next, -1)
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
}

public class Regex {
    private let states: Array<State>
    private let startState: Int64
    private let wordCharacters: CharSet
    private let groupNames: Array<String>
    public init(pattern: String) {
        let parser = Parser(pattern)
        let tree = parser.parse()
        normalizeWidth(tree)
        let compiler = Compiler()
        let accept = compiler.add(Op.Accept, -1, -1)
        startState = compiler.compile(tree, accept)
        states = compiler.states.toArray()
        // HIR removes groups underneath {0}. Keep surviving original indices,
        // including holes, but omit trailing removed groups and their names.
        let live = Array<Bool>(parser.captureNames.size, repeat: false)
        live[0] = true
        var last: Int64 = 0
        var hasBoundary = false
        for (state in states) {
            match (state.op) {
                case Op.WordBoundary(_) => hasBoundary = true
                case Op.Save(slot) =>
                    let index = slot / 2
                    live[index] = true
                    if (index > last) {
                        last = index
                    }
                case _ => ()
            }
        }
        wordCharacters = if (hasBoundary) {
            unicodeClass(r'w')
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
                case Op.WordBoundary(positive) =>
                    let before = pos > 0 && wordCharacters.contains(input.chars[pos - 1])
                    let after = pos < input.chars.size && wordCharacters.contains(input.chars[pos])
                    if ((before != after) == positive) {
                        stack.add(Thread(s.first, start, frame.slots))
                    }
                case Op.Begin(multiline) =>
                    if (pos == 0 || (multiline && input.chars[pos - 1] == r'\n')) {
                        stack.add(Thread(s.first, start, frame.slots))
                    }
                case Op.End(multiline) =>
                    if (pos == input.chars.size || (multiline && input.chars[pos] == r'\n')) {
                        stack.add(Thread(s.first, start, frame.slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
    private func search(input: Input, from: Int64, capture: Bool): Option<SearchMatch> {
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
                        best = Some(SearchMatch(thread.start, pos, thread.slots))
                        found = true
                        break
                    case Op.Literal(c) => consume = pos < input.chars.size && input.chars[pos] == c
                    case Op.CharacterClass(set) => consume = pos < input.chars.size && set.contains(input.chars[pos])
                    case Op.Any(dotAll) => consume = pos < input.chars.size && (dotAll || input.chars[pos] != r'\n')
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
        match (search(input, 0, false)) {
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
    // Eager collection for this milestone, not yet Rust's lazy find_iter API.
    public func findAll(text: String): Array<RegexMatch> {
        let input = Input(text)
        let result = ArrayList<RegexMatch>()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        while (cursor <= input.chars.size) {
            match (search(input, cursor, false)) {
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
        return Captures(groups, groupNames)
    }
    public func captures(text: String): Option<Captures> {
        checkCaptureWorkspace()
        let input = Input(text)
        match (search(input, 0, true)) {
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
            match (search(input, cursor, true)) {
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
            match (search(input, cursor, capture)) {
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
            match (search(input, cursor, false)) {
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
