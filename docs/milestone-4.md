# 第四步：替换模板、回调替换与分割

本阶段把已有的匹配和捕获用于文本处理，执行仍完全由仓颉实现。模式语法范围沿用第三步，新增文本操作不代表完整上游兼容。

## 公开接口

| 接口 | 语义 |
|---|---|
| `Regex.replace(text, replacement)` | 替换首次匹配 |
| `Regex.replaceAll(text, replacement)` | 替换全部非重叠匹配 |
| `Regex.replaceN(text, limit, replacement)` | 最多替换 limit 次；0 表示不限次数 |
| `Regex.replaceLiteral(text, limit, replacement)` | 不展开 `$`，对应 Rust `NoExpand`；0 表示不限次数 |
| `Regex.replaceWith(text, limit, replacer)` | 调用 `(Captures) -> String` 回调；0 表示不限次数 |
| `Captures.expand(template)` | 返回展开后的 String；Rust 接口则追加到调用方提供的缓冲区 |
| `Regex.split(text)` | 收集全部分段，包括开头／结尾的空字段 |
| `Regex.splitN(text, limit)` | 最多返回 limit 段，最后一段保留未分割的余文；0 返回空数组，1 返回原文一段 |

次数使用 Int64，负数明确抛出异常。Rust 的次数类型是 usize，不能传负数。分割结果是 `Array<String>`，尚未提供惰性迭代器；替换返回 String，没有移植 Rust 的 Cow 借用优化或 Replacer trait。

## 替换模板规则

- `$0` 是整体匹配，`$1` 等是编号组，`$name` / `${name}` 是命名组。
- 无括号名称最长读取 ASCII 字母、数字和下划线。因此 `$1suffix` 是一个名称，不是第 1 组接文字；应使用 `${1}suffix`。
- 花括号内读到第一个 `}`；名称中的点号、方括号需使用 `${x.y}` / `${x[0]}`。
- `$$` 输出一个字面量 `$`；反斜杠不会转义替换模板中的 `$`。
- 不存在或未参与匹配的组展开为空。没有闭合 `}` 的引用保留 `$` 并继续扫描；这不是模式语法错误。
- `${+1}` 和前导零数字引用遵循 Rust 数字解析语义。超长数字通过饱和解析避免溢出，超出组号范围时展开为空。

## 操作验证

完成 `bash scripts/verify.sh` 后运行 `bash scripts/demo.sh`，可以同时看到 Rust 和仓颉的输出。以下命令在 bash 中执行：

```sh
source scripts/env.sh
port/target/release/bin/main replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'order=AB-123; order=CD-456' '${prefix}-***' | python3 scripts/show_text.py
port/target/release/bin/main split-n ',' 'a,b,c' 2 | python3 scripts/show_text.py
port/target/release/bin/main split '' '中🙂' | python3 scripts/show_text.py
```

第一条输出 `"order=AB-***; order=CD-***"`，第二条依次输出 `"a"` 和 `"b,c"`，第三条输出 `""`、`"中"`、`"🙂"`、`""`。模板用 shell 单引号，避免 `$` 被 shell 提前解释。

CLI 的替换／展开／分割输出每行是一个 UTF-8 十六进制字符串；空行表示空字段，无输出表示没有字段。`show_text.py` 仅解码显示成 JSON 字符串，不参与匹配。`replace-with` 是验证用入口，使用固定回调输出调用序号、完整匹配和第 1 组，并额外输出回调次数。

## 实现原理与来源

固定上游仍为 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`：

- `regex-automata/src/util/interpolate.rs`：`string`、`find_cap_ref`、`find_cap_ref_braced`、`is_valid_cap_letter` 的模板解释规则。
- `src/regex/string.rs`：`Regex::replacen`、`Replacer`、`NoExpand`、`Captures::expand` 的行为契约。
- `regex-automata/src/meta/regex.rs`：`Split` / `SplitN` 的字段与尾部余文语义。

替换逐次查找匹配，把匹配前的原文和替换结果追加到 StringBuilder，最后追加尾部原文。达到 limit 后立即停止搜索，回调只对实际替换的匹配执行一次，不先收集全部捕获。没有 `$` 的模板及显式字面量替换只请求匹配位置，不分配捕获槽。

分割使用相同的位置搜索，把匹配区间当作分隔符，不把分隔符的捕获组插入结果。达到 limit - 1 次分割后直接保留余文。两种操作都沿用非重叠迭代规则：抑制紧邻前一匹配结尾的空匹配，按 Unicode 标量推进，避免无限循环和切断 UTF-8 字符。

## 验收与剩余范围

新增 `tests/verify_text_ops.py`：1,037 条差分用例、7 条独立黄金结果、4 个负数限制检查。覆盖空文本、零宽匹配、分支优先级、重复捕获、Unicode、模板歧义、字面量替换、回调次数、有限分割、随机组合，以及无需捕获的路径不触发捕获工作区限制。

模板当前每次替换重新解析；输入仍先构建标量和字节偏移表，分割结果立即收集。没有性能对标、流式输入、模板预编译或零拷贝保证。重复查找的总耗时也不能简单宣称对输入严格线性。

原有语法、组名和资源上限继续有效。完整 Unicode 属性、内联标志、bytes、RegexSet、DFA 和底层全量 API 尚未完成。项目仍是可执行包；下一步优先拆出可依赖库与独立 CLI，并建立不经过命令行的原生 API 测试，以覆盖 NUL、回调异常等边界。
