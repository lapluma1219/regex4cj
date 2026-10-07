# regex4cj

**一个仓颉原生正则表达式库，用规则查找、提取、替换和拆分文本。**

例如，给出规则 `[A-Z]{2}-[0-9]{3}` 和文本 `订单 AB-123 已付款，订单 CD-456 待发货`，就能提取出 `AB-123` 和 `CD-456`。应用程序可以直接导入 `regex4cj` 使用这些能力。

本项目参考 [Rust regex 原仓库](https://github.com/rust-lang/regex) 实现。匹配过程由仓颉代码执行，Rust 仅用于开发时的结果对照。**当前版本不是原仓库所有功能的完整等价替代**，具体支持范围和差异见[当前能力](docs/status.md)。

## 1. 准备环境

本项目已在 **Apple Silicon macOS + 仓颉 STS 1.1.3** 环境验证。其他操作系统尚未完成验证，不能直接视为已支持。

| 你要做什么 | 需要准备什么 |
|---|---|
| 在自己的仓颉程序中引用库 | 仓颉 STS 1.1.3 SDK，包含 `cjc` 和 `cjpm`；对应平台的编译工具 |
| 运行本文的演示命令和仓颉测试 | 上述环境，加 Python 3.9 或更新版本 |
| 执行完整的 Rust/仓颉结果对照 | 上述环境，加 Git、Rust/Cargo；首次下载依赖需要网络 |

macOS 还需安装 Command Line Tools 或提供兼容的系统 SDK。若遇到链接错误，请看[环境与故障处理](docs/getting-started.md)。仓颉 SDK 需自行安装，不包含在本仓库中。

### 获取代码并指定 SDK

```sh
git clone https://github.com/lapluma1219/regex4cj.git
cd regex4cj

# 将下面路径改为你实际安装的仓颉 1.1.3 SDK 目录
export CANGJIE_HOME="/绝对路径/cangjie"

# 检查工具是否能运行，并确认仓颉版本为 1.1.3
bash -c 'source scripts/env.sh; cjc --version; cjpm --version'
python3 --version
```

如果已经下载或解压了源码，直接进入包含本 README 和 `scripts` 的目录即可。**以下命令都在仓库根目录执行。**

`CANGJIE_HOME` 应指向包含 `bin/cjc` 的 SDK 根目录，而不是 `bin` 本身。环境变量只对当前终端及其子进程有效，换一个终端需要重新设置。若已通过 SDK 官方方式配置好环境，也可以使用现有环境。

脚本会加载构建和运行所需的环境。只运行示例不需要安装 Rust，也不需要另外克隆原仓库。

## 2. 运行第一个例子

```sh
bash scripts/run.sh find '[A-Z]{2}-[0-9]{3}' '订单 AB-123 已付款，订单 CD-456 待发货'
```

脚本会先编译命令行程序，然后输出两行匹配结果。每行依次是：**开始位置、结束位置、匹配文本**，字段之间用制表符分隔。

想先看一个位置容易核对的例子，可以运行：

```sh
bash scripts/run.sh find '[A-Z]{2}-[0-9]{3}' 'AB-123 xx CD-456'
```

除构建提示外，应得到：

```text
0       6       AB-123
10      16      CD-456
```

位置从 0 开始，结束位置不包含在匹配内。这里的位置是 **UTF-8 字节偏移**，不是字符序号，所以中文通常占多个位置。没有匹配时，`find` 不输出匹配行，属于正常结果。

### 再试三个常用功能

```sh
# 判断是否匹配：应输出 false
bash scripts/run.sh is-match '[A-Z]{2}-[0-9]{3}' '普通咨询'

# 提取命名字段：prefix 为 AB，number 为 123
bash scripts/run.sh captures '(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})' 'AB-123'

# 保留前缀并隐藏数字：应输出 "AB-*** CD-***"
bash scripts/run.sh replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'AB-123 CD-456' '${prefix}-***'
```

请保留命令中的单引号，尤其是含 `$` 或反斜线的规则、替换模板，避免终端提前解释它们。

更多可运行场景：

```sh
bash scripts/run.sh demo
```

这个命令逐项展示输入、预期结果、实际结果及是否通过。应看到单模式场景 **13/13 通过**，以及**多规则分类验收：7/7 通过**。

## 3. 在仓颉代码中使用

先运行仓库自带的调用示例：

```sh
bash scripts/run.sh example
```

然后打开 [examples/consumer/src/main.cj](examples/consumer/src/main.cj)，修改其中的文本或规则，再执行同一命令。这个程序通过依赖引用本库，演示查找、捕获、替换、分割、中文处理和多规则分类。

最小调用代码如下，放入已有仓颉可执行项目时，保留该项目自己的 `package` 声明：

```cangjie
import regex4cj.*

main(): Unit {
    let rule = Regex("[A-Z]{2}-[0-9]{3}")
    for (m in rule.findAll("订单 AB-123 已付款")) {
        println(m.text)
    }
}
```

输出：

```text
AB-123
```

在你自己的 `cjpm.toml` 中添加路径依赖：

```toml
[dependencies]
regex4cj = { path = "../regex4cj/port" }
```

这个示例假设你的项目目录与 `regex4cj` 目录并列。**依赖路径相对于你自己的 `cjpm.toml`，必须指向本仓库的 `port` 目录。** 如果已有 `[dependencies]`，只追加其中那一行，不要重复创建同名节。配置好后，在自己的项目中执行 `cjpm run`。

仓库名称和导入包名均为 `regex4cj`。直接使用仓颉库不需要 Python 或 Rust；它们用于演示脚本和对照测试。

## 4. 如何确认复现成功

不同命令验证的范围不同，可以按需要选择：

| 命令 | 检查内容 | 成功标志 |
|---|---|---|
| `bash scripts/run.sh example` | 仓颉程序实际引用并调用库 | 示例正常结束，能看到订单提取等结果 |
| `bash scripts/run.sh demo` | 13 个单模式场景和 7 个分类场景 | 分别显示 13/13 和 7/7 通过 |
| `bash scripts/run.sh check` | 仓颉原生测试，加上述演示场景 | 原生测试零失败，演示全部通过 |
| `bash scripts/run.sh coverage` | 在隔离副本中执行完整验收并测量代码执行覆盖（另需 SDK 的 cjcov） | 完整验收通过，生成 `.build/coverage/latest.json` |
| `bash scripts/run.sh verify` | 构建、原生测试、完整批量对照、具名案例与演示 | 命令成功结束，报告的 `status` 为 `passed` |

**首次尝试建议先运行 `example` 或 `demo`，需要完整复现验收时再运行 `verify`。** 完整验收会调用 Cargo，首次可能需要下载依赖；运行时间可能超过十分钟，请等待结束，不要把中间出现的通过提示当成最终结果。

具体检查内容和覆盖率口径见 [测试覆盖说明](docs/test-coverage.md)。

当前测试按 **15 个功能组**组织，包括 **47 个批量回归套件、77 项仓颉原生测试、91 个具名案例**，并检查测试工具自身的行为。这些数字用途不同，不能相加当作功能数，也不代表原仓库的完成百分比。

默认情况下，本次执行结果保存在：

- `.build/work/verification-run.json`：完整验收的最终状态、受测源码哈希、环境和各步骤结果。
- `.build/work/functional-report.md`：按功能查看本次结果。
- `.build/work/feature-cases.json`：具名案例的实际输出与通过情况。

覆盖率命令的详细日志位于 `.build/coverage/latest.log`，报告记录各源码文件未执行的行，以及公开接口是否被执行。它衡量本仓库代码的执行范围，不能解释为原仓库完成度或所有行为组合均已验证。

只有 `verification-run.json` 中的 `status: passed` 才表示整次完整验收通过。仓库中的 [已归档报告](docs/validation/functional.md) 是此前执行的证据，不代替你本机新运行的结果。

原仓库参考语料和 Unicode 数据已包含在仓库内。完整验证不需要本机另存一份原仓库源码；Rust 参考程序由 Cargo 按固定提交和锁文件获取。默认缓存放在 `.build/`，仓颉构建产物放在各包的 `target/`。可通过 `REGEX4CJ_LOCAL` 更改缓存与报告目录，它不是额外源码依赖。

## 5. 功能范围

| 功能 | 主要入口或用途 |
|---|---|
| 查找与判断 | 首次匹配、全部匹配、指定起点、迭代 |
| 捕获与文本处理 | 编号或命名分组、模板/字面量/回调替换、分割 |
| 多规则匹配 | `RegexSet` / `BytesRegexSet` 返回命中的规则编号 |
| 字节与字符处理 | `BytesRegex`、Unicode 16 字符属性、大小写与词边界 |
| 规则配置 | Builder、内联选项、语法及资源限制 |
| 语法和引擎扩展 | 部分 AST/HIR、字面量工具、NFA、PikeVM、回溯及 DFA 接口 |

常用调用见 [API 文档](docs/api.md)。扩展接口存在支持边界，尤其不能将当前 OnePass、Meta、镜像格式等理解为原仓库完整实现，详见[当前能力与差异](docs/status.md)。前后查找和反向引用不在本库支持范围内，Rust regex 原仓库也不支持这两类语法。

多规则分类可以直接体验：

```sh
bash scripts/run.sh classify '订单 AB-123 需要退款，也需要开发票'
```

应返回命中编号 `[0, 1, 2]` 及相应标签。规则和标签配置在 [examples/classification-rules.json](examples/classification-rules.json)，也可以通过 `--rules /路径/rules.json` 使用自己的配置。标签由示例应用提供，库返回规则编号。

## 6. 遇到问题时

| 现象 | 优先检查 |
|---|---|
| 找不到 `cjc` 或 `cjpm` | `CANGJIE_HOME` 是否为正确的 SDK 根目录，SDK 是否为 1.1.3 |
| 找不到 Python | 确认 `python3 --version`；也可用 `PYTHON=/绝对路径/python3 bash scripts/run.sh demo` |
| `verify` 找不到 Cargo | 安装并配置 Rust/Cargo；仅演示和使用仓颉库无需 Rust |
| 提示找不到 `scripts/run.sh` | 是否处于仓库根目录 |
| 自己的程序无法导入 `regex4cj` | 依赖路径是否指向本仓库的 `port`，是否相对于调用方清单填写 |
| 匹配位置看起来比字符数大 | 返回的是 UTF-8 字节偏移 |
| 模式报错或没有结果 | 先用本文固定输入复现，再检查规则、引号和支持范围 |

系统 SDK、动态库、打包以及独立克隆复现的详细说明见[上手与故障指南](docs/getting-started.md)。

## 7. 代码和文档在哪里

| 路径 | 用途 |
|---|---|
| `port/` | 仓颉库源码，应用依赖入口 |
| `cli/` | 命令行演示和测试适配程序 |
| `examples/consumer/` | 可修改的仓颉调用示例与原生测试 |
| `tests/functional/` | 按功能分组的回归测试和具名案例 |
| `tests/upstream/` | 仓库内保存的原仓库参考语料 |
| `oracle/` | 用于对照的固定版本 Rust 程序 |
| `scripts/` | 构建、演示、验收与数据生成入口 |
| `docs/`、`data/` | 使用文档、验收记录与 Unicode 数据 |
| `presentation/` | 项目汇报材料 |

进一步阅读：[学习指南](docs/learning-guide.md)、[测试结构](tests/README.md)、[功能与特性目录](docs/testing.md)、[接口对应审计](docs/api-audit.md)、[语法结构说明](docs/hir.md)。原仓库固定版本记录在 [baseline.json](docs/baseline.json)。

代码采用 MIT OR Apache-2.0，Unicode 数据遵循其独立许可证，见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
