#!/usr/bin/env bash
# User entry point: no shell environment setup required after SDK installation.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$PROJECT_ROOT"
usage() {
  cat <<'EOF'
regex4cj 0.3.0 — 字符串语法与起点搜索版
用法：bash scripts/run.sh 命令 [参数...]

  demo                     构建并演示，逐项核对预期结果（无需 Rust）
  classify TEXT [--rules JSON]
                           使用规则文件给文本分类
  set-matches TEXT [PATTERN ...]
                           返回命中的规则编号
  set-is-match TEXT [PATTERN ...]
                           是否至少命中一条规则
  example                  运行可修改的仓颉调用示例
  build                    构建仓颉库、CLI 和调用示例
  check                    28 项仓颉测试 + 场景验收（无需 Rust）
  verify                   完整 Rust/仓颉差分验收（需 Cargo）
  find PATTERN TEXT        查找全部匹配；输出 UTF-8 起止字节和文本
  first PATTERN TEXT       只查找第一条匹配
  is-match PATTERN TEXT    是否匹配
  captures PATTERN TEXT    显示捕获字段与偏移
  replace-all PATTERN TEXT TEMPLATE
  split PATTERN TEXT       显示分割字段（保留空字符串）
  escape TEXT              将普通文本转义为正则字面量
  raw ...                  原始 CLI 协议，供开发与自动化使用
  help                     显示此帮助

模式和替换模板请用 shell 单引号，例如：
  bash scripts/run.sh find '\p{Han}+' 'A中文α'
EOF
}
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少命令：$1。请按 docs/getting-started.md 配置环境。" >&2
    exit 2
  fi
}
cli_build() { need cjc; need cjpm; (cd cli && cjpm build) >&2; }
consumer_build() { (cd examples/consumer && cjpm build) >&2; }
py() { need "${PYTHON:-python3}"; "${PYTHON:-python3}" "$@"; }
command_name="${1:-help}"
if [ "$#" -gt 0 ]; then shift; fi
case "$command_name" in
  help|--help|-h) usage ;;
  build) cli_build; consumer_build ;;
  demo) cli_build; py scripts/showcase.py; py scripts/classify.py --demo ;;
  example) cli_build; consumer_build; examples/consumer/target/release/bin/main ;;
  check)
    cli_build; consumer_build
    (cd examples/consumer && cjpm test)
    py scripts/showcase.py
    py scripts/classify.py --demo
    ;;
  verify) need cargo; need cjc; need cjpm; need "${PYTHON:-python3}"; exec bash scripts/verify.sh ;;
  captures|capture-first)
    cli_build
    cli/target/release/bin/main "$command_name" "$@" | py scripts/show_captures.py
    ;;
  replace|replace-all|replace-n|replace-literal|split|split-n|expand)
    cli_build
    cli/target/release/bin/main "$command_name" "$@" | py scripts/show_text.py
    ;;
  find|first|is-match|escape) cli_build; exec cli/target/release/bin/main "$command_name" "$@" ;;
  classify) cli_build; py scripts/classify.py "$@" ;;
  set-matches|set-is-match) cli_build; exec cli/target/release/bin/main "$command_name" "$@" ;;
  raw) cli_build; exec cli/target/release/bin/main "$@" ;;
  *) usage >&2; exit 2 ;;
esac
