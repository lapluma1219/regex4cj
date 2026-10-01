# regex4cj v0.2.0 多规则文本分类版

## 本版交付范围

在 v0.1.0 可用字符串库上增加 RegexSet 的常用流程：多模式构建、是否命中、全部命中编号、结果查询、规则数量与原始模式查询。采用统一多模式 NFA 扫描，包含可配置分类演示、API 映射与源码包。不代表原版 RegexSet 的全部接口或整个上游仓库已移植。

RegexSet 的当前调用方式见 [当前接口](api.md)。当时的验收命令是：

```sh
bash scripts/run.sh classify '订单 AB-123 需要退款，也需要开发票'
bash scripts/run.sh demo
bash scripts/run.sh check
bash scripts/run.sh verify
```

分类规则文件可以自行修改；无需修改库实现。旧单模式 API 和九个演示继续保留。完整示例仍通过独立 cjpm 包依赖 cjregex，不依赖 Rust 运行时。

## 验收目标

- 原有 9,532 条差分与新增 573 条 RegexSet 差分，共 10,105 条通过。
- 26 项仓颉原生测试、3 项 Rust 原生测试和4项 Python 数据导入测试通过。
- 九个原场景和六个分类场景通过，非法规则不静默忽略。
- 构建、使用、分类、错误退出与自定义规则入口可运行。
- 源码包校验正确，从无构建产物的解压目录能重新构建、运行演示与原生测试。

验收数量不是覆盖率；实际本机报告见 `$REGEX4CJ_LOCAL/work/verification.json`、`classification.json` 和 `set-benchmark.json`，要结合命令的整体退出码判断是否通过。

## 已知边界

- 模式语法沿用 v0.1.0；大小写 i、x/R/u、Age/Break 等仍未支持。
- Set 结果只返回编号；位置、捕获需额外调用 Regex。
- indices() 返回数组；起点搜索、复用结果缓冲区和 SetBuilder 暂缓。
- 256 条模式与集合总编译规模有固定上限，详见契约文档。
- 不含 bytes、多引擎优化或全部底层 API；仅在当前 Apple Silicon macOS / 仓颉 1.0.5 上验收。未验证跨平台、并发安全，未承诺 Rust 同级性能。

## 交付物

Git 中包含代码、示例、数据、测试、文档与许可证。`bash scripts/package.sh` 生成 `dist/regex4cj-0.2.0.tar.gz` 与校验文件；需要已提交的干净工作区。包内不含 SDK、完整上游或本机缓存；用户先准备 SDK，普通演示额外需要 Python，完整差分验收额外需要 Rust/Cargo。

完成本版验收即停止扩展，后续功能另行确定，避免把本里程碑无限扩张。
