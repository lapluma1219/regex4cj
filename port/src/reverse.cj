package cjregex

import std.collection.*

// Reverse Thompson search. Concatenation and UTF-8 byte sequences run backwards.
// The reported offset is the start of the match, matching a reverse DFA search.
// Captures are omitted, matching WhichCaptures::None. This is not a reversed string.
public class ReverseNfa {
    let states: Array<State>
    let startState: Int64
    let anchored: Bool
    let unicodeWords: CharSet
    let asciiWords: CharSet
    public init(pattern: String) {
        let options = PatternOptions()
        let parser = Parser(pattern, options)
        let tree = parser.parse()
        ensureWithinSizeLimit([tree], options.sizeLimit, false)
        let compiler = ReverseCompiler()
        let accept = compiler.add(Op.Accept, -1, -1)
        let start = compiler.compile(tree, accept)
        states = compiler.states.toArray()
        startState = start
        anchored = allAnchored([tree], true)
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
    }
    public func search(text: String): Option<Int64> {
        let bytes = text.toArray()
        let limit = bytes.size
        var pos = limit
        var current = ArrayList<Thread>()
        var best = -1
        var found = false
        var reading = true
        while (reading) {
            if (!found && (!anchored || pos == limit)) {
                let seen = Array<Bool>(states.size, repeat: false)
                closure(current, seen, startState, pos, bytes)
            }
            let next = ArrayList<Thread>()
            let nextSeen = Array<Bool>(states.size, repeat: false)
            var halt = false
            for (thread in current) {
                if (halt) {
                    break
                }
                let state = states[thread.state]
                match (state.op) {
                    case Op.Accept =>
                        best = pos
                        found = true
                        halt = true
                    case Op.Literal(_) =>
                        if (byteMatches(state, bytes, pos)) {
                            closure(next, nextSeen, state.first, pos - 1, bytes)
                        }
                    case Op.CharacterClass(_) =>
                        if (byteMatches(state, bytes, pos)) {
                            closure(next, nextSeen, state.first, pos - 1, bytes)
                        }
                    case _ => ()
                }
            }
            if (found && next.size == 0) {
                return Some(best)
            }
            if (pos == 0) {
                reading = false
            } else {
                current = next
                pos--
            }
        }
        if (best >= 0) {
            Some(best)
        } else {
            None
        }
    }
    func byteMatches(state: State, bytes: Array<UInt8>, pos: Int64): Bool {
        if (pos <= 0) {
            return false
        }
        let byte = bytes[pos - 1]
        match (state.op) {
            case Op.Literal(c) => Int64(byte) == Int64(UInt32(c))
            case Op.CharacterClass(set) => set.contains(Rune(UInt32(byte)))
            case _ => false
        }
    }
    func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, pos: Int64, bytes: Array<UInt8>): Unit {
        let stack = ArrayList<Thread>()
        let slots = Array<Int64>()
        stack.add(Thread(state, pos, slots))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            let id = frame.state
            if (seen[id]) {
                continue
            }
            seen[id] = true
            let current = states[id]
            match (current.op) {
                case Op.Split =>
                    stack.add(Thread(current.second, pos, slots))
                    stack.add(Thread(current.first, pos, slots))
                case Op.Look(mode) =>
                    if (passesLookBytes(mode, pos, bytes, unicodeWords, asciiWords)) {
                        stack.add(Thread(current.first, pos, slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
}

class ReverseCompiler {
    let states = ArrayList<State>()
    func add(op: Op, first: Int64, second: Int64): Int64 {
        states.add(State(op, first, second))
        return states.size - 1
    }
    func split(first: Int64, second: Int64, greedy: Bool): Int64 {
        if (greedy) {
            return add(Op.Split, first, second)
        }
        return add(Op.Split, second, first)
    }
    func compile(expr: Expr, next: Int64): Int64 {
        match (expr.kind) {
            case ExprKind.Capture => compile(expr.children[0], next)
            case ExprKind.WordBoundary | ExprKind.Begin | ExprKind.End => add(
                Op.Look(AtomMode(expr.modeKind, expr.modeTerm, expr.modeUnicode, expr.modePositive)), next, -1)
            case ExprKind.Empty => next
            case ExprKind.Literal => compileLiteral(expr, next)
            case ExprKind.CharacterClass => compileClass(expr.charset, expr.byteAtom, next)
            case ExprKind.Any => compileClass(dotSet(expr), expr.byteAtom, next)
            case ExprKind.Concat =>
                var start = next
                for (child in expr.children) {
                    start = compile(child, start)
                }
                start
            case ExprKind.Alternate =>
                if (expr.children.size == 0) {
                    next
                } else {
                    var index = expr.children.size - 1
                    var start = compile(expr.children[index], next)
                    while (index > 0) {
                        index--
                        start = split(compile(expr.children[index], next), start, true)
                    }
                    start
                }
            case ExprKind.Repeat => compileRepeat(expr, next)
        }
    }
    func compileRepeat(expr: Expr, next: Int64): Int64 {
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
            if (expr.minimum == 0) {
                return split(body, next, expr.greedy)
            }
            var start = body
            var count: Int64 = 1
            while (count < expr.minimum) {
                start = compile(expr.children[0], start)
                count++
            }
            return start
        }
        var start = next
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
        start
    }
    func compileLiteral(expr: Expr, next: Int64): Int64 {
        if (expr.byteAtom) {
            return byteLiteral(Int64(UInt32(expr.ch)), next)
        }
        let bytes = utf8Of(Int64(UInt32(expr.ch)))
        var start = next
        for (byte in bytes) {
            start = byteLiteral(Int64(byte), start)
        }
        start
    }
    func compileClass(set: CharSet, bytes: Bool, next: Int64): Int64 {
        if (bytes || !set.exceedsAscii()) {
            return byteClass(set, next)
        }
        let starts = ArrayList<Int64>()
        for (i in 0..set.rangeCount()) {
            let sequences = utf8Sequences(set.rangeLow(i), set.rangeHigh(i))
            for (seq in sequences) {
                var end = next
                for (range in seq) {
                    end = byteSpan(range.start, range.end, end)
                }
                starts.add(end)
            }
        }
        unionAll(starts, next)
    }
    func unionAll(starts: ArrayList<Int64>, next: Int64): Int64 {
        if (starts.size == 0) {
            return byteSpan(1, 0, next)
        }
        var index = starts.size - 1
        var start = starts[index]
        while (index > 0) {
            index--
            start = split(starts[index], start, true)
        }
        start
    }
    func byteLiteral(byte: Int64, next: Int64): Int64 {
        let id = add(Op.Literal(Rune(UInt32(byte))), next, -1)
        states[id].byteAtom = true
        id
    }
    func byteSpan(low: Int64, high: Int64, next: Int64): Int64 {
        let set = CharSet()
        if (low <= high) {
            set.addRange(low, high)
        }
        byteClass(set, next)
    }
    func byteClass(set: CharSet, next: Int64): Int64 {
        let id = add(Op.CharacterClass(set), next, -1)
        states[id].byteAtom = true
        id
    }
}
