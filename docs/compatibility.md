# 当前兼容范围与剩余工作

此表是功能路线图，不是完整公开 API 清单或覆盖率统计；“已实现”仅表示下述范围通过当前测试，不表示完整上游兼容。顶层 regex 和底层 regex-syntax/regex-automata 的全量公开 API 尚未逐项提取和交付。

| 范围 | 当前状态 | 主要剩余工作 |
|---|---|---|
| escape | 已实现，含原生 NUL 验证 | 更多非 CLI 生成测试 |
| find / is_match / find_iter 的基本行为 | 已有 find/isMatch/findAll | 惰性迭代器、更多输入与配置接口 |
| 库交付 | 第五步提供 cjregex 静态库、独立 CLI 和外部消费包测试 | 包发布、跨平台验证、完整 API 清单 |
| 基础语法、分支、分组 | 已实现子集 | 完整语法、AST/HIR 公开结构、精确错误类型与位置 |
| 字符类与集合运算 | 基本标量区间、代数及第八步 POSIX 命名类 | Unicode 属性、字符类转义全集 |
| 字符转义 | 第七步支持 x/u/U 定长与花括号形式及 a/f/v | 其余 Unicode 属性和方向性边界 |
| 重复 | 支持 * + ? 与 {m,n} 等及非贪婪 | 计数空白、堆叠量词、与上游一致的配置限制 |
| 捕获 | 第三步支持编号、ASCII 名称、Captures、captures/capturesAll | Unicode 组名、惰性迭代、extract、可复用捕获工作区 |
| Unicode | Unicode 16.0.0 d/s/w、字节偏移、通用类别、Script/Script_Extensions 及第十三步二元属性 | Age/Break 枚举属性、大小写折叠、方向性边界 |
| 词边界 | 第十步支持 Unicode b/B | start/end、半边界和 ASCII 模式 |
| Builder / flags | 第六步支持内联 m/s/U、禁用与局部作用域 | Builder、大小写折叠 i、扩展模式 x、CRLF R、Unicode 开关 u 等 |
| 替换、分割 | 第四步支持模板展开、字面量／回调替换、次数限制、split/splitN | 惰性分割迭代器、Replacer trait 对应设计、模板预编译与分配优化 |
| bytes | 未实现 | 任意字节输入与禁用 Unicode 的语义 |
| RegexSet | 未实现 | 多模式编译与结果 API |
| 性能与资源管理 | 基础有序 NFA 与原型限制 | 工作区复用、字节 NFA、DFA、lazy DFA、预过滤等 |
| 其他仓库包 | 未移植 | regex-lite、C API、开发 CLI 及底层全量公开接口按最终范围推进 |

来源与实现差异详见 milestone-1.md（历史阶段）和 milestone-2.md（历史阶段）、milestone-3.md（历史阶段）、milestone-4.md（历史阶段）、milestone-5.md（历史阶段）、milestone-6.md（历史阶段）、milestone-7.md（历史阶段）、milestone-8.md（历史阶段）、milestone-9.md（历史阶段）、milestone-10.md（历史阶段）、milestone-11.md（历史阶段）、milestone-12.md（历史阶段）及 milestone-13.md（当前阶段）。固定上游版本见 baseline.json。

交付层次、估算与停止条件见 [delivery-plan.md](delivery-plan.md)。
