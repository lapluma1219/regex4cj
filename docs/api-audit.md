# 顶层 regex 接口覆盖审计

本轮只审计固定上游 `72d650cb0a880a01ab6dc2137c0888e8f89740f7` 的顶层 `regex` 包。字符串、bytes、两种 RegexSet、四种 Builder 及结果辅助类型均在范围内。regex-syntax、regex-automata、regex-lite、C API 不在本轮范围内。

结论：项目已经有可使用的匹配、捕获、替换和分类能力，但不能称作顶层接口在调用方式、惰性、内存行为、配置含义上全部等价。上游匹配套件通过不能替代辅助接口审计。本轮已发现并修复三个真实行为问题，同时把尚未实现和证据不足的能力明确列出。

## 如何阅读证据

- [逐项对应表](api-audit-methods.md)：170 个公开固有方法，包括 doc(hidden) 历史别名，逐行映射仓颉代码和相关测试。
- [机器可读清单](api-audit-inventory.json)：原始文件哈希、上游提交、公开类型声明、方法位置、状态及证据文件。
- [接口契约差分](../tests/verify_api_contracts.py)：2414 个具名辅助接口结果与 513 次字符串起点差分检查。其中包括1400项迭代结果、384项Builder配置模式组合、260项bytes起点结果。Rust 和仓颉分别调用真实接口，输出协议包含 NUL/原始字节的十六进制表示。
- [Rust 探针](../oracle/src/api_audit.rs)与[仓颉探针](../cli/src/api_audit.cj)：每个结果的生成操作都可直接阅读；`raw api-audit` 是开发验收入口，不是库的新功能。
- 迭代器和 Builder 组合的扩展操作分别在 [Rust 扩展探针](../oracle/src/lazy_audit.rs) 与 [仓颉扩展探针](../cli/src/lazy_audit.cj)。输入配置相同，期望结果由固定 Rust 独立计算，不使用仓颉结果生成预期。
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

原有原生测试曾把“失败后保留位置”和“字符内部起点报错”当作预期。初次审计依据固定 Rust 实测修正了这两处测试，当时原生测试为29项；本次补齐迭代器又新增2项，当前为31项。修复前后的行为及上游依据明确记录于此，不用修改预期掩盖未经验证的差异。

此外，修正 `shortestMatch` 的文档：上游只承诺引擎确认匹配时的终点，明确允许不同内部引擎/启发式产生不同终点，不保证全局最短。这类允许的差异不能据此判定为兼容缺陷。

## 不在固有方法表里的公开能力

| 上游能力/类型 | 仓颉对应与结论 | 验证或剩余工作 |
|---|---|---|
| 根级 `escape` | `escape`；返回转义文本 | `tests/verify.py`，原生 NUL 用例 |
| `regex!`、`bytes::regex!` | 尚无宏或同等“每个调用点编译一次”的便捷封装；可由应用自行持有已编译实例 | 不能把普通构造器当作宏缓存已移植 |
| `Matches` / `CaptureMatches` | 字符串 `MatchIter` / `CaptureIter.next()`；bytes 对应 `BytesMatchIter` / `BytesCaptureIter.next()` | 两类均有空匹配、结束后多次 next 对照；bytes 另有快照和独立游标原生验证 |
| `Split` / `SplitN` | 两类输入均有 splitIter/splitNIter；原有数组接口保留 | 0/1/2/5限制、尾空段、连续结束有对照；负数限制有原生测试 |
| `CaptureNames` | `captureNames()` 返回数组 | 名称/编号结果有测试，无上游命名迭代器类型 |
| `SubCaptureMatches` | `GroupIter` / `BytesGroupIter`，用 done/value 区分结束和未参与，支持len/sizeHint/clone | 独立游标复制、缺席组和耗尽后复制有字符串/bytes对照；不承诺bytes载荷深复制 |
| `SetMatchesIter` / `SetMatchesIntoIter` | `iter()` 返回SetMatchesIter，支持next/nextBack/clone；保留indices数组 | 128项双向/交错/复制差分，含字符串和bytes；没有独立IntoIter类型与Rust IntoIterator trait |
| `Iterator` / `FusedIterator` | 仅部分显式 next；无对应 Rust trait | 字符串连续 None 行为有回归；终止后内部不再搜索的效率未承诺 |
| `ExactSizeIterator` / `DoubleEndedIterator` | 捕获组迭代器提供len/sizeHint；集合迭代器提供nextBack | 显式方法适配；集合sizeHint按原仓库返回未扫描槽位数，不是命中数 |
| `Replacer`、`ReplacerRef`、`NoExpand` | 模板、replaceWith、replaceLiteral 覆盖常见使用结果 | 无通用 trait 扩展点、by_ref 或 no_expansion 提示；回调重入/异常已有原生测试，bytes 回调与字面量本轮补对照 |
| `FromStr` / `TryFrom` / `Default` | 显式构造；空 Set 用空数组 | 调用形式适配，不提供 Rust trait 本身 |
| `Index<usize>` / `Index<&str>` | `get` / `name` 返回 Option；没有索引语法 | 上游索引对缺组可 panic，仓颉查询返回 None，不能混淆这两种契约 |
| Match 的 `From` / `range` | 字段 start/end/text/bytes 手动组合 | 没有 Rust Range 转换 trait，字节数组可修改 |
| `Clone` / `Copy` / `Eq` / `PartialEq` | SetMatchesIter、GroupIter和BytesGroupIter已提供显式clone及独立游标，其他类型未完整提供对应契约 | 仓颉class引用赋值不是Clone；不能把一种迭代器的复制保证推广到所有类型 |
| `Display` / `Debug` | 模式有 asStr；RegexError 有 toString | 未复刻全部 Debug/Display 格式；错误文本仅已测输入对齐 |
| `Error::Syntax/CompiledTooBig` | `RegexErrorKind`、`RegexError.text/limit`；抛异常代替 Result | 语法/限额文本测试已存在，类型/载荷的逐项专用对照还可加强 |
| Rust `Send` / `Sync` 等自动 trait | 无跨语言同名保证 | 并发共享、回调并发和迭代器线程使用尚未专项验证 |
| 可选 `pattern` 特性 | 没有 `str` Pattern/Searcher 集成；上游也是可选不稳定特性 | 非默认范围，明确记为未移植 |
| Cargo std/unicode/perf 特性矩阵 | 固定启用当前 Unicode 数据，单一仓颉包；没有等同编译特性组合 | 本轮只对锁定默认依赖配置作结论，不承诺无标准库/裁剪构建 |

