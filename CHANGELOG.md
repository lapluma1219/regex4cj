# 变更记录

## 0.3.0 — 字符串语法与起点搜索版

- 内联 `(?i)` / `(?-i)` 按 Unicode 简单大小写折叠匹配。捕获和替换仍返回原文；`ß` 不展开成 `SS`。
- 字符类在取反、交集和差集之前折叠。
- 支持 `x`、`R`、`u`、字符串安全的 `(?-u)`、方向性词边界、Unicode 捕获名、八进制（仅 Builder）和 ASCII 行终止符。
- Age 按版本累积查询；Grapheme/Word/Sentence Break 只做集合查询，不做切分。
- 增加 `findAt`、`isMatchAt`、`capturesAt`、`shortestMatch`、`next()` 迭代、`staticCapturesLen`、`extract` 和可复用捕获位置。搜索始终对着整段原文。
- `RegexBuilder` / `RegexSetBuilder` 只包装已经生效的选项。`dfaSizeLimit` 和 `sizeLimit` 会失败，不会静默忽略。
- RegexSet 的进程计时仍包含启动。`repeat-find` 在同一次进程里分开记录构造和后续查找。
- 仍然没有任意字节引擎和 DFA。

## 0.2.0 — 多规则文本分类版

- 新增 RegexSet / SetMatches，通过统一多模式 NFA 收集全部命中规则。
- 新增 JSON 规则配置、分类入口、六个分类演示和仓颉调用示例。
- 新增差分、单 Regex 基准、NUL、结果独立性与资源限制验证。
- 明确接口适配、数量限制、性能基线和暂缓的进阶能力。

## 0.1.0 — 学习与演示版

- 冻结现有仓颉原生正则库功能，提供明确的 API 与不支持范围。
- 提供统一运行入口、九个带预期结果的场景、可修改的独立仓颉示例。
- 提供上手指南、实现原理、验证说明和源码打包流程。
- 保留固定上游 Rust 差分验收、Unicode 数据生成与许可证。
- 暂缓新增特性，先交付使用和学习；不宣称完整迁移整个上游仓库。
