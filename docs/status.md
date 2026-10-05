# 当前能力与验收

基线：仓颉STS 1.1.3，固定Rust原仓库`72d650cb0a880a01ab6dc2137c0888e8f89740f7`，regex 1.13.1，Unicode16。仓颉运行库不调用Rust；Rust只用于开发对照。

## 能做什么

| 使用层 | 当前提供 | 主要边界 |
|---|---|---|
| Regex / BytesRegex | 查找、捕获、替换、分割、起点搜索、惰性结果读取；match/capture/split 迭代器可 clone | 其余语言集成和资源行为未完全对齐 |
| RegexSet / BytesRegexSet | 多规则命中编号、编号迭代、Builder | 返回编号，不返回各规则的位置或捕获 |
| AST / HIR / SyntaxParser | 结构、类运算、属性、打印、访问与翻译；语法阶段可保留语义非法规则 | 尚不是完整regex-syntax；所有配置、访问协议和极端输入还未逐项审计 |
| 字面量与UTF-8工具 | 可配置提取上限、前后缀提取、序列交叉/合并/截断/偏好最小化/前后缀优化、公共前后缀，标量区间到UTF-8字节范围 | 有限语料上的过滤器检查不能代替全模式证明 |
| PikeVM | 一张 ThompsonNfa 上的多模式搜索；SearchInput 提供范围、锚定、指定模式和 earliest；`searchAll` 做非重叠迭代；`whichOverlapping` 也接收 SearchInput，按 MatchKind::All 报告范围内命中的模式编号；捕获可以保留全部分组、只保留整段匹配，或完全不记录；Cache 复用访问标记、活动线程和捕获槽工作区。非法 UTF-8 走前向字节自动机 | quit 不属于 Pike 的契约。捕获槽在搜索期间放在 Cache 里，结果仍由 Captures 单独保存。不记录捕获时，`isMatch` 仍为真，但搜索报不出区间。earliest 的重叠查询只保留范围起点上的空匹配。能匹配非法 UTF-8 的模式仍在 UTF-8 解析时拒绝 |
| ReverseNfa | 反向字节搜索，返回匹配起点；与前向 DFA 共用同一个字节编译器，反向模式把连接和 UTF-8 字节从末尾编起；可以一次编译多个模式。空模式列表得到一张永不命中的图。`SearchInput` 可限制范围并锚定到区间终点；打开每个模式的起点后，可以锚定到某一个模式。大小上限沿用编译超限错误 | 不返回捕获。不是把 Pike 的标量 Thompson 图边反过来。默认构造不打开每个模式的起点，指定模式编号仍会拒绝。超限句子是 `Compiled regex exceeds size limit`，密集 DFA 对外只显示 `error building NFA` |
| BoundedBacktracker | 单模式和多模式回溯、SearchInput、可复用的访问 Cache、容量错误；`searchAll` 可在一段字节范围内做非重叠迭代。非法 UTF-8 走前向字节自动机，访问预算仍按那张字节图的状态数检查。`memoryUsage` 按状态和字符类区间计数，并加上访问容量 | 一次只跑一个搜索。这个字节数是这张图自己的占用，不承诺与 Rust 的 `memory_usage` 相同。prefilter 不改变最左优先的匹配区间 |
| DenseDfa / SparseDfa | 多模式字符串和原始字节搜索、CRLF 锚点、范围、锚定、earliest、quit 字节；非法 UTF-8 按字节匹配，起点仍由反向字节 NFA 恢复。多模式和重叠搜索也走原始字节。打开每个模式的起点后，可以锚定到某一个模式。`overlap` 按 MatchKind::All 报告重叠半匹配（模式编号和终点）。`memoryUsage` 按转移槽计数。另有字节上限：下一状态会使 `状态数 * 1024` 超过上限时，报 `DFA exceeded size limit` | Unicode 词边界在构造时拒绝。未打开每个模式的起点时，指定模式编号的锚定搜索会拒绝。重叠结果不含起点。默认仍有 8192 个状态的上限。字节数按我们自己的 256 宽转移表计算，不承诺与原仓库等价类表的字节数相同 |
| HybridDfa | 搜索时按需生成状态；可以一次编译多个模式，也可以为每个模式准备锚定起点；缓存放不下起点状态就拒绝；`reset` 清空后重建；清空上限到了就放弃搜索 | 缓存容量按状态个数计算，不是原仓库的字节容量。放弃搜索的偏移不承诺与原仓库相同。`dfaSizeLimit` 仍是字符串步进缓存，没有改名成混合 DFA |
| OnePass | 能编成 one-pass 的模式做锚定搜索；`searchAnchored` 从指定偏移锚定 | 非 one-pass 在构造时拒绝。未锚定的 `try_search` 会报 `unanchored searches are not supported`。`cli-find onepass` 与原命令一样，在未加锚定参数时直接报这个错 |
| MetaRegex | 能编成 one-pass 时按标量边界做锚定搜索。否则用惰性 DFA，起点由反向 NFA 恢复。有限的必选字面前缀会跳过不可能的起点。两者都不可用时用 PikeVM | 没有原仓库 meta 的全部策略组合。prefilter 只跳过必选前缀，不改变最左优先的命中。不替换 `Regex.find` |
| LiteRegex | Unicode 关闭的 Pike 搜索。`\p` / `\P` 报 `Unicode character classes are not supported` | 只有字符串、一条模式。没有 `RegexSet`，也没有 bytes 版 |
| Rure | 包一层 `Regex`：`isMatch`、`find`、`findAt`。`capi/rure.h` 写出和 `regex-capi` 的名字对应 | 仓颉 1.1.3 静态库没有 C 导出，没有可链接的 C ABI，也没有独立的 C 测试程序 |
| DenseDfa 镜像 | `toImage` / `fromImage` 用 `CJD1` 记下模式列表和状态数，重新编译后再搜 | 不是 regex-automata 的转移表线格式。魔数不对、截断、尾部多余字节或状态数不一致都报 `invalid DFA serialization` |

