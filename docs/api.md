# 当前接口

完整的公开入口数量、参数签名和逐项中文行为说明见[接口数量与行为清单](api-catalog.md)。该清单区分仓颉实际公开入口与上游方法审计条目，不将两者混作完成率。

使用 `import cjregex.*`。可运行的调用在 `examples/consumer/src/main.cj`。这里写的是 v0.3.0 的仓颉接口。固定上游是 `regex` 提交 `72d650cb`，记在 [baseline.json](baseline.json)。它不是 regex-syntax、regex-automata 或 regex-lite 的公开类型。

查找返回的区间是原输入的 UTF-8 字节偏移，半开区间 `[start, end)`。未找到匹配时返回 `None`、空数组或 `false`，不抛异常。

## 查找

```cangjie
let re = Regex("[A-Z]{2}-[0-9]{3}")
for (m in re.findAll("AB-123 CD-456")) {
    println("${m.text} [${m.start}, ${m.end})")
}
```

| 接口 | 含义 |
|---|---|
| `Regex(pattern)` | 解析并编译。非法、不支持或超限时抛 `RegexError` |
| `isMatch(text)` | 是否存在匹配 |
| `find(text)` | 第一条匹配，`Option<RegexMatch>` |
| `findAll(text)` | 按顺序收集不重叠匹配 |
| `findAt` / `isMatchAt` / `capturesAt` | 从原文字节偏移继续搜索。起点落在字符内部时，匹配从后续字符边界开始，断言仍保留原文上下文 |
| `shortestMatch` / `shortestMatchAt` | 引擎确认匹配时的早停终点。本实现中 `a+` 在 `aaaaa` 上返回 `1`；上游不保证数学最短，也不保证不同引擎返回相同终点 |
| `findIter().next()` | 与 `findAll` 同一套空匹配推进，按需取下一条 |
| `asStr()` | 编译时的原始模式 |

`RegexMatch` 还有 `isEmpty()`、`len()` 和 `asStr()`。`text` 是原文切片。大小写匹配不会把结果改成折叠后的字符：`(?i)k` 匹配 `K` 时，取回的文本仍是 `K`。`ß` 只和 `ẞ` 互配，不会把 `SS` 当成一个 `ß`。

## 捕获

| 接口 | 含义 |
|---|---|
| `captures(text)` / `capturesAll(text)` | 第一条，或全部不重叠匹配的各组 |
| `capturesIter().next()` | 按需取下一组捕获 |
| `capturesLen()` | 分组数，包括完整匹配组 0 |
| `captureNames()` | 按组号排列。组 0 和未命名组是 `None`。名称可以是 Unicode |
| `staticCapturesLen()` | 每次匹配的组数固定时为 `Some`，否则 `None`。`(a)\|(b)` 是 `Some(2)`，`(a)\|b` 是 `None` |

`Captures`：

| 接口 | 含义 |
|---|---|
| `size` | 包括组 0 |
| `get(index)` | 该组的匹配。未参与、负数或越界返回 `None` |
| `getMatch()` | 组 0 |
| `name(value)` | 按名字查询。不存在或未参与返回 `None`。名字不折叠、不规范化 |
| `expand(template)` | 展开模板，返回新字符串 |
| `expandInto(template, destination)` | 把展开结果追加到StringBuilder，保留已有内容，可连续调用 |
| `extract(count)` | `count` 必须等于 `staticCapturesLen() - 1`。第一项是完整匹配 |
| `iter().next()` | 逐组查看。结束和“这一组没参与”用 `GroupItem` 区分 |

命名组写成 `(?<number>[0-9]+)` 或 `(?<名>a)`。未参与的组和捕获到空文本不是一回事。

`captureLocations()` 只保存整型位置，不保存文本。应使用同一个 Regex 创建的位置对象。`capturesRead` / `capturesReadAt` 成功时覆盖全部槽；失败后 `get` 返回 `None`，不保留旧命中的可读位置。已经返回的 `Captures` 不会被下一次搜索改写。这里复用的是位置容器，尚不保证像上游一样复用内部搜索内存。

## 替换与分割

| 接口 | 含义 |
|---|---|
| `replace(text, replacement)` | 用模板替换第一条 |
| `replaceAll(text, replacement)` | 替换全部 |
| `replaceN(text, limit, replacement)` | 最多 `limit` 次。`0` 表示不限 |
| `replaceLiteral(text, limit, replacement)` | 把 `replacement` 当普通文本，不展开 `$` |
| `replaceWith(text, limit, replacer)` | 回调 `(Captures) -> String`。回调里可以再使用同一个 `Regex` |
| `split(text)` | 按匹配分割，包含首尾空段 |
| `splitN(text, limit)` | 最多 `limit` 段，最后一段保留剩余文本 |
| `splitIter().next()` | 按需取下一段 |
| `splitNIter(text, limit).next()` | 按需最多取 limit 段，最后一段保留剩余输入；0 无结果，1 返回原输入，负数抛异常 |

