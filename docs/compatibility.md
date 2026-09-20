# 当前兼容范围与剩余工作

此表是功能路线图，不是完整公开 API 清单或覆盖率统计；“已实现”仅表示下述范围通过当前测试，不表示完整上游兼容。顶层 regex 和底层 regex-syntax/regex-automata 的全量公开 API 尚未逐项提取和交付。

| 范围 | 当前状态 | 主要剩余工作 |
|---|---|---|
| escape | 已实现 | 补充非 CLI 输入测试 |
| find / is_match / find_iter 的基本行为 | 已有 find/isMatch/findAll | 惰性迭代器、更多输入与配置接口，拆出可依赖库包 |
| 基础语法、分支、分组 | 已实现子集 | 完整语法、AST/HIR 公开结构、精确错误类型与位置 |
| 字符类与集合运算 | 第二步完成基本标量区间与代数 | POSIX、Unicode 属性、字符类转义全集 |
| 重复 | 支持 * + ? 与 {m,n} 等及非贪婪 | 计数空白、堆叠量词、与上游一致的配置限制 |
| 捕获 | 未实现捕获结果；括号仅控制结构 | 捕获槽、编号／命名组、Captures、captures_iter |
| Unicode | 标量扫描、字面量、范围和字节偏移 | 固定 Unicode 数据、属性、大小写折叠、词边界 |
| Builder / flags | 未实现 | 大小写、多行、dot-all、CRLF、Unicode 开关等 |
| 替换、分割 | 未实现 | 替换模板、回调、零宽匹配细节 |
| bytes | 未实现 | 任意字节输入与禁用 Unicode 的语义 |
| RegexSet | 未实现 | 多模式编译与结果 API |
| 性能与资源管理 | 基础有序 NFA 与原型限制 | 工作区复用、字节 NFA、DFA、lazy DFA、预过滤等 |
| 其他仓库包 | 未移植 | regex-lite、C API、开发 CLI 及底层全量公开接口按最终范围推进 |

来源与实现差异详见 milestone-1.md（历史阶段）和 milestone-2.md（当前阶段）。固定上游版本见 baseline.json。
