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
if [ -d "$REGEX4CJ_LOCAL/tools/cangjie" ]; then
  export CANGJIE_HOME="$REGEX4CJ_LOCAL/tools/cangjie"
  export PATH="$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$PATH"
  if [ "$(uname -s)" = Darwin ]; then
    export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:$CANGJIE_HOME/tools/lib:${DYLD_LIBRARY_PATH:-}"
  fi
fi
# Cangjie 1.0.5's linker cannot read the macOS 26.5 SDK stubs.
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
