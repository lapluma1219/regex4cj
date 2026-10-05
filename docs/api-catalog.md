# 当前仓颉公开接口清单

由`scripts/generate_api_catalog.py`从仓库源码生成；可用`--check`检查是否过期。

当前显式公开调用入口 **303** 个，公开字段（含var） **96** 个；类型数量见下表。重复名称在不同类型/重载上分别计数，不计继承方法，不把枚举分支当作函数。

这是声明扫描，不是完整语言解析器，也不是原仓库覆盖率。主要库的170条固有方法映射仍见[接口审计](api-audit.md)，语法/自动机的差异见[当前边界](status.md)。调用行为见[API](api.md)与[语法说明](hir.md)。

| 类别 | 数量 |
|---|---:|
| class | 49 |
| constructor | 36 |
| enum | 4 |
| field | 96 |
| function | 7 |
| method | 260 |

## Ast

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Ast` | class | [port/src/syntax_ast.cj:97](../port/src/syntax_ast.cj#L97) |
| `public let label: String` | field | [port/src/syntax_ast.cj:98](../port/src/syntax_ast.cj#L98) |
| `public let span: AstSpan` | field | [port/src/syntax_ast.cj:99](../port/src/syntax_ast.cj#L99) |
| `public var code: Int64` | field | [port/src/syntax_ast.cj:100](../port/src/syntax_ast.cj#L100) |
| `public var greedy: Bool` | field | [port/src/syntax_ast.cj:101](../port/src/syntax_ast.cj#L101) |
| `public var negated: Bool` | field | [port/src/syntax_ast.cj:102](../port/src/syntax_ast.cj#L102) |
| `public var captureIndex: Int64` | field | [port/src/syntax_ast.cj:103](../port/src/syntax_ast.cj#L103) |
| `public var captureName: String` | field | [port/src/syntax_ast.cj:104](../port/src/syntax_ast.cj#L104) |
| `public var startsWithP: Bool` | field | [port/src/syntax_ast.cj:105](../port/src/syntax_ast.cj#L105) |
| `public var quantifier: String` | field | [port/src/syntax_ast.cj:106](../port/src/syntax_ast.cj#L106) |
| `public var minimum: Int64` | field | [port/src/syntax_ast.cj:107](../port/src/syntax_ast.cj#L107) |
| `public var maximum: Int64` | field | [port/src/syntax_ast.cj:108](../port/src/syntax_ast.cj#L108) |
| `public var classItem: AstClassItem` | field | [port/src/syntax_ast.cj:109](../port/src/syntax_ast.cj#L109) |
| `public var flagMask: Int64` | field | [port/src/syntax_ast.cj:115](../port/src/syntax_ast.cj#L115) |
| `public var flagValue: Int64` | field | [port/src/syntax_ast.cj:116](../port/src/syntax_ast.cj#L116) |
| `public var baseCaseInsensitive: Bool` | field | [port/src/syntax_ast.cj:117](../port/src/syntax_ast.cj#L117) |
| `public var baseMultiLine: Bool` | field | [port/src/syntax_ast.cj:118](../port/src/syntax_ast.cj#L118) |
| `public var baseDotAll: Bool` | field | [port/src/syntax_ast.cj:119](../port/src/syntax_ast.cj#L119) |
| `public var baseSwapGreed: Bool` | field | [port/src/syntax_ast.cj:120](../port/src/syntax_ast.cj#L120) |
| `public var baseIgnoreWhitespace: Bool` | field | [port/src/syntax_ast.cj:121](../port/src/syntax_ast.cj#L121) |
| `public var baseCrlf: Bool` | field | [port/src/syntax_ast.cj:122](../port/src/syntax_ast.cj#L122) |
| `public var baseUnicode: Bool` | field | [port/src/syntax_ast.cj:123](../port/src/syntax_ast.cj#L123) |
| `public var source: String` | field | [port/src/syntax_ast.cj:124](../port/src/syntax_ast.cj#L124) |
| `public func subs(): Array<Ast>` | method | [port/src/syntax_ast.cj:151](../port/src/syntax_ast.cj#L151) |
| `public func visit(enter: (Ast) -> Unit): Unit` | method | [port/src/syntax_ast.cj:154](../port/src/syntax_ast.cj#L154) |
| `public func walk(enter: (Ast) -> Unit, leave: (Ast) -> Unit): Unit` | method | [port/src/syntax_ast.cj:160](../port/src/syntax_ast.cj#L160) |
| `public func walkUntil(enter: (Ast) -> Bool, leave: (Ast) -> Bool): Bool` | method | [port/src/syntax_ast.cj:168](../port/src/syntax_ast.cj#L168) |
| `public func shape(): String` | method | [port/src/syntax_ast.cj:180](../port/src/syntax_ast.cj#L180) |
| `public func toPattern(): String` | method | [port/src/syntax_ast.cj:197](../port/src/syntax_ast.cj#L197) |
| `public func toHir(): Hir` | method | [port/src/syntax_ast.cj:202](../port/src/syntax_ast.cj#L202) |
| `public static func parse(pattern: String): Ast` | method | [port/src/syntax_ast.cj:205](../port/src/syntax_ast.cj#L205) |

## AstClassItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class AstClassItem` | class | [port/src/syntax_ast.cj:29](../port/src/syntax_ast.cj#L29) |
| `public let label: String` | field | [port/src/syntax_ast.cj:30](../port/src/syntax_ast.cj#L30) |
| `public let span: AstSpan` | field | [port/src/syntax_ast.cj:31](../port/src/syntax_ast.cj#L31) |
| `public let startSpan: AstSpan` | field | [port/src/syntax_ast.cj:33](../port/src/syntax_ast.cj#L33) |
| `public let origin: String` | field | [port/src/syntax_ast.cj:34](../port/src/syntax_ast.cj#L34) |
| `public let endSpan: AstSpan` | field | [port/src/syntax_ast.cj:35](../port/src/syntax_ast.cj#L35) |
| `public let endOrigin: String` | field | [port/src/syntax_ast.cj:36](../port/src/syntax_ast.cj#L36) |
| `public let start: Int64` | field | [port/src/syntax_ast.cj:37](../port/src/syntax_ast.cj#L37) |
| `public let end: Int64` | field | [port/src/syntax_ast.cj:38](../port/src/syntax_ast.cj#L38) |
| `public let negated: Bool` | field | [port/src/syntax_ast.cj:39](../port/src/syntax_ast.cj#L39) |
| `public let children: Array<AstClassItem>` | field | [port/src/syntax_ast.cj:40](../port/src/syntax_ast.cj#L40) |
| `public let name: String` | field | [port/src/syntax_ast.cj:41](../port/src/syntax_ast.cj#L41) |
| `public init(label: String, span: AstSpan, startSpan: AstSpan, origin: String, endSpan: AstSpan, endOrigin: String, start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String)` | constructor | [port/src/syntax_ast.cj:42](../port/src/syntax_ast.cj#L42) |
| `public init(label: String, start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String)` | constructor | [port/src/syntax_ast.cj:56](../port/src/syntax_ast.cj#L56) |
| `public func text(): String` | method | [port/src/syntax_ast.cj:59](../port/src/syntax_ast.cj#L59) |

## AstSpan

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class AstSpan` | class | [port/src/syntax_ast.cj:8](../port/src/syntax_ast.cj#L8) |
| `public let startOffset: Int64` | field | [port/src/syntax_ast.cj:9](../port/src/syntax_ast.cj#L9) |
| `public let startLine: Int64` | field | [port/src/syntax_ast.cj:10](../port/src/syntax_ast.cj#L10) |
| `public let startColumn: Int64` | field | [port/src/syntax_ast.cj:11](../port/src/syntax_ast.cj#L11) |
| `public let endOffset: Int64` | field | [port/src/syntax_ast.cj:12](../port/src/syntax_ast.cj#L12) |
| `public let endLine: Int64` | field | [port/src/syntax_ast.cj:13](../port/src/syntax_ast.cj#L13) |
| `public let endColumn: Int64` | field | [port/src/syntax_ast.cj:14](../port/src/syntax_ast.cj#L14) |
| `public init(startOffset: Int64, startLine: Int64, startColumn: Int64, endOffset: Int64, endLine: Int64, endColumn: Int64)` | constructor | [port/src/syntax_ast.cj:15](../port/src/syntax_ast.cj#L15) |
| `public func text(): String` | method | [port/src/syntax_ast.cj:24](../port/src/syntax_ast.cj#L24) |

## BoundedBacktracker

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BoundedBacktracker` | class | [port/src/backtrack.cj:14](../port/src/backtrack.cj#L14) |
| `public init(pattern: String)` | constructor | [port/src/backtrack.cj:26](../port/src/backtrack.cj#L26) |
| `public init(pattern: String, visitedCapacity: Int64)` | constructor | [port/src/backtrack.cj:29](../port/src/backtrack.cj#L29) |
| `public func stateCount(): Int64` | method | [port/src/backtrack.cj:96](../port/src/backtrack.cj#L96) |
| `public func maxHaystackLen(): Int64` | method | [port/src/backtrack.cj:101](../port/src/backtrack.cj#L101) |
| `public func search(text: String): Option<Captures>` | method | [port/src/backtrack.cj:114](../port/src/backtrack.cj#L114) |

## BytesCaptureIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesCaptureIter` | class | [port/src/bytes.cj:961](../port/src/bytes.cj#L961) |
| `public init(pull: () -> Option<BytesCaptures>)` | constructor | [port/src/bytes.cj:963](../port/src/bytes.cj#L963) |
| `public func next(): Option<BytesCaptures>` | method | [port/src/bytes.cj:966](../port/src/bytes.cj#L966) |

## BytesCaptures

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesCaptures` | class | [port/src/bytes.cj:595](../port/src/bytes.cj#L595) |
| `public let size: Int64` | field | [port/src/bytes.cj:599](../port/src/bytes.cj#L599) |
| `public func getMatch(): BytesMatch` | method | [port/src/bytes.cj:606](../port/src/bytes.cj#L606) |
| `public func get(index: Int64): Option<BytesMatch>` | method | [port/src/bytes.cj:612](../port/src/bytes.cj#L612) |
| `public func iter(): BytesGroupIter` | method | [port/src/bytes.cj:618](../port/src/bytes.cj#L618) |
| `public func extract(count: Int64): Array<Array<UInt8>>` | method | [port/src/bytes.cj:621](../port/src/bytes.cj#L621) |
| `public func name(value: String): Option<BytesMatch>` | method | [port/src/bytes.cj:647](../port/src/bytes.cj#L647) |
| `public func expand(template: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:659](../port/src/bytes.cj#L659) |
| `public func expandInto(template: Array<UInt8>, out: ArrayList<UInt8>): Unit` | method | [port/src/bytes.cj:664](../port/src/bytes.cj#L664) |

## BytesGroupItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesGroupItem` | class | [port/src/bytes.cj:745](../port/src/bytes.cj#L745) |
| `public let done: Bool` | field | [port/src/bytes.cj:746](../port/src/bytes.cj#L746) |
| `public let value: Option<BytesMatch>` | field | [port/src/bytes.cj:747](../port/src/bytes.cj#L747) |

## BytesGroupIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesGroupIter` | class | [port/src/bytes.cj:754](../port/src/bytes.cj#L754) |
| `public func len(): Int64` | method | [port/src/bytes.cj:761](../port/src/bytes.cj#L761) |
| `public func sizeHint(): (Int64, Option<Int64>)` | method | [port/src/bytes.cj:764](../port/src/bytes.cj#L764) |
| `public func clone(): BytesGroupIter` | method | [port/src/bytes.cj:767](../port/src/bytes.cj#L767) |
| `public func next(): BytesGroupItem` | method | [port/src/bytes.cj:772](../port/src/bytes.cj#L772) |

## BytesMatch

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesMatch` | class | [port/src/bytes.cj:7](../port/src/bytes.cj#L7) |
| `public let start: Int64` | field | [port/src/bytes.cj:8](../port/src/bytes.cj#L8) |
| `public let end: Int64` | field | [port/src/bytes.cj:9](../port/src/bytes.cj#L9) |
| `public let bytes: Array<UInt8>` | field | [port/src/bytes.cj:10](../port/src/bytes.cj#L10) |
| `public init(start: Int64, end: Int64, bytes: Array<UInt8>)` | constructor | [port/src/bytes.cj:11](../port/src/bytes.cj#L11) |
| `public func isEmpty(): Bool` | method | [port/src/bytes.cj:16](../port/src/bytes.cj#L16) |
| `public func len(): Int64` | method | [port/src/bytes.cj:19](../port/src/bytes.cj#L19) |

## BytesMatchIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesMatchIter` | class | [port/src/bytes.cj:951](../port/src/bytes.cj#L951) |
| `public init(pull: () -> Option<BytesMatch>)` | constructor | [port/src/bytes.cj:953](../port/src/bytes.cj#L953) |
| `public func next(): Option<BytesMatch>` | method | [port/src/bytes.cj:956](../port/src/bytes.cj#L956) |

## BytesRegex

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesRegex` | class | [port/src/bytes.cj:24](../port/src/bytes.cj#L24) |
| `public init(pattern: String)` | constructor | [port/src/bytes.cj:33](../port/src/bytes.cj#L33) |
| `public func asStr(): String` | method | [port/src/bytes.cj:96](../port/src/bytes.cj#L96) |
| `public func capturesLen(): Int64` | method | [port/src/bytes.cj:99](../port/src/bytes.cj#L99) |
| `public func staticCapturesLen(): Option<Int64>` | method | [port/src/bytes.cj:102](../port/src/bytes.cj#L102) |
| `public func captureNames(): Array<Option<String>>` | method | [port/src/bytes.cj:109](../port/src/bytes.cj#L109) |
| `public func captureLocations(): CaptureLocations` | method | [port/src/bytes.cj:118](../port/src/bytes.cj#L118) |
| `public func find(haystack: Array<UInt8>): Option<BytesMatch>` | method | [port/src/bytes.cj:121](../port/src/bytes.cj#L121) |
| `public func isMatch(haystack: Array<UInt8>): Bool` | method | [port/src/bytes.cj:124](../port/src/bytes.cj#L124) |
| `public func findAt(haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | method | [port/src/bytes.cj:127](../port/src/bytes.cj#L127) |
| `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | method | [port/src/bytes.cj:133](../port/src/bytes.cj#L133) |
| `public func shortestMatch(haystack: Array<UInt8>): Option<Int64>` | method | [port/src/bytes.cj:139](../port/src/bytes.cj#L139) |
| `public func shortestMatchAt(haystack: Array<UInt8>, start: Int64): Option<Int64>` | method | [port/src/bytes.cj:142](../port/src/bytes.cj#L142) |
| `public func findIter(haystack: Array<UInt8>): BytesMatchIter` | method | [port/src/bytes.cj:172](../port/src/bytes.cj#L172) |
| `public func capturesIter(haystack: Array<UInt8>): BytesCaptureIter` | method | [port/src/bytes.cj:182](../port/src/bytes.cj#L182) |
| `public func splitIter(haystack: Array<UInt8>): BytesSplitIter` | method | [port/src/bytes.cj:192](../port/src/bytes.cj#L192) |
| `public func splitNIter(haystack: Array<UInt8>, limit: Int64): BytesSplitIter` | method | [port/src/bytes.cj:195](../port/src/bytes.cj#L195) |
| `public func capturesRead(locations: CaptureLocations, haystack: Array<UInt8>): Option<BytesMatch>` | method | [port/src/bytes.cj:228](../port/src/bytes.cj#L228) |
| `public func findAll(haystack: Array<UInt8>): Array<BytesMatch>` | method | [port/src/bytes.cj:231](../port/src/bytes.cj#L231) |
| `public func captures(haystack: Array<UInt8>): Option<BytesCaptures>` | method | [port/src/bytes.cj:356](../port/src/bytes.cj#L356) |
| `public func capturesAt(haystack: Array<UInt8>, start: Int64): Option<BytesCaptures>` | method | [port/src/bytes.cj:359](../port/src/bytes.cj#L359) |
| `public func capturesAll(haystack: Array<UInt8>): Array<BytesCaptures>` | method | [port/src/bytes.cj:365](../port/src/bytes.cj#L365) |
| `public func capturesReadAt(locations: CaptureLocations, haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | method | [port/src/bytes.cj:384](../port/src/bytes.cj#L384) |
| `public func replace(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:408](../port/src/bytes.cj#L408) |
| `public func replaceAll(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:411](../port/src/bytes.cj#L411) |
| `public func replaceN(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:414](../port/src/bytes.cj#L414) |
| `public func replaceLiteral(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:427](../port/src/bytes.cj#L427) |
| `public func replaceWith(haystack: Array<UInt8>, limit: Int64, replacer: (BytesCaptures) -> Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:430](../port/src/bytes.cj#L430) |
| `public func split(haystack: Array<UInt8>): Array<Array<UInt8>>` | method | [port/src/bytes.cj:433](../port/src/bytes.cj#L433) |
| `public func splitN(haystack: Array<UInt8>, limit: Int64): Array<Array<UInt8>>` | method | [port/src/bytes.cj:436](../port/src/bytes.cj#L436) |

## BytesRegexBuilder

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesRegexBuilder` | class | [port/src/builder.cj:157](../port/src/builder.cj#L157) |
| `public init(pattern: String)` | constructor | [port/src/builder.cj:160](../port/src/builder.cj#L160) |
| `public func build(): BytesRegex` | method | [port/src/builder.cj:164](../port/src/builder.cj#L164) |
| `public func caseInsensitive(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:168](../port/src/builder.cj#L168) |
| `public func multiLine(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:172](../port/src/builder.cj#L172) |
| `public func dotMatchesNewLine(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:176](../port/src/builder.cj#L176) |
| `public func swapGreed(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:180](../port/src/builder.cj#L180) |
| `public func ignoreWhitespace(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:184](../port/src/builder.cj#L184) |
| `public func crlf(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:188](../port/src/builder.cj#L188) |
| `public func unicode(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:192](../port/src/builder.cj#L192) |
| `public func octal(yes: Bool): BytesRegexBuilder` | method | [port/src/builder.cj:196](../port/src/builder.cj#L196) |
| `public func lineTerminator(byte: Rune): BytesRegexBuilder` | method | [port/src/builder.cj:200](../port/src/builder.cj#L200) |
| `public func nestLimit(limit: Int64): BytesRegexBuilder` | method | [port/src/builder.cj:207](../port/src/builder.cj#L207) |
| `public func sizeLimit(limit: Int64): BytesRegexBuilder` | method | [port/src/builder.cj:214](../port/src/builder.cj#L214) |
| `public func dfaSizeLimit(limit: Int64): BytesRegexBuilder` | method | [port/src/builder.cj:221](../port/src/builder.cj#L221) |

## BytesRegexSet

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesRegexSet` | class | [port/src/bytes.cj:787](../port/src/bytes.cj#L787) |
| `public init(patterns: Array<String>)` | constructor | [port/src/bytes.cj:794](../port/src/bytes.cj#L794) |
| `public func len(): Int64` | method | [port/src/bytes.cj:844](../port/src/bytes.cj#L844) |
| `public func isEmpty(): Bool` | method | [port/src/bytes.cj:847](../port/src/bytes.cj#L847) |
| `public func patterns(): Array<String>` | method | [port/src/bytes.cj:850](../port/src/bytes.cj#L850) |
| `public func isMatch(haystack: Array<UInt8>): Bool` | method | [port/src/bytes.cj:853](../port/src/bytes.cj#L853) |
| `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | method | [port/src/bytes.cj:856](../port/src/bytes.cj#L856) |
| `public func matches(haystack: Array<UInt8>): SetMatches` | method | [port/src/bytes.cj:859](../port/src/bytes.cj#L859) |
| `public func matchesAt(haystack: Array<UInt8>, start: Int64): SetMatches` | method | [port/src/bytes.cj:862](../port/src/bytes.cj#L862) |
| `public func matchesReadAt(slots: Array<Bool>, haystack: Array<UInt8>, start: Int64): Bool` | method | [port/src/bytes.cj:865](../port/src/bytes.cj#L865) |

## BytesRegexSetBuilder

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesRegexSetBuilder` | class | [port/src/builder.cj:230](../port/src/builder.cj#L230) |
| `public init()` | constructor | [port/src/builder.cj:233](../port/src/builder.cj#L233) |
| `public init(patterns: Array<String>)` | constructor | [port/src/builder.cj:236](../port/src/builder.cj#L236) |
| `public func pattern(value: String): BytesRegexSetBuilder` | method | [port/src/builder.cj:240](../port/src/builder.cj#L240) |
| `public func build(): BytesRegexSet` | method | [port/src/builder.cj:244](../port/src/builder.cj#L244) |
| `public func caseInsensitive(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:248](../port/src/builder.cj#L248) |
| `public func multiLine(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:252](../port/src/builder.cj#L252) |
| `public func dotMatchesNewLine(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:256](../port/src/builder.cj#L256) |
| `public func swapGreed(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:260](../port/src/builder.cj#L260) |
| `public func ignoreWhitespace(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:264](../port/src/builder.cj#L264) |
| `public func crlf(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:268](../port/src/builder.cj#L268) |
| `public func unicode(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:272](../port/src/builder.cj#L272) |
| `public func octal(yes: Bool): BytesRegexSetBuilder` | method | [port/src/builder.cj:276](../port/src/builder.cj#L276) |
| `public func lineTerminator(byte: Rune): BytesRegexSetBuilder` | method | [port/src/builder.cj:280](../port/src/builder.cj#L280) |
| `public func nestLimit(limit: Int64): BytesRegexSetBuilder` | method | [port/src/builder.cj:287](../port/src/builder.cj#L287) |
| `public func sizeLimit(limit: Int64): BytesRegexSetBuilder` | method | [port/src/builder.cj:294](../port/src/builder.cj#L294) |
| `public func dfaSizeLimit(limit: Int64): BytesRegexSetBuilder` | method | [port/src/builder.cj:301](../port/src/builder.cj#L301) |

## BytesSplitIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesSplitIter` | class | [port/src/bytes.cj:971](../port/src/bytes.cj#L971) |
| `public init(pull: () -> Option<Array<UInt8>>)` | constructor | [port/src/bytes.cj:973](../port/src/bytes.cj#L973) |
| `public func next(): Option<Array<UInt8>>` | method | [port/src/bytes.cj:976](../port/src/bytes.cj#L976) |

## CaptureIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class CaptureIter` | class | [port/src/nfa.cj:1245](../port/src/nfa.cj#L1245) |
| `public init(pull: () -> Option<Captures>)` | constructor | [port/src/nfa.cj:1247](../port/src/nfa.cj#L1247) |
| `public func next(): Option<Captures>` | method | [port/src/nfa.cj:1250](../port/src/nfa.cj#L1250) |

## CaptureLocations

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class CaptureLocations` | class | [port/src/captures.cj:16](../port/src/captures.cj#L16) |
| `public let size: Int64` | field | [port/src/captures.cj:17](../port/src/captures.cj#L17) |
| `public func get(index: Int64): Option<CaptureSpan>` | method | [port/src/captures.cj:25](../port/src/captures.cj#L25) |

## CaptureSpan

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class CaptureSpan` | class | [port/src/captures.cj:7](../port/src/captures.cj#L7) |
| `public let start: Int64` | field | [port/src/captures.cj:8](../port/src/captures.cj#L8) |
| `public let end: Int64` | field | [port/src/captures.cj:9](../port/src/captures.cj#L9) |

## Captures

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Captures` | class | [port/src/captures.cj:41](../port/src/captures.cj#L41) |
| `public let size: Int64` | field | [port/src/captures.cj:45](../port/src/captures.cj#L45) |
| `public func getMatch(): RegexMatch` | method | [port/src/captures.cj:52](../port/src/captures.cj#L52) |
| `public func extract(count: Int64): Array<String>` | method | [port/src/captures.cj:60](../port/src/captures.cj#L60) |
| `public func iter(): GroupIter` | method | [port/src/captures.cj:86](../port/src/captures.cj#L86) |
| `public func get(index: Int64): Option<RegexMatch>` | method | [port/src/captures.cj:89](../port/src/captures.cj#L89) |
| `public func name(value: String): Option<RegexMatch>` | method | [port/src/captures.cj:95](../port/src/captures.cj#L95) |
| `public func expand(template: String): String` | method | [port/src/captures.cj:107](../port/src/captures.cj#L107) |
| `public func expandInto(template: String, out: StringBuilder): Unit` | method | [port/src/captures.cj:112](../port/src/captures.cj#L112) |

## DenseDfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class DenseDfa` | class | [port/src/dfa.cj:549](../port/src/dfa.cj#L549) |
| `public init(pattern: String)` | constructor | [port/src/dfa.cj:551](../port/src/dfa.cj#L551) |
| `public func stateCount(): Int64` | method | [port/src/dfa.cj:554](../port/src/dfa.cj#L554) |
| `public func search(text: String): Option<RegexMatch>` | method | [port/src/dfa.cj:557](../port/src/dfa.cj#L557) |

## GroupItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class GroupItem` | class | [port/src/captures.cj:198](../port/src/captures.cj#L198) |
| `public let done: Bool` | field | [port/src/captures.cj:199](../port/src/captures.cj#L199) |
| `public let value: Option<RegexMatch>` | field | [port/src/captures.cj:200](../port/src/captures.cj#L200) |

## GroupIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class GroupIter` | class | [port/src/captures.cj:207](../port/src/captures.cj#L207) |
| `public func len(): Int64` | method | [port/src/captures.cj:214](../port/src/captures.cj#L214) |
| `public func sizeHint(): (Int64, Option<Int64>)` | method | [port/src/captures.cj:215](../port/src/captures.cj#L215) |
| `public func clone(): GroupIter` | method | [port/src/captures.cj:218](../port/src/captures.cj#L218) |
| `public func next(): GroupItem` | method | [port/src/captures.cj:223](../port/src/captures.cj#L223) |

## Hir

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Hir` | class | [port/src/syntax_hir.cj:215](../port/src/syntax_hir.cj#L215) |
| `public func kind(): HirKind` | method | [port/src/syntax_hir.cj:223](../port/src/syntax_hir.cj#L223) |
| `public func properties(): HirProperties` | method | [port/src/syntax_hir.cj:231](../port/src/syntax_hir.cj#L231) |
| `public func subs(): Array<Hir>` | method | [port/src/syntax_hir.cj:234](../port/src/syntax_hir.cj#L234) |
| `public func visit(enter: (Hir) -> Unit): Unit` | method | [port/src/syntax_hir.cj:243](../port/src/syntax_hir.cj#L243) |
| `public func walk(enter: (Hir) -> Unit, leave: (Hir) -> Unit): Unit` | method | [port/src/syntax_hir.cj:257](../port/src/syntax_hir.cj#L257) |
| `public func walkUntil(enter: (Hir) -> Bool, leave: (Hir) -> Bool): Bool` | method | [port/src/syntax_hir.cj:272](../port/src/syntax_hir.cj#L272) |
| `public func toPattern(): String` | method | [port/src/syntax_hir.cj:285](../port/src/syntax_hir.cj#L285) |
| `public static func empty(): Hir` | method | [port/src/syntax_hir.cj:290](../port/src/syntax_hir.cj#L290) |
| `public static func fail(): Hir` | method | [port/src/syntax_hir.cj:293](../port/src/syntax_hir.cj#L293) |
| `public static func literal(bytes: Array<UInt8>): Hir` | method | [port/src/syntax_hir.cj:296](../port/src/syntax_hir.cj#L296) |
| `public static func unicodeClass(ranges: Array<HirRange>): Hir` | method | [port/src/syntax_hir.cj:303](../port/src/syntax_hir.cj#L303) |
| `public static func byteClass(ranges: Array<HirRange>): Hir` | method | [port/src/syntax_hir.cj:306](../port/src/syntax_hir.cj#L306) |
| `public static func capture(index: UInt32, name: Option<String>, sub: Hir): Hir` | method | [port/src/syntax_hir.cj:358](../port/src/syntax_hir.cj#L358) |
| `public static func repetition(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir): Hir` | method | [port/src/syntax_hir.cj:361](../port/src/syntax_hir.cj#L361) |
| `public static func concat(children: Array<Hir>): Hir` | method | [port/src/syntax_hir.cj:392](../port/src/syntax_hir.cj#L392) |
| `public static func look(look: HirLook): Hir` | method | [port/src/syntax_hir.cj:435](../port/src/syntax_hir.cj#L435) |
| `public static func dot(dot: HirDot): Hir` | method | [port/src/syntax_hir.cj:438](../port/src/syntax_hir.cj#L438) |
| `public static func dotExcept(bytes: Bool, excluded: Int64): Hir` | method | [port/src/syntax_hir.cj:448](../port/src/syntax_hir.cj#L448) |
| `public static func alternation(subs: Array<Hir>): Hir` | method | [port/src/syntax_hir.cj:451](../port/src/syntax_hir.cj#L451) |
| `public static func parse(pattern: String): Hir` | method | [port/src/syntax_hir.cj:528](../port/src/syntax_hir.cj#L528) |
| `public static func parse(pattern: String, utf8: Bool): Hir` | method | [port/src/syntax_hir.cj:531](../port/src/syntax_hir.cj#L531) |

## HirCapture

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HirCapture` | class | [port/src/syntax_hir.cj:101](../port/src/syntax_hir.cj#L101) |
| `public let index: UInt32` | field | [port/src/syntax_hir.cj:102](../port/src/syntax_hir.cj#L102) |
| `public let name: Option<String>` | field | [port/src/syntax_hir.cj:103](../port/src/syntax_hir.cj#L103) |
| `public let sub: Hir` | field | [port/src/syntax_hir.cj:104](../port/src/syntax_hir.cj#L104) |

## HirClass

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HirClass` | class | [port/src/syntax_hir.cj:31](../port/src/syntax_hir.cj#L31) |
| `public let isBytes: Bool` | field | [port/src/syntax_hir.cj:32](../port/src/syntax_hir.cj#L32) |
| `public func ranges(): Array<HirRange>` | method | [port/src/syntax_hir.cj:38](../port/src/syntax_hir.cj#L38) |
| `public func isEmpty(): Bool` | method | [port/src/syntax_hir.cj:41](../port/src/syntax_hir.cj#L41) |
| `public func union(other: HirClass): Hir` | method | [port/src/syntax_hir.cj:44](../port/src/syntax_hir.cj#L44) |
| `public func intersect(other: HirClass): Hir` | method | [port/src/syntax_hir.cj:47](../port/src/syntax_hir.cj#L47) |
| `public func difference(other: HirClass): Hir` | method | [port/src/syntax_hir.cj:50](../port/src/syntax_hir.cj#L50) |
| `public func negate(): Hir` | method | [port/src/syntax_hir.cj:53](../port/src/syntax_hir.cj#L53) |
| `public func caseFold(): Hir` | method | [port/src/syntax_hir.cj:74](../port/src/syntax_hir.cj#L74) |

## HirDot

| 声明 | 种类 | 实现 |
|---|---|---|
| `public enum HirDot` | enum | [port/src/syntax_hir.cj:133](../port/src/syntax_hir.cj#L133) |

## HirKind

| 声明 | 种类 | 实现 |
|---|---|---|
| `public enum HirKind` | enum | [port/src/syntax_hir.cj:137](../port/src/syntax_hir.cj#L137) |

## HirLook

| 声明 | 种类 | 实现 |
|---|---|---|
| `public enum HirLook` | enum | [port/src/syntax_hir.cj:112](../port/src/syntax_hir.cj#L112) |

## HirProperties

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HirProperties` | class | [port/src/syntax_hir.cj:148](../port/src/syntax_hir.cj#L148) |
| `public func minimumLen(): Option<UInt64>` | method | [port/src/syntax_hir.cj:177](../port/src/syntax_hir.cj#L177) |
| `public func maximumLen(): Option<UInt64>` | method | [port/src/syntax_hir.cj:180](../port/src/syntax_hir.cj#L180) |
| `public func isUtf8(): Bool` | method | [port/src/syntax_hir.cj:183](../port/src/syntax_hir.cj#L183) |
| `public func explicitCapturesLen(): Int64` | method | [port/src/syntax_hir.cj:186](../port/src/syntax_hir.cj#L186) |
| `public func staticExplicitCapturesLen(): Option<Int64>` | method | [port/src/syntax_hir.cj:189](../port/src/syntax_hir.cj#L189) |
| `public func isLiteral(): Bool` | method | [port/src/syntax_hir.cj:192](../port/src/syntax_hir.cj#L192) |
| `public func isAlternationLiteral(): Bool` | method | [port/src/syntax_hir.cj:195](../port/src/syntax_hir.cj#L195) |
| `public func lookSet(): UInt64` | method | [port/src/syntax_hir.cj:198](../port/src/syntax_hir.cj#L198) |
| `public func lookSetPrefix(): UInt64` | method | [port/src/syntax_hir.cj:201](../port/src/syntax_hir.cj#L201) |
| `public func lookSetPrefixAny(): UInt64` | method | [port/src/syntax_hir.cj:204](../port/src/syntax_hir.cj#L204) |
| `public func lookSetSuffix(): UInt64` | method | [port/src/syntax_hir.cj:207](../port/src/syntax_hir.cj#L207) |
| `public func lookSetSuffixAny(): UInt64` | method | [port/src/syntax_hir.cj:210](../port/src/syntax_hir.cj#L210) |

## HirRange

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HirRange` | class | [port/src/syntax_hir.cj:14](../port/src/syntax_hir.cj#L14) |
| `public let start: Int64` | field | [port/src/syntax_hir.cj:15](../port/src/syntax_hir.cj#L15) |
| `public let end: Int64` | field | [port/src/syntax_hir.cj:16](../port/src/syntax_hir.cj#L16) |
| `public init(start: Int64, end: Int64)` | constructor | [port/src/syntax_hir.cj:17](../port/src/syntax_hir.cj#L17) |

## HirRepetition

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HirRepetition` | class | [port/src/syntax_hir.cj:88](../port/src/syntax_hir.cj#L88) |
| `public let min: UInt32` | field | [port/src/syntax_hir.cj:89](../port/src/syntax_hir.cj#L89) |
| `public let max: Option<UInt32>` | field | [port/src/syntax_hir.cj:90](../port/src/syntax_hir.cj#L90) |
| `public let greedy: Bool` | field | [port/src/syntax_hir.cj:91](../port/src/syntax_hir.cj#L91) |
| `public let sub: Hir` | field | [port/src/syntax_hir.cj:92](../port/src/syntax_hir.cj#L92) |

## HirUnsupportedError

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HirUnsupportedError <: Exception` | class | [port/src/syntax_hir.cj:8](../port/src/syntax_hir.cj#L8) |
| `public init(message: String)` | constructor | [port/src/syntax_hir.cj:9](../port/src/syntax_hir.cj#L9) |

## LiteralPiece

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class LiteralPiece` | class | [port/src/syntax_literal.cj:7](../port/src/syntax_literal.cj#L7) |
| `public let exact: Bool` | field | [port/src/syntax_literal.cj:8](../port/src/syntax_literal.cj#L8) |
| `public let bytes: Array<UInt8>` | field | [port/src/syntax_literal.cj:9](../port/src/syntax_literal.cj#L9) |

## LiteralSeq

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class LiteralSeq` | class | [port/src/syntax_literal.cj:16](../port/src/syntax_literal.cj#L16) |
| `public let finite: Bool` | field | [port/src/syntax_literal.cj:17](../port/src/syntax_literal.cj#L17) |
| `public let pieces: Array<LiteralPiece>` | field | [port/src/syntax_literal.cj:18](../port/src/syntax_literal.cj#L18) |

## MatchIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class MatchIter` | class | [port/src/nfa.cj:1235](../port/src/nfa.cj#L1235) |
| `public init(pull: () -> Option<RegexMatch>)` | constructor | [port/src/nfa.cj:1237](../port/src/nfa.cj#L1237) |
| `public func next(): Option<RegexMatch>` | method | [port/src/nfa.cj:1240](../port/src/nfa.cj#L1240) |

## PikeCache

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class PikeCache` | class | [port/src/pikevm.cj:8](../port/src/pikevm.cj#L8) |
| `public func reset(): Unit` | method | [port/src/pikevm.cj:12](../port/src/pikevm.cj#L12) |
| `public func hasMatch(): Bool` | method | [port/src/pikevm.cj:19](../port/src/pikevm.cj#L19) |
| `public func patternId(): Int64` | method | [port/src/pikevm.cj:22](../port/src/pikevm.cj#L22) |
| `public func groupStart(index: Int64): Int64` | method | [port/src/pikevm.cj:25](../port/src/pikevm.cj#L25) |
| `public func groupEnd(index: Int64): Int64` | method | [port/src/pikevm.cj:32](../port/src/pikevm.cj#L32) |

## PikeMatch

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class PikeMatch` | class | [port/src/pikevm.cj:63](../port/src/pikevm.cj#L63) |
| `public let pattern: Int64` | field | [port/src/pikevm.cj:64](../port/src/pikevm.cj#L64) |
| `public let captures: Captures` | field | [port/src/pikevm.cj:65](../port/src/pikevm.cj#L65) |
| `public init(pattern: Int64, captures: Captures)` | constructor | [port/src/pikevm.cj:66](../port/src/pikevm.cj#L66) |
| `public func start(): Int64` | method | [port/src/pikevm.cj:70](../port/src/pikevm.cj#L70) |
| `public func end(): Int64` | method | [port/src/pikevm.cj:76](../port/src/pikevm.cj#L76) |

## PikeVM

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class PikeVM` | class | [port/src/pikevm.cj:84](../port/src/pikevm.cj#L84) |
| `public let cache: PikeCache` | field | [port/src/pikevm.cj:86](../port/src/pikevm.cj#L86) |
| `public init(pattern: String)` | constructor | [port/src/pikevm.cj:87](../port/src/pikevm.cj#L87) |
| `public init(patterns: Array<String>)` | constructor | [port/src/pikevm.cj:90](../port/src/pikevm.cj#L90) |
| `public init(hir: Hir)` | constructor | [port/src/pikevm.cj:94](../port/src/pikevm.cj#L94) |
| `public init(hirs: Array<Hir>)` | constructor | [port/src/pikevm.cj:97](../port/src/pikevm.cj#L97) |
| `public func patternCount(): Int64` | method | [port/src/pikevm.cj:101](../port/src/pikevm.cj#L101) |
| `public func reset(): Unit` | method | [port/src/pikevm.cj:104](../port/src/pikevm.cj#L104) |
| `public func stateCount(pattern: Int64): Int64` | method | [port/src/pikevm.cj:107](../port/src/pikevm.cj#L107) |
| `public func startState(pattern: Int64): Int64` | method | [port/src/pikevm.cj:110](../port/src/pikevm.cj#L110) |
| `public func opName(pattern: Int64, state: Int64): String` | method | [port/src/pikevm.cj:113](../port/src/pikevm.cj#L113) |
| `public func opNext(pattern: Int64, state: Int64): Int64` | method | [port/src/pikevm.cj:116](../port/src/pikevm.cj#L116) |
| `public func opAlternate(pattern: Int64, state: Int64): Int64` | method | [port/src/pikevm.cj:119](../port/src/pikevm.cj#L119) |
| `public func whichOverlapping(text: String): Array<Int64>` | method | [port/src/pikevm.cj:122](../port/src/pikevm.cj#L122) |
| `public func searchEarliest(text: String): Option<PikeMatch>` | method | [port/src/pikevm.cj:131](../port/src/pikevm.cj#L131) |
| `public func search(text: String): Option<PikeMatch>` | method | [port/src/pikevm.cj:165](../port/src/pikevm.cj#L165) |
| `public func search(text: String, start: Int64, end: Int64, anchored: Bool): Option<PikeMatch>` | method | [port/src/pikevm.cj:168](../port/src/pikevm.cj#L168) |

## Regex

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Regex` | class | [port/src/nfa.cj:508](../port/src/nfa.cj#L508) |
| `public init(pattern: String)` | constructor | [port/src/nfa.cj:517](../port/src/nfa.cj#L517) |
| `public func asStr(): String` | method | [port/src/nfa.cj:652](../port/src/nfa.cj#L652) |
| `public func staticCapturesLen(): Option<Int64>` | method | [port/src/nfa.cj:655](../port/src/nfa.cj#L655) |
| `public func searchEarliest(text: String): Option<Captures>` | method | [port/src/nfa.cj:795](../port/src/nfa.cj#L795) |
| `public func find(text: String): Option<RegexMatch>` | method | [port/src/nfa.cj:802](../port/src/nfa.cj#L802) |
| `public func isMatch(text: String): Bool` | method | [port/src/nfa.cj:814](../port/src/nfa.cj#L814) |
| `public func findAt(text: String, start: Int64): Option<RegexMatch>` | method | [port/src/nfa.cj:825](../port/src/nfa.cj#L825) |
| `public func isMatchAt(text: String, start: Int64): Bool` | method | [port/src/nfa.cj:833](../port/src/nfa.cj#L833) |
| `public func shortestMatch(text: String): Option<Int64>` | method | [port/src/nfa.cj:839](../port/src/nfa.cj#L839) |
| `public func shortestMatchAt(text: String, start: Int64): Option<Int64>` | method | [port/src/nfa.cj:842](../port/src/nfa.cj#L842) |
| `public func capturesAt(text: String, start: Int64): Option<Captures>` | method | [port/src/nfa.cj:850](../port/src/nfa.cj#L850) |
| `public func findIter(text: String): MatchIter` | method | [port/src/nfa.cj:858](../port/src/nfa.cj#L858) |
| `public func capturesIter(text: String): CaptureIter` | method | [port/src/nfa.cj:882](../port/src/nfa.cj#L882) |
| `public func splitIter(text: String): SplitIter` | method | [port/src/nfa.cj:906](../port/src/nfa.cj#L906) |
| `public func splitNIter(text: String, limit: Int64): SplitIter` | method | [port/src/nfa.cj:946](../port/src/nfa.cj#L946) |
| `public func captureLocations(): CaptureLocations` | method | [port/src/nfa.cj:975](../port/src/nfa.cj#L975) |
| `public func capturesRead(locations: CaptureLocations, text: String): Option<RegexMatch>` | method | [port/src/nfa.cj:978](../port/src/nfa.cj#L978) |
| `public func capturesReadAt(locations: CaptureLocations, text: String, start: Int64): Option<RegexMatch>` | method | [port/src/nfa.cj:981](../port/src/nfa.cj#L981) |
| `public func findAll(text: String): Array<RegexMatch>` | method | [port/src/nfa.cj:1007](../port/src/nfa.cj#L1007) |
| `public func capturesLen(): Int64` | method | [port/src/nfa.cj:1031](../port/src/nfa.cj#L1031) |
| `public func captureNames(): Array<Option<String>>` | method | [port/src/nfa.cj:1034](../port/src/nfa.cj#L1034) |
| `public func captures(text: String): Option<Captures>` | method | [port/src/nfa.cj:1059](../port/src/nfa.cj#L1059) |
| `public func capturesAll(text: String): Array<Captures>` | method | [port/src/nfa.cj:1066](../port/src/nfa.cj#L1066) |
| `public func replace(text: String, replacement: String): String` | method | [port/src/nfa.cj:1086](../port/src/nfa.cj#L1086) |
| `public func replaceAll(text: String, replacement: String): String` | method | [port/src/nfa.cj:1089](../port/src/nfa.cj#L1089) |
| `public func replaceN(text: String, limit: Int64, replacement: String): String` | method | [port/src/nfa.cj:1093](../port/src/nfa.cj#L1093) |
| `public func replaceLiteral(text: String, limit: Int64, replacement: String): String` | method | [port/src/nfa.cj:1106](../port/src/nfa.cj#L1106) |
| `public func replaceWith(text: String, limit: Int64, replacer: (Captures) -> String): String` | method | [port/src/nfa.cj:1109](../port/src/nfa.cj#L1109) |
| `public func split(text: String): Array<String>` | method | [port/src/nfa.cj:1143](../port/src/nfa.cj#L1143) |
| `public func splitN(text: String, limit: Int64): Array<String>` | method | [port/src/nfa.cj:1147](../port/src/nfa.cj#L1147) |
| `public func nfaStateCount(): Int64` | method | [port/src/nfa.cj:1183](../port/src/nfa.cj#L1183) |
| `public func nfaStart(): Int64` | method | [port/src/nfa.cj:1186](../port/src/nfa.cj#L1186) |
| `public func nfaOp(index: Int64): String` | method | [port/src/nfa.cj:1189](../port/src/nfa.cj#L1189) |
| `public func nfaNext(index: Int64): Int64` | method | [port/src/nfa.cj:1203](../port/src/nfa.cj#L1203) |
| `public func nfaAlternate(index: Int64): Int64` | method | [port/src/nfa.cj:1209](../port/src/nfa.cj#L1209) |
| `public func searchWindow(text: String, start: Int64, end: Int64, anchored: Bool): Option<Captures>` | method | [port/src/nfa.cj:1215](../port/src/nfa.cj#L1215) |

## RegexBuilder

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexBuilder` | class | [port/src/builder.cj:9](../port/src/builder.cj#L9) |
| `public init(pattern: String)` | constructor | [port/src/builder.cj:12](../port/src/builder.cj#L12) |
| `public func build(): Regex` | method | [port/src/builder.cj:15](../port/src/builder.cj#L15) |
| `public func caseInsensitive(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:18](../port/src/builder.cj#L18) |
| `public func multiLine(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:22](../port/src/builder.cj#L22) |
| `public func dotMatchesNewLine(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:26](../port/src/builder.cj#L26) |
| `public func swapGreed(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:30](../port/src/builder.cj#L30) |
| `public func ignoreWhitespace(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:34](../port/src/builder.cj#L34) |
| `public func crlf(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:38](../port/src/builder.cj#L38) |
| `public func unicode(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:42](../port/src/builder.cj#L42) |
| `public func octal(yes: Bool): RegexBuilder` | method | [port/src/builder.cj:46](../port/src/builder.cj#L46) |
| `public func lineTerminator(byte: Rune): RegexBuilder` | method | [port/src/builder.cj:50](../port/src/builder.cj#L50) |
| `public func nestLimit(limit: Int64): RegexBuilder` | method | [port/src/builder.cj:57](../port/src/builder.cj#L57) |
| `public func sizeLimit(limit: Int64): RegexBuilder` | method | [port/src/builder.cj:64](../port/src/builder.cj#L64) |
| `public func dfaSizeLimit(limit: Int64): RegexBuilder` | method | [port/src/builder.cj:71](../port/src/builder.cj#L71) |

## RegexError

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexError <: Exception` | class | [port/src/error.cj:34](../port/src/error.cj#L34) |
| `public let errorKind: RegexErrorKind` | field | [port/src/error.cj:35](../port/src/error.cj#L35) |
| `public let limit: Int64` | field | [port/src/error.cj:36](../port/src/error.cj#L36) |
| `public let text: String` | field | [port/src/error.cj:37](../port/src/error.cj#L37) |
| `public let phase: String` | field | [port/src/error.cj:39](../port/src/error.cj#L39) |
| `public let name: String` | field | [port/src/error.cj:41](../port/src/error.cj#L41) |
| `public let primary: Option<RegexErrorSpan>` | field | [port/src/error.cj:42](../port/src/error.cj#L42) |
| `public let auxiliary: Option<RegexErrorSpan>` | field | [port/src/error.cj:43](../port/src/error.cj#L43) |
| `public init(errorKind: RegexErrorKind, message: String, limit: Int64)` | constructor | [port/src/error.cj:44](../port/src/error.cj#L44) |
| `public init(errorKind: RegexErrorKind, message: String, limit: Int64, phase: String, name: String, primary: Option<RegexErrorSpan>, auxiliary: Option<RegexErrorSpan>)` | constructor | [port/src/error.cj:47](../port/src/error.cj#L47) |
| `public override func toString(): String` | method | [port/src/error.cj:58](../port/src/error.cj#L58) |
| `public func structure(): String` | method | [port/src/error.cj:61](../port/src/error.cj#L61) |

## RegexErrorKind

| 声明 | 种类 | 实现 |
|---|---|---|
| `public enum RegexErrorKind` | enum | [port/src/error.cj:7](../port/src/error.cj#L7) |

## RegexErrorSpan

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexErrorSpan` | class | [port/src/error.cj:13](../port/src/error.cj#L13) |
| `public let startOffset: Int64` | field | [port/src/error.cj:14](../port/src/error.cj#L14) |
| `public let startLine: Int64` | field | [port/src/error.cj:15](../port/src/error.cj#L15) |
| `public let startColumn: Int64` | field | [port/src/error.cj:16](../port/src/error.cj#L16) |
| `public let endOffset: Int64` | field | [port/src/error.cj:17](../port/src/error.cj#L17) |
| `public let endLine: Int64` | field | [port/src/error.cj:18](../port/src/error.cj#L18) |
| `public let endColumn: Int64` | field | [port/src/error.cj:19](../port/src/error.cj#L19) |
| `public init(startOffset: Int64, startLine: Int64, startColumn: Int64, endOffset: Int64, endLine: Int64, endColumn: Int64)` | constructor | [port/src/error.cj:20](../port/src/error.cj#L20) |
| `public func text(): String` | method | [port/src/error.cj:29](../port/src/error.cj#L29) |

## RegexMatch

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexMatch` | class | [port/src/nfa.cj:238](../port/src/nfa.cj#L238) |
| `public let start: Int64` | field | [port/src/nfa.cj:239](../port/src/nfa.cj#L239) |
| `public let end: Int64` | field | [port/src/nfa.cj:240](../port/src/nfa.cj#L240) |
| `public let text: String` | field | [port/src/nfa.cj:241](../port/src/nfa.cj#L241) |
| `public func isEmpty(): Bool` | method | [port/src/nfa.cj:247](../port/src/nfa.cj#L247) |
| `public func len(): Int64` | method | [port/src/nfa.cj:250](../port/src/nfa.cj#L250) |
| `public func asStr(): String` | method | [port/src/nfa.cj:253](../port/src/nfa.cj#L253) |

## RegexSet

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexSet` | class | [port/src/regex_set.cj:101](../port/src/regex_set.cj#L101) |
| `public init(patterns: Array<String>)` | constructor | [port/src/regex_set.cj:108](../port/src/regex_set.cj#L108) |
| `public func len(): Int64` | method | [port/src/regex_set.cj:157](../port/src/regex_set.cj#L157) |
| `public func isEmpty(): Bool` | method | [port/src/regex_set.cj:160](../port/src/regex_set.cj#L160) |
| `public func patterns(): Array<String>` | method | [port/src/regex_set.cj:163](../port/src/regex_set.cj#L163) |
| `public func isMatch(text: String): Bool` | method | [port/src/regex_set.cj:166](../port/src/regex_set.cj#L166) |
| `public func isMatchAt(text: String, start: Int64): Bool` | method | [port/src/regex_set.cj:169](../port/src/regex_set.cj#L169) |
| `public func matches(text: String): SetMatches` | method | [port/src/regex_set.cj:172](../port/src/regex_set.cj#L172) |
| `public func matchesAt(text: String, start: Int64): SetMatches` | method | [port/src/regex_set.cj:175](../port/src/regex_set.cj#L175) |
| `public func matchesReadAt(slots: Array<Bool>, text: String, start: Int64): Bool` | method | [port/src/regex_set.cj:180](../port/src/regex_set.cj#L180) |

## RegexSetBuilder

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexSetBuilder` | class | [port/src/builder.cj:80](../port/src/builder.cj#L80) |
| `public init()` | constructor | [port/src/builder.cj:83](../port/src/builder.cj#L83) |
| `public init(patterns: Array<String>)` | constructor | [port/src/builder.cj:84](../port/src/builder.cj#L84) |
| `public func pattern(value: String): RegexSetBuilder` | method | [port/src/builder.cj:87](../port/src/builder.cj#L87) |
| `public func build(): RegexSet` | method | [port/src/builder.cj:91](../port/src/builder.cj#L91) |
| `public func caseInsensitive(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:94](../port/src/builder.cj#L94) |
| `public func multiLine(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:98](../port/src/builder.cj#L98) |
| `public func dotMatchesNewLine(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:102](../port/src/builder.cj#L102) |
| `public func swapGreed(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:106](../port/src/builder.cj#L106) |
| `public func ignoreWhitespace(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:110](../port/src/builder.cj#L110) |
| `public func crlf(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:114](../port/src/builder.cj#L114) |
| `public func unicode(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:118](../port/src/builder.cj#L118) |
| `public func octal(yes: Bool): RegexSetBuilder` | method | [port/src/builder.cj:122](../port/src/builder.cj#L122) |
| `public func lineTerminator(byte: Rune): RegexSetBuilder` | method | [port/src/builder.cj:126](../port/src/builder.cj#L126) |
| `public func nestLimit(limit: Int64): RegexSetBuilder` | method | [port/src/builder.cj:133](../port/src/builder.cj#L133) |
| `public func sizeLimit(limit: Int64): RegexSetBuilder` | method | [port/src/builder.cj:140](../port/src/builder.cj#L140) |
| `public func dfaSizeLimit(limit: Int64): RegexSetBuilder` | method | [port/src/builder.cj:147](../port/src/builder.cj#L147) |

## ReverseNfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class ReverseNfa` | class | [port/src/reverse.cj:8](../port/src/reverse.cj#L8) |
| `public init(pattern: String)` | constructor | [port/src/reverse.cj:14](../port/src/reverse.cj#L14) |
| `public func search(text: String): Option<Int64>` | method | [port/src/reverse.cj:54](../port/src/reverse.cj#L54) |

## SetMatches

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SetMatches` | class | [port/src/regex_set.cj:7](../port/src/regex_set.cj#L7) |
| `public func len(): Int64` | method | [port/src/regex_set.cj:12](../port/src/regex_set.cj#L12) |
| `public func matched(index: Int64): Bool` | method | [port/src/regex_set.cj:15](../port/src/regex_set.cj#L15) |
| `public func matchedAny(): Bool` | method | [port/src/regex_set.cj:21](../port/src/regex_set.cj#L21) |
| `public func matchedAll(): Bool` | method | [port/src/regex_set.cj:29](../port/src/regex_set.cj#L29) |
| `public func indices(): Array<Int64>` | method | [port/src/regex_set.cj:37](../port/src/regex_set.cj#L37) |
| `public func iter(): SetMatchesIter` | method | [port/src/regex_set.cj:47](../port/src/regex_set.cj#L47) |

## SetMatchesIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SetMatchesIter` | class | [port/src/regex_set.cj:54](../port/src/regex_set.cj#L54) |
| `public func next(): Option<Int64>` | method | [port/src/regex_set.cj:65](../port/src/regex_set.cj#L65) |
| `public func nextBack(): Option<Int64>` | method | [port/src/regex_set.cj:76](../port/src/regex_set.cj#L76) |
| `public func sizeHint(): (Int64, Option<Int64>)` | method | [port/src/regex_set.cj:88](../port/src/regex_set.cj#L88) |
| `public func clone(): SetMatchesIter` | method | [port/src/regex_set.cj:93](../port/src/regex_set.cj#L93) |

## SparseDfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SparseDfa` | class | [port/src/dfa.cj:562](../port/src/dfa.cj#L562) |
| `public init(pattern: String)` | constructor | [port/src/dfa.cj:564](../port/src/dfa.cj#L564) |
| `public func stateCount(): Int64` | method | [port/src/dfa.cj:567](../port/src/dfa.cj#L567) |
| `public func search(text: String): Option<RegexMatch>` | method | [port/src/dfa.cj:570](../port/src/dfa.cj#L570) |

## SplitIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SplitIter` | class | [port/src/nfa.cj:1255](../port/src/nfa.cj#L1255) |
| `public init(pull: () -> Option<String>)` | constructor | [port/src/nfa.cj:1257](../port/src/nfa.cj#L1257) |
| `public func next(): Option<String>` | method | [port/src/nfa.cj:1260](../port/src/nfa.cj#L1260) |

## SyntaxParser

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SyntaxParser` | class | [port/src/syntax_ast.cj:1866](../port/src/syntax_ast.cj#L1866) |
| `public var caseInsensitive: Bool = false` | field | [port/src/syntax_ast.cj:1867](../port/src/syntax_ast.cj#L1867) |
| `public var multiLine: Bool = false` | field | [port/src/syntax_ast.cj:1868](../port/src/syntax_ast.cj#L1868) |
| `public var dotAll: Bool = false` | field | [port/src/syntax_ast.cj:1869](../port/src/syntax_ast.cj#L1869) |
| `public var swapGreed: Bool = false` | field | [port/src/syntax_ast.cj:1870](../port/src/syntax_ast.cj#L1870) |
| `public var ignoreWhitespace: Bool = false` | field | [port/src/syntax_ast.cj:1871](../port/src/syntax_ast.cj#L1871) |
| `public var crlf: Bool = false` | field | [port/src/syntax_ast.cj:1872](../port/src/syntax_ast.cj#L1872) |
| `public var unicode: Bool = true` | field | [port/src/syntax_ast.cj:1873](../port/src/syntax_ast.cj#L1873) |
| `public var utf8: Bool = true` | field | [port/src/syntax_ast.cj:1874](../port/src/syntax_ast.cj#L1874) |
| `public var octal: Bool = false` | field | [port/src/syntax_ast.cj:1875](../port/src/syntax_ast.cj#L1875) |
| `public var nestLimit: Int64 = 250` | field | [port/src/syntax_ast.cj:1876](../port/src/syntax_ast.cj#L1876) |
| `public init()` | constructor | [port/src/syntax_ast.cj:1877](../port/src/syntax_ast.cj#L1877) |
| `public func parseAst(pattern: String): Ast` | method | [port/src/syntax_ast.cj:1878](../port/src/syntax_ast.cj#L1878) |
| `public func parseHir(pattern: String): Hir` | method | [port/src/syntax_ast.cj:1895](../port/src/syntax_ast.cj#L1895) |
| `public func translate(ast: Ast): Hir` | method | [port/src/syntax_ast.cj:1900](../port/src/syntax_ast.cj#L1900) |

## Utf8Sequence

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Utf8Sequence` | class | [port/src/utf8seq.cj:7](../port/src/utf8seq.cj#L7) |
| `public let starts: Array<Int64>` | field | [port/src/utf8seq.cj:8](../port/src/utf8seq.cj#L8) |
| `public let ends: Array<Int64>` | field | [port/src/utf8seq.cj:9](../port/src/utf8seq.cj#L9) |
| `public func text(): String` | method | [port/src/utf8seq.cj:14](../port/src/utf8seq.cj#L14) |

## 顶层函数

| 声明 | 种类 | 实现 |
|---|---|---|
| `public func escape(text: String): String` | function | [port/src/escape.cj:13](../port/src/escape.cj#L13) |
| `public func hirLookName(look: HirLook): String` | function | [port/src/syntax_hir.cj:1495](../port/src/syntax_hir.cj#L1495) |
| `public func extractLiterals(hir: Hir): LiteralSeq` | function | [port/src/syntax_literal.cj:25](../port/src/syntax_literal.cj#L25) |
| `public func extractLiterals(hir: Hir, suffix: Bool): LiteralSeq` | function | [port/src/syntax_literal.cj:29](../port/src/syntax_literal.cj#L29) |
| `public func formatLiterals(hir: Hir, suffix: Bool): String` | function | [port/src/syntax_literal.cj:34](../port/src/syntax_literal.cj#L34) |
| `public func utf8SequenceLines(start: Int64, end: Int64): String` | function | [port/src/utf8seq.cj:29](../port/src/utf8seq.cj#L29) |
| `public func utf8SequencesOf(start: Int64, end: Int64): Array<Utf8Sequence>` | function | [port/src/utf8seq.cj:41](../port/src/utf8seq.cj#L41) |