`Regex.find`仍使用原有有序PikeVM路径，不因增加DFA类就自动改为DFA。`dfaSizeLimit`是字符串步进缓存预算；bytes搜索不使用它。`HybridDfa`是单独的惰性 DFA，没有替换这个预算。`memoryUsage` 和 DFA 字节上限都按本地表的槽数计算，不把原仓库的数字抄过来。

字符串位置均为UTF-8字节偏移；BytesRegex输入可包含非法UTF-8。前后查找、反向引用、全量大小写折叠并非固定原仓库支持的行为，不作为缺失任务。

## 本版修正与验证边界

新增实现曾在DFA分支起点、反向断言上下文、连续断言，以及AST语法拒绝、嵌套捕获编号、标志作用域、转义范围和打印上产生错误。本版修复并将反例纳入`tests/verify_engine_edges.py`和原生测试。AST使用独立语法校验模式，推迟Unicode属性/UTF-8语义检查到翻译阶段；不会重新使用字符串匹配的语义规则拒绝这些AST。

**最近一次全量验收（`07ff940`基线）53个阶段全部通过**，包括52项仓颉原生测试、401项新增边界差分、3213条原仓库匹配用例、2414项主要接口契约和513次字符串起点对照。演示13/13、分类7/7通过。证据：[完整报告](validation/latest.json)、[运行日志](validation/latest.log)。这些数量有不同统计口径，不应相加为功能数。

该次全量验收从`02e7a65`创建新克隆并覆盖待提交源码，不复制旧target/工作目录；没有设置REGEX4CJ_LOCAL和CARGO_TARGET_DIR覆盖，全部产物在新目录内生成。显式复用已安装的1.1.3 SDK、Rust工具链和Cargo依赖缓存，以离线模式运行；未读取外部原仓库检出或临时探针。这是独立源码复现，不是全新操作系统/空缓存首次下载验证。报告保留原始基线及dirty状态，并绑定160份受测输入的SHA-256；归档时已核对`07ff940`交付源码与受测源码一致。通过有限输入对照不证明任意输入、全部配置或性能完全等价，不发布“已完成80%”。

八进制专项补齐了显式开启时的 AST 字面量、字符类、范围端点和打印，并修复忽略大小写时过早折叠导致字符类解析失败的问题。该专项有 1039 项 AST/打印/翻译对照、20 项真实匹配对照及 3 项默认关闭检查；当时仓颉原生测试为 53 项。见[专项证据](validation/syntax.json)。那次没有重跑全部 53 个阶段。

本轮在那之后继续实现交付计划里的几块现有引擎：多模式收成一张 `ThompsonNfa`，Pike 搜索和 earliest 从优先级并起点出发，命中模式集合从每个模式自己的起点出发；`PikeCache` 记下活动线程的状态编号，`reset` 同时清掉命中和线程。`MatchIter`、`CaptureIter`、`SplitIter` 以及 bytes 对应迭代器可以 `clone`，复制后的游标各自前进。`LiteralLimits` 可配置四项提取上限，默认仍是 10、10、100、250。`SparseDfa` 在区间生成后释放密集 `next`/`lookMatch`，`DenseDfa` 保留它们。DFA 接受 CRLF 锚点。`Regex.find` 仍走原来的单模式 Pike 路径。

