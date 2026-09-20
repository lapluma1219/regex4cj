package cjregex

import std.collection.*

// Scalar interval representation corresponding to regex-syntax HIR classes.
// No Unicode property database is included at this stage.
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
}
