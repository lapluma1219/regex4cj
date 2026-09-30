# regex4cj v0.3.0 字符串语法与起点搜索版

这一版让模式语法和“从原文中间接着找”真正影响结果。匹配仍在仓颉里完成。它不是 Rust regex 仓库的完整移植。

## 现在可以做什么

- 用 `(?x)` 忽略空白和 `#` 注释，包括字符类里面的空白。`\ ` 仍是一个空格。
- 用 `(?R)` 把一行的结尾看成回车、换行，或回车紧挨换行。点号不会把回车和换行当成一个字符吃掉。
- 用 `(?-u)` 把 `\d`、`\w`、`\s` 和词边界收成 ASCII。会匹配到非 ASCII 的点号或字符类会在构造时失败。普通非 ASCII 字面量仍然可以。
- 用 `\b{start}`、`\b{end}`、`\<`、`\>` 表示词的某一侧。
- 用 `(?<名>...)` 这样的 Unicode 捕获名。
- 用 `\p{age=1.1}` 查询“到这个 Unicode 版本为止已经出现的字符”。`\p{gcb=...}`、`\p{wb=...}`、`\p{sb=...}` 只判断字符属于哪个集合，不会把文本切成词或句。
- `findAt`、`isMatchAt`、`capturesAt` 以及 RegexSet 的 `isMatchAt` / `matchesAt` 使用原文字节偏移。偏移必须落在字符边界上，否则抛出异常。
- `shortestMatch` 返回最早能结束的匹配终点，不是贪心 `find` 的终点。`a+` 在 `aaaaa` 上的最短终点是 1。
- `findIter`、`capturesIter`、`splitIter` 用 `next()` 逐个给出结果。原来的数组接口仍可用。
- `staticCapturesLen` 在每次匹配的捕获组数固定时给出数量，否则是 `None`。`extract` 要求的组数必须正好是这个数量减 1。
- `RegexBuilder` 和 `RegexSetBuilder` 可以打开大小写、多行、点号、CRLF、忽略空白、Unicode、八进制和 ASCII 行终止符。`dfaSizeLimit`、`sizeLimit` 会明确失败。嵌套上限默认仍是 64，可以改，但它不是 Rust 的字节上限。

`Regex(pattern)` 和 `RegexSet(patterns)` 的默认值不变：Unicode 开，八进制关，行终止符是换行。

## 这一版不做

- 不匹配任意字节，也不接受非法 UTF-8。
- 没有 DFA，也没有 lazy DFA。
- 不支持前后查找和反向引用。上游也会拒绝它们。
- Break 属性不会做文本切分。
- 失败的 `capturesRead` 保留上一次写入的位置。已经返回的 `Captures` 不会被下一次搜索改写。

## 怎么看结果

```sh
bash scripts/run.sh demo
bash scripts/run.sh check
```

演示应出现 13/13 和分类 7/7。`check` 跑 28 项原生测试。完整对照固定 Rust 版本用 `bash scripts/run.sh verify`。报告里的条数是已经跑过的检查，不是完成百分比。

工作区干净后，`bash scripts/package.sh` 生成 `dist/regex4cj-0.3.0.tar.gz` 和 SHA-256。包里没有 SDK，也没有完整上游仓库。
