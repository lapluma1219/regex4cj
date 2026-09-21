#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
echo 'Rust: extract order numbers, capture fields, replace digits'
"$CARGO_TARGET_DIR/debug/regex-oracle" demo
echo 'Rust escape:'
"$CARGO_TARGET_DIR/debug/regex-oracle" escape 'a+b.txt'
echo 'Cangjie escape:'
cli/target/release/bin/main escape 'a+b.txt'
echo 'Rust Unicode byte offsets:'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '中' 'a中b'
echo 'Rust and Cangjie: same order-pattern search (restricted syntax)'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '(AB|CD)-.+?;' 'order=AB-123; order=CD-456;'
cli/target/release/bin/main find '(AB|CD)-.+?;' 'order=AB-123; order=CD-456;'
echo 'Cangjie: Unicode positions and branch priority'
cli/target/release/bin/main find '(中|🙂)+' 'a中🙂b'
cli/target/release/bin/main find 'a|ab' 'ab'
echo 'Rust and Cangjie: original order pattern with classes and counted repetitions'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '[A-Z]{2}-[0-9]{3}' 'order=AB-123; order=CD-456'
cli/target/release/bin/main find '[A-Z]{2}-[0-9]{3}' 'order=AB-123; order=CD-456'
echo 'Cangjie: class intersection and lazy counted repetition'
cli/target/release/bin/main find '[a-z&&[^aeiou]]+' 'abcde'
cli/target/release/bin/main find 'a{2,3}?' 'aaaaa'
echo 'Rust: named capture fields (UTF-8 byte ranges)'
"$CARGO_TARGET_DIR/debug/regex-oracle" captures '(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})' 'order=AB-123; order=CD-456' | "${PYTHON:-python3}" scripts/show_captures.py
echo 'Cangjie: the same named capture fields'
cli/target/release/bin/main captures '(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})' 'order=AB-123; order=CD-456' | "${PYTHON:-python3}" scripts/show_captures.py
echo 'Cangjie: unmatched group versus captured empty string'
cli/target/release/bin/main captures '(a)?(b*)' '' | "${PYTHON:-python3}" scripts/show_captures.py
echo 'Rust and Cangjie: replace order numbers using the named prefix'
"$CARGO_TARGET_DIR/debug/regex-oracle" replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'order=AB-123; order=CD-456' '${prefix}-***' | "${PYTHON:-python3}" scripts/show_text.py
cli/target/release/bin/main replace-all '(?<prefix>[A-Z]{2})-[0-9]{3}' 'order=AB-123; order=CD-456' '${prefix}-***' | "${PYTHON:-python3}" scripts/show_text.py
echo 'Rust and Cangjie: split into at most two fields, keeping the remainder'
"$CARGO_TARGET_DIR/debug/regex-oracle" split-n ',' 'a,b,c' 2 | "${PYTHON:-python3}" scripts/show_text.py
cli/target/release/bin/main split-n ',' 'a,b,c' 2 | "${PYTHON:-python3}" scripts/show_text.py
echo 'Cangjie: zero-width split preserves Unicode scalars'
cli/target/release/bin/main split '' '中🙂' | "${PYTHON:-python3}" scripts/show_text.py
echo 'Rust and Cangjie: multiline anchors'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '(?m)^[A-Z]+$' $'AB\nCD\n'
cli/target/release/bin/main find '(?m)^[A-Z]+$' $'AB\nCD\n'
echo 'Rust and Cangjie: swapped greed and explicit reversal'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '(?U)a+' 'aaa'
cli/target/release/bin/main find '(?U)a+' 'aaa'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '(?U)a+?' 'aaa'
cli/target/release/bin/main find '(?U)a+?' 'aaa'
echo 'Rust and Cangjie: escaped Unicode scalars'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '\u4e2d\U0001F642' 'a中🙂b'
cli/target/release/bin/main find '\u4e2d\U0001F642' 'a中🙂b'
echo 'Cangjie: escaped character class endpoints'
cli/target/release/bin/main find '[\x41-\x5A]+' 'aABCz'
echo 'Rust and Cangjie: POSIX digits are ASCII'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '[[:digit:]]+' 'a12٣４b'
cli/target/release/bin/main find '[[:digit:]]+' 'a12٣４b'
echo 'Rust and Cangjie: complement of ASCII includes Unicode'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '[[:^ascii:]]+' 'a中🙂b'
cli/target/release/bin/main find '[[:^ascii:]]+' 'a中🙂b'
echo 'Rust and Cangjie: Unicode decimal digits versus other numbers'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '\d+' 'A３٣²'
cli/target/release/bin/main find '\d+' 'A３٣²'
echo 'Rust and Cangjie: Unicode word characters'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '\w+' '中文🙂abc'
cli/target/release/bin/main find '\w+' '中文🙂abc'
