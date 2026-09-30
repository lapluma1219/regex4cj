# RegexSet：多规则分类与 API 契约

## 先运行一个完整例子

```sh
bash scripts/run.sh classify '订单 AB-123 需要退款，也需要开发票'
```

输出命中编号 `[0, 1, 2]` 和三个标签。默认配置在 `examples/classification-rules.json`：

```json
[
  {"label":"退款相关", "pattern":"退款"},
  {"label":"发票相关", "pattern":"发票"},
  {"label":"包含订单号", "pattern":"[A-Z]{2}-[0-9]{3}"}
]
```

可复制并修改文件，运行 `bash scripts/run.sh classify '你的文本' --rules /绝对路径/rules.json`。JSON 字符串中的反斜线要写成 `\\`，例如 `"pattern":"\\d+"`。规则文件中的次序决定编号，从 0 开始。标签由 Python 演示程序管理，实际正则编译和所有规则的命中判断由仓颉 RegexSet 完成。

`bash scripts/run.sh demo` 同时运行九个原有场景与六个分类场景；`check` 还会执行仓颉原生测试。CLI 也可直接传模式，无需 JSON：

```sh
bash scripts/run.sh set-matches '订单 AB-123 退款' '退款' '发票' '[A-Z]{2}-[0-9]{3}'
bash scripts/run.sh set-is-match 'hello' '退款' '发票'
```

第一条的协议输出为：

```text
patterns  3
any       true
all       false
hit       0
hit       2
```

字段间实际是 TAB。第二条输出 false。命令参数与单模式 `find` 不同：先 TEXT，再跟零条或多条 PATTERN。`set-matches 'abc'` 构造空集合。

## 仓颉调用

```cangjie
let set = RegexSet(["退款", "发票", "[A-Z]{2}-[0-9]{3}"])
let result = set.matches("订单 AB-123 退款")
for (id in result.indices()) {
    println(id) // 0，然后 2
}
```

可运行的实际调用已加入 `examples/consumer/src/main.cj`。与原库一样，RegexSet 只回答哪些规则命中，不直接返回位置、文本或捕获；需要这些信息时再用相应的 Regex 查询。

| 固定 Rust 上游 | 仓颉对应 | 契约或差异 |
|---|---|---|
| RegexSet::new | RegexSet(patterns: Array<String>) | 所有模式先编译；任意一条失败则整个构建失败 |
| RegexSet::empty | RegexSet(Array<String>()) | 用空数组构造，未另设静态 empty 方法 |
| is_match | isMatch(text): Bool | 至少一个规则命中；允许提早结束 |
| matches | matches(text): SetMatches | 收集全部命中编号，包括重叠规则 |
| len / is_empty | len(): Int64 / isEmpty(): Bool | 原始规则数量及是否为空集合 |
| patterns | patterns(): Array<String> | 返回保留原始次序的副本；Rust 返回借用切片 |
| SetMatches::matched | matched(index: Int64): Bool | 指定编号是否命中；越界或负数抛 Exception，Rust 越界会 panic |
| matched_any / matched_all | matchedAny() / matchedAll() | 空集合为 false / true，与固定 Rust 一致 |
| SetMatches::len | len(): Int64 | **原始规则总数**，不是命中数 |
| SetMatches::iter | indices(): Array<Int64> | 编号递增、每编号一次；当前返回数组，不是惰性迭代器 |

匹配对象与返回数组都是独立快照。修改构造时传入的模式数组、`patterns()` 或 `indices()` 的返回值，不会改变集合或此前结果。String 为不可变值。

本版没有移植 matches_at / is_match_at、matches_read_at、RegexSetBuilder、bytes::RegexSet 及完整 Rust trait 表面。只接受原单模式库已支持的语法；加入 RegexSet 不意味着 `(?i)` 等此前未支持的语法突然可用。原有模式限制继续生效。

## 实现原则

`port/src/regex_set.cj` 复用 Parser、normalizeWidth、Compiler、CharSet 和 Unicode 数据，使用统一的状态数组。每个规则有独立的 Accept 状态，其 first 字段保存原规则编号。普通 Regex 仍使用自己的搜索路径，未改动其优先匹配语义。

集合执行器扫描 Unicode 标量，维护当前状态集合；不收集捕获，Save 被视作不消耗字符的跳转。到达 Accept 时只记录该规则命中，继续处理其他规则。匹配编号用布尔数组去重，输出时按编号顺序收集。没有把多个模式简单拼成分支，也没有在正式搜索中循环调用各个 Regex。

这是一条统一的多模式 NFA 执行路径，但尚未合并相同前缀，也没有上游的 DFA、预过滤等优化。输入仍会转换为标量和字节偏移数组，不能将“统一扫描”解读为零分配或流式输入。

新增保护：最多 256 条规则、模式总计 65,536 UTF-8 字节；整个集合共享最多 16,384 个 NFA 状态和 65,536 编译工作单位。这些是本版固定限制，不是 Rust 默认资源配置的复制。已有单模式 4096 字节、64 层嵌套等限制仍适用。限制检查失败即报错，不返回部分构建成功的集合。

## 验证与性能

新增 573 条差分检查，包括空集合、空匹配、重复/重叠规则、锚点、词边界、捕获语法、Unicode 和多规则规模；120 组随机规则另与仓颉逐条 Regex 的结果对照。四条独立黄金预期和六类错误/资源检查补充正常结果对照。

新增六项仓颉原生测试覆盖 NUL、数据独立性、结果索引越界和单规则基准；Rust 新增一项 NUL/空集合/重叠测试。完整入口 `bash scripts/run.sh verify` 执行新旧所有测试，分类演示也作为最后的验收项。

`$REGEX4CJ_LOCAL/work/set-benchmark.json` 记录 8、64、256 条规则在约 4KB 文本上的进程耗时，包含启动、编译和扫描，不能当成纯匹配吞吐基准或可靠的速度比。首次本机测量仓颉约 0.031/0.094/0.279 秒，Rust 约 0.010/0.011/0.012 秒；可见尚有性能差距，不能宣称与原库同速。全量验收会刷新测量结果。
