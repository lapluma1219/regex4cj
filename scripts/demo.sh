#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
echo 'Rust: extract order numbers, capture fields, replace digits'
"$CARGO_TARGET_DIR/debug/regex-oracle" demo
echo 'Rust escape:'
"$CARGO_TARGET_DIR/debug/regex-oracle" escape 'a+b.txt'
echo 'Cangjie escape:'
port/target/release/bin/main escape 'a+b.txt'
echo 'Rust Unicode byte offsets:'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '中' 'a中b'
echo 'Rust and Cangjie: same order-pattern search (restricted syntax)'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '(AB|CD)-.+?;' 'order=AB-123; order=CD-456;'
port/target/release/bin/main find '(AB|CD)-.+?;' 'order=AB-123; order=CD-456;'
echo 'Cangjie: Unicode positions and branch priority'
port/target/release/bin/main find '(中|🙂)+' 'a中🙂b'
port/target/release/bin/main find 'a|ab' 'ab'
echo 'Rust and Cangjie: original order pattern with classes and counted repetitions'
"$CARGO_TARGET_DIR/debug/regex-oracle" find '[A-Z]{2}-[0-9]{3}' 'order=AB-123; order=CD-456'
port/target/release/bin/main find '[A-Z]{2}-[0-9]{3}' 'order=AB-123; order=CD-456'
echo 'Cangjie: class intersection and lazy counted repetition'
port/target/release/bin/main find '[a-z&&[^aeiou]]+' 'abcde'
port/target/release/bin/main find 'a{2,3}?' 'aaaaa'
echo 'Rust: named capture fields (UTF-8 byte ranges)'
"$CARGO_TARGET_DIR/debug/regex-oracle" captures '(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})' 'order=AB-123; order=CD-456' | "${PYTHON:-python3}" scripts/show_captures.py
echo 'Cangjie: the same named capture fields'
port/target/release/bin/main captures '(?<prefix>[A-Z]{2})-(?<number>[0-9]{3})' 'order=AB-123; order=CD-456' | "${PYTHON:-python3}" scripts/show_captures.py
echo 'Cangjie: unmatched group versus captured empty string'
port/target/release/bin/main captures '(a)?(b*)' '' | "${PYTHON:-python3}" scripts/show_captures.py
