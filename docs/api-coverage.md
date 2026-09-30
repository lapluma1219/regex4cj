# 字符串层公共契约清单

这份清单对照固定上游 `72d650cb0a880a01ab6dc2137c0888e8f89740f7` 的**字符串** Regex API，不是 bytes 模块，也不是 regex-syntax / regex-automata 的全部公开类型。只统计 `pub fn` 行数不能当作覆盖率。下文每个条目都核对过模块归属：顶层 `src/lib.rs` 再导出的是 `regex::string`、`regexset::string` 和 `builders::string`。

上游源码在本机 `/Users/jalonyan/Desktop/regex4cj-local/upstream/regex`。编写时仓颉实现所在提交见 [progress-v0.3.0.md](progress-v0.3.0.md)。历史路线图仍是 [compatibility.md](compatibility.md)；本文件才是 v0.3.0 的接口归属。

## 状态词

| 状态 | 含义 |
|---|---|
| 已验证 | 当前实现与固定上游在已有差分或原生测试中一致 |
| 部分支持 | 能用，但契约、语法或调用形式还不完整 |
| 待实现 | v0.3.0 必做，还没有对应行为 |
| 本版排除 | 明确不放进 v0.3.0，不能事后说成遗漏 |
| 语言适配 | Rust 机制在仓颉里用另一种形式表达，语义边界写在本表 |

差异若存在，会标明是功能、接口形式、资源还是性能。

## 一个贯穿例子

模式 `(?i)k`，文本是三个看起来都像 k 的字符：普通 `k`、大写 `K`，以及开尔文符号 `K`（U+212A）。

- 输入仍是原来的字符。库不会先把整段文本改成小写。
- 三条都应命中。捕获或替换拿回的是原文，例如输入 `K` 时结果文本是 `K`，不是 `k`。
- `ß` 只和 `ẞ` 互配，不把两个字符的 `SS` 当成一个 `ß`。那是 Unicode 全量大小写折叠，不是本库跟随的简单折叠。
- `(?i)[^k]` 不能匹配 `K` 或 `K`。大小写扩展发生在取反之前；如果先取反再扩展，被排除的大写会漏回来。
- `(?i)[a-z--c]` 不能匹配 `C`。交集、差集的两边都要先按大小写扩展，再做运算。

可以自己看：

```sh
bash scripts/run.sh find '(?i)k' 'kKK'
bash scripts/run.sh find '(?i)ß' 'SS'
```

第一条应有三次匹配；第二条没有匹配行，并且正常退出。`(?x)`、`(?u)`、`(?R)` 仍会报错并以退出码 2 结束。

## 本版必做与明确排除

v0.3.0 必做，对应工作包 C–G：

- 内联和 Builder 的匹配语义：`i` / `x` / `R`，以及字符串接口允许的 `u` 与 ASCII 模式。`m` / `s` / `U` 的组合和作用域保持不变。
- 简单大小写折叠、Unicode 捕获名、方向性词边界、Age/Break 枚举查询，以及清单里点名的其余语法差异。
- `isMatchAt` / `findAt` / `capturesAt`，以及 RegexSet 的对应起点查询。起点是原文字节偏移，不能先截掉前缀。
- 按需推进的匹配、捕获、分割；捕获元数据；可复用捕获位置。
- `RegexBuilder` / `RegexSetBuilder`。匹配语义选项必须生效。资源选项写明单位差异。DFA 专属选项不能做成静默忽略的空函数。

本版排除，对应源码仍可定位：

- `src/regex/bytes.rs`、`src/regexset/bytes.rs`，以及 `builders.rs` 后半的 bytes builder。顶层 `pub mod bytes`。
- 前后查找、反向引用。固定上游会拒绝它们，不是待追赶缺口。
- regex-syntax / regex-automata 的 AST、HIR、DFA、lazy DFA、预过滤器公开类型。
- regex-lite、regex-capi。
- Rust 的 `Display` / `Debug` / `FromStr` / `TryFrom` / `Index` / `Iterator` / `FusedIterator` / `ExactSizeIterator` / `Default` / `IntoIterator` 等 trait 本体。需要的行为用仓颉方法或数组表达，不另造同名 trait。

