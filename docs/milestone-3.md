# 第三步：编号／命名捕获与路径状态

这是第三步的历史记录。替换和分割已在第四步实现，当前范围见 milestone-4.md。

本阶段在现有仓颉 NFA 中实现捕获，不调用 Rust 或 std.regex。仍是受限语义移植，不是完整 regex、regex-syntax、regex-automata 仓库的交付。

## 已实现的接口

| 仓颉接口 | 行为 |
|---|---|
| `Regex.captures(text)` | 首次匹配，返回 `Option<Captures>` |
| `Regex.capturesAll(text)` | 收集全部非重叠捕获；不是惰性迭代器 |
| `Regex.capturesLen()` | 包含完整匹配 0 的组槽数量 |
| `Regex.captureNames()` | 返回按组号排列的名称 Option 数组 |
| `Captures.size` | 当前结果的组槽数量 |
| `Captures.get(index)` | 按编号取值，负数／越界／未参与匹配返回 None |
| `Captures.name(name)` | 按名称取值，空名／未知名／未参与匹配返回 None |

捕获值沿用 `RegexMatch.start/end/text`。区间为原文 UTF-8 字节偏移的左闭右开区间。

支持 `(expr)`、`(?P<name>expr)`、`(?<name>expr)`，`(?:expr)` 不占组号。按左括号出现顺序编号，组 0 表示整体匹配。组名首字符限 ASCII 字母或 `_`，后续允许 ASCII 字母、数字、`_ . [ ]`；上游支持更广的 Unicode 名称，本阶段明确拒绝。重复名称报错，即使该组在 `{0}` 下也不例外。

## 可操作的验证

先运行 `bash scripts/verify.sh` 构建两端并完成回归，然后运行 `bash scripts/demo.sh`。演示将同一模式和输入分别交给 Rust 与仓颉：

```text
模式：(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})
输入：order=AB-123; order=CD-456
第一条：整体 AB-123 [6,12)，prefix AB [6,8)，number 123 [9,12)
第二条：整体 CD-456 [20,26)，prefix CD [20,22)，number 456 [23,26)
```

`(a)?(b*)` 对空文本的组 1 是 None，组 2 是存在但为空的字符串。这两者不能合并。`(a(b)?)+` 匹配 `aba` 时，组 2 保留之前捕获的 `b`，不因最后一轮没有参与而清空。

测试 CLI 提供 `captures`、`capture-first`、`capture-name`。协议中的文本和名称使用 UTF-8 十六进制，以避免换行／制表符造成分隔歧义；`scripts/show_captures.py` 仅将它解码显示，不参与匹配。

## 技术实现与上游对应

上游版本仍固定为 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`。

- `regex-syntax/src/ast/parse.rs`：捕获组解析、编号与 `is_capture_char` 名称规则的 ASCII 子集。
- `regex-syntax/src/hir/mod.rs` 的 `Hir::repetition`：仅能匹配空文本的子表达式，将重复上限和下限各压到至多一次。`normalize.cj` 只计算不能匹配／只能空匹配／可能消耗输入三类属性，不是完整 HIR。
- `regex-automata/src/nfa/thompson/compiler.rs` 的 `c_cap`：在组的入口和出口插入保存位置的状态。
- 同目录 `pikevm.rs`：有序路径、捕获槽和 epsilon closure 的优先级。上游使用可变槽与恢复栈；当前实现遇到 Save 就复制槽数组，各分支共享未修改的快照。

每个组占两个槽，存进入和离开时的标量位置。某一路径成功后，通过已有的输入偏移表转换成 UTF-8 字节位置。先到达相同 NFA 状态的路径保留优先级及其捕获数据，因此贪婪、非贪婪和分支顺序仍作用于捕获结果。

`{0}` 不编译其子树，所以 `(a){0}` 只剩组 0；`(a){0}(b)` 仍有 0、1、2 三个槽位，但 1 永远不存在。编译后扫描保留下来的 Save 状态，裁剪尾部已消去的捕获并清除其名称，保留中间编号空洞。

## 验证与限制

`tests/verify_captures.py` 新增 877 条差分用例（含固定、确定性随机、长输入和组数边界），2 条独立黄金结果、35 条名称查询、8 个非法模式、2 个当前不支持的 Unicode 名称、2 项资源限制检查。普通匹配、字符类与转义的旧回归同时执行。

- 最多 128 个显式捕获组；原有 64 层嵌套、4096 字节模式、16384 状态及 65536 编译工作量限制继续有效。
- 捕获操作要求 `状态数 × 组槽数量 × 2 <= 1048576`；此为保守的工作区规模门槛，不是精确峰值内存限制。不提取分组的 find/isMatch 不分配捕获槽数组。
- 每个 Save 的快照复制成本随捕获数增长；尚未做工作区复用及性能对标，不声称达到上游性能。
- findAll/capturesAll 立即收集结果；大输入、零宽匹配多时会占用较多内存。
- 仍未提供完整 Unicode 属性、标志、替换／分割、bytes、RegexSet、底层全量公开 API 及 DFA 等优化。
- 当前项目还是可执行包；后续需要拆出可被其他仓颉项目依赖的库和独立 CLI。
- CLI 无法传递 NUL，负数／越界 get 的防护目前由实现提供，尚无独立原生 API 单测。有限差分用例不构成完整等价证明。

下一阶段先使捕获能力用于替换／分割，并整理可依赖库包，然后继续扩展语法和 Unicode 兼容。
