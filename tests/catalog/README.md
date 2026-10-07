# 测试注册与维护

文件布局和命令见 [测试说明](../README.md)。`features.json` 注册各功能的批量套件、`functional/<功能>/cases.json` 和源码归属；`native.json` 注册原生测试函数。

新增功能或案例后执行 `python3 scripts/feature_catalog.py` 更新文档，再执行 `bash scripts/run.sh verify`。检查器拒绝漏登记的套件、原生测试、源码文件，拒绝重复案例编号和不存在/不明确的接口引用。

公开接口有功能归属不代表已验证。`api_refs` 只登记核实过调用路径的具体方法，不通过名称搜索推算覆盖。原生案例输入和预期保留在 @Test 函数内；批量随机测试保持原有种子和跳过规则。
