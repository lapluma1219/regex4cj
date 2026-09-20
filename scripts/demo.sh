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
