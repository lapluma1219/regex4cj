package regex_consumer

import cjregex.*

// Start here: this program depends on the library through cjpm.toml.
// Change the text or pattern and run: bash scripts/run.sh example
main(): Unit {
    let text = "order=AB-123; order=CD-456"
    let orders = Regex("(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})")

    println("1. 查找订单号：")
    for (m in orders.findAll(text)) {
        println("  ${m.text} [${m.start}, ${m.end})")
    }

    println("2. 按名称提取编号：")
    for (caps in orders.capturesAll(text)) {
        match (caps.name("number")) {
            case Some(value) => println("  number = " + value.text)
            case None => println("  此捕获组未参与匹配")
        }
    }

    println("3. 保留前缀，对数字脱敏：")
    // A raw string preserves ${prefix} for the regex replacement template.
    println("  " + orders.replaceAll(text, #"${prefix}-***"#))

    println("4. 分割字段：")
    for (part in Regex(#"[,;]\s*"#).split("a, b;c")) {
        println("  " + part)
    }

    println("5. 汉字与 UTF-8 字节偏移：")
    for (m in Regex(#"\p{Han}+"#).findAll("A中文α")) {
        println("  ${m.text} [${m.start}, ${m.end})")
    }

    println("6. 把普通文本安全地当作模式：")
    let literal = "a+b.txt"
    println("  转义后：" + escape(literal))
    println("  是否匹配原文：${Regex(escape(literal)).isMatch(literal)}")

    println("7. 多规则文本分类：")
    let rules = RegexSet(["退款", "发票", "[A-Z]{2}-[0-9]{3}"])
    let labels = ["退款相关", "发票相关", "包含订单号"]
    for (id in rules.matches("订单 AB-123 需要退款").indices()) {
        println("  规则 ${id}：${labels[id]}")
    }
}
