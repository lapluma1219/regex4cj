package cjregex

import std.collection.*

// Forward byte Pike search for haystacks that are not UTF-8. The graph is the
// same byte compiler the DFA uses, with capture saves when they were requested.
// UTF-8 searches stay on the scalar Thompson graph.
class ByteEngine {
    let states: Array<State>
    let startState: Int64
    let patternEntries: Array<Int64>
    let names: Array<Array<String>>
    let staticLens: Array<Int64>
    let slotCount: Int64
    let whichCaptures: Int64
    let unicodeWords: CharSet
    let asciiWords: CharSet
    init(exprs: Array<Expr>, names: Array<Array<String>>, staticLens: Array<Int64>, whichCaptures: Int64) {
        let compiler = ByteCompiler(false, whichCaptures)
        let starts = ArrayList<Int64>()
        for (i in 0..exprs.size) {
            let accept = compiler.add(Op.Accept, -1, -1)
            compiler.states[accept].patternId = i
            starts.add(compiler.compile(exprs[i], accept))
        }
        var union = if (starts.size == 0) {
            -1
        } else {
            starts[starts.size - 1]
        }
        if (starts.size > 1) {
            var index = starts.size - 1
            while (index > 0) {
                index--
                union = compiler.split(starts[index], union, true)
            }
        }
        states = compiler.states.toArray()
        startState = union
        patternEntries = starts.toArray()
        this.names = names
        this.staticLens = staticLens
        this.whichCaptures = whichCaptures
        var slots: Int64 = 0
        for (row in names) {
            let width = row.size * 2
            if (width > slots) {
                slots = width
            }
        }
        slotCount = slots
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
    func stateCount(): Int64 {
        states.size
    }
    func search(input: SearchInput): Option<PikeMatch> {
        match (run(input, whichCaptures != 2)) {
            case None => None
            case Some(hit) =>
                if (whichCaptures == 2) {
                    None
                } else {
                    Some(PikeMatch(hit.pattern, capturesOf(input.bytes, hit)))
                }
        }
    }
    func isMatch(input: SearchInput): Bool {
        match (run(input, false)) {
            case Some(_) => true
            case None => false
        }
    }
    func whichOverlapping(input: SearchInput): Array<Int64> {
        let ids = ArrayList<Int64>()
        if (startState < 0 || patternEntries.size == 0) {
            return ids.toArray()
        }
        let anchored = input.anchor != 0
        var begin: Int64 = 0
        var end = patternEntries.size
        if (input.anchor == 2) {
            if (input.pattern < 0 || input.pattern >= patternEntries.size) {
                return ids.toArray()
            }
            begin = input.pattern
            end = input.pattern + 1
        }
        let from = input.start
        let until = input.end
        let reported = Array<Bool>(patternEntries.size, repeat: false)
        var current = ArrayList<Thread>()
        var pos = from
        var scanning = true
        let empty = Array<Int64>()
        while (scanning && pos <= until) {
            if (current.isEmpty() && anchored && pos > from) {
                scanning = false
            } else {
                var index = begin
                while (index < end) {
                    let seen = Array<Bool>(states.size, repeat: false)
                    closure(current, seen, patternEntries[index], pos, empty, pos, input.bytes)
                    index++
                }
                let next = ArrayList<Thread>()
                for (thread in current) {
                    let state = states[thread.state]
                    match (state.op) {
                        case Op.Accept =>
                            if (state.patternId >= 0 && state.patternId < reported.size) {
                                reported[state.patternId] = true
                            }
                        case Op.Literal(_) | Op.CharacterClass(_) =>
                            if (byteHits(state, input.bytes, pos, until)) {
                                let seen = Array<Bool>(states.size, repeat: false)
                                closure(next, seen, state.first, thread.start, empty, pos + 1, input.bytes)
                            }
                        case _ => ()
                    }
                }
                if (input.earliest) {
                    scanning = false
                } else {
                    current = next
                    pos++
                }
            }
        }
        for (i in 0..reported.size) {
            if (reported[i]) {
                ids.add(i)
            }
        }
        ids.toArray()
    }
    func run(input: SearchInput, capture: Bool): Option<NfaHit> {
        if (startState < 0) {
            return None
        }
        var entry = startState
        let anchored = input.anchor != 0
        if (input.anchor == 2) {
            if (input.pattern < 0 || input.pattern >= patternEntries.size) {
                return None
            }
            entry = patternEntries[input.pattern]
        }
        let from = input.start
        let until = input.end
        var current = ArrayList<Thread>()
        var best: Option<NfaHit> = None
        var found = false
        var pos = from
        let slots = Array<Int64>(if (capture) {
            slotCount
        } else {
            0
        }, repeat: -1)
        while (pos <= until) {
            if (!found && (!anchored || pos == from)) {
                let seen = Array<Bool>(states.size, repeat: false)
                closure(current, seen, entry, pos, slots, pos, input.bytes)
            }
            if (anchored && pos != from && current.isEmpty()) {
                return best
            }
            let next = ArrayList<Thread>()
            let nextSeen = Array<Bool>(states.size, repeat: false)
            var stop = false
            for (thread in current) {
                if (stop) {
                    break
                }
                let state = states[thread.state]
                var consume = false
                match (state.op) {
                    case Op.Accept =>
                        best = Some(NfaHit(state.patternId, thread.start, pos, thread.slots))
                        found = true
                        stop = true
                    case Op.Literal(_) | Op.CharacterClass(_) => consume = byteHits(state, input.bytes, pos, until)
                    case _ => ()
                }
                if (consume) {
                    closure(next, nextSeen, state.first, thread.start, thread.slots, pos + 1, input.bytes)
                }
            }
            if (input.earliest && found) {
                return best
            }
            if (found && next.isEmpty()) {
                return best
            }
            current = next
            pos++
        }
        best
    }
    func byteHits(state: State, bytes: Array<UInt8>, pos: Int64, limit: Int64): Bool {
        if (pos < 0 || pos >= limit || pos >= bytes.size) {
            return false
        }
        let byte = Int64(bytes[pos])
        match (state.op) {
            case Op.Literal(c) => byte == Int64(UInt32(c))
            case Op.CharacterClass(set) => set.contains(Rune(UInt32(byte)))
            case _ => false
        }
    }
    func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, start: Int64, slots: Array<Int64>, pos: Int64,
        bytes: Array<UInt8>): Unit {
        let stack = ArrayList<Thread>()
        stack.add(Thread(state, start, slots))
        while (!stack.isEmpty()) {
            let frame = stack.remove(at: stack.size - 1)
            let id = frame.state
            if (id < 0 || id >= seen.size || seen[id]) {
                continue
            }
            seen[id] = true
            let current = states[id]
            match (current.op) {
                case Op.Split =>
                    stack.add(Thread(current.second, start, frame.slots))
                    stack.add(Thread(current.first, start, frame.slots))
                case Op.Save(slot) =>
                    if (frame.slots.size == 0) {
                        stack.add(Thread(current.first, start, frame.slots))
                    } else {
                        let updated = Array<Int64>(frame.slots.size, {i => frame.slots[i]})
                        if (slot >= 0 && slot < updated.size) {
                            updated[slot] = pos
                        }
                        stack.add(Thread(current.first, start, updated))
                    }
                case Op.Look(mode) =>
                    if (passesLookBytes(mode, pos, bytes, unicodeWords, asciiWords)) {
                        stack.add(Thread(current.first, start, frame.slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
    func capturesOf(bytes: Array<UInt8>, hit: NfaHit): Captures {
        let labels = if (hit.pattern >= 0 && hit.pattern < names.size) {
            names[hit.pattern]
        } else {
            Array<String>()
        }
        let groups = Array<Option<RegexMatch>>(labels.size, repeat: None)
        if (labels.size > 0) {
            groups[0] = Some(RegexMatch(hit.start, hit.end, sliceText(bytes, hit.start, hit.end)))
        }
        for (i in 1..labels.size) {
            let a = hit.slots[i * 2]
            let b = hit.slots[i * 2 + 1]
            if (a >= 0 && b >= 0) {
                groups[i] = Some(RegexMatch(a, b, sliceText(bytes, a, b)))
            }
        }
        let frozen = if (hit.pattern >= 0 && hit.pattern < staticLens.size) {
            staticLens[hit.pattern]
        } else {
            -1
        }
        Captures(groups, labels, frozen)
    }
    func sliceText(bytes: Array<UInt8>, start: Int64, end: Int64): String {
        if (start < 0 || end < start || end > bytes.size) {
            return ""
        }
        let piece = Array<UInt8>(end - start, {i => bytes[start + i]})
        match (decodeUtf8(piece)) {
            case Some(text) => text
            case None =>
                let out = StringBuilder()
                for (byte in piece) {
                    out.append(debugByte(Int64(byte)))
                }
                out.toString()
        }
    }
}
