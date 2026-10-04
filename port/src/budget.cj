package cjregex

import std.collection.*

// Thompson builder accounting from regex-automata on 64-bit targets.
// Each builder state is 32 bytes. A sparse transition is 8 bytes and each
// union alternate is 4. The check is usage > limit, once for the forward NFA
// and once for the reverse NFA. Exact literal patterns never build an NFA.
const THOMPSON_STATE: Int64 = 32
const THOMPSON_TRANSITION: Int64 = 8
const THOMPSON_ALTERNATE: Int64 = 4
const LITERAL_CLASS_LIMIT: Int64 = 10
const LITERAL_REPEAT_LIMIT: Int64 = 10
const LITERAL_LENGTH_LIMIT: Int64 = 100
const LITERAL_TOTAL_LIMIT: Int64 = 250

func ensureWithinSizeLimit(exprs: Array<Expr>, limit: Int64, captures: Bool): Unit {
    if (captures && exprs.size == 1) {
        if (literalBypass(exprs[0])) {
            return
        }
    }
    let forward = ThompsonBudget(false, captures, limit).compileMany(exprs)
    let reverse = ThompsonBudget(true, false, limit).compileMany(exprs)
    if (forward > limit || reverse > limit) {
        throw compiledTooBig(limit)
    }
}

class ThompsonRef {
    let start: Int64
    let end: Int64
    init(start: Int64, end: Int64) {
        this.start = start
        this.end = end
    }
}

class NfaTrans {
    let start: Int64
    let end: Int64
    let next: Int64
    init(start: Int64, end: Int64, next: Int64) {
        this.start = start
        this.end = end
        this.next = next
    }
}

class VarTrans {
    let start: Int64
    let end: Int64
    var next: Int64
    init(start: Int64, end: Int64, next: Int64) {
        this.start = start
        this.end = end
        this.next = next
    }
}

class TrieLink {
    let byte: Int64
    let next: Int64
    init(byte: Int64, next: Int64) {
        this.byte = byte
        this.next = next
    }
}

class TrieState {
    var transitions = ArrayList<TrieLink>()
    var chunkEnds = ArrayList<Int64>()
    func isLeaf(): Bool {
        transitions.size == 0
    }
    func activeStart(): Int64 {
        if (chunkEnds.size == 0) {
            0
        } else {
            chunkEnds[chunkEnds.size - 1]
        }
    }
    func addMatch(): Unit {
        if (transitions.size == 0 && chunkEnds.size != 0) {
            return
        }
        chunkEnds.add(transitions.size)
    }
    func allChunks(): ArrayList<ArrayList<TrieLink>> {
        let out = ArrayList<ArrayList<TrieLink>>()
        var from: Int64 = 0
        for (end in chunkEnds) {
            out.add(copyLinks(from, end))
            from = end
        }
        out.add(copyLinks(from, transitions.size))
        out
    }
    func copyLinks(from: Int64, until: Int64): ArrayList<TrieLink> {
        let out = ArrayList<TrieLink>()
        var i = from
        while (i < until) {
            out.add(transitions[i])
            i++
        }
        out
    }
    func insertLink(index: Int64, link: TrieLink): Unit {
        let copy = ArrayList<TrieLink>()
        var i: Int64 = 0
        while (i < transitions.size) {
            if (i == index) {
                copy.add(link)
            }
            copy.add(transitions[i])
            i++
        }
        if (index == transitions.size) {
            copy.add(link)
        }
        transitions = copy
    }
}

class TrieFrame {
    var trans = ArrayList<TrieLink>()
    var transIndex: Int64 = 0
    var rest = ArrayList<ArrayList<TrieLink>>()
    var restIndex: Int64 = 0
    var union = ArrayList<Int64>()
    var sparse = ArrayList<VarTrans>()
    init(state: TrieState) {
        let chunks = state.allChunks()
        trans = chunks[0]
        var i: Int64 = 1
        while (i < chunks.size) {
            rest.add(chunks[i])
            i++
        }
    }
}

class LitTry {
    var ok = false
    let bytes = ArrayList<UInt8>()
}

class ClassTry {
    var ok = false
    var bytes = false
    let set = CharSet()
}

class LitList {
    var ok = false
    let seqs = ArrayList<ArrayList<UInt8>>()
}

class ByteSpan {
    let start: Int64
    let end: Int64
    init(start: Int64, end: Int64) {
        this.start = start
        this.end = end
    }
}

class ScalarSpan {
    var start: Int64
    var end: Int64
    init(start: Int64, end: Int64) {
        this.start = start
        this.end = end
    }
}

class Utf8Node {
    let trans = ArrayList<NfaTrans>()
    var hasLast = false
    var lastStart: Int64 = 0
    var lastEnd: Int64 = 0
    func freeze(next: Int64): Unit {
        if (hasLast) {
            trans.add(NfaTrans(lastStart, lastEnd, next))
            hasLast = false
        }
    }
}

class MapEntry {
    var version: Int64 = 0
    let key = ArrayList<NfaTrans>()
    var value: Int64 = -1
}

