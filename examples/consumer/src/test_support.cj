package regex_consumer

import regex4cj.*
import std.collection.*

func requiredMatch(value: Option<RegexMatch>): RegexMatch {
    match (value) {
        case Some(m) => return m
        case None => throw Exception("expected match")
    }
}

func requiredText(value: Option<String>): String {
    match (value) {
        case Some(text) => return text
        case None => throw Exception("expected text")
    }
}

func requiredCaptures(value: Option<Captures>): Captures {
    match (value) {
        case Some(c) => return c
        case None => throw Exception("expected captures")
    }
}

func requiredBytes(value: Option<BytesMatch>): BytesMatch {
    match (value) {
        case Some(item) => return item
        case None => throw Exception("expected bytes match")
    }
}
