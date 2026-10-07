# 按功能阅读测试

运行命令见 [README](../README.md)，已归档结果见 [测试结果](test-coverage.md)。本页是自动生成的案例目录，静态目录不表示实际运行结果。

本目录区分**功能组 → 特性 → 具体案例**与尚未细分的批量回归证据。一个脚本可以覆盖多个特性；其通过不能证明整组功能完整。

具名案例含输入、操作和独立预期，同时与固定 Rust 版本对照。批量套件保持原断言、固定种子、语料和跳过规则，不重复计数。

当前全部公开声明均有功能归属，但归属不是行为验证。逐接口特性审计尚未完成。完整声明见 [接口清单](api-catalog.md)，案例中的 `api_refs` 记录已核实的部分特性关联。

范围边界以 [当前能力](status.md) 为准：不支持与未验证分开看；下列未验证项不表示功能不存在。

## 查找文本

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `find-normal` | 普通输入返回首次匹配 | `["[0-9]+", "订单123已完成"]` | 未运行（静态目录） |
| `find-first` | 多个匹配返回第一个 | `["[0-9]+", "12和34"]` | 未运行（静态目录） |
| `find-absent` | 没有匹配返回空结果 | `["[0-9]+", "没有数字"]` | 未运行（静态目录） |
| `find-start` | 匹配位于开头 | `["[0-9]+", "12abc"]` | 未运行（静态目录） |
| `find-end` | 匹配位于结尾 | `["[0-9]+", "abc12"]` | 未运行（静态目录） |
| `find-empty-input` | 非空规则在空文本中不命中 | `["a", ""]` | 未运行（静态目录） |
| `find-utf8` | 位置使用 UTF-8 字节偏移 | `["中", "a中b"]` | 未运行（静态目录） |
| `find-empty-progress` | 空匹配按字符边界推进并结束 | `["", "中"]` | 未运行（静态目录） |
| `find-priority` | 分支按先后优先 | `["a&#124;ab", "ab"]` | 未运行（静态目录） |
| `find-greedy` | 贪婪重复优先长匹配 | `["a+", "aaa"]` | 未运行（静态目录） |
| `find-lazy` | 非贪婪重复优先短匹配 | `["a+?", "aaa"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/search/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 基础匹配与演示协议 | [verify](../tests/functional/search/verify.py) | 未运行（静态目录） |
| 匹配优先级、空匹配与非法规则 | [verify_matching](../tests/functional/search/verify_matching.py) | 未运行（静态目录） |
| 原仓库可适用的平面区间样例（含跳过记录） | [verify_upstream_sample](../tests/functional/search/verify_upstream_sample.py) | 未运行（静态目录） |
| 原仓库字符串、字节及规则集验收语料 | [verify_upstream_suite](../tests/functional/search/verify_upstream_suite.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| Unicode 零宽匹配与限制 | [zeroWidthUnicodeAndLimits](../examples/consumer/src/search_test.cj) | consumer-test 整套：未运行（静态目录） |
| 指定起点与语法配置 | [searchFromOffsetAndConfiguredSyntax](../examples/consumer/src/search_test.cj) | consumer-test 整套：未运行（静态目录） |
| 复制迭代器的位置独立 | [clonedIteratorsKeepIndependentCursors](../examples/consumer/src/search_test.cj) | consumer-test 整套：未运行（静态目录） |
| 文本最早匹配、范围约束与捕获迭代器复制 | [textConvenienceMethodsAndClonedCapturesPreserveContract](../examples/consumer/src/search_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 提取与遍历捕获

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `capture-absent-empty` | 未参与分组与匹配到空字符串不同 | `["(a)?(b*)", ""]` | 未运行（静态目录） |
| `capture-unicode` | 捕获内容完整且位置为字节偏移 | `["(中)(🙂)", "a中🙂b"]` | 未运行（静态目录） |
| `capture-no-match` | 无匹配时仍有分组元数据但无捕获结果 | `["(a)", "b"]` | 未运行（静态目录） |
| `capture-name-present` | 命名分组：存在 | `["(?<n>a)", "ba"]` | 未运行（静态目录） |
| `capture-name-absent` | 命名分组：未参与 | `["(?<n>a)?b", "b"]` | 未运行（静态目录） |
| `capture-name-empty` | 命名分组：空内容 | `["(?<n>a*)", ""]` | 未运行（静态目录） |
| `capture-name-unknown` | 命名分组：名称不存在 | `["(?<n>a)", "a"]` | 未运行（静态目录） |
| `capture-repeat` | 重复分组保留最后一次捕获 | `["(a)+", "aaa"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/capture/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 捕获槽、重复分组与可空路径优先级 | [verify_captures](../tests/functional/capture/verify_captures.py) | 未运行（静态目录） |
| 分组数量、固定分组数与名称 | [verify_group_info](../tests/functional/capture/verify_group_info.py) | 未运行（静态目录） |
| 迭代、配置、起点与捕获等接口契约组合 | [verify_api_contracts](../tests/functional/capture/verify_api_contracts.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 缺失分组与下标边界 | [captureAbsenceAndBounds](../examples/consumer/src/capture_test.cj) | consumer-test 整套：未运行（静态目录） |
| 捕获结果和元数据独立 | [captureResultsAndMetadataAreIndependent](../examples/consumer/src/capture_test.cj) | consumer-test 整套：未运行（静态目录） |
| 保留捕获结果与模板展开 | [retainedCaptureAndTemplateExpansion](../examples/consumer/src/capture_test.cj) | consumer-test 整套：未运行（静态目录） |
| 分组游标复制后独立推进 | [groupCursorCopiesHaveIndependentPositions](../examples/consumer/src/capture_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 替换与分割

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `replace-named` | 命名分组模板替换 | `["(?<prefix>[A-Z]{2})-[0-9]{3}", "AB-123 CD-456"]` | 未运行（静态目录） |
| `replace-zero-width` | 空匹配替换保留完整字符 | `["", "中🙂"]` | 未运行（静态目录） |
| `split-empty-fields` | 分割保留首尾和中间空字段 | `[",", ",a,,b,"]` | 未运行（静态目录） |
| `split-limit` | 次数上限保留剩余内容 | `[",", "a,b,c"]` | 未运行（静态目录） |
| `split-zero` | 零次分割返回空序列 | `[",", "a,b,c"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/text/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 模板、字面量、回调替换及分割边界 | [verify_text_ops](../tests/functional/text/verify_text_ops.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| NUL 字符替换与分割 | [nulReplacementAndSplit](../examples/consumer/src/text_test.cj) | consumer-test 整套：未运行（静态目录） |
| 回调次数限制与无匹配 | [callbackLimitAndNoMatch](../examples/consumer/src/text_test.cj) | consumer-test 整套：未运行（静态目录） |
| 回调异常后复用 | [callbackExceptionAndReuse](../examples/consumer/src/text_test.cj) | consumer-test 整套：未运行（静态目录） |
| 回调内重用同一正则 | [callbackCanReuseSameRegex](../examples/consumer/src/text_test.cj) | consumer-test 整套：未运行（静态目录） |
| 惰性分割限制与字节捕获元数据 | [lazySplitLimitsAndByteCaptureMetadata](../examples/consumer/src/text_test.cj) | consumer-test 整套：未运行（静态目录） |
| 追加展开保留缓冲区原内容 | [appendExpansionPreservesBuffers](../examples/consumer/src/text_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 多规则匹配

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `set-empty` | 空规则集不命中且全部命中条件为真 | `[[], "a"]` | 未运行（静态目录） |
| `set-no-hit` | 没有规则命中 | `[["x", "y"], "ab"]` | 未运行（静态目录） |
| `set-some` | 部分命中仍返回原规则数 | `[["a", "z"], "ab"]` | 未运行（静态目录） |
| `set-all` | 全部规则命中 | `[["a", "b"], "ab"]` | 未运行（静态目录） |
| `set-duplicates` | 重复规则各有编号 | `[["a", "a"], "a"]` | 未运行（静态目录） |
| `set-overlap` | 重叠规则都被报告 | `[["ab", "b"], "ab"]` | 未运行（静态目录） |
| `set-order` | 编号按规则顺序而非出现位置 | `[["b", "a"], "ab"]` | 未运行（静态目录） |
| `set-empty-pattern` | 空规则命中空文本 | `[["", "a"], ""]` | 未运行（静态目录） |
| `set-unicode` | Unicode 多规则匹配 | `[["中", "🙂", "x"], "中🙂"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/set/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 全部命中编号与单规则结果一致性 | [verify_sets](../tests/functional/set/verify_sets.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 数组构建与构建错误 | [setBuilderArrayConstructionAndErrors](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 迭代大小提示跟踪槽位 | [setSizeHintTracksSlotsNotHits](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 空规则集与空匹配 | [emptySetAndEmptyMatches](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 重叠、重复规则及编号顺序 | [setOverlapDuplicatesAndOrdering](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 结果和规则数组独立 | [setResultsAndPatternsAreIndependent](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| NUL 与 Unicode | [setNulAndUnicode](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 规则集与单规则结果一致 | [setAgreesWithIndependentRegexes](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 非法下标及构建失败 | [setInvalidIndexAndConstruction](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |
| 双向迭代、复制与生命周期 | [setIteratorDirectionsCloneAndLifetime](../examples/consumer/src/set_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 字节数据处理

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `bytes-raw` | 非 UTF-8 字节可以按字节匹配 | `["bytes-find", "(?-u).", "ff"]` | 未运行（静态目录） |
| `bytes-unicode` | Unicode 点匹配完整三字节字符 | `["bytes-find", ".", "e4b8ad"]` | 未运行（静态目录） |
| `bytes-invalid` | Unicode 模式不匹配非法 UTF-8 | `["bytes-find", ".", "ff"]` | 未运行（静态目录） |
| `bytes-empty` | 空字节输入不匹配非空规则 | `["bytes-find", "a", ""]` | 未运行（静态目录） |
| `bytes-nul` | 字节串中间的 NUL | `["bytes-find", "\\x00", "610062"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/bytes/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 字节匹配和捕获 | [verify_bytes](../tests/functional/bytes/verify_bytes.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 原始字节匹配 | [bytesRegexMatchesRawBytes](../examples/consumer/src/bytes_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字节迭代器快照与独立位置 | [byteIteratorsSnapshotAndKeepIndependentCursors](../examples/consumer/src/bytes_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字节接口最短匹配、命名捕获和分割限制 | [byteConvenienceMethodsRetainOffsetsAndNames](../examples/consumer/src/bytes_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字节捕获与分割迭代器复制后游标独立 | [clonedByteIteratorsKeepIndependentCursors](../examples/consumer/src/bytes_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 规则创建与语法选项

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `syntax-unclosed-group` | 非法规则被拒绝且有错误信息 | `["(", "a"]` | 未运行（静态目录） |
| `syntax-unclosed-class` | 非法规则被拒绝且有错误信息 | `["[", "a"]` | 未运行（静态目录） |
| `syntax-orphan-repeat` | 非法规则被拒绝且有错误信息 | `["*a", "a"]` | 未运行（静态目录） |
| `capture-duplicate-name` | 重复分组名称被拒绝 | `["(?<n>a)(?<n>b)", "ab"]` | 未运行（静态目录） |
| `config-case-sensitive` | 默认区分大小写 | `["a", "A"]` | 未运行（静态目录） |
| `config-ignore-case` | 忽略大小写 | `["(?i)a", "A"]` | 未运行（静态目录） |
| `config-case-scope` | 局部选项不泄漏 | `["(?i:a)b", "AB"]` | 未运行（静态目录） |
| `config-dot-default` | 默认点号不匹配换行 | `[".", "\n"]` | 未运行（静态目录） |
| `config-dot-all` | 开启点号匹配换行 | `["(?s:.)", "\n"]` | 未运行（静态目录） |
| `config-multiline` | 多行模式行首断言 | `["(?m)^b", "a\nb"]` | 未运行（静态目录） |
| `config-anchor-default` | 默认行首只匹配文本开头 | `["^b", "a\nb"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/syntax/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 字符集合运算与计数重复 | [verify_classes](../tests/functional/syntax/verify_classes.py) | 未运行（静态目录） |
| 选项作用域与贪婪、多行、点号行为 | [verify_flags](../tests/functional/syntax/verify_flags.py) | 未运行（静态目录） |
| 转义、字符范围端点与非法输入 | [verify_escapes](../tests/functional/syntax/verify_escapes.py) | 未运行（静态目录） |
| 扩展选项、位置与早停匹配 | [verify_syntax](../tests/functional/syntax/verify_syntax.py) | 未运行（静态目录） |
| 非法规则与规则集错误文本 | [verify_errors](../tests/functional/syntax/verify_errors.py) | 未运行（静态目录） |
| 大小和缓存限制的有限样例 | [verify_limits](../tests/functional/syntax/verify_limits.py) | 未运行（静态目录） |
| 语法错误类别与字节位置 | [verify_error_spans](../tests/functional/syntax/verify_error_spans.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 非法规则和负数限制 | [invalidPatternAndNegativeLimit](../examples/consumer/src/syntax_test.cj) | consumer-test 整套：未运行（静态目录） |
| 多行和点号选项 | [multilineAndDotAllFlags](../examples/consumer/src/syntax_test.cj) | consumer-test 整套：未运行（静态目录） |
| 局部贪婪选项与绝对锚点 | [scopedGreedAndAbsoluteAnchors](../examples/consumer/src/syntax_test.cj) | consumer-test 整套：未运行（静态目录） |
| NUL 与标量转义 | [escapedNulAndUnicodeScalars](../examples/consumer/src/syntax_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 字符类别与 Unicode

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `unicode-han` | 汉字属性及字节偏移 | `["find", "\\p{Han}+", "a中文b"]` | 未运行（静态目录） |
| `unicode-digit` | Unicode 阿拉伯数字 | `["find", "\\d", "٣"]` | 未运行（静态目录） |
| `unicode-ascii` | 关闭 Unicode 后仅匹配 ASCII 数字 | `["find", "(?-u:\\d)", "٣"]` | 未运行（静态目录） |
| `unicode-fold` | Kelvin 字符大小写折叠 | `["find", "(?i:k)", "K"]` | 未运行（静态目录） |
| `unicode-absent` | 不同文字属性不匹配 | `["find", "\\p{Greek}", "中文"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/unicode/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 简单大小写折叠与类运算顺序 | [verify_case](../tests/functional/unicode/verify_case.py) | 未运行（静态目录） |
| ASCII 类及补集 | [verify_ascii_classes](../tests/functional/unicode/verify_ascii_classes.py) | 未运行（静态目录） |
| Unicode 简写类的边界及随机标量 | [verify_unicode](../tests/functional/unicode/verify_unicode.py) | 未运行（静态目录） |
| 词边界与零宽迭代 | [verify_boundaries](../tests/functional/unicode/verify_boundaries.py) | 未运行（静态目录） |
| 类别别名与属性语法 | [verify_properties](../tests/functional/unicode/verify_properties.py) | 未运行（静态目录） |
| 文字系统及扩展属性 | [verify_scripts](../tests/functional/unicode/verify_scripts.py) | 未运行（静态目录） |
| 二元属性及别名优先级 | [verify_binary](../tests/functional/unicode/verify_binary.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 大小写折叠保留原文本 | [simpleCaseFoldingKeepsOriginalText](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| ASCII 类与 NUL | [posixClassesWithNul](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| ASCII 类范围与名称回退 | [posixClassesAreAsciiAndNamesCanFallBack](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| Unicode 简写类与 NUL | [unicodeShorthandsAndNul](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| Unicode 词边界 | [unicodeWordBoundaries](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| Unicode 一般类别 | [unicodeGeneralCategories](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| 文字系统属性 | [unicodeScripts](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |
| 二元属性 | [unicodeBinaryProperties](../examples/consumer/src/unicode_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 语法结构解析与转换

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `ast-print-literal` | 语法解析后输出 literal | `["ast-print", "a"]` | 未运行（静态目录） |
| `ast-print-group` | 语法解析后输出 group | `["ast-print", "(a&#124;b)+"]` | 未运行（静态目录） |
| `ast-print-empty` | 语法解析后输出 empty | `["ast-print", ""]` | 未运行（静态目录） |
| `ast-print-invalid` | 未闭合分组拒绝解析 | `["ast-print", "("]` | 未运行（静态目录） |
| `hir-literal` | HIR 保留字节值与长度 | `["hir", "a", "true"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/structure/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| AST 节点、位置与转换 | [verify_ast](../tests/functional/structure/verify_ast.py) | 未运行（静态目录） |
| HIR 结构、长度与打印 | [verify_hir](../tests/functional/structure/verify_hir.py) | 未运行（静态目录） |
| HIR 属性及构建搜索 | [verify_props](../tests/functional/structure/verify_props.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| AST 保留 HIR 简化掉的分组 | [astKeepsTheGroupThatHirCollapses](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| 解析与转换分别校验 | [syntaxValidationKeepsTranslationSeparate](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| 八进制字符类保留数值和形式 | [octalAstClassesKeepTheirValueAndSpelling](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| HIR 暴露六位数字规则结构 | [hirExposesSixDigitStructure](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| HIR 构造保持快照独立 | [hirSmartConstructorsPreserveSnapshots](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| 长度溢出、空值与失败区分 | [hirLengthOverflowAndEmptyAreDistinctFromFailure](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| 明确拒绝不支持的结构 | [hirRejectsUnimplementedStructuresExplicitly](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| Unicode 和边界规则结构往返 | [reviewedAstUnicodeAndBoundaryRoundTrips](../examples/consumer/src/structure_test.cj) | consumer-test 整套：未运行（静态目录） |
| 错误位置对象保留坐标和文本 | [syntaxSpansAndErrorsRetainCoordinates](../examples/consumer/src/structure_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字符集合运算与空集合 | [hirClassAlgebraChecksMembershipAndEmptyResults](../examples/consumer/src/structure_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| 语法遍历进入和离开均可提前停止 | [hirTraversalVisitsEnterLeaveAndHonorsBothStops](../examples/consumer/src/structure_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 字面量和 UTF-8 工具

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `utf8-ascii` | UTF-8 编码范围 ascii | `["utf8", "0", "127"]` | 未运行（静态目录） |
| `utf8-two-byte` | UTF-8 编码范围 two-byte | `["utf8", "128", "128"]` | 未运行（静态目录） |
| `utf8-nul` | UTF-8 编码范围 nul | `["utf8", "0", "0"]` | 未运行（静态目录） |
| `utf8-reject-reversed` | 拒绝非法编码范围 reversed | `["utf8", "10", "9"]` | 未运行（静态目录） |
| `utf8-reject-surrogate` | 拒绝非法编码范围 surrogate | `["utf8", "55296", "55296"]` | 未运行（静态目录） |
| `utf8-reject-overflow` | 拒绝非法编码范围 overflow | `["utf8", "1114112", "1114112"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/tools/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 前后缀提取与序列操作 | [verify_literals](../tests/functional/tools/verify_literals.py) | 未运行（静态目录） |
| 标量区间到 UTF-8 序列 | [verify_utf8](../tests/functional/tools/verify_utf8.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| NUL 字符匹配与转义 | [nulMatchingAndEscape](../examples/consumer/src/tools_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字面量、UTF-8 与早停样例 | [literalsUtf8AndEarliestMatchThePinnedCorpus](../examples/consumer/src/tools_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字面量序列空值、无限值和组合契约 | [literalSequenceEmptyInfiniteAndFiniteContracts](../examples/consumer/src/tools_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| UTF-8 范围边界与非法输入 | [utf8RangesRejectInvalidScalarsAndKeepBoundaries](../examples/consumer/src/tools_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## NFA 构建与 PikeVM

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `pike-earliest` | PikeVM 最早匹配 earliest | `["pike-earliest", "zaa", "a+"]` | 未运行（静态目录） |
| `pike-absent` | PikeVM 最早匹配 absent | `["pike-earliest", "aa", "z"]` | 未运行（静态目录） |
| `pike-empty` | PikeVM 最早匹配 empty | `["pike-earliest", "", "a"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/nfa/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 模式编号、捕获、范围与锚定 | [verify_pike](../tests/functional/nfa/verify_pike.py) | 未运行（静态目录） |
| HIR 构建、反向配置与大小错误 | [verify_nfa_build](../tests/functional/nfa/verify_nfa_build.py) | 未运行（静态目录） |
| 范围内重叠编号、锚定及早停 | [verify_pike_overlap](../tests/functional/nfa/verify_pike_overlap.py) | 未运行（静态目录） |
| 全部、隐式、禁用捕获模式 | [verify_capture_modes](../tests/functional/nfa/verify_capture_modes.py) | 未运行（静态目录） |
| 非法 UTF-8 的 Pike 与回溯路径 | [verify_bytes_nfa](../tests/functional/nfa/verify_bytes_nfa.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 模式编号、区间及捕获 | [pikeReportsPatternSpanAndCaptures](../examples/consumer/src/nfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 锚定搜索断言能查看范围外上下文 | [pikeAnchoredSearchSeesTextOutsideTheRange](../examples/consumer/src/nfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 搜索锚定与规则开头断言的区别 | [anchoredSearchIsNotTheSameAsACaret](../examples/consumer/src/nfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 图搜索复用缓存线程 | [oneGraphPikeKeepsThreadsInTheCache](../examples/consumer/src/nfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 字节范围与空模式集 | [reviewedPikeByteRangesAndEmptyPatternSet](../examples/consumer/src/nfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 捕获模式非法参数拒绝 | [captureModesRejectUnknownValuesAcrossEngines](../examples/consumer/src/dfa_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| 搜索配置和非法范围 | [searchInputConfigurationPreservesSourceAndRejectsRanges](../examples/consumer/src/nfa_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| 缓存复用不泄露旧捕获 | [pikeCacheResetsCapturedStateAfterMiss](../examples/consumer/src/nfa_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| NFA 图检查与下标边界 | [graphInspectionChecksIndicesAndReachableAccept](../examples/consumer/src/nfa_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 有界回溯搜索

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `backtrack-greedy` | 有界回溯 greedy | `["backtrack", "default", "a+", "zaa"]` | 未运行（静态目录） |
| `backtrack-absent` | 有界回溯 absent | `["backtrack", "default", "z", "aa"]` | 未运行（静态目录） |
| `backtrack-empty` | 有界回溯 empty | `["backtrack", "default", "a", ""]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/backtrack/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 匹配区间与访问预算错误 | [verify_backtrack](../tests/functional/backtrack/verify_backtrack.py) | 未运行（静态目录） |
| 非重叠迭代与空匹配推进 | [verify_backtrack_iter](../tests/functional/backtrack/verify_backtrack_iter.py) | 未运行（静态目录） |
| 指定字节范围的连续搜索 | [verify_backtrack_span](../tests/functional/backtrack/verify_backtrack_span.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 捕获结果与预算错误 | [boundedBacktrackerReportsCapturesAndBudgetErrors](../examples/consumer/src/backtrack_test.cj) | consumer-test 整套：未运行（静态目录） |
| 复用访问缓存 | [backtrackerReusesItsVisitedCache](../examples/consumer/src/backtrack_test.cj) | consumer-test 整套：未运行（静态目录） |
| 空匹配、缓存参数和反向结果 | [backtrackerEmptyMatchesAndCacheArguments](../examples/consumer/src/products_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 反向搜索

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `reverse-rightmost` | 反向搜索 rightmost | `["nfa-rev", "a", "aba"]` | 未运行（静态目录） |
| `reverse-unicode` | 反向搜索 unicode | `["nfa-rev", "中", "a中b"]` | 未运行（静态目录） |
| `reverse-absent` | 反向搜索 absent | `["nfa-rev", "z", "aa"]` | 未运行（静态目录） |
| `reverse-empty` | 反向搜索 empty | `["nfa-rev", "", ""]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/reverse/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 反向搜索起点 | [verify_reverse](../tests/functional/reverse/verify_reverse.py) | 未运行（静态目录） |
| 多模式反向搜索与指定模式锚定 | [verify_reverse_many](../tests/functional/reverse/verify_reverse_many.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 反向搜索返回起点 | [reverseSearchReportsTheMatchStart](../examples/consumer/src/reverse_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## DFA 搜索

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `dense-greedy` | dense 搜索 greedy | `["dfa", "dense", "a+", "zaa"]` | 未运行（静态目录） |
| `dense-lazy` | dense 搜索 lazy | `["dfa", "dense", "a+?", "aaa"]` | 未运行（静态目录） |
| `dense-absent` | dense 搜索 absent | `["dfa", "dense", "z", "aa"]` | 未运行（静态目录） |
| `dense-empty` | dense 搜索 empty | `["dfa", "dense", "", ""]` | 未运行（静态目录） |
| `sparse-greedy` | sparse 搜索 greedy | `["dfa", "sparse", "a+", "zaa"]` | 未运行（静态目录） |
| `sparse-lazy` | sparse 搜索 lazy | `["dfa", "sparse", "a+?", "aaa"]` | 未运行（静态目录） |
| `sparse-absent` | sparse 搜索 absent | `["dfa", "sparse", "z", "aa"]` | 未运行（静态目录） |
| `sparse-empty` | sparse 搜索 empty | `["dfa", "sparse", "", ""]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/dfa/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 密集、稀疏和惰性引擎的区间搜索 | [verify_dfa](../tests/functional/dfa/verify_dfa.py) | 未运行（静态目录） |
| 三类 DFA 的字节输入 | [verify_dfa_bytes](../tests/functional/dfa/verify_dfa_bytes.py) | 未运行（静态目录） |
| 指定模式锚定与未知编号 | [verify_dfa_pattern](../tests/functional/dfa/verify_dfa_pattern.py) | 未运行（静态目录） |
| 惰性 DFA 多模式与锚定 | [verify_hybrid_many](../tests/functional/dfa/verify_hybrid_many.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| 惰性引擎重叠搜索及复用 | [hybridOverlapBuildsTransitionsAndCanBeReused](../examples/consumer/src/dfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 镜像拒绝无法保留的配置 | [dfaImagesNeverSilentlyDropConfiguration](../examples/consumer/src/dfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 密集和稀疏引擎区间一致 | [denseAndSparseDfaReportTheSameSpan](../examples/consumer/src/dfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 多模式搜索规则优先级 | [multiPatternDfaPrefersTheEarlierRule](../examples/consumer/src/dfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 反向恢复保留优先级和上下文 | [dfaReverseRecoveryRetainsPriorityAndContext](../examples/consumer/src/dfa_test.cj) | consumer-test 整套：未运行（静态目录） |
| 序列化截断、篡改和往返一致性 | [dfaImagesRejectEveryTruncationAndCorruptHeader](../examples/consumer/src/dfa_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |
| 退出字节与缓存重置 | [dfaQuitBytesAbortAndCacheResetPreservesResults](../examples/consumer/src/dfa_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 组合引擎和扩展入口

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `onepass-anchored` | 扩展入口 onepass anchored | `["onepass", "a+", "aa"]` | 未运行（静态目录） |
| `onepass-unanchored-miss` | 扩展入口 onepass unanchored-miss | `["onepass", "a+", "zaa"]` | 未运行（静态目录） |
| `meta-search` | 扩展入口 meta search | `["meta", "a+", "zaa"]` | 未运行（静态目录） |
| `lite-ascii-class` | 扩展入口 lite ascii-class | `["lite", "\\w", "é"]` | 未运行（静态目录） |
| `rure-absent` | 扩展入口 rure absent | `["rure", "z", "aa"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/products/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| OnePass、Meta、Lite、Rure 与镜像有限案例 | [verify_products](../tests/functional/products/verify_products.py) | 未运行（静态目录） |
| 语法及引擎的固定种子边界回归 | [verify_engine_edges](../tests/functional/products/verify_engine_edges.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|
| Lite 标量匹配与 ASCII 类 | [liteMatchesScalarsWithAsciiClasses](../examples/consumer/src/products_test.cj) | consumer-test 整套：未运行（静态目录） |
| Meta 使用惰性引擎仍保留捕获 | [metaKeepsCapturesWhenUsingHybrid](../examples/consumer/src/products_test.cj) | consumer-test 整套：未运行（静态目录） |
| 扩展入口锚定和迭代 | [adaptersRespectAnchorsAndIterationResults](../examples/consumer/src/products_coverage_test.cj) | consumer-test 整套：未运行（静态目录） |

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 命令行协议

### 已具名的特性与案例

| 案例 | 特性 | 输入（规则；文本） | 结果 |
|---|---|---|---|
| `cli-find-match` | 命令行匹配协议 match | `["cli-find", "pikevm", "-p", "a", "-y", "za"]` | 未运行（静态目录） |
| `cli-find-absent` | 命令行匹配协议 absent | `["cli-find", "pikevm", "-p", "z", "-y", "aa"]` | 未运行（静态目录） |
| `cli-find-unicode` | 命令行匹配协议 unicode | `["cli-find", "pikevm", "-p", "中", "-y", "a中"]` | 未运行（静态目录） |

操作、附加参数及完整预期见 [案例数据](../tests/functional/cli/cases.json)。

### 保留的批量回归证据

| 验证范围 | 测试文件 | 本次套件结果 |
|---|---|---|
| 匹配行格式与退出状态 | [verify_cli_find](../tests/functional/cli/verify_cli_find.py) | 未运行（静态目录） |
| 半匹配、捕获、编号及资源趋势 | [verify_rest](../tests/functional/cli/verify_rest.py) | 未运行（静态目录） |

### 仓颉原生特性案例

| 特性 | 测试函数 | 执行证据 |
|---|---|---|

**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。

## 构建与交付（不计为功能特性通过）

完整验收另执行数据一致性、接口清单、Python 工具测试、Rust/仓颉构建、仓颉原生测试及演示。

跨平台、性能基准及代码分支覆盖率未纳入本流程。验收摘要与测量口径见 [测试结果](test-coverage.md)。运行方式见 [README](../README.md)。

报告只展示实际执行结果，不生成原仓库完成百分比，也不把套件通过提升成全部特性通过。
