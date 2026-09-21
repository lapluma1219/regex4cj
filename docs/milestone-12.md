# 第十二步：Unicode Script 与 Script_Extensions

基于固定 Rust 上游提交和 Unicode 16.0.0，新增两套各 170 个书写系统的标量区间表。提供完整长名及上游可用别名，支持：

- `\p{Han}`、`\p{Greek}`：省略属性名的 Script 查询。
- `\p{sc=Latn}`、`\p{Script:Latin}`：显式 Script 查询。
- `\p{scx=Hira}`、`\p{Script_Extensions=Hiragana}`：Script_Extensions 查询。
- `\P{sc=Greek}`、`\p{scx!=Hira}` 及双重取反。
- 属性参与字符类集合运算、重复、捕获、替换和分割。

Script 表示字符所属的书写系统；Script_Extensions 表示字符可用于哪些书写系统，不能简单视作 Script 的同义词或并集。例如 U+30FC 日文长音符“ー”的 Script 是 Common，Script_Extensions 包含 Hiragana 和 Katakana，而不包含 Common。

```sh
source scripts/env.sh
cli/target/release/bin/main find '\p{Han}+' 'A中文α'
cli/target/release/bin/main find '\p{sc=Hira}' 'ー'
cli/target/release/bin/main find '\p{scx=Hira}' 'ー'
```

第一条输出中文，UTF-8 字节范围 `[1,7)`；第二条没有匹配；第三条匹配“ー”，范围 `[0,3)`。

名称使用上阶段的规范化规则。裸 `\p{sc}` 仍然表示 Currency_Symbol，不能误解释为 Script。显式 `\p{gc=Greek}` 和 `\p{sc=L}` 报错。固定上游的别名表还列出 Unknown / Zzzz 和 Katakana_Or_Hiragana / Hrkt，但没有对应可用表，本实现与该上游一致地拒绝这些查询。

## 数据来源与复现

新生成器 `scripts/generate_scripts.py` 复用经过测试的 Rust 区间表解析器，导入：

- `regex-syntax/src/unicode_tables/script.rs`
- `regex-syntax/src/unicode_tables/script_extension.rs`
- `regex-syntax/src/unicode_tables/property_values.rs` 的 Script 与 Script_Extensions 部分。

快照 `data/unicode/scripts.json` 保存区间、别名、Unicode 版本、固定提交和源文件 SHA-256；生成 `port/src/unicode_scripts.cj`。默认离线生成或核对，不依赖完整上游仓库；重新导入时检查上游 Git 提交和源文件是否被修改。

```sh
python3 scripts/generate_scripts.py --check
python3 scripts/generate_scripts.py --upstream /path/to/pinned/regex --check
```

统一验收入口仍是 `bash scripts/verify.sh`。新增差分测试覆盖两套表的所有区间端点和邻点、所有可用别名、不可用别名报错、规范化、随机集合运算及四类 API。另有六条独立预期结果验证中文偏移和长音符差异，消费包原生测试覆盖 NUL 和相关 API。

本轮完整验收通过：新增 2,148 条差分用例，累计 9,115 条；19 项仓颉原生测试、2 项 Rust 原生测试及 4 项 Python 数据导入测试通过。演示脚本通过，数据快照与固定上游源文件核对一致。

本阶段仍不支持二元属性（如 Alphabetic、White_Space）、Age、大小写折叠或完整 Unicode 属性系统。下一步扩展二元属性；其他 API、bytes、RegexSet 和优化引擎继续按兼容路线图推进。
