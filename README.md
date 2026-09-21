# regex4cj · v0.1.0

**一个可以运行、验证和学习的仓颉原生正则表达式库。** 将 [Rust regex](https://github.com/rust-lang/regex) 的核心匹配行为移植到仓颉，提供库、命令行入口、调用示例、场景演示和 Rust 差分验证。

本版冻结已实现的功能，形成可交付的学习与演示版本。它不是整个上游仓库的完整转译：支持范围和已知限制见[版本说明](docs/release-0.1.0.md)。匹配过程完全在仓颉中执行，不调用 Rust 或 `std.regex`；Rust 只参与完整差分验收。

## 从这里开始

准备仓颉 1.0.5 SDK 和 Python 3.9+，配置 SDK 环境。然后在仓库根目录执行：

```sh
bash scripts/run.sh demo
```

脚本自动构建，展示九个场景的输入、预期和实际结果。最后应显示 **9/9 通过**。第一次运行、环境配置和故障处理见[上手指南](docs/getting-started.md)。

```sh
# 运行真正导入 cjregex 的仓颉示例；可修改源码再运行
bash scripts/run.sh example

# 自己尝试一个模式
bash scripts/run.sh find '\p{Han}+' 'A中文α'
bash scripts/run.sh replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'AB-123 CD-456' '${prefix}-***'

# 快速验收：20 项仓颉原生测试 + 9 个演示场景，不需要 Rust
bash scripts/run.sh check

# 完整验收：另需 Git、Rust/Cargo；首次获取依赖需要网络
bash scripts/run.sh verify
```

前两个查询分别得到 `中文 [1,7)` 和 `AB-*** CD-***`。查找输出的数字是 **UTF-8 字节偏移**，不是字符序号。替换和分割结果使用带引号的可读形式，便于区分空字符串。

## 建议的阅读顺序

1. [上手指南](docs/getting-started.md)：运行、改输入、理解结果。
2. [学习指南](docs/learning-guide.md)：这个库做什么、从模式到结果如何实现、如何证明当前行为正确。
3. [当前 API](docs/api.md)：在自己的仓颉程序中调用。
4. [版本说明](docs/release-0.1.0.md)：交付内容、支持边界和验收证据。

旧的 `milestone-*.md` 是研发历史，**不需要按顺序读完才能使用**。

## 能做什么

- 查找、判断是否匹配，返回第一条或全部匹配。
- 编号与 ASCII 名称捕获，提取字段、展开模板。
- 模板、字面量和回调替换，以及分割文本。
- 字符类、集合运算、分支、分组、贪婪/非贪婪重复和计数重复。
- 锚点、Unicode 词边界，内联 `m` / `s` / `U` 标志。
- Unicode 16.0.0 的 d/s/w、通用类别、Script/Script_Extensions 和 64 个二元属性。

**本版不支持** `(?i)` 大小写折叠、x/R/u 标志、前后查找、反向引用、任意字节 API、RegexSet、Builder、惰性迭代器及全部上游底层接口。前后查找和反向引用也不属于 Rust regex 的支持范围。未支持的模式应报错，不应当作其他含义执行。

## 作为库依赖

在已有仓颉项目的 `cjpm.toml` 中加入相对路径依赖：

```toml
[dependencies]
cjregex = { path = "../regex4cj/port" }
```

若已经有 `[dependencies]`，只添加其中一行。路径相对调用项目的清单文件，指向本仓库的 `port`。源码使用 `import cjregex.*`；完整例子在 [examples/consumer/src/main.cj](examples/consumer/src/main.cj)。使用仓颉库不需要 Python 或 Rust。

## 交付与验证

本机验证环境为 Apple Silicon macOS、仓颉 1.0.5。完整套件包含 **9,532 条差分用例、20 项仓颉原生测试、2 项 Rust 原生测试和 4 项 Python 数据导入测试**，另有黄金预期和错误检查。通过有限测试不等于完全兼容上游。

构建缓存和报告默认写到同级 `regex4cj-local/`；可用 `REGEX4CJ_LOCAL` 指定其他位置。仓颉构建产物位于各包 `target/`。以上都不进入源码包。

Git 工作区干净后运行 `bash scripts/package.sh`，生成 `dist/regex4cj-0.1.0.tar.gz` 和 SHA-256 文件。源码包包含文档、示例、测试、锁文件、Unicode 数据和许可证，不包含 SDK、完整上游仓库或机器专用配置。解压后依然使用同一套命令。

| 目录 | 用途 |
|---|---|
| `port` | 真正被应用依赖的仓颉静态库 |
| `cli` | 调用库的命令行适配器 |
| `examples` | 仓颉示例、原生测试和演示预期 |
| `oracle` / `tests` | 固定 Rust 参照及差分验收 |
| `scripts` | 统一入口、验收、打包与数据生成 |
| `docs` / `data` | 学习文档、版本记录、可复现 Unicode 数据 |

代码采用 MIT OR Apache-2.0；Unicode 数据保留独立许可证。详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。后续扩展已暂缓，先使用和理解本版，再按实际需要增加功能。
