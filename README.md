# regex4cj

将 [rust-lang/regex](https://github.com/rust-lang/regex) 逐步移植到仓颉语言，通过原版 Rust 实现进行差分验证。

目前是最小可验证原型，**尚不是完整正则表达式库**。

## 当前实现

- 仓颉原生 `escape` 和辅助函数 `isMetaCharacter`，不调用 Rust 或 `std.regex`。
- Rust 参照程序：转义、查找、订单字段捕获及替换演示。
- 336 条转义差分用例、4 条字面值匹配验证。
- 6 条匹配行为参照用例目前只在 Rust 上执行，不能算作仓颉引擎通过。
- 尚未实现正则解析、NFA/PikeVM、捕获、替换、bytes 和 RegexSet。

例如，两个程序都将 `a+b.txt` 转换成 `a\+b\.txt`，使其能作为正则中的字面值。

## 环境与运行

准备 Git、Rust/Cargo、仓颉 1.0.5 SDK（`cjc`、`cjpm`）和 Python 3.6+。
先按仓颉官方安装说明配置 SDK 环境，并将 `CANGJIE_HOME` 指向 SDK 根目录（用于定位运行库），然后：

```sh
git clone https://github.com/lapluma1219/regex4cj.git
cd regex4cj
bash scripts/verify.sh
bash scripts/demo.sh
```

首次构建需要网络，Cargo 会根据已提交的锁文件获取依赖。Rust 参照程序固定依赖原库 commit `72d650cb0a880a01ab6dc2137c0888e8f89740f7`。

脚本默认将 Rust 构建缓存与测试报告写入项目同级的 `regex4cj-local/`。可以通过 `REGEX4CJ_LOCAL` 指定其他目录。仓颉生成的 `port/target/` 已加入 `.gitignore`。`PYTHON` 可以指定 Python 可执行文件。

本机已有的隔离工具链位于 `regex4cj-local/tools/`，脚本检测到后会使用它们；其他机器可以直接使用已配置在 PATH 中的工具链。

已验证平台：Apple Silicon macOS、仓颉 1.0.5、Rust 1.98.1。仓颉自带旧链接器不兼容 macOS 26.5 SDK；脚本在未指定 SDKROOT 时优先使用已有的 macOS 15.4 SDK。其他平台尚未验证，需按平台配置 SDK 环境。

## 手工实验

进入 bash，加载环境并完成构建后：

```sh
source scripts/env.sh
"$CARGO_TARGET_DIR/debug/regex-oracle" find '[A-Z]{2}-[0-9]{3}' 'order=AB-123; order=CD-456'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '中' 'a中b'
"$CARGO_TARGET_DIR/debug/regex-oracle" escape 'a+b.txt'
port/target/release/bin/main escape 'a+b.txt'
```

查找结果每行依次为起始字节偏移、结束字节偏移和匹配文本。`中` 在 `a中b` 中的区间为 `[1,4)`。

测试报告位于 `$REGEX4CJ_LOCAL/work/verification.json`。CLI 不支持传入 NUL，当前未覆盖这个边界。有限用例通过不能证明整个库等价。

## 仓库结构

| 目录 | 内容 |
|---|---|
| port | 仓颉源码和 cjpm 配置 |
| oracle | Rust 参照程序与固定依赖 |
| tests | 差分测试及匹配验收用例 |
| scripts | 环境、构建和演示入口 |
| docs | 上游版本记录、工具评估 |

完整上游仓库、参考语料、SDK、下载文件和缓存均不随本仓库发布。开发机将它们保存在同级的 `regex4cj-local/`，运行当前测试不需要参考语料。

## 下一步

打通 AST/HIR → Thompson NFA → 搜索，先支持字面量、连接、分支与简单重复，再将匹配用例接入仓颉实现。未支持语法应明确报错。

## 来源与许可

MIT OR Apache-2.0。移植代码保留上游版权声明与许可证，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)、[LICENSE-MIT](LICENSE-MIT)、[LICENSE-APACHE](LICENSE-APACHE)。