class Utf8Cache {
    let slots: Array<MapEntry>
    let version: Int64 = 1
    init(capacity: Int64) {
        slots = Array<MapEntry>(capacity, {_ => MapEntry()})
    }
    func hash(key: ArrayList<NfaTrans>): Int64 {
        var h = fnvInit()
        for (t in key) {
            h = fnvMix(h, UInt64(t.start))
            h = fnvMix(h, UInt64(t.end))
            h = fnvMix(h, UInt64(t.next))
        }
        Int64(h % UInt64(slots.size))
    }
    func find(key: ArrayList<NfaTrans>, hash: Int64): Int64 {
        let entry = slots[hash]
        if (entry.version != version || entry.key.size != key.size) {
            return -1
        }
        for (i in 0..key.size) {
            if (entry.key[i].start != key[i].start || entry.key[i].end != key[i].end || entry.key[i].next != key[i].next) {
                return -1
            }
        }
        entry.value
    }
    func store(key: ArrayList<NfaTrans>, hash: Int64, id: Int64): Unit {
        let entry = slots[hash]
        entry.version = version
        while (!entry.key.isEmpty()) {
            entry.key.remove(at: entry.key.size - 1)
        }
        for (t in key) {
            entry.key.add(NfaTrans(t.start, t.end, t.next))
        }
        entry.value = id
    }
}

class SuffixEntry {
    var version: Int64 = 0
    var from: Int64 = -1
    var start: Int64 = 0
    var end: Int64 = 0
    var value: Int64 = -1
}

class SuffixCache {
    let slots: Array<SuffixEntry>
    let version: Int64 = 1
    init(capacity: Int64) {
        slots = Array<SuffixEntry>(capacity, {_ => SuffixEntry()})
    }
    func hash(from: Int64, start: Int64, end: Int64): Int64 {
        var h = fnvInit()
        h = fnvMix(h, UInt64(from))
        h = fnvMix(h, UInt64(start))
        h = fnvMix(h, UInt64(end))
        Int64(h % UInt64(slots.size))
    }
    func find(from: Int64, start: Int64, end: Int64, hash: Int64): Int64 {
        let entry = slots[hash]
        if (entry.version != version || entry.from != from || entry.start != start || entry.end != end) {
            return -1
        }
        entry.value
    }
    func store(from: Int64, start: Int64, end: Int64, hash: Int64, id: Int64): Unit {
        let entry = slots[hash]
        entry.version = version
        entry.from = from
        entry.start = start
        entry.end = end
        entry.value = id
    }
}

