"""Reverse NFA start offsets against regex-automata dense DFA try_search_rev.

The reported offset is the beginning of the match. Patterns the DFA refuses,
including Unicode word boundaries, stay outside this comparison.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(pattern, text):
    args = ("nfa-rev", pattern, text)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("reverse-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("a", "xa"),
    ("a", "aba"),
    ("ab", "ab"),
    ("baz[0-9]+", "foobaz12345bar"),
    ("^a", "ab"),
    ("a$", "ba"),
    ("", "ab"),
    ("", ""),
    ("中", "a中b"),
    ("(?m)^a", "b\na"),
    ("a+", "aaa"),
    ("a+?", "aaa"),
    ("a*", "aaa"),
    ("a*?", "aaa"),
    ("ab*c", "abbc"),
    ("a|ab", "ab"),
    ("sam|samwise", "samwise"),
    ("a{2,4}", "aaaa"),
    ("a{3}", "aaaa"),
    ("foo|bar", "xxbar"),
    ("a中", "xa中"),
    ("^中", "中"),
    ("中$", "a中"),
    ("(?m)a$", "a\nb"),
    (".", "中"),
    ("a+", "xaa"),
    ("^a", "ba"),
    ("a$", "ab"),
    ("(?:ab)+", "abab"),
    ("a?", "b"),
    ("z", "ab"),
    ("a*", ""),
    ("(?m)^", "a\nb"),
    ("(?m)$", "a\nb"),
    ("a+", "中a"),
    (r"\d+", "ab12"),
    ("(a)", "xa"),
    ("a|b|c", "zzc"),
    ("(?m)^a$", "b\na"),
    ("foo", "foo"),
    (r"(?-u:\bfoo\b)", "afoo "),
    (".*", "ab"),
    (".*?", "ab"),
    ("a{3,}", "aaaa"),
    ("[a-c]+", "zzab"),
]

for pattern, text in cases:
    compare(pattern, text)


def compare_query(start, end, mode, pattern, text):
    args = ("nfa-rev-query", str(start), str(end), mode, pattern, text)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("reverse-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


queries = [
    (0, 2, "no", "a", "xa"),
    (0, 1, "no", "a", "xa"),
    (1, 2, "no", "a", "xa"),
    (0, 14, "no", "baz[0-9]+", "foobaz12345bar"),
    (0, 9, "no", "baz[0-9]+", "foobaz12345bar"),
    (3, 9, "no", "baz[0-9]+", "foobaz12345bar"),
    (0, 2, "yes", "a", "xa"),
    (0, 2, "yes", "a$", "ba"),
    (0, 2, "no", "a$", "ba"),
    (0, 1, "yes", "^a", "ab"),
    (1, 2, "yes", "^a", "ab"),
    (0, 0, "no", "a*", "ab"),
    (1, 1, "no", "a*", "ab"),
    (0, 5, "no", "中", "a中b"),
    (1, 4, "no", "中", "a中b"),
    (0, 1, "no", "中", "a中b"),
    (0, 3, "no", "(?m)^a", "b\na"),
    (2, 3, "no", "(?m)^a", "b\na"),
    (0, 3, "yes", "a+", "aaa"),
    (0, 2, "yes", "a+", "aaa"),
    (1, 3, "no", "a+", "aaa"),
    (0, 2, "no", "", "ab"),
    (2, 2, "yes", "", "ab"),
    (0, 2, "0", "a", "xa"),
]

for start, end, mode, pattern, text in queries:
    compare_query(start, end, mode, pattern, text)

rejected = run(RUST, "nfa-rev", r"\bfoo", " foo")
if not rejected.stdout.startswith("error"):
    raise AssertionError(rejected.stdout)

print(f"reverse NFA: {len(cases)} searches and {len(queries)} ranged queries matched")
