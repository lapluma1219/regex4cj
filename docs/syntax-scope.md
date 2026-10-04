# regex-syntax公开范围初查

这份清单用于定位语法库原始公开项目；条目不表示已经实现，也不能作为整个原仓库的完成率分母。参照提交为 `72d650cb0a880a01ab6dc2137c0888e8f89740f7`，regex-syntax版本为0.8.11。

通过现有Rust对照程序锁定的依赖生成文档，从rustdoc的all.html提取公开项目页，得到91个条目：52个struct、26个enum、11个函数、2个trait。原始路径见 [机器清单](syntax-public-items.json)。**这91项不包含每个类型下的方法、字段和枚举分支，也不包含可选arbitrary特性。** 完整接口审计仍须展开这些内容并审阅重导出和配置条件。

| 模块 | 条目页数 | 用途 |
|---|---:|---|
| 根模块 | 12 | 简便解析、解析配置、错误、转义和字符判断 |
| ast | 43 | 保留正则写法与位置的语法结构，以及结构访问 |
| ast::parse | 2 | 从模式文本构造AST及配置 |
| ast::print | 1 | 将AST写回模式文本 |
| hir | 22 | 归一化后的匹配结构、字符集合、属性与访问 |
| hir::translate | 2 | 将AST翻译为HIR及配置 |
| hir::print | 1 | 将HIR表示为模式文本 |
| hir::literal | 5 | 从HIR提取字面量信息，供搜索优化使用 |
| utf8 | 3 | 将字符范围表示为UTF-8字节序列范围 |

当前实现见[能力边界](status.md)，唯一后续计划见[交付计划](delivery-plan.md)。这份清单只用于定位原仓库公开项目页。

## 本次提取方式

在仓库根目录进入Rust环境后执行：

```sh
source scripts/env.sh
cargo doc --manifest-path oracle/Cargo.toml -p regex-syntax --no-deps --offline --locked
```

无依赖缓存时去掉`--offline`。文档位于Cargo目标目录的`doc/regex_syntax/`；默认目标目录为仓库内`.build/work/rust-target`，不纳入交付仓库。提取all.html中的公开项目链接，按路径去重，未将标准库自动trait或通用实现计入以上91项。JSON记录了文档索引哈希，编译器升级可能改变生成文件，因此该哈希不是原仓库源码哈希。
