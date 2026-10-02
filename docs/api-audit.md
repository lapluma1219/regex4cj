# 顶层 regex 接口覆盖审计

本轮只审计固定上游 `72d650cb0a880a01ab6dc2137c0888e8f89740f7` 的顶层 `regex` 包。字符串、bytes、两种 RegexSet、四种 Builder 及结果辅助类型均在范围内。regex-syntax、regex-automata、regex-lite、C API 不在本轮范围内。

结论：项目已经有可使用的匹配、捕获、替换和分类能力，但不能称作顶层接口在调用方式、惰性、内存行为、配置含义上全部等价。上游匹配套件通过不能替代辅助接口审计。本轮已发现并修复三个真实行为问题，同时把尚未实现和证据不足的能力明确列出。

## 如何阅读证据

- [逐项对应表](api-audit-methods.md)：170 个公开固有方法，包括 doc(hidden) 历史别名，逐行映射仓颉代码和相关测试。
- [机器可读清单](api-audit-inventory.json)：原始文件哈希、上游提交、公开类型声明、方法位置、状态及证据文件。
- [接口契约差分](../tests/verify_api_contracts.py)：95 个具名辅助接口结果与 513 次起点差分检查。Rust 和仓颉分别调用真实接口，输出协议包含 NUL/原始字节的十六进制表示。
- [Rust 探针](../oracle/src/api_audit.rs)与[仓颉探针](../cli/src/api_audit.cj)：每个结果的生成操作都可直接阅读；`raw api-audit` 是开发验收入口，不是库的新功能。
- [原有完整上游套件](../tests/verify_upstream_suite.py)、其他差分脚本和原生测试继续保留。

状态“有样例验证”只表示存在对应实现及相关输入的证据，不表示所有边界都验证。“证据待补”表示代码存在但尚缺专门对照；“有明确差异”表示需要替代调用或功能/资源约定有区别。完全缺少的能力列在下文，不能把它们算成已实现。170 是固有方法清单大小，不是完成百分比；宏、trait、默认 trait 方法和特性开关不能靠数 `pub fn` 覆盖。

提取脚本从固定提交的 Git 对象读源码，而非信任当前工作树。它是针对这个已审阅版本的源代码清单工具，不是完整 Rust 语法解析器。重导出与 trait/宏由人工按 `src/lib.rs`、`src/bytes.rs` 和具体实现复核。未来升级基线必须重新审阅，不能只更新版本号。

## 本轮发现与修复

| 编号 | 最小操作 | 固定 Rust 结果 | 修复前仓颉结果 | 当前处理 |
|---|---|---|---|---|
| A1 | 模式空字符串，输入 `中`，逐次调用 split 迭代器 | 空串、`中`、空串、结束 | 空串、`中`、结束 | 修复迭代器越过末尾空匹配后遗漏最终尾段；空输入和 `$` 也纳入回归 |
| A2 | `(a)(b)?` 的位置容器先搜索 `a`，再搜索 `z`，读取第0组 | None | 仍为 `[0,1)` | 字符串和 bytes 搜索失败均清除可读位置；成功时未参与的组也仍清空 |
| A3 | `Regex("a").findAt("中a", 1)` | `[3,4)` | 抛“不是字符边界”异常 | 允许合法字节起点落在字符内部，从后续边界搜索，保留完整输入上下文 |

A3 同时检查 find/isMatch/captures/shortest/capturesRead 和 Set；对二、三、四字节字符的每一个字节位置、ASCII/Unicode 词边界、绝对锚点与空模式进行对照。不能用截取子串代替起点搜索，例如 `\ba` 在 `中a` 上仍需看到前面的中文是 Unicode 单词字符。

原有原生测试曾把“失败后保留位置”和“字符内部起点报错”当作预期。本轮依据固定 Rust 实测修正了这两处测试；测试数量仍为29，另新增独立契约差分阶段。修复前后的行为及上游依据明确记录于此，不用修改预期掩盖未经验证的差异。

此外，修正 `shortestMatch` 的文档：上游只承诺引擎确认匹配时的终点，明确允许不同内部引擎/启发式产生不同终点，不保证全局最短。这类允许的差异不能据此判定为兼容缺陷。

## 不在固有方法表里的公开能力

