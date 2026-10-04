# 追加展开与集合构造验收

2026-10-04，当前工作区在Apple Silicon macOS、Cangjie1.1.3下完整40阶段验收通过。

## 本批补齐的行为

- `Captures.expandInto(template, StringBuilder)`：把捕获模板展开内容追加到现有文本。
- `BytesCaptures.expandInto(template, ArrayList<UInt8>)`：对应字节行为，支持NUL和非法UTF-8。
- `RegexSetBuilder(Array<String>)`、`BytesRegexSetBuilder(Array<String>)`：从规则数组构造，保存快照，build时编译；继续支持无参数构造后逐条追加。

字符串与字节的原有expand便捷方法共用新增追加逻辑。构造器复制规则容器，调用者后来修改数组不影响Builder。未改变匹配引擎与搜索策略。

## 结果

| 检查 | 结果 |
|---|---:|
| 完整验收阶段 | 40/40通过 |
| 仓颉原生测试 | 34通过，0失败 |
| 原仓库匹配套件 | 3213通过 |
| 接口契约对照 | 2360通过 |
| 其中本批追加展开对照 | 80通过 |
| 其中本批数组构造对照 | 4通过 |
| 字符串起点差分 | 513通过 |
| 单模式/分类演示 | 13/13、7/7通过 |

新增的84项已包含在2360中，不能重复相加。原生测试另检查空模板、空集合、重复规则、无效模式延迟报错，以及构造后继续追加规则。比较结果包括缓冲区前缀和连续两次追加，避免仅证明返回片段相同。

## 可复核记录

[机器记录](append-builder-2026-10-04.json)包含提交号、dirty状态、环境、阶段和116份受测源码文件的SHA-256。该次验证包含此前尚未提交的修改，并非仅对HEAD提交作出的结论。Rust参照固定为`72d650cb0a880a01ab6dc2137c0888e8f89740f7`。

执行命令：

```sh
CARGO_NET_OFFLINE=true bash scripts/run.sh verify
```

本机已具备Cargo缓存。新环境首次运行需要联网时，去掉`CARGO_NET_OFFLINE=true`。专项验证位于[接口契约脚本](../../tests/verify_api_contracts.py)，调用固定Rust与仓颉的真实接口探针；原生测试位于[append_builder_test.cj](../../examples/consumer/src/append_builder_test.cj)。

## 边界

这是主要regex库现有兼容层的增量，不能称作整个原仓库已完成50%。完整公开regex-syntax、regex-automata及其他产品入口仍未移植。183个仓颉公开调用入口和132/170条有样例验证的映射都是各自范围的统计，不是全仓库完成率。

语法库下一阶段的初查见[公开范围](../syntax-scope.md)。本轮还纠正现状文档：原仓库固定版本没有公开LeftmostLongest匹配策略，不把注释讨论中的功能列为待移植能力。
