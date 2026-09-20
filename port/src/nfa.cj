package cjregex

import std.collection.*

// Adapted from regex-automata's Thompson compiler and ordered PikeVM.
// See docs/milestone-1.md for exact upstream symbols and representation changes.
enum Op {
    Literal(Rune) | CharacterClass(CharSet) | Any | Begin | End | Split | Accept
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
            case ExprKind.Empty => return next
            case ExprKind.Literal => return add(Op.Literal(expr.ch), next, -1)
            case ExprKind.CharacterClass => return add(Op.CharacterClass(expr.charset), next, -1)
            case ExprKind.Any => return add(Op.Any, next, -1)
            case ExprKind.Begin => return add(Op.Begin, next, -1)
            case ExprKind.End => return add(Op.End, next, -1)
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

class Thread {
    let state: Int64
    let start: Int64
    init(state: Int64, start: Int64) {
        this.state = state
        this.start = start
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
    public init(pattern: String) {
        let tree = Parser(pattern).parse()
        let compiler = Compiler()
        let accept = compiler.add(Op.Accept, -1, -1)
        startState = compiler.compile(tree, accept)
        states = compiler.states.toArray()
    }
    // Iterative epsilon closure: visit each state only once per input position.
    private func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, start: Int64, pos: Int64,
        length: Int64): Unit {
        let stack = ArrayList<Int64>()
        stack.add(state)
        while (!stack.isEmpty()) {
            let id = stack.remove(at: stack.size - 1)
            if (seen[id]) {
                continue
            }
            seen[id] = true
            let s = states[id]
            match (s.op) {
                case Op.Split =>
                    stack.add(s.second);
                    stack.add(s.first)
                case Op.Begin =>
                    if (pos == 0) {
                        stack.add(s.first)
                    }
                case Op.End =>
                    if (pos == length) {
                        stack.add(s.first)
                    }
                case _ => out.add(Thread(id, start))
            }
        }
    }
    private func search(input: Input, from: Int64): Option<(Int64, Int64)> {
        var current = ArrayList<Thread>()
        var seen = Array<Bool>(states.size, repeat: false)
        var best: Option<(Int64, Int64)> = None
        var found = false
        var pos = from
        while (pos <= input.chars.size) {
            if (!found) {
                closure(current, seen, startState, pos, pos, input.chars.size)
            }
            let next = ArrayList<Thread>()
            let nextSeen = Array<Bool>(states.size, repeat: false)
            for (thread in current) {
                let s = states[thread.state]
                var consume = false
                match (s.op) {
                    case Op.Accept =>
                        best = Some((thread.start, pos))
                        found = true
                        break
                    case Op.Literal(c) => consume = pos < input.chars.size && input.chars[pos] == c
                    case Op.CharacterClass(set) => consume = pos < input.chars.size && set.contains(input.chars[pos])
                    case Op.Any => consume = pos < input.chars.size && input.chars[pos] != r'\n'
                    case _ => ()
                }
                if (consume) {
                    closure(next, nextSeen, s.first, thread.start, pos + 1, input.chars.size)
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
        match (search(input, 0)) {
            case Some((start, end)) =>
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
            match (search(input, cursor)) {
                case None => break
                case Some((start, end)) =>
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
}
