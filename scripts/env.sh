#!/usr/bin/env bash
# Source from bash. Local dependencies and caches are outside the Git repository.
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REGEX4CJ_LOCAL="${REGEX4CJ_LOCAL:-$(dirname "$PROJECT_ROOT")/regex4cj-local}"
mkdir -p "$REGEX4CJ_LOCAL/work"
if [ -d "$REGEX4CJ_LOCAL/tools/rustup" ]; then
  export CARGO_HOME="$REGEX4CJ_LOCAL/tools/cargo"
  export RUSTUP_HOME="$REGEX4CJ_LOCAL/tools/rustup"
  export PATH="$CARGO_HOME/bin:$PATH"
fi
export CARGO_TARGET_DIR="$REGEX4CJ_LOCAL/work/rust-target"
export TMPDIR="$REGEX4CJ_LOCAL/work"
if [ -z "${CANGJIE_HOME:-}" ]; then
  if [ -d "$REGEX4CJ_LOCAL/tools/cangjie-1.1.3" ]; then
    export CANGJIE_HOME="$REGEX4CJ_LOCAL/tools/cangjie-1.1.3"
  elif [ -d "$REGEX4CJ_LOCAL/tools/cangjie" ]; then
    export CANGJIE_HOME="$REGEX4CJ_LOCAL/tools/cangjie"
  fi
fi
if [ -n "${CANGJIE_HOME:-}" ]; then
  export PATH="$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$PATH"
  if [ "$(uname -s)" = Darwin ]; then
    cj_arch="$(uname -m)"
    if [ "$cj_arch" = arm64 ]; then cj_arch=aarch64; fi
    export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_${cj_arch}_cjnative:$CANGJIE_HOME/tools/lib:${DYLD_LIBRARY_PATH:-}"
    unset cj_arch
  fi
fi
# Keep the validated macOS SDK selection (originally needed for Cangjie 1.0.5).
# Respect an explicitly selected SDK; prefer an installed compatible SDK on this Mac.
if [ "$(uname -s)" = Darwin ] && [ -z "${SDKROOT:-}" ]; then
  if [ -d /Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk ]; then
    export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk
  else
    export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
  fi
fi

# Apple-provided Python can strip DYLD_* on startup; preserve it for child tests.
export REGEX4CJ_DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
