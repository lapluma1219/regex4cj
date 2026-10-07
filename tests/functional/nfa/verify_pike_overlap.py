"""Pike which_overlapping_matches over a span, with anchor and earliest.

earliest stops before a later byte can reach Accept, so only an empty match
at the span start is reported. An unknown pattern id is an empty set.
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
        REPORT.with_name("pike-overlap-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("0", "6", "no", "false", "foobar", r"\w+", r"\d+", r"\pL+", "foo", "bar", "barfoo", "foobar"),
    ("0", "7", "no", "false", "samwise", "sam", "samwise"),
    ("0", "3", "no", "false", "samwise", "sam", "samwise"),
    ("3", "7", "no", "false", "samwise", "sam", "samwise"),
    ("0", "7", "yes", "false", "samwise", "sam", "samwise"),
    ("0", "7", "0", "false", "samwise", "sam", "samwise"),
    ("0", "7", "1", "false", "samwise", "sam", "samwise"),
    ("3", "7", "1", "false", "samwise", "sam", "samwise"),
    ("0", "7", "9", "false", "samwise", "sam", "samwise"),
    ("0", "0", "no", "false", "", "a*", "b"),
    ("0", "3", "yes", "false", "aaa", "a+", "b"),
    ("1", "3", "no", "false", "xab", "ab", "b"),
    ("0", "3", "no", "true", "foo", "foo", "a*"),
    ("0", "3", "no", "true", "foo", "a*", "b*"),
    ("0", "1", "yes", "true", "a", "a", "a*"),
    ("0", "4", "no", "false", "中a", ".", "a", "中"),
    ("1", "4", "no", "false", "中a", ".", "a"),
    ("0", "2", "yes", "false", "ab", "a", "b", "ab"),
    ("0", "5", "1", "false", "xxbar", "foo", "bar"),
    ("2", "5", "1", "false", "xxbar", "foo", "bar"),
]

count = 0
for start, end, mode, earliest, text, *patterns in cases:
    check("pike-overlap-query", start, end, mode, earliest, text, *patterns)
    count += 1

print(f"pike overlap queries: {count} searches matched")
