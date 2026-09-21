#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
"${PYTHON:-python3}" scripts/generate_unicode.py --check
cargo build --locked --manifest-path oracle/Cargo.toml
cargo test --locked --manifest-path oracle/Cargo.toml
(cd port && cjpm build)
(cd cli && cjpm build)
(cd examples/consumer && cjpm build && cjpm test && cjpm run)
"${PYTHON:-python3}" tests/verify.py
"${PYTHON:-python3}" tests/verify_matching.py
"${PYTHON:-python3}" tests/verify_classes.py
"${PYTHON:-python3}" tests/verify_captures.py
"${PYTHON:-python3}" tests/verify_text_ops.py
"${PYTHON:-python3}" tests/verify_flags.py
"${PYTHON:-python3}" tests/verify_escapes.py
"${PYTHON:-python3}" tests/verify_ascii_classes.py
"${PYTHON:-python3}" tests/verify_unicode.py
