package regex4cj

import std.collection.*

// Experimental one-pass eligibility adapter, with a conservative local byte
// graph check. This is NOT a one-pass execution engine: accepted patterns use
// anchored PikeVM search. The accepted set can differ from regex-automata's.
public class OnePass {
    let vm: PikeVM
    public let engineName: String = "onepass"
    public init(pattern: String) {
        this([pattern])
    }
    public init(patterns: Array<String>) {
        match (onePassRejection(patterns)) {
            case Some(detail) => throw Exception(
                "one-pass DFA could not be built because pattern is not one-pass: ${detail}")
            case None => ()
        }
        vm = PikeVM(patterns)
    }
    // One-pass search is anchored. Callers that need an unanchored match retry
    // at each later offset.
    public func search(text: String): Option<PikeMatch> {
        searchAnchored(text, 0)
    }
    public func searchAnchored(text: String, at: Int64): Option<PikeMatch> {
        vm.search(text, at, text.size, true)
    }
    public func searchAll(text: String): Array<PikeMatch> {
        match (search(text)) {
            case Some(hit) => [hit]
            case None => Array<PikeMatch>()
        }
    }
}

func onePassRejection(patterns: Array<String>): Option<String> {
    if (patterns.size == 0) {
        return Some("multiple epsilon transitions to match state")
    }
    let options = PatternOptions()
    let compiler = ByteCompiler()
    let starts = ArrayList<Int64>()
    for (pattern in patterns) {
        let tree = Parser(pattern, options).parse()
        normalizeWidth(tree)
        let accept = compiler.add(Op.Accept, -1, -1)
        compiler.states[accept].patternId = starts.size
        starts.add(compiler.compile(tree, accept))
    }
    let states = compiler.states.toArray()
    for (state in 0..states.size) {
        match (closureProblem(states, state)) {
            case Some(detail) => return Some(detail)
            case None => ()
        }
    }
    None<String>
}

func closureProblem(states: Array<State>, start: Int64): Option<String> {
    let seen = Array<Bool>(states.size, repeat: false)
    let bytes = Array<Int64>(256, repeat: -1)
    let stack = ArrayList<Int64>()
    stack.add(start)
    while (!stack.isEmpty()) {
        let id = stack.remove(at: stack.size - 1)
        if (id < 0 || id >= states.size) {
            continue
        }
        if (seen[id]) {
            match (states[id].op) {
                case Op.Accept => return Some("multiple epsilon transitions to match state")
                case _ => return Some("multiple epsilon transitions to same state")
            }
        }
        seen[id] = true
        let state = states[id]
        match (state.op) {
            case Op.Split =>
                stack.add(state.second)
                stack.add(state.first)
            case Op.Look(_) | Op.Save(_) => stack.add(state.first)
            case Op.Accept => ()
            case Op.Literal(char) => match (noteByte(bytes, Int64(UInt32(char)), state.first)) {
                case Some(detail) => return Some(detail)
                case None => ()
            }
            case Op.CharacterClass(set) => for (range in 0..set.rangeCount()) {
                var low = set.rangeLow(range)
                let high = set.rangeHigh(range)
                if (low < 0) {
                    low = 0
                }
                var byte = low
                let last = if (high > 255) {
                    255
                } else {
                    high
                }
                while (byte <= last) {
                    match (noteByte(bytes, byte, state.first)) {
                        case Some(detail) => return Some(detail)
                        case None => ()
                    }
                    byte++
                }
            }
            case Op.Any(_) =>
                var byte: Int64 = 0
                while (byte < 256) {
                    match (noteByte(bytes, byte, state.first)) {
                        case Some(detail) => return Some(detail)
                        case None => ()
                    }
                    byte++
                }
        }
    }
    None<String>
}

func noteByte(bytes: Array<Int64>, byte: Int64, target: Int64): Option<String> {
    if (byte < 0 || byte > 255) {
        return None<String>
    }
    if (bytes[byte] >= 0 && bytes[byte] != target) {
        return Some("conflicting transition")
    }
    bytes[byte] = target
    None<String>
}
