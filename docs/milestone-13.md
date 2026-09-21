# 第十三步：Unicode 二元属性与交付范围核对

支持固定 Unicode 16.0.0 / Rust 上游的 64 个可查询二元属性及 121 个别名，包括 Alphabetic、Uppercase、Lowercase、White_Space、Emoji、Extended_Pictographic、ID_Start / XID_Start、Math 等。复用此前的属性名称规范化、字符类集合运算和 NFA。

二元属性表示“字符是否具有该性质”。语法是 `\p{Alphabetic}` 或 `\P{Alphabetic}`，没有必要、也不能擅自提供上游不接受的 `\p{Alphabetic=Yes}`。该固定上游拒绝带 Yes/No 等值的二元查询，本实现保持一致。

## 关键差异

- U+0345 是组合标记，符合 Alphabetic，却不属于通用类别 L。
- U+2160 “Ⅰ”符合 Uppercase，却属于 Letter_Number，不属于 Lu。
- Emoji 属性也包括 ASCII 数字等可用于 emoji 序列的字符；它不是“完整 emoji 序列匹配器”。例如 `\p{Emoji}+` 在 `a1🙂b` 中匹配 `1🙂`。
- White_Space 与当前 Unicode `\s` 一致，包含 U+0085、U+00A0 等。
- 裸属性优先查询二元属性，保留 `cf`、`sc`、`lc` 的类别含义；显式 `gc=...` 不改为二元属性查询。
- 上游 property_bool.rs 有 65 张表，但其中 InCB 不能通过上游公开属性查询解析：名称规范化映射为 Indic_Conjunct_Break，未匹配该表。快照明确记录排除项，并测试其报错行为。

## 来源和复现

`scripts/generate_binary.py` 从固定上游 `regex-syntax/src/unicode_tables/property_bool.rs` 与 `property_names.rs` 导入，复用已测的区间解析器。`data/unicode/binary_properties.json` 记录数据、别名、提交、Unicode 版本、文件 SHA-256 和排除表；生成 `port/src/unicode_binary.cj`。许可证沿用 `data/unicode/LICENSE-UNICODE`。

```sh
python3 scripts/generate_binary.py --check
python3 scripts/generate_binary.py --upstream /path/to/pinned/regex --check
bash scripts/verify.sh
```

默认离线重建，指定上游导入则核对 Git 提交与源文件内容。新增测试核对每张表的区间端点/邻点、所有可用别名、否定、集合运算、类别区别、接口行为和错误情况。仓颉消费测试覆盖无法经命令行传递的 NUL。

仍未实现 Age / 各 Break 枚举属性、大小写折叠、其余标志及全部公共接口。本轮另新增 `docs/delivery-plan.md`，明确核心交付与整个仓库完整转译的差别，并把后续工作合并为较大的能力阶段。

完整验收通过：本轮新增 417 条差分，累计 9,532 条；20 项仓颉原生测试、2 项 Rust 原生测试、4 项 Python 数据导入测试通过。演示脚本及快照来源核对通过。
