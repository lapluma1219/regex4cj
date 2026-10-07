"""DFA searches that select one pattern, matching starts_for_each_pattern.

The default DFA still rejects Anchored::Pattern. These commands build the extra
start states, then anchor the search at one pattern. An unknown id is a miss.
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
        REPORT.with_name("dfa-pattern-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


searches = [
    ("dense", "0", "2", "0", "false", "ab", ("a", "ab")),
    ("sparse", "0", "2", "1", "false", "ab", ("a", "ab")),
    ("dense", "0", "5", "1", "false", "xxbar", ("foo", "bar")),
    ("dense", "2", "5", "1", "false", "xxbar", ("foo", "bar")),
    ("sparse", "0", "3", "0", "false", "aaa", ("a+", "b")),
    ("dense", "0", "3", "1", "false", "aaa", ("a+", "b")),
    ("dense", "0", "2", "9", "false", "ab", ("a", "b")),
    ("sparse", "0", "3", "no", "false", "aaa", ("a+", "a")),
    ("dense", "0", "3", "yes", "false", "aba", ("b", "a")),
    ("dense", "0", "4", "0", "false", "中a", ("中", "a")),
    ("sparse", "1", "4", "0", "false", "xaaa", ("a+", "b+")),
    ("dense", "2", "4", "0", "false", "b\naa", ("(?m)^a", "b")),
    ("sparse", "0", "2", "0", "true", "ab", ("a+", "b")),
    ("dense", "0", "1", "1", "false", "b", ("a*", "b")),
]
overlaps = [
    ("dense", "0", "3", "0", "aaa", ("a+", "b+")),
    ("sparse", "0", "3", "1", "aaabb", ("a+", "b+")),
    ("dense", "0", "2", "1", "ab", ("a", "b")),
    ("dense", "0", "2", "9", "ab", ("a", "b")),
    ("sparse", "0", "3", "no", "aaa", ("a+", "a")),
    ("dense", "0", "3", "yes", "aba", ("a", "b")),
]
raw = [
    ("dense", "6162", "0", ("a", "ab")),
    ("sparse", "6162", "1", ("a", "ab")),
    ("dense", "ff61", "0", ("a", "b")),
    ("sparse", "61ff", "0", ("a", "b")),
    ("dense", "ff62", "1", ("a", "b")),
    ("sparse", "6162", "9", ("a", "b")),
    ("dense", "e4b8ad", "0", ("中", "a")),
    ("sparse", "80e4b8ad", "0", ("中", "a")),
]

count = 0
for kind, start, end, mode, earliest, text, patterns in searches:
    check("dfa-pattern", kind, start, end, mode, earliest, text, *patterns)
    count += 1
for kind, start, end, mode, text, patterns in overlaps:
    check("dfa-pattern-overlap", kind, start, end, mode, text, *patterns)
    count += 1
for kind, hex_text, mode, patterns in raw:
    check("dfa-bytes-pattern", kind, hex_text, mode, *patterns)
    count += 1

print(f"dfa pattern starts: {count} searches matched")
