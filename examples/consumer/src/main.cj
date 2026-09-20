package regex_consumer

import cjregex.*

main(): Unit {
    let orders = Regex("(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})")
    let text = "order=AB-123; order=CD-456"
    println(orders.replaceAll(text, #"${prefix}-***"#))
    for (caps in orders.capturesAll(text)) {
        match (caps.name("number")) {
            case Some(value) => println(value.text)
            case None => ()
        }
    }
}
