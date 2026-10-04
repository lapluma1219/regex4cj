package cjregex

import std.collection.*

// Byte haystacks, including invalid UTF-8. Patterns that can match a single
// non-ASCII byte are legal here and rejected by the string Regex.
public class BytesMatch {
    public let start: Int64
    public let end: Int64
    public let bytes: Array<UInt8>
    public init(start: Int64, end: Int64, bytes: Array<UInt8>) {
        this.start = start
        this.end = end
        this.bytes = bytes
    }
    public func isEmpty(): Bool {
        start == end
    }
    public func len(): Int64 {
        end - start
    }
}

public class BytesRegex {
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
        options.utf8 = false
        source = pattern
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
        groupNames = Array<String>(last + 1, {
            i => if (live[i]) {
                parser.captureNames[i]
            } else {
                ""
            }
        })
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
    public func asStr(): String {
        source
    }
    public func capturesLen(): Int64 {
        groupNames.size
    }
    public func staticCapturesLen(): Option<Int64> {
        if (staticLen < 0) {
            None
        } else {
            Some(staticLen)
        }
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
    public func captureLocations(): CaptureLocations {
        CaptureLocations(groupNames.size)
    }
    public func find(haystack: Array<UInt8>): Option<BytesMatch> {
        findAt(haystack, 0)
    }
    public func isMatch(haystack: Array<UInt8>): Bool {
        isMatchAt(haystack, 0)
    }
    public func findAt(haystack: Array<UInt8>, start: Int64): Option<BytesMatch> {
        match (search(haystack, start, false, false)) {
            case Some(hit) => Some(matched(haystack, hit))
            case None => None
        }
    }
    public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool {
        match (search(haystack, start, true, false)) {
            case Some(_) => true
            case None => false
        }
    }
    public func shortestMatch(haystack: Array<UInt8>): Option<Int64> {
        shortestMatchAt(haystack, 0)
    }
    public func shortestMatchAt(haystack: Array<UInt8>, start: Int64): Option<Int64> {
        match (search(haystack, start, true, false)) {
            case Some(hit) => Some(hit.end)
            case None => None
        }
    }
    // Iterators snapshot mutable input once; matching itself happens only in next().
    private func matchPull(haystack: Array<UInt8>, capture: Bool): () -> Option<SearchMatch> {
        let cursor = [0]
        let previousEnd = [-1]
        let done = [false]
        return {
            =>
                while (!done[0] && cursor[0] <= haystack.size) {
                    match (search(haystack, cursor[0], false, capture)) {
                        case None => done[0] = true
                        case Some(hit) =>
                            if (hit.start == hit.end && hit.end == previousEnd[0]) {
                                cursor[0] = hit.end + 1
                                continue
                            }
                            previousEnd[0] = hit.end
                            cursor[0] = hit.end
                            return Some(hit)
                    }
                }
                done[0] = true
                return None
        }
    }
    public func findIter(haystack: Array<UInt8>): BytesMatchIter {
        let snapshot = haystack.clone()
        let pull = matchPull(snapshot, false)
        BytesMatchIter({
            => match (pull()) {
                case Some(hit) => Some(matched(snapshot, hit))
                case None => None
            }
        })
    }
    public func capturesIter(haystack: Array<UInt8>): BytesCaptureIter {
        let snapshot = haystack.clone()
        let pull = matchPull(snapshot, true)
        BytesCaptureIter({
            => match (pull()) {
                case Some(hit) => Some(captureResult(snapshot, hit))
                case None => None
            }
        })
    }
    public func splitIter(haystack: Array<UInt8>): BytesSplitIter {
        splitIterator(haystack, 0, false)
    }
    public func splitNIter(haystack: Array<UInt8>, limit: Int64): BytesSplitIter {
        if (limit < 0) {
            throw Exception("split limit must be nonnegative")
        }
        splitIterator(haystack, limit, true)
    }
    private func splitIterator(haystack: Array<UInt8>, limit: Int64, bounded: Bool): BytesSplitIter {
        let snapshot = haystack.clone()
        let pull = matchPull(snapshot, false)
        let last = [0]
        let count = [0]
        let done = [bounded && limit == 0]
        BytesSplitIter(
            {
                =>
                    if (done[0]) {
                        return None
                    }
                    if (!bounded || count[0] < limit - 1) {
                        match (pull()) {
                            case Some(hit) =>
                                let part = Array<UInt8>(hit.start - last[0], {i => snapshot[last[0] + i]})
                                last[0] = hit.end
                                count[0]++
                                return Some(part)
                            case None => ()
                        }
                    }
                    done[0] = true
                    return Some(Array<UInt8>(snapshot.size - last[0], {i => snapshot[last[0] + i]}))
            }
        )
    }
    public func capturesRead(locations: CaptureLocations, haystack: Array<UInt8>): Option<BytesMatch> {
        capturesReadAt(locations, haystack, 0)
    }
    public func findAll(haystack: Array<UInt8>): Array<BytesMatch> {
        let result = ArrayList<BytesMatch>()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        while (cursor <= haystack.size) {
            match (search(haystack, cursor, false, false)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    previousEnd = hit.end
                    cursor = hit.end
                    result.add(matched(haystack, hit))
            }
        }
        return result.toArray()
    }
    private func matched(haystack: Array<UInt8>, hit: SearchMatch): BytesMatch {
        let width = hit.end - hit.start
        let slice = Array<UInt8>(width, {i => haystack[hit.start + i]})
        BytesMatch(hit.start, hit.end, slice)
    }
    private func closure(out: ArrayList<Thread>, seen: Array<Bool>, state: Int64, start: Int64, slots: Array<Int64>,
        pos: Int64, haystack: Array<UInt8>): Unit {
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
                    if (passesLookBytes(mode, pos, haystack, unicodeWords, asciiWords)) {
                        stack.add(Thread(s.first, start, frame.slots))
                    }
                case _ => out.add(frame)
            }
        }
    }
    private func consumeWidth(state: State, haystack: Array<UInt8>, pos: Int64): Int64 {
        byteConsumeWidth(state, haystack, pos)
    }
    private func search(haystack: Array<UInt8>, from: Int64, earliest: Bool, capture: Bool): Option<SearchMatch> {
        if (from < 0 || from > haystack.size) {
            throw Exception("search start is outside the haystack")
        }
        let limit = haystack.size
        let buckets = ArrayList<ArrayList<Thread>>()
        let seens = ArrayList<Array<Bool>>()
        var index: Int64 = 0
        while (index <= limit) {
            buckets.add(ArrayList<Thread>())
            seens.add(Array<Bool>(states.size, repeat: false))
            index++
        }
        let slots = Array<Int64>(if (capture) {
            groupNames.size * 2
        } else {
            0
        }, repeat: -1)
        var best: Option<SearchMatch> = None
        var found = false
        var pos = from
        while (pos <= limit) {
            if (!found) {
                closure(buckets[pos], seens[pos], startState, pos, slots, pos, haystack)
            }
            var halt = false
            for (thread in buckets[pos]) {
                if (halt) {
                    break
                }
                let s = states[thread.state]
                match (s.op) {
                    case Op.Accept =>
                        let hit = SearchMatch(thread.start, pos, thread.slots)
                        if (earliest) {
                            return Some(hit)
                        }
                        best = Some(hit)
                        found = true
                        halt = true
                    case _ =>
                        let width = consumeWidth(s, haystack, pos)
                        if (width > 0) {
                            closure(buckets[pos + width], seens[pos + width], s.first, thread.start, thread.slots,
                                pos + width, haystack)
                        }
                }
            }
            if (found) {
                var later = false
                var look = pos + 1
                while (look <= limit) {
                    if (!buckets[look].isEmpty()) {
                        later = true
                        break
                    }
                    look++
                }
                if (!later) {
                    return best
                }
            }
            pos++
        }
        return best
    }
    public func captures(haystack: Array<UInt8>): Option<BytesCaptures> {
        capturesAt(haystack, 0)
    }
    public func capturesAt(haystack: Array<UInt8>, start: Int64): Option<BytesCaptures> {
        match (search(haystack, start, false, true)) {
            case Some(hit) => Some(captureResult(haystack, hit))
            case None => None
        }
    }
    public func capturesAll(haystack: Array<UInt8>): Array<BytesCaptures> {
        let result = ArrayList<BytesCaptures>()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        while (cursor <= haystack.size) {
            match (search(haystack, cursor, false, true)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    result.add(captureResult(haystack, hit))
                    previousEnd = hit.end
                    cursor = hit.end
            }
        }
        return result.toArray()
    }
    public func capturesReadAt(locations: CaptureLocations, haystack: Array<UInt8>, start: Int64): Option<BytesMatch> {
        if (locations.size != groupNames.size) {
            throw Exception("capture locations were not created by this regex")
        }
        match (search(haystack, start, false, true)) {
            case None =>
                for (i in 0..locations.size) {
                    locations.clear(i)
                }
                None
            case Some(hit) =>
                locations.write(0, hit.start, hit.end)
                for (i in 1..groupNames.size) {
                    let a = hit.slots[i * 2]
                    let b = hit.slots[i * 2 + 1]
                    if (a >= 0 && b >= 0) {
                        locations.write(i, a, b)
                    } else {
                        locations.clear(i)
                    }
                }
                Some(matched(haystack, hit))
        }
    }
    public func replace(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8> {
        replaceN(haystack, 1, replacement)
    }
    public func replaceAll(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8> {
        replaceN(haystack, 0, replacement)
    }
    public func replaceN(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8> {
        var expansion = false
        for (byte in replacement) {
            if (byte == UInt8(36)) {
                expansion = true
                break
            }
        }
        if (!expansion) {
            return replaceLiteral(haystack, limit, replacement)
        }
        return replaceWith(haystack, limit, {caps => caps.expand(replacement)})
    }
    public func replaceLiteral(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8> {
        replaceImpl(haystack, limit, false, {_ => replacement})
    }
    public func replaceWith(haystack: Array<UInt8>, limit: Int64, replacer: (BytesCaptures) -> Array<UInt8>): Array<UInt8> {
        replaceImpl(haystack, limit, true, {hit => replacer(captureResult(haystack, hit))})
    }
    public func split(haystack: Array<UInt8>): Array<Array<UInt8>> {
        splitImpl(haystack, 0, false)
    }
    public func splitN(haystack: Array<UInt8>, limit: Int64): Array<Array<UInt8>> {
        if (limit < 0) {
            throw Exception("split limit must be nonnegative")
        }
        splitImpl(haystack, limit, true)
    }
    private func captureResult(haystack: Array<UInt8>, hit: SearchMatch): BytesCaptures {
        let groups = Array<Option<BytesMatch>>(groupNames.size, repeat: None)
        groups[0] = Some(matched(haystack, hit))
        for (i in 1..groupNames.size) {
            let a = hit.slots[i * 2]
            let b = hit.slots[i * 2 + 1]
            if (a >= 0 && b >= 0) {
                let width = b - a
                let slice = Array<UInt8>(width, {n => haystack[a + n]})
                groups[i] = Some(BytesMatch(a, b, slice))
            }
        }
        BytesCaptures(groups, groupNames, staticLen)
    }
    private func replaceImpl(haystack: Array<UInt8>, limit: Int64, capture: Bool, render: (SearchMatch) -> Array<UInt8>): Array<UInt8> {
        if (limit < 0) {
            throw Exception("replacement limit must be nonnegative")
        }
        let out = ArrayList<UInt8>()
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        var last: Int64 = 0
        var count: Int64 = 0
        while (cursor <= haystack.size && (limit == 0 || count < limit)) {
            match (search(haystack, cursor, false, capture)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    appendBytes(out, haystack, last, hit.start)
                    let piece = render(hit)
                    appendBytes(out, piece, 0, piece.size)
                    last = hit.end
                    previousEnd = hit.end
                    cursor = hit.end
                    count++
            }
        }
        appendBytes(out, haystack, last, haystack.size)
        return out.toArray()
    }
    private func splitImpl(haystack: Array<UInt8>, limit: Int64, bounded: Bool): Array<Array<UInt8>> {
        let result = ArrayList<Array<UInt8>>()
        if (bounded && limit == 0) {
            return result.toArray()
        }
        if (bounded && limit == 1) {
            result.add(copyBytes(haystack, 0, haystack.size))
            return result.toArray()
        }
        var cursor: Int64 = 0
        var previousEnd: Int64 = -1
        var last: Int64 = 0
        while (cursor <= haystack.size && (!bounded || result.size < limit - 1)) {
            match (search(haystack, cursor, false, false)) {
                case None => break
                case Some(hit) =>
                    if (hit.start == hit.end && hit.end == previousEnd) {
                        cursor = hit.end + 1
                        continue
                    }
                    result.add(copyBytes(haystack, last, hit.start))
                    last = hit.end
                    previousEnd = hit.end
                    cursor = hit.end
            }
        }
        result.add(copyBytes(haystack, last, haystack.size))
        return result.toArray()
    }
}

func copyBytes(bytes: Array<UInt8>, start: Int64, end: Int64): Array<UInt8> {
    Array<UInt8>(end - start, {i => bytes[start + i]})
}

func appendBytes(out: ArrayList<UInt8>, bytes: Array<UInt8>, start: Int64, end: Int64): Unit {
    var i = start
    while (i < end) {
        out.add(bytes[i])
        i++
    }
}

func byteConsumeWidth(state: State, haystack: Array<UInt8>, pos: Int64): Int64 {
    match (state.op) {
        case Op.Literal(c) =>
            if (state.byteAtom) {
                if (pos < haystack.size && Int64(haystack[pos]) == Int64(UInt32(c))) {
                    return 1
                }
                return 0
            }
            match (decodeForward(haystack, pos, haystack.size)) {
                case Some(decoded) =>
                    if (decoded.char == c) {
                        return decoded.width
                    }
                    return 0
                case None => return 0
            }
        case Op.CharacterClass(set) =>
            if (state.byteAtom) {
                if ((if (pos < haystack.size) {
                    set.contains(Rune(UInt32(haystack[pos])))
                } else {
                    false
                })) {
                    return 1
                }
                return 0
            }
            match (decodeForward(haystack, pos, haystack.size)) {
                case Some(decoded) =>
                    if (set.contains(decoded.char)) {
                        return decoded.width
                    }
                    return 0
                case None => return 0
            }
        case Op.Any(mode) =>
            if (state.byteAtom) {
                if (pos < haystack.size && passesDot(mode, Rune(UInt32(haystack[pos])))) {
                    return 1
                }
                return 0
            }
            match (decodeForward(haystack, pos, haystack.size)) {
                case Some(decoded) =>
                    if (passesDot(mode, decoded.char)) {
                        return decoded.width
                    }
                    return 0
                case None => return 0
            }
        case _ => return 0
    }
}

func sameBytes(left: Array<UInt8>, right: Array<UInt8>): Bool {
    if (left.size != right.size) {
        return false
    }
    for (i in 0..left.size) {
        if (left[i] != right[i]) {
            return false
        }
    }
    return true
}

public class BytesCaptures {
    private let groups: Array<Option<BytesMatch>>
    private let names: Array<String>
    private let staticLen: Int64
    public let size: Int64
    init(groups: Array<Option<BytesMatch>>, names: Array<String>, staticLen: Int64) {
        this.groups = groups
        this.names = names
        this.staticLen = staticLen
        this.size = groups.size
    }
    public func getMatch(): BytesMatch {
        match (get(0)) {
            case Some(item) => item
            case None => throw Exception("capture has no match")
        }
    }
    public func get(index: Int64): Option<BytesMatch> {
        if (index < 0 || index >= size) {
            return None
        }
        return groups[index]
    }
    public func iter(): BytesGroupIter {
        BytesGroupIter(groups)
    }
    public func extract(count: Int64): Array<Array<UInt8>> {
        if (staticLen < 0) {
            throw Exception("the number of capture groups can vary in a match")
        }
        if (count != staticLen - 1) {
            throw Exception("extract asked for ${count} groups, but must ask for ${staticLen - 1}")
        }
        let whole = getMatch()
        let matched = ArrayList<Array<UInt8>>()
        for (i in 1..size) {
            match (get(i)) {
                case Some(item) => matched.add(item.bytes)
                case None => ()
            }
        }
        if (matched.size < count) {
            throw Exception("too few matching groups")
        }
        return Array<Array<UInt8>>(count + 1, {
            i => if (i == 0) {
                whole.bytes
            } else {
                matched[i - 1]
            }
        })
    }
    public func name(value: String): Option<BytesMatch> {
        if (value == "") {
            return None
        }
        let key = value.toArray()
        for (i in 1..names.size) {
            if (names[i] != "" && sameBytes(names[i].toArray(), key)) {
                return groups[i]
            }
        }
        return None
    }
    public func expand(template: Array<UInt8>): Array<UInt8> {
        let out = ArrayList<UInt8>()
        expandInto(template, out)
        return out.toArray()
    }
    public func expandInto(template: Array<UInt8>, out: ArrayList<UInt8>): Unit {
        var i: Int64 = 0
        while (i < template.size) {
            if (template[i] != UInt8(36)) {
                out.add(template[i])
                i++
                continue
            }
            if (i + 1 < template.size && template[i + 1] == UInt8(36)) {
                out.add(UInt8(36))
                i += 2
                continue
            }
            var begin = i + 1
            var end = begin
            let braced = begin < template.size && template[i + 1] == UInt8(123)
            if (braced) {
                begin++
                end = begin
                while (end < template.size && template[end] != UInt8(125)) {
                    end++
                }
                if (end == template.size) {
                    out.add(UInt8(36))
                    i++
                    continue
                }
            } else {
                while (end < template.size && referenceByte(template[end])) {
                    end++
                }
                if (end == begin) {
                    out.add(UInt8(36))
                    i++
                    continue
                }
            }
            let key = copyBytes(template, begin, end)
            var digit = 0
            if (key.size > 0 && key[0] == UInt8(43)) {
                digit = 1
            }
            var numeric = digit < key.size
            var index: Int64 = 0
            while (digit < key.size) {
                let c = key[digit]
                if (c < UInt8(48) || c > UInt8(57)) {
                    numeric = false
                    break
                }
                if (index <= size) {
                    index = index * 10 + Int64(c) - 48
                }
                digit++
            }
            let value = if (numeric) {
                get(index)
            } else {
                named(key)
            }
            match (value) {
                case Some(item) => appendBytes(out, item.bytes, 0, item.bytes.size)
                case None => ()
            }
            i = if (braced) {
                end + 1
            } else {
                end
            }
        }
    }
    private func named(key: Array<UInt8>): Option<BytesMatch> {
        for (i in 1..names.size) {
            if (names[i] != "" && sameBytes(names[i].toArray(), key)) {
                return groups[i]
            }
        }
        return None
    }
}

public class BytesGroupItem {
    public let done: Bool
    public let value: Option<BytesMatch>
    init(done: Bool, value: Option<BytesMatch>) {
        this.done = done
        this.value = value
    }
}

public class BytesGroupIter {
    private let groups: Array<Option<BytesMatch>>
    private var index: Int64 = 0
    init(groups: Array<Option<BytesMatch>>) {
        this.groups = groups
    }
    // Remaining slots include groups that did not participate in the match.
    public func len(): Int64 {
        groups.size - index
    }
    public func sizeHint(): (Int64, Option<Int64>) {
        (len(), Some(len()))
    }
    public func clone(): BytesGroupIter {
        let copy = BytesGroupIter(groups)
        copy.index = index
        return copy
    }
    public func next(): BytesGroupItem {
        if (index >= groups.size) {
            return BytesGroupItem(true, None)
        }
        let value = groups[index]
        index++
        BytesGroupItem(false, value)
    }
}

func referenceByte(byte: UInt8): Bool {
    (byte >= UInt8(48) && byte <= UInt8(57)) || (byte >= UInt8(65) && byte <= UInt8(90)) || (byte >= UInt8(97) &&
        byte <= UInt8(122)) || byte == UInt8(95)
}

public class BytesRegexSet {
    private let sourcePatterns: Array<String>
    private let states: Array<State>
    private let starts: Array<Int64>
    private let unicodeWords: CharSet
    private let asciiWords: CharSet

    public init(patterns: Array<String>) {
        this(patterns, PatternOptions())
    }
    init(patterns: Array<String>, options: PatternOptions) {
        options.utf8 = false
        sourcePatterns = patterns.clone()
        let trees = ArrayList<Expr>()
        for (i in 0..patterns.size) {
            let tree = Parser(patterns[i], options).parse()
            normalizeWidth(tree)
            trees.add(tree)
        }
        ensureWithinSizeLimit(trees.toArray(), options.sizeLimit, false)
        let compiler = Compiler(options.sizeLimit)
        let roots = ArrayList<Int64>()
        for (i in 0..trees.size) {
            let accept = compiler.add(Op.Accept, i, -1)
            roots.add(compiler.compile(trees[i], accept))
        }
        states = compiler.states.toArray()
        starts = roots.toArray()
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
    public func len(): Int64 {
        sourcePatterns.size
    }
    public func isEmpty(): Bool {
        sourcePatterns.isEmpty()
    }
    public func patterns(): Array<String> {
        sourcePatterns.clone()
    }
    public func isMatch(haystack: Array<UInt8>): Bool {
        isMatchAt(haystack, 0)
    }
    public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool {
        scan(haystack, start, true).matchedAny()
    }
    public func matches(haystack: Array<UInt8>): SetMatches {
        matchesAt(haystack, 0)
    }
    public func matchesAt(haystack: Array<UInt8>, start: Int64): SetMatches {
        scan(haystack, start, false)
    }
    public func matchesReadAt(slots: Array<Bool>, haystack: Array<UInt8>, start: Int64): Bool {
        let found = scan(haystack, start, false)
        var any = false
        for (i in 0..starts.size) {
            if (found.matched(i)) {
                if (i >= slots.size) {
                    throw Exception("match index out of bounds")
                }
                slots[i] = true
                any = true
            }
        }
        return any
    }
    private func closure(out: ArrayList<Int64>, seen: Array<Bool>, root: Int64, pos: Int64, haystack: Array<UInt8>): Unit {
        let stack = ArrayList<Int64>()
        stack.add(root)
        while (!stack.isEmpty()) {
            let id = stack.remove(at: stack.size - 1)
            if (seen[id]) {
                continue
            }
            seen[id] = true
            let state = states[id]
            match (state.op) {
                case Op.Split =>
                    stack.add(state.second)
                    stack.add(state.first)
                case Op.Save(_) => stack.add(state.first)
                case Op.Look(mode) =>
                    if (passesLookBytes(mode, pos, haystack, unicodeWords, asciiWords)) {
                        stack.add(state.first)
                    }
                case _ => out.add(id)
            }
        }
    }
    private func scan(haystack: Array<UInt8>, from: Int64, stopAtFirst: Bool): SetMatches {
        if (from < 0 || from > haystack.size) {
            throw Exception("search start is outside the haystack")
        }
        let hits = Array<Bool>(starts.size, repeat: false)
        if (starts.isEmpty()) {
            return SetMatches(hits)
        }
        let limit = haystack.size
        let buckets = ArrayList<ArrayList<Int64>>()
        let seens = ArrayList<Array<Bool>>()
        var index: Int64 = 0
        while (index <= limit) {
            buckets.add(ArrayList<Int64>())
            seens.add(Array<Bool>(states.size, repeat: false))
            index++
        }
        var count: Int64 = 0
        var pos = from
        while (pos <= limit) {
            for (i in 0..starts.size) {
                if (!hits[i]) {
                    closure(buckets[pos], seens[pos], starts[i], pos, haystack)
                }
            }
            for (id in buckets[pos]) {
                let state = states[id]
                match (state.op) {
                    case Op.Accept =>
                        if (!hits[state.first]) {
                            hits[state.first] = true
                            count++
                            if (stopAtFirst || count == starts.size) {
                                return SetMatches(hits)
                            }
                        }
                    case _ =>
                        let width = byteConsumeWidth(state, haystack, pos)
                        if (width > 0) {
                            closure(buckets[pos + width], seens[pos + width], state.first, pos + width, haystack)
                        }
                }
            }
            pos++
        }
        return SetMatches(hits)
    }
}

public class BytesMatchIter {
    private let pull: () -> Option<BytesMatch>
    public init(pull: () -> Option<BytesMatch>) {
        this.pull = pull
    }
    public func next(): Option<BytesMatch> {
        pull()
    }
}

public class BytesCaptureIter {
    private let pull: () -> Option<BytesCaptures>
    public init(pull: () -> Option<BytesCaptures>) {
        this.pull = pull
    }
    public func next(): Option<BytesCaptures> {
        pull()
    }
}

public class BytesSplitIter {
    private let pull: () -> Option<Array<UInt8>>
    public init(pull: () -> Option<Array<UInt8>>) {
        this.pull = pull
    }
    public func next(): Option<Array<UInt8>> {
        pull()
    }
}
