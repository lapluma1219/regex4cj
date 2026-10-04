package cjregex

import std.collection.*

// Bounded backtracking over the Thompson NFA. A visited bit records each
// (state, byte offset) pair so a failing path is not explored twice.
// The bit table is sized from the haystack. If it cannot cover every state at
// every byte boundary, search throws. That is not a failed match.
// Default capacity is 256 KiB, matching regex-automata's BoundedBacktracker.
enum BackFrame {
    Step(Int64, Int64) | Restore(Int64, Int64)
}

public class BoundedBacktracker {
    let states: Array<State>
    let startState: Int64
    let unicodeWords: CharSet
    let asciiWords: CharSet
    let groupNames: Array<String>
    let staticLen: Int64
    let visitedCapacity: Int64
    var bits: Array<UInt64>
    var stride: Int64
    var matchedFrom: Int64
    var matchedTo: Int64
    public init(pattern: String) {
        this(pattern, 256 * 1024)
    }
    public init(pattern: String, visitedCapacity: Int64) {
        if (visitedCapacity < 0) {
            throw Exception("visited capacity must be nonnegative")
        }
        this.visitedCapacity = visitedCapacity
        let options = PatternOptions()
        let parser = Parser(pattern, options)
        let tree = parser.parse()
        normalizeWidth(tree)
        ensureWithinSizeLimit([tree], options.sizeLimit, true)
        staticLen = match (staticExplicit(tree)) {
            case Some(count) => count + 1
            case None => -1
        }
        let compiler = Compiler(options.sizeLimit)
        let accept = compiler.add(Op.Accept, -1, -1)
        startState = compiler.compile(tree, accept)
        states = compiler.states.toArray()
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
        bits = Array<UInt64>(0, repeat: UInt64(0))
        stride = 0
        matchedFrom = 0
        matchedTo = 0
    }
    public func stateCount(): Int64 {
        states.size
    }
    // Same formula as BoundedBacktracker::max_haystack_len. The bit capacity
    // is rounded up to 64-bit blocks. The count is this NFA's state count.
    public func maxHaystackLen(): Int64 {
        let bitsAvailable = bitCapacity()
        let blocks = if (bitsAvailable <= 0) {
            0
        } else {
            (bitsAvailable + 63) / 64
        }
        let real = blocks * 64
        if (states.size <= 0 || real < states.size) {
            return 0
        }
        return real / states.size - 1
    }
    public func search(text: String): Option<Captures> {
        let input = Input(text)
        let byteLen = input.offsets[input.offsets.size - 1]
        resetVisited(byteLen)
        let slots = Array<Int64>(groupNames.size * 2, repeat: -1)
        var origin: Int64 = 0
        while (origin <= input.chars.size) {
            if (step(input, origin, slots)) {
                return Some(captureResult(text, input, slots))
            }
            origin++
        }
        return None
    }
    private func bitCapacity(): Int64 {
        if (visitedCapacity > 1152921504606846975) {
            throw Exception("visited capacity is too large")
        }
        return visitedCapacity * 8
    }
    private func resetVisited(byteLen: Int64): Unit {
        if (byteLen < 0) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let nextStride = byteLen + 1
        if (states.size > 0 && nextStride > 1152921504606846975 / states.size) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let needed = states.size * nextStride
        if (needed > bitCapacity()) {
            throw Exception("haystack of length ${byteLen} is too long")
        }
        let blocks = if (needed <= 0) {
            0
        } else {
            (needed + 63) / 64
        }
        bits = Array<UInt64>(blocks, repeat: UInt64(0))
        stride = nextStride
    }
    private func markVisited(sid: Int64, byteAt: Int64): Bool {
        let index = sid * stride + byteAt
        let block = index / 64
        let mask = UInt64(1) << UInt64(index % 64)
        if ((bits[block] & mask) != UInt64(0)) {
            return false
        }
        bits[block] = bits[block] | mask
        return true
    }
    private func step(input: Input, origin: Int64, slots: Array<Int64>): Bool {
        let stack = ArrayList<BackFrame>()
        stack.add(BackFrame.Step(startState, origin))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            match (frame) {
                case BackFrame.Restore(slot, old) => slots[slot] = old
                case BackFrame.Step(sid0, at0) =>
                    if (walk(stack, input, sid0, at0, origin, slots)) {
                        return true
                    }
            }
        }
        return false
    }
    private func walk(stack: ArrayList<BackFrame>, input: Input, sid0: Int64, at0: Int64, origin: Int64,
        slots: Array<Int64>): Bool {
        var sid = sid0
        var at = at0
        var walking = true
        while (walking) {
            if (!markVisited(sid, input.offsets[at])) {
                walking = false
            } else {
                let state = states[sid]
                match (state.op) {
                    case Op.Accept =>
                        matchedFrom = origin
                        matchedTo = at
                        return true
                    case Op.Split =>
                        stack.add(BackFrame.Step(state.second, at))
                        sid = state.first
                    case Op.Save(slot) =>
                        stack.add(BackFrame.Restore(slot, slots[slot]))
                        slots[slot] = at
                        sid = state.first
                    case Op.Look(mode) =>
                        if (passesLook(mode, at, input.chars, unicodeWords, asciiWords)) {
                            sid = state.first
                        } else {
                            walking = false
                        }
                    case Op.Literal(c) =>
                        if (at < input.chars.size && input.chars[at] == c) {
                            sid = state.first
                            at++
                        } else {
                            walking = false
                        }
                    case Op.CharacterClass(set) =>
                        if ((if (at < input.chars.size) {
                            set.contains(input.chars[at])
                        } else {
                            false
                        })) {
                            sid = state.first
                            at++
                        } else {
                            walking = false
                        }
                    case Op.Any(mode) =>
                        if (at < input.chars.size && passesDot(mode, input.chars[at])) {
                            sid = state.first
                            at++
                        } else {
                            walking = false
                        }
                }
            }
        }
        return false
    }
    private func captureResult(text: String, input: Input, slots: Array<Int64>): Captures {
        let groups = Array<Option<RegexMatch>>(groupNames.size, repeat: None)
        let start = input.offsets[matchedFrom]
        let end = input.offsets[matchedTo]
        groups[0] = Some(RegexMatch(start, end, text[start..end]))
        for (i in 1..groupNames.size) {
            let a = slots[i * 2]
            let b = slots[i * 2 + 1]
            if (a >= 0 && b >= 0) {
                let left = input.offsets[a]
                let right = input.offsets[b]
                groups[i] = Some(RegexMatch(left, right, text[left..right]))
            }
        }
        return Captures(groups, groupNames, staticLen)
    }
}
