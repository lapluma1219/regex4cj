# regex4cj

仓颉1.1.3原生正则库。提供字符串/字节匹配、捕获、替换、分割、RegexSet，以及正在完善的AST/HIR与前向搜索接口。

在调用项目的cjpm.toml中将路径依赖指向本目录，使用`import regex4cj.*`。模块不依赖Rust运行库；仓库中的Rust程序仅供对照验证。

```cangjie
import regex4cj.*

main(): Int64 {
    println(Regex("[0-9]{6}").isMatch("编号123456"))
    return 0
}
```

公开语法与PikeVM接口仍有兼容差异，不能视为完整regex-syntax/regex-automata移植。完整源码交付请使用仓库根目录，其docs、examples/consumer与tests包含用法、测试和边界说明。源码包：https://github.com/lapluma1219/regex4cj

许可为MIT OR Apache-2.0，见本目录LICENSE文件及THIRD_PARTY_NOTICES.md。当前仅验证Apple Silicon macOS与仓颉1.1.3，其他平台和中心仓发布包尚未验收。
