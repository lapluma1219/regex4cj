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

源码包解压出的目录名为 `regex4cj-0.3.0`，请相应调整 `cd` 路径。命令中的模式用单引号，防止 shell 处理反斜线或 `${prefix}`。

`demo` 会构建仓颉库/CLI，然后运行十三个单模式场景与七个分类场景。看到 `13/13 通过` 和 `多规则分类验收：7/7 通过` 就完成第一次端到端运行。每个 PASS 都是程序比较真实输出与独立预期的结果，不是打印好的展示文本。

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

没有结果时，`find` 正常退出且没有匹配行；不是执行失败。`(?i)k` 会匹配 `K`，返回的文本仍是原文。`(?x)a b` 会匹配 `ab`。不支持的 `(?=a)` 会打印错误并以退出码 2 结束。

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

`check` 用于日常试用：31 项原生测试加 20 个场景，完全不启动 Rust。报告中的原生测试应为零失败，场景分别为 13/13 和 7/7。

`verify` 用于严格验收，按锁文件构建固定 Rust 参照，运行数据检查、原生测试和差分用例。首次 Cargo 依赖下载需要网络；后续会利用缓存，整个套件可能持续数分钟。任何一步失败都会返回非零退出码。验收范围见 [现状](status.md)。本次跑过的条数以 `verification.json` 为准。

默认报告在同级目录 `regex4cj-local/work/`：

- `showcase.json`：单模式场景的预期、实际与是否通过。
- `verification-run.json`：整次验收的提交号、工作区状态、工具版本、阶段结果和最终状态。只有 `status: passed` 代表完成；`running` 也可能表示被强制中断，不能算通过。源码包无 Git 信息时提交号为空。
- `verification.json`：本次差分套件计数，中途失败时可能不完整。完整验收开始先清除旧计数与旧反例。
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
| 模式报错 | 前后查找和反向引用会报错。字符串 `Regex` 拒绝非法 UTF-8，以及会匹配到非法 UTF-8 的模式。原始字节用 `BytesRegex`。详见 [现状](status.md) |
| 库依赖路径错误 | path 指向带 cjpm.toml 的 `port`，相对于调用项目的清单 |

脚本会在构建时显示 cjpm 的进度，但不会自动安装 SDK 或修改你的系统配置。只想看演示，请从 `demo` 开始；无需读完历史研发文档。

## 多规则分类

运行 `bash scripts/run.sh classify '订单 AB-123 退款'` 查看命中编号与标签。接口见 [当前接口](api.md)。命令按完整规则文件构建，任一规则失败会整体报错。

## 6. 从 GitHub 独立复现

推荐直接克隆仓库作为交付文件夹，不必下载压缩包：

```sh
git clone https://github.com/lapluma1219/regex4cj.git
cd regex4cj
```

完整验收的 25 份上游测试数据在 `tests/upstream/`，含固定提交、哈希和许可证，脚本首先检查数据完整性。不需要原来的 `regex4cj-local/upstream/regex`，也不需要 CangjieSkills 或 CangjieCorpus。

环境要求：Apple Silicon macOS、仓颉 1.0.5（cjc/cjpm）、兼容的 macOS SDK、Python 3.9+；完整验收另需 Git 和 Rust/Cargo。当前开发验收使用 Rust 1.98.1；Rust 参照固定在 `oracle/Cargo.toml` 的 rev，并使用 `Cargo.lock` 和 `--locked`。首次构建需要访问 GitHub 和 Cargo 依赖源。本项目不承诺离线首次构建或其他操作系统。

`REGEX4CJ_LOCAL` 是可重建的缓存与报告目录，可以指定新位置。使用新目录前，请先配置工具 PATH，并显式设置 `CANGJIE_HOME`；SDK 安装目录与缓存目录不是一回事。

```sh
export CANGJIE_HOME=/你的/仓颉SDK目录
export REGEX4CJ_LOCAL=/你的/新缓存目录
bash scripts/run.sh demo
bash scripts/run.sh example
bash scripts/run.sh check
bash scripts/run.sh verify
```

检验交付时，应从待验收提交创建新的克隆目录，使用空的 REGEX4CJ_LOCAL、CARGO_HOME 和构建目录，保留 `verification-run.json` 与完整日志。工具链可以复用已安装版本，这与全新操作系统验证不同。不要复制旧 target 或旧上游检出。验收失败时，先查看报告最后一个阶段和日志。
