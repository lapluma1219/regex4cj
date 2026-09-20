#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
cargo build --locked --manifest-path oracle/Cargo.toml
(cd port && cjpm build)
"${PYTHON:-python3}" tests/verify.py