上游 `__private` 和 `__bytes_regex` 是宏支撑细节，不单列为用户业务能力，但它们支撑的宏缺口已记录。`regex::Error` 不是两个模块各自不同的错误类型。

## 已确认的差异及优先级

1. **已补齐：bytes 惰性接口、两类输入的惰性 splitN。** 匹配由 next 按需执行，不包装预先收集的数组；bytes 创建时复制输入。输入快照和字符串扫描信息仍有初始化成本，不承诺零复制。
2. **Builder 和资源预算不是完整引擎等价。** 四种 Builder 大体有对应选项；`dfaSizeLimit` 不是原版 DFA 缓存预算。`sizeLimit` 模拟构造预算，已有阈值样例，不保证所有启发式接受边界。更换引擎是后续工作，不以增加空壳配置接口宣称完成。
3. **已补证据：bytes 辅助方法与四种 Builder 组合。** bytes 非零起点、捕获 metadata/extract/组迭代均加入专项验证。四种Builder每种显式设置全部选项，16组配置乘6种模式共384项，比较编译接受/拒绝及两段输入的命中结果。不把统一输出error当作错误文本完全等价的证明。
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

## 初次审计验收结果（历史提交）

实现与审计提交：`904a6acab6d88b3440924079b802b439d97e5baa`。在工作区干净时执行完整 `verify`，40 个阶段全部成功，最终状态为 `passed`。详见 [完整验收记录](acceptance/api-audit-2026-10-02.json)。本节与记录在后续文档提交保存，没有修改被验收的实现。

- 清单检查覆盖 170 个公开固有方法；trait、宏和特性开关按本文另行审阅。
- 新增接口契约结果 95 项、字节起点差分 513 次，全部通过。
- 原有完整上游套件 3213 条及其余差分阶段通过。
- 29 项仓颉原生测试、3 项 Rust 测试、4 项 Python 测试通过。
- 13 个单模式演示与 7 个分类场景通过。

本次沿用已安装工具链及 Cargo 依赖缓存，并设置 `CARGO_NET_OFFLINE=true`；不是新的异机或首次下载验收。报告时间跨度包含本次运行的实际墙钟时间，不可拿来作为正则引擎性能数据。上述有限验证不消除本文列出的缺口，也不证明任意输入完全等价。

## 惰性接口与专项验证补齐结果

后续本地工作已完成三项约定：bytes 的 findIter/capturesIter/splitIter，两类输入的 splitNIter，以及原先列出的 bytes 辅助接口和 Builder 组合专项验证。另提供 bytes capturesRead 快捷入口，保留原有数组接口。

完整 verify 的40个阶段全部通过：31项仓颉原生测试、3项Rust测试、4项Python测试、3213条上游用例、2148项接口契约结果和513次字符串起点差分；13个单模式演示与7个分类演示通过。2148项契约结果包括1400项迭代结果、384项Builder配置模式组合和260项bytes起点结果，其余为既有及新增辅助接口结果。

