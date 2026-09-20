# 第五步：可依赖库、独立 CLI 与原生 API 测试

这是第五步的历史记录；第六步已加入内联 m/s/U 标志，当前范围见 milestone-6.md。

本阶段调整交付结构，不新增正则语法。库代码只有一份：CLI 和示例均通过 cjpm 的本地 path 依赖导入它。

## 项目结构

- `port/`：`cjregex` 静态库，入口为 `import cjregex.*`。公开 `Regex`、`RegexMatch`、`Captures`、`escape`、`isMetaCharacter`。解析器和 NFA 内部结构不作为公开 API。
- `cli/`：`regex_cli` 可执行包，依赖 `../port`，负责参数、退出码和验证输出协议。
- `examples/consumer/`：独立的 `regex_consumer` 可执行包，依赖 `../../port`，包含可运行示例及跨包公开 API 测试。

旧 `port/src/main.cj` 拆为 `port/src/escape.cj` 和 `cli/src/main.cj`。CLI 新路径为 `cli/target/release/bin/main`；第一至第四步文档中的旧二进制路径只适用于历史提交。当前 README 和脚本已更新。

## 在自己的项目中使用

假设你的 cjpm 项目与 regex4cj 仓库同级，在自己已有的 `cjpm.toml` 的 `[dependencies]` 中增加：

```toml
cjregex = { path = "../regex4cj/port" }
```

path 相对当前项目的 cjpm.toml，指向带有库清单的 `port` 目录，而不是仓库根目录。调用方式：

```cangjie
import cjregex.*

main(): Unit {
    let orders = Regex("(?<prefix>[A-Z]{2})-[0-9]{3}")
    println(orders.replaceAll("AB-123 CD-456", #"${prefix}-***"#))
}
```

输出 `AB-*** CD-***`。这里的 `#"..."#` 是仓颉原始字符串，保留 `${prefix}` 供正则模板展开；普通仓颉字符串会尝试执行语言自身的插值。

直接运行仓库提供的消费包，在仓库根目录进入 bash 并执行：

```sh
source scripts/env.sh
(cd examples/consumer && cjpm run)
(cd examples/consumer && cjpm test)
```

示例输出脱敏后的完整文本和捕获的编号 `123`、`456`。只构建仓颉库／CLI／消费包不需要 Rust；Rust 和 Python 用于跨语言验收。库没有 stdx、Rust FFI 或 std.regex 依赖。尚未发布包注册表版本或跨平台预编译二进制。

## 原生验证

`examples/consumer/src/api_test.cj` 的 10 项测试在库外部导入公开 API，覆盖：

1. NUL 字面量匹配、转义及 UTF-8 字节偏移。
2. NUL 捕获展开、替换文本和分割输入。
3. 未参与捕获、空捕获、负数／越界组号、未知名称。
4. 返回的名称数组不改变 Regex 内部元数据，多个捕获结果彼此独立。
5. 重复捕获保留与模板歧义。
6. 回调次数限制及无匹配时不调用。
7. 回调异常传播、停止后续调用以及 Regex 的后续复用。
8. 回调内部再次调用同一个 Regex。
9. Unicode 零宽替换／分割及段数限制。
10. 非法模式和负数替换次数报错。

Rust oracle 同时添加 2 项不经 CLI 的 NUL 测试，使用与仓颉一致的黄金预期，避免命令行参数不能携带 NUL 的限制。它们不是任意字节 bytes API 的测试，也不是完整 NUL 差分生成器。

`bash scripts/verify.sh` 顺序执行 Rust 构建与测试、仓颉库／CLI 构建、消费包构建／原生测试／运行，再运行原有 3,723 条差分用例及黄金／非法输入检查。任何阶段失败都会中止。原生测试结果在终端中显示，`verification.json` 仍记录 Python 差分套件结果。

本机仓颉测试运行器需本地端口通信；受限执行环境需要允许它绑定端口。这不是库的运行时网络依赖。

## 当前限制与下一步

本阶段使用仓颉 1.0.5 在 Apple Silicon macOS 上验证。原有语法子集、ASCII 捕获名称、资源限制、立即收集 API 及性能限制继续有效。增加包边界和原生测试不等于完成全部转译，也未验证线程间并发安全。

下一步优先扩展常用语法与内联标志，逐步补齐 Unicode 数据与词边界，再推进 bytes、RegexSet、惰性迭代与优化引擎。完整公开 API 的逐项映射与最终兼容清单仍需持续完善。
