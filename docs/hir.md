# 公开HIR：先读取正则的组成

`Hir` 是正则表达式解析并归一化后的结构。它回答“这条规则由什么组成”，不是拿规则去匹配文本。具体写法留在 `Ast` 里：`a`、`(?:a)` 和 `[a]` 在 AST 中不同，降到 HIR 后可以变成同一个字面量。现有 `Regex` 匹配入口没有改成从这棵 AST 构建。

## 一个能运行的例子

```cangjie
package hir_demo

import cjregex.*

main(): Int64 {
    let rule = Hir.parse("[0-9]{6}")
    match (rule.kind()) {
        case HirKind.Repetition(rep) =>
            println("最少重复：${rep.min}，是否贪婪：${rep.greedy}")
            match (rep.sub.kind()) {
                case HirKind.Class(c) =>
                    for (range in c.ranges()) {
                        println("字符码范围：${range.start} 到 ${range.end}")
                    }
                case _ => ()
            }
        case _ => ()
    }
    println(rule.properties().minimumLen())
    println(rule.properties().maximumLen())
    return 0
}
```

这条规则的外层是重复节点，最少和最多均为6；子节点是Unicode字符类，范围48到57，即字符`0`到`9`。最短和最长匹配长度都是6字节。业务可以用这些信息解释规则、检查规则是否固定长度，或在后续支持完整结构后分析允许哪些输入。

仓库还提供开发用结构对照入口：

```sh
bash scripts/run.sh raw hir '[0-9]{6}' true
```

输出：

```text
R(6,6,true,U(48-57){1,1}){6,6}
```

R表示重复，U表示Unicode字符类，花括号是该节点的最短/最长字节数。这个紧凑格式用于本仓库对照测试，不承诺等同原仓库的Debug或Display格式。

## 当前节点及构造入口

| HirKind | 内容 | 构造方式 |
|---|---|---|
| Empty | 可以匹配空文本 | Hir.empty() |
| Literal | 原始字节串 | Hir.literal(Array<UInt8>) |
| Class | Unicode范围或字节范围 | Hir.unicodeClass / Hir.byteClass |
| Repetition | 最少、最多、贪婪性、子节点 | Hir.repetition |
| Capture | 编号、可选名称、子节点 | Hir.capture |
| Concat | 顺序连接的子节点 | Hir.concat |
| Look | 零宽断言，含行首行尾和词边界 | Hir.look |
| Alternation | 按从左到右保留的分支；单字符分支会收成字符类 | Hir.alternation |

`Hir.dot` 按点号种类直接生成字符类，HIR 里没有单独的点号节点。`Hir.fail()`产生空字节类，表示不能匹配任何文本，和Empty不同。`HirRange`存储闭区间端点，反向传入会交换；字符类构造时检查字节/Unicode范围并合并重叠与相邻区间。Unicode区间可以跨越代理码点空洞，但端点必须是有效标量。

这些是有归一化行为的构造器：空字面量转为空节点，单个字符的字符类转为字面量；连接会展平、去掉空节点并合并相邻字面量；分支会展平，并把单字符或同类字符合并，也会抽出各分支共有的前缀；重复零次、一次及零宽子节点按原仓库规则简化。因此解析后不一定保留原始括号和写法。原始括号在 `Ast.parse` 里。

## 查询、数值与数据保护

- `kind()`读取节点类型及载荷；`subs()`读取直接子节点；`properties()`读取属性。
- `minimumLen()`返回`Option<UInt64>`：原仓库报告的最短匹配字节数；None表示未给出长度，不能单凭它证明没有匹配；64位长度溢出时饱和到UInt64最大值。
- `maximumLen()`同样返回字节长度；无可匹配文本、无界重复或长度溢出均为None，不能只凭None区分这三种情况。
- 重复次数和捕获编号为UInt32，对应原仓库u32。此处以已验证的64位平台为参照。
- 构造时保存数组快照，读取字面量、字符范围及子节点数组时返回副本。节点对象本身不可变，子节点可以安全共享；无需复制整棵树。

长度按UTF-8字节计算，例如`中文`长度是6，不是2。固定原仓库存在需保留的边界行为：`[a&&b]*`的最短/最长属性均为None，尽管零次重复可以匹配空文本；本批对照已覆盖。因此不要把这些属性当作所有匹配行为的独立判定器。

## 解析范围与错误

`Hir.parse(pattern)`使用UTF-8安全模式；`Hir.parse(pattern, false)`允许模式匹配非法UTF-8字节，例如`(?-u:\xFF)`。这与是否开启Unicode语法模式是两个不同选项，字节类与Unicode类仍会保留不同结构。

解析覆盖现有匹配器能接受的语法，包括分支、点号和断言。非法规则仍抛 `RegexError`。`toString()` 仍是原来的 Display 文本。`phase`、`name`、`primary` 和 `auxiliary` 另外给出种类和位置，位置里的偏移是 UTF-8 字节。`toPattern()` 的文本与上游 HIR Display 对照过一批模式。`visit` 是前序进入。`walk` 在子节点之后离开。`walkUntil` 可以在进入时停下。

`Ast.toHir()` 按内联标志 `i`、`m`、`s`、`U`、`x`、`R`、`u` 的作用域降级。`(?U)a?` 在 AST 里仍是贪婪的 `?`，降级时才交换成非贪婪。Perl 类、`\p` 和 `[a&&b]` 这种类集合运算在 AST 里保留原写法，降级时走现有的字符类表。`SyntaxParser` 可以先改默认标志和 UTF-8 安全，再解析或翻译。

`Hir.properties()` 还提供是否总是匹配合法 UTF-8、显式捕获数、静态捕获数、字面量判定，以及断言集合。长度口径仍是 UTF-8 字节。`PikeVM` 也可以直接接收 `Hir`，不必先把结构打印回字符串。

还没有字面量提取和公开 UTF-8 范围工具。`[:digit:]` 和 `[:^alpha:]` 已经是 AST 里的具名类节点，降级时走现有的 ASCII 类表。`Hir.subs()` 放在 Hir 对象上，是对原仓库 `HirKind::subs` 的显式适配。

## 如何验证

```sh
source scripts/env.sh
cargo build --manifest-path oracle/Cargo.toml --locked
bash scripts/run.sh build
python3 tests/verify_hir.py
```

验证使用锁定到原仓库固定提交的 regex-syntax 独立解析和构造，每个节点都比较结构、载荷及长度范围。当前这批是 367 组解析、235 组直接构造、41 组 Display 打印，另有 4 个非法规则。构造对照包括空类、反向/重叠范围、跨 Unicode 代理区间、非法 UTF-8、空捕获重复、字面量合并、断言、点号、分支前缀提取，以及 UInt64 长度溢出。原生测试另外检查返回数组被修改后不会影响节点。具体语法对照在 `python3 tests/verify_ast.py`，当前是 83 组形状、83 组 AST Display 和 50 组降级。属性对照在 `python3 tests/verify_props.py`，当前是 32 组，另有 6 组从 HIR 编译后再搜索。语法错误的种类和位置在 `python3 tests/verify_error_spans.py`，当前是 37 组。

`bash scripts/run.sh verify`已将HIR差分加入验收，共41个阶段。通过这些输入不代表完成了全部regex-syntax，更不能把节点种类或接口数直接换算为整个原仓库的完成百分比。
