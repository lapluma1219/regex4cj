# 测试：按功能查找、按特性验证

完整运行：`bash scripts/run.sh verify`。只检查组织和映射：`bash scripts/run.sh test-catalog`。

## 文件结构

- `functional/<功能>/verify*.py`：批量对照用例、边界与随机回归，原有断言保持不变。
- `functional/<功能>/cases.json`：可逐条阅读的规则、输入、预期输出和公开接口关联；每一组均有具名案例；个别命令用 `args` 明确表示完整调用参数。
- `catalog/features.json`：功能组、测试文件和源码归属，是完整执行入口使用的唯一注册表。
- `catalog/native.json`：仓颉原生测试函数与特性对应表。
- `support/`：共享进程协议和对照辅助代码。
- `tooling/`：测试目录检查器、数据生成器自身的 Python 单元测试。
- `upstream/`：仓库内保存的原仓库测试数据，保持原始结构。
- `run_suite.py`、`run_feature_cases.py`：批量套件与具名案例的执行器。

仓颉原生测试位于 `examples/consumer/src/<功能>_test.cj`，例如 `capture_test.cj`、`set_test.cj`、`structure_test.cj`；共享辅助函数在 `test_support.cj`。保留在消费者包内，是为了直接验证用户通过依赖调用本库的方式，并遵守 cjpm 的测试发现方式。

## 功能目录

| 目录 | 功能 |
|---|---|
| search | 查找、首次匹配、匹配顺序、原仓库综合语料 |
| capture | 分组提取、元数据、迭代和接口契约 |
| text | 替换、模板展开、分割 |
| set | 多规则命中及结果遍历 |
| bytes | 字节输入 |
| syntax | 语法、选项、错误、限制 |
| unicode | 字符属性、大小写、词边界 |
| structure | AST、HIR、转换、结构属性 |
| tools | 字面量提取及 UTF-8 范围 |
| nfa | NFA、PikeVM、捕获模式 |
| backtrack | 有界回溯 |
| reverse | 反向搜索 |
| dfa | 密集、稀疏、惰性 DFA |
| products | 组合引擎、Lite、兼容入口和跨引擎回归 |
| cli | 命令行输入输出协议 |

完整结果在 `.build/work/functional-report.md`，逐案例数据在 `feature-cases.json`，整体状态和源码哈希在 `verification-run.json`。若设置输出目录覆盖，则使用相应目录。

案例应说明正常、边界、异常、配置交互或重复调用特性；不要用脚本数或案例数推断覆盖率。跨功能回归只注册一次。既有大批量语料和原生断言无需全部翻抄为 JSON。

测量代码执行覆盖：`bash scripts/run.sh coverage`（需 SDK 的 cjcov）。在隔离副本运行同一套验收，成功后生成 `.build/coverage/latest.json`；失败时不保留旧的成功报告。其统计口径、检查范围与边界见 [测试覆盖说明](../docs/test-coverage.md)。