## Regex

源码 `src/regex/string.rs`，类型从约第 150 行起。默认 `Regex::new` 等价于 Unicode 开、其余语法标志关。搜索起点默认 0。返回的范围相对整段输入，单位是 UTF-8 字节。未匹配是 `None` / 空迭代，不是错误。越界起点在上游会 panic；仓颉对应接口实现后应抛 Exception，并在测试里写明。

| 上游 | 位置 | 仓颉现状 | 状态 | 差异 |
|---|---|---|---|---|
| `new` | string.rs:229 | `Regex(pattern)` | 已验证 | 失败是 Exception，不是 `Result`。错误字符串不要求逐字相同 |
| `is_match` | :253 | `isMatch` | 部分支持 | 语义已对照。内部仍先找完整匹配，存在性短路属于后续优化，不改变结果 |
| `find` | :281 | `find` | 已验证 | 最左优先、字面量文本、字节区间 |
| `find_iter` | :313 | `findAll` 返回数组 | 部分支持 | 功能结果已对照。不是按需迭代，属于工作包 F |
| `captures` | :404 | `captures` | 已验证 | 组 0 为完整匹配；未参与组与空文本不同 |
| `captures_iter` | :469 | `capturesAll` | 部分支持 | 同 `find_iter`，结果已收集成数组 |
| `split` | :602 | `split` | 已验证 | 含首尾空段。返回数组 |
| `splitn` | :677 | `splitN` | 已验证 | `0` 返回空数组，`1` 返回整段输入。负数抛 Exception |
| `replace` / `replace_all` / `replacen` | :791 / :891 / :956 | `replace` / `replaceAll` / `replaceN` | 部分支持 | 模板替换已对照。`Replacer` 拆成模板、`replaceLiteral` 和 `replaceWith` 回调。见下文替换 |
| `shortest_match` / `shortest_match_at` | :1047 / :1082 | 无 | 待实现 | 工作包 E。不是 `find().end` 的别名。先记录固定上游探针，再写保证什么、允许什么引擎差异 |
| `is_match_at` | :1120 | 无 | 待实现 | 工作包 E。禁止用 `text[start..]` 代替 |
| `find_at` | :1154 | 无 | 待实现 | 落在多字节字符内部的字节偏移必须按固定上游实测，不能自行四舍五入或一律拒绝 |
| `captures_at` | :1193 | 无 | 待实现 | 返回范围仍相对完整输入 |
| `captures_read` / `captures_read_at` | :1243 / :1283 | 无 | 待实现 | 工作包 F。配合可复用位置，不能覆盖已经返回的 `Captures` |
| `as_str` | :1324 | 无 | 待实现 | 返回编译时的原始模式，不是转义后的形式 |
| `capture_names` | :1374 | `captureNames()` 返回数组 | 部分支持 | 组 0 为 `None`。名称目前只接受 ASCII。迭代器改为数组是语言适配 |
| `captures_len` | :1405 | `capturesLen()` | 已验证 | 含组 0 |
| `static_captures_len` | :1445 | 无 | 待实现 | 不等于 `capturesLen()`。分支里捕获数不固定时上游返回 `None` |
| `capture_locations` / `locations` | :1471 / :1481 | 无 | 待实现 | 工作区不能默认跨另一个 `Regex` 复用；容量不匹配和失败后是否保留旧内容，先按上游写测试 |

`Display`、`Debug`、`FromStr`、`TryFrom<&str>`、`TryFrom<String>` 归入语言适配：仓颉用构造函数和 `Exception`，不实现这些 trait。

## RegexMatch

上游类型名 `Match`，`src/regex/string.rs` 约第 1539 行。仓颉名为 `RegexMatch`，避免和语言里的匹配语法混淆。

