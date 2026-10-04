# 当前仓颉公开接口清单

由`scripts/generate_api_catalog.py`从仓库源码生成；可用`--check`检查是否过期。

当前显式公开调用入口 **280** 个，公开字段（含var） **84** 个；类型数量见下表。重复名称在不同类型/重载上分别计数，不计继承方法，不把枚举分支当作函数。

这是声明扫描，不是完整语言解析器，也不是原仓库覆盖率。主要库的170条固有方法映射仍见[接口审计](api-audit.md)，语法/自动机的差异见[复核结论](review-2026-10-04.md)。调用行为见[API](api.md)与[语法说明](hir.md)。

| 类别 | 数量 |
|---|---:|
| class | 42 |
| constructor | 30 |
| enum | 4 |
| field | 84 |
| function | 2 |
| method | 248 |

## Ast

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Ast` | class | [port/src/syntax_ast.cj:71](../port/src/syntax_ast.cj#L71) |
| `public let label: String` | field | [port/src/syntax_ast.cj:72](../port/src/syntax_ast.cj#L72) |
| `public let span: AstSpan` | field | [port/src/syntax_ast.cj:73](../port/src/syntax_ast.cj#L73) |
| `public var code: Int64` | field | [port/src/syntax_ast.cj:74](../port/src/syntax_ast.cj#L74) |
| `public var greedy: Bool` | field | [port/src/syntax_ast.cj:75](../port/src/syntax_ast.cj#L75) |
| `public var negated: Bool` | field | [port/src/syntax_ast.cj:76](../port/src/syntax_ast.cj#L76) |
| `public var captureIndex: Int64` | field | [port/src/syntax_ast.cj:77](../port/src/syntax_ast.cj#L77) |
| `public var captureName: String` | field | [port/src/syntax_ast.cj:78](../port/src/syntax_ast.cj#L78) |
| `public var startsWithP: Bool` | field | [port/src/syntax_ast.cj:79](../port/src/syntax_ast.cj#L79) |
| `public var quantifier: String` | field | [port/src/syntax_ast.cj:80](../port/src/syntax_ast.cj#L80) |
| `public var minimum: Int64` | field | [port/src/syntax_ast.cj:81](../port/src/syntax_ast.cj#L81) |
| `public var maximum: Int64` | field | [port/src/syntax_ast.cj:82](../port/src/syntax_ast.cj#L82) |
| `public var classItem: AstClassItem` | field | [port/src/syntax_ast.cj:83](../port/src/syntax_ast.cj#L83) |
| `public var flagMask: Int64` | field | [port/src/syntax_ast.cj:86](../port/src/syntax_ast.cj#L86) |
| `public var flagValue: Int64` | field | [port/src/syntax_ast.cj:87](../port/src/syntax_ast.cj#L87) |
| `public var baseCaseInsensitive: Bool` | field | [port/src/syntax_ast.cj:88](../port/src/syntax_ast.cj#L88) |
| `public var baseMultiLine: Bool` | field | [port/src/syntax_ast.cj:89](../port/src/syntax_ast.cj#L89) |
| `public var baseDotAll: Bool` | field | [port/src/syntax_ast.cj:90](../port/src/syntax_ast.cj#L90) |
| `public var baseSwapGreed: Bool` | field | [port/src/syntax_ast.cj:91](../port/src/syntax_ast.cj#L91) |
| `public var baseIgnoreWhitespace: Bool` | field | [port/src/syntax_ast.cj:92](../port/src/syntax_ast.cj#L92) |
| `public var baseCrlf: Bool` | field | [port/src/syntax_ast.cj:93](../port/src/syntax_ast.cj#L93) |
| `public var baseUnicode: Bool` | field | [port/src/syntax_ast.cj:94](../port/src/syntax_ast.cj#L94) |
| `public func subs(): Array<Ast>` | method | [port/src/syntax_ast.cj:120](../port/src/syntax_ast.cj#L120) |
| `public func visit(enter: (Ast) -> Unit): Unit` | method | [port/src/syntax_ast.cj:123](../port/src/syntax_ast.cj#L123) |
| `public func walk(enter: (Ast) -> Unit, leave: (Ast) -> Unit): Unit` | method | [port/src/syntax_ast.cj:129](../port/src/syntax_ast.cj#L129) |
| `public func walkUntil(enter: (Ast) -> Bool, leave: (Ast) -> Bool): Bool` | method | [port/src/syntax_ast.cj:137](../port/src/syntax_ast.cj#L137) |
| `public func shape(): String` | method | [port/src/syntax_ast.cj:149](../port/src/syntax_ast.cj#L149) |
| `public func toPattern(): String` | method | [port/src/syntax_ast.cj:166](../port/src/syntax_ast.cj#L166) |
| `public func toHir(): Hir` | method | [port/src/syntax_ast.cj:171](../port/src/syntax_ast.cj#L171) |
| `public static func parse(pattern: String): Ast` | method | [port/src/syntax_ast.cj:174](../port/src/syntax_ast.cj#L174) |

## AstClassItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class AstClassItem` | class | [port/src/syntax_ast.cj:29](../port/src/syntax_ast.cj#L29) |
| `public let label: String` | field | [port/src/syntax_ast.cj:30](../port/src/syntax_ast.cj#L30) |
| `public let start: Int64` | field | [port/src/syntax_ast.cj:31](../port/src/syntax_ast.cj#L31) |
| `public let end: Int64` | field | [port/src/syntax_ast.cj:32](../port/src/syntax_ast.cj#L32) |
| `public let negated: Bool` | field | [port/src/syntax_ast.cj:33](../port/src/syntax_ast.cj#L33) |
| `public let children: Array<AstClassItem>` | field | [port/src/syntax_ast.cj:34](../port/src/syntax_ast.cj#L34) |
| `public let name: String` | field | [port/src/syntax_ast.cj:35](../port/src/syntax_ast.cj#L35) |
| `public init(label: String, start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String)` | constructor | [port/src/syntax_ast.cj:36](../port/src/syntax_ast.cj#L36) |
| `public func text(): String` | method | [port/src/syntax_ast.cj:44](../port/src/syntax_ast.cj#L44) |

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

## BytesCaptureIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesCaptureIter` | class | [port/src/bytes.cj:955](../port/src/bytes.cj#L955) |
| `public init(pull: () -> Option<BytesCaptures>)` | constructor | [port/src/bytes.cj:957](../port/src/bytes.cj#L957) |
| `public func next(): Option<BytesCaptures>` | method | [port/src/bytes.cj:960](../port/src/bytes.cj#L960) |

## BytesCaptures

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesCaptures` | class | [port/src/bytes.cj:591](../port/src/bytes.cj#L591) |
| `public let size: Int64` | field | [port/src/bytes.cj:595](../port/src/bytes.cj#L595) |
| `public func getMatch(): BytesMatch` | method | [port/src/bytes.cj:602](../port/src/bytes.cj#L602) |
| `public func get(index: Int64): Option<BytesMatch>` | method | [port/src/bytes.cj:608](../port/src/bytes.cj#L608) |
| `public func iter(): BytesGroupIter` | method | [port/src/bytes.cj:614](../port/src/bytes.cj#L614) |
| `public func extract(count: Int64): Array<Array<UInt8>>` | method | [port/src/bytes.cj:617](../port/src/bytes.cj#L617) |
| `public func name(value: String): Option<BytesMatch>` | method | [port/src/bytes.cj:643](../port/src/bytes.cj#L643) |
| `public func expand(template: Array<UInt8>): Array<UInt8>` | method | [port/src/bytes.cj:655](../port/src/bytes.cj#L655) |
| `public func expandInto(template: Array<UInt8>, out: ArrayList<UInt8>): Unit` | method | [port/src/bytes.cj:660](../port/src/bytes.cj#L660) |

## BytesGroupItem

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesGroupItem` | class | [port/src/bytes.cj:741](../port/src/bytes.cj#L741) |
| `public let done: Bool` | field | [port/src/bytes.cj:742](../port/src/bytes.cj#L742) |
| `public let value: Option<BytesMatch>` | field | [port/src/bytes.cj:743](../port/src/bytes.cj#L743) |

## BytesGroupIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class BytesGroupIter` | class | [port/src/bytes.cj:750](../port/src/bytes.cj#L750) |
| `public func len(): Int64` | method | [port/src/bytes.cj:757](../port/src/bytes.cj#L757) |
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
| `public init(pull: () -> Option<BytesMatch>)` | constructor | [port/src/bytes.cj:947](../port/src/bytes.cj#L947) |
| `public func next(): Option<BytesMatch>` | method | [port/src/bytes.cj:950](../port/src/bytes.cj#L950) |

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
| `public class BytesSplitIter` | class | [port/src/bytes.cj:965](../port/src/bytes.cj#L965) |
| `public init(pull: () -> Option<Array<UInt8>>)` | constructor | [port/src/bytes.cj:967](../port/src/bytes.cj#L967) |
| `public func next(): Option<Array<UInt8>>` | method | [port/src/bytes.cj:970](../port/src/bytes.cj#L970) |

## CaptureIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class CaptureIter` | class | [port/src/nfa.cj:1231](../port/src/nfa.cj#L1231) |
| `public init(pull: () -> Option<Captures>)` | constructor | [port/src/nfa.cj:1233](../port/src/nfa.cj#L1233) |
| `public func next(): Option<Captures>` | method | [port/src/nfa.cj:1236](../port/src/nfa.cj#L1236) |

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

## MatchIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class MatchIter` | class | [port/src/nfa.cj:1221](../port/src/nfa.cj#L1221) |
| `public init(pull: () -> Option<RegexMatch>)` | constructor | [port/src/nfa.cj:1223](../port/src/nfa.cj#L1223) |
| `public func next(): Option<RegexMatch>` | method | [port/src/nfa.cj:1226](../port/src/nfa.cj#L1226) |

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
| `public func search(text: String): Option<PikeMatch>` | method | [port/src/pikevm.cj:122](../port/src/pikevm.cj#L122) |
| `public func search(text: String, start: Int64, end: Int64, anchored: Bool): Option<PikeMatch>` | method | [port/src/pikevm.cj:125](../port/src/pikevm.cj#L125) |

## Regex

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class Regex` | class | [port/src/nfa.cj:509](../port/src/nfa.cj#L509) |
| `public init(pattern: String)` | constructor | [port/src/nfa.cj:518](../port/src/nfa.cj#L518) |
| `public func asStr(): String` | method | [port/src/nfa.cj:653](../port/src/nfa.cj#L653) |
| `public func staticCapturesLen(): Option<Int64>` | method | [port/src/nfa.cj:656](../port/src/nfa.cj#L656) |
| `public func find(text: String): Option<RegexMatch>` | method | [port/src/nfa.cj:792](../port/src/nfa.cj#L792) |
| `public func isMatch(text: String): Bool` | method | [port/src/nfa.cj:804](../port/src/nfa.cj#L804) |
| `public func findAt(text: String, start: Int64): Option<RegexMatch>` | method | [port/src/nfa.cj:815](../port/src/nfa.cj#L815) |
| `public func isMatchAt(text: String, start: Int64): Bool` | method | [port/src/nfa.cj:823](../port/src/nfa.cj#L823) |
| `public func shortestMatch(text: String): Option<Int64>` | method | [port/src/nfa.cj:829](../port/src/nfa.cj#L829) |
| `public func shortestMatchAt(text: String, start: Int64): Option<Int64>` | method | [port/src/nfa.cj:832](../port/src/nfa.cj#L832) |
| `public func capturesAt(text: String, start: Int64): Option<Captures>` | method | [port/src/nfa.cj:840](../port/src/nfa.cj#L840) |
| `public func findIter(text: String): MatchIter` | method | [port/src/nfa.cj:848](../port/src/nfa.cj#L848) |
| `public func capturesIter(text: String): CaptureIter` | method | [port/src/nfa.cj:872](../port/src/nfa.cj#L872) |
| `public func splitIter(text: String): SplitIter` | method | [port/src/nfa.cj:896](../port/src/nfa.cj#L896) |
| `public func splitNIter(text: String, limit: Int64): SplitIter` | method | [port/src/nfa.cj:936](../port/src/nfa.cj#L936) |
| `public func captureLocations(): CaptureLocations` | method | [port/src/nfa.cj:965](../port/src/nfa.cj#L965) |
| `public func capturesRead(locations: CaptureLocations, text: String): Option<RegexMatch>` | method | [port/src/nfa.cj:968](../port/src/nfa.cj#L968) |
| `public func capturesReadAt(locations: CaptureLocations, text: String, start: Int64): Option<RegexMatch>` | method | [port/src/nfa.cj:971](../port/src/nfa.cj#L971) |
| `public func findAll(text: String): Array<RegexMatch>` | method | [port/src/nfa.cj:997](../port/src/nfa.cj#L997) |
| `public func capturesLen(): Int64` | method | [port/src/nfa.cj:1021](../port/src/nfa.cj#L1021) |
| `public func captureNames(): Array<Option<String>>` | method | [port/src/nfa.cj:1024](../port/src/nfa.cj#L1024) |
| `public func captures(text: String): Option<Captures>` | method | [port/src/nfa.cj:1049](../port/src/nfa.cj#L1049) |
| `public func capturesAll(text: String): Array<Captures>` | method | [port/src/nfa.cj:1056](../port/src/nfa.cj#L1056) |
| `public func replace(text: String, replacement: String): String` | method | [port/src/nfa.cj:1076](../port/src/nfa.cj#L1076) |
| `public func replaceAll(text: String, replacement: String): String` | method | [port/src/nfa.cj:1079](../port/src/nfa.cj#L1079) |
| `public func replaceN(text: String, limit: Int64, replacement: String): String` | method | [port/src/nfa.cj:1083](../port/src/nfa.cj#L1083) |
| `public func replaceLiteral(text: String, limit: Int64, replacement: String): String` | method | [port/src/nfa.cj:1096](../port/src/nfa.cj#L1096) |
| `public func replaceWith(text: String, limit: Int64, replacer: (Captures) -> String): String` | method | [port/src/nfa.cj:1099](../port/src/nfa.cj#L1099) |
| `public func split(text: String): Array<String>` | method | [port/src/nfa.cj:1133](../port/src/nfa.cj#L1133) |
| `public func splitN(text: String, limit: Int64): Array<String>` | method | [port/src/nfa.cj:1137](../port/src/nfa.cj#L1137) |
| `public func nfaStateCount(): Int64` | method | [port/src/nfa.cj:1173](../port/src/nfa.cj#L1173) |
| `public func nfaStart(): Int64` | method | [port/src/nfa.cj:1176](../port/src/nfa.cj#L1176) |
| `public func nfaOp(index: Int64): String` | method | [port/src/nfa.cj:1179](../port/src/nfa.cj#L1179) |
| `public func nfaNext(index: Int64): Int64` | method | [port/src/nfa.cj:1193](../port/src/nfa.cj#L1193) |
| `public func nfaAlternate(index: Int64): Int64` | method | [port/src/nfa.cj:1199](../port/src/nfa.cj#L1199) |
| `public func searchWindow(text: String, start: Int64, end: Int64, anchored: Bool): Option<Captures>` | method | [port/src/nfa.cj:1205](../port/src/nfa.cj#L1205) |

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
| `public class RegexMatch` | class | [port/src/nfa.cj:239](../port/src/nfa.cj#L239) |
| `public let start: Int64` | field | [port/src/nfa.cj:240](../port/src/nfa.cj#L240) |
| `public let end: Int64` | field | [port/src/nfa.cj:241](../port/src/nfa.cj#L241) |
| `public let text: String` | field | [port/src/nfa.cj:242](../port/src/nfa.cj#L242) |
| `public func isEmpty(): Bool` | method | [port/src/nfa.cj:248](../port/src/nfa.cj#L248) |
| `public func len(): Int64` | method | [port/src/nfa.cj:251](../port/src/nfa.cj#L251) |
| `public func asStr(): String` | method | [port/src/nfa.cj:254](../port/src/nfa.cj#L254) |

## RegexSet

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class RegexSet` | class | [port/src/regex_set.cj:97](../port/src/regex_set.cj#L97) |
| `public init(patterns: Array<String>)` | constructor | [port/src/regex_set.cj:104](../port/src/regex_set.cj#L104) |
| `public func len(): Int64` | method | [port/src/regex_set.cj:153](../port/src/regex_set.cj#L153) |
| `public func isEmpty(): Bool` | method | [port/src/regex_set.cj:156](../port/src/regex_set.cj#L156) |
| `public func patterns(): Array<String>` | method | [port/src/regex_set.cj:159](../port/src/regex_set.cj#L159) |
| `public func isMatch(text: String): Bool` | method | [port/src/regex_set.cj:162](../port/src/regex_set.cj#L162) |
| `public func isMatchAt(text: String, start: Int64): Bool` | method | [port/src/regex_set.cj:165](../port/src/regex_set.cj#L165) |
| `public func matches(text: String): SetMatches` | method | [port/src/regex_set.cj:168](../port/src/regex_set.cj#L168) |
| `public func matchesAt(text: String, start: Int64): SetMatches` | method | [port/src/regex_set.cj:171](../port/src/regex_set.cj#L171) |
| `public func matchesReadAt(slots: Array<Bool>, text: String, start: Int64): Bool` | method | [port/src/regex_set.cj:176](../port/src/regex_set.cj#L176) |

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
| `public func nextBack(): Option<Int64>` | method | [port/src/regex_set.cj:74](../port/src/regex_set.cj#L74) |
| `public func sizeHint(): (Int64, Option<Int64>)` | method | [port/src/regex_set.cj:84](../port/src/regex_set.cj#L84) |
| `public func clone(): SetMatchesIter` | method | [port/src/regex_set.cj:89](../port/src/regex_set.cj#L89) |

## SplitIter

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SplitIter` | class | [port/src/nfa.cj:1241](../port/src/nfa.cj#L1241) |
| `public init(pull: () -> Option<String>)` | constructor | [port/src/nfa.cj:1243](../port/src/nfa.cj#L1243) |
| `public func next(): Option<String>` | method | [port/src/nfa.cj:1246](../port/src/nfa.cj#L1246) |

## SyntaxParser

| 声明 | 种类 | 实现 |
|---|---|---|
| `public class SyntaxParser` | class | [port/src/syntax_ast.cj:1605](../port/src/syntax_ast.cj#L1605) |
| `public var caseInsensitive = false` | field | [port/src/syntax_ast.cj:1606](../port/src/syntax_ast.cj#L1606) |
| `public var multiLine = false` | field | [port/src/syntax_ast.cj:1607](../port/src/syntax_ast.cj#L1607) |
| `public var dotAll = false` | field | [port/src/syntax_ast.cj:1608](../port/src/syntax_ast.cj#L1608) |
| `public var swapGreed = false` | field | [port/src/syntax_ast.cj:1609](../port/src/syntax_ast.cj#L1609) |
| `public var ignoreWhitespace = false` | field | [port/src/syntax_ast.cj:1610](../port/src/syntax_ast.cj#L1610) |
| `public var crlf = false` | field | [port/src/syntax_ast.cj:1611](../port/src/syntax_ast.cj#L1611) |
| `public var unicode = true` | field | [port/src/syntax_ast.cj:1612](../port/src/syntax_ast.cj#L1612) |
| `public var utf8 = true` | field | [port/src/syntax_ast.cj:1613](../port/src/syntax_ast.cj#L1613) |
| `public var octal = false` | field | [port/src/syntax_ast.cj:1614](../port/src/syntax_ast.cj#L1614) |
| `public var nestLimit: Int64 = 250` | field | [port/src/syntax_ast.cj:1615](../port/src/syntax_ast.cj#L1615) |
| `public init()` | constructor | [port/src/syntax_ast.cj:1616](../port/src/syntax_ast.cj#L1616) |
| `public func parseAst(pattern: String): Ast` | method | [port/src/syntax_ast.cj:1617](../port/src/syntax_ast.cj#L1617) |
| `public func parseHir(pattern: String): Hir` | method | [port/src/syntax_ast.cj:1631](../port/src/syntax_ast.cj#L1631) |
| `public func translate(ast: Ast): Hir` | method | [port/src/syntax_ast.cj:1636](../port/src/syntax_ast.cj#L1636) |

## 顶层函数

| 声明 | 种类 | 实现 |
|---|---|---|
| `public func escape(text: String): String` | function | [port/src/escape.cj:13](../port/src/escape.cj#L13) |
| `public func hirLookName(look: HirLook): String` | function | [port/src/syntax_hir.cj:1468](../port/src/syntax_hir.cj#L1468) |
