#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then
  echo '请先提交交付内容；源码包只包含已提交文件，避免遗漏本地修改。' >&2
  exit 2
fi
version="$(cat VERSION)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'VERSION 必须为 major.minor.patch。' >&2
  exit 2
fi
mkdir -p dist
archive="dist/regex4cj-${version}.tar.gz"
git archive --format=tar --prefix="regex4cj-${version}/" HEAD | gzip -n > "$archive"
"${PYTHON:-python3}" - "$archive" <<'PY'
import hashlib
from pathlib import Path
import sys
p = Path(sys.argv[1])
digest = hashlib.sha256(p.read_bytes()).hexdigest()
p.with_suffix(p.suffix + '.sha256').write_text(digest + '  ' + p.name + '\n')
print('源码包：' + str(p.resolve()))
print('SHA-256：' + digest)
PY
