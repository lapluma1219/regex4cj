# 功能范围与已知限制

基线：仓颉 STS 1.1.3，固定 Rust 原仓库 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`，regex 1.13.1，Unicode 16。仓颉运行库不调用 Rust；Rust 只用于开发对照。

## 交付范围

这是一个可独立构建、调用、演示和验证的仓颉正则库，**不是 Rust regex 整个仓库的完整移植**。主要使用入口是 `Regex`、`BytesRegex`、`RegexSet` 及 Builder；语法结构和独立引擎属于部分兼容的扩展接口。

| 使用层 | 当前提供 | 主要边界 |
|---|---|---|
| Regex / BytesRegex | 查找、捕获、替换、分割、起点搜索；match/capture/split 迭代器独立 clone | 语言集成、分配与资源行为未完全对齐 |
| RegexSet / BytesRegexSet | 多规则命中编号、双向编号迭代、Builder | 返回编号，不返回各规则的位置或捕获 |
| AST / HIR / SyntaxParser | 结构、类运算、属性、打印、访问与翻译；显式八进制配置 | 所有配置、访问协议和极端输入尚未逐项审计，不是完整 regex-syntax |
| 字面量与 UTF-8 工具 | 可配置提取上限、前后缀提取、序列运算、公共前后缀；标量区间转换为 UTF-8 字节范围 | 有限过滤器测试不能代替全模式证明 |
| ThompsonNfa / PikeVM | 多模式图、模式/HIR构建、捕获配置、SearchInput、非重叠迭代与命中模式集合 | 标量图与非法 UTF-8 输入使用的字节图分开；无完整原仓库 NFA 状态检查协议；Cache 槽池复用不等于原实现的内存上限 |
| ReverseNfa | 多模式反向字节搜索，返回模式编号和起点；范围及指定模式锚定 | 不返回捕获；与前向 DFA 共用字节编译器，不是对公开标量图直接反转 |
| BoundedBacktracker | 多模式、范围、捕获配置、访问预算、Cache 和非重叠迭代 | 同一引擎同时只进行一次搜索；非法 UTF-8 路径使用字节自动机；预算和内存布局不等同原仓库 |
| DenseDfa / SparseDfa | 多模式字符串/字节搜索、范围、锚定、earliest、quit、CRLF、重叠半匹配；稀疏版释放密集转移数组 | 构造时拒绝 Unicode 词边界；指定模式锚定需显式打开；默认 8192 状态上限；预算与 memoryUsage 按本地槽数估算，不等于实际进程占用或原仓库字节数 |
| HybridDfa | 按需生成转移、缓存重建与清空上限、多模式和重叠半匹配 | 容量单位是状态数；放弃偏移和原仓库不同；不替换顶层 Regex 的匹配路径 |
| OnePass | 保守的字节图资格检查，之后调用 PikeVM 做锚定搜索 | **不是独立 one-pass 执行引擎**。接受/拒绝集合与原仓库不同，例如部分 Unicode 类被本地检查拒绝；不能声称性能或构造错误完全一致 |
| MetaRegex | 在上述锚定适配路径、惰性 DFA、PikeVM 间选择；必选前缀过滤；返回包含捕获的结果 | 策略组合不完整，DFA 路径通过 PikeVM 补捕获；不替换 Regex.find |
| LiteRegex | Unicode 标量匹配，ASCII 的 d/s/w、词边界及大小写折叠；点号、取反类、字符串迭代 | 只支持一条字符串模式；拒绝 Unicode 属性类；共享解析器接受的语法及错误文本并非完整 regex-lite 契约 |
| Rure | 仓颉类型，转发 Regex 的 isMatch、find、findAt | **没有 C ABI**，不能被 C 程序链接；不提供占位 C 头文件 |
| DenseDfa 镜像 | CJD1 保存模式并重新编译、核对状态数 | 仅默认搜索配置；quit、重叠模式、指定模式起点配置显式拒绝导出；不是原仓库的转移表格式 |
| CLI | 演示入口，以及部分 find/half/capture/which 对照协议 | 不是完整 regex-cli；未完整移植文件输入、配置和所有子命令 |

`SearchInput` 范围限制匹配位置，断言仍能查看范围外文本。字符串位置是 UTF-8 字节偏移；BytesRegex 和搜索输入的字节形式可包含非法 UTF-8。启用 UTF-8 语法时，能匹配非法 UTF-8 的模式仍会被拒绝。捕获配置为 none 时，Pike/回溯的 `isMatch` 可以为真，但搜索结果没有可报告区间。

`Regex.find` 保持原有有序 Pike 路径。`dfaSizeLimit` 只控制字符串步进缓存，bytes 搜索不读取它；它不是 HybridDfa 的容量配置。前后查找、反向引用、全量大小写折叠也不属于固定原仓库支持的行为。

## 运行与验证边界

已验证平台是 Apple Silicon macOS + 仓颉 STS 1.1.3。其他操作系统、全新系统环境和中心仓安装/发布未由本次验收证明。仓颉库运行时不依赖 Rust；完整对照测试通过锁文件获取固定版本的 Rust 依赖。

配置环境、运行示例、依赖方式和复现命令统一见 [README](../README.md)。测试结果及其适用范围见 [测试结果](test-coverage.md)，逐项案例见 [测试目录](testing.md)。

仓库交付源码、示例、固定测试数据、Unicode 快照、生成器及许可证。SDK 和工具链由使用者安装，生成的缓存和构建产物不属于交付源码。
