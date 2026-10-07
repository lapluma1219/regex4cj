"""Hybrid DFA multi-pattern search, plus anchored search of one pattern.

The cache is counted in states. These patterns stay inside the default cache,
so the give-up offset is not part of this comparison.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def check(*args):
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("hybrid-many-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


many = [
    ("0", "3", "no", "false", "aaa", "a+", "a"),
    ("0", "2", "no", "false", "ab", "ab", "a"),
    ("0", "5", "no", "false", "xxbar", "foo", "bar"),
    ("0", "3", "yes", "false", "aba", "a", "b"),
    ("1", "4", "no", "false", "xaaa", "a+", "b+"),
    ("0", "3", "no", "true", "aaa", "a+", "a"),
    ("0", "4", "no", "false", "中a", "中", "a"),
    ("2", "5", "no", "false", "xxbar", "foo", "bar"),
]
pattern = [
    ("0", "2", "0", "false", "ab", "a", "ab"),
    ("0", "2", "1", "false", "ab", "a", "ab"),
    ("0", "5", "1", "false", "xxbar", "foo", "bar"),
    ("2", "5", "1", "false", "xxbar", "foo", "bar"),
    ("0", "2", "9", "false", "ab", "a", "b"),
    ("0", "3", "no", "false", "aaa", "a+", "b"),
    ("0", "3", "yes", "false", "aba", "b", "a"),
    ("0", "4", "0", "false", "中a", "中", "a"),
    ("1", "4", "0", "false", "xaaa", "a+", "b+"),
]

count = 0
for start, end, mode, earliest, text, *patterns in many:
    check("hybrid-many", start, end, mode, earliest, text, *patterns)
    count += 1
for start, end, mode, earliest, text, *patterns in pattern:
    check("hybrid-pattern", start, end, mode, earliest, text, *patterns)
    count += 1

print(f"hybrid many: {count} searches matched")
