# 现状

这一份说明当前仓库做到哪里。包版本号仍是 `0.3.0`，那只是 `port/cjpm.toml` 里的号码。中间版本的发布说明已经删除，不要把它们当成现在的边界。

目标是复刻固定上游的行为，不添加上游没有的功能。上游是 [rust-lang/regex](https://github.com/rust-lang/regex) 提交 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`（regex 1.13.1，Unicode 16.0.0），记在 [baseline.json](baseline.json)。匹配只在仓颉里做。Rust 只用来对照。

## 已经实现

移植的是顶层 `regex` 包的字符串接口和 bytes 接口，不是整个 workspace。

调用方可以用 `import cjregex.*` 做这些事：

- `Regex` / `BytesRegex`：查找、判断是否匹配、捕获、替换、分割，以及从原文偏移继续搜索。
- `RegexSet` / `BytesRegexSet`：回答哪些模式命中。不返回位置和捕获。
- `RegexBuilder` 和对应的 Set、bytes Builder：Unicode、大小写、多行、点号、CRLF、忽略空白、八进制、行终止符、嵌套上限、`sizeLimit`、`dfaSizeLimit`。
- Unicode 16.0.0 的 `\d` `\s` `\w`、通用类别、Script、Script_Extensions、二元属性、简单大小写折叠，以及 Age 和三种 Break 的集合成员查询。
- 语法错误和编译超限抛 `RegexError`。`toString()` 与上游 Display 相同。超限句是 `Compiled regex exceeds size limit of N bytes.`

字符串引擎按 Unicode 标量扫描，再换算成 UTF-8 字节偏移。字节引擎按原始字节扫描，输入可以不是合法 UTF-8。`(?-u).` 在字节接口上匹配一个字节，在字符串接口上构造失败。

搜索是一条有序 PikeVM。`dfaSizeLimit` 只决定字符串搜索要不要用一块步进缓存；小于 128 时不用。匹配文本不变。没有 lazy DFA，字节搜索不读这个限额。

接口写法在 [api.md](api.md)。怎么运行在 [getting-started.md](getting-started.md)。

## 怎么确认它和上游一致

上游 `regex` 包自己会断言的测试，已经用固定 Rust 和仓颉对过：

- `tests/suite_string.rs`、`suite_bytes.rs`、`suite_string_set.rs`、`suite_bytes_set.rs` 真正执行的题，共 3213 条。入口是 `tests/verify_upstream_suite.py`。
- `tests/regression.rs` 和 `tests/replace.rs` 里的手写行为用例。

这些题覆盖 `is_match`、`find`、`captures`，以及 RegexSet 的命中编号。同一条模式、同一段文本，两边的区间和捕获一致；该拒绝编译的也会拒绝。

这是顶层 `regex` 包的验收线，不是每一条可以写出来的正则都已被证明，也不是整个上游仓库的全部测试。上游自己会跳过的题不在这 3213 条里，例如单条 `Regex` 的重叠搜索、不限次数的锚定搜索，以及 `regex-lite`。

`bash scripts/run.sh verify` 还会跑本仓库自己的差分。报告在 `$REGEX4CJ_LOCAL/work/verification.json`。里面的条数是已经跑过的检查，不是完成百分比。

## 调用形式上的差别

这些不影响把结果收集出来之后的内容：

- 失败抛 `Exception`。语法错误和编译超限是 `RegexError`。越界起点、落在字符中间的起点、负数限额抛普通 `Exception`。上游在这些情况下会 panic。
- 没有 `regex!`，也没有 `Iterator`、`Replacer`、`FromStr`、`Debug` 这些 trait。对应的是 `next()`、数组和 `replaceWith`。
- `expand` 返回新字符串。`SetMatches.indices()` 返回升序数组。
- `isMatch` 会先做出一条完整匹配，再变成布尔值。

## 距离 100% 复刻还差什么

原仓库是一个 workspace。顶层 `regex` 只是其中一层。还没有移植的是：

| 上游 | 里面有什么 |
|---|---|
| `regex-syntax` | AST、HIR、解析器、打印、访问器，以及 Unicode 表的公开查询。解析行为已经在内部使用，缺的是让别人直接调用这套库 |
| `regex-automata` | Thompson NFA、PikeVM、one-pass、有界回溯、lazy DFA、完全 DFA、meta 调度、预过滤、反向 NFA 的公开接口 |
| `regex-lite` | 另一套更小的引擎 |
| `regex-capi` | C 接口 |
| `regex-cli`、`regex-test` | 上游的命令行和测试驱动。本仓库有自己的对照 CLI 和 Python 差分 |

`regex-automata` 里还有两种不同的差距：

- **换搜索方法。** 预过滤、反向自动机、one-pass、有界回溯、lazy DFA、完全 DFA。顶层 `Regex.find` 实际走的是 meta 引擎里的快路径。已接受模式的匹配文本可以保持不变，变的是速度，以及 `dfaSizeLimit` 的真实含义。现在只有 PikeVM 和一块字符串步进缓存。
- **换一种问法。** 重叠匹配、锚定搜索、leftmost-longest、多模式同时给出匹配位置和捕获。同一条正则、同一段文字会得到另一份结果。它们不在顶层 `Regex.find` 上。`Regex.find` 固定是不锚定、最左优先、不重叠。

前后查找、反向引用、全量大小写折叠、用 Break 属性做分词或 `\X`，固定上游的字符串接口也没有。上游会拒绝前后查找和反向引用，这里同样拒绝。这些不是缺口。

## 还需要补充的内容

功能先停在现在的顶层接口。下面这些还没写进仓库，接手时以这一节为准。

- 速度工作还没做。要做的话，先做 lazy DFA、字面量预过滤和反向自动机，因为那是顶层 `regex` 的快路径。不要为了变快去改已经对过的匹配文本。
- 重叠匹配、锚定搜索、leftmost-longest、多模式带位置，是另一套接口。做它们才会出现和 `Regex.find` 不同的结果。
- 环境固定在 Apple Silicon、仓颉 1.0.5。不要升级 Rust regex、Unicode 或仓颉 SDK。构建用 `cjpm build`，不要加 `--release`。本地缓存和上游检出在仓库同级的 `regex4cj-local/`，用 `scripts/env.sh` 进入。
- 负数限额的报错里保留 “nonnegative”。语法错误和超限的 `toString()` 继续对齐上游 Display。
- 通过有限测试不等于任意输入都已证明。新增行为要用固定 Rust 对照，不要只看仓颉自己的预期。

## Reproduction evidence

Acceptance fixtures are vendored in `tests/upstream/`; no external upstream checkout is required. `verification-run.json` records the commit, environment and every stage. Only a final `passed` status means the complete invocation succeeded; `verification.json` holds incremental counters.
