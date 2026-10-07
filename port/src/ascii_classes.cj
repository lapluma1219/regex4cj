package regex4cj

// Adapted from regex-syntax hir::translate::ascii_class at the pinned revision.
// Positive POSIX classes are ASCII; negation uses the Unicode scalar universe.
func asciiClass(name: String): Option<CharSet> {
    let ranges: Array<Array<Int64>> = match (name) {
        case "alnum" => [[48, 57], [65, 90], [97, 122]]
        case "alpha" => [[65, 90], [97, 122]]
        case "ascii" => [[0, 127]]
        case "blank" => [[9, 9], [32, 32]]
        case "cntrl" => [[0, 31], [127, 127]]
        case "digit" => [[48, 57]]
        case "graph" => [[33, 126]]
        case "lower" => [[97, 122]]
        case "print" => [[32, 126]]
        case "punct" => [[33, 47], [58, 64], [91, 96], [123, 126]]
        case "space" => [[9, 13], [32, 32]]
        case "upper" => [[65, 90]]
        case "word" => [[48, 57], [65, 90], [95, 95], [97, 122]]
        case "xdigit" => [[48, 57], [65, 70], [97, 102]]
        case _ => return None
    }
    let result = CharSet()
    for (range in ranges) {
        result.addRange(range[0], range[1])
    }
    return Some(result)
}
