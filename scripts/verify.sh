#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
"${PYTHON:-python3}" scripts/generate_unicode.py --check
"${PYTHON:-python3}" scripts/generate_categories.py --check
"${PYTHON:-python3}" scripts/generate_scripts.py --check
"${PYTHON:-python3}" scripts/generate_binary.py --check
"${PYTHON:-python3}" scripts/generate_case_fold.py --check
"${PYTHON:-python3}" scripts/generate_age_break.py --check
"${PYTHON:-python3}" -m unittest discover -s tests -p test_category_generator.py
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
"${PYTHON:-python3}" tests/verify_case.py
"${PYTHON:-python3}" tests/verify_escapes.py
"${PYTHON:-python3}" tests/verify_ascii_classes.py
"${PYTHON:-python3}" tests/verify_unicode.py
"${PYTHON:-python3}" tests/verify_boundaries.py
"${PYTHON:-python3}" tests/verify_properties.py
"${PYTHON:-python3}" tests/verify_scripts.py
"${PYTHON:-python3}" tests/verify_binary.py
"${PYTHON:-python3}" tests/verify_syntax.py
"${PYTHON:-python3}" tests/verify_upstream_sample.py
"${PYTHON:-python3}" tests/verify_sets.py
"${PYTHON:-python3}" scripts/showcase.py
"${PYTHON:-python3}" scripts/classify.py --demo
