"""WhichCaptures for PikeVM and the bounded backtracker.

all keeps every group. implicit keeps only the whole match. none still
matches, but find cannot report a span because no capture states were built.
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
        REPORT.with_name("captures-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("all", "abc", ("a(b)c",)),
    ("implicit", "abc", ("a(b)c",)),
    ("none", "abc", ("a(b)c",)),
    ("all", "ab", ("(a)(b)",)),
    ("implicit", "ab", ("(a)(b)",)),
    ("none", "ab", ("(a)(b)",)),
    ("none", "zzz", ("[0-9]+",)),
    ("all", "", ("a*",)),
    ("implicit", "", ("a*",)),
    ("none", "", ("a*",)),
    ("all", "aaa", ("a+", "b")),
    ("implicit", "samwise", ("sam", "(sam)(wise)")),
    ("none", "aaa", ("a+", "b")),
    ("all", "中", ("(中)",)),
    ("implicit", "中a", ("(中)", "a")),
    ("none", "中a", ("(中)", "a")),
]

count = 0
for mode, text, patterns in cases:
    check("pike-captures", mode, text, *patterns)
    check("backtrack-captures", "1048576", mode, text, *patterns)
    count += 2

print(f"capture modes: {count} searches matched")