次数或段数小于 0 时抛 `Exception`。`replaceN(..., 0, ...)` 是不限次数；`splitN(..., 0)` 返回空数组；`splitN(..., 1)` 只返回完整输入。

模板支持 `$0`、`$1`、`${name}`。`$$` 是字面量 `$`。不存在或未参与的组展开为空。名称边界用花括号，例如 `${prefix}_end`。仓颉源码里写 `#"${prefix}-***"#`，shell 里用单引号。

## Builder

`RegexSetBuilder(patterns)`和`BytesRegexSetBuilder(patterns)`可直接接收规则数组。构造时保存规则副本，调用build时编译；修改原数组不会改变Builder。无参构造与pattern追加方式继续保留。

`Regex(pattern)` 和 `RegexSet(patterns)` 使用默认值：Unicode 开，八进制关，行终止符是换行，嵌套 250，`sizeLimit` 约 10 MiB，`dfaSizeLimit` 约 2 MiB。`build()` 复制当时的选项，之后再改 Builder 不影响已经构造好的对象。

内联标志 `i`、`m`、`s`、`U`、`x`、`R`、`u` 可以写在模式里，也可以用 Builder 打开。`i` 在 Unicode 开时做简单大小写折叠，`(?-u)` 时只折叠 A–Z。

| 选项 | 作用 |
|---|---|
| `unicode` | 关闭后 `\d`、`\w`、`\s` 和词边界收成 ASCII。会匹配到非 ASCII 的点号或字符类在构造时失败。普通非 ASCII 字面量仍然可以 |
| `caseInsensitive` | 与 `(?i)` 相同 |
| `multiLine` | 与 `(?m)` 相同 |
| `dotMatchesNewLine` | 与 `(?s)` 相同 |
| `swapGreed` | 与 `(?U)` 相同 |
| `crlf` | 与 `(?R)` 相同。一行的结尾可以是回车、换行，或回车紧挨换行。不预先替换输入 |
| `ignoreWhitespace` | 与 `(?x)` 相同。忽略 Unicode 空白和 `#` 注释，包括字符类内部。`\ ` 仍是一个空格 |
| `octal` | 只由 Builder 打开。最多三位，最大 511。关闭时 `\1` 仍是不支持的反向引用 |
| `lineTerminator` | 一个字节，`0`–`255`。非 ASCII 时，含 `.` 的字符串模式会失败 |
| `nestLimit` | 默认 250。`0` 允许 `a`，拒绝 `ab` |
| `sizeLimit` | 按 Thompson 构造字节数检查，正向与反向取较大值。默认约 10 MiB。`\w` 在 `45000` 失败，在 `50044` 成功。单条有限字面量可以在限额为 0 时编译 |
| `dfaSizeLimit` | 字符串搜索的缓存预算。小于 128 时仍用原来的 NFA。匹配文本不变。没有 lazy DFA，字节搜索不读取它 |

`RegexSetBuilder` 使用同一组选项。RegexSet 不会把有限字面量绕过 `sizeLimit`。Set 搜索不提供上游 DFA 缓存；`dfaSizeLimit` 在 Set 和 bytes 上没有对应的缓存效果，不能据此声称资源行为与 Rust 相同。

## 错误

语法错误和编译超限抛出 `RegexError`，它是 `Exception` 的子类，所以 `catch (Exception)` 仍能接住。`toString()` 按固定上游 Display 实现并通过现有错误样例对照：语法错误带模式和脱字符，超限是 `Compiled regex exceeds size limit of N bytes.`。负数限额、越界起点抛普通 `Exception`；Rust 的无符号参数不能表达负数，越界起点按上游契约可 panic。合法范围内的字符内部起点不应报错。

`escape(text)` 把普通文本转成正则字面量。它不是 JSON 或 shell 转义。

## 字节接口

`BytesCaptures.expandInto(template, destination)`向`ArrayList<UInt8>`追加展开结果，保留已有字节，支持NUL及非法UTF-8；原expand仍返回新数组。两种展开形式共用同一模板解析逻辑。

`BytesRegex` 和 `BytesRegexSet` 的输入、匹配片段和替换结果都是 `Array<UInt8>`，可以包含非法 UTF-8。查找、捕获、`expand`、替换、分割和 RegexSet 的命中查询都有对应方法。`(?-u).` 匹配一个字节。同一个模式在字符串 `Regex` 上构造失败。

bytes 已提供 `findIter`、`capturesIter`、`splitIter`、`splitNIter`，分别返回 `BytesMatchIter`、`BytesCaptureIter`、`BytesSplitIter`，以 `next()` 按需读取。原有 `findAll`、`capturesAll`、`split`、`splitN` 仍返回数组。新增 `capturesRead(locations, bytes)` 等同起点为0的 `capturesReadAt`。

bytes 迭代器创建时复制输入数组作为快照，之后每次 `next()` 才执行下一次搜索，没有预先收集全部匹配。外部修改输入、修改已返回的匹配字节或交错使用两个迭代器，不会改变另一个游标的结果。结束后持续返回 None。输入快照仍需 O(输入字节数) 的空间，这不是流式文件读取，也不是 Rust 的零复制借用。

