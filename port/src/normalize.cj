package cjregex

// Mirrors HIR repetition's empty-only simplification. Width categories are
// -1: cannot match, 0: can only match empty, 1: can consume input (not a length).
// Assertions are conservatively treated as zero-width, as in HIR properties.
func normalizeWidth(expr: Expr): Int64 {
    match (expr.kind) {
        case ExprKind.Empty | ExprKind.Begin | ExprKind.End | ExprKind.WordBoundary => return 0
        case ExprKind.Literal | ExprKind.Any => return 1
        case ExprKind.CharacterClass => return if (expr.charset.isEmpty()) {
            -1
        } else {
            1
        }
        case ExprKind.Capture => return normalizeWidth(expr.children[0])
        case ExprKind.Concat =>
            var width: Int64 = 0
            for (child in expr.children) {
                let next = normalizeWidth(child)
                if (next < 0) {
                    width = -1
                } else if (width >= 0 && next > 0) {
                    width = 1
                }
            }
            return width
        case ExprKind.Alternate =>
            var width: Int64 = -1
            for (child in expr.children) {
                let next = normalizeWidth(child)
                if (next > width) {
                    width = next
                }
            }
            return width
        case ExprKind.Repeat =>
            let width = normalizeWidth(expr.children[0])
            if (width == 0) {
                if (expr.minimum > 1) {
                    expr.minimum = 1
                }
                if (expr.maximum < 0 || expr.maximum > 1) {
                    expr.maximum = 1
                }
            }
            if (expr.maximum == 0) {
                return 0
            }
            if (width < 0) {
                return if (expr.minimum == 0) {
                    0
                } else {
                    -1
                }
            }
            return width
    }
}
