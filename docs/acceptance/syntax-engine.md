# 语法层和 PikeVM

这一批把三层入口补到可以单独调用：

- `Hir` 增加断言、分支和点号到字符类的转换。`toPattern()` 与固定上游的 HIR Display 对照了 41 组。构造对照 235 组，解析对照 367 组。
- `Ast` 保留分组、重复、括号类、Perl 类、Unicode 属性、`[a&&b]`、`[a--b]`、`[a~~b]`，以及 `[:digit:]`、`[:^alpha:]`。83 组形状与 regex-syntax 一致，其中 50 组 `toHir()` 与 `Hir.parse` 的结构一致。同一批 83 组的 `toPattern()` 与 AST Display 一致。`(?U)a?` 的贪婪位保持语法上的 true，降到 HIR 才换成非贪婪。
- `Hir.properties()` 增加 UTF-8、显式捕获数、静态捕获数、字面量判定和断言集合。32 组和 regex-syntax 一致。最短、最长长度的原有 367 组解析和 235 组构造仍然一致。
- `SyntaxParser` 带上和 Builder 相同的标志、八进制、嵌套上限和 UTF-8 安全配置，可以解析 AST、解析 HIR，或把 AST 翻译成 HIR。
- `PikeVM` 可以从 `Hir` 直接编译再搜索。同一批模式上，这条路径和从模式字符串编译的搜索结果一致，抽了 6 组。此前 19 组和 regex-automata 的范围、锚定、多模式对照仍然有效。

`RegexError` 在保持原有 Display 文本的同时，给出 `parse` 或 `translate`、种类名、主位置和可选辅助位置。位置是字节偏移加 1 开始的行和标量列。37 组与 regex-syntax 的错误结构一致，其中包括 `中(` 这种多字节偏移，以及重复标志、重复捕获名的辅助位置。原有 49 组错误 Display 文本没有改。

`walk` 先进入再离开。`walkUntil` 在进入回调返回 false 时停下，不再访问子节点和后续兄弟。

`Regex.find` 仍是不锚定、最左优先、不重叠。重叠匹配、反向 NFA、lazy DFA、完全 DFA、one-pass、有界回溯和 meta 没有做。状态编号不是上游编号。

这一轮 45 个验收阶段全部通过，记录在 `regex4cj-local/work/verification-run.json`。基线提交是 `c01354b`，当时工作区还有未提交改动。