| 上游 | 仓颉 | 状态 | 说明 |
|---|---|---|---|
| `start` / `end` | 字段 `start` / `end` | 已验证 | UTF-8 字节，半开区间 |
| `is_empty` | 无 | 待实现 | `start == end` |
| `len` | 无 | 待实现 | 字节长度 |
| `range` | 无 | 待实现 | 可用一对整数或现有字段表达，不引入 Rust `Range` |
| `as_str` | 字段 `text` | 已验证 | 原输入切片，不是折叠后的文本 |

零宽匹配会继续向后推进，不能停在同一个位置死循环，也不能推进到一个多字节字符的中间。这条在现有空匹配测试里已覆盖；惰性迭代实现后要再测一遍。

## Captures

`src/regex/string.rs` 约第 1691 行。

| 上游 | 仓颉 | 状态 | 说明 |
|---|---|---|---|
| `get` | `get` | 已验证 | 未参与、越界返回 `None`。Rust 的 `Index<usize>` 越界会 panic，仓颉不提供会 panic 的下标 |
| `get_match` | `get(0)` | 部分支持 | 有匹配时组 0 必存在。可另加只取完整匹配的方法，不能把缺失组换成空字符串冒充 |
| `name` | `name` | 部分支持 | ASCII 名称已验证。Unicode 名称属工作包 D |
| `extract` | 无 | 待实现 | 仅当捕获组数量在所有分支中固定，且调用方要的组数正好等于“总组数减 1”。不能把未参与组填成空串后声称等价 |
| `expand` | `expand` | 已验证 | `$0`、`$1`、`${name}`、`$$`。未参与组展开为空。上游写入调用方缓冲区，仓颉返回新字符串 |
| `iter` | 无 | 待实现 | 按组号给出 `Option<RegexMatch>`，组 0 在有匹配时不是 `None` |
| `len` | 字段 `size` | 已验证 | 含组 0 |
| `Index<&str>` | `name` | 语言适配 | 未知名字在上游索引时 panic；仓颉返回 `None` |

## CaptureLocations

`src/regex/string.rs` 约第 2142 行。整型位置，不持有文本。

| 上游 | 状态 | 要先写清的行为 |
|---|---|---|
| `get` / `pos` | 待实现 | 未参与组是 `None`，不是 `(0,0)` |
| `len` | 待实现 | 槽位数，含组 0 |

`captures_read` 失败时是否留下上一次的位置，以实现时对照固定上游的结果为准，不凭直觉清空或保留。已返回给调用方的 `Captures` 不能被下一次搜索改掉。完成前不宣称线程安全。

## 迭代器

这些类型都在 `src/regex/string.rs`。当前仓颉用数组一次性收集。v0.3.0 要增加真正的按需接口，并让旧的 `findAll` / `capturesAll` / `split` / `splitN` 走同一套推进规则。

| 上游类型 | 产生方式 | 状态 |
|---|---|---|
| `Matches` | `find_iter` | 待实现按需接口；数组结果已验证 |
| `CaptureMatches` | `captures_iter` | 同上 |
| `Split` / `SplitN` | `split` / `splitn` | 同上。`splitN` 的最后一段是剩余文本 |
| `CaptureNames` | `capture_names` | 数组已部分支持；名称字符集未完成 |
| `SubCaptureMatches` | `Captures::iter` | 待实现 |

按需接口的验收包括：只取第一项就停止、两个迭代器交错推进、保留旧匹配再推进后内容不变、空匹配不无限循环、非空匹配后的同位置空匹配跳过规则与上游一致。Rust 生命周期用仓颉对象持有输入副本来适配，文档要写明分配成本。

## 替换

`Replacer`、`ReplacerRef`、`NoExpand` 在 string.rs 约第 2501 行之后。

