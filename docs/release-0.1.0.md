# regex4cj v0.1.0 学习与演示版

## 交付目标

本版交付一个范围明确、可运行、可验证、可演示、可作为仓颉依赖使用的成果，先供使用者学习理解。依据本次用户选择冻结现有功能，后续增强暂缓；不把完整移植所有上游内容作为本次交付的前置条件。

本版不是 Rust regex 全仓库的完整替代品，不是生产成熟度或任意输入下完全等价的声明。

## 包含什么

| 交付物 | 位置 / 入口 |
|---|---|
| 纯仓颉静态库 | `port`，`import cjregex.*` |
| 一致的运行入口 | `bash scripts/run.sh help` |
| 带独立预期的九个演示场景 | `bash scripts/run.sh demo` |
| 可修改的仓颉应用例子 | `bash scripts/run.sh example` |
| 无 Rust 的日常验收 | `bash scripts/run.sh check` |
| 固定版本 Rust 差分验收 | `bash scripts/run.sh verify` |
| 上手、原理与 API 文档 | `getting-started.md`、`learning-guide.md`、`api.md` |
| 可复现的数据、许可证与依赖锁 | `data`、`THIRD_PARTY_NOTICES.md`、各包锁文件 |
| 可独立解压的源码包 | `bash scripts/package.sh` 生成 tar.gz 与 SHA-256 |

## 功能边界

支持字符串匹配、捕获、模板/字面量/回调替换、分割；基本分组分支和重复；字符类及集合代数；m/s/U 标志、锚点与 b/B 词边界；Unicode 16.0.0 简写类、通用类别、书写系统及二元属性。详细公共接口见 API 文档。

未支持大小写折叠 i、x/R/u 标志、方向性词边界、Unicode 捕获名称、Age/Break 枚举属性、Builder、惰性迭代、bytes、RegexSet、多种优化引擎和上游全量底层公开 API。前后查找和反向引用也不在 Rust regex 的支持范围内。不要用本版判断全部正则语法是否有效。

实现采用受限解析器、有序 Thompson NFA 和 Unicode 标量输入。生成的数据表来自固定上游，匹配不依赖 Rust 运行时；不是逐行翻译所有 Rust 模块。当前只在 Apple Silicon macOS / 仓颉 1.0.5 上验收，尚未承诺跨平台、并发安全或与 Rust 同级的性能。

## 验收标准

- 演示九个场景全部与独立预期一致；包括无结果和未支持模式的报错。
- 20 项仓颉原生测试通过，涵盖库外调用、捕获、NUL、文本操作及 Unicode。
- 完整差分套件 9,532 条通过；另有 2 项 Rust 原生测试、4 项 Python 导入测试和黄金/错误检查。
- 数据生成物与快照一致，来源可对固定上游核对。
- 源码包不含 SDK、完整上游仓库、缓存或机器专用配置；解压后能通过统一入口构建、演示和验收。

原始 Rust 参照固定到 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`，Git/Cargo 负责获取锁定依赖。9,532 是测试数量，不是覆盖率；成功输出必须结合整个验收命令的退出码。

## 怎样交给别人

配置好 SDK 后，可以直接传源码包及校验文件。接收者校验 SHA-256、解压、进入目录，然后运行：

```sh
bash scripts/run.sh demo
bash scripts/run.sh check
```

需要严格对照时再准备 Rust/Cargo 并运行 `verify`。源码包没有预装工具链，不能宣传成“任何机器免配置双击运行”。包内命令不依赖 `.git`；只有从 Git 仓库重新打包需要 Git 和干净工作区。

当前学习阶段以 README 的四份入门文档为主，里程碑文档只用于追踪实现历史。未来按实际使用中的缺口恢复扩展，不把继续加功能当成本版验收的一部分。