新增原生测试检查输入快照、返回值修改、独立游标、连续结束、负数限制和可变捕获组提取拒绝。源码复核确认迭代器没有调用 eager 数组方法，每次 next 才搜索，splitN 达到限制不再搜索。bytes 输入快照仍需要线性空间；字符串仍需准备字符偏移，不宣称零复制或输入读取本身完全惰性。

完整证据见 [验收记录与源码哈希](acceptance/lazy-interfaces-2026-10-02.json)。本次先验证工作区修改，最后才提交，因此原始报告的 dirty 为 true、commit 为修改前基线；额外保留实际验收的源码SHA-256，提交前逐项核对一致。没有将旧提交伪装成此次实现。沿用已安装环境与Cargo缓存，不是异机验收。

宏、语言trait、DFA资源语义、零复制和并发保证等仍按前述差异说明；本次补齐三项不等于这些额外能力也已实现。

## 集合结果双向迭代（2026-10-03）

SetMatches新增iter，返回SetMatchesIter。next从低编号向高编号扫描，nextBack从高编号向低编号扫描；交错调用共享剩余范围，耗尽后持续返回None。clone复制游标的当前位置，不预先收集编号数组；字符串和bytes共用同一结果类型。indices继续提供数组形式。

新增128项与原仓库的差分：16种命中组合×字符串/bytes×正向/反向/交错/复制4种操作序列。接口契约结果现为2276项，另有513次字符串起点差分，专项测试全部通过。原生测试现为32项，包括重复规则、空集合、临时结果、快照隔离、结束后复制和非法UTF-8。

原仓库方法表仍为170条，目前128条有样例验证、42条有明确差异；这些标签仍不是完全等价证明。该次尚未提供IntoIterator、size_hint、Debug等剩余约定（sizeHint已在后续批次补齐），不能声称整个集合迭代器体系已完整移植。更大范围按[完整行为对齐计划](full-compatibility-plan.md)继续推进。

本次完整验收40个阶段全部通过，包含3213条原仓库匹配用例、2276项接口契约结果、513次字符串起点差分和32项仓颉原生测试。证据见[本轮验收与源码校验值](acceptance/set-iterator-2026-10-03.json)。报告如实保留工作区dirty状态；使用本机工具链及Cargo缓存，不是异机或全新环境验收。

## 追加展开与集合构造补齐（2026-10-04）

字符串和字节捕获结果均新增 `expandInto`：直接向调用者的 StringBuilder / ArrayList<UInt8> 追加模板展开内容，保留已有前缀。原有 `expand` 返回新结果的便利用法保留，并共用同一展开逻辑。两种 SetBuilder 新增规则数组构造器：构造时保存规则快照，build 时才解析，继续允许空集合和重复规则。

新增80项追加展开对照结果，覆盖缺席组、命名组、转义美元符号、非法/超大组号、未闭合模板、NUL/中文前缀、非法UTF-8与重复追加；另有4项集合构造对照，覆盖数组修改后的快照和大小写配置。原生测试另检查空模板、空集合、延迟编译错误和后续追加规则。

当前契约结果2360项（新增84项包括在内），另有513次起点差分。主要库的170条固有方法映射中，132条有样例验证、38条有明确差异；这不是原仓库完成率。新增接口和测试见 [API清单](api-catalog.md)、[仓颉探针](../cli/src/append_builder_audit.cj) 和 [原生测试](../examples/consumer/src/append_builder_test.cj)。仓颉1.1.3完整40阶段验收通过，见[本批验收记录](acceptance/append-builder-2026-10-04.md)。

## 捕获组游标与大小提示（2026-10-04）

新增GroupIter/BytesGroupIter的len、sizeHint和clone，以及SetMatchesIter的sizeHint。捕获组数量包括未参与匹配的槽位；复制在当前进度分叉，两份游标独立推进；结束后持续为空。集合sizeHint复刻固定原仓库未扫描槽位计数，不能解释为剩余命中数下界。

54项新增对照记录包含不同复制位置、原游标与副本不同推进速度、缺席组、空匹配、中文与非法UTF-8；原有128条集合迭代记录中的96条正向/反向/交错记录新增每步大小提示对照。总计2414项接口结果及513次起点差分通过，36项仓颉原生测试通过。本批采用构建、原生测试、接口契约和清单检查的专项验证；没有把前一批的40阶段完整验收冒充为本批新跑的结果。见[本批验证记录](acceptance/group-cursor-2026-10-04.md)。

主要库170条固有方法表的状态数量仍为132/38；本批增加的是trait对应的显式方法，记录在本节和仓颉接口清单中，不往170条固有方法分母中强加条目。