字符串 `splitNIter` 创建时准备扫描信息，但不预先计算全部匹配。两类输入的 limit=0 不搜索，limit=1 直接返回原输入，达到段数限制后不再搜索剩余输入。专项证据见 [接口审计](api-audit.md)。

例如 `Regex(",").splitNIter("a,b,c", 2)` 连续三次 `next()` 分别得到 `Some("a")`、`Some("b,c")`、`None`。`BytesRegex("(?-u).").findIter([UInt8(255), UInt8(97)])` 则按需返回 `[0,1)` 的字节255和 `[1,2)` 的字节97；只调用一次就不会搜索第二条。

## RegexSet

RegexSet 只回答哪些规则命中，不返回位置、文本或捕获。需要这些信息时，再用对应的单条 `Regex` 查。

```cangjie
let set = RegexSet(["退款", "发票", "[A-Z]{2}-[0-9]{3}"])
let result = set.matches("订单 AB-123 退款")
for (id in result.indices()) {
    println(id) // 0，然后 2
}
```

分类演示把编号映射成标签，标签不属于库：

```sh
bash scripts/run.sh classify '订单 AB-123 需要退款，也需要开发票'
bash scripts/run.sh set-matches '订单 AB-123 退款' '退款' '发票' '[A-Z]{2}-[0-9]{3}'
```

规则文件在 `examples/classification-rules.json`。JSON 里的反斜线写成 `\\`。编号从 0 开始，次序就是数组次序。任一条模式编译失败，整个集合失败。错误文本与单条 `Regex` 相同，不附加规则编号。

| 接口 | 含义 |
|---|---|
| `RegexSet(patterns)` | 编译全部模式。空数组是空集合 |
| `isMatch` / `isMatchAt` | 至少一条命中。起点是原文字节偏移 |
| `matches` / `matchesAt` | 返回 `SetMatches`。互相重叠的规则都算命中 |
| `matchesReadAt` | 命中的槽写成 `true`，其余槽保持原值。返回这次是否命中 |
| `len` / `isEmpty` | 规则总数，不是命中数 |
| `patterns` | 原始模式的副本 |
| `matched(index)` | 该编号是否命中。负数或越界抛 `Exception` |
| `matchedAny` / `matchedAll` | 空集合分别是 `false` 和 `true` |
| `indices()` | 命中编号，升序，每个编号一次 |
| `iter()` | 返回独立的编号游标，不预先收集编号数组 |

`SetMatchesIter.next()` 从前往后取编号，`nextBack()` 从后往前取。两者可以交错使用，同一编号不会重复返回；耗尽后持续返回 `None`。`clone()` 复制当前游标位置，之后两份游标独立移动。字符串与 bytes 的集合结果共用此类型。此处提供显式方法，`sizeHint()` 返回 `(Int64, Option<Int64>)`，两端均为尚未扫描的规则槽位数。这忠实保留固定原仓库的行为，不是剩余命中数，不能用它断言至少还会返回多少命中。尚未提供 Rust 的 Iterator/IntoIterator trait 或 Debug。

`BytesRegexSet` 用同样的命中语义扫描字节数组。修改构造时传入的数组，或修改 `patterns()`、`indices()` 的返回值，不会改掉集合或已经返回的结果。

## 这套接口不提供的东西

- 前后查找和反向引用。上游的字符串接口也会拒绝它们。
- Break 属性只判断字符属于哪个集合，不把文本切成词或句。
- 没有 `regex!` 宏，也没有 Rust 的 `Iterator`、`Replacer`、`FromStr`、`Debug` 这些 trait。对应行为是上面的方法、数组和回调。
- 顶层 `Regex` 不是完整的 regex-syntax、regex-automata、regex-lite 或 regex-capi。`PikeVM`、`ReverseNfa`、`BoundedBacktracker`、`DenseDfa` 和 `SparseDfa` 是单独的搜索类型，见 [现状](status.md)。

### 捕获组迭代器的剩余数量与复制

`GroupIter` / `BytesGroupIter` 除逐次 `next()` 外，提供：

- `len()`：尚未读取的捕获槽位数，包含组0及未参与匹配的组。
- `sizeHint()`：`(len(), Some(len()))`，这里是准确的剩余项数。
- `clone()`：从当前进度复制一个独立游标，不重新开始、不推进原游标。两者共享结果存储；bytes结果数组的深复制不在此保证中。

未参与匹配的组仍返回 `done=false, value=None`，与迭代结束的 `done=true` 不同。耗尽后的len保持0，复制耗尽游标仍然耗尽。这些是显式仓颉方法，不表示实现了Rust的同名trait。

## 公开语法结构（HIR切片）

新增Hir及相关不可变模型，支持读取和构造空、字面量、字符类、重复、捕获、连接六类结构，并查询最短/最长匹配字节数。详见[HIR使用与范围](hir.md)。这是regex-syntax的部分公开能力，不等于完整解析结构库；未支持的节点会明确报错。
