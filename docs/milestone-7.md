# 第七步：码点与控制字符转义

新增 `\xNN`（2 位）、`\uNNNN`（4 位）、`\UNNNNNNNN`（8 位），以及三种前缀的花括号形式 `\x{...}` / `\u{...}` / `\U{...}`。十六进制数字大小写均可，花括号内允许前导零，但不能为空或包含空白。新增 `\a`（U+0007）、`\f`（U+000C）、`\v`（U+000B）。

这些转义可直接作为字面量、捕获内容或字符类范围端点，也能与已有集合运算、量词和 m/s/U 标志组合。解码后的标点不会重新作为正则语法解释，例如 `\x{2e}` 匹配字面量点号。

## Unicode 与边界

这是字符串正则的 Unicode 标量语义：`\xFF` 匹配 `ÿ`，UTF-8 长度为 2，不表示任意原始字节。有效码点为 U+0000 至 U+10FFFF，排除 U+D800 至 U+DFFF 代理区。UTF-16 代理对写法不会自动合并。定长形式只读取规定的位数，例如 `\x41B` 匹配 `AB`。

数值逐位解析并检查上界，避免超长数字溢出；不足位数、缺少右括号、非十六进制字符、空括号和无效标量明确报错。模式总长度仍受原有 4096 UTF-8 字节限制。

NUL 可在模式中写成 `\x00`，但操作系统仍不能通过 CLI 参数传递含 NUL 的输入文本。消费包原生测试直接构造 NUL，验证匹配、替换和分割。

## 实现来源

固定上游 commit `72d650cb0a880a01ab6dc2137c0888e8f89740f7` 的 `regex-syntax/src/ast/parse.rs`：`parse_hex`、`parse_hex_digits`、`parse_hex_brace` 和 `parse_escape` 的特殊字符分支。

仓颉 `Parser.hexScalar` 将转义转换为 Rune，复用已有字面量、字符类和 NFA 链路，不新增执行引擎。错误分类和位置仍未逐项对齐 Rust。

## 使用与验证

在 bash 中从仓库根目录执行：

```sh
source scripts/env.sh
cli/target/release/bin/main find '\u4e2d\U0001F642' 'a中🙂b'
cli/target/release/bin/main find '[\x41-\x5A]+' 'aABCz'
```

分别得到 `中🙂 [1,8)` 和 `ABC [1,4)`。命令中的模式使用 shell 单引号。

新增 `tests/verify_escapes.py`：366 条差分用例、22 个非法模式、3 条独立黄金结果、4 项接口对照；消费包新增一项含 NUL 的原生测试。统一入口为 `bash scripts/verify.sh`，本阶段完整差分总数为 5,049，仓颉原生测试 13 项，Rust 原生测试 2 项。

完整 Unicode 属性与大小写折叠、`\d` / `\w` / `\s`、词边界、POSIX 命名字符类、其余标志、bytes 和 RegexSet 仍未实现。下一阶段优先推进命名字符类及 Unicode 数据支持。有限测试不构成整个上游库的等价证明。
