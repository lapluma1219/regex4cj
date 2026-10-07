"""Bounded backtracker spans and budget errors against regex-automata.

Match text is compared directly. The maximum haystack length uses each
engine's own NFA state count, so those two numbers are not required to be equal.
A haystack past that limit must be an error, not a miss.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(capacity, pattern, text):
    args = ("backtrack", capacity, pattern, text)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("backtrack-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


def info(binary, capacity, pattern):
    result = run(binary, "backtrack-info", capacity, pattern)
    if result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    rows = {}
    for line in result.stdout.splitlines():
        key, value = line.split("\t")
        rows[key] = int(value)
    return rows


def check_budget(binary):
    capacity = "64"
    bound = info(binary, capacity, "a+")
    if bound["max"] <= 0:
        raise AssertionError(bound)
    hay = "a" * bound["max"]
    ok = run(binary, "backtrack", capacity, "a+", hay)
    if ok.returncode or not ok.stdout.startswith("pattern\t0\nspan\t0\t%s\n" % bound["max"]):
        raise AssertionError(dict(stdout=ok.stdout, stderr=ok.stderr, bound=bound))
    too_long = bound["max"] + 1
    denied = run(binary, "backtrack", capacity, "a+", hay + "a")
    expected = "error\thaystack of length %s is too long\n" % too_long
    if denied.returncode or denied.stdout != expected:
        raise AssertionError(dict(stdout=denied.stdout, stderr=denied.stderr, expected=expected))
    text = "abcd"
    minimum = (bound["states"] * (len(text) + 1) + 7) // 8
    tight = run(binary, "backtrack", str(minimum), "a+", text)
    wide = run(binary, "backtrack", "1048576", "a+", text)
    if tight.returncode or wide.returncode or tight.stdout != wide.stdout or tight.stdout.startswith("error"):
        raise AssertionError(dict(tight=tight.stdout, wide=wide.stdout, minimum=minimum))
    short = run(binary, "backtrack", str(minimum - 1), "a+", text)
    short_expected = "error\thaystack of length %s is too long\n" % len(text)
    if short.returncode or short.stdout != short_expected:
        raise AssertionError(dict(stdout=short.stdout, stderr=short.stderr, expected=short_expected))


cases = [
    ("a+", "aaa"),
    ("a+?", "aaa"),
    ("a*", "aaa"),
    ("a*?", "aaa"),
    ("a*", "b"),
    ("a*?", ""),
    ("", "ab"),
    ("", ""),
    ("a|ab", "ab"),
    ("ab|a", "ab"),
    ("sam|samwise", "samwise"),
    ("(a+)", "xa"),
    ("(a+)(b+)", "aaabbb"),
    ("(a)|(b)", "b"),
    ("(ab)|(a)", "ab"),
    ("(?:ab)+", "abab"),
    ("a{2,4}", "aaaa"),
    ("a{3}", "aa"),
    ("a{3,}", "aaaa"),
    ("^a", "ba"),
    ("a$", "ba"),
    ("a*$", "b"),
    ("(?m)^a", "b\na"),
    ("(?m)a$", "a\nb"),
    (".", "中"),
    (".*", "ab"),
    (".*?", "ab"),
    ("中+", "a中中b"),
    ("(a)(中)", "a中"),
    ("(?<n>a+)", "xaa"),
    (r"\d+", "ab12cd"),
    (r"(?-u:\d+)", "ab12cd"),
    (r"\bfoo", " foo"),
    (r"(?-u:\bfoo\b)", " foo "),
    ("(?i:a+)", "bAAa"),
    ("(a+)+", "aaa"),
    ("(a|b)+", "abba"),
    ("a+", "x" + ("a" * 40)),
    ("z", "ab"),
    ("a?", "b"),
    ("[a-c]+", "zzab"),
    ("foo|bar", "xxbar"),
]

for pattern, text in cases:
    compare("1048576", pattern, text)

tiny = run(RUST, "backtrack", "1", "a+", "aaaa")
if tiny.returncode or tiny.stdout != "error\thaystack of length 4 is too long\n":
    raise AssertionError(dict(stdout=tiny.stdout, stderr=tiny.stderr))
compare("1", "a+", "aaaa")

check_budget(RUST)
check_budget(CJ)

queries = [
    ("backtrack-query", "1048576", "1", "4", "no", "false", "xaaa", "a+"),
    ("backtrack-query", "1048576", "0", "3", "no", "true", "aaa", "a+"),
    ("backtrack-query", "1048576", "3", "6", "no", "false", "foo123bar", r"\b123\b"),
    ("backtrack-query", "1048576", "1", "3", "yes", "false", "aba", "a"),
    ("backtrack-many", "1048576", "0", "3", "no", "false", "aaa", "a+", "a"),
    ("backtrack-many", "1048576", "0", "3", "1", "false", "aaa", "a+", "a"),
    ("backtrack-many", "1048576", "0", "3", "9", "false", "aaa", "a+", "a"),
    ("backtrack-many", "1048576", "0", "6", "no", "false", "foo123", "[a-z0-9]{6}", "[a-z][a-z0-9]{5}"),
    ("backtrack-many", "1048576", "0", "6", "1", "false", "foo123", "[a-z0-9]{6}", "[a-z][a-z0-9]{5}"),
]
for args in queries:
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

print("backtrack: %s searches matched, %s input queries" % (len(cases), len(queries)))