class ThompsonBudget {
    let reverse: Bool
    let captures: Bool
    let limit: Int64
    var states: Int64 = 0
    var extra: Int64 = 0
    let unions = ArrayList<Bool>()
    init(reverse: Bool, captures: Bool, limit: Int64) {
        this.reverse = reverse
        this.captures = captures
        this.limit = limit
    }
    func compileMany(exprs: Array<Expr>): Int64 {
        let prefix = if (allAnchored(exprs, reverse)) {
            cEmpty()
        } else {
            unanchoredPrefix()
        }
        let parts = ArrayList<ThompsonRef>()
        for (expr in exprs) {
            parts.add(compilePattern(expr))
        }
        let body = cAlt(parts)
        patch(prefix.end, body.start)
        states * THOMPSON_STATE + extra
    }
    func compilePattern(expr: Expr): ThompsonRef {
        let inner = if (captures) {
            wrapCapture(expr)
        } else {
            c(expr)
        }
        let matched = addState(false, 0)
        patch(inner.end, matched)
        ThompsonRef(inner.start, matched)
    }
    func wrapCapture(expr: Expr): ThompsonRef {
        let start = addState(false, 0)
        let body = c(expr)
        let end = addState(false, 0)
        patch(start, body.start)
        patch(body.end, end)
        ThompsonRef(start, end)
    }
    func unanchoredPrefix(): ThompsonRef {
        let union = addState(true, 0)
        let dot = cBytes(0, 255)
        patch(union, dot.start)
        patch(dot.end, union)
        ThompsonRef(union, union)
    }
    func c(expr: Expr): ThompsonRef {
        match (expr.kind) {
            case ExprKind.Empty => cEmpty()
            case ExprKind.Literal => cLiteral(expr)
            case ExprKind.CharacterClass => cClass(expr.charset, expr.byteAtom)
            case ExprKind.Any => cClass(dotSet(expr), expr.byteAtom)
            case ExprKind.Begin | ExprKind.End | ExprKind.WordBoundary =>
                let id = addState(false, 0)
                ThompsonRef(id, id)
            case ExprKind.Concat => cConcat(compileChildren(stripFlagNodes(expr.children)))
            case ExprKind.Alternate => cAlternate(expr)
            case ExprKind.Repeat => cRepeat(expr)
            case ExprKind.Capture =>
                if (!captures) {
                    c(expr.children[0])
                } else {
                    wrapCapture(expr.children[0])
                }
        }
    }
    func compileChildren(children: Array<Expr>): ArrayList<ThompsonRef> {
        let refs = ArrayList<ThompsonRef>()
        if (reverse) {
            var i = children.size
            while (i > 0) {
                i--
                refs.add(c(children[i]))
            }
        } else {
            for (child in children) {
                refs.add(c(child))
            }
        }
        refs
    }
    func cRepeat(expr: Expr): ThompsonRef {
        let child = expr.children[0]
        if (expr.maximum >= 0 && expr.minimum == expr.maximum) {
            return cExactly(child, expr.minimum)
        }
        if (expr.minimum == 0 && expr.maximum == 1) {
            return cZeroOrOne(child, expr.greedy)
        }
        if (expr.maximum < 0) {
            return cAtLeast(child, expr.greedy, expr.minimum)
        }
        cBounded(child, expr.greedy, expr.minimum, expr.maximum)
    }
    // Each copy adds at least one 32-byte state. Stop before unrolling a count
    // that cannot fit, so a repetition like {2147483516} reports the size limit
    // instead of building billions of states.
    func repeatWouldExceed(copies: Int64): Bool {
        if (copies <= 1) {
            return false
        }
        let room = limit - (states * THOMPSON_STATE + extra)
        if (room < THOMPSON_STATE) {
            return true
        }
        copies > room / THOMPSON_STATE
    }
    func cExactly(expr: Expr, times: Int64): ThompsonRef {
        if (times <= 0) {
            return cEmpty()
        }
        if (repeatWouldExceed(times)) {
            throw compiledTooBig(limit)
        }
        let refs = ArrayList<ThompsonRef>()
        var i: Int64 = 0
        while (i < times) {
            refs.add(c(expr))
            i++
        }
        cConcat(refs)
    }
    func cZeroOrOne(expr: Expr, greedy: Bool): ThompsonRef {
        let union = addState(true, 0)
        let compiled = c(expr)
        let empty = addState(false, 0)
        if (greedy) {
            patch(union, compiled.start)
            patch(union, empty)
        } else {
            patch(union, empty)
            patch(union, compiled.start)
        }
        patch(compiled.end, empty)
        ThompsonRef(union, empty)
    }
    func cAtLeast(expr: Expr, greedy: Bool, times: Int64): ThompsonRef {
        if (times == 0) {
            if (minBytes(expr) > 0) {
                let union = addState(true, 0)
                let compiled = c(expr)
                if (greedy) {
                    patch(union, compiled.start)
                } else {
                    patch(union, compiled.start)
                }
                patch(compiled.end, union)
                return ThompsonRef(union, union)
            }
            let compiled = c(expr)
            let plus = addState(true, 0)
            patch(compiled.end, plus)
            patch(plus, compiled.start)
            let question = addState(true, 0)
            let empty = addState(false, 0)
            if (greedy) {
                patch(question, compiled.start)
                patch(question, empty)
            } else {
                patch(question, empty)
                patch(question, compiled.start)
            }
            patch(plus, empty)
            return ThompsonRef(question, empty)
        }
        if (times == 1) {
            let compiled = c(expr)
            let union = addState(true, 0)
            patch(compiled.end, union)
            patch(union, compiled.start)
            return ThompsonRef(compiled.start, union)
        }
        let prefix = cExactly(expr, times - 1)
        let last = c(expr)
        let union = addState(true, 0)
        patch(prefix.end, last.start)
        patch(last.end, union)
        patch(union, last.start)
        ThompsonRef(prefix.start, union)
    }
    func cBounded(expr: Expr, greedy: Bool, minimum: Int64, maximum: Int64): ThompsonRef {
        if (repeatWouldExceed(maximum - minimum)) {
            throw compiledTooBig(limit)
        }
        let prefix = cExactly(expr, minimum)
        if (minimum == maximum) {
            return prefix
        }
        let empty = addState(false, 0)
        var prev = prefix.end
        var i = minimum
        while (i < maximum) {
            let union = addState(true, 0)
            let compiled = c(expr)
            patch(prev, union)
            if (greedy) {
                patch(union, compiled.start)
                patch(union, empty)
            } else {
                patch(union, empty)
                patch(union, compiled.start)
            }
            prev = compiled.end
            i++
        }
        patch(prev, empty)
        ThompsonRef(prefix.start, empty)
    }
    func cConcat(refs: ArrayList<ThompsonRef>): ThompsonRef {
        if (refs.size == 0) {
            return cEmpty()
        }
        var end = refs[0].end
        let start = refs[0].start
        for (i in 1..refs.size) {
            patch(end, refs[i].start)
            end = refs[i].end
        }
        ThompsonRef(start, end)
    }
    func cAlt(refs: ArrayList<ThompsonRef>): ThompsonRef {
        if (refs.size == 0) {
            return cFail()
        }
        if (refs.size == 1) {
            return refs[0]
        }
        let union = addState(true, 0)
        let end = addState(false, 0)
        for (part in refs) {
            patch(union, part.start)
            patch(part.end, end)
        }
        ThompsonRef(union, end)
    }
    func cAlternate(expr: Expr): ThompsonRef {
        let branches = ArrayList<Expr>()
        flattenAlt(expr, branches)
        if (branches.size == 0) {
            return cFail()
        }
        if (branches.size == 1) {
            return c(branches[0])
        }
        let cls = singletonClass(branches)
        if (cls.ok) {
            return cClass(cls.set, cls.bytes)
        }
        let lits = literalBranches(branches)
        if (lits.ok) {
            return cLiteralTrie(lits.seqs)
        }
        let refs = ArrayList<ThompsonRef>()
        for (branch in branches) {
            refs.add(c(branch))
        }
        cAlt(refs)
    }
    func cLiteralTrie(seqs: ArrayList<ArrayList<UInt8>>): ThompsonRef {
        let trie = ArrayList<TrieState>()
        trie.add(TrieState())
        for (seq in seqs) {
            addTrieLiteral(trie, seq)
        }
        let end = addState(false, 0)
        let stack = ArrayList<TrieFrame>()
        var frame = TrieFrame(trie[0])
        var finished = false
        var result = ThompsonRef(end, end)
        while (!finished) {
            if (frame.transIndex < frame.trans.size) {
                let link = frame.trans[frame.transIndex]
                frame.transIndex++
                if (trie[link.next].isLeaf()) {
                    frame.sparse.add(VarTrans(link.byte, link.byte, end))
                } else {
                    frame.sparse.add(VarTrans(link.byte, link.byte, 0))
                    stack.add(frame)
                    frame = TrieFrame(trie[link.next])
                }
                continue
            }
            if (frame.sparse.size != 0) {
                let chunkId = if (frame.sparse.size == 1) {
                    addState(false, 0)
                } else {
                    addState(false, frame.sparse.size * THOMPSON_TRANSITION)
                }
                frame.union.add(chunkId)
                frame.sparse = ArrayList<VarTrans>()
            }
            if (frame.restIndex < frame.rest.size) {
                frame.union.add(end)
                frame.trans = frame.rest[frame.restIndex]
                frame.restIndex++
                frame.transIndex = 0
                continue
            }
            let start = addState(true, frame.union.size * THOMPSON_ALTERNATE)
            if (stack.size == 0) {
                result = ThompsonRef(start, end)
                finished = true
            } else {
                let parent = stack.remove(at: stack.size - 1)
                parent.sparse[parent.sparse.size - 1].next = start
                frame = parent
            }
        }
        result
    }
    func addTrieLiteral(trie: ArrayList<TrieState>, bytes: ArrayList<UInt8>): Unit {
        var prev: Int64 = 0
        if (reverse) {
            var i = bytes.size
            while (i > 0) {
                i--
                prev = addTrieState(trie, prev, Int64(bytes[i]))
            }
        } else {
            for (byte in bytes) {
                prev = addTrieState(trie, prev, Int64(byte))
            }
        }
        trie[prev].addMatch()
    }
    func addTrieState(trie: ArrayList<TrieState>, from: Int64, byte: Int64): Int64 {
        let state = trie[from]
        let start = state.activeStart()
        var index = start
        while (index < state.transitions.size) {
            let link = state.transitions[index]
            if (link.byte == byte) {
                return link.next
            }
            if (link.byte > byte) {
                break
            }
            index++
        }
        let next = trie.size
        trie.add(TrieState())
        trie[from].insertLink(index, TrieLink(byte, next))
        next
    }
    func cLiteral(expr: Expr): ThompsonRef {
        if (expr.byteAtom) {
            let byte = Int64(UInt32(expr.ch))
            return cRange(byte, byte)
        }
        let bytes = utf8Of(Int64(UInt32(expr.ch)))
        let refs = ArrayList<ThompsonRef>()
        if (reverse) {
            var i = bytes.size
            while (i > 0) {
                i--
                let byte = Int64(bytes[i])
                refs.add(cRange(byte, byte))
            }
        } else {
            for (byte in bytes) {
                refs.add(cRange(Int64(byte), Int64(byte)))
            }
        }
        cConcat(refs)
    }
    func cClass(set: CharSet, bytes: Bool): ThompsonRef {
        if (bytes || !set.exceedsAscii()) {
            return cSparse(set)
        }
        if (reverse) {
            cUnicodeReverse(set)
        } else {
            cUnicodeForward(set)
        }
    }
    func cSparse(set: CharSet): ThompsonRef {
        let end = addState(false, 0)
        let trans = ArrayList<NfaTrans>()
        for (i in 0..set.rangeCount()) {
            trans.add(NfaTrans(set.rangeLow(i), set.rangeHigh(i), end))
        }
        let start = addSparse(trans)
        ThompsonRef(start, end)
    }
    func cBytes(start: Int64, end: Int64): ThompsonRef {
        let tail = addState(false, 0)
        let trans = ArrayList<NfaTrans>()
        trans.add(NfaTrans(start, end, tail))
        ThompsonRef(addSparse(trans), tail)
    }
    func cUnicodeForward(set: CharSet): ThompsonRef {
        let cache = Utf8Cache(10000)
        let target = addState(false, 0)
        let nodes = ArrayList<Utf8Node>()
        nodes.add(Utf8Node())
        for (i in 0..set.rangeCount()) {
            let sequences = utf8Sequences(set.rangeLow(i), set.rangeHigh(i))
            for (seq in sequences) {
                addSequence(cache, nodes, target, seq)
            }
        }
        compileFrom(cache, nodes, target, 0)
        let root = nodes.remove(at: nodes.size - 1)
        ThompsonRef(compileNode(cache, root.trans), target)
    }
    func addSequence(cache: Utf8Cache, nodes: ArrayList<Utf8Node>, target: Int64, seq: ArrayList<ByteSpan>): Unit {
        var prefix: Int64 = 0
        while (prefix < seq.size && prefix < nodes.size) {
            let node = nodes[prefix]
            let range = seq[prefix]
            if (!node.hasLast || node.lastStart != range.start || node.lastEnd != range.end) {
                break
            }
            prefix++
        }
        compileFrom(cache, nodes, target, prefix)
        let last = nodes[nodes.size - 1]
        let first = seq[prefix]
        last.hasLast = true
        last.lastStart = first.start
        last.lastEnd = first.end
        var i = prefix + 1
        while (i < seq.size) {
            let node = Utf8Node()
            node.hasLast = true
            node.lastStart = seq[i].start
            node.lastEnd = seq[i].end
            nodes.add(node)
            i++
        }
    }
    func compileFrom(cache: Utf8Cache, nodes: ArrayList<Utf8Node>, target: Int64, from: Int64): Unit {
        var next = target
        while (from + 1 < nodes.size) {
            let node = nodes.remove(at: nodes.size - 1)
            node.freeze(next)
            next = compileNode(cache, node.trans)
        }
        nodes[nodes.size - 1].freeze(next)
    }
    func compileNode(cache: Utf8Cache, trans: ArrayList<NfaTrans>): Int64 {
        let hashed = cache.hash(trans)
        let found = cache.find(trans, hashed)
        if (found >= 0) {
            return found
        }
        let id = addSparse(trans)
        cache.store(trans, hashed, id)
        id
    }
    func cUnicodeReverse(set: CharSet): ThompsonRef {
        let cache = SuffixCache(1000)
        let union = addState(true, 0)
        let altEnd = addState(false, 0)
        for (i in 0..set.rangeCount()) {
            let sequences = utf8Sequences(set.rangeLow(i), set.rangeHigh(i))
            for (seq in sequences) {
                var end = altEnd
                for (range in seq) {
                    let from = end
                    let hashed = cache.hash(from, range.start, range.end)
                    let found = cache.find(from, range.start, range.end, hashed)
                    if (found >= 0) {
                        end = found
                    } else {
                        let compiled = cRange(range.start, range.end)
                        patch(compiled.end, end)
                        end = compiled.start
                        cache.store(from, range.start, range.end, hashed, end)
                    }
                }
                patch(union, end)
            }
        }
        ThompsonRef(union, altEnd)
    }
    func cRange(start: Int64, end: Int64): ThompsonRef {
        if (end < start) {
            extra += 0
        }
        let id = addState(false, 0)
        ThompsonRef(id, id)
    }
    func cEmpty(): ThompsonRef {
        let id = addState(false, 0)
        ThompsonRef(id, id)
    }
    func cFail(): ThompsonRef {
        let id = addState(false, 0)
        ThompsonRef(id, id)
    }
    func addSparse(trans: ArrayList<NfaTrans>): Int64 {
        addState(false, trans.size * THOMPSON_TRANSITION)
    }
    func addState(union: Bool, extraBytes: Int64): Int64 {
        let next = (states + 1) * THOMPSON_STATE + extra + extraBytes
        if (next > limit) {
            throw compiledTooBig(limit)
        }
        let id = states
        states++
        extra += extraBytes
        unions.add(union)
        id
    }
    func patch(from: Int64, to: Int64): Unit {
        if (unions[from]) {
            extra += THOMPSON_ALTERNATE
            if (states * THOMPSON_STATE + extra > limit) {
                throw compiledTooBig(limit)
            }
        }
        if (to < 0) {
            extra += 0
        }
    }
}

