"""Shared process protocol and failure recording for Rust/Cangjie comparisons."""
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
RUST = Path(os.environ['CARGO_TARGET_DIR']) / 'debug/regex-oracle'
CJ = ROOT / 'port/target/release/bin/main'
ENV = os.environ.copy()
if ENV.get('REGEX4CJ_DYLD_LIBRARY_PATH'):
    ENV['DYLD_LIBRARY_PATH'] = ENV['REGEX4CJ_DYLD_LIBRARY_PATH']
REPORT = Path(os.environ['REGEX4CJ_LOCAL']) / 'work/verification.json'

def invoke(binary, mode, pattern, text):
    return subprocess.run([str(binary), mode, pattern, text], env=ENV,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)

def compare(pattern, text, mode='find'):
    rust = invoke(RUST, mode, pattern, text)
    cj = invoke(CJ, mode, pattern, text)
    if rust.returncode != 0 or cj.returncode != 0 or rust.stdout != cj.stdout:
        failure = {'mode': mode, 'pattern': pattern, 'text': text,
                   'rust': rust.stdout.decode(), 'cangjie': cj.stdout.decode(),
                   'rust_error': rust.stderr.decode(), 'cangjie_error': cj.stderr.decode(),
                   'rust_code': rust.returncode, 'cangjie_code': cj.returncode}
        REPORT.with_name('matching-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)

