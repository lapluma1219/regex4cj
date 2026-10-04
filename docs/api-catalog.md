# 仓颉公开接口数量与逐项行为

统计基线：`b40034516279644cc53cbc4dba4ff77e07b8c8c3` 加2026-10-04公开HIR切片工作区修改。扫描范围为 `port/src/*.cj`；不包含CLI命令、测试探针、内部方法或依赖库继承而未显式声明的方法。此文档是该工作区状态的静态快照，公开代码变化后需重新核对。

## 统计口径

**208个公开可调用入口 = 187个公开方法 + 20个公开构造器 + 1个顶层函数。另有28个公开字段，不计入208。** 同名方法在不同类型上分别计数；每个显式公开构造器计一次，不计包内构造器。`Regex.find`和`BytesRegex.find`因此算两个入口，但并不代表两种独立业务功能。

公开类型共36个（34个class和2个enum）。`RegexErrorKind`与`HirKind`的枚举分支单独说明，不算函数。接口数量是代码规模口径，不是移植完成率。

原仓库审计有170条固有方法记录：132条“有样例验证”，38条“有明确差异”，映射到151个不同仓颉符号（包括字段）。多条原仓库记录可以共用仓颉入口，原仓库方法也可由字段替代；仓颉另有数组便捷方法、回调构造器等，新增HIR切片对应regex-syntax，另有[范围与示例](hir.md)。因此170与208不能相除作为完成率。宏、trait与构建特性不在这个分母里。

本表的“行为”来自当前实现与[API说明](api.md)。原仓库状态沿用[接口审计](api-audit.md)，存在样例不等于完整语义等价。有些入口在原仓库映射表中没有单独条目，并不表示没有测试。

## 按类型汇总

| 类型 | 方法/函数 | 公开构造器 | 可调用合计 | 公开字段 |
|---|---:|---:|---:|---:|
| Regex | 28 | 1 | 29 | 0 |
| BytesRegex | 28 | 1 | 29 | 0 |
| RegexSet | 8 | 1 | 9 | 0 |
| BytesRegexSet | 8 | 1 | 9 | 0 |
| RegexBuilder | 13 | 1 | 14 | 0 |
| BytesRegexBuilder | 13 | 1 | 14 | 0 |
| RegexSetBuilder | 14 | 2 | 16 | 0 |
| BytesRegexSetBuilder | 14 | 2 | 16 | 0 |
| RegexMatch | 3 | 0 | 3 | 3 |
| BytesMatch | 2 | 1 | 3 | 3 |
| Captures | 7 | 0 | 7 | 1 |
| BytesCaptures | 7 | 0 | 7 | 1 |
| CaptureSpan | 0 | 0 | 0 | 2 |
| CaptureLocations | 1 | 0 | 1 | 1 |
| SetMatches | 6 | 0 | 6 | 0 |
| SetMatchesIter | 4 | 0 | 4 | 0 |
| MatchIter | 1 | 1 | 2 | 0 |
| CaptureIter | 1 | 1 | 2 | 0 |
| SplitIter | 1 | 1 | 2 | 0 |
| BytesMatchIter | 1 | 1 | 2 | 0 |
| BytesCaptureIter | 1 | 1 | 2 | 0 |
| BytesSplitIter | 1 | 1 | 2 | 0 |
| GroupIter | 4 | 0 | 4 | 0 |
| BytesGroupIter | 4 | 0 | 4 | 0 |
| GroupItem | 0 | 0 | 0 | 2 |
| BytesGroupItem | 0 | 0 | 0 | 2 |
| RegexError | 1 | 1 | 2 | 3 |
| Hir | 13 | 0 | 13 | 0 |
| HirProperties | 2 | 0 | 2 | 0 |
| HirRange | 0 | 1 | 1 | 2 |
| HirClass | 1 | 0 | 1 | 1 |
| HirCapture | 0 | 0 | 0 | 3 |
| HirRepetition | 0 | 0 | 0 | 4 |
| HirUnsupportedError | 0 | 1 | 1 | 0 |
| 顶层函数 | 1 | 0 | 1 | 0 |
| **合计** | **188** | **20** | **208** | **28** |

## 共同约定

- 字符串输入是String，bytes输入与输出片段为Array<UInt8>，可包含非法UTF-8；bytes的模式本身仍是String。具体参数顺序与返回类型见每行签名。
- 位置均为原输入字节偏移的半开区间[start,end)。合法的字符串内部字节起点会从后续字符边界搜索，断言仍可看到之前的上下文；负数或越界起点抛异常。
- 无匹配通常返回None、false或空数组。无匹配不等于非法模式；后者在编译时抛RegexError。
- 内置bytes迭代器复制输入后逐次搜索，字符串迭代器会准备扫描信息；不是零复制，也不是流式读取文件。
- 模板支持捕获展开，替换0次限制表示不限；分割0段限制表示无结果。
- 所有Builder选项方法返回当前Builder，支持链式调用。资源限额与Rust的引擎实现存在差异，见各行说明。

## 逐项清单

