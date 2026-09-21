# 第八步：POSIX 命名字符类

支持上游的全部 14 种 POSIX ASCII 名称，可在方括号内使用，也可参与嵌套、并集、交集、差集和对称差。

| 名称 | 字符范围 |
|---|---|
| alnum | ASCII 数字和字母 |
| alpha | A–Z、a–z |
| ascii | U+0000–U+007F |
| blank | TAB、空格 |
| cntrl | U+0000–U+001F、U+007F |
| digit | 0–9 |
| graph | U+0021–U+007E |
| lower | a–z |
| print | U+0020–U+007E |
| punct | ASCII 标点，含下划线 |
| space | U+0009–U+000D、空格 |
| upper | A–Z |
| word | ASCII 字母、数字、下划线 |
| xdigit | 0–9、A–F、a–f |

`[[:digit:]]` 只匹配 ASCII 数字，不匹配全角数字或阿拉伯文数字。`[[:alpha:]]` 不匹配中文或 é。这些定义与操作系统区域设置无关，也不等同于尚未实现的 Unicode `\d`、`\w`、`\s`。

`[[:^digit:]]` 对 digit 在整个 Unicode 标量集合中取反，因而可以匹配中文、emoji 和 NUL。`[^[:digit:]]` 是对应的外层取反写法。代理区仍从标量集合中排除。

## 解析细节

命名类只在字符类内部识别，需要双层方括号。`[:digit:]` 是包含冒号和字母的普通字符类。按上游的回退规则，拼错的 `[[:digitt:]]` 也作为普通嵌套类解析；并非所有看似命名类的错误都会报错。已识别的 `[[:digit:]` 缺少外层右括号则会报错。命名类不是单个字符，不能作为 `a-[:digit:]` 的范围终点。

## 实现来源

固定上游 commit `72d650cb0a880a01ab6dc2137c0888e8f89740f7`：

- `regex-syntax/src/ast/parse.rs` 的 `maybe_parse_ascii_class`：不成功时恢复普通字符类解析的规则。
- `regex-syntax/src/hir/translate.rs` 的 `ascii_class`：14 种名称的精确区间表。

`ascii_classes.cj` 把区间表转换为现有 CharSet；`Parser.namedClass` 先试探识别，成功才移动解析位置。编译与匹配复用现有字符类链路，不引入区域设置或外部运行时依赖。

## 使用与验证

在 bash 中加载环境后：

```sh
source scripts/env.sh
cli/target/release/bin/main find '[[:digit:]]+' 'a12٣４b'
cli/target/release/bin/main find '[[:^ascii:]]+' 'a中🙂b'
```

分别返回 `12 [1,3)` 和 `中🙂 [1,8)`。新增演示也接入 `scripts/demo.sh`。

专项测试 `tests/verify_ascii_classes.py` 包含 496 条差分用例、5 条黄金结果、4 个非法模式和4项接口对照，覆盖 ASCII 全范围（CLI 排除 NUL）、非 ASCII、集合组合、随机模式及名称回退。两项原生测试补充 NUL 和公开 API 行为。

统一验收 `bash scripts/verify.sh` 本阶段共 5,545 条差分用例、15 项仓颉原生测试和 2 项 Rust 原生测试，另有既有黄金／接口／错误检查。所有数量均为测试用例数，不是上游功能覆盖率。

完整 Unicode 属性与简写类、词边界、大小写折叠、其余标志、bytes、RegexSet 和优化引擎尚未完成。下一阶段需要选定与固定上游一致的 Unicode 数据版本，建立可复现的数据生成流程，再实现属性查询与简写类。
