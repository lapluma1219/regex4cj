# 当前仓颉公开接口清单

由`scripts/generate_api_catalog.py`从仓库源码生成；可用`--check`检查是否过期。

当前显式公开调用入口 **451** 个，公开字段（含var） **118** 个；类型数量见下表。重复名称在不同类型/重载上分别计数，不计继承方法，不把枚举分支当作函数。

这是声明扫描，不是完整语言解析器，也不是原仓库覆盖率。主要库的170条固有方法映射仍见[接口审计](api-audit-methods.md)，语法/自动机的差异见[当前边界](status.md)。调用行为见[API](api.md)与[语法说明](hir.md)。

| 类别 | 数量 |
|---|---:|
| class | 61 |
| constructor | 80 |
| enum | 4 |
| field | 118 |
| function | 12 |
| method | 359 |

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
| `public func shape(): String` | method | [port/src/syntax_ast.cj:179](../port/src/syntax_ast.cj#L179) |
| `public func toPattern(): String` | method | [port/src/syntax_ast.cj:196](../port/src/syntax_ast.cj#L196) |
| `public func toHir(): Hir` | method | [port/src/syntax_ast.cj:201](../port/src/syntax_ast.cj#L201) |
| `public static func parse(pattern: String): Ast` | method | [port/src/syntax_ast.cj:204](../port/src/syntax_ast.cj#L204) |

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

## BacktrackCache

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BacktrackCache` | class | [port/src/backtrack.cj:518](../port/src/backtrack.cj#L518) |
| `public init()` | constructor | [port/src/backtrack.cj:521](../port/src/backtrack.cj#L521) |

## BoundedBacktracker

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BoundedBacktracker` | class | [port/src/backtrack.cj:14](../port/src/backtrack.cj#L14) |
| `public init(pattern: String)` | constructor | [port/src/backtrack.cj:36](../port/src/backtrack.cj#L36) |
| `public init(pattern: String, visitedCapacity: Int64)` | constructor | [port/src/backtrack.cj:39](../port/src/backtrack.cj#L39) |
| `public init(pattern: String, visitedCapacity: Int64, whichCaptures: Int64)` | constructor | [port/src/backtrack.cj:42](../port/src/backtrack.cj#L42) |
| `public init(patterns: Array<String>)` | constructor | [port/src/backtrack.cj:128](../port/src/backtrack.cj#L128) |
| `public init(patterns: Array<String>, visitedCapacity: Int64)` | constructor | [port/src/backtrack.cj:131](../port/src/backtrack.cj#L131) |
| `public init(patterns: Array<String>, visitedCapacity: Int64, whichCaptures: Int64)` | constructor | [port/src/backtrack.cj:134](../port/src/backtrack.cj#L134) |
| `public func stateCount(): Int64` | method | [port/src/backtrack.cj:196](../port/src/backtrack.cj#L196) |
| `public func memoryUsage(): Int64` | method | [port/src/backtrack.cj:199](../port/src/backtrack.cj#L199) |
| `public func maxHaystackLen(): Int64` | method | [port/src/backtrack.cj:211](../port/src/backtrack.cj#L211) |
| `public func createCache(): BacktrackCache` | method | [port/src/backtrack.cj:224](../port/src/backtrack.cj#L224) |
| `public func searchAll(text: String): Array<PikeMatch>` | method | [port/src/backtrack.cj:227](../port/src/backtrack.cj#L227) |
| `public func searchAll(input: SearchInput): Array<PikeMatch>` | method | [port/src/backtrack.cj:233](../port/src/backtrack.cj#L233) |
| `public func search(text: String): Option<Captures>` | method | [port/src/backtrack.cj:277](../port/src/backtrack.cj#L277) |
| `public func isMatch(input: SearchInput): Bool` | method | [port/src/backtrack.cj:283](../port/src/backtrack.cj#L283) |
| `public func search(cache: BacktrackCache, input: SearchInput): Option<PikeMatch>` | method | [port/src/backtrack.cj:311](../port/src/backtrack.cj#L311) |

## BytesCaptureIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesCaptureIter` | class | [port/src/bytes.cj:960](../port/src/bytes.cj#L960) |
| `public init(step: (Array<Int64>) -> Option<BytesCaptures>, state: Array<Int64>)` | constructor | [port/src/bytes.cj:963](../port/src/bytes.cj#L963) |
| `public func next(): Option<BytesCaptures>` | method | [port/src/bytes.cj:967](../port/src/bytes.cj#L967) |
| `public func clone(): BytesCaptureIter` | method | [port/src/bytes.cj:970](../port/src/bytes.cj#L970) |

## BytesCaptures

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesCaptures` | class | [port/src/bytes.cj:589](../port/src/bytes.cj#L589) |
| `public let size: Int64` | field | [port/src/bytes.cj:593](../port/src/bytes.cj#L593) |
| `public func getMatch(): BytesMatch` | method | [port/src/bytes.cj:600](../port/src/bytes.cj#L600) |
| `public func get(index: Int64): Option<BytesMatch>` | method | [port/src/bytes.cj:606](../port/src/bytes.cj#L606) |
| `public func iter(): BytesGroupIter` | method | [port/src/bytes.cj:612](../port/src/bytes.cj#L612) |
| `public func extract(count: Int64): Array<Array<UInt8>>` | method | [port/src/bytes.cj:615](../port/src/bytes.cj#L615) |
| `public func name(value: String): Option<BytesMatch>` | method | [port/src/bytes.cj:641](../port/src/bytes.cj#L641) |
| `public func expand(template: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:653](../port/src/bytes.cj#L653) |
| `public func expandInto(template: Array<UInt8>, out: ArrayList<UInt8>): Unit` | method | [port/src/bytes.cj:658](../port/src/bytes.cj#L658) |

## BytesGroupItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesGroupItem` | class | [port/src/bytes.cj:739](../port/src/bytes.cj#L739) |
| `public let done: Bool` | field | [port/src/bytes.cj:740](../port/src/bytes.cj#L740) |
| `public let value: Option<BytesMatch>` | field | [port/src/bytes.cj:741](../port/src/bytes.cj#L741) |

## BytesGroupIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesGroupIter` | class | [port/src/bytes.cj:748](../port/src/bytes.cj#L748) |
| `public func len(): Int64` | method | [port/src/bytes.cj:755](../port/src/bytes.cj#L755) |
| `public func sizeHint(): (Int64, Option<Int64>)` | method | [port/src/bytes.cj:758](../port/src/bytes.cj#L758) |
| `public func clone(): BytesGroupIter` | method | [port/src/bytes.cj:761](../port/src/bytes.cj#L761) |
| `public func next(): BytesGroupItem` | method | [port/src/bytes.cj:766](../port/src/bytes.cj#L766) |

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
| `public class BytesMatchIter` | class | [port/src/bytes.cj:945](../port/src/bytes.cj#L945) |
| `public init(step: (Array<Int64>) -> Option<BytesMatch>, state: Array<Int64>)` | constructor | [port/src/bytes.cj:948](../port/src/bytes.cj#L948) |
| `public func next(): Option<BytesMatch>` | method | [port/src/bytes.cj:952](../port/src/bytes.cj#L952) |
| `public func clone(): BytesMatchIter` | method | [port/src/bytes.cj:955](../port/src/bytes.cj#L955) |

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
| `public func findIter(haystack: Array<UInt8>): BytesMatchIter` | method | [port/src/bytes.cj:166](../port/src/bytes.cj#L166) |
| `public func capturesIter(haystack: Array<UInt8>): BytesCaptureIter` | method | [port/src/bytes.cj:175](../port/src/bytes.cj#L175) |
| `public func splitIter(haystack: Array<UInt8>): BytesSplitIter` | method | [port/src/bytes.cj:184](../port/src/bytes.cj#L184) |
| `public func splitNIter(haystack: Array<UInt8>, limit: Int64): BytesSplitIter` | method | [port/src/bytes.cj:187](../port/src/bytes.cj#L187) |
| `public func capturesRead(locations: CaptureLocations, haystack: Array<UInt8>): Option<BytesMatch>` | method | [port/src/bytes.cj:222](../port/src/bytes.cj#L222) |
| `public func findAll(haystack: Array<UInt8>): Array<BytesMatch>` | method | [port/src/bytes.cj:225](../port/src/bytes.cj#L225) |
| `public func captures(haystack: Array<UInt8>): Option<BytesCaptures>` | method | [port/src/bytes.cj:350](../port/src/bytes.cj#L350) |
| `public func capturesAt(haystack: Array<UInt8>, start: Int64): Option<BytesCaptures>` | method | [port/src/bytes.cj:353](../port/src/bytes.cj#L353) |
| `public func capturesAll(haystack: Array<UInt8>): Array<BytesCaptures>` | method | [port/src/bytes.cj:359](../port/src/bytes.cj#L359) |
| `public func capturesReadAt(locations: CaptureLocations, haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | method | [port/src/bytes.cj:378](../port/src/bytes.cj#L378) |
| `public func replace(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:402](../port/src/bytes.cj#L402) |
| `public func replaceAll(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:405](../port/src/bytes.cj#L405) |
| `public func replaceN(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:408](../port/src/bytes.cj#L408) |
| `public func replaceLiteral(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:421](../port/src/bytes.cj#L421) |
| `public func replaceWith(haystack: Array<UInt8>, limit: Int64, replacer: (BytesCaptures) -> Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:424](../port/src/bytes.cj#L424) |
| `public func split(haystack: Array<UInt8>): Array<Array<UInt8>>` | method | [port/src/bytes.cj:427](../port/src/bytes.cj#L427) |
| `public func splitN(haystack: Array<UInt8>, limit: Int64): Array<Array<UInt8>>` | method | [port/src/bytes.cj:430](../port/src/bytes.cj#L430) |

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
| `public class BytesRegexSet` | class | [port/src/bytes.cj:781](../port/src/bytes.cj#L781) |
| `public init(patterns: Array<String>)` | constructor | [port/src/bytes.cj:788](../port/src/bytes.cj#L788) |
| `public func len(): Int64` | method | [port/src/bytes.cj:838](../port/src/bytes.cj#L838) |
| `public func isEmpty(): Bool` | method | [port/src/bytes.cj:841](../port/src/bytes.cj#L841) |
| `public func patterns(): Array<String>` | method | [port/src/bytes.cj:844](../port/src/bytes.cj#L844) |
| `public func isMatch(haystack: Array<UInt8>): Bool` | method | [port/src/bytes.cj:847](../port/src/bytes.cj#L847) |
| `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | method | [port/src/bytes.cj:850](../port/src/bytes.cj#L850) |
| `public func matches(haystack: Array<UInt8>): SetMatches` | method | [port/src/bytes.cj:853](../port/src/bytes.cj#L853) |
| `public func matchesAt(haystack: Array<UInt8>, start: Int64): SetMatches` | method | [port/src/bytes.cj:856](../port/src/bytes.cj#L856) |
| `public func matchesReadAt(slots: Array<Bool>, haystack: Array<UInt8>, start: Int64): Bool` | method | [port/src/bytes.cj:859](../port/src/bytes.cj#L859) |

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
| `public class BytesSplitIter` | class | [port/src/bytes.cj:975](../port/src/bytes.cj#L975) |
| `public init(step: (Array<Int64>) -> Option<Array<UInt8>>, state: Array<Int64>)` | constructor | [port/src/bytes.cj:978](../port/src/bytes.cj#L978) |
| `public func next(): Option<Array<UInt8>>` | method | [port/src/bytes.cj:982](../port/src/bytes.cj#L982) |
| `public func clone(): BytesSplitIter` | method | [port/src/bytes.cj:985](../port/src/bytes.cj#L985) |

## CaptureIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class CaptureIter` | class | [port/src/nfa.cj:1239](../port/src/nfa.cj#L1239) |
| `public init(step: (Array<Int64>) -> Option<Captures>, state: Array<Int64>)` | constructor | [port/src/nfa.cj:1242](../port/src/nfa.cj#L1242) |
| `public func next(): Option<Captures>` | method | [port/src/nfa.cj:1246](../port/src/nfa.cj#L1246) |
| `public func clone(): CaptureIter` | method | [port/src/nfa.cj:1249](../port/src/nfa.cj#L1249) |

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
| `public func groupName(index: Int64): String` | method | [port/src/captures.cj:89](../port/src/captures.cj#L89) |
| `public func get(index: Int64): Option<RegexMatch>` | method | [port/src/captures.cj:95](../port/src/captures.cj#L95) |
| `public func name(value: String): Option<RegexMatch>` | method | [port/src/captures.cj:101](../port/src/captures.cj#L101) |
| `public func expand(template: String): String` | method | [port/src/captures.cj:113](../port/src/captures.cj#L113) |
| `public func expandInto(template: String, out: StringBuilder): Unit` | method | [port/src/captures.cj:118](../port/src/captures.cj#L118) |

## DenseDfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class DenseDfa` | class | [port/src/dfa.cj:1068](../port/src/dfa.cj#L1068) |
| `public init(pattern: String)` | constructor | [port/src/dfa.cj:1070](../port/src/dfa.cj#L1070) |
| `public init(pattern: String, quit: Array<UInt8>)` | constructor | [port/src/dfa.cj:1073](../port/src/dfa.cj#L1073) |
| `public init(patterns: Array<String>)` | constructor | [port/src/dfa.cj:1076](../port/src/dfa.cj#L1076) |
| `public init(patterns: Array<String>, quit: Array<UInt8>)` | constructor | [port/src/dfa.cj:1079](../port/src/dfa.cj#L1079) |
| `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool)` | constructor | [port/src/dfa.cj:1082](../port/src/dfa.cj#L1082) |
| `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool, patternStarts: Bool)` | constructor | [port/src/dfa.cj:1085](../port/src/dfa.cj#L1085) |
| `public init(patterns: Array<String>, byteLimit: Int64)` | constructor | [port/src/dfa.cj:1088](../port/src/dfa.cj#L1088) |
| `public static func overlap(patterns: Array<String>): DenseDfa` | method | [port/src/dfa.cj:1091](../port/src/dfa.cj#L1091) |
| `public func stateCount(): Int64` | method | [port/src/dfa.cj:1094](../port/src/dfa.cj#L1094) |
| `public func memoryUsage(): Int64` | method | [port/src/dfa.cj:1097](../port/src/dfa.cj#L1097) |
| `public func retainsDenseTable(): Bool` | method | [port/src/dfa.cj:1100](../port/src/dfa.cj#L1100) |
| `public func search(text: String): Option<DfaMatch>` | method | [port/src/dfa.cj:1103](../port/src/dfa.cj#L1103) |
| `public func search(input: SearchInput): Option<DfaMatch>` | method | [port/src/dfa.cj:1106](../port/src/dfa.cj#L1106) |
| `public func searchOverlapping(text: String): Array<DfaHalf>` | method | [port/src/dfa.cj:1109](../port/src/dfa.cj#L1109) |
| `public func searchOverlapping(input: SearchInput): Array<DfaHalf>` | method | [port/src/dfa.cj:1112](../port/src/dfa.cj#L1112) |
| `public func toImage(): Array<UInt8>` | method | [port/src/dfa.cj:1118](../port/src/dfa.cj#L1118) |
| `public static func fromImage(bytes: Array<UInt8>): DenseDfa` | method | [port/src/dfa.cj:1144](../port/src/dfa.cj#L1144) |

## DfaHalf

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class DfaHalf` | class | [port/src/dfa.cj:1046](../port/src/dfa.cj#L1046) |
| `public let pattern: Int64` | field | [port/src/dfa.cj:1047](../port/src/dfa.cj#L1047) |
| `public let end: Int64` | field | [port/src/dfa.cj:1048](../port/src/dfa.cj#L1048) |
| `public init(pattern: Int64, end: Int64)` | constructor | [port/src/dfa.cj:1049](../port/src/dfa.cj#L1049) |

## DfaMatch

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class DfaMatch` | class | [port/src/dfa.cj:1055](../port/src/dfa.cj#L1055) |
| `public let pattern: Int64` | field | [port/src/dfa.cj:1056](../port/src/dfa.cj#L1056) |
| `public let start: Int64` | field | [port/src/dfa.cj:1057](../port/src/dfa.cj#L1057) |
| `public let end: Int64` | field | [port/src/dfa.cj:1058](../port/src/dfa.cj#L1058) |
| `public let text: String` | field | [port/src/dfa.cj:1059](../port/src/dfa.cj#L1059) |
| `public init(pattern: Int64, start: Int64, end: Int64, text: String)` | constructor | [port/src/dfa.cj:1060](../port/src/dfa.cj#L1060) |

## GroupItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class GroupItem` | class | [port/src/captures.cj:204](../port/src/captures.cj#L204) |
| `public let done: Bool` | field | [port/src/captures.cj:205](../port/src/captures.cj#L205) |
| `public let value: Option<RegexMatch>` | field | [port/src/captures.cj:206](../port/src/captures.cj#L206) |

## GroupIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class GroupIter` | class | [port/src/captures.cj:213](../port/src/captures.cj#L213) |
| `public func len(): Int64` | method | [port/src/captures.cj:220](../port/src/captures.cj#L220) |
| `public func sizeHint(): (Int64, Option<Int64>)` | method | [port/src/captures.cj:223](../port/src/captures.cj#L223) |
| `public func clone(): GroupIter` | method | [port/src/captures.cj:226](../port/src/captures.cj#L226) |
| `public func next(): GroupItem` | method | [port/src/captures.cj:231](../port/src/captures.cj#L231) |

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
| `public func toPattern(): String` | method | [port/src/syntax_hir.cj:284](../port/src/syntax_hir.cj#L284) |
| `public static func empty(): Hir` | method | [port/src/syntax_hir.cj:289](../port/src/syntax_hir.cj#L289) |
| `public static func fail(): Hir` | method | [port/src/syntax_hir.cj:292](../port/src/syntax_hir.cj#L292) |
| `public static func literal(bytes: Array<UInt8>): Hir` | method | [port/src/syntax_hir.cj:295](../port/src/syntax_hir.cj#L295) |
| `public static func unicodeClass(ranges: Array<HirRange>): Hir` | method | [port/src/syntax_hir.cj:302](../port/src/syntax_hir.cj#L302) |
| `public static func byteClass(ranges: Array<HirRange>): Hir` | method | [port/src/syntax_hir.cj:305](../port/src/syntax_hir.cj#L305) |
| `public static func capture(index: UInt32, name: Option<String>, sub: Hir): Hir` | method | [port/src/syntax_hir.cj:357](../port/src/syntax_hir.cj#L357) |
| `public static func repetition(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir): Hir` | method | [port/src/syntax_hir.cj:360](../port/src/syntax_hir.cj#L360) |
| `public static func concat(children: Array<Hir>): Hir` | method | [port/src/syntax_hir.cj:391](../port/src/syntax_hir.cj#L391) |
| `public static func look(look: HirLook): Hir` | method | [port/src/syntax_hir.cj:434](../port/src/syntax_hir.cj#L434) |
| `public static func dot(dot: HirDot): Hir` | method | [port/src/syntax_hir.cj:437](../port/src/syntax_hir.cj#L437) |
| `public static func dotExcept(bytes: Bool, excluded: Int64): Hir` | method | [port/src/syntax_hir.cj:447](../port/src/syntax_hir.cj#L447) |
| `public static func alternation(subs: Array<Hir>): Hir` | method | [port/src/syntax_hir.cj:450](../port/src/syntax_hir.cj#L450) |
| `public static func parse(pattern: String): Hir` | method | [port/src/syntax_hir.cj:527](../port/src/syntax_hir.cj#L527) |
| `public static func parse(pattern: String, utf8: Bool): Hir` | method | [port/src/syntax_hir.cj:530](../port/src/syntax_hir.cj#L530) |

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

## HybridDfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class HybridDfa` | class | [port/src/dfa.cj:1241](../port/src/dfa.cj#L1241) |
| `public init(pattern: String)` | constructor | [port/src/dfa.cj:1243](../port/src/dfa.cj#L1243) |
| `public init(pattern: String, quit: Array<UInt8>)` | constructor | [port/src/dfa.cj:1246](../port/src/dfa.cj#L1246) |
| `public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64)` | constructor | [port/src/dfa.cj:1249](../port/src/dfa.cj#L1249) |
| `public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool)` | constructor | [port/src/dfa.cj:1252](../port/src/dfa.cj#L1252) |
| `public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool, matchAll: Bool)` | constructor | [port/src/dfa.cj:1255](../port/src/dfa.cj#L1255) |
| `public static func overlap(patterns: Array<String>): HybridDfa` | method | [port/src/dfa.cj:1258](../port/src/dfa.cj#L1258) |
| `public func stateCount(): Int64` | method | [port/src/dfa.cj:1261](../port/src/dfa.cj#L1261) |
| `public func memoryUsage(): Int64` | method | [port/src/dfa.cj:1264](../port/src/dfa.cj#L1264) |
| `public func reset(): Unit` | method | [port/src/dfa.cj:1267](../port/src/dfa.cj#L1267) |
| `public func search(text: String): Option<DfaMatch>` | method | [port/src/dfa.cj:1270](../port/src/dfa.cj#L1270) |
| `public func searchOverlapping(text: String): Array<DfaHalf>` | method | [port/src/dfa.cj:1273](../port/src/dfa.cj#L1273) |
| `public func search(input: SearchInput): Option<DfaMatch>` | method | [port/src/dfa.cj:1276](../port/src/dfa.cj#L1276) |

## LiteRegex

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class LiteRegex` | class | [port/src/lite.cj:8](../port/src/lite.cj#L8) |
| `public init(pattern: String)` | constructor | [port/src/lite.cj:11](../port/src/lite.cj#L11) |
| `public func search(text: String): Option<PikeMatch>` | method | [port/src/lite.cj:16](../port/src/lite.cj#L16) |
| `public func isMatch(text: String): Bool` | method | [port/src/lite.cj:19](../port/src/lite.cj#L19) |
| `public func searchAll(text: String): Array<PikeMatch>` | method | [port/src/lite.cj:22](../port/src/lite.cj#L22) |

## LiteralLimits

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class LiteralLimits` | class | [port/src/syntax_literal.cj:186](../port/src/syntax_literal.cj#L186) |
| `public let classLimit: Int64` | field | [port/src/syntax_literal.cj:187](../port/src/syntax_literal.cj#L187) |
| `public let repeatLimit: Int64` | field | [port/src/syntax_literal.cj:188](../port/src/syntax_literal.cj#L188) |
| `public let literalLen: Int64` | field | [port/src/syntax_literal.cj:189](../port/src/syntax_literal.cj#L189) |
| `public let totalLimit: Int64` | field | [port/src/syntax_literal.cj:190](../port/src/syntax_literal.cj#L190) |
| `public init()` | constructor | [port/src/syntax_literal.cj:191](../port/src/syntax_literal.cj#L191) |
| `public init(classLimit: Int64, repeatLimit: Int64, literalLen: Int64, totalLimit: Int64)` | constructor | [port/src/syntax_literal.cj:194](../port/src/syntax_literal.cj#L194) |

## LiteralPiece

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class LiteralPiece` | class | [port/src/syntax_literal.cj:7](../port/src/syntax_literal.cj#L7) |
| `public let exact: Bool` | field | [port/src/syntax_literal.cj:8](../port/src/syntax_literal.cj#L8) |
| `public let bytes: Array<UInt8>` | field | [port/src/syntax_literal.cj:9](../port/src/syntax_literal.cj#L9) |
| `public init(exact: Bool, bytes: Array<UInt8>)` | constructor | [port/src/syntax_literal.cj:10](../port/src/syntax_literal.cj#L10) |

## LiteralSeq

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class LiteralSeq` | class | [port/src/syntax_literal.cj:16](../port/src/syntax_literal.cj#L16) |
| `public let finite: Bool` | field | [port/src/syntax_literal.cj:17](../port/src/syntax_literal.cj#L17) |
| `public let pieces: Array<LiteralPiece>` | field | [port/src/syntax_literal.cj:18](../port/src/syntax_literal.cj#L18) |
| `public static func infinite(): LiteralSeq` | method | [port/src/syntax_literal.cj:23](../port/src/syntax_literal.cj#L23) |
| `public static func of(pieces: Array<LiteralPiece>): LiteralSeq` | method | [port/src/syntax_literal.cj:26](../port/src/syntax_literal.cj#L26) |
| `public func isEmpty(): Bool` | method | [port/src/syntax_literal.cj:29](../port/src/syntax_literal.cj#L29) |
| `public func isExact(): Bool` | method | [port/src/syntax_literal.cj:32](../port/src/syntax_literal.cj#L32) |
| `public func isInexact(): Bool` | method | [port/src/syntax_literal.cj:43](../port/src/syntax_literal.cj#L43) |
| `public func literalCount(): Option<Int64>` | method | [port/src/syntax_literal.cj:54](../port/src/syntax_literal.cj#L54) |
| `public func minLiteralLen(): Option<Int64>` | method | [port/src/syntax_literal.cj:61](../port/src/syntax_literal.cj#L61) |
| `public func maxUnionLen(other: LiteralSeq): Option<Int64>` | method | [port/src/syntax_literal.cj:73](../port/src/syntax_literal.cj#L73) |
| `public func maxCrossLen(other: LiteralSeq): Option<Int64>` | method | [port/src/syntax_literal.cj:82](../port/src/syntax_literal.cj#L82) |
| `public func maxLiteralLen(): Option<Int64>` | method | [port/src/syntax_literal.cj:91](../port/src/syntax_literal.cj#L91) |
| `public func crossForward(other: LiteralSeq): LiteralSeq` | method | [port/src/syntax_literal.cj:103](../port/src/syntax_literal.cj#L103) |
| `public func crossReverse(other: LiteralSeq): LiteralSeq` | method | [port/src/syntax_literal.cj:109](../port/src/syntax_literal.cj#L109) |
| `public func union(other: LiteralSeq): LiteralSeq` | method | [port/src/syntax_literal.cj:115](../port/src/syntax_literal.cj#L115) |
| `public func unionIntoEmpty(other: LiteralSeq): LiteralSeq` | method | [port/src/syntax_literal.cj:121](../port/src/syntax_literal.cj#L121) |
| `public func keepFirst(len: Int64): LiteralSeq` | method | [port/src/syntax_literal.cj:127](../port/src/syntax_literal.cj#L127) |
| `public func keepLast(len: Int64): LiteralSeq` | method | [port/src/syntax_literal.cj:135](../port/src/syntax_literal.cj#L135) |
| `public func minimize(): LiteralSeq` | method | [port/src/syntax_literal.cj:143](../port/src/syntax_literal.cj#L143) |
| `public func optimizePrefix(): LiteralSeq` | method | [port/src/syntax_literal.cj:148](../port/src/syntax_literal.cj#L148) |
| `public func optimizeSuffix(): LiteralSeq` | method | [port/src/syntax_literal.cj:153](../port/src/syntax_literal.cj#L153) |
| `public func reversed(): LiteralSeq` | method | [port/src/syntax_literal.cj:158](../port/src/syntax_literal.cj#L158) |
| `public func sorted(): LiteralSeq` | method | [port/src/syntax_literal.cj:163](../port/src/syntax_literal.cj#L163) |
| `public func makeInexact(): LiteralSeq` | method | [port/src/syntax_literal.cj:168](../port/src/syntax_literal.cj#L168) |
| `public func deduped(): LiteralSeq` | method | [port/src/syntax_literal.cj:173](../port/src/syntax_literal.cj#L173) |
| `public func commonPrefix(): Option<Array<UInt8>>` | method | [port/src/syntax_literal.cj:178](../port/src/syntax_literal.cj#L178) |
| `public func commonSuffix(): Option<Array<UInt8>>` | method | [port/src/syntax_literal.cj:181](../port/src/syntax_literal.cj#L181) |

## MatchIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class MatchIter` | class | [port/src/nfa.cj:1224](../port/src/nfa.cj#L1224) |
| `public init(step: (Array<Int64>) -> Option<RegexMatch>, state: Array<Int64>)` | constructor | [port/src/nfa.cj:1227](../port/src/nfa.cj#L1227) |
| `public func next(): Option<RegexMatch>` | method | [port/src/nfa.cj:1231](../port/src/nfa.cj#L1231) |
| `public func clone(): MatchIter` | method | [port/src/nfa.cj:1234](../port/src/nfa.cj#L1234) |

## MetaRegex

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class MetaRegex` | class | [port/src/meta.cj:47](../port/src/meta.cj#L47) |
| `public let engineName: String` | field | [port/src/meta.cj:52](../port/src/meta.cj#L52) |
| `public init(pattern: String)` | constructor | [port/src/meta.cj:53](../port/src/meta.cj#L53) |
| `public init(patterns: Array<String>)` | constructor | [port/src/meta.cj:56](../port/src/meta.cj#L56) |
| `public func memoryUsage(): Int64` | method | [port/src/meta.cj:72](../port/src/meta.cj#L72) |
| `public func search(text: String): Option<PikeMatch>` | method | [port/src/meta.cj:80](../port/src/meta.cj#L80) |
| `public func searchAll(text: String): Array<PikeMatch>` | method | [port/src/meta.cj:83](../port/src/meta.cj#L83) |

## OnePass

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class OnePass` | class | [port/src/onepass.cj:8](../port/src/onepass.cj#L8) |
| `public let engineName: String = "onepass"` | field | [port/src/onepass.cj:10](../port/src/onepass.cj#L10) |
| `public init(pattern: String)` | constructor | [port/src/onepass.cj:11](../port/src/onepass.cj#L11) |
| `public init(patterns: Array<String>)` | constructor | [port/src/onepass.cj:14](../port/src/onepass.cj#L14) |
| `public func search(text: String): Option<PikeMatch>` | method | [port/src/onepass.cj:24](../port/src/onepass.cj#L24) |
| `public func searchAnchored(text: String, at: Int64): Option<PikeMatch>` | method | [port/src/onepass.cj:27](../port/src/onepass.cj#L27) |
| `public func searchAll(text: String): Array<PikeMatch>` | method | [port/src/onepass.cj:30](../port/src/onepass.cj#L30) |

## PikeCache

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class PikeCache` | class | [port/src/pikevm.cj:8](../port/src/pikevm.cj#L8) |
| `public func reset(): Unit` | method | [port/src/pikevm.cj:20](../port/src/pikevm.cj#L20) |
| `public func captureWorkspace(): Int64` | method | [port/src/pikevm.cj:31](../port/src/pikevm.cj#L31) |
| `public func activeThreads(): Int64` | method | [port/src/pikevm.cj:73](../port/src/pikevm.cj#L73) |
| `public func hasMatch(): Bool` | method | [port/src/pikevm.cj:109](../port/src/pikevm.cj#L109) |
| `public func patternId(): Int64` | method | [port/src/pikevm.cj:112](../port/src/pikevm.cj#L112) |
| `public func groupStart(index: Int64): Int64` | method | [port/src/pikevm.cj:115](../port/src/pikevm.cj#L115) |
| `public func groupEnd(index: Int64): Int64` | method | [port/src/pikevm.cj:122](../port/src/pikevm.cj#L122) |

## PikeMatch

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class PikeMatch` | class | [port/src/pikevm.cj:153](../port/src/pikevm.cj#L153) |
| `public let pattern: Int64` | field | [port/src/pikevm.cj:154](../port/src/pikevm.cj#L154) |
| `public let captures: Captures` | field | [port/src/pikevm.cj:155](../port/src/pikevm.cj#L155) |
| `public init(pattern: Int64, captures: Captures)` | constructor | [port/src/pikevm.cj:156](../port/src/pikevm.cj#L156) |
| `public func start(): Int64` | method | [port/src/pikevm.cj:160](../port/src/pikevm.cj#L160) |
| `public func end(): Int64` | method | [port/src/pikevm.cj:166](../port/src/pikevm.cj#L166) |

## PikeVM

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class PikeVM` | class | [port/src/pikevm.cj:174](../port/src/pikevm.cj#L174) |
| `public let cache: PikeCache` | field | [port/src/pikevm.cj:176](../port/src/pikevm.cj#L176) |
| `public init(pattern: String)` | constructor | [port/src/pikevm.cj:177](../port/src/pikevm.cj#L177) |
| `public init(patterns: Array<String>)` | constructor | [port/src/pikevm.cj:180](../port/src/pikevm.cj#L180) |
| `public init(patterns: Array<String>, whichCaptures: Int64)` | constructor | [port/src/pikevm.cj:183](../port/src/pikevm.cj#L183) |
| `public init(hir: Hir)` | constructor | [port/src/pikevm.cj:187](../port/src/pikevm.cj#L187) |
| `public init(hirs: Array<Hir>)` | constructor | [port/src/pikevm.cj:190](../port/src/pikevm.cj#L190) |
| `public func patternCount(): Int64` | method | [port/src/pikevm.cj:194](../port/src/pikevm.cj#L194) |
| `public func memoryUsage(): Int64` | method | [port/src/pikevm.cj:197](../port/src/pikevm.cj#L197) |
| `public func reset(): Unit` | method | [port/src/pikevm.cj:200](../port/src/pikevm.cj#L200) |
| `public func graph(): ThompsonNfa` | method | [port/src/pikevm.cj:203](../port/src/pikevm.cj#L203) |
| `public func stateCount(pattern: Int64): Int64` | method | [port/src/pikevm.cj:206](../port/src/pikevm.cj#L206) |
| `public func startState(pattern: Int64): Int64` | method | [port/src/pikevm.cj:209](../port/src/pikevm.cj#L209) |
| `public func opName(pattern: Int64, state: Int64): String` | method | [port/src/pikevm.cj:212](../port/src/pikevm.cj#L212) |
| `public func opNext(pattern: Int64, state: Int64): Int64` | method | [port/src/pikevm.cj:215](../port/src/pikevm.cj#L215) |
| `public func opAlternate(pattern: Int64, state: Int64): Int64` | method | [port/src/pikevm.cj:218](../port/src/pikevm.cj#L218) |
| `public func whichOverlapping(text: String): Array<Int64>` | method | [port/src/pikevm.cj:221](../port/src/pikevm.cj#L221) |
| `public func whichOverlapping(input: SearchInput): Array<Int64>` | method | [port/src/pikevm.cj:224](../port/src/pikevm.cj#L224) |
| `public func searchEarliest(text: String): Option<PikeMatch>` | method | [port/src/pikevm.cj:227](../port/src/pikevm.cj#L227) |
| `public func search(text: String): Option<PikeMatch>` | method | [port/src/pikevm.cj:230](../port/src/pikevm.cj#L230) |
| `public func search(text: String, start: Int64, end: Int64, anchored: Bool): Option<PikeMatch>` | method | [port/src/pikevm.cj:233](../port/src/pikevm.cj#L233) |
| `public func search(input: SearchInput): Option<PikeMatch>` | method | [port/src/pikevm.cj:236](../port/src/pikevm.cj#L236) |
| `public func isMatch(input: SearchInput): Bool` | method | [port/src/pikevm.cj:239](../port/src/pikevm.cj#L239) |
| `public func searchAll(text: String): Array<PikeMatch>` | method | [port/src/pikevm.cj:244](../port/src/pikevm.cj#L244) |

## Regex

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Regex` | class | [port/src/nfa.cj:519](../port/src/nfa.cj#L519) |
| `public init(pattern: String)` | constructor | [port/src/nfa.cj:528](../port/src/nfa.cj#L528) |
| `public func asStr(): String` | method | [port/src/nfa.cj:663](../port/src/nfa.cj#L663) |
| `public func staticCapturesLen(): Option<Int64>` | method | [port/src/nfa.cj:666](../port/src/nfa.cj#L666) |
| `public func searchEarliest(text: String): Option<Captures>` | method | [port/src/nfa.cj:806](../port/src/nfa.cj#L806) |
| `public func find(text: String): Option<RegexMatch>` | method | [port/src/nfa.cj:813](../port/src/nfa.cj#L813) |
| `public func isMatch(text: String): Bool` | method | [port/src/nfa.cj:825](../port/src/nfa.cj#L825) |
| `public func findAt(text: String, start: Int64): Option<RegexMatch>` | method | [port/src/nfa.cj:836](../port/src/nfa.cj#L836) |
| `public func isMatchAt(text: String, start: Int64): Bool` | method | [port/src/nfa.cj:844](../port/src/nfa.cj#L844) |
| `public func shortestMatch(text: String): Option<Int64>` | method | [port/src/nfa.cj:850](../port/src/nfa.cj#L850) |
| `public func shortestMatchAt(text: String, start: Int64): Option<Int64>` | method | [port/src/nfa.cj:853](../port/src/nfa.cj#L853) |
| `public func capturesAt(text: String, start: Int64): Option<Captures>` | method | [port/src/nfa.cj:861](../port/src/nfa.cj#L861) |
| `public func findIter(text: String): MatchIter` | method | [port/src/nfa.cj:886](../port/src/nfa.cj#L886) |
| `public func capturesIter(text: String): CaptureIter` | method | [port/src/nfa.cj:895](../port/src/nfa.cj#L895) |
| `public func splitIter(text: String): SplitIter` | method | [port/src/nfa.cj:904](../port/src/nfa.cj#L904) |
| `public func splitNIter(text: String, limit: Int64): SplitIter` | method | [port/src/nfa.cj:907](../port/src/nfa.cj#L907) |
| `public func captureLocations(): CaptureLocations` | method | [port/src/nfa.cj:960](../port/src/nfa.cj#L960) |
| `public func capturesRead(locations: CaptureLocations, text: String): Option<RegexMatch>` | method | [port/src/nfa.cj:963](../port/src/nfa.cj#L963) |
| `public func capturesReadAt(locations: CaptureLocations, text: String, start: Int64): Option<RegexMatch>` | method | [port/src/nfa.cj:966](../port/src/nfa.cj#L966) |
| `public func findAll(text: String): Array<RegexMatch>` | method | [port/src/nfa.cj:992](../port/src/nfa.cj#L992) |
| `public func capturesLen(): Int64` | method | [port/src/nfa.cj:1016](../port/src/nfa.cj#L1016) |
| `public func captureNames(): Array<Option<String>>` | method | [port/src/nfa.cj:1019](../port/src/nfa.cj#L1019) |
| `public func captures(text: String): Option<Captures>` | method | [port/src/nfa.cj:1044](../port/src/nfa.cj#L1044) |
| `public func capturesAll(text: String): Array<Captures>` | method | [port/src/nfa.cj:1051](../port/src/nfa.cj#L1051) |
| `public func replace(text: String, replacement: String): String` | method | [port/src/nfa.cj:1071](../port/src/nfa.cj#L1071) |
| `public func replaceAll(text: String, replacement: String): String` | method | [port/src/nfa.cj:1074](../port/src/nfa.cj#L1074) |
| `public func replaceN(text: String, limit: Int64, replacement: String): String` | method | [port/src/nfa.cj:1078](../port/src/nfa.cj#L1078) |
| `public func replaceLiteral(text: String, limit: Int64, replacement: String): String` | method | [port/src/nfa.cj:1091](../port/src/nfa.cj#L1091) |
| `public func replaceWith(text: String, limit: Int64, replacer: (Captures) -> String): String` | method | [port/src/nfa.cj:1094](../port/src/nfa.cj#L1094) |
| `public func split(text: String): Array<String>` | method | [port/src/nfa.cj:1128](../port/src/nfa.cj#L1128) |
| `public func splitN(text: String, limit: Int64): Array<String>` | method | [port/src/nfa.cj:1132](../port/src/nfa.cj#L1132) |
| `public func nfaStateCount(): Int64` | method | [port/src/nfa.cj:1168](../port/src/nfa.cj#L1168) |
| `public func nfaStart(): Int64` | method | [port/src/nfa.cj:1171](../port/src/nfa.cj#L1171) |
| `public func nfaOp(index: Int64): String` | method | [port/src/nfa.cj:1174](../port/src/nfa.cj#L1174) |
| `public func nfaNext(index: Int64): Int64` | method | [port/src/nfa.cj:1188](../port/src/nfa.cj#L1188) |
| `public func nfaAlternate(index: Int64): Int64` | method | [port/src/nfa.cj:1194](../port/src/nfa.cj#L1194) |
| `public func searchWindow(text: String, start: Int64, end: Int64, anchored: Bool): Option<Captures>` | method | [port/src/nfa.cj:1200](../port/src/nfa.cj#L1200) |

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
| `public class RegexMatch` | class | [port/src/nfa.cj:249](../port/src/nfa.cj#L249) |
| `public let start: Int64` | field | [port/src/nfa.cj:250](../port/src/nfa.cj#L250) |
| `public let end: Int64` | field | [port/src/nfa.cj:251](../port/src/nfa.cj#L251) |
| `public let text: String` | field | [port/src/nfa.cj:252](../port/src/nfa.cj#L252) |
| `public func isEmpty(): Bool` | method | [port/src/nfa.cj:258](../port/src/nfa.cj#L258) |
| `public func len(): Int64` | method | [port/src/nfa.cj:261](../port/src/nfa.cj#L261) |
| `public func asStr(): String` | method | [port/src/nfa.cj:264](../port/src/nfa.cj#L264) |

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

## ReverseMatch

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class ReverseMatch` | class | [port/src/reverse.cj:8](../port/src/reverse.cj#L8) |
| `public let pattern: Int64` | field | [port/src/reverse.cj:9](../port/src/reverse.cj#L9) |
| `public let offset: Int64` | field | [port/src/reverse.cj:10](../port/src/reverse.cj#L10) |
| `public init(pattern: Int64, offset: Int64)` | constructor | [port/src/reverse.cj:11](../port/src/reverse.cj#L11) |

## ReverseNfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class ReverseNfa` | class | [port/src/reverse.cj:17](../port/src/reverse.cj#L17) |
| `public init(pattern: String)` | constructor | [port/src/reverse.cj:26](../port/src/reverse.cj#L26) |
| `public init(patterns: Array<String>)` | constructor | [port/src/reverse.cj:29](../port/src/reverse.cj#L29) |
| `public init(patterns: Array<String>, patternStarts: Bool)` | constructor | [port/src/reverse.cj:32](../port/src/reverse.cj#L32) |
| `public init(patterns: Array<String>, patternStarts: Bool, sizeLimit: Int64)` | constructor | [port/src/reverse.cj:35](../port/src/reverse.cj#L35) |
| `public func search(text: String): Option<Int64>` | method | [port/src/reverse.cj:108](../port/src/reverse.cj#L108) |
| `public func search(input: SearchInput): Option<Int64>` | method | [port/src/reverse.cj:114](../port/src/reverse.cj#L114) |
| `public func find(input: SearchInput): Option<ReverseMatch>` | method | [port/src/reverse.cj:120](../port/src/reverse.cj#L120) |

## Rure

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Rure` | class | [port/src/rure.cj:6](../port/src/rure.cj#L6) |
| `public init(pattern: String)` | constructor | [port/src/rure.cj:8](../port/src/rure.cj#L8) |
| `public func isMatch(text: String): Bool` | method | [port/src/rure.cj:11](../port/src/rure.cj#L11) |
| `public func find(text: String): Option<RegexMatch>` | method | [port/src/rure.cj:14](../port/src/rure.cj#L14) |
| `public func findAt(text: String, at: Int64): Option<RegexMatch>` | method | [port/src/rure.cj:17](../port/src/rure.cj#L17) |

## SearchInput

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SearchInput` | class | [port/src/search_input.cj:78](../port/src/search_input.cj#L78) |
| `public let bytes: Array<UInt8>` | field | [port/src/search_input.cj:79](../port/src/search_input.cj#L79) |
| `public let text: String` | field | [port/src/search_input.cj:80](../port/src/search_input.cj#L80) |
| `public let utf8: Bool` | field | [port/src/search_input.cj:81](../port/src/search_input.cj#L81) |
| `public let start: Int64` | field | [port/src/search_input.cj:82](../port/src/search_input.cj#L82) |
| `public let end: Int64` | field | [port/src/search_input.cj:83](../port/src/search_input.cj#L83) |
| `public let anchor: Int64` | field | [port/src/search_input.cj:84](../port/src/search_input.cj#L84) |
| `public let pattern: Int64` | field | [port/src/search_input.cj:85](../port/src/search_input.cj#L85) |
| `public let earliest: Bool` | field | [port/src/search_input.cj:86](../port/src/search_input.cj#L86) |
| `public init(text: String)` | constructor | [port/src/search_input.cj:87](../port/src/search_input.cj#L87) |
| `public init(bytes: Array<UInt8>)` | constructor | [port/src/search_input.cj:90](../port/src/search_input.cj#L90) |
| `public func span(start: Int64, end: Int64): SearchInput` | method | [port/src/search_input.cj:110](../port/src/search_input.cj#L110) |
| `public func anchored(yes: Bool): SearchInput` | method | [port/src/search_input.cj:113](../port/src/search_input.cj#L113) |
| `public func selectPattern(id: Int64): SearchInput` | method | [port/src/search_input.cj:120](../port/src/search_input.cj#L120) |
| `public func withEarliest(yes: Bool): SearchInput` | method | [port/src/search_input.cj:123](../port/src/search_input.cj#L123) |
| `public func isAnchored(): Bool` | method | [port/src/search_input.cj:126](../port/src/search_input.cj#L126) |
| `public func selectedPattern(): Int64` | method | [port/src/search_input.cj:129](../port/src/search_input.cj#L129) |

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
| `public class SparseDfa` | class | [port/src/dfa.cj:1195](../port/src/dfa.cj#L1195) |
| `public init(pattern: String)` | constructor | [port/src/dfa.cj:1197](../port/src/dfa.cj#L1197) |
| `public init(pattern: String, quit: Array<UInt8>)` | constructor | [port/src/dfa.cj:1200](../port/src/dfa.cj#L1200) |
| `public init(patterns: Array<String>)` | constructor | [port/src/dfa.cj:1203](../port/src/dfa.cj#L1203) |
| `public init(patterns: Array<String>, quit: Array<UInt8>)` | constructor | [port/src/dfa.cj:1206](../port/src/dfa.cj#L1206) |
| `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool)` | constructor | [port/src/dfa.cj:1209](../port/src/dfa.cj#L1209) |
| `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool, patternStarts: Bool)` | constructor | [port/src/dfa.cj:1212](../port/src/dfa.cj#L1212) |
| `public static func overlap(patterns: Array<String>): SparseDfa` | method | [port/src/dfa.cj:1215](../port/src/dfa.cj#L1215) |
| `public func stateCount(): Int64` | method | [port/src/dfa.cj:1218](../port/src/dfa.cj#L1218) |
| `public func memoryUsage(): Int64` | method | [port/src/dfa.cj:1221](../port/src/dfa.cj#L1221) |
| `public func retainsDenseTable(): Bool` | method | [port/src/dfa.cj:1224](../port/src/dfa.cj#L1224) |
| `public func search(text: String): Option<DfaMatch>` | method | [port/src/dfa.cj:1227](../port/src/dfa.cj#L1227) |
| `public func search(input: SearchInput): Option<DfaMatch>` | method | [port/src/dfa.cj:1230](../port/src/dfa.cj#L1230) |
| `public func searchOverlapping(text: String): Array<DfaHalf>` | method | [port/src/dfa.cj:1233](../port/src/dfa.cj#L1233) |
| `public func searchOverlapping(input: SearchInput): Array<DfaHalf>` | method | [port/src/dfa.cj:1236](../port/src/dfa.cj#L1236) |

## SplitIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SplitIter` | class | [port/src/nfa.cj:1254](../port/src/nfa.cj#L1254) |
| `public init(step: (Array<Int64>) -> Option<String>, state: Array<Int64>)` | constructor | [port/src/nfa.cj:1257](../port/src/nfa.cj#L1257) |
| `public func next(): Option<String>` | method | [port/src/nfa.cj:1261](../port/src/nfa.cj#L1261) |
| `public func clone(): SplitIter` | method | [port/src/nfa.cj:1264](../port/src/nfa.cj#L1264) |

## SyntaxParser

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SyntaxParser` | class | [port/src/syntax_ast.cj:1865](../port/src/syntax_ast.cj#L1865) |
| `public var caseInsensitive: Bool = false` | field | [port/src/syntax_ast.cj:1866](../port/src/syntax_ast.cj#L1866) |
| `public var multiLine: Bool = false` | field | [port/src/syntax_ast.cj:1867](../port/src/syntax_ast.cj#L1867) |
| `public var dotAll: Bool = false` | field | [port/src/syntax_ast.cj:1868](../port/src/syntax_ast.cj#L1868) |
| `public var swapGreed: Bool = false` | field | [port/src/syntax_ast.cj:1869](../port/src/syntax_ast.cj#L1869) |
| `public var ignoreWhitespace: Bool = false` | field | [port/src/syntax_ast.cj:1870](../port/src/syntax_ast.cj#L1870) |
| `public var crlf: Bool = false` | field | [port/src/syntax_ast.cj:1871](../port/src/syntax_ast.cj#L1871) |
| `public var unicode: Bool = true` | field | [port/src/syntax_ast.cj:1872](../port/src/syntax_ast.cj#L1872) |
| `public var utf8: Bool = true` | field | [port/src/syntax_ast.cj:1873](../port/src/syntax_ast.cj#L1873) |
| `public var octal: Bool = false` | field | [port/src/syntax_ast.cj:1874](../port/src/syntax_ast.cj#L1874) |
| `public var nestLimit: Int64 = 250` | field | [port/src/syntax_ast.cj:1875](../port/src/syntax_ast.cj#L1875) |
| `public init()` | constructor | [port/src/syntax_ast.cj:1876](../port/src/syntax_ast.cj#L1876) |
| `public func parseAst(pattern: String): Ast` | method | [port/src/syntax_ast.cj:1877](../port/src/syntax_ast.cj#L1877) |
| `public func parseHir(pattern: String): Hir` | method | [port/src/syntax_ast.cj:1894](../port/src/syntax_ast.cj#L1894) |
| `public func translate(ast: Ast): Hir` | method | [port/src/syntax_ast.cj:1899](../port/src/syntax_ast.cj#L1899) |

## ThompsonNfa

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class ThompsonNfa` | class | [port/src/thompson.cj:242](../port/src/thompson.cj#L242) |
| `public init(patterns: Array<String>)` | constructor | [port/src/thompson.cj:245](../port/src/thompson.cj#L245) |
| `public init(patterns: Array<String>, whichCaptures: Int64)` | constructor | [port/src/thompson.cj:248](../port/src/thompson.cj#L248) |
| `public init(hirs: Array<Hir>)` | constructor | [port/src/thompson.cj:252](../port/src/thompson.cj#L252) |
| `public init(patterns: Array<String>, whichCaptures: Int64, unicode: Bool)` | constructor | [port/src/thompson.cj:255](../port/src/thompson.cj#L255) |
| `public init(hirs: Array<Hir>, sizeLimit: Int64)` | constructor | [port/src/thompson.cj:259](../port/src/thompson.cj#L259) |
| `public func stateCount(): Int64` | method | [port/src/thompson.cj:287](../port/src/thompson.cj#L287) |
| `public func memoryUsage(): Int64` | method | [port/src/thompson.cj:290](../port/src/thompson.cj#L290) |
| `public func patternCount(): Int64` | method | [port/src/thompson.cj:300](../port/src/thompson.cj#L300) |
| `public func patternStateCount(pattern: Int64): Int64` | method | [port/src/thompson.cj:303](../port/src/thompson.cj#L303) |
| `public func startState(pattern: Int64): Int64` | method | [port/src/thompson.cj:306](../port/src/thompson.cj#L306) |
| `public func opName(pattern: Int64, state: Int64): String` | method | [port/src/thompson.cj:310](../port/src/thompson.cj#L310) |
| `public func opNext(pattern: Int64, state: Int64): Int64` | method | [port/src/thompson.cj:321](../port/src/thompson.cj#L321) |
| `public func opAlternate(pattern: Int64, state: Int64): Int64` | method | [port/src/thompson.cj:324](../port/src/thompson.cj#L324) |
| `public func whichOverlapping(text: String): Array<Int64>` | method | [port/src/thompson.cj:327](../port/src/thompson.cj#L327) |
| `public func whichOverlapping(input: SearchInput): Array<Int64>` | method | [port/src/thompson.cj:333](../port/src/thompson.cj#L333) |
| `public func search(input: SearchInput, cache: PikeCache): Option<PikeMatch>` | method | [port/src/thompson.cj:424](../port/src/thompson.cj#L424) |
| `public func isMatch(input: SearchInput, cache: PikeCache): Bool` | method | [port/src/thompson.cj:466](../port/src/thompson.cj#L466) |

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
| `public func debugByte(byte: Int64): String` | function | [port/src/search_input.cj:50](../port/src/search_input.cj#L50) |
| `public func hirLookName(look: HirLook): String` | function | [port/src/syntax_hir.cj:1494](../port/src/syntax_hir.cj#L1494) |
| `public func extractLiterals(hir: Hir): LiteralSeq` | function | [port/src/syntax_literal.cj:205](../port/src/syntax_literal.cj#L205) |
| `public func extractLiterals(hir: Hir, suffix: Bool): LiteralSeq` | function | [port/src/syntax_literal.cj:209](../port/src/syntax_literal.cj#L209) |
| `public func extractLiterals(hir: Hir, suffix: Bool, limits: LiteralLimits): LiteralSeq` | function | [port/src/syntax_literal.cj:213](../port/src/syntax_literal.cj#L213) |
| `public func formatLiterals(hir: Hir, suffix: Bool): String` | function | [port/src/syntax_literal.cj:218](../port/src/syntax_literal.cj#L218) |
| `public func formatLiterals(hir: Hir, suffix: Bool, limits: LiteralLimits): String` | function | [port/src/syntax_literal.cj:222](../port/src/syntax_literal.cj#L222) |
| `public func formatLiteralSeq(seq: LiteralSeq): String` | function | [port/src/syntax_literal.cj:243](../port/src/syntax_literal.cj#L243) |
| `public func formatCommon(bytes: Option<Array<UInt8>>): String` | function | [port/src/syntax_literal.cj:261](../port/src/syntax_literal.cj#L261) |
| `public func utf8SequenceLines(start: Int64, end: Int64): String` | function | [port/src/utf8seq.cj:29](../port/src/utf8seq.cj#L29) |
| `public func utf8SequencesOf(start: Int64, end: Int64): Array<Utf8Sequence>` | function | [port/src/utf8seq.cj:41](../port/src/utf8seq.cj#L41) |
