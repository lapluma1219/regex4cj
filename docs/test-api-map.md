# 公开接口的功能归属

由当前声明清单生成。包括重载、字段与类型；每条独立保留。

**归属不等于测试覆盖。** 现有批量案例可能调用这些接口，但尚未逐条核实到具体断言，已经核实调用路径的接口关联到具名案例；其余标为待审计。关联只证明所列特性，不代表接口全部行为覆盖。

| 功能组 | 类型 | 声明 | 源码 | 逐接口行为证据 |
|---|---|---|---|---|
| 有界回溯搜索 | BoundedBacktracker | `public class BoundedBacktracker` | [port/src/backtrack.cj:14](../port/src/backtrack.cj#L14) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public init(pattern: String)` | [port/src/backtrack.cj:36](../port/src/backtrack.cj#L36) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public init(pattern: String, visitedCapacity: Int64)` | [port/src/backtrack.cj:39](../port/src/backtrack.cj#L39) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public init(pattern: String, visitedCapacity: Int64, whichCaptures: Int64)` | [port/src/backtrack.cj:42](../port/src/backtrack.cj#L42) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public init(patterns: Array<String>)` | [port/src/backtrack.cj:128](../port/src/backtrack.cj#L128) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public init(patterns: Array<String>, visitedCapacity: Int64)` | [port/src/backtrack.cj:131](../port/src/backtrack.cj#L131) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public init(patterns: Array<String>, visitedCapacity: Int64, whichCaptures: Int64)` | [port/src/backtrack.cj:134](../port/src/backtrack.cj#L134) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func stateCount(): Int64` | [port/src/backtrack.cj:196](../port/src/backtrack.cj#L196) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func memoryUsage(): Int64` | [port/src/backtrack.cj:199](../port/src/backtrack.cj#L199) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func maxHaystackLen(): Int64` | [port/src/backtrack.cj:211](../port/src/backtrack.cj#L211) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func createCache(): BacktrackCache` | [port/src/backtrack.cj:224](../port/src/backtrack.cj#L224) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func searchAll(text: String): Array<PikeMatch>` | [port/src/backtrack.cj:227](../port/src/backtrack.cj#L227) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func searchAll(input: SearchInput): Array<PikeMatch>` | [port/src/backtrack.cj:233](../port/src/backtrack.cj#L233) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func search(text: String): Option<Captures>` | [port/src/backtrack.cj:277](../port/src/backtrack.cj#L277) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func isMatch(input: SearchInput): Bool` | [port/src/backtrack.cj:283](../port/src/backtrack.cj#L283) | 待逐项审计 |
| 有界回溯搜索 | BoundedBacktracker | `public func search(cache: BacktrackCache, input: SearchInput): Option<PikeMatch>` | [port/src/backtrack.cj:311](../port/src/backtrack.cj#L311) | 待逐项审计 |
| 有界回溯搜索 | BacktrackCache | `public class BacktrackCache` | [port/src/backtrack.cj:518](../port/src/backtrack.cj#L518) | 待逐项审计 |
| 有界回溯搜索 | BacktrackCache | `public init()` | [port/src/backtrack.cj:521](../port/src/backtrack.cj#L521) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public class RegexBuilder` | [port/src/builder.cj:9](../port/src/builder.cj#L9) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public init(pattern: String)` | [port/src/builder.cj:12](../port/src/builder.cj#L12) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func build(): Regex` | [port/src/builder.cj:15](../port/src/builder.cj#L15) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func caseInsensitive(yes: Bool): RegexBuilder` | [port/src/builder.cj:18](../port/src/builder.cj#L18) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func multiLine(yes: Bool): RegexBuilder` | [port/src/builder.cj:22](../port/src/builder.cj#L22) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func dotMatchesNewLine(yes: Bool): RegexBuilder` | [port/src/builder.cj:26](../port/src/builder.cj#L26) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func swapGreed(yes: Bool): RegexBuilder` | [port/src/builder.cj:30](../port/src/builder.cj#L30) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func ignoreWhitespace(yes: Bool): RegexBuilder` | [port/src/builder.cj:34](../port/src/builder.cj#L34) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func crlf(yes: Bool): RegexBuilder` | [port/src/builder.cj:38](../port/src/builder.cj#L38) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func unicode(yes: Bool): RegexBuilder` | [port/src/builder.cj:42](../port/src/builder.cj#L42) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func octal(yes: Bool): RegexBuilder` | [port/src/builder.cj:46](../port/src/builder.cj#L46) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func lineTerminator(byte: Rune): RegexBuilder` | [port/src/builder.cj:50](../port/src/builder.cj#L50) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func nestLimit(limit: Int64): RegexBuilder` | [port/src/builder.cj:57](../port/src/builder.cj#L57) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func sizeLimit(limit: Int64): RegexBuilder` | [port/src/builder.cj:64](../port/src/builder.cj#L64) | 待逐项审计 |
| 规则创建与语法选项 | RegexBuilder | `public func dfaSizeLimit(limit: Int64): RegexBuilder` | [port/src/builder.cj:71](../port/src/builder.cj#L71) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public class RegexSetBuilder` | [port/src/builder.cj:80](../port/src/builder.cj#L80) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public init()` | [port/src/builder.cj:83](../port/src/builder.cj#L83) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public init(patterns: Array<String>)` | [port/src/builder.cj:84](../port/src/builder.cj#L84) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func pattern(value: String): RegexSetBuilder` | [port/src/builder.cj:87](../port/src/builder.cj#L87) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func build(): RegexSet` | [port/src/builder.cj:91](../port/src/builder.cj#L91) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func caseInsensitive(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:94](../port/src/builder.cj#L94) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func multiLine(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:98](../port/src/builder.cj#L98) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func dotMatchesNewLine(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:102](../port/src/builder.cj#L102) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func swapGreed(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:106](../port/src/builder.cj#L106) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func ignoreWhitespace(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:110](../port/src/builder.cj#L110) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func crlf(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:114](../port/src/builder.cj#L114) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func unicode(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:118](../port/src/builder.cj#L118) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func octal(yes: Bool): RegexSetBuilder` | [port/src/builder.cj:122](../port/src/builder.cj#L122) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func lineTerminator(byte: Rune): RegexSetBuilder` | [port/src/builder.cj:126](../port/src/builder.cj#L126) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func nestLimit(limit: Int64): RegexSetBuilder` | [port/src/builder.cj:133](../port/src/builder.cj#L133) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func sizeLimit(limit: Int64): RegexSetBuilder` | [port/src/builder.cj:140](../port/src/builder.cj#L140) | 待逐项审计 |
| 规则创建与语法选项 | RegexSetBuilder | `public func dfaSizeLimit(limit: Int64): RegexSetBuilder` | [port/src/builder.cj:147](../port/src/builder.cj#L147) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public class BytesRegexBuilder` | [port/src/builder.cj:157](../port/src/builder.cj#L157) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public init(pattern: String)` | [port/src/builder.cj:160](../port/src/builder.cj#L160) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func build(): BytesRegex` | [port/src/builder.cj:164](../port/src/builder.cj#L164) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func caseInsensitive(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:168](../port/src/builder.cj#L168) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func multiLine(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:172](../port/src/builder.cj#L172) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func dotMatchesNewLine(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:176](../port/src/builder.cj#L176) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func swapGreed(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:180](../port/src/builder.cj#L180) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func ignoreWhitespace(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:184](../port/src/builder.cj#L184) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func crlf(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:188](../port/src/builder.cj#L188) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func unicode(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:192](../port/src/builder.cj#L192) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func octal(yes: Bool): BytesRegexBuilder` | [port/src/builder.cj:196](../port/src/builder.cj#L196) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func lineTerminator(byte: Rune): BytesRegexBuilder` | [port/src/builder.cj:200](../port/src/builder.cj#L200) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func nestLimit(limit: Int64): BytesRegexBuilder` | [port/src/builder.cj:207](../port/src/builder.cj#L207) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func sizeLimit(limit: Int64): BytesRegexBuilder` | [port/src/builder.cj:214](../port/src/builder.cj#L214) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexBuilder | `public func dfaSizeLimit(limit: Int64): BytesRegexBuilder` | [port/src/builder.cj:221](../port/src/builder.cj#L221) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public class BytesRegexSetBuilder` | [port/src/builder.cj:230](../port/src/builder.cj#L230) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public init()` | [port/src/builder.cj:233](../port/src/builder.cj#L233) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public init(patterns: Array<String>)` | [port/src/builder.cj:236](../port/src/builder.cj#L236) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func pattern(value: String): BytesRegexSetBuilder` | [port/src/builder.cj:240](../port/src/builder.cj#L240) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func build(): BytesRegexSet` | [port/src/builder.cj:244](../port/src/builder.cj#L244) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func caseInsensitive(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:248](../port/src/builder.cj#L248) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func multiLine(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:252](../port/src/builder.cj#L252) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func dotMatchesNewLine(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:256](../port/src/builder.cj#L256) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func swapGreed(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:260](../port/src/builder.cj#L260) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func ignoreWhitespace(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:264](../port/src/builder.cj#L264) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func crlf(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:268](../port/src/builder.cj#L268) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func unicode(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:272](../port/src/builder.cj#L272) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func octal(yes: Bool): BytesRegexSetBuilder` | [port/src/builder.cj:276](../port/src/builder.cj#L276) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func lineTerminator(byte: Rune): BytesRegexSetBuilder` | [port/src/builder.cj:280](../port/src/builder.cj#L280) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func nestLimit(limit: Int64): BytesRegexSetBuilder` | [port/src/builder.cj:287](../port/src/builder.cj#L287) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func sizeLimit(limit: Int64): BytesRegexSetBuilder` | [port/src/builder.cj:294](../port/src/builder.cj#L294) | 待逐项审计 |
| 规则创建与语法选项 | BytesRegexSetBuilder | `public func dfaSizeLimit(limit: Int64): BytesRegexSetBuilder` | [port/src/builder.cj:301](../port/src/builder.cj#L301) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public class BytesMatch` | [port/src/bytes.cj:7](../port/src/bytes.cj#L7) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public let start: Int64` | [port/src/bytes.cj:8](../port/src/bytes.cj#L8) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public let end: Int64` | [port/src/bytes.cj:9](../port/src/bytes.cj#L9) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public let bytes: Array<UInt8>` | [port/src/bytes.cj:10](../port/src/bytes.cj#L10) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public init(start: Int64, end: Int64, bytes: Array<UInt8>)` | [port/src/bytes.cj:11](../port/src/bytes.cj#L11) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public func isEmpty(): Bool` | [port/src/bytes.cj:16](../port/src/bytes.cj#L16) | 待逐项审计 |
| 字节数据处理 | BytesMatch | `public func len(): Int64` | [port/src/bytes.cj:19](../port/src/bytes.cj#L19) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public class BytesRegex` | [port/src/bytes.cj:24](../port/src/bytes.cj#L24) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public init(pattern: String)` | [port/src/bytes.cj:33](../port/src/bytes.cj#L33) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func asStr(): String` | [port/src/bytes.cj:96](../port/src/bytes.cj#L96) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func capturesLen(): Int64` | [port/src/bytes.cj:99](../port/src/bytes.cj#L99) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func staticCapturesLen(): Option<Int64>` | [port/src/bytes.cj:102](../port/src/bytes.cj#L102) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func captureNames(): Array<Option<String>>` | [port/src/bytes.cj:109](../port/src/bytes.cj#L109) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func captureLocations(): CaptureLocations` | [port/src/bytes.cj:118](../port/src/bytes.cj#L118) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func find(haystack: Array<UInt8>): Option<BytesMatch>` | [port/src/bytes.cj:121](../port/src/bytes.cj#L121) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func isMatch(haystack: Array<UInt8>): Bool` | [port/src/bytes.cj:124](../port/src/bytes.cj#L124) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func findAt(haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | [port/src/bytes.cj:127](../port/src/bytes.cj#L127) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | [port/src/bytes.cj:133](../port/src/bytes.cj#L133) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func shortestMatch(haystack: Array<UInt8>): Option<Int64>` | [port/src/bytes.cj:139](../port/src/bytes.cj#L139) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func shortestMatchAt(haystack: Array<UInt8>, start: Int64): Option<Int64>` | [port/src/bytes.cj:142](../port/src/bytes.cj#L142) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func findIter(haystack: Array<UInt8>): BytesMatchIter` | [port/src/bytes.cj:166](../port/src/bytes.cj#L166) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func capturesIter(haystack: Array<UInt8>): BytesCaptureIter` | [port/src/bytes.cj:175](../port/src/bytes.cj#L175) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func splitIter(haystack: Array<UInt8>): BytesSplitIter` | [port/src/bytes.cj:184](../port/src/bytes.cj#L184) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func splitNIter(haystack: Array<UInt8>, limit: Int64): BytesSplitIter` | [port/src/bytes.cj:187](../port/src/bytes.cj#L187) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func capturesRead(locations: CaptureLocations, haystack: Array<UInt8>): Option<BytesMatch>` | [port/src/bytes.cj:222](../port/src/bytes.cj#L222) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func findAll(haystack: Array<UInt8>): Array<BytesMatch>` | [port/src/bytes.cj:225](../port/src/bytes.cj#L225) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func captures(haystack: Array<UInt8>): Option<BytesCaptures>` | [port/src/bytes.cj:350](../port/src/bytes.cj#L350) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func capturesAt(haystack: Array<UInt8>, start: Int64): Option<BytesCaptures>` | [port/src/bytes.cj:353](../port/src/bytes.cj#L353) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func capturesAll(haystack: Array<UInt8>): Array<BytesCaptures>` | [port/src/bytes.cj:359](../port/src/bytes.cj#L359) | 待逐项审计 |
| 字节数据处理 | BytesRegex | `public func capturesReadAt(locations: CaptureLocations, haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | [port/src/bytes.cj:378](../port/src/bytes.cj#L378) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func replace(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | [port/src/bytes.cj:402](../port/src/bytes.cj#L402) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func replaceAll(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | [port/src/bytes.cj:405](../port/src/bytes.cj#L405) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func replaceN(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | [port/src/bytes.cj:408](../port/src/bytes.cj#L408) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func replaceLiteral(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | [port/src/bytes.cj:421](../port/src/bytes.cj#L421) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func replaceWith(haystack: Array<UInt8>, limit: Int64, replacer: (BytesCaptures) -> Array<UInt8>): Array<UInt8>` | [port/src/bytes.cj:424](../port/src/bytes.cj#L424) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func split(haystack: Array<UInt8>): Array<Array<UInt8>>` | [port/src/bytes.cj:427](../port/src/bytes.cj#L427) | 待逐项审计 |
| 替换与分割 | BytesRegex | `public func splitN(haystack: Array<UInt8>, limit: Int64): Array<Array<UInt8>>` | [port/src/bytes.cj:430](../port/src/bytes.cj#L430) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public class BytesCaptures` | [port/src/bytes.cj:589](../port/src/bytes.cj#L589) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public let size: Int64` | [port/src/bytes.cj:593](../port/src/bytes.cj#L593) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public func getMatch(): BytesMatch` | [port/src/bytes.cj:600](../port/src/bytes.cj#L600) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public func get(index: Int64): Option<BytesMatch>` | [port/src/bytes.cj:606](../port/src/bytes.cj#L606) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public func iter(): BytesGroupIter` | [port/src/bytes.cj:612](../port/src/bytes.cj#L612) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public func extract(count: Int64): Array<Array<UInt8>>` | [port/src/bytes.cj:615](../port/src/bytes.cj#L615) | 待逐项审计 |
| 字节数据处理 | BytesCaptures | `public func name(value: String): Option<BytesMatch>` | [port/src/bytes.cj:641](../port/src/bytes.cj#L641) | 待逐项审计 |
| 替换与分割 | BytesCaptures | `public func expand(template: Array<UInt8>): Array<UInt8>` | [port/src/bytes.cj:653](../port/src/bytes.cj#L653) | 待逐项审计 |
| 替换与分割 | BytesCaptures | `public func expandInto(template: Array<UInt8>, out: ArrayList<UInt8>): Unit` | [port/src/bytes.cj:658](../port/src/bytes.cj#L658) | 待逐项审计 |
| 字节数据处理 | BytesGroupItem | `public class BytesGroupItem` | [port/src/bytes.cj:739](../port/src/bytes.cj#L739) | 待逐项审计 |
| 字节数据处理 | BytesGroupItem | `public let done: Bool` | [port/src/bytes.cj:740](../port/src/bytes.cj#L740) | 待逐项审计 |
| 字节数据处理 | BytesGroupItem | `public let value: Option<BytesMatch>` | [port/src/bytes.cj:741](../port/src/bytes.cj#L741) | 待逐项审计 |
| 字节数据处理 | BytesGroupIter | `public class BytesGroupIter` | [port/src/bytes.cj:748](../port/src/bytes.cj#L748) | 待逐项审计 |
| 字节数据处理 | BytesGroupIter | `public func len(): Int64` | [port/src/bytes.cj:755](../port/src/bytes.cj#L755) | 待逐项审计 |
| 字节数据处理 | BytesGroupIter | `public func sizeHint(): (Int64, Option<Int64>)` | [port/src/bytes.cj:758](../port/src/bytes.cj#L758) | 待逐项审计 |
| 字节数据处理 | BytesGroupIter | `public func clone(): BytesGroupIter` | [port/src/bytes.cj:761](../port/src/bytes.cj#L761) | 待逐项审计 |
| 字节数据处理 | BytesGroupIter | `public func next(): BytesGroupItem` | [port/src/bytes.cj:766](../port/src/bytes.cj#L766) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public class BytesRegexSet` | [port/src/bytes.cj:781](../port/src/bytes.cj#L781) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public init(patterns: Array<String>)` | [port/src/bytes.cj:788](../port/src/bytes.cj#L788) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func len(): Int64` | [port/src/bytes.cj:838](../port/src/bytes.cj#L838) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func isEmpty(): Bool` | [port/src/bytes.cj:841](../port/src/bytes.cj#L841) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func patterns(): Array<String>` | [port/src/bytes.cj:844](../port/src/bytes.cj#L844) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func isMatch(haystack: Array<UInt8>): Bool` | [port/src/bytes.cj:847](../port/src/bytes.cj#L847) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | [port/src/bytes.cj:850](../port/src/bytes.cj#L850) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func matches(haystack: Array<UInt8>): SetMatches` | [port/src/bytes.cj:853](../port/src/bytes.cj#L853) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func matchesAt(haystack: Array<UInt8>, start: Int64): SetMatches` | [port/src/bytes.cj:856](../port/src/bytes.cj#L856) | 待逐项审计 |
| 字节数据处理 | BytesRegexSet | `public func matchesReadAt(slots: Array<Bool>, haystack: Array<UInt8>, start: Int64): Bool` | [port/src/bytes.cj:859](../port/src/bytes.cj#L859) | 待逐项审计 |
| 字节数据处理 | BytesMatchIter | `public class BytesMatchIter` | [port/src/bytes.cj:945](../port/src/bytes.cj#L945) | 待逐项审计 |
| 字节数据处理 | BytesMatchIter | `public init(step: (Array<Int64>) -> Option<BytesMatch>, state: Array<Int64>)` | [port/src/bytes.cj:948](../port/src/bytes.cj#L948) | 待逐项审计 |
| 字节数据处理 | BytesMatchIter | `public func next(): Option<BytesMatch>` | [port/src/bytes.cj:952](../port/src/bytes.cj#L952) | 待逐项审计 |
| 字节数据处理 | BytesMatchIter | `public func clone(): BytesMatchIter` | [port/src/bytes.cj:955](../port/src/bytes.cj#L955) | 待逐项审计 |
| 字节数据处理 | BytesCaptureIter | `public class BytesCaptureIter` | [port/src/bytes.cj:960](../port/src/bytes.cj#L960) | 待逐项审计 |
| 字节数据处理 | BytesCaptureIter | `public init(step: (Array<Int64>) -> Option<BytesCaptures>, state: Array<Int64>)` | [port/src/bytes.cj:963](../port/src/bytes.cj#L963) | 待逐项审计 |
| 字节数据处理 | BytesCaptureIter | `public func next(): Option<BytesCaptures>` | [port/src/bytes.cj:967](../port/src/bytes.cj#L967) | 待逐项审计 |
| 字节数据处理 | BytesCaptureIter | `public func clone(): BytesCaptureIter` | [port/src/bytes.cj:970](../port/src/bytes.cj#L970) | 待逐项审计 |
| 替换与分割 | BytesSplitIter | `public class BytesSplitIter` | [port/src/bytes.cj:975](../port/src/bytes.cj#L975) | 待逐项审计 |
| 替换与分割 | BytesSplitIter | `public init(step: (Array<Int64>) -> Option<Array<UInt8>>, state: Array<Int64>)` | [port/src/bytes.cj:978](../port/src/bytes.cj#L978) | 待逐项审计 |
| 替换与分割 | BytesSplitIter | `public func next(): Option<Array<UInt8>>` | [port/src/bytes.cj:982](../port/src/bytes.cj#L982) | 待逐项审计 |
| 替换与分割 | BytesSplitIter | `public func clone(): BytesSplitIter` | [port/src/bytes.cj:985](../port/src/bytes.cj#L985) | 待逐项审计 |
| 提取与遍历捕获 | CaptureSpan | `public class CaptureSpan` | [port/src/captures.cj:7](../port/src/captures.cj#L7) | 待逐项审计 |
| 提取与遍历捕获 | CaptureSpan | `public let start: Int64` | [port/src/captures.cj:8](../port/src/captures.cj#L8) | 待逐项审计 |
| 提取与遍历捕获 | CaptureSpan | `public let end: Int64` | [port/src/captures.cj:9](../port/src/captures.cj#L9) | 待逐项审计 |
| 提取与遍历捕获 | CaptureLocations | `public class CaptureLocations` | [port/src/captures.cj:16](../port/src/captures.cj#L16) | 待逐项审计 |
| 提取与遍历捕获 | CaptureLocations | `public let size: Int64` | [port/src/captures.cj:17](../port/src/captures.cj#L17) | 待逐项审计 |
| 提取与遍历捕获 | CaptureLocations | `public func get(index: Int64): Option<CaptureSpan>` | [port/src/captures.cj:25](../port/src/captures.cj#L25) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public class Captures` | [port/src/captures.cj:41](../port/src/captures.cj#L41) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public let size: Int64` | [port/src/captures.cj:45](../port/src/captures.cj#L45) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public func getMatch(): RegexMatch` | [port/src/captures.cj:52](../port/src/captures.cj#L52) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public func extract(count: Int64): Array<String>` | [port/src/captures.cj:60](../port/src/captures.cj#L60) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public func iter(): GroupIter` | [port/src/captures.cj:86](../port/src/captures.cj#L86) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public func groupName(index: Int64): String` | [port/src/captures.cj:89](../port/src/captures.cj#L89) | 待逐项审计 |
| 提取与遍历捕获 | Captures | `public func get(index: Int64): Option<RegexMatch>` | [port/src/captures.cj:95](../port/src/captures.cj#L95) | 部分特性案例：`capture-absent-empty`, `capture-unicode`, `capture-no-match`, `capture-repeat` |
| 提取与遍历捕获 | Captures | `public func name(value: String): Option<RegexMatch>` | [port/src/captures.cj:101](../port/src/captures.cj#L101) | 部分特性案例：`capture-name-present`, `capture-name-absent`, `capture-name-empty`, `capture-name-unknown` |
| 替换与分割 | Captures | `public func expand(template: String): String` | [port/src/captures.cj:113](../port/src/captures.cj#L113) | 待逐项审计 |
| 替换与分割 | Captures | `public func expandInto(template: String, out: StringBuilder): Unit` | [port/src/captures.cj:118](../port/src/captures.cj#L118) | 待逐项审计 |
| 提取与遍历捕获 | GroupItem | `public class GroupItem` | [port/src/captures.cj:204](../port/src/captures.cj#L204) | 待逐项审计 |
| 提取与遍历捕获 | GroupItem | `public let done: Bool` | [port/src/captures.cj:205](../port/src/captures.cj#L205) | 待逐项审计 |
| 提取与遍历捕获 | GroupItem | `public let value: Option<RegexMatch>` | [port/src/captures.cj:206](../port/src/captures.cj#L206) | 待逐项审计 |
| 提取与遍历捕获 | GroupIter | `public class GroupIter` | [port/src/captures.cj:213](../port/src/captures.cj#L213) | 待逐项审计 |
| 提取与遍历捕获 | GroupIter | `public func len(): Int64` | [port/src/captures.cj:220](../port/src/captures.cj#L220) | 待逐项审计 |
| 提取与遍历捕获 | GroupIter | `public func sizeHint(): (Int64, Option<Int64>)` | [port/src/captures.cj:223](../port/src/captures.cj#L223) | 待逐项审计 |
| 提取与遍历捕获 | GroupIter | `public func clone(): GroupIter` | [port/src/captures.cj:226](../port/src/captures.cj#L226) | 待逐项审计 |
| 提取与遍历捕获 | GroupIter | `public func next(): GroupItem` | [port/src/captures.cj:231](../port/src/captures.cj#L231) | 待逐项审计 |
| DFA 搜索 | DfaHalf | `public class DfaHalf` | [port/src/dfa.cj:1046](../port/src/dfa.cj#L1046) | 待逐项审计 |
| DFA 搜索 | DfaHalf | `public let pattern: Int64` | [port/src/dfa.cj:1047](../port/src/dfa.cj#L1047) | 待逐项审计 |
| DFA 搜索 | DfaHalf | `public let end: Int64` | [port/src/dfa.cj:1048](../port/src/dfa.cj#L1048) | 待逐项审计 |
| DFA 搜索 | DfaHalf | `public init(pattern: Int64, end: Int64)` | [port/src/dfa.cj:1049](../port/src/dfa.cj#L1049) | 待逐项审计 |
| DFA 搜索 | DfaMatch | `public class DfaMatch` | [port/src/dfa.cj:1055](../port/src/dfa.cj#L1055) | 待逐项审计 |
| DFA 搜索 | DfaMatch | `public let pattern: Int64` | [port/src/dfa.cj:1056](../port/src/dfa.cj#L1056) | 待逐项审计 |
| DFA 搜索 | DfaMatch | `public let start: Int64` | [port/src/dfa.cj:1057](../port/src/dfa.cj#L1057) | 待逐项审计 |
| DFA 搜索 | DfaMatch | `public let end: Int64` | [port/src/dfa.cj:1058](../port/src/dfa.cj#L1058) | 待逐项审计 |
| DFA 搜索 | DfaMatch | `public let text: String` | [port/src/dfa.cj:1059](../port/src/dfa.cj#L1059) | 待逐项审计 |
| DFA 搜索 | DfaMatch | `public init(pattern: Int64, start: Int64, end: Int64, text: String)` | [port/src/dfa.cj:1060](../port/src/dfa.cj#L1060) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public class DenseDfa` | [port/src/dfa.cj:1068](../port/src/dfa.cj#L1068) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(pattern: String)` | [port/src/dfa.cj:1070](../port/src/dfa.cj#L1070) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(pattern: String, quit: Array<UInt8>)` | [port/src/dfa.cj:1073](../port/src/dfa.cj#L1073) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(patterns: Array<String>)` | [port/src/dfa.cj:1076](../port/src/dfa.cj#L1076) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(patterns: Array<String>, quit: Array<UInt8>)` | [port/src/dfa.cj:1079](../port/src/dfa.cj#L1079) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool)` | [port/src/dfa.cj:1082](../port/src/dfa.cj#L1082) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool, patternStarts: Bool)` | [port/src/dfa.cj:1085](../port/src/dfa.cj#L1085) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public init(patterns: Array<String>, byteLimit: Int64)` | [port/src/dfa.cj:1088](../port/src/dfa.cj#L1088) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public static func overlap(patterns: Array<String>): DenseDfa` | [port/src/dfa.cj:1091](../port/src/dfa.cj#L1091) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func stateCount(): Int64` | [port/src/dfa.cj:1094](../port/src/dfa.cj#L1094) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func memoryUsage(): Int64` | [port/src/dfa.cj:1097](../port/src/dfa.cj#L1097) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func retainsDenseTable(): Bool` | [port/src/dfa.cj:1100](../port/src/dfa.cj#L1100) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func search(text: String): Option<DfaMatch>` | [port/src/dfa.cj:1103](../port/src/dfa.cj#L1103) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func search(input: SearchInput): Option<DfaMatch>` | [port/src/dfa.cj:1106](../port/src/dfa.cj#L1106) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func searchOverlapping(text: String): Array<DfaHalf>` | [port/src/dfa.cj:1109](../port/src/dfa.cj#L1109) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func searchOverlapping(input: SearchInput): Array<DfaHalf>` | [port/src/dfa.cj:1112](../port/src/dfa.cj#L1112) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public func toImage(): Array<UInt8>` | [port/src/dfa.cj:1118](../port/src/dfa.cj#L1118) | 待逐项审计 |
| DFA 搜索 | DenseDfa | `public static func fromImage(bytes: Array<UInt8>): DenseDfa` | [port/src/dfa.cj:1144](../port/src/dfa.cj#L1144) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public class SparseDfa` | [port/src/dfa.cj:1195](../port/src/dfa.cj#L1195) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public init(pattern: String)` | [port/src/dfa.cj:1197](../port/src/dfa.cj#L1197) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public init(pattern: String, quit: Array<UInt8>)` | [port/src/dfa.cj:1200](../port/src/dfa.cj#L1200) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public init(patterns: Array<String>)` | [port/src/dfa.cj:1203](../port/src/dfa.cj#L1203) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public init(patterns: Array<String>, quit: Array<UInt8>)` | [port/src/dfa.cj:1206](../port/src/dfa.cj#L1206) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool)` | [port/src/dfa.cj:1209](../port/src/dfa.cj#L1209) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public init(patterns: Array<String>, quit: Array<UInt8>, matchAll: Bool, patternStarts: Bool)` | [port/src/dfa.cj:1212](../port/src/dfa.cj#L1212) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public static func overlap(patterns: Array<String>): SparseDfa` | [port/src/dfa.cj:1215](../port/src/dfa.cj#L1215) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func stateCount(): Int64` | [port/src/dfa.cj:1218](../port/src/dfa.cj#L1218) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func memoryUsage(): Int64` | [port/src/dfa.cj:1221](../port/src/dfa.cj#L1221) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func retainsDenseTable(): Bool` | [port/src/dfa.cj:1224](../port/src/dfa.cj#L1224) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func search(text: String): Option<DfaMatch>` | [port/src/dfa.cj:1227](../port/src/dfa.cj#L1227) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func search(input: SearchInput): Option<DfaMatch>` | [port/src/dfa.cj:1230](../port/src/dfa.cj#L1230) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func searchOverlapping(text: String): Array<DfaHalf>` | [port/src/dfa.cj:1233](../port/src/dfa.cj#L1233) | 待逐项审计 |
| DFA 搜索 | SparseDfa | `public func searchOverlapping(input: SearchInput): Array<DfaHalf>` | [port/src/dfa.cj:1236](../port/src/dfa.cj#L1236) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public class HybridDfa` | [port/src/dfa.cj:1241](../port/src/dfa.cj#L1241) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public init(pattern: String)` | [port/src/dfa.cj:1243](../port/src/dfa.cj#L1243) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public init(pattern: String, quit: Array<UInt8>)` | [port/src/dfa.cj:1246](../port/src/dfa.cj#L1246) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64)` | [port/src/dfa.cj:1249](../port/src/dfa.cj#L1249) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool)` | [port/src/dfa.cj:1252](../port/src/dfa.cj#L1252) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public init(patterns: Array<String>, cacheLimit: Int64, clearLimit: Int64, patternStarts: Bool, matchAll: Bool)` | [port/src/dfa.cj:1255](../port/src/dfa.cj#L1255) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public static func overlap(patterns: Array<String>): HybridDfa` | [port/src/dfa.cj:1258](../port/src/dfa.cj#L1258) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public func stateCount(): Int64` | [port/src/dfa.cj:1261](../port/src/dfa.cj#L1261) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public func memoryUsage(): Int64` | [port/src/dfa.cj:1264](../port/src/dfa.cj#L1264) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public func reset(): Unit` | [port/src/dfa.cj:1267](../port/src/dfa.cj#L1267) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public func search(text: String): Option<DfaMatch>` | [port/src/dfa.cj:1270](../port/src/dfa.cj#L1270) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public func searchOverlapping(text: String): Array<DfaHalf>` | [port/src/dfa.cj:1273](../port/src/dfa.cj#L1273) | 待逐项审计 |
| DFA 搜索 | HybridDfa | `public func search(input: SearchInput): Option<DfaMatch>` | [port/src/dfa.cj:1276](../port/src/dfa.cj#L1276) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorKind | `public enum RegexErrorKind` | [port/src/error.cj:7](../port/src/error.cj#L7) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public class RegexErrorSpan` | [port/src/error.cj:13](../port/src/error.cj#L13) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public let startOffset: Int64` | [port/src/error.cj:14](../port/src/error.cj#L14) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public let startLine: Int64` | [port/src/error.cj:15](../port/src/error.cj#L15) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public let startColumn: Int64` | [port/src/error.cj:16](../port/src/error.cj#L16) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public let endOffset: Int64` | [port/src/error.cj:17](../port/src/error.cj#L17) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public let endLine: Int64` | [port/src/error.cj:18](../port/src/error.cj#L18) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public let endColumn: Int64` | [port/src/error.cj:19](../port/src/error.cj#L19) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public init(startOffset: Int64, startLine: Int64, startColumn: Int64, endOffset: Int64, endLine: Int64, endColumn: Int64)` | [port/src/error.cj:20](../port/src/error.cj#L20) | 待逐项审计 |
| 规则创建与语法选项 | RegexErrorSpan | `public func text(): String` | [port/src/error.cj:29](../port/src/error.cj#L29) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public class RegexError <: Exception` | [port/src/error.cj:34](../port/src/error.cj#L34) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let errorKind: RegexErrorKind` | [port/src/error.cj:35](../port/src/error.cj#L35) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let limit: Int64` | [port/src/error.cj:36](../port/src/error.cj#L36) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let text: String` | [port/src/error.cj:37](../port/src/error.cj#L37) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let phase: String` | [port/src/error.cj:39](../port/src/error.cj#L39) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let name: String` | [port/src/error.cj:41](../port/src/error.cj#L41) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let primary: Option<RegexErrorSpan>` | [port/src/error.cj:42](../port/src/error.cj#L42) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public let auxiliary: Option<RegexErrorSpan>` | [port/src/error.cj:43](../port/src/error.cj#L43) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public init(errorKind: RegexErrorKind, message: String, limit: Int64)` | [port/src/error.cj:44](../port/src/error.cj#L44) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public init(errorKind: RegexErrorKind, message: String, limit: Int64, phase: String, name: String, primary: Option<RegexErrorSpan>, auxiliary: Option<RegexErrorSpan>)` | [port/src/error.cj:47](../port/src/error.cj#L47) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public override func toString(): String` | [port/src/error.cj:58](../port/src/error.cj#L58) | 待逐项审计 |
| 规则创建与语法选项 | RegexError | `public func structure(): String` | [port/src/error.cj:61](../port/src/error.cj#L61) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func escape(text: String): String` | [port/src/escape.cj:13](../port/src/escape.cj#L13) | 待逐项审计 |
| 组合引擎和扩展入口 | LiteRegex | `public class LiteRegex` | [port/src/lite.cj:8](../port/src/lite.cj#L8) | 待逐项审计 |
| 组合引擎和扩展入口 | LiteRegex | `public init(pattern: String)` | [port/src/lite.cj:11](../port/src/lite.cj#L11) | 待逐项审计 |
| 组合引擎和扩展入口 | LiteRegex | `public func search(text: String): Option<PikeMatch>` | [port/src/lite.cj:16](../port/src/lite.cj#L16) | 待逐项审计 |
| 组合引擎和扩展入口 | LiteRegex | `public func isMatch(text: String): Bool` | [port/src/lite.cj:19](../port/src/lite.cj#L19) | 待逐项审计 |
| 组合引擎和扩展入口 | LiteRegex | `public func searchAll(text: String): Array<PikeMatch>` | [port/src/lite.cj:22](../port/src/lite.cj#L22) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public class MetaRegex` | [port/src/meta.cj:47](../port/src/meta.cj#L47) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public let engineName: String` | [port/src/meta.cj:52](../port/src/meta.cj#L52) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public init(pattern: String)` | [port/src/meta.cj:53](../port/src/meta.cj#L53) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public init(patterns: Array<String>)` | [port/src/meta.cj:56](../port/src/meta.cj#L56) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public func memoryUsage(): Int64` | [port/src/meta.cj:72](../port/src/meta.cj#L72) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public func search(text: String): Option<PikeMatch>` | [port/src/meta.cj:80](../port/src/meta.cj#L80) | 待逐项审计 |
| 组合引擎和扩展入口 | MetaRegex | `public func searchAll(text: String): Array<PikeMatch>` | [port/src/meta.cj:83](../port/src/meta.cj#L83) | 待逐项审计 |
| 查找文本 | RegexMatch | `public class RegexMatch` | [port/src/nfa.cj:249](../port/src/nfa.cj#L249) | 待逐项审计 |
| 查找文本 | RegexMatch | `public let start: Int64` | [port/src/nfa.cj:250](../port/src/nfa.cj#L250) | 待逐项审计 |
| 查找文本 | RegexMatch | `public let end: Int64` | [port/src/nfa.cj:251](../port/src/nfa.cj#L251) | 待逐项审计 |
| 查找文本 | RegexMatch | `public let text: String` | [port/src/nfa.cj:252](../port/src/nfa.cj#L252) | 待逐项审计 |
| 查找文本 | RegexMatch | `public func isEmpty(): Bool` | [port/src/nfa.cj:258](../port/src/nfa.cj#L258) | 待逐项审计 |
| 查找文本 | RegexMatch | `public func len(): Int64` | [port/src/nfa.cj:261](../port/src/nfa.cj#L261) | 待逐项审计 |
| 查找文本 | RegexMatch | `public func asStr(): String` | [port/src/nfa.cj:264](../port/src/nfa.cj#L264) | 待逐项审计 |
| 查找文本 | Regex | `public class Regex` | [port/src/nfa.cj:519](../port/src/nfa.cj#L519) | 待逐项审计 |
| 查找文本 | Regex | `public init(pattern: String)` | [port/src/nfa.cj:528](../port/src/nfa.cj#L528) | 待逐项审计 |
| 查找文本 | Regex | `public func asStr(): String` | [port/src/nfa.cj:663](../port/src/nfa.cj#L663) | 待逐项审计 |
| 提取与遍历捕获 | Regex | `public func staticCapturesLen(): Option<Int64>` | [port/src/nfa.cj:666](../port/src/nfa.cj#L666) | 待逐项审计 |
| 查找文本 | Regex | `public func searchEarliest(text: String): Option<Captures>` | [port/src/nfa.cj:806](../port/src/nfa.cj#L806) | 待逐项审计 |
| 查找文本 | Regex | `public func find(text: String): Option<RegexMatch>` | [port/src/nfa.cj:813](../port/src/nfa.cj#L813) | 部分特性案例：`find-normal`, `find-first`, `find-absent`, `find-start`, `find-end`, `find-priority`, `find-greedy`, `find-lazy`, `config-case-sensitive`, `config-ignore-case`, `config-case-scope`, `config-dot-default`, `config-dot-all`, `config-multiline`, `config-anchor-default` |
| 查找文本 | Regex | `public func isMatch(text: String): Bool` | [port/src/nfa.cj:825](../port/src/nfa.cj#L825) | 待逐项审计 |
| 查找文本 | Regex | `public func findAt(text: String, start: Int64): Option<RegexMatch>` | [port/src/nfa.cj:836](../port/src/nfa.cj#L836) | 待逐项审计 |
| 查找文本 | Regex | `public func isMatchAt(text: String, start: Int64): Bool` | [port/src/nfa.cj:844](../port/src/nfa.cj#L844) | 待逐项审计 |
| 查找文本 | Regex | `public func shortestMatch(text: String): Option<Int64>` | [port/src/nfa.cj:850](../port/src/nfa.cj#L850) | 待逐项审计 |
| 查找文本 | Regex | `public func shortestMatchAt(text: String, start: Int64): Option<Int64>` | [port/src/nfa.cj:853](../port/src/nfa.cj#L853) | 待逐项审计 |
| 提取与遍历捕获 | Regex | `public func capturesAt(text: String, start: Int64): Option<Captures>` | [port/src/nfa.cj:861](../port/src/nfa.cj#L861) | 待逐项审计 |
| 查找文本 | Regex | `public func findIter(text: String): MatchIter` | [port/src/nfa.cj:886](../port/src/nfa.cj#L886) | 待逐项审计 |
| 提取与遍历捕获 | Regex | `public func capturesIter(text: String): CaptureIter` | [port/src/nfa.cj:895](../port/src/nfa.cj#L895) | 待逐项审计 |
| 替换与分割 | Regex | `public func splitIter(text: String): SplitIter` | [port/src/nfa.cj:904](../port/src/nfa.cj#L904) | 待逐项审计 |
| 替换与分割 | Regex | `public func splitNIter(text: String, limit: Int64): SplitIter` | [port/src/nfa.cj:907](../port/src/nfa.cj#L907) | 待逐项审计 |
| 提取与遍历捕获 | Regex | `public func captureLocations(): CaptureLocations` | [port/src/nfa.cj:960](../port/src/nfa.cj#L960) | 待逐项审计 |
| 提取与遍历捕获 | Regex | `public func capturesRead(locations: CaptureLocations, text: String): Option<RegexMatch>` | [port/src/nfa.cj:963](../port/src/nfa.cj#L963) | 待逐项审计 |
| 提取与遍历捕获 | Regex | `public func capturesReadAt(locations: CaptureLocations, text: String, start: Int64): Option<RegexMatch>` | [port/src/nfa.cj:966](../port/src/nfa.cj#L966) | 待逐项审计 |
| 查找文本 | Regex | `public func findAll(text: String): Array<RegexMatch>` | [port/src/nfa.cj:992](../port/src/nfa.cj#L992) | 部分特性案例：`find-empty-input`, `find-utf8`, `find-empty-progress` |
| 提取与遍历捕获 | Regex | `public func capturesLen(): Int64` | [port/src/nfa.cj:1016](../port/src/nfa.cj#L1016) | 部分特性案例：`capture-absent-empty`, `capture-unicode`, `capture-no-match`, `capture-repeat` |
| 提取与遍历捕获 | Regex | `public func captureNames(): Array<Option<String>>` | [port/src/nfa.cj:1019](../port/src/nfa.cj#L1019) | 部分特性案例：`capture-absent-empty`, `capture-unicode`, `capture-no-match`, `capture-repeat` |
| 提取与遍历捕获 | Regex | `public func captures(text: String): Option<Captures>` | [port/src/nfa.cj:1044](../port/src/nfa.cj#L1044) | 部分特性案例：`capture-name-present`, `capture-name-absent`, `capture-name-empty`, `capture-name-unknown`, `capture-repeat` |
| 提取与遍历捕获 | Regex | `public func capturesAll(text: String): Array<Captures>` | [port/src/nfa.cj:1051](../port/src/nfa.cj#L1051) | 部分特性案例：`capture-absent-empty`, `capture-unicode`, `capture-no-match` |
| 替换与分割 | Regex | `public func replace(text: String, replacement: String): String` | [port/src/nfa.cj:1071](../port/src/nfa.cj#L1071) | 待逐项审计 |
| 替换与分割 | Regex | `public func replaceAll(text: String, replacement: String): String` | [port/src/nfa.cj:1074](../port/src/nfa.cj#L1074) | 部分特性案例：`replace-named`, `replace-zero-width` |
| 替换与分割 | Regex | `public func replaceN(text: String, limit: Int64, replacement: String): String` | [port/src/nfa.cj:1078](../port/src/nfa.cj#L1078) | 待逐项审计 |
| 替换与分割 | Regex | `public func replaceLiteral(text: String, limit: Int64, replacement: String): String` | [port/src/nfa.cj:1091](../port/src/nfa.cj#L1091) | 待逐项审计 |
| 替换与分割 | Regex | `public func replaceWith(text: String, limit: Int64, replacer: (Captures) -> String): String` | [port/src/nfa.cj:1094](../port/src/nfa.cj#L1094) | 待逐项审计 |
| 替换与分割 | Regex | `public func split(text: String): Array<String>` | [port/src/nfa.cj:1128](../port/src/nfa.cj#L1128) | 部分特性案例：`split-empty-fields` |
| 替换与分割 | Regex | `public func splitN(text: String, limit: Int64): Array<String>` | [port/src/nfa.cj:1132](../port/src/nfa.cj#L1132) | 部分特性案例：`split-limit`, `split-zero` |
| 查找文本 | Regex | `public func nfaStateCount(): Int64` | [port/src/nfa.cj:1168](../port/src/nfa.cj#L1168) | 待逐项审计 |
| 查找文本 | Regex | `public func nfaStart(): Int64` | [port/src/nfa.cj:1171](../port/src/nfa.cj#L1171) | 待逐项审计 |
| 查找文本 | Regex | `public func nfaOp(index: Int64): String` | [port/src/nfa.cj:1174](../port/src/nfa.cj#L1174) | 待逐项审计 |
| 查找文本 | Regex | `public func nfaNext(index: Int64): Int64` | [port/src/nfa.cj:1188](../port/src/nfa.cj#L1188) | 待逐项审计 |
| 查找文本 | Regex | `public func nfaAlternate(index: Int64): Int64` | [port/src/nfa.cj:1194](../port/src/nfa.cj#L1194) | 待逐项审计 |
| 查找文本 | Regex | `public func searchWindow(text: String, start: Int64, end: Int64, anchored: Bool): Option<Captures>` | [port/src/nfa.cj:1200](../port/src/nfa.cj#L1200) | 待逐项审计 |
| 查找文本 | MatchIter | `public class MatchIter` | [port/src/nfa.cj:1224](../port/src/nfa.cj#L1224) | 待逐项审计 |
| 查找文本 | MatchIter | `public init(step: (Array<Int64>) -> Option<RegexMatch>, state: Array<Int64>)` | [port/src/nfa.cj:1227](../port/src/nfa.cj#L1227) | 待逐项审计 |
| 查找文本 | MatchIter | `public func next(): Option<RegexMatch>` | [port/src/nfa.cj:1231](../port/src/nfa.cj#L1231) | 待逐项审计 |
| 查找文本 | MatchIter | `public func clone(): MatchIter` | [port/src/nfa.cj:1234](../port/src/nfa.cj#L1234) | 待逐项审计 |
| 提取与遍历捕获 | CaptureIter | `public class CaptureIter` | [port/src/nfa.cj:1239](../port/src/nfa.cj#L1239) | 待逐项审计 |
| 查找文本 | CaptureIter | `public init(step: (Array<Int64>) -> Option<Captures>, state: Array<Int64>)` | [port/src/nfa.cj:1242](../port/src/nfa.cj#L1242) | 待逐项审计 |
| 查找文本 | CaptureIter | `public func next(): Option<Captures>` | [port/src/nfa.cj:1246](../port/src/nfa.cj#L1246) | 待逐项审计 |
| 查找文本 | CaptureIter | `public func clone(): CaptureIter` | [port/src/nfa.cj:1249](../port/src/nfa.cj#L1249) | 待逐项审计 |
| 替换与分割 | SplitIter | `public class SplitIter` | [port/src/nfa.cj:1254](../port/src/nfa.cj#L1254) | 待逐项审计 |
| 替换与分割 | SplitIter | `public init(step: (Array<Int64>) -> Option<String>, state: Array<Int64>)` | [port/src/nfa.cj:1257](../port/src/nfa.cj#L1257) | 待逐项审计 |
| 替换与分割 | SplitIter | `public func next(): Option<String>` | [port/src/nfa.cj:1261](../port/src/nfa.cj#L1261) | 待逐项审计 |
| 替换与分割 | SplitIter | `public func clone(): SplitIter` | [port/src/nfa.cj:1264](../port/src/nfa.cj#L1264) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public class OnePass` | [port/src/onepass.cj:8](../port/src/onepass.cj#L8) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public let engineName: String = "onepass"` | [port/src/onepass.cj:10](../port/src/onepass.cj#L10) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public init(pattern: String)` | [port/src/onepass.cj:11](../port/src/onepass.cj#L11) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public init(patterns: Array<String>)` | [port/src/onepass.cj:14](../port/src/onepass.cj#L14) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public func search(text: String): Option<PikeMatch>` | [port/src/onepass.cj:24](../port/src/onepass.cj#L24) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public func searchAnchored(text: String, at: Int64): Option<PikeMatch>` | [port/src/onepass.cj:27](../port/src/onepass.cj#L27) | 待逐项审计 |
| 组合引擎和扩展入口 | OnePass | `public func searchAll(text: String): Array<PikeMatch>` | [port/src/onepass.cj:30](../port/src/onepass.cj#L30) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public class PikeCache` | [port/src/pikevm.cj:8](../port/src/pikevm.cj#L8) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func reset(): Unit` | [port/src/pikevm.cj:20](../port/src/pikevm.cj#L20) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func captureWorkspace(): Int64` | [port/src/pikevm.cj:31](../port/src/pikevm.cj#L31) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func activeThreads(): Int64` | [port/src/pikevm.cj:73](../port/src/pikevm.cj#L73) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func hasMatch(): Bool` | [port/src/pikevm.cj:109](../port/src/pikevm.cj#L109) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func patternId(): Int64` | [port/src/pikevm.cj:112](../port/src/pikevm.cj#L112) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func groupStart(index: Int64): Int64` | [port/src/pikevm.cj:115](../port/src/pikevm.cj#L115) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeCache | `public func groupEnd(index: Int64): Int64` | [port/src/pikevm.cj:122](../port/src/pikevm.cj#L122) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeMatch | `public class PikeMatch` | [port/src/pikevm.cj:153](../port/src/pikevm.cj#L153) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeMatch | `public let pattern: Int64` | [port/src/pikevm.cj:154](../port/src/pikevm.cj#L154) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeMatch | `public let captures: Captures` | [port/src/pikevm.cj:155](../port/src/pikevm.cj#L155) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeMatch | `public init(pattern: Int64, captures: Captures)` | [port/src/pikevm.cj:156](../port/src/pikevm.cj#L156) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeMatch | `public func start(): Int64` | [port/src/pikevm.cj:160](../port/src/pikevm.cj#L160) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeMatch | `public func end(): Int64` | [port/src/pikevm.cj:166](../port/src/pikevm.cj#L166) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public class PikeVM` | [port/src/pikevm.cj:174](../port/src/pikevm.cj#L174) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public let cache: PikeCache` | [port/src/pikevm.cj:176](../port/src/pikevm.cj#L176) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public init(pattern: String)` | [port/src/pikevm.cj:177](../port/src/pikevm.cj#L177) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public init(patterns: Array<String>)` | [port/src/pikevm.cj:180](../port/src/pikevm.cj#L180) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public init(patterns: Array<String>, whichCaptures: Int64)` | [port/src/pikevm.cj:183](../port/src/pikevm.cj#L183) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public init(hir: Hir)` | [port/src/pikevm.cj:187](../port/src/pikevm.cj#L187) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public init(hirs: Array<Hir>)` | [port/src/pikevm.cj:190](../port/src/pikevm.cj#L190) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func patternCount(): Int64` | [port/src/pikevm.cj:194](../port/src/pikevm.cj#L194) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func memoryUsage(): Int64` | [port/src/pikevm.cj:197](../port/src/pikevm.cj#L197) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func reset(): Unit` | [port/src/pikevm.cj:200](../port/src/pikevm.cj#L200) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func graph(): ThompsonNfa` | [port/src/pikevm.cj:203](../port/src/pikevm.cj#L203) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func stateCount(pattern: Int64): Int64` | [port/src/pikevm.cj:206](../port/src/pikevm.cj#L206) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func startState(pattern: Int64): Int64` | [port/src/pikevm.cj:209](../port/src/pikevm.cj#L209) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func opName(pattern: Int64, state: Int64): String` | [port/src/pikevm.cj:212](../port/src/pikevm.cj#L212) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func opNext(pattern: Int64, state: Int64): Int64` | [port/src/pikevm.cj:215](../port/src/pikevm.cj#L215) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func opAlternate(pattern: Int64, state: Int64): Int64` | [port/src/pikevm.cj:218](../port/src/pikevm.cj#L218) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func whichOverlapping(text: String): Array<Int64>` | [port/src/pikevm.cj:221](../port/src/pikevm.cj#L221) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func whichOverlapping(input: SearchInput): Array<Int64>` | [port/src/pikevm.cj:224](../port/src/pikevm.cj#L224) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func searchEarliest(text: String): Option<PikeMatch>` | [port/src/pikevm.cj:227](../port/src/pikevm.cj#L227) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func search(text: String): Option<PikeMatch>` | [port/src/pikevm.cj:230](../port/src/pikevm.cj#L230) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func search(text: String, start: Int64, end: Int64, anchored: Bool): Option<PikeMatch>` | [port/src/pikevm.cj:233](../port/src/pikevm.cj#L233) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func search(input: SearchInput): Option<PikeMatch>` | [port/src/pikevm.cj:236](../port/src/pikevm.cj#L236) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func isMatch(input: SearchInput): Bool` | [port/src/pikevm.cj:239](../port/src/pikevm.cj#L239) | 待逐项审计 |
| NFA 构建与 PikeVM | PikeVM | `public func searchAll(text: String): Array<PikeMatch>` | [port/src/pikevm.cj:244](../port/src/pikevm.cj#L244) | 待逐项审计 |
| 多规则匹配 | SetMatches | `public class SetMatches` | [port/src/regex_set.cj:7](../port/src/regex_set.cj#L7) | 待逐项审计 |
| 多规则匹配 | SetMatches | `public func len(): Int64` | [port/src/regex_set.cj:12](../port/src/regex_set.cj#L12) | 部分特性案例：`set-empty`, `set-no-hit`, `set-some`, `set-all`, `set-duplicates`, `set-overlap`, `set-order`, `set-empty-pattern`, `set-unicode` |
| 多规则匹配 | SetMatches | `public func matched(index: Int64): Bool` | [port/src/regex_set.cj:15](../port/src/regex_set.cj#L15) | 待逐项审计 |
| 多规则匹配 | SetMatches | `public func matchedAny(): Bool` | [port/src/regex_set.cj:21](../port/src/regex_set.cj#L21) | 部分特性案例：`set-empty`, `set-no-hit`, `set-some`, `set-all`, `set-duplicates`, `set-overlap`, `set-order`, `set-empty-pattern`, `set-unicode` |
| 多规则匹配 | SetMatches | `public func matchedAll(): Bool` | [port/src/regex_set.cj:29](../port/src/regex_set.cj#L29) | 部分特性案例：`set-empty`, `set-no-hit`, `set-some`, `set-all`, `set-duplicates`, `set-overlap`, `set-order`, `set-empty-pattern`, `set-unicode` |
| 多规则匹配 | SetMatches | `public func indices(): Array<Int64>` | [port/src/regex_set.cj:37](../port/src/regex_set.cj#L37) | 部分特性案例：`set-empty`, `set-no-hit`, `set-some`, `set-all`, `set-duplicates`, `set-overlap`, `set-order`, `set-empty-pattern`, `set-unicode` |
| 多规则匹配 | SetMatches | `public func iter(): SetMatchesIter` | [port/src/regex_set.cj:47](../port/src/regex_set.cj#L47) | 待逐项审计 |
| 多规则匹配 | SetMatchesIter | `public class SetMatchesIter` | [port/src/regex_set.cj:54](../port/src/regex_set.cj#L54) | 待逐项审计 |
| 多规则匹配 | SetMatchesIter | `public func next(): Option<Int64>` | [port/src/regex_set.cj:65](../port/src/regex_set.cj#L65) | 待逐项审计 |
| 多规则匹配 | SetMatchesIter | `public func nextBack(): Option<Int64>` | [port/src/regex_set.cj:76](../port/src/regex_set.cj#L76) | 待逐项审计 |
| 多规则匹配 | SetMatchesIter | `public func sizeHint(): (Int64, Option<Int64>)` | [port/src/regex_set.cj:88](../port/src/regex_set.cj#L88) | 待逐项审计 |
| 多规则匹配 | SetMatchesIter | `public func clone(): SetMatchesIter` | [port/src/regex_set.cj:93](../port/src/regex_set.cj#L93) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public class RegexSet` | [port/src/regex_set.cj:101](../port/src/regex_set.cj#L101) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public init(patterns: Array<String>)` | [port/src/regex_set.cj:108](../port/src/regex_set.cj#L108) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func len(): Int64` | [port/src/regex_set.cj:157](../port/src/regex_set.cj#L157) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func isEmpty(): Bool` | [port/src/regex_set.cj:160](../port/src/regex_set.cj#L160) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func patterns(): Array<String>` | [port/src/regex_set.cj:163](../port/src/regex_set.cj#L163) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func isMatch(text: String): Bool` | [port/src/regex_set.cj:166](../port/src/regex_set.cj#L166) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func isMatchAt(text: String, start: Int64): Bool` | [port/src/regex_set.cj:169](../port/src/regex_set.cj#L169) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func matches(text: String): SetMatches` | [port/src/regex_set.cj:172](../port/src/regex_set.cj#L172) | 部分特性案例：`set-empty`, `set-no-hit`, `set-some`, `set-all`, `set-duplicates`, `set-overlap`, `set-order`, `set-empty-pattern`, `set-unicode` |
| 多规则匹配 | RegexSet | `public func matchesAt(text: String, start: Int64): SetMatches` | [port/src/regex_set.cj:175](../port/src/regex_set.cj#L175) | 待逐项审计 |
| 多规则匹配 | RegexSet | `public func matchesReadAt(slots: Array<Bool>, text: String, start: Int64): Bool` | [port/src/regex_set.cj:180](../port/src/regex_set.cj#L180) | 待逐项审计 |
| 反向搜索 | ReverseMatch | `public class ReverseMatch` | [port/src/reverse.cj:8](../port/src/reverse.cj#L8) | 待逐项审计 |
| 反向搜索 | ReverseMatch | `public let pattern: Int64` | [port/src/reverse.cj:9](../port/src/reverse.cj#L9) | 待逐项审计 |
| 反向搜索 | ReverseMatch | `public let offset: Int64` | [port/src/reverse.cj:10](../port/src/reverse.cj#L10) | 待逐项审计 |
| 反向搜索 | ReverseMatch | `public init(pattern: Int64, offset: Int64)` | [port/src/reverse.cj:11](../port/src/reverse.cj#L11) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public class ReverseNfa` | [port/src/reverse.cj:17](../port/src/reverse.cj#L17) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public init(pattern: String)` | [port/src/reverse.cj:26](../port/src/reverse.cj#L26) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public init(patterns: Array<String>)` | [port/src/reverse.cj:29](../port/src/reverse.cj#L29) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public init(patterns: Array<String>, patternStarts: Bool)` | [port/src/reverse.cj:32](../port/src/reverse.cj#L32) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public init(patterns: Array<String>, patternStarts: Bool, sizeLimit: Int64)` | [port/src/reverse.cj:35](../port/src/reverse.cj#L35) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public func search(text: String): Option<Int64>` | [port/src/reverse.cj:108](../port/src/reverse.cj#L108) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public func search(input: SearchInput): Option<Int64>` | [port/src/reverse.cj:114](../port/src/reverse.cj#L114) | 待逐项审计 |
| 反向搜索 | ReverseNfa | `public func find(input: SearchInput): Option<ReverseMatch>` | [port/src/reverse.cj:120](../port/src/reverse.cj#L120) | 待逐项审计 |
| 组合引擎和扩展入口 | Rure | `public class Rure` | [port/src/rure.cj:6](../port/src/rure.cj#L6) | 待逐项审计 |
| 组合引擎和扩展入口 | Rure | `public init(pattern: String)` | [port/src/rure.cj:8](../port/src/rure.cj#L8) | 待逐项审计 |
| 组合引擎和扩展入口 | Rure | `public func isMatch(text: String): Bool` | [port/src/rure.cj:11](../port/src/rure.cj#L11) | 待逐项审计 |
| 组合引擎和扩展入口 | Rure | `public func find(text: String): Option<RegexMatch>` | [port/src/rure.cj:14](../port/src/rure.cj#L14) | 待逐项审计 |
| 组合引擎和扩展入口 | Rure | `public func findAt(text: String, at: Int64): Option<RegexMatch>` | [port/src/rure.cj:17](../port/src/rure.cj#L17) | 待逐项审计 |
| NFA 构建与 PikeVM | 顶层函数 | `public func debugByte(byte: Int64): String` | [port/src/search_input.cj:50](../port/src/search_input.cj#L50) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public class SearchInput` | [port/src/search_input.cj:78](../port/src/search_input.cj#L78) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let bytes: Array<UInt8>` | [port/src/search_input.cj:79](../port/src/search_input.cj#L79) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let text: String` | [port/src/search_input.cj:80](../port/src/search_input.cj#L80) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let utf8: Bool` | [port/src/search_input.cj:81](../port/src/search_input.cj#L81) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let start: Int64` | [port/src/search_input.cj:82](../port/src/search_input.cj#L82) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let end: Int64` | [port/src/search_input.cj:83](../port/src/search_input.cj#L83) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let anchor: Int64` | [port/src/search_input.cj:84](../port/src/search_input.cj#L84) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let pattern: Int64` | [port/src/search_input.cj:85](../port/src/search_input.cj#L85) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public let earliest: Bool` | [port/src/search_input.cj:86](../port/src/search_input.cj#L86) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public init(text: String)` | [port/src/search_input.cj:87](../port/src/search_input.cj#L87) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public init(bytes: Array<UInt8>)` | [port/src/search_input.cj:90](../port/src/search_input.cj#L90) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public func span(start: Int64, end: Int64): SearchInput` | [port/src/search_input.cj:110](../port/src/search_input.cj#L110) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public func anchored(yes: Bool): SearchInput` | [port/src/search_input.cj:113](../port/src/search_input.cj#L113) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public func selectPattern(id: Int64): SearchInput` | [port/src/search_input.cj:120](../port/src/search_input.cj#L120) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public func withEarliest(yes: Bool): SearchInput` | [port/src/search_input.cj:123](../port/src/search_input.cj#L123) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public func isAnchored(): Bool` | [port/src/search_input.cj:126](../port/src/search_input.cj#L126) | 待逐项审计 |
| NFA 构建与 PikeVM | SearchInput | `public func selectedPattern(): Int64` | [port/src/search_input.cj:129](../port/src/search_input.cj#L129) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public class AstSpan` | [port/src/syntax_ast.cj:8](../port/src/syntax_ast.cj#L8) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public let startOffset: Int64` | [port/src/syntax_ast.cj:9](../port/src/syntax_ast.cj#L9) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public let startLine: Int64` | [port/src/syntax_ast.cj:10](../port/src/syntax_ast.cj#L10) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public let startColumn: Int64` | [port/src/syntax_ast.cj:11](../port/src/syntax_ast.cj#L11) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public let endOffset: Int64` | [port/src/syntax_ast.cj:12](../port/src/syntax_ast.cj#L12) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public let endLine: Int64` | [port/src/syntax_ast.cj:13](../port/src/syntax_ast.cj#L13) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public let endColumn: Int64` | [port/src/syntax_ast.cj:14](../port/src/syntax_ast.cj#L14) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public init(startOffset: Int64, startLine: Int64, startColumn: Int64, endOffset: Int64, endLine: Int64, endColumn: Int64)` | [port/src/syntax_ast.cj:15](../port/src/syntax_ast.cj#L15) | 待逐项审计 |
| 语法结构解析与转换 | AstSpan | `public func text(): String` | [port/src/syntax_ast.cj:24](../port/src/syntax_ast.cj#L24) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public class AstClassItem` | [port/src/syntax_ast.cj:29](../port/src/syntax_ast.cj#L29) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let label: String` | [port/src/syntax_ast.cj:30](../port/src/syntax_ast.cj#L30) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let span: AstSpan` | [port/src/syntax_ast.cj:31](../port/src/syntax_ast.cj#L31) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let startSpan: AstSpan` | [port/src/syntax_ast.cj:33](../port/src/syntax_ast.cj#L33) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let origin: String` | [port/src/syntax_ast.cj:34](../port/src/syntax_ast.cj#L34) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let endSpan: AstSpan` | [port/src/syntax_ast.cj:35](../port/src/syntax_ast.cj#L35) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let endOrigin: String` | [port/src/syntax_ast.cj:36](../port/src/syntax_ast.cj#L36) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let start: Int64` | [port/src/syntax_ast.cj:37](../port/src/syntax_ast.cj#L37) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let end: Int64` | [port/src/syntax_ast.cj:38](../port/src/syntax_ast.cj#L38) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let negated: Bool` | [port/src/syntax_ast.cj:39](../port/src/syntax_ast.cj#L39) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let children: Array<AstClassItem>` | [port/src/syntax_ast.cj:40](../port/src/syntax_ast.cj#L40) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public let name: String` | [port/src/syntax_ast.cj:41](../port/src/syntax_ast.cj#L41) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public init(label: String, span: AstSpan, startSpan: AstSpan, origin: String, endSpan: AstSpan, endOrigin: String, start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String)` | [port/src/syntax_ast.cj:42](../port/src/syntax_ast.cj#L42) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public init(label: String, start: Int64, end: Int64, negated: Bool, children: Array<AstClassItem>, name: String)` | [port/src/syntax_ast.cj:56](../port/src/syntax_ast.cj#L56) | 待逐项审计 |
| 语法结构解析与转换 | AstClassItem | `public func text(): String` | [port/src/syntax_ast.cj:59](../port/src/syntax_ast.cj#L59) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public class Ast` | [port/src/syntax_ast.cj:97](../port/src/syntax_ast.cj#L97) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public let label: String` | [port/src/syntax_ast.cj:98](../port/src/syntax_ast.cj#L98) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public let span: AstSpan` | [port/src/syntax_ast.cj:99](../port/src/syntax_ast.cj#L99) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var code: Int64` | [port/src/syntax_ast.cj:100](../port/src/syntax_ast.cj#L100) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var greedy: Bool` | [port/src/syntax_ast.cj:101](../port/src/syntax_ast.cj#L101) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var negated: Bool` | [port/src/syntax_ast.cj:102](../port/src/syntax_ast.cj#L102) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var captureIndex: Int64` | [port/src/syntax_ast.cj:103](../port/src/syntax_ast.cj#L103) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var captureName: String` | [port/src/syntax_ast.cj:104](../port/src/syntax_ast.cj#L104) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var startsWithP: Bool` | [port/src/syntax_ast.cj:105](../port/src/syntax_ast.cj#L105) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var quantifier: String` | [port/src/syntax_ast.cj:106](../port/src/syntax_ast.cj#L106) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var minimum: Int64` | [port/src/syntax_ast.cj:107](../port/src/syntax_ast.cj#L107) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var maximum: Int64` | [port/src/syntax_ast.cj:108](../port/src/syntax_ast.cj#L108) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var classItem: AstClassItem` | [port/src/syntax_ast.cj:109](../port/src/syntax_ast.cj#L109) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var flagMask: Int64` | [port/src/syntax_ast.cj:115](../port/src/syntax_ast.cj#L115) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var flagValue: Int64` | [port/src/syntax_ast.cj:116](../port/src/syntax_ast.cj#L116) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseCaseInsensitive: Bool` | [port/src/syntax_ast.cj:117](../port/src/syntax_ast.cj#L117) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseMultiLine: Bool` | [port/src/syntax_ast.cj:118](../port/src/syntax_ast.cj#L118) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseDotAll: Bool` | [port/src/syntax_ast.cj:119](../port/src/syntax_ast.cj#L119) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseSwapGreed: Bool` | [port/src/syntax_ast.cj:120](../port/src/syntax_ast.cj#L120) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseIgnoreWhitespace: Bool` | [port/src/syntax_ast.cj:121](../port/src/syntax_ast.cj#L121) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseCrlf: Bool` | [port/src/syntax_ast.cj:122](../port/src/syntax_ast.cj#L122) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var baseUnicode: Bool` | [port/src/syntax_ast.cj:123](../port/src/syntax_ast.cj#L123) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public var source: String` | [port/src/syntax_ast.cj:124](../port/src/syntax_ast.cj#L124) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func subs(): Array<Ast>` | [port/src/syntax_ast.cj:151](../port/src/syntax_ast.cj#L151) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func visit(enter: (Ast) -> Unit): Unit` | [port/src/syntax_ast.cj:154](../port/src/syntax_ast.cj#L154) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func walk(enter: (Ast) -> Unit, leave: (Ast) -> Unit): Unit` | [port/src/syntax_ast.cj:160](../port/src/syntax_ast.cj#L160) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func walkUntil(enter: (Ast) -> Bool, leave: (Ast) -> Bool): Bool` | [port/src/syntax_ast.cj:168](../port/src/syntax_ast.cj#L168) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func shape(): String` | [port/src/syntax_ast.cj:179](../port/src/syntax_ast.cj#L179) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func toPattern(): String` | [port/src/syntax_ast.cj:196](../port/src/syntax_ast.cj#L196) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public func toHir(): Hir` | [port/src/syntax_ast.cj:201](../port/src/syntax_ast.cj#L201) | 待逐项审计 |
| 语法结构解析与转换 | Ast | `public static func parse(pattern: String): Ast` | [port/src/syntax_ast.cj:204](../port/src/syntax_ast.cj#L204) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public class SyntaxParser` | [port/src/syntax_ast.cj:1865](../port/src/syntax_ast.cj#L1865) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var caseInsensitive: Bool = false` | [port/src/syntax_ast.cj:1866](../port/src/syntax_ast.cj#L1866) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var multiLine: Bool = false` | [port/src/syntax_ast.cj:1867](../port/src/syntax_ast.cj#L1867) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var dotAll: Bool = false` | [port/src/syntax_ast.cj:1868](../port/src/syntax_ast.cj#L1868) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var swapGreed: Bool = false` | [port/src/syntax_ast.cj:1869](../port/src/syntax_ast.cj#L1869) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var ignoreWhitespace: Bool = false` | [port/src/syntax_ast.cj:1870](../port/src/syntax_ast.cj#L1870) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var crlf: Bool = false` | [port/src/syntax_ast.cj:1871](../port/src/syntax_ast.cj#L1871) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var unicode: Bool = true` | [port/src/syntax_ast.cj:1872](../port/src/syntax_ast.cj#L1872) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var utf8: Bool = true` | [port/src/syntax_ast.cj:1873](../port/src/syntax_ast.cj#L1873) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var octal: Bool = false` | [port/src/syntax_ast.cj:1874](../port/src/syntax_ast.cj#L1874) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public var nestLimit: Int64 = 250` | [port/src/syntax_ast.cj:1875](../port/src/syntax_ast.cj#L1875) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public init()` | [port/src/syntax_ast.cj:1876](../port/src/syntax_ast.cj#L1876) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public func parseAst(pattern: String): Ast` | [port/src/syntax_ast.cj:1877](../port/src/syntax_ast.cj#L1877) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public func parseHir(pattern: String): Hir` | [port/src/syntax_ast.cj:1894](../port/src/syntax_ast.cj#L1894) | 待逐项审计 |
| 语法结构解析与转换 | SyntaxParser | `public func translate(ast: Ast): Hir` | [port/src/syntax_ast.cj:1899](../port/src/syntax_ast.cj#L1899) | 待逐项审计 |
| 语法结构解析与转换 | HirUnsupportedError | `public class HirUnsupportedError <: Exception` | [port/src/syntax_hir.cj:8](../port/src/syntax_hir.cj#L8) | 待逐项审计 |
| 语法结构解析与转换 | HirUnsupportedError | `public init(message: String)` | [port/src/syntax_hir.cj:9](../port/src/syntax_hir.cj#L9) | 待逐项审计 |
| 语法结构解析与转换 | HirRange | `public class HirRange` | [port/src/syntax_hir.cj:14](../port/src/syntax_hir.cj#L14) | 待逐项审计 |
| 语法结构解析与转换 | HirRange | `public let start: Int64` | [port/src/syntax_hir.cj:15](../port/src/syntax_hir.cj#L15) | 待逐项审计 |
| 语法结构解析与转换 | HirRange | `public let end: Int64` | [port/src/syntax_hir.cj:16](../port/src/syntax_hir.cj#L16) | 待逐项审计 |
| 语法结构解析与转换 | HirRange | `public init(start: Int64, end: Int64)` | [port/src/syntax_hir.cj:17](../port/src/syntax_hir.cj#L17) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public class HirClass` | [port/src/syntax_hir.cj:31](../port/src/syntax_hir.cj#L31) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public let isBytes: Bool` | [port/src/syntax_hir.cj:32](../port/src/syntax_hir.cj#L32) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func ranges(): Array<HirRange>` | [port/src/syntax_hir.cj:38](../port/src/syntax_hir.cj#L38) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func isEmpty(): Bool` | [port/src/syntax_hir.cj:41](../port/src/syntax_hir.cj#L41) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func union(other: HirClass): Hir` | [port/src/syntax_hir.cj:44](../port/src/syntax_hir.cj#L44) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func intersect(other: HirClass): Hir` | [port/src/syntax_hir.cj:47](../port/src/syntax_hir.cj#L47) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func difference(other: HirClass): Hir` | [port/src/syntax_hir.cj:50](../port/src/syntax_hir.cj#L50) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func negate(): Hir` | [port/src/syntax_hir.cj:53](../port/src/syntax_hir.cj#L53) | 待逐项审计 |
| 语法结构解析与转换 | HirClass | `public func caseFold(): Hir` | [port/src/syntax_hir.cj:74](../port/src/syntax_hir.cj#L74) | 待逐项审计 |
| 语法结构解析与转换 | HirRepetition | `public class HirRepetition` | [port/src/syntax_hir.cj:88](../port/src/syntax_hir.cj#L88) | 待逐项审计 |
| 语法结构解析与转换 | HirRepetition | `public let min: UInt32` | [port/src/syntax_hir.cj:89](../port/src/syntax_hir.cj#L89) | 待逐项审计 |
| 语法结构解析与转换 | HirRepetition | `public let max: Option<UInt32>` | [port/src/syntax_hir.cj:90](../port/src/syntax_hir.cj#L90) | 待逐项审计 |
| 语法结构解析与转换 | HirRepetition | `public let greedy: Bool` | [port/src/syntax_hir.cj:91](../port/src/syntax_hir.cj#L91) | 待逐项审计 |
| 语法结构解析与转换 | HirRepetition | `public let sub: Hir` | [port/src/syntax_hir.cj:92](../port/src/syntax_hir.cj#L92) | 待逐项审计 |
| 语法结构解析与转换 | HirCapture | `public class HirCapture` | [port/src/syntax_hir.cj:101](../port/src/syntax_hir.cj#L101) | 待逐项审计 |
| 语法结构解析与转换 | HirCapture | `public let index: UInt32` | [port/src/syntax_hir.cj:102](../port/src/syntax_hir.cj#L102) | 待逐项审计 |
| 语法结构解析与转换 | HirCapture | `public let name: Option<String>` | [port/src/syntax_hir.cj:103](../port/src/syntax_hir.cj#L103) | 待逐项审计 |
| 语法结构解析与转换 | HirCapture | `public let sub: Hir` | [port/src/syntax_hir.cj:104](../port/src/syntax_hir.cj#L104) | 待逐项审计 |
| 语法结构解析与转换 | HirLook | `public enum HirLook` | [port/src/syntax_hir.cj:112](../port/src/syntax_hir.cj#L112) | 待逐项审计 |
| 语法结构解析与转换 | HirDot | `public enum HirDot` | [port/src/syntax_hir.cj:133](../port/src/syntax_hir.cj#L133) | 待逐项审计 |
| 语法结构解析与转换 | HirKind | `public enum HirKind` | [port/src/syntax_hir.cj:137](../port/src/syntax_hir.cj#L137) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public class HirProperties` | [port/src/syntax_hir.cj:148](../port/src/syntax_hir.cj#L148) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func minimumLen(): Option<UInt64>` | [port/src/syntax_hir.cj:177](../port/src/syntax_hir.cj#L177) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func maximumLen(): Option<UInt64>` | [port/src/syntax_hir.cj:180](../port/src/syntax_hir.cj#L180) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func isUtf8(): Bool` | [port/src/syntax_hir.cj:183](../port/src/syntax_hir.cj#L183) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func explicitCapturesLen(): Int64` | [port/src/syntax_hir.cj:186](../port/src/syntax_hir.cj#L186) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func staticExplicitCapturesLen(): Option<Int64>` | [port/src/syntax_hir.cj:189](../port/src/syntax_hir.cj#L189) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func isLiteral(): Bool` | [port/src/syntax_hir.cj:192](../port/src/syntax_hir.cj#L192) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func isAlternationLiteral(): Bool` | [port/src/syntax_hir.cj:195](../port/src/syntax_hir.cj#L195) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func lookSet(): UInt64` | [port/src/syntax_hir.cj:198](../port/src/syntax_hir.cj#L198) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func lookSetPrefix(): UInt64` | [port/src/syntax_hir.cj:201](../port/src/syntax_hir.cj#L201) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func lookSetPrefixAny(): UInt64` | [port/src/syntax_hir.cj:204](../port/src/syntax_hir.cj#L204) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func lookSetSuffix(): UInt64` | [port/src/syntax_hir.cj:207](../port/src/syntax_hir.cj#L207) | 待逐项审计 |
| 语法结构解析与转换 | HirProperties | `public func lookSetSuffixAny(): UInt64` | [port/src/syntax_hir.cj:210](../port/src/syntax_hir.cj#L210) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public class Hir` | [port/src/syntax_hir.cj:215](../port/src/syntax_hir.cj#L215) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func kind(): HirKind` | [port/src/syntax_hir.cj:223](../port/src/syntax_hir.cj#L223) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func properties(): HirProperties` | [port/src/syntax_hir.cj:231](../port/src/syntax_hir.cj#L231) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func subs(): Array<Hir>` | [port/src/syntax_hir.cj:234](../port/src/syntax_hir.cj#L234) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func visit(enter: (Hir) -> Unit): Unit` | [port/src/syntax_hir.cj:243](../port/src/syntax_hir.cj#L243) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func walk(enter: (Hir) -> Unit, leave: (Hir) -> Unit): Unit` | [port/src/syntax_hir.cj:257](../port/src/syntax_hir.cj#L257) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func walkUntil(enter: (Hir) -> Bool, leave: (Hir) -> Bool): Bool` | [port/src/syntax_hir.cj:272](../port/src/syntax_hir.cj#L272) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public func toPattern(): String` | [port/src/syntax_hir.cj:284](../port/src/syntax_hir.cj#L284) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func empty(): Hir` | [port/src/syntax_hir.cj:289](../port/src/syntax_hir.cj#L289) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func fail(): Hir` | [port/src/syntax_hir.cj:292](../port/src/syntax_hir.cj#L292) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func literal(bytes: Array<UInt8>): Hir` | [port/src/syntax_hir.cj:295](../port/src/syntax_hir.cj#L295) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func unicodeClass(ranges: Array<HirRange>): Hir` | [port/src/syntax_hir.cj:302](../port/src/syntax_hir.cj#L302) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func byteClass(ranges: Array<HirRange>): Hir` | [port/src/syntax_hir.cj:305](../port/src/syntax_hir.cj#L305) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func capture(index: UInt32, name: Option<String>, sub: Hir): Hir` | [port/src/syntax_hir.cj:357](../port/src/syntax_hir.cj#L357) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func repetition(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir): Hir` | [port/src/syntax_hir.cj:360](../port/src/syntax_hir.cj#L360) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func concat(children: Array<Hir>): Hir` | [port/src/syntax_hir.cj:391](../port/src/syntax_hir.cj#L391) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func look(look: HirLook): Hir` | [port/src/syntax_hir.cj:434](../port/src/syntax_hir.cj#L434) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func dot(dot: HirDot): Hir` | [port/src/syntax_hir.cj:437](../port/src/syntax_hir.cj#L437) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func dotExcept(bytes: Bool, excluded: Int64): Hir` | [port/src/syntax_hir.cj:447](../port/src/syntax_hir.cj#L447) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func alternation(subs: Array<Hir>): Hir` | [port/src/syntax_hir.cj:450](../port/src/syntax_hir.cj#L450) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func parse(pattern: String): Hir` | [port/src/syntax_hir.cj:527](../port/src/syntax_hir.cj#L527) | 待逐项审计 |
| 语法结构解析与转换 | Hir | `public static func parse(pattern: String, utf8: Bool): Hir` | [port/src/syntax_hir.cj:530](../port/src/syntax_hir.cj#L530) | 待逐项审计 |
| 语法结构解析与转换 | 顶层函数 | `public func hirLookName(look: HirLook): String` | [port/src/syntax_hir.cj:1494](../port/src/syntax_hir.cj#L1494) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralPiece | `public class LiteralPiece` | [port/src/syntax_literal.cj:7](../port/src/syntax_literal.cj#L7) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralPiece | `public let exact: Bool` | [port/src/syntax_literal.cj:8](../port/src/syntax_literal.cj#L8) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralPiece | `public let bytes: Array<UInt8>` | [port/src/syntax_literal.cj:9](../port/src/syntax_literal.cj#L9) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralPiece | `public init(exact: Bool, bytes: Array<UInt8>)` | [port/src/syntax_literal.cj:10](../port/src/syntax_literal.cj#L10) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public class LiteralSeq` | [port/src/syntax_literal.cj:16](../port/src/syntax_literal.cj#L16) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public let finite: Bool` | [port/src/syntax_literal.cj:17](../port/src/syntax_literal.cj#L17) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public let pieces: Array<LiteralPiece>` | [port/src/syntax_literal.cj:18](../port/src/syntax_literal.cj#L18) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public static func infinite(): LiteralSeq` | [port/src/syntax_literal.cj:23](../port/src/syntax_literal.cj#L23) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public static func of(pieces: Array<LiteralPiece>): LiteralSeq` | [port/src/syntax_literal.cj:26](../port/src/syntax_literal.cj#L26) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func isEmpty(): Bool` | [port/src/syntax_literal.cj:29](../port/src/syntax_literal.cj#L29) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func isExact(): Bool` | [port/src/syntax_literal.cj:32](../port/src/syntax_literal.cj#L32) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func isInexact(): Bool` | [port/src/syntax_literal.cj:43](../port/src/syntax_literal.cj#L43) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func literalCount(): Option<Int64>` | [port/src/syntax_literal.cj:54](../port/src/syntax_literal.cj#L54) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func minLiteralLen(): Option<Int64>` | [port/src/syntax_literal.cj:61](../port/src/syntax_literal.cj#L61) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func maxUnionLen(other: LiteralSeq): Option<Int64>` | [port/src/syntax_literal.cj:73](../port/src/syntax_literal.cj#L73) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func maxCrossLen(other: LiteralSeq): Option<Int64>` | [port/src/syntax_literal.cj:82](../port/src/syntax_literal.cj#L82) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func maxLiteralLen(): Option<Int64>` | [port/src/syntax_literal.cj:91](../port/src/syntax_literal.cj#L91) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func crossForward(other: LiteralSeq): LiteralSeq` | [port/src/syntax_literal.cj:103](../port/src/syntax_literal.cj#L103) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func crossReverse(other: LiteralSeq): LiteralSeq` | [port/src/syntax_literal.cj:109](../port/src/syntax_literal.cj#L109) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func union(other: LiteralSeq): LiteralSeq` | [port/src/syntax_literal.cj:115](../port/src/syntax_literal.cj#L115) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func unionIntoEmpty(other: LiteralSeq): LiteralSeq` | [port/src/syntax_literal.cj:121](../port/src/syntax_literal.cj#L121) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func keepFirst(len: Int64): LiteralSeq` | [port/src/syntax_literal.cj:127](../port/src/syntax_literal.cj#L127) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func keepLast(len: Int64): LiteralSeq` | [port/src/syntax_literal.cj:135](../port/src/syntax_literal.cj#L135) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func minimize(): LiteralSeq` | [port/src/syntax_literal.cj:143](../port/src/syntax_literal.cj#L143) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func optimizePrefix(): LiteralSeq` | [port/src/syntax_literal.cj:148](../port/src/syntax_literal.cj#L148) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func optimizeSuffix(): LiteralSeq` | [port/src/syntax_literal.cj:153](../port/src/syntax_literal.cj#L153) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func reversed(): LiteralSeq` | [port/src/syntax_literal.cj:158](../port/src/syntax_literal.cj#L158) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func sorted(): LiteralSeq` | [port/src/syntax_literal.cj:163](../port/src/syntax_literal.cj#L163) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func makeInexact(): LiteralSeq` | [port/src/syntax_literal.cj:168](../port/src/syntax_literal.cj#L168) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func deduped(): LiteralSeq` | [port/src/syntax_literal.cj:173](../port/src/syntax_literal.cj#L173) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func commonPrefix(): Option<Array<UInt8>>` | [port/src/syntax_literal.cj:178](../port/src/syntax_literal.cj#L178) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralSeq | `public func commonSuffix(): Option<Array<UInt8>>` | [port/src/syntax_literal.cj:181](../port/src/syntax_literal.cj#L181) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public class LiteralLimits` | [port/src/syntax_literal.cj:186](../port/src/syntax_literal.cj#L186) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public let classLimit: Int64` | [port/src/syntax_literal.cj:187](../port/src/syntax_literal.cj#L187) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public let repeatLimit: Int64` | [port/src/syntax_literal.cj:188](../port/src/syntax_literal.cj#L188) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public let literalLen: Int64` | [port/src/syntax_literal.cj:189](../port/src/syntax_literal.cj#L189) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public let totalLimit: Int64` | [port/src/syntax_literal.cj:190](../port/src/syntax_literal.cj#L190) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public init()` | [port/src/syntax_literal.cj:191](../port/src/syntax_literal.cj#L191) | 待逐项审计 |
| 字面量和 UTF-8 工具 | LiteralLimits | `public init(classLimit: Int64, repeatLimit: Int64, literalLen: Int64, totalLimit: Int64)` | [port/src/syntax_literal.cj:194](../port/src/syntax_literal.cj#L194) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func extractLiterals(hir: Hir): LiteralSeq` | [port/src/syntax_literal.cj:205](../port/src/syntax_literal.cj#L205) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func extractLiterals(hir: Hir, suffix: Bool): LiteralSeq` | [port/src/syntax_literal.cj:209](../port/src/syntax_literal.cj#L209) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func extractLiterals(hir: Hir, suffix: Bool, limits: LiteralLimits): LiteralSeq` | [port/src/syntax_literal.cj:213](../port/src/syntax_literal.cj#L213) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func formatLiterals(hir: Hir, suffix: Bool): String` | [port/src/syntax_literal.cj:218](../port/src/syntax_literal.cj#L218) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func formatLiterals(hir: Hir, suffix: Bool, limits: LiteralLimits): String` | [port/src/syntax_literal.cj:222](../port/src/syntax_literal.cj#L222) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func formatLiteralSeq(seq: LiteralSeq): String` | [port/src/syntax_literal.cj:243](../port/src/syntax_literal.cj#L243) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func formatCommon(bytes: Option<Array<UInt8>>): String` | [port/src/syntax_literal.cj:261](../port/src/syntax_literal.cj#L261) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public class ThompsonNfa` | [port/src/thompson.cj:242](../port/src/thompson.cj#L242) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public init(patterns: Array<String>)` | [port/src/thompson.cj:245](../port/src/thompson.cj#L245) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public init(patterns: Array<String>, whichCaptures: Int64)` | [port/src/thompson.cj:248](../port/src/thompson.cj#L248) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public init(hirs: Array<Hir>)` | [port/src/thompson.cj:252](../port/src/thompson.cj#L252) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public init(patterns: Array<String>, whichCaptures: Int64, unicode: Bool)` | [port/src/thompson.cj:255](../port/src/thompson.cj#L255) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public init(hirs: Array<Hir>, sizeLimit: Int64)` | [port/src/thompson.cj:259](../port/src/thompson.cj#L259) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func stateCount(): Int64` | [port/src/thompson.cj:287](../port/src/thompson.cj#L287) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func memoryUsage(): Int64` | [port/src/thompson.cj:290](../port/src/thompson.cj#L290) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func patternCount(): Int64` | [port/src/thompson.cj:300](../port/src/thompson.cj#L300) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func patternStateCount(pattern: Int64): Int64` | [port/src/thompson.cj:303](../port/src/thompson.cj#L303) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func startState(pattern: Int64): Int64` | [port/src/thompson.cj:306](../port/src/thompson.cj#L306) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func opName(pattern: Int64, state: Int64): String` | [port/src/thompson.cj:310](../port/src/thompson.cj#L310) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func opNext(pattern: Int64, state: Int64): Int64` | [port/src/thompson.cj:321](../port/src/thompson.cj#L321) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func opAlternate(pattern: Int64, state: Int64): Int64` | [port/src/thompson.cj:324](../port/src/thompson.cj#L324) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func whichOverlapping(text: String): Array<Int64>` | [port/src/thompson.cj:327](../port/src/thompson.cj#L327) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func whichOverlapping(input: SearchInput): Array<Int64>` | [port/src/thompson.cj:333](../port/src/thompson.cj#L333) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func search(input: SearchInput, cache: PikeCache): Option<PikeMatch>` | [port/src/thompson.cj:424](../port/src/thompson.cj#L424) | 待逐项审计 |
| NFA 构建与 PikeVM | ThompsonNfa | `public func isMatch(input: SearchInput, cache: PikeCache): Bool` | [port/src/thompson.cj:466](../port/src/thompson.cj#L466) | 待逐项审计 |
| 字面量和 UTF-8 工具 | Utf8Sequence | `public class Utf8Sequence` | [port/src/utf8seq.cj:7](../port/src/utf8seq.cj#L7) | 待逐项审计 |
| 字面量和 UTF-8 工具 | Utf8Sequence | `public let starts: Array<Int64>` | [port/src/utf8seq.cj:8](../port/src/utf8seq.cj#L8) | 待逐项审计 |
| 字面量和 UTF-8 工具 | Utf8Sequence | `public let ends: Array<Int64>` | [port/src/utf8seq.cj:9](../port/src/utf8seq.cj#L9) | 待逐项审计 |
| 字面量和 UTF-8 工具 | Utf8Sequence | `public func text(): String` | [port/src/utf8seq.cj:14](../port/src/utf8seq.cj#L14) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func utf8SequenceLines(start: Int64, end: Int64): String` | [port/src/utf8seq.cj:29](../port/src/utf8seq.cj#L29) | 待逐项审计 |
| 字面量和 UTF-8 工具 | 顶层函数 | `public func utf8SequencesOf(start: Int64, end: Int64): Array<Utf8Sequence>` | [port/src/utf8seq.cj:41](../port/src/utf8seq.cj#L41) | 待逐项审计 |
