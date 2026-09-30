package cjregex

import std.collection.*

// Scalar interval representation corresponding to regex-syntax HIR classes.
// Unicode shorthand tables use the same normalized scalar range representation.
class CodeRange {
    let low: Int64
    let high: Int64
    init(low: Int64, high: Int64) {
        this.low = low
        this.high = high
    }
}

class CharSet {
    private var ranges = ArrayList<CodeRange>()

    init() {}
    // Validated, sorted generated pairs; linear construction avoids repeated union.
    init(data: Array<Int64>) {
        if (data.size % 2 != 0) {
            throw Exception("invalid scalar range pairs")
        }
        var i: Int64 = 0
        var last: Int64 = -1
        while (i < data.size) {
            let low = data[i]
            let high = data[i + 1]
            if (low <= last || low < 0 || high < low || high > 0x10FFFF || (low <= 0xDFFF && high >= 0xD800)) {
                throw Exception("invalid scalar range table")
            }
            ranges.add(CodeRange(low, high))
            last = high
            i += 2
        }
    }

    // Keep ranges sorted, disjoint and non-adjacent. Exclude surrogate code points.
    func addRange(low: Int64, high: Int64): Unit {
        if (low > high) {
            return
        }
        if (low <= 0xDFFF && high >= 0xD800) {
            if (low < 0xD800) {
                insert(low, 0xD7FF)
            }
            if (high > 0xDFFF) {
                insert(0xE000, high)
            }
        } else {
            insert(low, high)
        }
    }
    private func insert(low: Int64, high: Int64): Unit {
        let merged = ArrayList<CodeRange>()
        var a = low
        var b = high
        var written = false
        for (range in ranges) {
            if (range.high + 1 < a) {
                merged.add(range)
            } else if (b + 1 < range.low) {
                if (!written) {
                    merged.add(CodeRange(a, b));
                    written = true
                }
                merged.add(range)
            } else {
                if (range.low < a) {
                    a = range.low
                }
                if (range.high > b) {
                    b = range.high
                }
            }
        }
        if (!written) {
            merged.add(CodeRange(a, b))
        }
        ranges = merged
    }
    func isEmpty(): Bool {
        ranges.isEmpty()
    }
    func contains(c: Rune): Bool {
        let code = Int64(UInt32(c))
        var lo: Int64 = 0
        var hi = ranges.size
        while (lo < hi) {
            let mid = lo + (hi - lo) / 2
            let range = ranges[mid]
            if (code < range.low) {
                hi = mid
            } else if (code > range.high) {
                lo = mid + 1
            } else {
                return true
            }
        }
        return false
    }
    func unionWith(other: CharSet): Unit {
        for (range in other.ranges) {
            addRange(range.low, range.high)
        }
    }
    func intersect(other: CharSet): CharSet {
        let result = CharSet()
        var i: Int64 = 0
        var j: Int64 = 0
        while (i < ranges.size && j < other.ranges.size) {
            let a = ranges[i]
            let b = other.ranges[j]
            let low = if (a.low > b.low) {
                a.low
            } else {
                b.low
            }
            let high = if (a.high < b.high) {
                a.high
            } else {
                b.high
            }
            if (low <= high) {
                result.ranges.add(CodeRange(low, high))
            }
            if (a.high < b.high) {
                i++
            } else {
                j++
            }
        }
        return result
    }
    func negated(): CharSet {
        let result = CharSet()
        var start: Int64 = 0
        for (range in ranges) {
            result.addRange(start, range.low - 1)
            start = range.high + 1
        }
        result.addRange(start, 0x10FFFF)
        return result
    }
    func difference(other: CharSet): CharSet {
        intersect(other.negated())
    }
    func symmetricDifference(other: CharSet): CharSet {
        let result = difference(other)
        result.unionWith(other.difference(this))
        return result
    }
    func containsCode(code: Int64): Bool {
        var lo: Int64 = 0
        var hi = ranges.size
        while (lo < hi) {
            let mid = lo + (hi - lo) / 2
            let range = ranges[mid]
            if (code < range.low) {
                hi = mid
            } else if (code > range.high) {
                lo = mid + 1
            } else {
                return true
            }
        }
        return false
    }
    func isOnly(code: Int64): Bool {
        ranges.size == 1 && ranges[0].low == code && ranges[0].high == code
    }
    func exceedsAscii(): Bool {
        for (range in ranges) {
            if (range.high > 127) {
                return true
            }
        }
        return false
    }
    // ASCII case folding used when Unicode mode is off. Only A-Z and a-z move.
    func caseFoldAscii(): Unit {
        let extra = CharSet()
        for (range in ranges) {
            let upperLow = if (range.low > 65) { range.low } else { 65 }
            let upperHigh = if (range.high < 90) { range.high } else { 90 }
            if (upperLow <= upperHigh) {
                extra.addRange(upperLow + 32, upperHigh + 32)
            }
            let lowerLow = if (range.low > 97) { range.low } else { 97 }
            let lowerHigh = if (range.high < 122) { range.high } else { 122 }
            if (lowerLow <= lowerHigh) {
                extra.addRange(lowerLow - 32, lowerHigh - 32)
            }
        }
        unionWith(extra)
    }
    // Unicode simple case folding, matching regex-syntax ClassUnicodeRange::case_fold_simple.
    // The table stores each scalar's full equivalence class, so one pass closes the set.
    // Callers must fold before negation and before class intersection or difference.
    func caseFoldSimple(): Unit {
        let data = caseFoldTable()
        let extra = CharSet()
        var i: Int64 = 0
        while (i < data.size) {
            let key = data[i]
            let count = data[i + 1]
            i += 2
            if (containsCode(key)) {
                var j: Int64 = 0
                while (j < count) {
                    let fold = data[i + j]
                    extra.addRange(fold, fold)
                    j++
                }
            }
            i += count
        }
        unionWith(extra)
    }
}
