"""Pike and backtracker searches over haystacks that are not UTF-8.

The byte automaton is compared with regex-automata PikeVM and
BoundedBacktracker. Patterns that the UTF-8 parser rejects stay out.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(args):
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("bytes-nfa-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("pike-bytes", "0", "2", "no", "ff61", "a"),
    ("pike-bytes", "0", "2", "yes", "ff61", "a"),
    ("pike-bytes", "1", "2", "no", "ff61", "a"),
    ("pike-bytes", "0", "2", "no", "ff62", "a", "b"),
    ("pike-bytes", "0", "2", "1", "ff62", "a", "b"),
    ("pike-bytes", "0", "2", "9", "ff62", "a", "b"),
    ("pike-bytes", "0", "3", "no", "61ff61", "a+"),
    ("pike-bytes", "0", "3", "no", "61ff62", "(a)"),
    ("pike-bytes", "0", "1", "no", "ff", "a*"),
    ("pike-bytes", "0", "1", "no", "ff", "."),
    ("pike-bytes", "0", "4", "no", "ff61ff62", "a", "b"),
    ("pike-bytes", "0", "0", "no", "", "a*"),
    ("pike-bytes", "0", "2", "no", "0a61", "(?m)^a"),
    ("backtrack-bytes", "default", "0", "2", "no", "ff61", "a"),
    ("backtrack-bytes", "default", "0", "2", "yes", "ff61", "a"),
    ("backtrack-bytes", "default", "1", "2", "no", "ff61", "a"),
    ("backtrack-bytes", "default", "0", "2", "no", "ff62", "a", "b"),
    ("backtrack-bytes", "default", "0", "2", "1", "ff62", "a", "b"),
    ("backtrack-bytes", "default", "0", "3", "no", "61ff61", "a+"),
    ("backtrack-bytes", "default", "0", "3", "no", "61ff62", "(a)"),
    ("backtrack-bytes", "default", "0", "1", "no", "ff", "a*"),
    ("backtrack-bytes", "default", "0", "1", "no", "ff", "."),
    ("backtrack-bytes", "default", "0", "4", "no", "ff61ff62", "a", "b"),
    ("backtrack-bytes", "default", "0", "0", "no", "", "a*"),
    ("backtrack-bytes", "default", "0", "2", "no", "0a61", "(?m)^a"),
]

for args in cases:
    compare(args)
print(f"byte nfa: {len(cases)} searches matched")