| 上游能力/类型 | 仓颉对应与结论 | 验证或剩余工作 |
|---|---|---|
| 根级 `escape` | `escape`；返回转义文本 | `tests/verify.py`，原生 NUL 用例 |
| `regex!`、`bytes::regex!` | 尚无宏或同等“每个调用点编译一次”的便捷封装；可由应用自行持有已编译实例 | 不能把普通构造器当作宏缓存已移植 |
| `Matches` / `CaptureMatches` | 字符串 `MatchIter` / `CaptureIter.next()`；bytes 只有 eager 数组 | 字符串已测空匹配、结束后多次 next；bytes 惰性类型尚缺 |
| `Split` / `SplitN` | 字符串 splitIter 存在；字符串 splitN、全部 bytes 分割返回数组 | 对应按需限制分割尚缺；splitN 的结果由原有测试验证 |
| `CaptureNames` | `captureNames()` 返回数组 | 名称/编号结果有测试，无上游命名迭代器类型 |
| `SubCaptureMatches` | `GroupIter` / `BytesGroupIter`，用 done/value 区分结束和未参与 | 字符串有原生与差分；bytes 独立契约仍待补 |
| `SetMatchesIter` / `SetMatchesIntoIter` | `indices()` 升序数组 | 结果内容有测试；没有独立迭代器、反向 next_back |
| `Iterator` / `FusedIterator` | 仅部分显式 next；无对应 Rust trait | 字符串连续 None 行为有回归；终止后内部不再搜索的效率未承诺 |
| `ExactSizeIterator` / `DoubleEndedIterator` | 没有对应迭代器契约 | 数组可自行按大小/逆序访问，但不是同等按需接口 |
| `Replacer`、`ReplacerRef`、`NoExpand` | 模板、replaceWith、replaceLiteral 覆盖常见使用结果 | 无通用 trait 扩展点、by_ref 或 no_expansion 提示；回调重入/异常已有原生测试，bytes 回调与字面量本轮补对照 |
| `FromStr` / `TryFrom` / `Default` | 显式构造；空 Set 用空数组 | 调用形式适配，不提供 Rust trait 本身 |
| `Index<usize>` / `Index<&str>` | `get` / `name` 返回 Option；没有索引语法 | 上游索引对缺组可 panic，仓颉查询返回 None，不能混淆这两种契约 |
| Match 的 `From` / `range` | 字段 start/end/text/bytes 手动组合 | 没有 Rust Range 转换 trait，字节数组可修改 |
| `Clone` / `Copy` / `Eq` / `PartialEq` | 未提供与 Rust 对应的值复制/值比较契约 | 仓颉 class 引用赋值不是 Clone；尤其 iterator 不能据此当成独立游标副本 |
| `Display` / `Debug` | 模式有 asStr；RegexError 有 toString | 未复刻全部 Debug/Display 格式；错误文本仅已测输入对齐 |
| `Error::Syntax/CompiledTooBig` | `RegexErrorKind`、`RegexError.text/limit`；抛异常代替 Result | 语法/限额文本测试已存在，类型/载荷的逐项专用对照还可加强 |
| Rust `Send` / `Sync` 等自动 trait | 无跨语言同名保证 | 并发共享、回调并发和迭代器线程使用尚未专项验证 |
| 可选 `pattern` 特性 | 没有 `str` Pattern/Searcher 集成；上游也是可选不稳定特性 | 非默认范围，明确记为未移植 |
| Cargo std/unicode/perf 特性矩阵 | 固定启用当前 Unicode 数据，单一仓颉包；没有等同编译特性组合 | 本轮只对锁定默认依赖配置作结论，不承诺无标准库/裁剪构建 |

上游 `__private` 和 `__bytes_regex` 是宏支撑细节，不单列为用户业务能力，但它们支撑的宏缺口已记录。`regex::Error` 不是两个模块各自不同的错误类型。

## 已确认的差异及优先级

1. **bytes 惰性接口、惰性 splitN 缺失。** 现在可用数组取得结果，但不能在大量匹配中只取前几条而避免计算余下部分。这是实际能力差别，不只是命名区别。建议下一轮优先补，不在本轮突然扩大实现。
2. **Builder 和资源预算不是完整引擎等价。** 四种 Builder 大体有对应选项；`dfaSizeLimit` 不是原版 DFA 缓存预算。`sizeLimit` 模拟构造预算，已有阈值样例，不保证所有启发式接受边界。更换引擎是后续工作，不以增加空壳配置接口宣称完成。
3. **bytes 辅助方法与部分 Builder 组合证据不足。** 非零原始字节起点、bytes 捕获 metadata/extract/组迭代，尤其 bytes Set Builder 的多选项组合，需要专门差分。对应表将其标为待补，不用字符串共享实现作为完整证明。
4. **内存及所有权契约不同。** 返回数组/新文本，不复刻 Rust 借用生命周期、Cow、Iterator trait；CaptureLocations 复用位置容器，搜索仍可能分配新数组。不能声称分配行为相同。
5. **便利接口与语言集成缺失。** 宏、clone、Debug、索引等不影响常见手动调用，但仍应按上述表述介绍。

这些差异并不妨碍把本项目作为“有明确兼容范围、可运行和可验证的仓颉原生库”交付；它们阻止的是“顶层接口已经完全等价”这一更强声明。

## 复核与完成条件

完整验收入口仍为 `bash scripts/run.sh verify`，新增 api-inventory 和 verify_api_contracts 阶段。单独检查清单不需要上游检出：

```sh
python3 scripts/audit_api_surface.py --check
```

修改公开仓颉方法后应更新清单位置。重新提取需显式提供固定上游检出，仅审计维护时需要，普通验收不需要：

```sh
python3 scripts/audit_api_surface.py --upstream /路径/regex
```

清单检查只验证声明/链接是否存在，不验证行为；契约差分与完整套件负责执行验证。本轮结束条件是：约定公开范围可逐项归类，真实缺陷有最小反例及修复回归，未覆盖处有明确清单，完整验收成功并绑定提交。不是要求本轮实现全部剩余能力。

## 本轮实际验收结果

实现与审计提交：`904a6acab6d88b3440924079b802b439d97e5baa`。在工作区干净时执行完整 `verify`，40 个阶段全部成功，最终状态为 `passed`。详见 [完整验收记录](acceptance/api-audit-2026-10-02.json)。本节与记录在后续文档提交保存，没有修改被验收的实现。

- 清单检查覆盖 170 个公开固有方法；trait、宏和特性开关按本文另行审阅。
- 新增接口契约结果 95 项、字节起点差分 513 次，全部通过。
- 原有完整上游套件 3213 条及其余差分阶段通过。
- 29 项仓颉原生测试、3 项 Rust 测试、4 项 Python 测试通过。
- 13 个单模式演示与 7 个分类场景通过。

本次沿用已安装工具链及 Cargo 依赖缓存，并设置 `CARGO_NET_OFFLINE=true`；不是新的异机或首次下载验收。报告时间跨度包含本次运行的实际墙钟时间，不可拿来作为正则引擎性能数据。上述有限验证不消除本文列出的缺口，也不证明任意输入完全等价。