随后补上公共 `SearchInput`：范围、锚定、指定模式和 earliest 接到 Pike 与有界回溯；DFA 另外接受 quit 字节，并在范围内搜索。PikeCache 复用访问标记。回溯有独立的 `BacktrackCache`，也能一次编译多个模式。非法 UTF-8 字节不会进入 Pike 或回溯。

这之后的对照：Pike 503 次搜索和 1 次非法范围，DFA 39 条全串搜索加 12 组输入查询，回溯 42 次搜索加 9 组输入查询，消费者测试 56 项通过。没有重跑 `scripts/verify.sh` 的 53 个阶段。

随后 DFA 可以一次编译多个模式。先出现的模式优先，命中结果带模式编号；起点仍由该模式的反向 NFA 恢复。指定模式编号的锚定搜索继续拒绝。新增 12 组多模式查询与原仓库一致，消费者测试 57 项通过。

`DenseDfa.overlap` 和 `SparseDfa.overlap` 用 MatchKind::All 做重叠搜索，结果是半匹配：模式编号和终点，不含起点。10 组查询与原仓库一致，包括同一终点上的多个模式、空匹配和锚定。多模式最左优先、重叠半匹配，以及 quit 字节，也可以直接作用在无法构成 UTF-8 的原始字节上。quit 报出的字节是 `\xHH`。默认构造没有每个模式的起点，指定模式编号会拒绝。构造时打开这个选项后，最左优先和重叠搜索都可以锚定到某一个模式，未知编号是未命中。

`HybridDfa` 在搜索过程中生成转移，而不是构造时展开整张表。它可以一次接收多个模式，也可以打开每个模式的锚定起点。8 次搜索和 2 次 `reset` 后的再次搜索与 `hybrid::regex::Regex` 的区间一致。缓存小于起点状态数时拒绝，消息含 `smaller than minimum required`。清空上限为 0 且缓存只够起点状态时，搜索报 `gave up searching at offset`。这个偏移不与原仓库的字节缓存对齐。

字面量序列补上了与 `regex-syntax` 的 `Seq` 相同的一批操作：前向/反向交叉、合并、把另一条序列插入第一个空字面量、保留首尾字节、按偏好最小化、按偏好优化前后缀、反转字节、排序、去重、标成非精确、最长公共前缀和后缀，以及合并或交叉后的最大条数（`maxUnionLen` / `maxCrossLen`，无限序列得到空结果，乘法按饱和处理）。74 组操作与原仓库逐条一致，其中包括 `sam`/`samwise`、空字面量截断、`farm` 那组先截断再最小化，以及 `samantha`/`sam` 在优化后仍保持精确。另外用 16 个模式的真实匹配检查了前后缀序列：每个匹配都能被序列中的某条字面量解释，精确字面量必须等于整个匹配，非精确字面量必须是匹配的前缀或后缀。这一轮盖住 38 个匹配区间。

嵌套上限现在连错误下划线的区间也和原仓库一致。30 个样例覆盖重复、分组、连接、分支、字符类并集和差集。`sizeLimit` 的通过/失败仍由原来的限额对照覆盖。未闭合的特殊词边界（例如 `\b{start`）从左花括号起标出，和原仓库同一段。

反向搜索可以按 `SearchInput` 的字节范围查询，也可以要求匹配结束在范围终点。45 次整段搜索和 24 次范围查询与 dense DFA 的 `try_search_rev` 一致，其中包括空范围、多字节标量和指定模式编号时的拒绝。反向图和前向 DFA 现在共用同一个字节编译器；Pike 的标量图仍然单独存在。

Pike 搜索的捕获槽改由 `PikeCache` 持有。Save 写入前复制池中的一行，`reset` 保留这些行供下一次搜索复用，命中结果仍写入单独的 `Captures`。`whichOverlapping(SearchInput)` 在范围内按每个模式自己是否命中来收集编号，锚定和指定模式编号都生效；`earliest` 只保留范围起点上的空匹配。503 次 Pike 对照仍然一致。字符串和 bytes 的捕获组数量、静态长度和名称在 21 个模式上与 `regex::Regex` 一致。`SetMatches` 的双向迭代仍由原来的接口契约覆盖。

`cli-find pikevm -p 模式 -y 文本` 按原仓库 `find match pikevm` 打印 `模式:起点:终点:转义文本`，成功退出码是 0，错误退出码是 1。20 条命令与 PikeVM 搜索一致，计时表不在这条契约里。

`BoundedBacktracker.searchAll` 返回非重叠匹配，命令行 `backtrack-iter` 把它打成 `模式:起点:终点:转义文本`。空匹配的推进方式与原仓库 `Searcher` 相同。访问预算装不下整段文本时打印 `haystack of length N is too long`，而不是未命中。18 条迭代命令，以及原来的 42 次搜索和 9 次范围查询，都与 `BoundedBacktracker` 一致。prefilter 和 `memory_usage` 仍不在这 1 分里。

