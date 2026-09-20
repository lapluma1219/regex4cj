# 官方图片所列资源的初步评估

图片是可选资源清单，不作为安装所有工具或启动多 Agent 的指令。

| 资源 | 决策与证据 |
|---|---|
| CangjieSkills | 已在仓库外的本地参考目录克隆并使用 cangjie-coding 技能查询 String.runes、StringBuilder、Rune 和 CLI 参数；已有分层本地检索，无需先自建向量 RAG。系统 Python 3.9 不支持其类型标注，使用 Python 3.11。https://github.com/cangjielanguage-sig/CangjieSkills |
| CangjieCorpus | 已在仓库外的本地参考目录克隆。README 标注 v1.0.0，部分链接含旧版路径；作为参考，不假定与 1.0.5 完全一致。https://github.com/cangjielanguage/CangjieCorpus |
| x2cj | 按精确名称检索尚未确认权威公开发布地址和 Rust 支持情况；待比赛资料提供链接后评估，不装同名替代品。 |
| ACEHarness | 找到维护方仓库，是工程任务多 Agent 平台；当前最小实验无需引入额外编排层。https://github.com/cangjielanguage-sig/ACEHarness |
| CangjieMagic / magic-cli / MagicExplorer | 图片描述为 Agent 框架、助手及示例；目前不是正则移植依赖。检索有多个无关 magic-cli 命中，未误当官方工具安装；准确发布入口待核实。 |

官方 SDK：https://cangjie-lang.cn/download/1.0.5
SDK SHA256：e07d22584237f065b30a771b7110a87a8931334c40be3a148090944ae916ed1f（已核对下载文件）。

初步结论：本轮 CangjieSkills 已产生实际价值，避免猜测 Rune 字面量和命令行参数用法。暂不投入向量库、MCP 服务或多 Agent 平台。
