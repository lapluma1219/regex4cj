# v0.3.0 进度

## 0.3.0 交付

三步已经接到同一套标量引擎上：

- 语法：`x`、`R`、字符串安全的 `(?-u)`、八进制、方向性词边界、Unicode 捕获名、累积 Age 和三种 Break 集合。
- 搜索：整段原文上的字节偏移、最短匹配、`next()` 迭代、`staticCapturesLen`、`extract` 和可复用捕获位置。
- Builder：只包装上述选项。`dfaSizeLimit` 和 `sizeLimit` 会失败。默认构造保持原来的 Unicode 开、八进制关、嵌套 64。

原生测试现为 28 项。演示为 13 个单模式场景和 7 个分类场景。包版本是 0.3.0。仍然没有 bytes 引擎和 DFA。

上游抽样 198 条通过、141 条跳过。跳过原因写在 `$REGEX4CJ_LOCAL/work/upstream-sample-skips.json`，包括搜索类型、字节模式、非扁平预期，以及两边都拒绝的模式。标准输出不一致会失败，不会被记成跳过。

`repeat-find` 在一次进程里分开计时。模式 `\p{L}+`、文本为 200 个“字”、查找 40 次：构造约 0.000077 秒，40 次查找合计约 0.0047 秒。8/64/256 条规则的进程耗时仍包含启动，仓颉约 0.030/0.093/0.286 秒，Rust 约 0.008/0.009/0.013 秒。

## 已执行的验证

命令都在 `/Users/jalonyan/Desktop/regex4cj`，并设置 `REGEX4CJ_LOCAL=/Users/jalonyan/Desktop/regex4cj-local`。

| 命令 | 退出码 | 结果 |
|---|---|---|
| `bash scripts/verify.sh` | 1 | 生成表、Rust、原生 28 项、匹配和字符类差分已通过；停在捕获名 `(?<名字>a)`，旧测试仍要求拒绝它 |
| 改为对照 Rust 后，从 `verify_captures.py` 到 `classify.py --demo` | 0 | 捕获差分 879，Unicode 名 2；演示 13/13，分类 7/7 |
| 同上批次中的 `verify_upstream_sample.py` | 0 | 198 通过，141 跳过 |
| 补上进程内计时后的 `python3 tests/verify_sets.py` | 0 | RegexSet 差分 573；构造与 40 次查找已分开记录 |

`verify.sh` 前半段和后半段合起来覆盖整套入口。捕获名那一次失败是测试还把已实现的 Unicode 名字当成非法模式，不是匹配结果不一致。

# v0.3.0 早期记录

以下是做到 `(?i)` 时留下的记录。当时工作区版本号仍是 0.2.0，上面的交付已经取代这里的“尚未完成”。

## 当前代码

- 接手时引擎在 `f343ef9`（v0.2.0），其后只有交接文档 `81db1a3`。
- 分支 `main` 比记录中的 `origin/main`（`130c8c9`）超前。本轮没有访问 GitHub，也没有推送。
- 本文件与大小写折叠、契约清单在同一次本地提交中。提交后应用 `git status` 确认工作区是否干净。

## 本轮完成

- 工作包 A：`docs/api-coverage.md` 列出字符串 Regex、RegexSet、Match、Captures、CaptureLocations、迭代器、替换、Builder 和 Error 的归属。bytes、DFA 和底层公开类型标为本版排除。
- 内联 `i` 的 Unicode 简单大小写折叠。折叠表来自固定上游 `case_folding_simple.rs`，Unicode 16.0.0，2938 个标量。
- 字面量、字符类、POSIX 类和 `\p` 会折叠。`\d` / `\w` / `\s` 本身不额外折叠；它们在字符类里会随整个类再过一次折叠，与上游一致。
- 取反和 `&&` / `--` / `~~` 之前先折叠。
- 捕获文本保持原文。

## 尚未完成

- 工作包 B：批量验证通道。现有单次进程对照仍在使用。
- `x`、`R`、`u`、八进制、方向性词边界、Unicode 捕获名、Age/Break。
- `(?-u)` 下的 ASCII 大小写折叠。不单独打开半套 `u`，避免 Unicode 已关但 `\w` 仍按 Unicode 解释。
- 起点搜索、`shortest_match`、惰性迭代、捕获工作区、Builder。
- 上游语料审计、分离式性能基准、v0.3.0 源码包。

## 已执行的验证

命令都在 `/Users/jalonyan/Desktop/regex4cj`，并设置 `REGEX4CJ_LOCAL=/Users/jalonyan/Desktop/regex4cj-local`。本机环境变量若指向 `/Users/jalonyan/regex4cj-local`，那里没有仓颉 SDK。

| 命令 | 退出码 | 结果 |
|---|---|---|
| `cjpm build`（port、cli） | 0 | 成功 |
| `examples/consumer` 的 `cjpm test` | 0 | 27 项通过，含 `simpleCaseFoldingKeepsOriginalText` |
| `python3 tests/verify_case.py` | 0 | 721 条差分、7 条黄金预期、2 条非法模式 |
| `bash scripts/verify.sh` | 1 | 差分、原生测试和 RegexSet 已通过；停在旧演示场景，该场景仍要求拒绝 `(?i)` |
| 更新场景后的 `python3 scripts/showcase.py` | 0 | 10/10 通过 |

`verify.sh` 的失败不是匹配结果不一致。场景 9 原来把 `(?i)abc` 当作必须报错；实现折叠后它正确返回 `ABC`。预期已改为：场景 9 接受 `(?i)abc` 且保留原文，场景 10 拒绝仍未实现的 `(?x)`。这次没有为了刷新退出码而把整套差分再跑一遍。`tests/verify_binary.py` 里的范围说明已改成包含简单大小写折叠；磁盘上的 `verification.json` 要等下一次跑到该脚本才会更新这句话。

## 下一步

按交接顺序继续工作包 B 或 C 的剩余部分：`x` 与 `R`。不要先公开一个多数选项无效的 Builder。
