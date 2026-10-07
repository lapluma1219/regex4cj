"""Bounded backtracker non-overlapping iteration inside a byte span.

Compared with regex-automata Searcher over Input::range.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(capacity, start, end, text, patterns):
    args = ("backtrack-iter-span", capacity, str(start), str(end), text, *patterns)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("backtrack-span-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("default", 0, 5, "ab ab", ["ab", "a"]),
    ("default", 1, 5, "ab ab", ["ab", "a"]),
    ("default", 0, 3, "aaa", ["a"]),
    ("default", 1, 3, "aaa", ["a+"]),
    ("default", 0, 4, "aaba", ["a*"]),
    ("default", 0, 0, "", ["a*"]),
    ("default", 2, 5, "xxfoo", ["foo", "bar"]),
    ("default", 0, 7, "samwise", ["sam", "samwise"]),
    ("default", 0, 5, "a中b", ["中", "."]),
    ("default", 1, 4, "a中b", ["中"]),
    ("default", 0, 4, "abab", ["ab"]),
    ("default", 1, 4, "abab", ["ab", "a"]),
    ("64", 0, 3, "aaa", ["a"]),
    ("default", 0, 3, "b\na", ["(?m)^a"]),
    ("default", 0, 2, "ba", ["a$", "a"]),
    ("default", 3, 3, "abc", ["a*"]),
]

for capacity, start, end, text, patterns in cases:
    compare(capacity, start, end, text, patterns)
print(f"backtrack span: {len(cases)} iterations matched")