| 上游 | 仓颉 | 状态 | 适配 |
|---|---|---|---|
| `&str` / `String` 等，含 `$` 展开 | `replace` / `replaceAll` / `replaceN` | 已验证 | 返回新字符串，不写回调用方缓冲区 |
| `NoExpand` | `replaceLiteral` | 已验证 | 不展开 `$` |
| `FnMut(&Captures) -> 字符串` | `replaceWith` | 已验证 | 回调里可以再使用同一个 `Regex` |
| `Replacer` / `by_ref` | 无 trait | 语言适配 | 不移植 trait。多次使用回调由调用方自己保留闭包 |

`replaceN(..., 0, ...)` 表示不限次数，和 `splitN(..., 0)` 不同。

## 自由函数

| 上游 | 仓颉 | 状态 |
|---|---|---|
| `regex::escape`（lib.rs 约第 1378 行） | `escape` | 已验证，含原生 NUL |
| 无同名公开函数；元字符判断来自语法层 | `isMetaCharacter` | 已验证 | 仓颉额外提供，不是上游 `Regex` 方法 |

`__private` 模块只给宏使用，本版排除。

## RegexSet 与 SetMatches

`src/regexset/string.rs`。

| 上游 | 仓颉 | 状态 | 说明 |
|---|---|---|---|
| `RegexSet::new` | `RegexSet(patterns)` | 已验证 | 任一条失败则整个构造失败，错误带规则编号 |
| `empty` / `Default` | `RegexSet([])` | 已验证 | 不另设静态 `empty`。空集合 `matchedAny` 为 false，`matchedAll` 为 true |
| `is_match` | `isMatch` | 已验证 | 可以提早结束 |
| `is_match_at` | 无 | 待实现 | 工作包 E |
| `matches` | `matches` | 已验证 | 重叠规则都算命中 |
| `matches_at` | 无 | 待实现 | 工作包 E |
| `matches_read_at` / `read_matches_at` | 无 | 待实现 | 若做复用缓冲区，要检查长度、旧结果清理和失败后的内容 |
| `len` / `is_empty` | `len` / `isEmpty` | 已验证 | 原始规则数，不是命中数 |
| `patterns` | `patterns` | 已验证 | 返回副本。Rust 返回借用切片 |
| `SetMatches::matched` | `matched` | 已验证 | 负数或越界抛 Exception；Rust 越界 panic |
| `matched_any` / `matched_all` | `matchedAny` / `matchedAll` | 已验证 | |
| `SetMatches::len` | `len` | 已验证 | 仍是规则总数 |
| `iter` / `IntoIterator` | `indices()` | 部分支持 | 编号升序、每个编号一次。当前是数组，按需迭代属工作包 F |
| `SetMatchesIntoIter` / `SetMatchesIter` | 无 | 待实现 | 双端迭代不单独立项；升序数组或正向按需迭代即可覆盖观测结果 |

RegexSet 不返回位置、文本或捕获。需要这些信息时再对单条规则构造 `Regex`。

当前资源上限：最多 256 条规则、模式合计 65536 字节，并与单模式共享 16384 个 NFA 状态。这是实现限制，不是 Rust 默认字节上限的同单位复制。

## Builder

`src/builders.rs` 的 `string` 模块。`RegexBuilder` 从约第 212 行起，`RegexSetBuilder` 从约第 787 行起。同名方法在 bytes 模块再出现一次，那些不在本清单的实现范围内。

仓颉还没有公开 Builder。在各选项真实生效之前，不提供“能设置但被忽略”的构造器。`Regex(pattern)` 和 `RegexSet(patterns)` 保持现在的默认行为。

默认值来自 `Builder::default` 和 `regex_syntax::ast::parse::ParserBuilder`：Unicode 开，大小写、多行、点号匹配换行、CRLF、交换贪婪、忽略空白、八进制都关，行终止符为 `\n`（字节 0x0A），NFA 大小约 10 MiB，hybrid 缓存约 2 MiB，嵌套限制 250。

