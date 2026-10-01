#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
exec "${PYTHON:-python3}" scripts/verify_runner.py
