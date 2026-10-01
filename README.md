# regex4cj · v0.3.0

**一个可以运行、验证和学习的仓颉原生正则表达式库。** 将 [Rust regex](https://github.com/rust-lang/regex) 的字符串匹配行为移植到仓颉，提供库、命令行入口、调用示例、场景演示和 Rust 差分验证。

它复刻固定上游 `regex` 包的字符串和 bytes 行为。匹配在仓颉里完成，Rust 只参与对照。现在做到哪、还差什么，见[现状](docs/status.md)。

## 从这里开始

准备仓颉 1.0.5 SDK 和 Python 3.9+，配置 SDK 环境。然后在仓库根目录执行：

```sh
bash scripts/run.sh demo
```

脚本自动构建，展示十三个单模式场景与七个分类场景的输入、预期和实际结果。最后应显示 **13/13 通过**与**多规则分类 7/7 通过**。第一次运行、环境配置和故障处理见[上手指南](docs/getting-started.md)。

```sh
# 运行真正导入 cjregex 的仓颉示例；可修改源码再运行
bash scripts/run.sh example

# 自己尝试一个模式
bash scripts/run.sh find '\p{Han}+' 'A中文α'
bash scripts/run.sh replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'AB-123 CD-456' '${prefix}-***'

# 快速验收：29 项仓颉原生测试 + 20 个演示场景，不需要 Rust
bash scripts/run.sh check

# 完整验收：另需 Git、Rust/Cargo；首次获取依赖需要网络
bash scripts/run.sh verify
```

前两个查询分别得到 `中文 [1,7)` 和 `AB-*** CD-***`。查找输出的数字是 **UTF-8 字节偏移**，不是字符序号。替换和分割结果使用带引号的可读形式，便于区分空字符串。

## 建议的阅读顺序

1. [上手指南](docs/getting-started.md)：运行、改输入、理解结果。
2. [学习指南](docs/learning-guide.md)：这个库做什么、从模式到结果如何实现、如何证明当前行为正确。
3. [当前接口](docs/api.md)：查找、捕获、替换、分割、Builder、字节接口和 RegexSet。
4. [现状](docs/status.md)：已经实现什么，距离复刻整个上游仓库还差什么。固定提交在 [baseline.json](docs/baseline.json)。

## 多规则文本分类

```sh
bash scripts/run.sh classify '订单 AB-123 需要退款，也需要开发票'
```

输出命中编号 `[0, 1, 2]` 及退款、发票、订单号标签。`ERROR disk full` 还会命中不区分大小写的“错误日志”规则。修改 `examples/classification-rules.json` 或使用 `--rules /路径/rules.json` 即可换规则。RegexSet 返回规则编号，标签由演示应用配置。

## 能做什么

- 多规则统一匹配、判断哪些规则命中、按编号返回结果。

- 查找、判断是否匹配，返回第一条或全部匹配。
- 编号与 ASCII 名称捕获，提取字段、展开模板。
- 模板、字面量和回调替换，以及分割文本。
- 字符类、集合运算、分支、分组、贪婪/非贪婪重复和计数重复。
- 锚点、Unicode 词边界，以及内联 `i` / `m` / `s` / `U` / `x` / `R` / `u`。
- Unicode 简单大小写折叠。匹配文本保持原样；`ß` 不会展开成两个字符的 `SS`。关掉 Unicode 后，大小写只折叠 A–Z。
- 从原文字节偏移继续搜索，并提供最短匹配、`next()` 迭代、固定捕获数量和可复用捕获位置。
- `RegexBuilder` / `RegexSetBuilder`。八进制和自定义行终止符只在 Builder 上打开。嵌套默认 250，`sizeLimit` 默认约 10 MiB，按 Thompson 构造字节数检查。语法错误和编译超限的文本与固定上游 Display 相同。`dfaSizeLimit` 只影响字符串搜索缓存，不改变匹配文本。
- Unicode 16.0.0 的 d/s/w、通用类别、Script/Script_Extensions、二元属性，以及 Age 与三种 Break 的集合查询。

字符串接口只接受合法 UTF-8。字节接口是 `BytesRegex` 和 `BytesRegexSet`。没有 lazy DFA。前后查找和反向引用会报错，上游也会拒绝它们。regex-syntax / regex-automata 的公开类型没有移植。接口见 [当前接口](docs/api.md)。

## 作为库依赖

在已有仓颉项目的 `cjpm.toml` 中加入相对路径依赖：

```toml
[dependencies]
cjregex = { path = "../regex4cj/port" }
```

若已经有 `[dependencies]`，只添加其中一行。路径相对调用项目的清单文件，指向本仓库的 `port`。源码使用 `import cjregex.*`；完整例子在 [examples/consumer/src/main.cj](examples/consumer/src/main.cj)。使用仓颉库不需要 Python 或 Rust。

## 交付与验证

本机验证环境为 Apple Silicon macOS、仓颉 1.0.5。验收范围和条数见 [现状](docs/status.md)。完整数字以最近一次 `bash scripts/run.sh verify` 写入的报告为准。通过有限测试不等于完全兼容上游。数字记录的是已经跑过的检查，不是完成百分比。

构建缓存和报告默认写到同级 `regex4cj-local/`；可用 `REGEX4CJ_LOCAL` 指定其他位置。仓颉构建产物位于各包 `target/`。以上都不进入源码包。

Git 工作区干净后运行 `bash scripts/package.sh`，生成 `dist/regex4cj-0.3.0.tar.gz` 和 SHA-256 文件。源码包包含文档、示例、测试、锁文件、Unicode 数据和许可证，不包含 SDK、完整上游仓库或机器专用配置。解压后依然使用同一套命令。

| 目录 | 用途 |
|---|---|
| `port` | 真正被应用依赖的仓颉静态库 |
| `cli` | 调用库的命令行适配器 |
| `examples` | 仓颉示例、原生测试和演示预期 |
| `oracle` / `tests` | 固定 Rust 参照及差分验收 |
| `scripts` | 统一入口、验收、打包与数据生成 |
| `docs` / `data` | 学习文档、版本记录、可复现 Unicode 数据 |

代码采用 MIT OR Apache-2.0；Unicode 数据保留独立许可证。详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。后续扩展已暂缓，先使用和理解本版，再按实际需要增加功能。
