#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
cargo build --locked --manifest-path oracle/Cargo.toml
(cd port && cjpm build)
"${PYTHON:-python3}" tests/verify.py
"${PYTHON:-python3}" tests/verify_matching.py
"${PYTHON:-python3}" tests/verify_classes.py
"${PYTHON:-python3}" tests/verify_captures.py
"${PYTHON:-python3}" tests/verify_text_ops.py
