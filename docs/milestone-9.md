# 第九步：Unicode 16.0.0 简写字符类与数据生成

新增 Unicode 模式下的 `\d`、`\s`、`\w` 及 `\D`、`\S`、`\W`，可用于普通模式和字符类内部，并参与取反、集合运算、捕获及替换／分割。

| 简写 | Unicode 定义 | 本次固定区间数 |
|---|---|---|
| `\d` | General_Category = Decimal_Number | 71 |
| `\s` | White_Space | 10 |
| `\w` | Alphabetic ∪ Mark ∪ Decimal_Number ∪ Connector_Punctuation ∪ Join_Control | 796 |

大写形式是相应集合在 Unicode 标量范围内的补集，排除代理区。例如 `\d` 可以匹配全角及阿拉伯文十进制数字，但不包含所有外观类似数字的字符（如 ²）。`\w` 可匹配中文、组合标记和 U+200C/U+200D，不把所有 emoji 视作单词字符。`\s` 包含 NBSP，却不包含 U+200B 和 BOM。POSIX 类仍保持 ASCII 定义。

`[\w&&[^\d]]`、`[\w--[:ascii:]]` 等组合已支持。`[\d-a]`、`[a-\d]` 明确报错，因为集合不能作单个范围端点；`[\d-]` 和 `[\d--a]` 分别是并入横线和集合差集。

## 可复现数据流程

依据固定上游 commit `72d650cb0a880a01ab6dc2137c0888e8f89740f7` 的三张表：

- `regex-syntax/src/unicode_tables/perl_decimal.rs`
- `regex-syntax/src/unicode_tables/perl_space.rs`
- `regex-syntax/src/unicode_tables/perl_word.rs`

它们的头部记录 Unicode 16.0.0 和 ucd-generate 0.3.1。本阶段从上游已生成的表转换，不从系统 Unicode 库重新计算属性，也不声称重现 UCD 到 Rust 表的完整工具链。

仓库保存 `data/unicode/perl_classes.json`（数值区间、上游提交、每个来源文件 SHA-256）和 `port/src/unicode_classes.cj`。另附上游目录中的 Unicode 许可证。完整 Rust 源码和完整 UCD 仍不在仓库内。

```sh
# 从已提交的区间快照重新生成，无网络、无上游仓库依赖
python3 scripts/generate_unicode.py
# 验证生成文件与区间快照一致
python3 scripts/generate_unicode.py --check
# 可选：从固定提交的外部 Rust checkout 重新导入和生成
python3 scripts/generate_unicode.py --upstream /path/to/regex
# 同时核对外部源表、快照与生成结果，不写文件
python3 scripts/generate_unicode.py --upstream /path/to/regex --check
```

导入时检查 Git HEAD、源文件是否与该提交对象一致、Unicode 版本、每一行的解析格式和标量范围；拒绝代理区、重叠／无序或越界区间。普通 `--check` 只验证本地快照和生成物，源表真实性核对需使用 `--upstream`。构建直接使用已提交的仓颉文件；统一验收先检查生成物是否过期。

## 实现与使用

`Parser.escaped` 将简写类转换为 CharSet；大写形式使用现有补集算法。新构造入口线性加载已排序的生成区间，成员查询仍使用二分查找。字符类组合复用已有集合代数，每次解析生成独立集合，避免修改共享表。

在 bash 中加载环境后：

```sh
source scripts/env.sh
cli/target/release/bin/main find '\d+' 'A３٣²'
cli/target/release/bin/main find '\w+' '中文🙂abc'
```

分别得到 `３٣ [1,6)`，以及 `中文 [0,6)`、`abc [10,13)`。公开 API 调用无需 Rust、Python、外部表或网络。

## 验证与限制

新增 284 条差分用例：其中边界用例把每个区间端点及邻点、每类 2,000 个确定性随机码点分批拼成输入，每批同时核对正类和补集。另覆盖 Unicode 16 新增数字、组合标记、集合代数和随机组合。还有 4 条独立黄金结果、4 个非法模式、4 项接口对照，以及新增原生 NUL 测试。

全套为 5,829 条差分用例、16 项仓颉原生测试、2 项 Rust 原生测试，另有既有黄金／接口／错误检查。边界与随机测试不等于逐一扫描全部 Unicode 码点。

`\p{...}` / `\P{...}` 属性语法、Unicode 组名、词边界、大小写折叠、Unicode 关闭模式仍未实现。仅有三个简写集合，不是完整 Unicode 属性 API。集合合并尚有重复分配开销，重复出现的大类可能占用较多内存；NFA 状态数不反映全部区间存储成本。

下一阶段在同一版本基础上扩展属性名称及属性表，再推进词边界、大小写折叠和其余标志。