### Regex

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/nfa.cj#L352)（构造器） | `public init(pattern: String)` | 使用默认选项解析并编译模式；语法错误或编译超限抛RegexError。 | 有样例验证 |
| [asStr](../port/src/nfa.cj#L417)（方法） | `public func asStr(): String` | 返回编译时的原始正则模式。 | 有样例验证 |
| [staticCapturesLen](../port/src/nfa.cj#L420)（方法） | `public func staticCapturesLen(): Option<Int64>` | 若每次匹配实际参与的捕获数量固定，返回Some(数量，含组0)，否则None；不是总槽位数。 | 有样例验证 |
| [find](../port/src/nfa.cj#L551)（方法） | `public func find(text: String): Option<RegexMatch>` | 返回第一条匹配的位置与原文片段；无匹配返回None。 | 有样例验证 |
| [isMatch](../port/src/nfa.cj#L563)（方法） | `public func isMatch(text: String): Bool` | 判断输入中是否存在匹配，返回Bool。 | 有样例验证 |
| [findAt](../port/src/nfa.cj#L574)（方法） | `public func findAt(text: String, start: Int64): Option<RegexMatch>` | 从指定字节起点查找第一条匹配，返回Option；保留原输入上下文。 | 有样例验证 |
| [isMatchAt](../port/src/nfa.cj#L582)（方法） | `public func isMatchAt(text: String, start: Int64): Bool` | 从指定字节起点判断有无匹配，保留原输入上下文。 | 有样例验证 |
| [shortestMatch](../port/src/nfa.cj#L588)（方法） | `public func shortestMatch(text: String): Option<Int64>` | 返回引擎确认命中时的早停终点，未命中返回None；不是数学最短，不保证与Rust其他引擎逐输入相同。 | 有明确差异：早停终点允许依赖内部引擎；不承诺逐输入与 Rust meta 的终点相等，也不承诺数学最短。 |
| [shortestMatchAt](../port/src/nfa.cj#L591)（方法） | `public func shortestMatchAt(text: String, start: Int64): Option<Int64>` | 从指定字节起点搜索并返回早停终点；边界与shortestMatch相同。 | 有明确差异：早停终点允许依赖内部引擎；不承诺逐输入与 Rust meta 的终点相等，也不承诺数学最短。 |
| [capturesAt](../port/src/nfa.cj#L599)（方法） | `public func capturesAt(text: String, start: Int64): Option<Captures>` | 从指定字节起点搜索，返回第一次匹配的捕获组。 | 有样例验证 |
| [findIter](../port/src/nfa.cj#L607)（方法） | `public func findIter(text: String): MatchIter` | 返回按next逐次搜索的匹配迭代器，结果不重叠；不会先收集全部匹配。 | 有样例验证 |
| [capturesIter](../port/src/nfa.cj#L631)（方法） | `public func capturesIter(text: String): CaptureIter` | 返回按next逐次搜索的捕获迭代器。 | 有样例验证 |
| [splitIter](../port/src/nfa.cj#L655)（方法） | `public func splitIter(text: String): SplitIter` | 返回按next逐次取分割片段的迭代器，保留首尾空段。 | 有样例验证 |
| [splitNIter](../port/src/nfa.cj#L695)（方法） | `public func splitNIter(text: String, limit: Int64): SplitIter` | 按next最多取limit段；0无结果，1返回原输入，最后一段保留余文，负数抛异常。 | 有样例验证 |
| [captureLocations](../port/src/nfa.cj#L724)（方法） | `public func captureLocations(): CaptureLocations` | 创建与此模式对应、可重复写入的捕获位置容器。 | 有明确差异；有样例验证：上游 doc(hidden) 的历史别名；仓颉使用对应的新名称。 |
| [capturesRead](../port/src/nfa.cj#L727)（方法） | `public func capturesRead(locations: CaptureLocations, text: String): Option<RegexMatch>` | 从起点0搜索并写入位置容器，返回完整匹配；失败时清空可读位置。 | 有样例验证 |
| [capturesReadAt](../port/src/nfa.cj#L730)（方法） | `public func capturesReadAt(locations: CaptureLocations, text: String, start: Int64): Option<RegexMatch>` | 从指定字节起点搜索并覆盖位置容器；失败或未参与的组不可读，不保留上次结果。 | 有明确差异；有样例验证：上游 doc(hidden) 的历史别名；仓颉使用对应的新名称。 |
| [findAll](../port/src/nfa.cj#L756)（方法） | `public func findAll(text: String): Array<RegexMatch>` | 立即搜索并返回全部不重叠匹配数组。 | 不单列于170条对应表 |
| [capturesLen](../port/src/nfa.cj#L780)（方法） | `public func capturesLen(): Int64` | 返回模式捕获组槽位总数，包括完整匹配组0。 | 有样例验证 |
| [captureNames](../port/src/nfa.cj#L783)（方法） | `public func captureNames(): Array<Option<String>>` | 返回按组号排列的名称数组；组0及未命名组为None。 | 有样例验证 |
| [captures](../port/src/nfa.cj#L808)（方法） | `public func captures(text: String): Option<Captures>` | 返回第一次匹配的捕获组，组0是整个匹配；无匹配返回None。 | 有样例验证 |
| [capturesAll](../port/src/nfa.cj#L815)（方法） | `public func capturesAll(text: String): Array<Captures>` | 立即收集所有不重叠匹配的捕获组，返回数组。 | 不单列于170条对应表 |
| [replace](../port/src/nfa.cj#L835)（方法） | `public func replace(text: String, replacement: String): String` | 用模板替换第一次匹配，返回新输入；模板可引用捕获组。 | 有样例验证 |
| [replaceAll](../port/src/nfa.cj#L838)（方法） | `public func replaceAll(text: String, replacement: String): String` | 用模板替换全部不重叠匹配。 | 有样例验证 |
| [replaceN](../port/src/nfa.cj#L842)（方法） | `public func replaceN(text: String, limit: Int64, replacement: String): String` | 最多替换limit次；0表示不限，负数抛异常。 | 有样例验证 |
| [replaceLiteral](../port/src/nfa.cj#L855)（方法） | `public func replaceLiteral(text: String, limit: Int64, replacement: String): String` | 最多替换limit次，将替换内容作为字面量，不展开$；0不限，负数抛异常。 | 不单列于170条对应表 |
| [replaceWith](../port/src/nfa.cj#L858)（方法） | `public func replaceWith(text: String, limit: Int64, replacer: (Captures) -> String): String` | 每次匹配调用回调产生替换内容；0不限，负数抛异常。 | 不单列于170条对应表 |
| [split](../port/src/nfa.cj#L892)（方法） | `public func split(text: String): Array<String>` | 按匹配分割，立即返回片段数组，保留首尾空段。 | 不单列于170条对应表 |
| [splitN](../port/src/nfa.cj#L896)（方法） | `public func splitN(text: String, limit: Int64): Array<String>` | 最多分成limit段，最后一段保留剩余输入；0返回空数组，1返回原输入，负数抛异常。 | 不单列于170条对应表 |

### BytesRegex

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/bytes.cj#L33)（构造器） | `public init(pattern: String)` | 使用默认选项解析并编译模式；语法错误或编译超限抛RegexError。 | 有样例验证 |
| [asStr](../port/src/bytes.cj#L96)（方法） | `public func asStr(): String` | 返回编译时的原始正则模式。 | 有样例验证 |
| [capturesLen](../port/src/bytes.cj#L99)（方法） | `public func capturesLen(): Int64` | 返回模式捕获组槽位总数，包括完整匹配组0。 | 有样例验证 |
| [staticCapturesLen](../port/src/bytes.cj#L102)（方法） | `public func staticCapturesLen(): Option<Int64>` | 若每次匹配实际参与的捕获数量固定，返回Some(数量，含组0)，否则None；不是总槽位数。 | 有样例验证 |
| [captureNames](../port/src/bytes.cj#L109)（方法） | `public func captureNames(): Array<Option<String>>` | 返回按组号排列的名称数组；组0及未命名组为None。 | 有样例验证 |
| [captureLocations](../port/src/bytes.cj#L118)（方法） | `public func captureLocations(): CaptureLocations` | 创建与此模式对应、可重复写入的捕获位置容器。 | 有明确差异；有样例验证：上游 doc(hidden) 的历史别名；仓颉使用对应的新名称。 |
| [find](../port/src/bytes.cj#L121)（方法） | `public func find(haystack: Array<UInt8>): Option<BytesMatch>` | 返回第一条匹配的位置与原文片段；无匹配返回None。 | 有样例验证 |
| [isMatch](../port/src/bytes.cj#L124)（方法） | `public func isMatch(haystack: Array<UInt8>): Bool` | 判断输入中是否存在匹配，返回Bool。 | 有样例验证 |
| [findAt](../port/src/bytes.cj#L127)（方法） | `public func findAt(haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | 从指定字节起点查找第一条匹配，返回Option；保留原输入上下文。 | 有样例验证 |
| [isMatchAt](../port/src/bytes.cj#L133)（方法） | `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | 从指定字节起点判断有无匹配，保留原输入上下文。 | 有样例验证 |
| [shortestMatch](../port/src/bytes.cj#L139)（方法） | `public func shortestMatch(haystack: Array<UInt8>): Option<Int64>` | 返回引擎确认命中时的早停终点，未命中返回None；不是数学最短，不保证与Rust其他引擎逐输入相同。 | 有明确差异：早停终点允许依赖内部引擎；不承诺逐输入与 Rust meta 的终点相等，也不承诺数学最短。 |
| [shortestMatchAt](../port/src/bytes.cj#L142)（方法） | `public func shortestMatchAt(haystack: Array<UInt8>, start: Int64): Option<Int64>` | 从指定字节起点搜索并返回早停终点；边界与shortestMatch相同。 | 有明确差异：早停终点允许依赖内部引擎；不承诺逐输入与 Rust meta 的终点相等，也不承诺数学最短。 |
| [findIter](../port/src/bytes.cj#L172)（方法） | `public func findIter(haystack: Array<UInt8>): BytesMatchIter` | 返回按next逐次搜索的匹配迭代器，结果不重叠；不会先收集全部匹配。 | 有样例验证 |
| [capturesIter](../port/src/bytes.cj#L182)（方法） | `public func capturesIter(haystack: Array<UInt8>): BytesCaptureIter` | 返回按next逐次搜索的捕获迭代器。 | 有样例验证 |
| [splitIter](../port/src/bytes.cj#L192)（方法） | `public func splitIter(haystack: Array<UInt8>): BytesSplitIter` | 返回按next逐次取分割片段的迭代器，保留首尾空段。 | 有样例验证 |
| [splitNIter](../port/src/bytes.cj#L195)（方法） | `public func splitNIter(haystack: Array<UInt8>, limit: Int64): BytesSplitIter` | 按next最多取limit段；0无结果，1返回原输入，最后一段保留余文，负数抛异常。 | 有样例验证 |
| [capturesRead](../port/src/bytes.cj#L228)（方法） | `public func capturesRead(locations: CaptureLocations, haystack: Array<UInt8>): Option<BytesMatch>` | 从起点0搜索并写入位置容器，返回完整匹配；失败时清空可读位置。 | 有样例验证 |
| [findAll](../port/src/bytes.cj#L231)（方法） | `public func findAll(haystack: Array<UInt8>): Array<BytesMatch>` | 立即搜索并返回全部不重叠匹配数组。 | 不单列于170条对应表 |
| [captures](../port/src/bytes.cj#L356)（方法） | `public func captures(haystack: Array<UInt8>): Option<BytesCaptures>` | 返回第一次匹配的捕获组，组0是整个匹配；无匹配返回None。 | 有样例验证 |
| [capturesAt](../port/src/bytes.cj#L359)（方法） | `public func capturesAt(haystack: Array<UInt8>, start: Int64): Option<BytesCaptures>` | 从指定字节起点搜索，返回第一次匹配的捕获组。 | 有样例验证 |
| [capturesAll](../port/src/bytes.cj#L365)（方法） | `public func capturesAll(haystack: Array<UInt8>): Array<BytesCaptures>` | 立即收集所有不重叠匹配的捕获组，返回数组。 | 不单列于170条对应表 |
| [capturesReadAt](../port/src/bytes.cj#L384)（方法） | `public func capturesReadAt(locations: CaptureLocations, haystack: Array<UInt8>, start: Int64): Option<BytesMatch>` | 从指定字节起点搜索并覆盖位置容器；失败或未参与的组不可读，不保留上次结果。 | 有明确差异；有样例验证：上游 doc(hidden) 的历史别名；仓颉使用对应的新名称。 |
| [replace](../port/src/bytes.cj#L408)（方法） | `public func replace(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | 用模板替换第一次匹配，返回新输入；模板可引用捕获组。 | 有样例验证 |
| [replaceAll](../port/src/bytes.cj#L411)（方法） | `public func replaceAll(haystack: Array<UInt8>, replacement: Array<UInt8>): Array<UInt8>` | 用模板替换全部不重叠匹配。 | 有样例验证 |
| [replaceN](../port/src/bytes.cj#L414)（方法） | `public func replaceN(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | 最多替换limit次；0表示不限，负数抛异常。 | 有样例验证 |
| [replaceLiteral](../port/src/bytes.cj#L427)（方法） | `public func replaceLiteral(haystack: Array<UInt8>, limit: Int64, replacement: Array<UInt8>): Array<UInt8>` | 最多替换limit次，将替换内容作为字面量，不展开$；0不限，负数抛异常。 | 不单列于170条对应表 |
| [replaceWith](../port/src/bytes.cj#L430)（方法） | `public func replaceWith(haystack: Array<UInt8>, limit: Int64, replacer: (BytesCaptures) -> Array<UInt8>): Array<UInt8>` | 每次匹配调用回调产生替换内容；0不限，负数抛异常。 | 不单列于170条对应表 |
| [split](../port/src/bytes.cj#L433)（方法） | `public func split(haystack: Array<UInt8>): Array<Array<UInt8>>` | 按匹配分割，立即返回片段数组，保留首尾空段。 | 不单列于170条对应表 |
| [splitN](../port/src/bytes.cj#L436)（方法） | `public func splitN(haystack: Array<UInt8>, limit: Int64): Array<Array<UInt8>>` | 最多分成limit段，最后一段保留剩余输入；0返回空数组，1返回原输入，负数抛异常。 | 不单列于170条对应表 |

### RegexSet

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/regex_set.cj#L104)（构造器） | `public init(patterns: Array<String>)` | 按顺序编译模式数组，任一模式失败则整体失败；空数组允许。 | 有明确差异；有样例验证：empty 用空数组构造；doc(hidden) read_matches_at 使用 matchesReadAt 名称。 |
| [len](../port/src/regex_set.cj#L153)（方法） | `public func len(): Int64` | 返回规则总数，不是命中数量。 | 有样例验证 |
| [isEmpty](../port/src/regex_set.cj#L156)（方法） | `public func isEmpty(): Bool` | 判断规则数量是否为0。 | 有样例验证 |
| [patterns](../port/src/regex_set.cj#L159)（方法） | `public func patterns(): Array<String>` | 返回按原顺序排列的模式数组副本。 | 有样例验证 |
| [isMatch](../port/src/regex_set.cj#L162)（方法） | `public func isMatch(text: String): Bool` | 判断是否至少一条规则命中，返回Bool。 | 有样例验证 |
| [isMatchAt](../port/src/regex_set.cj#L165)（方法） | `public func isMatchAt(text: String, start: Int64): Bool` | 判断是否至少一条规则命中，返回Bool。从指定字节起点搜索，保留原输入上下文。 | 有样例验证 |
| [matches](../port/src/regex_set.cj#L168)（方法） | `public func matches(text: String): SetMatches` | 返回所有命中规则的SetMatches；不同规则可重叠命中，不返回文本和位置。 | 有样例验证 |
| [matchesAt](../port/src/regex_set.cj#L171)（方法） | `public func matchesAt(text: String, start: Int64): SetMatches` | 从指定字节起点查询所有命中规则。 | 有样例验证 |
| [matchesReadAt](../port/src/regex_set.cj#L176)（方法） | `public func matchesReadAt(slots: Array<Bool>, text: String, start: Int64): Bool` | 从指定字节起点查询；仅将命中规则的槽写为true，其余槽保持原值，返回本次有无命中；命中编号超出槽长度时抛异常。 | 有明确差异；有样例验证：empty 用空数组构造；doc(hidden) read_matches_at 使用 matchesReadAt 名称。 |

### BytesRegexSet

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/bytes.cj#L788)（构造器） | `public init(patterns: Array<String>)` | 按顺序编译模式数组，任一模式失败则整体失败；空数组允许。 | 有明确差异；有样例验证：empty 用空数组构造；doc(hidden) read_matches_at 使用 matchesReadAt 名称。 |
| [len](../port/src/bytes.cj#L838)（方法） | `public func len(): Int64` | 返回规则总数，不是命中数量。 | 有样例验证 |
| [isEmpty](../port/src/bytes.cj#L841)（方法） | `public func isEmpty(): Bool` | 判断规则数量是否为0。 | 有样例验证 |
| [patterns](../port/src/bytes.cj#L844)（方法） | `public func patterns(): Array<String>` | 返回按原顺序排列的模式数组副本。 | 有样例验证 |
| [isMatch](../port/src/bytes.cj#L847)（方法） | `public func isMatch(haystack: Array<UInt8>): Bool` | 判断是否至少一条规则命中，返回Bool。 | 有样例验证 |
| [isMatchAt](../port/src/bytes.cj#L850)（方法） | `public func isMatchAt(haystack: Array<UInt8>, start: Int64): Bool` | 判断是否至少一条规则命中，返回Bool。从指定字节起点搜索，保留原输入上下文。 | 有样例验证 |
| [matches](../port/src/bytes.cj#L853)（方法） | `public func matches(haystack: Array<UInt8>): SetMatches` | 返回所有命中规则的SetMatches；不同规则可重叠命中，不返回文本和位置。 | 有样例验证 |
| [matchesAt](../port/src/bytes.cj#L856)（方法） | `public func matchesAt(haystack: Array<UInt8>, start: Int64): SetMatches` | 从指定字节起点查询所有命中规则。 | 有样例验证 |
| [matchesReadAt](../port/src/bytes.cj#L859)（方法） | `public func matchesReadAt(slots: Array<Bool>, haystack: Array<UInt8>, start: Int64): Bool` | 从指定字节起点查询；仅将命中规则的槽写为true，其余槽保持原值，返回本次有无命中；命中编号超出槽长度时抛异常。 | 有明确差异；有样例验证：empty 用空数组构造；doc(hidden) read_matches_at 使用 matchesReadAt 名称。 |

### RegexBuilder

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/builder.cj#L12)（构造器） | `public init(pattern: String)` | 保存模式并创建默认配置Builder；调用build时编译。 | 有样例验证 |
| [build](../port/src/builder.cj#L15)（方法） | `public func build(): Regex` | 按当前选项编译并返回目标Regex或Set；非法模式/超限抛RegexError，后续修改Builder不改变已构造对象。 | 有样例验证 |
| [caseInsensitive](../port/src/builder.cj#L18)（方法） | `public func caseInsensitive(yes: Bool): RegexBuilder` | 设置大小写不敏感（i）；Unicode开启时采用简单大小写折叠。 | 有样例验证 |
| [multiLine](../port/src/builder.cj#L22)（方法） | `public func multiLine(yes: Bool): RegexBuilder` | 设置多行锚点（m），使^和$可识别行首行尾。 | 有样例验证 |
| [dotMatchesNewLine](../port/src/builder.cj#L26)（方法） | `public func dotMatchesNewLine(yes: Bool): RegexBuilder` | 设置点号是否匹配换行（s）。 | 有样例验证 |
| [swapGreed](../port/src/builder.cj#L30)（方法） | `public func swapGreed(yes: Bool): RegexBuilder` | 交换重复量词的默认贪婪/非贪婪选择（U）。 | 有样例验证 |
| [ignoreWhitespace](../port/src/builder.cj#L34)（方法） | `public func ignoreWhitespace(yes: Bool): RegexBuilder` | 设置忽略模式中的空白与#注释（x），包括字符类内部。 | 有样例验证 |
| [crlf](../port/src/builder.cj#L38)（方法） | `public func crlf(yes: Bool): RegexBuilder` | 设置CRLF行边界模式（R），识别回车/换行及其组合。 | 有样例验证 |
| [unicode](../port/src/builder.cj#L42)（方法） | `public func unicode(yes: Bool): RegexBuilder` | 设置Unicode模式（u）；关闭后预定义类及词边界使用ASCII语义。字符串模式仍不能产生非法UTF-8匹配。 | 有样例验证 |
| [octal](../port/src/builder.cj#L46)（方法） | `public func octal(yes: Bool): RegexBuilder` | 允许或禁止八进制转义；默认禁止，不代表支持反向引用。 | 有样例验证 |
| [lineTerminator](../port/src/builder.cj#L50)（方法） | `public func lineTerminator(byte: Rune): RegexBuilder` | 设置单字节行终止符，允许0–255；非法值抛异常，字符串模式还受UTF-8安全限制。 | 有明确差异：参数为 Rune，再检查 0..255；上游参数为 u8。 |
| [nestLimit](../port/src/builder.cj#L57)（方法） | `public func nestLimit(limit: Int64): RegexBuilder` | 设置模式嵌套限制；负数抛异常。 | 有样例验证 |
| [sizeLimit](../port/src/builder.cj#L64)（方法） | `public func sizeLimit(limit: Int64): RegexBuilder` | 设置编译构造预算；负数抛异常。已有阈值样例，但不保证Rust所有启发式接受边界相同。 | 有明确差异：模拟上游 Thompson 构造预算并通过部分阈值对照；不保证所有启发式/限额接受边界相等。 |
| [dfaSizeLimit](../port/src/builder.cj#L71)（方法） | `public func dfaSizeLimit(limit: Int64): RegexBuilder` | 设置预算值；字符串搜索用于本地缓存预算，bytes与Set没有等价DFA缓存效果。不能解释为移植了Rust DFA引擎。 | 有明确差异：不是上游 DFA 缓存限额：字符串 Regex 使用步进缓存；bytes 忽略；Set 不提供同等 DFA。 |

### BytesRegexBuilder

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/builder.cj#L160)（构造器） | `public init(pattern: String)` | 保存模式并创建默认配置Builder；调用build时编译。 | 有样例验证 |
| [build](../port/src/builder.cj#L164)（方法） | `public func build(): BytesRegex` | 按当前选项编译并返回目标Regex或Set；非法模式/超限抛RegexError，后续修改Builder不改变已构造对象。 | 有样例验证 |
| [caseInsensitive](../port/src/builder.cj#L168)（方法） | `public func caseInsensitive(yes: Bool): BytesRegexBuilder` | 设置大小写不敏感（i）；Unicode开启时采用简单大小写折叠。 | 有样例验证 |
| [multiLine](../port/src/builder.cj#L172)（方法） | `public func multiLine(yes: Bool): BytesRegexBuilder` | 设置多行锚点（m），使^和$可识别行首行尾。 | 有样例验证 |
| [dotMatchesNewLine](../port/src/builder.cj#L176)（方法） | `public func dotMatchesNewLine(yes: Bool): BytesRegexBuilder` | 设置点号是否匹配换行（s）。 | 有样例验证 |
| [swapGreed](../port/src/builder.cj#L180)（方法） | `public func swapGreed(yes: Bool): BytesRegexBuilder` | 交换重复量词的默认贪婪/非贪婪选择（U）。 | 有样例验证 |
| [ignoreWhitespace](../port/src/builder.cj#L184)（方法） | `public func ignoreWhitespace(yes: Bool): BytesRegexBuilder` | 设置忽略模式中的空白与#注释（x），包括字符类内部。 | 有样例验证 |
| [crlf](../port/src/builder.cj#L188)（方法） | `public func crlf(yes: Bool): BytesRegexBuilder` | 设置CRLF行边界模式（R），识别回车/换行及其组合。 | 有样例验证 |
| [unicode](../port/src/builder.cj#L192)（方法） | `public func unicode(yes: Bool): BytesRegexBuilder` | 设置Unicode模式（u）；关闭后预定义类及词边界使用ASCII语义。字符串模式仍不能产生非法UTF-8匹配。 | 有样例验证 |
| [octal](../port/src/builder.cj#L196)（方法） | `public func octal(yes: Bool): BytesRegexBuilder` | 允许或禁止八进制转义；默认禁止，不代表支持反向引用。 | 有样例验证 |
| [lineTerminator](../port/src/builder.cj#L200)（方法） | `public func lineTerminator(byte: Rune): BytesRegexBuilder` | 设置单字节行终止符，允许0–255；非法值抛异常，字符串模式还受UTF-8安全限制。 | 有明确差异：参数为 Rune，再检查 0..255；上游参数为 u8。 |
| [nestLimit](../port/src/builder.cj#L207)（方法） | `public func nestLimit(limit: Int64): BytesRegexBuilder` | 设置模式嵌套限制；负数抛异常。 | 有样例验证 |
| [sizeLimit](../port/src/builder.cj#L214)（方法） | `public func sizeLimit(limit: Int64): BytesRegexBuilder` | 设置编译构造预算；负数抛异常。已有阈值样例，但不保证Rust所有启发式接受边界相同。 | 有明确差异：模拟上游 Thompson 构造预算并通过部分阈值对照；不保证所有启发式/限额接受边界相等。 |
| [dfaSizeLimit](../port/src/builder.cj#L221)（方法） | `public func dfaSizeLimit(limit: Int64): BytesRegexBuilder` | 设置预算值；字符串搜索用于本地缓存预算，bytes与Set没有等价DFA缓存效果。不能解释为移植了Rust DFA引擎。 | 有明确差异：不是上游 DFA 缓存限额：字符串 Regex 使用步进缓存；bytes 忽略；Set 不提供同等 DFA。 |

### RegexSetBuilder

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/builder.cj#L83)（构造器） | `public init()` | 创建空规则集合Builder，再通过pattern追加模式。 | 有样例验证 |
| [init](../port/src/builder.cj#L84)（构造器） | `public init(patterns: Array<String>)` | 复制规则数组创建Builder，调用build时才编译；后续修改原数组不影响已保存的规则。 | 有样例验证 |
| [pattern](../port/src/builder.cj#L87)（方法） | `public func pattern(value: String): RegexSetBuilder` | 向Set Builder追加一条模式，保持编号顺序，返回当前Builder供链式调用。 | 不单列于170条对应表 |
| [build](../port/src/builder.cj#L91)（方法） | `public func build(): RegexSet` | 按当前选项编译并返回目标Regex或Set；非法模式/超限抛RegexError，后续修改Builder不改变已构造对象。 | 有样例验证 |
| [caseInsensitive](../port/src/builder.cj#L94)（方法） | `public func caseInsensitive(yes: Bool): RegexSetBuilder` | 设置大小写不敏感（i）；Unicode开启时采用简单大小写折叠。 | 有样例验证 |
| [multiLine](../port/src/builder.cj#L98)（方法） | `public func multiLine(yes: Bool): RegexSetBuilder` | 设置多行锚点（m），使^和$可识别行首行尾。 | 有样例验证 |
| [dotMatchesNewLine](../port/src/builder.cj#L102)（方法） | `public func dotMatchesNewLine(yes: Bool): RegexSetBuilder` | 设置点号是否匹配换行（s）。 | 有样例验证 |
| [swapGreed](../port/src/builder.cj#L106)（方法） | `public func swapGreed(yes: Bool): RegexSetBuilder` | 交换重复量词的默认贪婪/非贪婪选择（U）。 | 有样例验证 |
| [ignoreWhitespace](../port/src/builder.cj#L110)（方法） | `public func ignoreWhitespace(yes: Bool): RegexSetBuilder` | 设置忽略模式中的空白与#注释（x），包括字符类内部。 | 有样例验证 |
| [crlf](../port/src/builder.cj#L114)（方法） | `public func crlf(yes: Bool): RegexSetBuilder` | 设置CRLF行边界模式（R），识别回车/换行及其组合。 | 有样例验证 |
| [unicode](../port/src/builder.cj#L118)（方法） | `public func unicode(yes: Bool): RegexSetBuilder` | 设置Unicode模式（u）；关闭后预定义类及词边界使用ASCII语义。字符串模式仍不能产生非法UTF-8匹配。 | 有样例验证 |
| [octal](../port/src/builder.cj#L122)（方法） | `public func octal(yes: Bool): RegexSetBuilder` | 允许或禁止八进制转义；默认禁止，不代表支持反向引用。 | 有样例验证 |
| [lineTerminator](../port/src/builder.cj#L126)（方法） | `public func lineTerminator(byte: Rune): RegexSetBuilder` | 设置单字节行终止符，允许0–255；非法值抛异常，字符串模式还受UTF-8安全限制。 | 有明确差异：参数为 Rune，再检查 0..255；上游参数为 u8。 |
| [nestLimit](../port/src/builder.cj#L133)（方法） | `public func nestLimit(limit: Int64): RegexSetBuilder` | 设置模式嵌套限制；负数抛异常。 | 有样例验证 |
| [sizeLimit](../port/src/builder.cj#L140)（方法） | `public func sizeLimit(limit: Int64): RegexSetBuilder` | 设置编译构造预算；负数抛异常。已有阈值样例，但不保证Rust所有启发式接受边界相同。 | 有明确差异：模拟上游 Thompson 构造预算并通过部分阈值对照；不保证所有启发式/限额接受边界相等。 |
| [dfaSizeLimit](../port/src/builder.cj#L147)（方法） | `public func dfaSizeLimit(limit: Int64): RegexSetBuilder` | 设置预算值；字符串搜索用于本地缓存预算，bytes与Set没有等价DFA缓存效果。不能解释为移植了Rust DFA引擎。 | 有明确差异：不是上游 DFA 缓存限额：字符串 Regex 使用步进缓存；bytes 忽略；Set 不提供同等 DFA。 |

### BytesRegexSetBuilder

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/builder.cj#L233)（构造器） | `public init()` | 创建空规则集合Builder，再通过pattern追加模式。 | 有样例验证 |
| [init](../port/src/builder.cj#L236)（构造器） | `public init(patterns: Array<String>)` | 复制规则数组创建Builder，调用build时才编译；后续修改原数组不影响已保存的规则。 | 有样例验证 |
| [pattern](../port/src/builder.cj#L240)（方法） | `public func pattern(value: String): BytesRegexSetBuilder` | 向Set Builder追加一条模式，保持编号顺序，返回当前Builder供链式调用。 | 不单列于170条对应表 |
| [build](../port/src/builder.cj#L244)（方法） | `public func build(): BytesRegexSet` | 按当前选项编译并返回目标Regex或Set；非法模式/超限抛RegexError，后续修改Builder不改变已构造对象。 | 有样例验证 |
| [caseInsensitive](../port/src/builder.cj#L248)（方法） | `public func caseInsensitive(yes: Bool): BytesRegexSetBuilder` | 设置大小写不敏感（i）；Unicode开启时采用简单大小写折叠。 | 有样例验证 |
| [multiLine](../port/src/builder.cj#L252)（方法） | `public func multiLine(yes: Bool): BytesRegexSetBuilder` | 设置多行锚点（m），使^和$可识别行首行尾。 | 有样例验证 |
| [dotMatchesNewLine](../port/src/builder.cj#L256)（方法） | `public func dotMatchesNewLine(yes: Bool): BytesRegexSetBuilder` | 设置点号是否匹配换行（s）。 | 有样例验证 |
| [swapGreed](../port/src/builder.cj#L260)（方法） | `public func swapGreed(yes: Bool): BytesRegexSetBuilder` | 交换重复量词的默认贪婪/非贪婪选择（U）。 | 有样例验证 |
| [ignoreWhitespace](../port/src/builder.cj#L264)（方法） | `public func ignoreWhitespace(yes: Bool): BytesRegexSetBuilder` | 设置忽略模式中的空白与#注释（x），包括字符类内部。 | 有样例验证 |
| [crlf](../port/src/builder.cj#L268)（方法） | `public func crlf(yes: Bool): BytesRegexSetBuilder` | 设置CRLF行边界模式（R），识别回车/换行及其组合。 | 有样例验证 |
| [unicode](../port/src/builder.cj#L272)（方法） | `public func unicode(yes: Bool): BytesRegexSetBuilder` | 设置Unicode模式（u）；关闭后预定义类及词边界使用ASCII语义。字符串模式仍不能产生非法UTF-8匹配。 | 有样例验证 |
| [octal](../port/src/builder.cj#L276)（方法） | `public func octal(yes: Bool): BytesRegexSetBuilder` | 允许或禁止八进制转义；默认禁止，不代表支持反向引用。 | 有样例验证 |
| [lineTerminator](../port/src/builder.cj#L280)（方法） | `public func lineTerminator(byte: Rune): BytesRegexSetBuilder` | 设置单字节行终止符，允许0–255；非法值抛异常，字符串模式还受UTF-8安全限制。 | 有明确差异：参数为 Rune，再检查 0..255；上游参数为 u8。 |
| [nestLimit](../port/src/builder.cj#L287)（方法） | `public func nestLimit(limit: Int64): BytesRegexSetBuilder` | 设置模式嵌套限制；负数抛异常。 | 有样例验证 |
| [sizeLimit](../port/src/builder.cj#L294)（方法） | `public func sizeLimit(limit: Int64): BytesRegexSetBuilder` | 设置编译构造预算；负数抛异常。已有阈值样例，但不保证Rust所有启发式接受边界相同。 | 有明确差异：模拟上游 Thompson 构造预算并通过部分阈值对照；不保证所有启发式/限额接受边界相等。 |
| [dfaSizeLimit](../port/src/builder.cj#L301)（方法） | `public func dfaSizeLimit(limit: Int64): BytesRegexSetBuilder` | 设置预算值；字符串搜索用于本地缓存预算，bytes与Set没有等价DFA缓存效果。不能解释为移植了Rust DFA引擎。 | 有明确差异：不是上游 DFA 缓存限额：字符串 Regex 使用步进缓存；bytes 忽略；Set 不提供同等 DFA。 |

### RegexMatch

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [start](../port/src/nfa.cj#L239)（字段） | `public let start: Int64` | 原输入中的起始字节偏移（包含）。 | 有明确差异：使用公开字段读取；range 用 start/end 构造。bytes 为可变数组，不是 Rust 只读借用切片。 |
| [end](../port/src/nfa.cj#L240)（字段） | `public let end: Int64` | 原输入中的结束字节偏移（不包含）。 | 有明确差异：使用公开字段读取；range 用 start/end 构造。bytes 为可变数组，不是 Rust 只读借用切片。 |
| [text](../port/src/nfa.cj#L241)（字段） | `public let text: String` | 匹配到的原文字符串。 | 不单列于170条对应表 |
| [isEmpty](../port/src/nfa.cj#L247)（方法） | `public func isEmpty(): Bool` | 判断匹配长度是否为0。 | 有样例验证 |
| [len](../port/src/nfa.cj#L250)（方法） | `public func len(): Int64` | 返回匹配字节长度end-start。 | 有样例验证 |
| [asStr](../port/src/nfa.cj#L253)（方法） | `public func asStr(): String` | 返回匹配到的原文字符串。 | 有样例验证 |

### BytesMatch

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [start](../port/src/bytes.cj#L8)（字段） | `public let start: Int64` | 原输入中的起始字节偏移（包含）。 | 有明确差异：使用公开字段读取；range 用 start/end 构造。bytes 为可变数组，不是 Rust 只读借用切片。 |
| [end](../port/src/bytes.cj#L9)（字段） | `public let end: Int64` | 原输入中的结束字节偏移（不包含）。 | 有明确差异：使用公开字段读取；range 用 start/end 构造。bytes 为可变数组，不是 Rust 只读借用切片。 |
| [bytes](../port/src/bytes.cj#L10)（字段） | `public let bytes: Array<UInt8>` | 匹配到的原始字节数组。 | 有明确差异：使用公开字段读取；range 用 start/end 构造。bytes 为可变数组，不是 Rust 只读借用切片。 |
| [init](../port/src/bytes.cj#L11)（构造器） | `public init(start: Int64, end: Int64, bytes: Array<UInt8>)` | 用提供的起点、终点和字节数组构造匹配结果对象；不是执行搜索。 | 不单列于170条对应表 |
| [isEmpty](../port/src/bytes.cj#L16)（方法） | `public func isEmpty(): Bool` | 判断匹配长度是否为0。 | 有样例验证 |
| [len](../port/src/bytes.cj#L19)（方法） | `public func len(): Int64` | 返回匹配字节长度end-start。 | 有样例验证 |

### Captures

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [size](../port/src/captures.cj#L45)（字段） | `public let size: Int64` | 捕获槽位数，包括组0。 | 有明确差异：extract 用运行时数量并返回含组0的数组；expand 返回新结果而非追加缓冲；len 用 size 字段。 |
| [getMatch](../port/src/captures.cj#L52)（方法） | `public func getMatch(): RegexMatch` | 返回完整匹配（组0）。 | 有样例验证 |
| [extract](../port/src/captures.cj#L60)（方法） | `public func extract(count: Int64): Array<String>` | 提取完整匹配及本次参与的分组内容；count必须等于固定参与组数减1，不固定或数量不符时抛异常。 | 有明确差异：extract 用运行时数量并返回含组0的数组；expand 返回新结果而非追加缓冲；len 用 size 字段。 |
| [iter](../port/src/captures.cj#L86)（方法） | `public func iter(): GroupIter` | 返回逐组迭代器；通过done区分结束，通过value=None表示组未参与。 | 有样例验证 |
| [get](../port/src/captures.cj#L89)（方法） | `public func get(index: Int64): Option<RegexMatch>` | 按组号读取匹配；越界、负数或未参与返回None。 | 有样例验证 |
| [name](../port/src/captures.cj#L95)（方法） | `public func name(value: String): Option<RegexMatch>` | 按精确名称读取捕获组；不存在或未参与返回None。 | 有样例验证 |
| [expand](../port/src/captures.cj#L107)（方法） | `public func expand(template: String): String` | 展开捕获模板并返回新内容；支持$0、$1、${name}和$$，缺失组展开为空。 | 不单列于170条对应表 |
| [expandInto](../port/src/captures.cj#L112)（方法） | `public func expandInto(template: String, out: StringBuilder): Unit` | 将捕获模板展开内容追加到调用者的现有缓冲区，保留原内容；字符串写入StringBuilder，bytes写入ArrayList<UInt8>。 | 有样例验证 |

### BytesCaptures

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [size](../port/src/bytes.cj#L595)（字段） | `public let size: Int64` | 捕获槽位数，包括组0。 | 有明确差异：extract 用运行时数量并返回含组0的数组；expand 返回新结果而非追加缓冲；len 用 size 字段。 |
| [getMatch](../port/src/bytes.cj#L602)（方法） | `public func getMatch(): BytesMatch` | 返回完整匹配（组0）。 | 有样例验证 |
| [get](../port/src/bytes.cj#L608)（方法） | `public func get(index: Int64): Option<BytesMatch>` | 按组号读取匹配；越界、负数或未参与返回None。 | 有样例验证 |
| [iter](../port/src/bytes.cj#L614)（方法） | `public func iter(): BytesGroupIter` | 返回逐组迭代器；通过done区分结束，通过value=None表示组未参与。 | 有样例验证 |
| [extract](../port/src/bytes.cj#L617)（方法） | `public func extract(count: Int64): Array<Array<UInt8>>` | 提取完整匹配及本次参与的分组内容；count必须等于固定参与组数减1，不固定或数量不符时抛异常。 | 有样例验证 |
| [name](../port/src/bytes.cj#L643)（方法） | `public func name(value: String): Option<BytesMatch>` | 按精确名称读取捕获组；不存在或未参与返回None。 | 有样例验证 |
| [expand](../port/src/bytes.cj#L655)（方法） | `public func expand(template: Array<UInt8>): Array<UInt8>` | 展开捕获模板并返回新内容；支持$0、$1、${name}和$$，缺失组展开为空。 | 不单列于170条对应表 |
| [expandInto](../port/src/bytes.cj#L660)（方法） | `public func expandInto(template: Array<UInt8>, out: ArrayList<UInt8>): Unit` | 将捕获模板展开内容追加到调用者的现有缓冲区，保留原内容；字符串写入StringBuilder，bytes写入ArrayList<UInt8>。 | 有样例验证 |

### CaptureSpan

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [start](../port/src/captures.cj#L8)（字段） | `public let start: Int64` | 原输入中的起始字节偏移（包含）。 | 不单列于170条对应表 |
| [end](../port/src/captures.cj#L9)（字段） | `public let end: Int64` | 原输入中的结束字节偏移（不包含）。 | 不单列于170条对应表 |

### CaptureLocations

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [size](../port/src/captures.cj#L17)（字段） | `public let size: Int64` | 捕获槽位数，包括组0。 | 有明确差异：len 对应 size 字段；doc(hidden) pos 别名对应 get。 |
| [get](../port/src/captures.cj#L25)（方法） | `public func get(index: Int64): Option<CaptureSpan>` | 按组号读取位置区间；越界、负数、未参与或上次搜索失败均返回None。 | 有明确差异；有样例验证：len 对应 size 字段；doc(hidden) pos 别名对应 get。 |

### SetMatches

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [len](../port/src/regex_set.cj#L12)（方法） | `public func len(): Int64` | 返回规则总数，不是命中数量。 | 有样例验证 |
| [matched](../port/src/regex_set.cj#L15)（方法） | `public func matched(index: Int64): Bool` | 查询指定规则编号是否命中；负数或越界抛异常。 | 有样例验证 |
| [matchedAny](../port/src/regex_set.cj#L21)（方法） | `public func matchedAny(): Bool` | 查询是否至少一条规则命中；空集合为false。 | 有样例验证 |
| [matchedAll](../port/src/regex_set.cj#L29)（方法） | `public func matchedAll(): Bool` | 查询是否全部规则命中；空集合为true。 | 有样例验证 |
| [indices](../port/src/regex_set.cj#L37)（方法） | `public func indices(): Array<Int64>` | 返回升序命中编号数组，每个编号只出现一次。 | 不单列于170条对应表 |
| [iter](../port/src/regex_set.cj#L47)（方法） | `public func iter(): SetMatchesIter` | 返回双向编号游标，按需扫描命中快照，不预先收集编号数组。 | 有样例验证 |

### SetMatchesIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [next](../port/src/regex_set.cj#L65)（方法） | `public func next(): Option<Int64>` | 从前往后返回下一个命中编号，耗尽返回None。 | 不单列于170条对应表 |
| [nextBack](../port/src/regex_set.cj#L74)（方法） | `public func nextBack(): Option<Int64>` | 从后往前返回下一个命中编号，可与next交错，不重复取编号。 | 不单列于170条对应表 |
| [sizeHint](../port/src/regex_set.cj#L84)（方法） | `public func sizeHint(): (Int64, Option<Int64>)` | 返回尚未扫描的规则槽位数作为两端提示；与固定Rust相同，不是剩余命中数，不作为命中数下界使用。 | 不单列于170条对应表 |
| [clone](../port/src/regex_set.cj#L89)（方法） | `public func clone(): SetMatchesIter` | 复制当前前后游标；两份游标独立推进，共享私有不可变命中快照。 | 不单列于170条对应表 |

### MatchIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/nfa.cj#L936)（构造器） | `public init(pull: () -> Option<RegexMatch>)` | 用调用者提供的pull回调构造迭代器；通常直接使用Regex返回的迭代器。自定义回调不自动获得内置迭代器的结束契约。 | 不单列于170条对应表 |
| [next](../port/src/nfa.cj#L939)（方法） | `public func next(): Option<RegexMatch>` | 调用pull返回下一项Option；内置迭代器耗尽后持续返回None。 | 不单列于170条对应表 |

### CaptureIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/nfa.cj#L946)（构造器） | `public init(pull: () -> Option<Captures>)` | 用调用者提供的pull回调构造迭代器；通常直接使用Regex返回的迭代器。自定义回调不自动获得内置迭代器的结束契约。 | 不单列于170条对应表 |
| [next](../port/src/nfa.cj#L949)（方法） | `public func next(): Option<Captures>` | 调用pull返回下一项Option；内置迭代器耗尽后持续返回None。 | 不单列于170条对应表 |

### SplitIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/nfa.cj#L956)（构造器） | `public init(pull: () -> Option<String>)` | 用调用者提供的pull回调构造迭代器；通常直接使用Regex返回的迭代器。自定义回调不自动获得内置迭代器的结束契约。 | 不单列于170条对应表 |
| [next](../port/src/nfa.cj#L959)（方法） | `public func next(): Option<String>` | 调用pull返回下一项Option；内置迭代器耗尽后持续返回None。 | 不单列于170条对应表 |

### BytesMatchIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/bytes.cj#L947)（构造器） | `public init(pull: () -> Option<BytesMatch>)` | 用调用者提供的pull回调构造迭代器；通常直接使用Regex返回的迭代器。自定义回调不自动获得内置迭代器的结束契约。 | 不单列于170条对应表 |
| [next](../port/src/bytes.cj#L950)（方法） | `public func next(): Option<BytesMatch>` | 调用pull返回下一项Option；内置迭代器耗尽后持续返回None。 | 不单列于170条对应表 |

### BytesCaptureIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/bytes.cj#L957)（构造器） | `public init(pull: () -> Option<BytesCaptures>)` | 用调用者提供的pull回调构造迭代器；通常直接使用Regex返回的迭代器。自定义回调不自动获得内置迭代器的结束契约。 | 不单列于170条对应表 |
| [next](../port/src/bytes.cj#L960)（方法） | `public func next(): Option<BytesCaptures>` | 调用pull返回下一项Option；内置迭代器耗尽后持续返回None。 | 不单列于170条对应表 |

### BytesSplitIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/bytes.cj#L967)（构造器） | `public init(pull: () -> Option<Array<UInt8>>)` | 用调用者提供的pull回调构造迭代器；通常直接使用Regex返回的迭代器。自定义回调不自动获得内置迭代器的结束契约。 | 不单列于170条对应表 |
| [next](../port/src/bytes.cj#L970)（方法） | `public func next(): Option<Array<UInt8>>` | 调用pull返回下一项Option；内置迭代器耗尽后持续返回None。 | 不单列于170条对应表 |

### GroupIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [len](../port/src/captures.cj#L214)（方法） | `public func len(): Int64` | 剩余捕获槽位数量，包括未参与匹配的组；耗尽后为0。 | 不单列于170条对应表 |
| [sizeHint](../port/src/captures.cj#L215)（方法） | `public func sizeHint(): (Int64, Option<Int64>)` | 返回剩余槽位数作为精确上下界，不移动游标。 | 不单列于170条对应表 |
| [clone](../port/src/captures.cj#L218)（方法） | `public func clone(): GroupIter` | 复制当前游标位置，之后两份游标独立推进；共享捕获结果，不承诺字节数组深复制。 | 不单列于170条对应表 |
| [next](../port/src/captures.cj#L223)（方法） | `public func next(): GroupItem` | 返回下一个组的Item；done=true表示结束，done=false且value=None表示该组未参与。 | 不单列于170条对应表 |

### BytesGroupIter

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [len](../port/src/bytes.cj#L757)（方法） | `public func len(): Int64` | 剩余捕获槽位数量，包括未参与匹配的组；耗尽后为0。 | 不单列于170条对应表 |
| [sizeHint](../port/src/bytes.cj#L758)（方法） | `public func sizeHint(): (Int64, Option<Int64>)` | 返回剩余槽位数作为精确上下界，不移动游标。 | 不单列于170条对应表 |
| [clone](../port/src/bytes.cj#L761)（方法） | `public func clone(): BytesGroupIter` | 复制当前游标位置，之后两份游标独立推进；共享捕获结果，不承诺字节数组深复制。 | 不单列于170条对应表 |
| [next](../port/src/bytes.cj#L766)（方法） | `public func next(): BytesGroupItem` | 返回下一个组的Item；done=true表示结束，done=false且value=None表示该组未参与。 | 不单列于170条对应表 |

### GroupItem

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [done](../port/src/captures.cj#L199)（字段） | `public let done: Bool` | 是否已结束组迭代；false时仍需检查value是否为None。 | 不单列于170条对应表 |
| [value](../port/src/captures.cj#L200)（字段） | `public let value: Option<RegexMatch>` | 当前捕获组；None表示该组未参与，不能单凭None判断迭代结束。 | 不单列于170条对应表 |

### BytesGroupItem

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [done](../port/src/bytes.cj#L742)（字段） | `public let done: Bool` | 是否已结束组迭代；false时仍需检查value是否为None。 | 不单列于170条对应表 |
| [value](../port/src/bytes.cj#L743)（字段） | `public let value: Option<BytesMatch>` | 当前捕获组；None表示该组未参与，不能单凭None判断迭代结束。 | 不单列于170条对应表 |

### RegexError

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [errorKind](../port/src/error.cj#L13)（字段） | `public let errorKind: RegexErrorKind` | 错误分类：Syntax或CompiledTooBig。 | 不单列于170条对应表 |
| [limit](../port/src/error.cj#L14)（字段） | `public let limit: Int64` | 错误携带的编译限额；主要用于CompiledTooBig。 | 不单列于170条对应表 |
| [text](../port/src/error.cj#L15)（字段） | `public let text: String` | 错误显示文本。 | 不单列于170条对应表 |
| [init](../port/src/error.cj#L16)（构造器） | `public init(errorKind: RegexErrorKind, message: String, limit: Int64)` | 用类别、消息和限额构造异常对象。 | 不单列于170条对应表 |
| [toString](../port/src/error.cj#L22)（方法） | `public override func toString(): String` | 返回异常显示文本；已测语法错误/超限样例对齐固定Rust，非所有错误格式的证明。 | 不单列于170条对应表 |

### Hir

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [kind](../port/src/syntax_hir.cj#L78)（方法） | `public func kind(): HirKind` | 读取结构节点种类及载荷；可修改数组返回副本。 | 不单列于170条对应表 |
| [properties](../port/src/syntax_hir.cj#L85)（方法） | `public func properties(): HirProperties` | 读取当前支持的最短/最长字节长度属性。 | 不单列于170条对应表 |
| [subs](../port/src/syntax_hir.cj#L86)（方法） | `public func subs(): Array<Hir>` | 读取直接子节点数组副本。 | 不单列于170条对应表 |
| [empty](../port/src/syntax_hir.cj#L94)（方法） | `public static func empty(): Hir` | 构造可以匹配空文本的空表达式。 | 不单列于170条对应表 |
| [fail](../port/src/syntax_hir.cj#L97)（方法） | `public static func fail(): Hir` | 构造不能匹配任何文本的空字节类节点。 | 不单列于170条对应表 |
| [literal](../port/src/syntax_hir.cj#L100)（方法） | `public static func literal(bytes: Array<UInt8>): Hir` | 复制字节数组构造字面量，空数组归一化为空表达式。 | 不单列于170条对应表 |
| [unicodeClass](../port/src/syntax_hir.cj#L105)（方法） | `public static func unicodeClass(ranges: Array<HirRange>): Hir` | 校验并合并Unicode范围；单个字符转为字面量，空类转为失败节点。 | 不单列于170条对应表 |
| [byteClass](../port/src/syntax_hir.cj#L108)（方法） | `public static func byteClass(ranges: Array<HirRange>): Hir` | 校验并合并0..255字节范围；单个字节转为字面量，空类转为失败节点。 | 不单列于170条对应表 |
| [capture](../port/src/syntax_hir.cj#L143)（方法） | `public static func capture(index: UInt32, name: Option<String>, sub: Hir): Hir` | 构造捕获节点，保存编号、可选名字和子节点。 | 不单列于170条对应表 |
| [repetition](../port/src/syntax_hir.cj#L146)（方法） | `public static func repetition(min: UInt32, max: Option<UInt32>, greedy: Bool, sub: Hir): Hir` | 构造重复并按原仓库简化零次、一次和零宽子节点；计算长度属性。 | 不单列于170条对应表 |
| [concat](../port/src/syntax_hir.cj#L165)（方法） | `public static func concat(children: Array<Hir>): Hir` | 展平连接、去空节点、合并相邻字面量；零/单子节点会简化。 | 不单列于170条对应表 |
| [parse](../port/src/syntax_hir.cj#L198)（方法） | `public static func parse(pattern: String): Hir` | 解析当前HIR切片，默认UTF-8安全；双参数形式可放开UTF-8限制。选择、点号和断言暂抛HirUnsupportedError；不是完整regex-syntax解析API。 | 不单列于170条对应表 |
| [parse](../port/src/syntax_hir.cj#L199)（方法） | `public static func parse(pattern: String, utf8: Bool): Hir` | 解析当前HIR切片，默认UTF-8安全；双参数形式可放开UTF-8限制。选择、点号和断言暂抛HirUnsupportedError；不是完整regex-syntax解析API。 | 不单列于170条对应表 |

### HirProperties

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [minimumLen](../port/src/syntax_hir.cj#L66)（方法） | `public func minimumLen(): Option<UInt64>` | 返回原仓库报告的最短匹配字节数；None不能单独证明无匹配，溢出饱和为UInt64最大值。 | 不单列于170条对应表 |
| [maximumLen](../port/src/syntax_hir.cj#L67)（方法） | `public func maximumLen(): Option<UInt64>` | 返回最长匹配字节数；无匹配、无界或溢出均返回None。 | 不单列于170条对应表 |

### HirRange

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [start](../port/src/syntax_hir.cj#L13)（字段） | `public let start: Int64` | 范围起点，包含；HirRange构造时按大小排列端点。 | 不单列于170条对应表 |
| [end](../port/src/syntax_hir.cj#L14)（字段） | `public let end: Int64` | 范围终点，包含；范围是否合法在构造字符类时验证。 | 不单列于170条对应表 |
| [init](../port/src/syntax_hir.cj#L15)（构造器） | `public init(start: Int64, end: Int64)` | 保存闭区间两端，反向端点会交换；Unicode/字节合法性由字符类构造器检查。 | 不单列于170条对应表 |

### HirClass

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [isBytes](../port/src/syntax_hir.cj#L22)（字段） | `public let isBytes: Bool` | true表示字节字符类，false表示Unicode标量字符类。 | 不单列于170条对应表 |
| [ranges](../port/src/syntax_hir.cj#L28)（方法） | `public func ranges(): Array<HirRange>` | 返回规范化字符范围的数组副本，不允许借此修改节点。 | 不单列于170条对应表 |

### HirCapture

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [index](../port/src/syntax_hir.cj#L45)（字段） | `public let index: UInt32` | 捕获组编号。 | 不单列于170条对应表 |
| [name](../port/src/syntax_hir.cj#L46)（字段） | `public let name: Option<String>` | 可选捕获组名称。 | 不单列于170条对应表 |
| [sub](../port/src/syntax_hir.cj#L47)（字段） | `public let sub: Hir` | 不可变子节点引用。 | 不单列于170条对应表 |

### HirRepetition

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [min](../port/src/syntax_hir.cj#L32)（字段） | `public let min: UInt32` | 最少重复次数。 | 不单列于170条对应表 |
| [max](../port/src/syntax_hir.cj#L33)（字段） | `public let max: Option<UInt32>` | 最多重复次数，None表示不设上限。 | 不单列于170条对应表 |
| [greedy](../port/src/syntax_hir.cj#L34)（字段） | `public let greedy: Bool` | 是否优先尝试更多次重复。 | 不单列于170条对应表 |
| [sub](../port/src/syntax_hir.cj#L35)（字段） | `public let sub: Hir` | 不可变子节点引用。 | 不单列于170条对应表 |

### HirUnsupportedError

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [init](../port/src/syntax_hir.cj#L9)（构造器） | `public init(message: String)` | 构造公开HIR切片未支持的结构错误。 | 不单列于170条对应表 |

### 顶层函数

| 名称与代码 | 声明（含输入输出类型） | 当前行为 | 原仓库审计状态 |
|---|---|---|---|
| [escape](../port/src/escape.cj#L13)（函数） | `public func escape(text: String): String` | 把普通字符串转义成正则字面量；不做JSON或shell转义。 | 不单列于170条对应表 |

## 如何用于答辩

建议表述：“当前仓颉库显式提供208个公开可调用入口，包含187个方法、20个构造器和1个转义函数，另有28个公开字段。我们对固定原仓库170条固有方法建立了映射与差异记录。”

不要表述为“已完全移植208个Rust接口”或“完成率208/170”。尤其dfaSizeLimit、早停终点、数组替代迭代器、历史别名与语言trait应结合审计差异说明。
