# 上手指南：从运行到自己修改

## 1. 环境与目录

仓颉库和例子需要仓颉 1.0.5 SDK（`cjc`、`cjpm`）。带预期结果的演示和验收脚本还需要 Python 3.9+。只有完整 Rust 对照验收需要 Git 和 Rust/Cargo；无需先下载完整 Rust regex 仓库或参考语料。

本版在 Apple Silicon macOS 上验证，其他平台尚未承诺可直接运行。先按 SDK 的安装说明配置环境，把 `CANGJIE_HOME` 指向 SDK 目录。若本机已经有项目同级的 `regex4cj-local/tools/cangjie`，脚本会自动使用，无需重新下载。

从仓库或源码包进入项目根目录：

```sh
cd /你的路径/regex4cj
bash scripts/run.sh help
bash scripts/run.sh demo
```

源码包解压出的目录名为 `regex4cj-0.2.0`，请相应调整 `cd` 路径。命令中的模式用单引号，防止 shell 处理反斜线或 `${prefix}`。

`demo` 会构建仓颉库/CLI，然后运行十个单模式场景与六个分类场景。看到 `10/10 通过` 和 `多规则分类验收：6/6 通过` 就完成第一次端到端运行。每个 PASS 都是程序比较真实输出与独立预期的结果，不是打印好的展示文本。

## 2. 自己动手改变输入

```sh
bash scripts/run.sh find '[A-Z]{2}-[0-9]{3}' 'AB-123 xx CD-456'
bash scripts/run.sh is-match '[A-Z]{2}-[0-9]{3}' 'xx'
bash scripts/run.sh captures '(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})' 'AB-123'
bash scripts/run.sh replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'AB-123 CD-456' '${prefix}-***'
bash scripts/run.sh split '[,;]\s*' 'a, b;c'
```

依次应看到两个订单号、`false`、`prefix=AB` 与 `number=123`、`"AB-*** CD-***"`、三个字段 `"a"` / `"b"` / `"c"`。捕获命令还显示分组 0，它表示完整匹配。

再试试字节偏移：

```sh
bash scripts/run.sh find '\p{Han}+' 'A中文α'
```

输出 `1 7 中文`（字段用 TAB 分隔）。A 占一个 UTF-8 字节，中文共六个字节，所以区间是 `[1,7)`。

没有结果时，`find` 正常退出且没有匹配行；不是执行失败。`(?i)k` 会匹配 `K`，返回的文本仍是原文。不支持的 `(?x)abc` 会打印错误并以退出码 2 结束。

## 3. 修改自己的仓颉调用

打开 `examples/consumer/src/main.cj`。它通过 `cjpm.toml` 的 path 依赖引用库，与 CLI 是两个独立调用者。

```sh
bash scripts/run.sh example
```

你可以只改 `text` 中的订单号，或把 `[0-9]{3}` 改成 `[0-9]{2,4}`，再运行同一命令。不要从自动生成的 Unicode 大表开始阅读。

仓颉原始字符串 `#"\p{Han}+"#` 保留反斜线；`#"${prefix}-***"#` 保留替换模板中的 `$`。普通仓颉字符串会把 `${...}` 当成语言插值，两者不要混淆。

## 4. 验证与报告

```sh
bash scripts/run.sh check
bash scripts/run.sh verify
```

`check` 用于日常试用：27 项原生测试加 16 个场景，完全不启动 Rust。报告中的原生测试应为零失败，场景分别为 10/10 和 6/6。

`verify` 用于严格验收，按锁文件构建固定 Rust 参照，运行数据检查、原生测试和 10,105 条差分用例。首次 Cargo 依赖下载需要网络；后续会利用缓存，整个套件可能持续数分钟。任何一步失败都会返回非零退出码。

默认报告在同级目录 `regex4cj-local/work/`：

- `showcase.json`：十个场景的预期、实际与是否通过。
- `verification.json`：完整差分套件统计，只有整条 verify 命令成功退出才代表本次全部完成。
- `matching-failure.json`：出现差分失败时记录反例；旧文件可能来自历史失败，不能单独据此判断本次状态。

完整验收不代替场景演示，场景演示也不代替完整差分验收。原生 NUL 测试弥补命令行无法传递 NUL 的限制。

## 5. 常见问题

| 现象 | 处理 |
|---|---|
| 找不到 cjc/cjpm | 确认 SDK 已安装，设置 `CANGJIE_HOME`，在 SDK 配好的环境中运行 |
| 找不到 Python | 安装 Python 3.9+；可用 `PYTHON=/绝对路径/python3 bash scripts/run.sh demo` |
| 找不到 Cargo | 仅 `verify` 需要 Rust；先运行 `demo` 或 `check` |
| macOS 链接器不识别 SDK stub | 仓颉 1.0.5 与本机 macOS 26.5 SDK 有兼容问题；脚本优先用已安装的 15.4 SDK，也可自行设置兼容的 `SDKROOT` |
| 直接运行二进制提示动态库缺失 | 使用统一入口，它会加载运行库环境；或在 bash 中 `source scripts/env.sh` 后运行 |
| 模式报 unsupported | 查阅版本边界，例如 i/x/R/u、前后查找和反向引用未支持，不是通过换一种引号就能解决 |
| 库依赖路径错误 | path 指向带 cjpm.toml 的 `port`，相对于调用项目的清单 |

脚本会在构建时显示 cjpm 的进度，但不会自动安装 SDK 或修改你的系统配置。只想看演示，请从 `demo` 开始；无需读完历史研发文档。

## 多规则分类

运行 `bash scripts/run.sh classify '订单 AB-123 退款'` 查看命中编号与标签。配置和 API 说明见 [RegexSet](regex-set.md)。命令按完整规则文件构建，任一规则失败会整体报错。
