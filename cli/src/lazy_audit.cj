package regex_cli

import cjregex.*

func lazyByteSpan(value: Option<BytesMatch>): String {
    match (value) {
        case Some(m) => "${m.start}:${m.end}:${hexBytes(m.bytes)}";
        case None => "none"
    }
}

func lazyByteCapture(value: Option<BytesCaptures>): String {
    match (value) {
        case Some(c) => lazyByteSpan(Some(c.getMatch()));
        case None => "none"
    }
}

func lazyPart(value: Option<Array<UInt8>>): String {
    match (value) {
        case Some(s) => "hex:${hexBytes(s)}";
        case None => "none"
    }
}

func extendedAudit(): Unit {
    let patterns = ["", "(?-u).", "(a)?", "$", "z"]
    let texts = [parseHex(""), parseHex("61ff"), parseHex("e4b8ad61"), parseHex("610062")]
    for (p in 0..patterns.size) {
        for (t in 0..texts.size) {
            let text = texts[t]
            let re = BytesRegex(patterns[p])
            let it = re.findIter(text)
            let ci = re.capturesIter(text)
            let si = re.splitIter(text)
            for (i in 0..7) {
                println("byte-iter-${p}-${t}-${i}\t${lazyByteSpan(it.next())}")
                println("byte-capiter-${p}-${t}-${i}\t${lazyByteCapture(ci.next())}")
                println("byte-splititer-${p}-${t}-${i}\t${lazyPart(si.next())}")
            }
            for (limit in [0, 1, 2, 5]) {
                let iter = re.splitNIter(text, limit)
                for (i in 0..7) {
                    println("byte-splitn-${p}-${t}-${limit}-${i}\t${lazyPart(iter.next())}")
                }
            }
            for (start in 0..(text.size + 1)) {
                println("byte-at-${p}-${t}-${start}\t${lazyByteSpan(re.findAt(text, start))}")
                println("byte-isat-${p}-${t}-${start}\t${re.isMatchAt(text, start)}")
                println("byte-capat-${p}-${t}-${start}\t${lazyByteCapture(re.capturesAt(text, start))}")
                let set = BytesRegexSet([patterns[p], "a"])
                println(
                    "byte-setat-${p}-${t}-${start}\t${set.isMatchAt(text, start)}:${set.matchesAt(text, start).matched(0)}:${set.matchesAt(text, start).matched(1)}")
            }
        }
    }
    let sp = ["", ",", "a*", "$", "z"]
    let st = ["", "a,b,c", "中a"]
    for (p in 0..sp.size) {
        for (t in 0..st.size) {
            for (limit in [0, 1, 2, 5]) {
                let it = Regex(sp[p]).splitNIter(st[t], limit)
                for (i in 0..7) {
                    let part = match (it.next()) {
                        case Some(s) => "hex:${hexText(s)}";
                        case None => "none"
                    }
                    println("string-splitn-${p}-${t}-${limit}-${i}\t${part}")
                }
            }
        }
    }
    let re = BytesRegex("(?<name>a)|(b)")
    let staticLen = match (re.staticCapturesLen()) {
        case Some(n) => n;
        case None => -1
    }
    println("byte-meta\t${re.asStr()}:${re.capturesLen()}:${staticLen}")
    let names = re.captureNames()
    for (i in 0..names.size) {
        let name = match (names[i]) {
            case Some(n) => n;
            case None => "none"
        };
        println("byte-name-${i}\t${name}")
    }
    match (re.captures(parseHex("62"))) {
        case Some(c) =>
            let ex = c.extract(1)
            println("byte-extract\t${hexBytes(ex[0])}:${hexBytes(ex[1])}")
            let groups = c.iter()
            for (i in 0..c.size) {
                println("byte-group-${i}\t${lazyByteSpan(groups.next().value)}")
            }
            let m = c.getMatch()
            println("byte-match-meta\t${m.isEmpty()}:${m.len()}")
        case None => throw Exception("missing captures")
    }
    for (config in 0..16) {
        let patterns = ["a+", "(?m)^a.$", #"\141+"#, "a # comment\n b", #"\w+"#, "."]
        for (pi in 0..patterns.size) {
            let b = RegexBuilder(patterns[pi])
            b
                .caseInsensitive((config & 1) != 0)
                .multiLine((config & 2) != 0)
                .dotMatchesNewLine((config & 4) != 0)
                .swapGreed((config & 8) != 0)
                .unicode(config % 3 != 0)
                .ignoreWhitespace(config % 2 == 0)
                .crlf(config % 3 == 1)
                .octal(config % 2 == 1)
                .lineTerminator(if (config % 4 == 0) {
                    r'!'
                } else {
                    r'\n'
                })
                .nestLimit(if (config == 14) {
                    0
                } else {
                    250
                })
                .sizeLimit(if (config == 15) {
                    1
                } else {
                    10 * 1024 * 1024
                })
                .dfaSizeLimit(if (config % 2 == 0) {
                    0
                } else {
                    128
                })
            var output = "error"
            try {
                let re = b.build()
                output = "${re.isMatch("A!ab\r\naZ\n")}:${re.isMatch("中")}"
            } catch (_: Exception) {}
            println("builder-s-${config}-${pi}\t${output}")
        }
    }
    for (config in 0..16) {
        let patterns = ["a+", "(?m)^a.$", #"\141+"#, "a # comment\n b", #"\w+"#, "."]
        for (pi in 0..patterns.size) {
            let b = RegexSetBuilder().pattern(patterns[pi]).pattern("z")
            b
                .caseInsensitive((config & 1) != 0)
                .multiLine((config & 2) != 0)
                .dotMatchesNewLine((config & 4) != 0)
                .swapGreed((config & 8) != 0)
                .unicode(config % 3 != 0)
                .ignoreWhitespace(config % 2 == 0)
                .crlf(config % 3 == 1)
                .octal(config % 2 == 1)
                .lineTerminator(if (config % 4 == 0) {
                    r'!'
                } else {
                    r'\n'
                })
                .nestLimit(if (config == 14) {
                    0
                } else {
                    250
                })
                .sizeLimit(if (config == 15) {
                    1
                } else {
                    10 * 1024 * 1024
                })
                .dfaSizeLimit(if (config % 2 == 0) {
                    0
                } else {
                    128
                })
            var output = "error"
            try {
                let re = b.build()
                output = "${re.isMatch("A!ab\r\naZ\n")}:${re.isMatch("中")}"
            } catch (_: Exception) {}
            println("builder-ss-${config}-${pi}\t${output}")
        }
    }
    for (config in 0..16) {
        let patterns = ["a+", "(?m)^a.$", #"\141+"#, "a # comment\n b", #"\w+"#, "."]
        for (pi in 0..patterns.size) {
            let b = BytesRegexBuilder(patterns[pi])
            b
                .caseInsensitive((config & 1) != 0)
                .multiLine((config & 2) != 0)
                .dotMatchesNewLine((config & 4) != 0)
                .swapGreed((config & 8) != 0)
                .unicode(config % 3 != 0)
                .ignoreWhitespace(config % 2 == 0)
                .crlf(config % 3 == 1)
                .octal(config % 2 == 1)
                .lineTerminator(if (config % 4 == 0) {
                    r'!'
                } else {
                    r'\n'
                })
                .nestLimit(if (config == 14) {
                    0
                } else {
                    250
                })
                .sizeLimit(if (config == 15) {
                    1
                } else {
                    10 * 1024 * 1024
                })
                .dfaSizeLimit(if (config % 2 == 0) {
                    0
                } else {
                    128
                })
            var output = "error"
            try {
                let re = b.build()
                output = "${re.isMatch("A!ab\r\naZ\n".toArray())}:${re.isMatch("中".toArray())}"
            } catch (_: Exception) {}
            println("builder-b-${config}-${pi}\t${output}")
        }
    }
    for (config in 0..16) {
        let patterns = ["a+", "(?m)^a.$", #"\141+"#, "a # comment\n b", #"\w+"#, "."]
        for (pi in 0..patterns.size) {
            let b = BytesRegexSetBuilder().pattern(patterns[pi]).pattern("z")
            b
                .caseInsensitive((config & 1) != 0)
                .multiLine((config & 2) != 0)
                .dotMatchesNewLine((config & 4) != 0)
                .swapGreed((config & 8) != 0)
                .unicode(config % 3 != 0)
                .ignoreWhitespace(config % 2 == 0)
                .crlf(config % 3 == 1)
                .octal(config % 2 == 1)
                .lineTerminator(if (config % 4 == 0) {
                    r'!'
                } else {
                    r'\n'
                })
                .nestLimit(if (config == 14) {
                    0
                } else {
                    250
                })
                .sizeLimit(if (config == 15) {
                    1
                } else {
                    10 * 1024 * 1024
                })
                .dfaSizeLimit(if (config % 2 == 0) {
                    0
                } else {
                    128
                })
            var output = "error"
            try {
                let re = b.build()
                output = "${re.isMatch("A!ab\r\naZ\n".toArray())}:${re.isMatch("中".toArray())}"
            } catch (_: Exception) {}
            println("builder-bs-${config}-${pi}\t${output}")
        }
    }
}