func stripFlagNodes(children: Array<Expr>): Array<Expr> {
    let kept = ArrayList<Expr>()
    for (child in children) {
        if (!child.flagOnly) {
            kept.add(child)
        }
    }
    kept.toArray()
}

func isConcat(expr: Expr): Bool {
    match (expr.kind) {
        case ExprKind.Concat => true
        case _ => false
    }
}

func isAlternate(expr: Expr): Bool {
    match (expr.kind) {
        case ExprKind.Alternate => true
        case _ => false
    }
}

func peelExpr(expr: Expr): Expr {
    var node = expr
    while (isConcat(node)) {
        let kept = ArrayList<Expr>()
        for (child in node.children) {
            if (!child.flagOnly) {
                kept.add(child)
            }
        }
        if (kept.size != 1) {
            break
        }
        node = kept[0]
    }
    node
}

func flattenAlt(expr: Expr, out: ArrayList<Expr>): Unit {
    let node = peelExpr(expr)
    if (isAlternate(node)) {
        for (child in node.children) {
            flattenAlt(child, out)
        }
    } else {
        out.add(node)
    }
}

func oneChar(expr: Expr): Bool {
    match (expr.kind) {
        case ExprKind.Literal =>
            if (expr.byteAtom && Int64(UInt32(expr.ch)) > 127) {
                false
            } else {
                true
            }
        case _ => false
    }
}

