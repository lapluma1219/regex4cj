# 文档入口

1. [上手指南](getting-started.md)：配置环境、运行、修改输入、独立复现。
2. [当前能力与验收](status.md)：支持范围、限制和当前测试证据。
3. [使用接口](api.md)、[语法与引擎](hir.md)、[声明目录](api-catalog.md)：调用方式。
4. [主要库接口对应](api-audit.md)、[功能范围台账](coverage/README.md)：定位实现和已知差异。
5. [比赛交付计划](delivery-plan.md)：唯一后续计划，以行为正确和可交付为第一目标。
6. [赛事要求](competition-requirements.md)：已记录要求和待官方确认事项。

历史复盘、计划和验收报告已从当前文件树移除，可从Git历史查看。`validation/`只保留当前机器验收证据，不新增按日期堆叠的复盘文档。源码生成清单由`scripts/`维护。

## 按功能查看测试

- [功能—特性—案例目录](testing.md)：区分具名案例、批量证据与未验证内容。
- [公开接口归属](test-api-map.md)：每个当前公开声明的功能归属；归属不代表逐接口行为已审计。
- 执行 `bash scripts/run.sh verify` 后，查看 `.build/work/functional-report.md` 的本次结果。
- [本次按功能验收结果](validation/functional.md)：当前保存的执行证据，与 latest.json 的运行编号一致。
- [测试文件结构与维护](../tests/README.md)：实际文件按功能归档。
- [测试覆盖说明](test-coverage.md)：各功能的验证范围、复现命令、代码覆盖率口径及边界。

- [演示视频逐步指南](demo-video-guide.md)：录制准备、命令、预期结果、逐步讲解与五分钟剪辑顺序。
