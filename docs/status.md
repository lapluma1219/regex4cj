# 现状

最新增量（2026-10-04）：公开HIR切片已实现，支持六类节点、归一化构造、切片解析与长度查询，详见[HIR使用说明](hir.md)。Cangjie1.1.3、Apple Silicon macOS下完整41阶段验收通过：40项原生测试、3213条原仓库匹配用例、2414项主要库接口契约、513次起点差分，以及325组HIR解析和205组HIR构造对照。见[本批验收记录](acceptance/hir-slice-2026-10-04.md)。

此前[1.1.3适配](acceptance/cangjie-1.1.3-2026-10-04.md)、[追加展开与构造](acceptance/append-builder-2026-10-04.md)、[捕获组游标](acceptance/group-cursor-2026-10-04.md)各自保留原有验证范围，不混用结果。

这一份说明当前仓库做到哪里。包版本号仍是 `0.3.0`，那只是 `port/cjpm.toml` 里的号码。中间版本的发布说明已经删除，不要把它们当成现在的边界。

目标是复刻固定上游的行为，不添加上游没有的功能。上游是 [rust-lang/regex](https://github.com/rust-lang/regex) 提交 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`（regex 1.13.1，Unicode 16.0.0），记在 [baseline.json](baseline.json)。匹配只在仓颉里做。Rust 只用来对照。

## 已经实现

主体是主要 `regex` 库的字符串接口和bytes接口，另外已新增[公开HIR切片](hir.md)，可以读取和构造部分正则语法结构；尚不是整个原仓库。

调用方可以用 `import cjregex.*` 做这些事：

- `Regex` / `BytesRegex`：查找、判断是否匹配、捕获、替换、分割，以及从原文偏移继续搜索。
- `Hir`：解析或构造空、字面量、字符类、重复、捕获、连接节点，读取结构及最短/最长字节数；有效但未支持的结构显式报错。
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

- 失败抛 `Exception`。语法错误和编译超限是 `RegexError`。越界起点、负数限额抛普通 `Exception`。合法范围的字符内部起点会继续搜索；Rust 无符号参数不接受负数，越界起点按上游契约可 panic。
- 没有 `regex!`，也没有 `Iterator`、`Replacer`、`FromStr`、`Debug` 这些 trait。对应的是 `next()`、数组和 `replaceWith`。
- `expand` 返回新内容；`expandInto` 可向现有缓冲区追加。`SetMatches.indices()` 返回升序数组，`iter()` 支持双向逐项读取和独立游标复制。
- 字符串 `isMatch` 会先做出一条完整匹配，再变成布尔值；bytes 有早停路径。

## 顶层接口仍存在的差异

见 [接口审计](api-audit.md) 和 [逐项对应表](api-audit-methods.md)。bytes 惰性迭代、两类输入的惰性 splitN 已补齐；原先列出的 bytes 辅助方法与 Builder 组合已补专项验证。宏和部分语言集成仍缺失；Builder 资源语义、所有权和分配行为不完全等价。有限组合测试不表示任意输入都已证明。

## 距离 100% 复刻还差什么

原仓库是一个 workspace。顶层 `regex` 只是其中一层。下列部分仍未完整移植：

| 上游 | 里面有什么 |
|---|---|
| `regex-syntax` | 已公开六类HIR节点、切片解析和长度查询；Look/Alternation、点号转换、AST、完整解析配置、打印/访问器和完整属性等仍缺失 |
| `regex-automata` | Thompson NFA、PikeVM、one-pass、有界回溯、lazy DFA、完全 DFA、meta 调度、预过滤、反向 NFA 的公开接口 |
| `regex-lite` | 另一套更小的引擎 |
| `regex-capi` | C 接口 |
| `regex-cli`、`regex-test` | 上游的命令行和测试驱动。本仓库有自己的对照 CLI 和 Python 差分 |

`regex-automata` 里还有两种不同的差距：

- **换搜索方法。** 预过滤、反向自动机、one-pass、有界回溯、lazy DFA、完全 DFA。顶层 `Regex.find` 实际走的是 meta 引擎里的快路径。已接受模式的匹配文本可以保持不变，变的是速度，以及 `dfaSizeLimit` 的真实含义。现在只有 PikeVM 和一块字符串步进缓存。
- **换一种问法。** 重叠匹配、锚定搜索、多模式同时给出匹配位置和捕获。同一条正则、同一段文字会得到另一份结果。它们不在顶层 `Regex.find` 上。`Regex.find` 固定是不锚定、最左优先、不重叠。

前后查找、反向引用、全量大小写折叠、用 Break 属性做分词或 `\X`，固定上游的字符串接口也没有。上游会拒绝前后查找和反向引用，这里同样拒绝。这些不是缺口。原仓库固定版本的 `MatchKind` 仅公开 `All` 与 `LeftmostFirst`；`LeftmostLongest` 只是源码注释讨论的可能扩展，不能列为待移植的已有能力。

## 还需要补充的内容

2026-10-03起，目标扩展为对齐整个原仓库，工作路线见[完整行为对齐计划](full-compatibility-plan.md)。本轮已增加SetMatches的双向编号迭代和独立游标复制；其余引擎与底层库仍未完成。

- 速度工作还没做。要做的话，先做 lazy DFA、字面量预过滤和反向自动机，因为那是顶层 `regex` 的快路径。不要为了变快去改已经对过的匹配文本。
- 重叠匹配、锚定搜索、多模式带位置，是另一套接口。做它们才会出现和 `Regex.find` 不同的结果。
- 当前适配目标为Apple Silicon、仓颉1.1.3，按赛事要求替换原1.0.5基线；Rust regex和Unicode版本保持固定。构建用 `cjpm build`，不要加 `--release`。本地缓存和上游检出在仓库同级的 `regex4cj-local/`，用 `scripts/env.sh` 进入。
- 负数限额的报错里保留 “nonnegative”。语法错误和超限的 `toString()` 继续对齐上游 Display。
- 通过有限测试不等于任意输入都已证明。新增行为要用固定 Rust 对照，不要只看仓颉自己的预期。

## 复现与交付

上游验收数据已收录到 `tests/upstream/`，完整验收不需要外部上游检出。`verification-run.json` 记录提交号、环境及每个阶段；只有最终状态为 `passed` 才表示整次成功，`verification.json` 只是逐项计数。直接克隆 Git 仓库即可交付，压缩包是可选副本。具体操作见 [上手指南](getting-started.md)。

[干净目录复现记录](acceptance/reproduction-2026-10-02.md) 对应复现流程提交 `574e31a`，说明了依赖下载缓存方面的限制。之后的接口审计与三个行为修复对应提交 `904a6ac`，其完整验收40阶段全部通过，见 [接口审计结论](api-audit.md) 及 [运行记录](acceptance/api-audit-2026-10-02.json)。两份记录各自绑定提交，不能相互替代。

2026-10-02的惰性接口与专项验证补齐见 [审计更新](api-audit.md#惰性接口与专项验证补齐结果) 和 [验收记录及源码哈希](acceptance/lazy-interfaces-2026-10-02.json)。该次31项仓颉原生测试、2148项接口契约结果及513次字符串起点差分，完整40阶段全部通过。该记录绑定测试时工作区源码，随后统一本地提交。

2026-10-03增量：SetMatches双向迭代与游标复制已完成；完整40阶段验收通过，当前32项仓颉原生测试、2276项接口契约结果和513次字符串起点差分。新增128项集合迭代差分包含在2276中。详见[验收记录](acceptance/set-iterator-2026-10-03.json)。此前PPT及历史报告仍对应各自标注的代码基线。

## 下一次较大交付计划

当前实现已本地提交为`13fb909`。后续拟按[约50%–60%里程碑计划](milestone-50-60-plan.md)推进主要库收口、语法库与基础自动机；该计划尚未执行，目标55%是待盘点锁定的功能权重估算，不是当前完成率。