func branchBytes(expr: Expr): LitTry {
    match (expr.kind) {
        case ExprKind.Literal =>
            let got = LitTry()
            got.ok = true
            if (expr.byteAtom) {
                got.bytes.add(UInt8(Int64(UInt32(expr.ch))))
            } else {
                for (byte in utf8Of(Int64(UInt32(expr.ch)))) {
                    got.bytes.add(byte)
                }
            }
            got
        case ExprKind.Concat =>
            let got = LitTry()
            got.ok = true
            var any = false
            for (child in expr.children) {
                if (child.flagOnly) {
                    continue
                }
                any = true
                let part = branchBytes(child)
                if (!part.ok) {
                    got.ok = false
                    return got
                }
                for (byte in part.bytes) {
                    got.bytes.add(byte)
                }
            }
            if (!any) {
                got.ok = false
            }
            got
        case _ => LitTry()
    }
}

func singletonClass(branches: ArrayList<Expr>): ClassTry {
    let result = ClassTry()
    var chars = true
    var bytes = true
    let charSet = CharSet()
    let byteSet = CharSet()
    for (branch in branches) {
        let lit = branchBytes(branch)
        if (!lit.ok) {
            return result
        }
        if (!oneChar(branch)) {
            chars = false
        } else {
            let code = Int64(UInt32(branch.ch))
            charSet.addRange(code, code)
        }
        if (lit.bytes.size != 1) {
            bytes = false
        } else {
            byteSet.addRange(Int64(lit.bytes[0]), Int64(lit.bytes[0]))
        }
    }
    if (chars) {
        result.ok = true
        result.bytes = false
        result.set.unionWith(charSet)
        return result
    }
    if (bytes) {
        result.ok = true
        result.bytes = true
        result.set.unionWith(byteSet)
        return result
    }
    result
}