`ReverseNfa` 可以一次编译多个模式。先出现的模式优先。`find` 同时返回模式编号和匹配起点。打开每个模式的起点后，指定模式编号的反向搜索才会生效；单模式构造和原来的 `nfa-rev-query` 仍拒绝它。24 次多模式反向搜索与打开了 `starts_for_each_pattern` 的反向 dense DFA 一致。原来的 45 次整段搜索和 24 次范围查询仍然一致。

`BoundedBacktracker.searchAll` 也可以只在 `SearchInput` 的字节范围内迭代。锚定输入最多返回一条。16 条范围迭代与 `Searcher` 在同一范围上的非重叠结果一致。原来的 42 次搜索和 9 次范围查询仍然一致。

Pike 和有界回溯在非法 UTF-8 上改走前向字节自动机。25 次原始字节搜索与 `PikeVM`、`BoundedBacktracker` 的区间和分组一致。能匹配非法 UTF-8 的模式仍由 UTF-8 解析拒绝。`ThompsonNfa` 可以直接从 HIR 构建：解析失败的阶段是 `parse`，大小上限失败的种类是 `CompiledTooBig`。反向 NFA 的空模式列表搜索结果是未命中；大小上限仍抛出编译超限，密集 DFA 把同一失败显示成 `error building NFA`。prefilter 不改变最左优先命中的位置，`memory_usage` 和 DFA 的字节预算仍不发明数字。`Regex.find` 和 `dfaSizeLimit` 没有改。

`OnePass` 的搜索从当前位置锚定。`a+` 在 `xxaaa` 上是未命中，在 `aaa` 上是 `0..3`。不能编成 one-pass 的模式在构造时拒绝，错误句子与原仓库一致。`MetaRegex` 的单次查找与 `meta::Regex::find` 在这批样例上一致。one-pass 编不成时改走惰性 DFA，惰性 DFA 也编不成时改走 Pike。必选字面前缀只用来跳过起点。`LiteRegex` 的 `\w`、`\d`、`\b` 和 `\p{L}` 与 regex-lite 一致。`Rure` 的命中区间与 `regex::Regex` 一致。`DenseDfa.toImage` 再 `fromImage` 之后的搜索区间与重新编译的 dense regex 一致；坏镜像被拒绝。这 25 条产品命令通过。`cli-find` 现在接受 `pikevm`、`backtrack`、`onepass`、`meta`、`lite`、`dense`、`sparse`、`hybrid`、`regex`，39 条命令的 stdout、stderr 和退出码与对应 Rust 引擎一致。`--table` 会在匹配行之后打印 `search time` 和 `total matches`；时间是各边自己测的，条数一致。`cli-half`、`cli-capture`、`cli-which` 共 16 条命令与对应引擎一致。`which` 使用 MatchKind::All。1 字节的 DFA 预算两边都失败，50000000 字节两边都成功。`memoryUsage` 不要求与 Rust 的字节数相等，但 Unicode `\w` 比 ASCII `\w` 更大，更长的分支也更大。`onepass` 在 `cli-find` 上保持未锚定，因此报 `unanchored searches are not supported or enabled`。顶层 `regex` 和 `lite` 只收一条模式。

台账已验收权重仍是 5。这些新产品没有改记成验收通过。没有重跑全量 53 个阶段。

仓颉1.1.3 SDK默认规则的`cjlint`检查已消除全部强制项（MANDATORY），仍有837条建议项，主要是命名、函数长度和异常注释；这不等于零建议或中心仓包认证。汇总及源码哈希见[lint证据](validation/lint.json)。

主要库收录3213条原仓库匹配测试，另有接口、AST/HIR、提取器、UTF-8、各引擎差分和原生回归。测试条数不等于功能数。AST探针、接口映射也不是全仓库公共契约的完整枚举。

## 独立性与交付边界

仓库包含源码、示例、测试数据、Unicode快照、生成器、许可证及Rust锁文件。SDK、系统SDK、Python、Rust/Cargo是环境前提，首次Cargo取依赖需联网或预备缓存。构建脚本不搜索同级`regex4cj-local`，默认生成内容写入被忽略的`.build/`和各模块`target/`。`REGEX4CJ_LOCAL`仅是兼容旧用法的输出目录覆盖。

目前验证平台为Apple Silicon macOS与仓颉1.1.3，不能据此宣称Linux/Windows或赛事评测平台已经通过。Git源码交付独立性与中心仓`.cjp`包完整性是两个检查；中心仓包和发布尚未验收。视频、官方模板、账号报名及平台提交不由代码测试代替。

唯一后续路线见[比赛交付计划](delivery-plan.md)，运行方法见[上手指南](getting-started.md)。
