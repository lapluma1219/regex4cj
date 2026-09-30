# v0.2.0 公共 API

使用 `import cjregex.*`。下面记录当前仓颉接口，不是 Rust 全量 API 清单。可运行调用见 `examples/consumer/src/main.cj`。

## 构造与查找

```cangjie
let re = Regex("[A-Z]{2}-[0-9]{3}")
for (m in re.findAll("AB-123 CD-456")) {
    println("${m.text} [${m.start}, ${m.end})")
}
```

| 接口 | 返回值 / 含义 |
|---|---|
| `Regex(pattern: String)` | 解析并编译；非法、不支持或超限模式抛出 Exception |
| `isMatch(text: String)` | Bool；是否存在匹配 |
| `find(text: String)` | Option&lt;RegexMatch&gt;；第一条匹配 |
| `findAll(text: String)` | Array&lt;RegexMatch&gt;；按顺序收集不重叠匹配 |
| `captures(text: String)` | Option&lt;Captures&gt;；第一条匹配及各组 |
| `capturesAll(text: String)` | Array&lt;Captures&gt;；收集不重叠匹配的各组 |
| `capturesLen()` | Int64；分组数，包括完整匹配组 0 |
| `captureNames()` | Array&lt;Option&lt;String&gt;&gt;；按组号排列，无名称的组为 None |

RegexMatch 公开只读字段 `start: Int64`、`end: Int64`、`text: String`。区间 `[start,end)` 使用原输入的 UTF-8 字节偏移。API 返回数组而非惰性迭代器，大量匹配会占用内存。

## 捕获

| Captures 接口 | 含义 |
|---|---|
| `size: Int64` | 包括组 0 的分组数量 |
| `get(index: Int64)` | Option&lt;RegexMatch&gt;；未参与、负数或越界组号返回 None |
| `name(value: String)` | 按名字查询；不存在或未参与返回 None |
| `expand(template: String)` | 展开模板，返回 String |

命名组示例：`(?<number>[0-9]+)`。名称目前限 ASCII。组 0 是完整匹配；未参与匹配与参与但捕获了空文本不同。

## 替换与分割

下列方法均为 Regex 的实例方法，参数按位置传入：

| 接口 | 含义 |
|---|---|
| `replace(text, replacement)` | 模板替换第一条匹配 |
| `replaceAll(text, replacement)` | 模板替换全部匹配 |
| `replaceN(text, limit: Int64, replacement)` | 最多替换 limit 次，0 表示不限 |
| `replaceLiteral(text, limit: Int64, replacement)` | 将 replacement 当作普通文本，不展开 `$` |
| `replaceWith(text, limit: Int64, replacer: (Captures) -> String)` | 通过回调构造替换文本 |
| `split(text)` | 按匹配分割，返回 Array&lt;String&gt; |
| `splitN(text, limit: Int64)` | 最多返回 limit 段，最后一段保留剩余文本 |

text、replacement 的类型均为 String；所有替换返回 String。次数/段数小于 0 时抛出 Exception。注意两种 0 的含义不同：`replaceN(...,0,...)` 表示不限次数，`splitN(...,0)` 返回空数组；`splitN(...,1)` 只返回完整输入。

模板支持 `$0`、`$1`、`${name}`；`$$` 表示字面量 `$`；不存在或未参与的组展开为空文本。建议用花括号明确名称边界，如 `${prefix}_end`。仓颉源码中用原始字符串 `#"${prefix}-***"#`，shell 中用单引号 `'${prefix}-***'`。

## 辅助函数与错误

`escape(text: String): String` 将普通文本转为正则字面量；`isMetaCharacter(c: Rune): Bool` 判断正则元字符。escape 不是 JSON 或 shell 转义函数。

库通过 Exception 报告非法语法、未支持的特性和资源超限；未找到匹配通常返回 None/空数组/false。CLI 将错误打印到 stderr 并返回退出码 2。当前没有上游完整的精确错误类型和位置 API。

资源保护包括：模式最多 4096 字节、嵌套 64 层、重复计数 10000、NFA 最多 16384 个状态、编译工作量 65536、显式捕获最多 128 个，以及捕获状态槽规模限制。它们是本版实现限制，不是对 Rust 默认配置的完整复刻。

## 多规则接口

新增 `RegexSet` 和 `SetMatches`。构造、查询、结果语义及与 Rust 的逐项映射见 [RegexSet 契约](regex-set.md)。现有单模式接口保持不变。