func literalBranches(branches: ArrayList<Expr>): LitList {
    let result = LitList()
    result.ok = true
    for (branch in branches) {
        let lit = branchBytes(branch)
        if (!lit.ok) {
            result.ok = false
            return result
        }
        result.seqs.add(lit.bytes)
    }
    result
}

func allAnchored(exprs: Array<Expr>, reverse: Bool): Bool {
    for (expr in exprs) {
        let anchored = if (reverse) {
            hasEndAnchor(expr)
        } else {
            hasStartAnchor(expr)
        }
        if (!anchored) {
            return false
        }
    }
    true
}

func hasStartAnchor(expr: Expr): Bool {
    match (expr.kind) {
        case ExprKind.Begin => expr.modeKind == 0
        case ExprKind.Concat =>
            var found = false
            var anchored = false
            for (child in expr.children) {
                if (child.flagOnly) {
                    continue
                }
                found = true
                anchored = hasStartAnchor(child)
                break
            }
            found && anchored
        case ExprKind.Alternate =>
            if (expr.children.size == 0) {
                false
            } else {
                var ok = true
                for (child in expr.children) {
                    if (!hasStartAnchor(child)) {
                        ok = false
                    }
                }
                ok
            }
        case ExprKind.Capture => hasStartAnchor(expr.children[0])
        case ExprKind.Repeat => (if (expr.minimum > 0) {
            hasStartAnchor(expr.children[0])
        } else {
            false
        })
        case _ => false
    }
}

func hasEndAnchor(expr: Expr): Bool {
    match (expr.kind) {
        case ExprKind.End => expr.modeKind == 1
        case ExprKind.Concat =>
            var index = expr.children.size
            while (index > 0) {
                index--
                if (!expr.children[index].flagOnly) {
                    return hasEndAnchor(expr.children[index])
                }
            }
            false
        case ExprKind.Alternate =>
            if (expr.children.size == 0) {
                false
            } else {
                var ok = true
                for (child in expr.children) {
                    if (!hasEndAnchor(child)) {
                        ok = false
                    }
                }
                ok
            }
        case ExprKind.Capture => hasEndAnchor(expr.children[0])
        case ExprKind.Repeat => (if (expr.minimum > 0) {
            hasEndAnchor(expr.children[0])
        } else {
            false
        })
        case _ => false
    }
}

func dotSet(expr: Expr): CharSet {
    let set = CharSet()
    let term = Int64(UInt32(expr.modeTerm))
    if (expr.byteAtom) {
        if (expr.modeKind == 1) {
            set.addRange(0, 255)
        } else if (expr.modeKind == 2) {
            set.addRange(0, 9)
            set.addRange(11, 12)
            set.addRange(14, 255)
        } else if (term <= 0) {
            set.addRange(1, 255)
        } else if (term >= 255) {
            set.addRange(0, 254)
        } else {
            set.addRange(0, term - 1)
            set.addRange(term + 1, 255)
        }
    } else if (expr.modeKind == 1) {
        set.addRange(0, 0x10FFFF)
    } else if (expr.modeKind == 2) {
        set.addRange(0, 9)
        set.addRange(11, 12)
        set.addRange(14, 0x10FFFF)
    } else if (term <= 0) {
        set.addRange(1, 0x10FFFF)
    } else {
        set.addRange(0, term - 1)
        set.addRange(term + 1, 0x10FFFF)
    }
    set
}

