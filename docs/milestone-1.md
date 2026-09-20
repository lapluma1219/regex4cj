# 第一步：受限语法的仓颉原生匹配引擎

这是第一步完成时的历史记录，不是全量 rust-lang/regex 移植。当前新增字符类与计数重复，见 [第二步](milestone-2.md)。

## 已交付

- `Regex(pattern)`：解析受支持语法并编译 NFA，非法或未支持语法抛出异常。
- `find(text)`：首个匹配，返回 `Option<RegexMatch>`。
- `isMatch(text)`：判断是否存在匹配。
- `findAll(text)`：按原库 find_iter 的非重叠及空匹配推进规则返回数组。当前为立即收集，尚未提供惰性迭代器。
- `RegexMatch.start/end` 是 UTF-8 字节偏移，区间左闭右开；`text` 是匹配内容。
- CLI 的 `find` 对应全部匹配，`first` 对应首个，`is-match` 对应布尔判断。

## 支持范围

| 语法 | 支持情况 |
|---|---|
| 字面量、中文、emoji | 支持有效 Unicode 标量；偏移返回 UTF-8 字节 |
| 连接、`a|b`、空模式／空分支 | 支持，保持分支顺序 |
| `(...)`、`(?:...)` | 支持分组匹配；本阶段不提取捕获内容 |
| `*`、`+`、`?` | 支持贪婪重复 |
| `*?`、`+?`、`??` | 支持非贪婪重复 |
| `.` | 匹配一个 Unicode 标量，排除 LF |
| `^`、`$`、`\A`、`\z` | 仅整段文本开始／结束，不启用多行模式 |
| `\n`、`\r`、`\t`、转义 ASCII 标点／空格 | 支持 |
| 字符类、计数重复、命名分组、内联标志 | 明确拒绝，后续移植 |
| `\d`、`\w`、Unicode 属性、词边界、十六进制转义 | 明确拒绝，后续移植 |
| 连续堆叠量词（如 `a**`） | Rust 接受部分这类写法，本阶段明确拒绝；可用分组表达嵌套 |
| bytes、替换、分割、RegexSet、捕获 API | 尚未实现 |

解析错误位置目前是 Unicode 标量索引，异常类型／消息尚未对齐 Rust。没有隐藏的 std.regex 或 Rust 运行时调用；Rust 只存在于开发验证程序中。

## 上游对应与调整

统一来源：https://github.com/rust-lang/regex/tree/72d650cb0a880a01ab6dc2137c0888e8f89740f7

| 本项目 | 上游依据 | 本阶段调整 |
|---|---|---|
| parser.cj | regex-syntax/src/ast、hir 的语法与语义边界 | 新写的受限递归下降解析器，直接构造 Expr；不是完整 AST/HIR 的逐行转译 |
| Compiler.compile | regex-automata/src/nfa/thompson/compiler.rs 的 c_concat、c_alt_iter、c_at_least、c_zero_or_one | 用 continuation 参数代替 Rust 的 fragment patch；以 Rune 消耗输入，未移植字节状态压缩 |
| 星号重复构造 | 同文件 c_at_least 对可空表达式的处理 | 统一按 `(x+)?` 构造 `x*`，保留可空重复中的优先级 |
| Regex.search / closure | regex-automata/src/nfa/thompson/pikevm.rs 的 search_imp、epsilon_closure | 有序活跃状态、迭代 epsilon 遍历、每位置去重；仅存整体起点，未移植捕获槽 |
| Regex.findAll | regex-automata/src/util/iter.rs 的 Searcher 与空匹配处理 | Unicode 标量推进保证 UTF-8 边界；抑制紧邻上一匹配结尾的空匹配 |

在发现接受状态时保留候选，但让更高优先级的线程继续执行，并丢弃更低优先级的线程。这是贪婪匹配、分支优先级同时成立的关键。

## 资源与性能边界

- 模式上限：4096 UTF-8 字节。
- 分组嵌套上限：64。
- NFA 状态上限：16384。
- 单次 search 每个输入位置至多访问每个 NFA 状态一次，没有逐路径递归回溯。
- 输入先转为 Rune 数组并构建偏移表，额外占用 O(n) 空间；暂未实现流式字节扫描。
- findAll 是多次搜索并立即收集结果，不承诺整个迭代过程为 O(mn)；特定模式下仍可能达到 O(mn²)。
- 未实现 DFA、预过滤、缓存复用和编译器优化；不要用当前原型代表原库性能。

## 验收

```sh
bash scripts/verify.sh
bash scripts/demo.sh
```

匹配验证包含固定规则／文本组合、确定种子的语法树生成、首个匹配与布尔接口、独立黄金结果、错误路径、资源限制和长输入。结果写入仓库外的 verification.json；若差分失败，matching-failure.json 会保留输入和双方输出。

本轮全套验证通过：336 条转义差分、4 条转义字面值验证、594 条匹配差分、16 项 find/isMatch 对照、4 条匹配黄金结果、12 条未支持语法拒绝、8 条非法模式拒绝、2 项资源限制检查；另有 6 条 Rust 基线用例。

尚未覆盖 CLI 无法传入的 NUL；未做 Windows/Linux 验证；测试通过不是形式化等价证明。

## 下一步

优先移植字符类及 `{m,n}` 计数重复，使最初的 `[A-Z]{2}-[0-9]{3}` 订单例子可由仓颉运行；随后加入捕获槽及完整 Unicode 语义。项目目前仍是验证用可执行包，稳定 API 后再拆分可供下游依赖的库包与 CLI。
