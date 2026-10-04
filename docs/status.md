# 现状

本次复核见 [2026-10-04 复查结论](review-2026-10-04.md)。AST/HIR 和前向 PikeVM 已有可用增量，但原计划未完整完成，旧记录中的 52 分不能作为已经审计通过的完成率。后续规划见 [约80%路线](milestone-80-plan.md)。

此前[1.1.3适配](acceptance/cangjie-1.1.3-2026-10-04.md)、[追加展开与构造](acceptance/append-builder-2026-10-04.md)、[捕获组游标](acceptance/group-cursor-2026-10-04.md)各自保留原有验证范围，不混用结果。

这一份说明当前仓库做到哪里。包版本号仍是 `0.3.0`，那只是 `port/cjpm.toml` 里的号码。中间版本的发布说明已经删除，不要把它们当成现在的边界。

目标是复刻固定原仓库的行为，不添加原仓库没有的功能。原仓库是 [rust-lang/regex](https://github.com/rust-lang/regex) 提交 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`（regex 1.13.1，Unicode 16.0.0），记在 [baseline.json](baseline.json)。匹配只在仓颉里做。Rust 只用来对照。

## 已经实现

主体是主要 `regex` 库的字符串接口和bytes接口，另外已新增[公开HIR切片](hir.md)，可以读取和构造部分正则语法结构；尚不是整个原仓库。

调用方可以用 `import cjregex.*` 做这些事：

- `Regex` / `BytesRegex`：查找、判断是否匹配、捕获、替换、分割，以及从原文偏移继续搜索。
- `Hir`：解析或构造空、字面量、字符类、断言、重复、捕获、连接和分支。点号会转成对应字符类。`toPattern()` 打印可再次解析的模式，`visit` 按前序遍历。字符类可以做并、交、差、取反和简单大小写折叠。属性除了最短和最长字节长度，还有是否总是匹配合法 UTF-8、显式捕获数、静态捕获数、是否为字面量或字面量分支，以及断言集合。
- `Ast`：解析具体语法。`a`、`(?:a)` 和 `[a]` 保持不同节点。`\d`、`\s`、`\w`、`\p` 和转义字面量也保留原来的写法。可以读跨度、遍历、打印。`toHir()` 按内联标志作用域降到 HIR：`(?i:a)` 会做大小写折叠，`(?m)^` 变成行首断言，`(?U)a?` 的语法树仍记为贪婪，降级后才变成非贪婪。`(?x:)` 里的空白和 `#` 注释不进入子节点，连接节点的跨度仍含这段空白。
- `PikeVM`：对一条或多条模式，或对已经得到的 `Hir`，做前向 Thompson 搜索。调用方给出全文和搜索范围；锚定表示只从范围起点尝试，和模式里的 `^` 不是一回事。范围外的文字仍参与断言。结果含模式编号、绝对字节跨度和捕获。`reset()` 清掉上次写入缓存的捕获。可以读取每个模式的状态数、起点和指令名。状态编号是本实现自己的，不承诺与原仓库相同。`searchEarliest` 在第一次接受时返回跨度，`whichOverlapping` 返回命中的模式编号。后者仍是每条模式各搜一次。没有 quit。不要把这两项说成 `Regex.find` 的结果。
- `ReverseNfa`：把模式按反向 Thompson 结构编译，从文本末尾向左匹配。多字节字符按 UTF-8 字节倒序消耗，不是把字符串倒过来。`search` 返回匹配起点的字节偏移。捕获组不参与这次搜索。
- `BoundedBacktracker`：在同一份前向 Thompson 状态上做有访问表的回溯。捕获会在失败分支上恢复。默认访问容量是 256 KiB。表装不下时 `search` 抛出 `haystack of length N is too long`，这不是“没有匹配”。`maxHaystackLen()` 用本实现的状态数套用原仓库公式，数字不必和原仓库相等。它不是 `Regex.find`，也不是 DFA。
- `DenseDfa` / `SparseDfa`：单条模式的字节子集 DFA。密集表按字节下标转移，稀疏表按连续字节区间转移。`search` 返回字节跨度，不返回捕获。Unicode 词边界和 CRLF 锚点在构造时失败。状态数超过 8192 时构造失败。匹配终点来自这份 DFA，起点来自该终点之前的反向 NFA。没有 quit，没有多模式，也没有重叠搜索。`Regex.find` 不走这里。
- `SyntaxParser`：用 Unicode、大小写、多行、点号、CRLF、忽略空白、八进制、嵌套上限等配置解析 AST 或 HIR。翻译 AST 时会带上 `utf8`。`(?-u:\xFF)`、`(?-u:.)` 和未知属性可以先形成语法树，再在翻译阶段拒绝。`Regex.find` 仍走原来的解析器。
- `RegexSet` / `BytesRegexSet`：回答哪些模式命中。不返回位置和捕获。
- `RegexBuilder` 和对应的 Set、bytes Builder：Unicode、大小写、多行、点号、CRLF、忽略空白、八进制、行终止符、嵌套上限、`sizeLimit`、`dfaSizeLimit`。
- Unicode 16.0.0 的 `\d` `\s` `\w`、通用类别、Script、Script_Extensions、二元属性、简单大小写折叠，以及 Age 和三种 Break 的集合成员查询。
- 语法错误和编译超限抛 `RegexError`。`toString()` 与原仓库 Display 相同。超限句是 `Compiled regex exceeds size limit of N bytes.`

字符串引擎按 Unicode 标量扫描，再换算成 UTF-8 字节偏移。字节引擎按原始字节扫描，输入可以不是合法 UTF-8。`(?-u).` 在字节接口上匹配一个字节，在字符串接口上构造失败。

`Regex.find` 仍是有序 PikeVM。`dfaSizeLimit` 只决定字符串搜索要不要用一块步进缓存；小于 128 时不用。匹配文本不变。没有 lazy DFA，字节搜索不读这个限额。`BoundedBacktracker` 是另一条搜索，不读 `dfaSizeLimit`。

接口写法在 [api.md](api.md)。怎么运行在 [getting-started.md](getting-started.md)。

## 怎么确认它和原仓库一致

原仓库 `regex` 包自己会断言的测试，已经用固定 Rust 和仓颉对过：

- `tests/suite_string.rs`、`suite_bytes.rs`、`suite_string_set.rs`、`suite_bytes_set.rs` 真正执行的题，共 3213 条。入口是 `tests/verify_upstream_suite.py`。
- `tests/regression.rs` 和 `tests/replace.rs` 里的手写行为用例。

这些题覆盖 `is_match`、`find`、`captures`，以及 RegexSet 的命中编号。同一条模式、同一段文本，两边的区间和捕获一致；该拒绝编译的也会拒绝。

这是顶层 `regex` 包的验收线，不是每一条可以写出来的正则都已被证明，也不是整个原仓库仓库的全部测试。原仓库自己会跳过的题不在这 3213 条里，例如单条 `Regex` 的重叠搜索、不限次数的锚定搜索，以及 `regex-lite`。

`bash scripts/run.sh verify` 还会跑本仓库自己的差分。报告在 `$REGEX4CJ_LOCAL/work/verification.json`。里面的条数是已经跑过的检查，不是完成百分比。

## 调用形式上的差别

这些不影响把结果收集出来之后的内容：

- 失败抛 `Exception`。语法错误和编译超限是 `RegexError`。越界起点、负数限额抛普通 `Exception`。合法范围的字符内部起点会继续搜索；Rust 无符号参数不接受负数，越界起点按原仓库契约可 panic。
- 没有 `regex!`，也没有 `Iterator`、`Replacer`、`FromStr`、`Debug` 这些 trait。对应的是 `next()`、数组和 `replaceWith`。
- `expand` 返回新内容；`expandInto` 可向现有缓冲区追加。`SetMatches.indices()` 返回升序数组，`iter()` 支持双向逐项读取和独立游标复制。
- 字符串 `isMatch` 会先做出一条完整匹配，再变成布尔值；bytes 有早停路径。

## 顶层接口仍存在的差异

见 [接口审计](api-audit.md) 和 [逐项对应表](api-audit-methods.md)。bytes 惰性迭代、两类输入的惰性 splitN 已补齐；原先列出的 bytes 辅助方法与 Builder 组合已补专项验证。宏和部分语言集成仍缺失；Builder 资源语义、所有权和分配行为不完全等价。有限组合测试不表示任意输入都已证明。

## 距离 100% 复刻还差什么

原仓库是一个 workspace。顶层 `regex` 只是其中一层。下列部分仍未完整移植：

| 原仓库 | 里面有什么 |
|---|---|
| `regex-syntax` | 已有 HIR 八类节点、点号转换、Display 打印、属性查询、带标志作用域的具体语法降级、`&&`/`--`/`~~` 类集合，以及 `[:digit:]` / `[:^alpha:]` 这种 POSIX 具名类节点。语法错误除 Display 文本外，还有种类、主位置和辅助位置。默认限额的前缀/后缀字面量提取，以及公开 UTF-8 区间工具，已与 `regex-syntax` 对照。`memory_usage` 这种 Rust 堆大小查询还没有 |
| `regex-automata` | 已有包装式前向 PikeVM 搜索、从右向左的反向搜索、有访问表的有界回溯，以及单模式的密集/稀疏 DFA 跨度。反向搜索的结果是匹配起点，捕获省略。有界回溯在预算不足时报错。DFA 在 Unicode 词边界上构造失败。quit、多模式 DFA、重叠搜索、lazy DFA、one-pass、meta 和预过滤还没有 |
| `regex-lite` | 另一套更小的引擎 |
| `regex-capi` | C 接口 |
| `regex-cli`、`regex-test` | 原仓库的命令行和测试驱动。本仓库有自己的对照 CLI 和 Python 差分 |

`regex-automata` 里还有两种不同的差距：

- **换搜索方法。** 预过滤、one-pass、lazy DFA 还没有。反向搜索、有界回溯，以及单模式密集/稀疏 DFA 已经可以单独调用。顶层 `Regex.find` 仍是原来的匹配器。`dfaSizeLimit` 仍只是字符串步进缓存的预算，不是这份 DFA 的限额。
- **换一种问法。** 重叠匹配仍然没有。锚定搜索和多模式的位置、捕获已经可以从 `PikeVM` 得到，它们和顶层 `Regex.find` 不是同一个问题。`Regex.find` 仍固定是不锚定、最左优先、不重叠。

前后查找、反向引用、全量大小写折叠、用 Break 属性做分词或 `\X`，固定原仓库的字符串接口也没有。原仓库会拒绝前后查找和反向引用，这里同样拒绝。这些不是缺口。原仓库固定版本的 `MatchKind` 仅公开 `All` 与 `LeftmostFirst`；`LeftmostLongest` 只是源码注释讨论的可能扩展，不能列为待移植的已有能力。

## 还需要补充的内容

2026-10-03起，目标扩展为对齐整个原仓库，工作路线见[完整行为对齐计划](full-compatibility-plan.md)。本轮已增加SetMatches的双向编号迭代和独立游标复制；其余引擎与底层库仍未完成。

- 速度工作还没做。要做的话，先做 lazy DFA、字面量预过滤和反向自动机，因为那是顶层 `regex` 的快路径。不要为了变快去改已经对过的匹配文本。
- `PikeVM.whichOverlapping` 只返回命中的模式编号，不枚举重叠区间。锚定和多模式位置已经在 `PikeVM` 上，不要把它们的结果说成 `Regex.find` 的结果。
- 当前适配目标为Apple Silicon、仓颉1.1.3，按赛事要求替换原1.0.5基线；Rust regex和Unicode版本保持固定。构建用 `cjpm build`，不要加 `--release`。生成缓存默认在仓库内 `.build/`，SDK 通过环境显式配置；不自动查找同级目录。
- 负数限额的报错里保留 “nonnegative”。语法错误和超限的 `toString()` 继续对齐原仓库 Display。
- 通过有限测试不等于任意输入都已证明。新增行为要用固定 Rust 对照，不要只看仓颉自己的预期。

## 复现与交付

原仓库验收数据已收录到 `tests/upstream/`，完整验收不需要外部原仓库检出。`verification-run.json` 记录提交号、环境及每个阶段；只有最终状态为 `passed` 才表示整次成功，`verification.json` 只是逐项计数。直接克隆 Git 仓库即可交付，压缩包是可选副本。具体操作见 [上手指南](getting-started.md)。

[干净目录复现记录](acceptance/reproduction-2026-10-02.md) 对应复现流程提交 `574e31a`，说明了依赖下载缓存方面的限制。之后的接口审计与三个行为修复对应提交 `904a6ac`，其完整验收40阶段全部通过，见 [接口审计结论](api-audit.md) 及 [运行记录](acceptance/api-audit-2026-10-02.json)。两份记录各自绑定提交，不能相互替代。

2026-10-02的惰性接口与专项验证补齐见 [审计更新](api-audit.md#惰性接口与专项验证补齐结果) 和 [验收记录及源码哈希](acceptance/lazy-interfaces-2026-10-02.json)。该次31项仓颉原生测试、2148项接口契约结果及513次字符串起点差分，完整40阶段全部通过。该记录绑定测试时工作区源码，随后统一本地提交。

2026-10-03增量：SetMatches双向迭代与游标复制已完成；完整40阶段验收通过，当前32项仓颉原生测试、2276项接口契约结果和513次字符串起点差分。新增128项集合迭代差分包含在2276中。详见[验收记录](acceptance/set-iterator-2026-10-03.json)。此前PPT及历史报告仍对应各自标注的代码基线。

## 里程碑复核

主要匹配层、AST/HIR、前向 PikeVM 已经有可运行成果；这不等于完整移植三个模块。复查指出的三处语法缺口已经补上：`Ast.parse` 不再先调用匹配解析器，`(?-u:\xFF)` 和 `\p{NotAProperty}` 可以先得到语法树，再由翻译按 `utf8` 决定是否拒绝；字符类子项带有各自的字节跨度和字面量来源，并进入 AST 差分。`PikeVM` 仍是逐条 `Regex` 搜索，`PikeCache` 仍只保存上次捕获，不是搜索线程队列。计分台账见 [功能台账](coverage/README.md)。目前 B5、C2b 和 D4 验收通过，合计 6 分。重叠模式编号和 earliest 跨度已对照，但 quit 还没有，重叠搜索仍是逐条模式进行，这两项不计分。反向搜索对照的是反向 DFA 的起点；Unicode 词边界会被那份 DFA 拒绝，所以不在这组成绩里。有界回溯对照的是 `BoundedBacktracker` 的跨度、捕获和预算报错。单模式 DFA 的密集表和稀疏表已经对照过跨度，缺 quit、多模式和重叠，这 6 分不计。混合 DFA 没有做。不发布约 80%。详见 [复查结论](review-2026-10-04.md)。这次增量没有重跑完整 `scripts/verify.sh`。