func minBytes(expr: Expr): Int64 {
    match (expr.kind) {
        case ExprKind.Empty | ExprKind.Begin | ExprKind.End | ExprKind.WordBoundary => 0
        case ExprKind.Literal =>
            if (expr.byteAtom) {
                1
            } else {
                utf8Length(Int64(UInt32(expr.ch)))
            }
        case ExprKind.Any => 1
        case ExprKind.CharacterClass => classMinBytes(expr.charset, expr.byteAtom)
        case ExprKind.Capture => minBytes(expr.children[0])
        case ExprKind.Concat =>
            var total: Int64 = 0
            for (child in expr.children) {
                let next = minBytes(child)
                if (next < 0) {
                    total = -1
                } else if (total >= 0) {
                    total += next
                }
            }
            total
        case ExprKind.Alternate =>
            var best: Int64 = -1
            for (child in expr.children) {
                let next = minBytes(child)
                if (next >= 0 && (best < 0 || next < best)) {
                    best = next
                }
            }
            best
        case ExprKind.Repeat =>
            if (expr.maximum == 0 || expr.minimum == 0) {
                0
            } else {
                let inner = minBytes(expr.children[0])
                if (inner < 0) {
                    -1
                } else {
                    inner
                }
            }
    }
}

func classMinBytes(set: CharSet, bytes: Bool): Int64 {
    if (set.isEmpty()) {
        return -1
    }
    if (bytes) {
        return 1
    }
    utf8Length(set.rangeLow(0))
}

class LitAcc {
    var exact = true
    let items = ArrayList<ArrayList<UInt8>>()
}

func literalBypass(expr: Expr): Bool {
    let acc = literalsOf(expr)
    if (!acc.exact || acc.items.size == 0) {
        return false
    }
    for (item in acc.items) {
        if (item.size == 0) {
            return false
        }
    }
    true
}

func literalsOf(expr: Expr): LitAcc {
    match (expr.kind) {
        case ExprKind.Empty => oneEmptyLiteral()
        case ExprKind.Literal =>
            let acc = LitAcc()
            acc.items.add(literalBytes(expr))
            acc
        case ExprKind.CharacterClass => classLiterals(expr.charset, expr.byteAtom)
        case ExprKind.Concat =>
            var acc = oneEmptyLiteral()
            var any = false
            for (child in expr.children) {
                if (child.flagOnly) {
                    continue
                }
                any = true
                acc = productLiterals(acc, literalsOf(child))
                if (!acc.exact) {
                    return acc
                }
            }
            if (!any) {
                oneEmptyLiteral()
            } else {
                acc
            }
        case ExprKind.Alternate =>
            if (expr.children.size == 1) {
                literalsOf(expr.children[0])
            } else {
                let acc = LitAcc()
                for (child in expr.children) {
                    let part = literalsOf(child)
                    if (!part.exact || acc.items.size + part.items.size > LITERAL_TOTAL_LIMIT) {
                        return inexactLiterals()
                    }
                    for (item in part.items) {
                        acc.items.add(item)
                    }
                }
                acc
            }
        case ExprKind.Repeat =>
            if (expr.minimum == expr.maximum && expr.minimum == 0) {
                oneEmptyLiteral()
            } else if (expr.minimum == expr.maximum && expr.minimum > 0 && expr.minimum <= LITERAL_REPEAT_LIMIT) {
                let part = literalsOf(expr.children[0])
                var acc = oneEmptyLiteral()
                var i: Int64 = 0
                while (i < expr.minimum) {
                    acc = productLiterals(acc, part)
                    if (!acc.exact) {
                        return acc
                    }
                    i++
                }
                acc
            } else {
                inexactLiterals()
            }
        case _ => inexactLiterals()
    }
}

func classLiterals(set: CharSet, bytes: Bool): LitAcc {
    let count = population(set)
    if (count == 0 || count > LITERAL_CLASS_LIMIT) {
        return inexactLiterals()
    }
    let acc = LitAcc()
    for (i in 0..set.rangeCount()) {
        var code = set.rangeLow(i)
        let high = set.rangeHigh(i)
        while (code <= high) {
            let item = ArrayList<UInt8>()
            if (bytes) {
                item.add(UInt8(code))
            } else {
                for (byte in utf8Of(code)) {
                    item.add(byte)
                }
            }
            acc.items.add(item)
            code++
        }
    }
    acc
}

func literalBytes(expr: Expr): ArrayList<UInt8> {
    if (expr.byteAtom) {
        let item = ArrayList<UInt8>()
        item.add(UInt8(UInt32(expr.ch)))
        return item
    }
    utf8Of(Int64(UInt32(expr.ch)))
}

func oneEmptyLiteral(): LitAcc {
    let acc = LitAcc()
    acc.items.add(ArrayList<UInt8>())
    acc
}

func inexactLiterals(): LitAcc {
    let acc = LitAcc()
    acc.exact = false
    acc
}

func productLiterals(left: LitAcc, right: LitAcc): LitAcc {
    if (!left.exact || !right.exact || left.items.size > LITERAL_TOTAL_LIMIT || right.items.size > LITERAL_TOTAL_LIMIT) {
        return inexactLiterals()
    }
    if (left.items.size * right.items.size > LITERAL_TOTAL_LIMIT) {
        return inexactLiterals()
    }
    let acc = LitAcc()
    for (prefix in left.items) {
        for (suffix in right.items) {
            if (prefix.size + suffix.size > LITERAL_LENGTH_LIMIT) {
                return inexactLiterals()
            }
            let both = ArrayList<UInt8>()
            for (byte in prefix) {
                both.add(byte)
            }
            for (byte in suffix) {
                both.add(byte)
            }
            acc.items.add(both)
        }
    }
    acc
}

