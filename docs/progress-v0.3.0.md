# v0.3.0 进度

工作区版本号仍是 0.2.0。本文件记录走向 v0.3.0 的增量，不把尚未完成的 Builder、起点搜索或惰性迭代算作该版本已交付。

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
