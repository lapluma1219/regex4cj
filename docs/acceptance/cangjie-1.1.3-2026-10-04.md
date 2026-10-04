# Cangjie 1.1.3 适配验收

结论：当前实现已在Apple Silicon macOS上通过Cangjie 1.1.3完整验收。40个阶段全部通过；本次没有修改正则解析、自动机或匹配算法来迁就新编译器。

## 环境与版本隔离

- 操作系统：macOS 26.6，ARM64；构建SDK：MacOSX15.4.sdk。
- 编译器：Cangjie Compiler 1.1.3 (cjnative)，aarch64-apple-darwin。
- 项目管理器：Cangjie Project Manager 1.1.3。
- [官方安装包](https://cangjie-lang.cn/download/1.1.3)：cangjie-sdk-mac-aarch64-1.1.3.tar.gz。
- 官方与本地SHA-256一致：`7eff8d3b9119535cf3d05cb81526c5df391137dce908d744449f4edb99da3199`。
- 新SDK安装在同级缓存目录tools/cangjie-1.1.3；原tools/cangjie的1.0.5安装保留。
- 构建前将port、cli、examples/consumer的旧target移到缓存目录work/cj113-old-targets，1.1.3从无旧产物状态重新构建。
- Rust及Unicode参照未升级，完整验收复用了Cargo依赖缓存，设置CARGO_NET_OFFLINE=true。

## 项目调整

三个cjpm.toml的cjc-version改为1.1.3。环境脚本在没有显式CANGJIE_HOME时优先选择tools/cangjie-1.1.3，仍尊重调用者指定的SDK。README和上手指南同步新版本。

先用1.1.3编译原有代码确认兼容，再更新项目配置并运行完整验收。仅改版本号不被视为适配完成。

## 验证结果

| 项目 | 结果 |
|---|---:|
| 完整验收阶段 | 40/40 |
| 仓颉原生测试 | 32通过，0失败 |
| 原仓库匹配套件 | 3213通过 |
| 接口契约对照 | 2276通过（含128项集合双向迭代） |
| 字符串起点差分 | 513通过 |
| 单模式演示 | 13/13 |
| 多规则分类演示 | 7/7 |

还包含Rust/Python测试、Unicode数据检查、其他差分与独立消费者运行。计数存在包含关系，不计算为完成百分比。

完整机器记录见[验收JSON](cangjie-1.1.3-2026-10-04.json)，其中记录工具版本、阶段、计数、dirty状态及114份受测源文件的SHA-256；测试后逐项核对未变化。没有把未提交的修改冒充为已有提交的验收结果。

## 复现

安装1.1.3后，在仓库根目录执行：

```sh
export CANGJIE_HOME=/你的/cangjie-1.1.3
bash scripts/run.sh check
bash scripts/run.sh verify
```

切换SDK前清理或移走三个模块的target；如在本机使用兼容SDK，可设置SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk。无Cargo缓存时首次完整验收需要联网，不应设置离线模式。

此结论覆盖当前实现和现有测试范围，不代表整个原仓库已经完整移植。Windows、Linux、鸿蒙与其他CPU环境未在本轮验证；中心仓打包/发布与视频材料不在本轮范围。之前PPT仍对应其封面标明的1.0.5历史版本，尚未更新。