func population(set: CharSet): Int64 {
    var count: Int64 = 0
    for (i in 0..set.rangeCount()) {
        count += set.rangeHigh(i) - set.rangeLow(i) + 1
        if (count > LITERAL_CLASS_LIMIT) {
            return count
        }
    }
    count
}

func utf8Length(code: Int64): Int64 {
    if (code <= 0x7F) {
        1
    } else if (code <= 0x7FF) {
        2
    } else if (code <= 0xFFFF) {
        3
    } else {
        4
    }
}

func utf8Of(code: Int64): ArrayList<UInt8> {
    let out = ArrayList<UInt8>()
    if (code <= 0x7F) {
        out.add(UInt8(code))
    } else if (code <= 0x7FF) {
        out.add(UInt8(0xC0 + (code >> 6)))
        out.add(UInt8(0x80 + (code & 0x3F)))
    } else if (code <= 0xFFFF) {
        out.add(UInt8(0xE0 + (code >> 12)))
        out.add(UInt8(0x80 + ((code >> 6) & 0x3F)))
        out.add(UInt8(0x80 + (code & 0x3F)))
    } else {
        out.add(UInt8(0xF0 + (code >> 18)))
        out.add(UInt8(0x80 + ((code >> 12) & 0x3F)))
        out.add(UInt8(0x80 + ((code >> 6) & 0x3F)))
        out.add(UInt8(0x80 + (code & 0x3F)))
    }
    out
}

func utf8Sequences(low: Int64, high: Int64): ArrayList<ArrayList<ByteSpan>> {
    let out = ArrayList<ArrayList<ByteSpan>>()
    let stack = ArrayList<ScalarSpan>()
    stack.add(ScalarSpan(low, high))
    while (!stack.isEmpty()) {
        var range = stack.remove(at: stack.size - 1)
        while (true) {
            if (range.start < 0xE000 && range.end > 0xD7FF) {
                stack.add(ScalarSpan(0xE000, range.end))
                range = ScalarSpan(range.start, 0xD7FF)
                continue
            }
            if (range.start > range.end) {
                break
            }
            var split = false
            for (i in 1..4) {
                let maxValue = maxScalar(i)
                if (range.start <= maxValue && maxValue < range.end) {
                    stack.add(ScalarSpan(maxValue + 1, range.end))
                    range = ScalarSpan(range.start, maxValue)
                    split = true
                    break
                }
            }
            if (split) {
                continue
            }
            if (range.end <= 0x7F) {
                let seq = ArrayList<ByteSpan>()
                seq.add(ByteSpan(range.start, range.end))
                out.add(seq)
                break
            }
            for (i in 1..4) {
                let mask = (1 << (6 * i)) - 1
                let inverted = bitNot32(mask)
                if ((range.start & inverted) != (range.end & inverted)) {
                    if ((range.start & mask) != 0) {
                        stack.add(ScalarSpan((range.start | mask) + 1, range.end))
                        range = ScalarSpan(range.start, range.start | mask)
                        split = true
                        break
                    }
                    if ((range.end & mask) != mask) {
                        stack.add(ScalarSpan(range.end & inverted, range.end))
                        range = ScalarSpan(range.start, (range.end & inverted) - 1)
                        split = true
                        break
                    }
                }
            }
            if (split) {
                continue
            }
            out.add(encodeScalarRange(range.start, range.end))
            break
        }
    }
    out
}

func encodeScalarRange(start: Int64, end: Int64): ArrayList<ByteSpan> {
    let left = utf8Of(start)
    let right = utf8Of(end)
    let seq = ArrayList<ByteSpan>()
    for (i in 0..left.size) {
        seq.add(ByteSpan(Int64(left[i]), Int64(right[i])))
    }
    seq
}

func maxScalar(nbytes: Int64): Int64 {
    if (nbytes == 1) {
        0x7F
    } else if (nbytes == 2) {
        0x7FF
    } else if (nbytes == 3) {
        0xFFFF
    } else {
        0x10FFFF
    }
}

func bitNot32(value: Int64): Int64 {
    (value ^ 0xFFFFFFFF) & 0xFFFFFFFF
}

func fnvInit(): UInt64 {
    (UInt64(0xCBF29CE4) << 32) | UInt64(0x84222325)
}

func fnvPrime(): UInt64 {
    (UInt64(0x100) << 32) | UInt64(0x1B3)
}

func fnvMix(hash: UInt64, value: UInt64): UInt64 {
    mul64(xor64(hash, value), fnvPrime())
}

func xor64(left: UInt64, right: UInt64): UInt64 {
    left ^ right
}

func mul64(left: UInt64, right: UInt64): UInt64 {
    let mask = UInt64(0xFFFFFFFF)
    let a0 = left & mask
    let a1 = left >> 32
    let b0 = right & mask
    let b1 = right >> 32
    let low = a0 * b0
    let mid0 = (a0 * b1) & mask
    let mid1 = (a1 * b0) & mask
    let mid = (mid0 + mid1) & mask
    add64(low, mid << 32)
}

func add64(left: UInt64, right: UInt64): UInt64 {
    let max = (UInt64(0xFFFFFFFF) << 32) | UInt64(0xFFFFFFFF)
    if (left > max - right) {
        return (left - (max - right)) - UInt64(1)
    }
    left + right
}