| 选项 | 类别 | 内联标志 | v0.3.0 要求 |
|---|---|---|---|
| `unicode` | 匹配语义 | `u` | 待实现。关闭后仍不是任意字节 API。字符串接口要拒绝可能匹配非法 UTF-8 的模式 |
| `case_insensitive` | 匹配语义 | `i` | 内联 `(?i)` / `(?-i)` 已验证简单折叠。Builder 开关和 `(?-u)` 下的 ASCII 折叠仍待实现 |
| `multi_line` | 匹配语义 | `m` | 内联已验证。Builder 待实现 |
| `dot_matches_new_line` | 匹配语义 | `s` | 内联已验证。Builder 待实现 |
| `swap_greed` | 匹配语义 | `U` | 内联已验证。Builder 待实现 |
| `crlf` | 匹配语义 | `R` | 待实现。不能把输入里的 CRLF 预先替换成 LF |
| `line_terminator` | 匹配语义 | 无 | 待实现。参数是一个字节，并且要满足字符串 UTF-8 安全约束，不能随意接受任意字符 |
| `ignore_whitespace` | 匹配语义 | `x` | 待实现。不能先删掉模式里的全部空白 |
| `octal` | 匹配语义 | 无 | 待实现。允许八进制转义不等于支持反向引用 |
| `size_limit` | 资源 | 无 | 待实现为诚实适配。仓颉按 NFA 状态和编译工作量限制，不能把“状态个数”说成同上游一样的字节数 |
| `dfa_size_limit` | 引擎专属 | 无 | 本版没有 DFA。不能提供一个成功但什么都不做的 setter。公开行为应是明确不支持 |
| `nest_limit` | 资源 | 无 | 待实现。当前固定 64 层，上游默认 250。两者都不是“无限嵌套” |

`build` 必须得到独立对象：之后再改 Builder，不影响已经构造好的 Regex 或 RegexSet。

## Error

`src/error.rs`。

| 上游 | 仓颉现状 | 状态 |
|---|---|---|
| `Error::Syntax(String)` | `Exception`，消息里带标量位置，如 `pattern scalar N: ...` | 部分支持。类别、阶段和原模式字节范围仍待工作包 H |
| `Error::CompiledTooBig(limit)` | 若干固定上限的 `Exception` | 部分支持。限额和单位都与上游不同，属于资源差异 |

未匹配不是错误。CLI 对编译和参数错误使用退出码 2，不把失败打印成空结果后返回 0。

## 语法与标志，供接口清单引用

这些不是单独的公开类型，但 Builder 和 `Regex::new` 的行为取决于它们。

| 项目 | 状态 | 验证入口 |
|---|---|---|
| 分组、分支、计数重复、贪婪和非贪婪 | 已验证 | `tests/verify_matching.py`、`tests/verify_classes.py` |
| 字符类交并差、POSIX ASCII 类 | 已验证 | `tests/verify_classes.py`、`tests/verify_ascii_classes.py` |
| 内联 `m` / `s` / `U` 及局部作用域 | 已验证 | `tests/verify_flags.py` |
| 内联 `i` 的 Unicode 简单大小写折叠 | 已验证 | `tests/verify_case.py`，原生测试 `simpleCaseFoldingKeepsOriginalText` |
| `x` / `R` / `u`、八进制、方向性词边界、Unicode 捕获名 | 待实现 | 现在构造这些模式会失败，不会改成别的含义 |
| Unicode 16.0.0 的 d/s/w、通用类别、Script、Script_Extensions、64 个二元属性 | 已验证 | `tests/verify_unicode.py` 等 |
| Age、Grapheme_Cluster_Break、Word_Break、Sentence_Break | 待实现 | 查询字符集合，不自动实现分词或断句算法 |
| 前后查找、反向引用 | 本版排除 | 上游同样拒绝。测试放在非法模式，不放在“未支持” |

简单大小写折叠表来自同一固定提交的 `regex-syntax/src/unicode_tables/case_folding_simple.rs`，生成文件是 `port/src/case_fold.cj`。`(?-u)` 尚未打开，因此 ASCII-only 折叠还没有可观察开关；它随 `u` 一起做，避免出现“Unicode 已关、但 `\w` 仍是 Unicode”的半套行为。
