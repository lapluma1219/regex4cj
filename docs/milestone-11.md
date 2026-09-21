# 第十一步：Unicode 通用类别属性

支持 Unicode 16.0.0 的 General_Category 查询，提供 37 个上游标量类别及 `Any`、`ASCII`、`Assigned`。本阶段不包括脚本、二元属性或完整 Unicode 属性 API。

## 语法与别名

- `\pL`、`\p{L}`、`\p{Letter}`：字母类别。
- `\p{Lu}`、`\p{Uppercase_Letter}`：大写字母类别，不等同于二元属性 Uppercase。
- `\p{gc=Nd}`、`\p{General_Category:Decimal_Number}`：指定通用类别属性及值。
- `\P{L}`、`\p{gc!=L}`：非字母；`\P{gc!=L}` 再次取反，等价于字母。
- `[\p{L}--\p{Lu}]`：属性可参与字符类、集合运算和捕获。

包含 L、M、N、P、S、Z、C 七个总类、其上游可匹配子类及 LC（Cased_Letter）。原始别名表有 80 个条目；指向 Surrogate 的 `cs` / `surrogate` 不具有可用标量表，和本次固定 Rust 原版一样报错，而不是悄悄视作空集合。

名称规范化遵循上游：忽略 ASCII 大小写、空格、下划线、横线和非 ASCII 字节；处理原始名称开头的 `is` 前缀，并保留 `isc` 特例。TAB 等其他 ASCII 字符不会当作空格忽略。支持规范名与上游类别别名，例如 digit、cntrl、punct，但 `White_Space`、`Alphabetic` 等二元属性仍未支持。`\p{sc}` 是 Currency_Symbol 类别，`\p{sc=Latin}` 则是尚不支持的 Script 属性。

`Any` 包含全部 Unicode 标量，`ASCII` 为 U+0000–U+007F，`Assigned` 是 Unassigned 的标量补集。`\p{N}` 比 `\d` 更宽，例如还包括 ²。组合标记属于 M，不因外观像字母就归入 L。

## 数据与生成

固定上游仍为 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`：

- `regex-syntax/src/unicode_tables/general_category.rs`：类别区间。
- `regex-syntax/src/unicode_tables/property_values.rs` 的 General_Category 部分：别名。
- `regex-syntax/src/unicode.rs`：名称规范化、类别查询及特殊集合。
- `regex-syntax/src/ast/parse.rs`：属性语法及 `!=`、`:`、`=` 识别优先级。

生成器只提取所需数据，保存到 `data/unicode/general_categories.json`，记录版本、提交和两份源文件 SHA-256，生成 `port/src/unicode_categories.cj`。Unicode 许可证沿用仓库中的原文。构建无需外部数据、网络或 Rust。

```sh
python3 scripts/generate_categories.py
python3 scripts/generate_categories.py --check
python3 scripts/generate_categories.py --upstream /path/to/pinned/regex --check
```

默认从本地快照生成／核对；指定 `--upstream` 时核对 Git 提交和源文件内容，并支持重新导入。原有 `generate_unicode.py` 继续负责 d/s/w 简写表；统一验收检查两类生成物。

导入器支持上游单行、多行两种表格式，按常量名称定位并拒绝未解析内容。跨越代理区的 Rust char 范围会拆成两个标量区间。每个类别生成独立数据函数，避免把全部大表放进一个函数；仅构造当前查询所需的集合。集合代数和大类重复分配的性能仍未优化。

## 操作与验收

在 bash 中从仓库根目录执行：

```sh
source scripts/env.sh
cli/target/release/bin/main find '\p{L}+' 'A中3🙂'
cli/target/release/bin/main find '\p{N}+' 'a²٣'
cli/target/release/bin/main find '\P{gc!=L}+' 'ab12'
```

依次得到 `A中 [0,4)`、`²٣ [1,5)`、`ab [0,2)`。原始模式要用 shell 单引号，仓颉源码中可用原始字符串 `#"..."#`。

新增 702 条差分用例，覆盖每个类别区间的端点和邻点、全部可用别名、特殊集合、否定运算、规范化及随机集合组合；另有 4 条黄金结果、11 个非法查询、6 个未支持属性查询、4 项 API 对照。消费包新增一项 NUL、类别与集合运算原生测试。生成器新增 4 项格式解析回归测试。

全量验收 `bash scripts/verify.sh` 共 6,967 条差分用例、18 项仓颉原生测试、2 项 Rust 原生测试和 4 项 Python 生成器测试，另有既有黄金／接口／错误检查。

下一阶段扩展 Script / Script_Extensions 和二元属性。大小写折叠、Unicode 组名、其余标志、方向性词边界、bytes、RegexSet、惰性迭代及优化引擎仍未完成。
