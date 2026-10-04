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

rejected = run(RUST, "nfa-rev", r"\bfoo", " foo")
if not rejected.stdout.startswith("error"):
    raise AssertionError(rejected.stdout)

print(f"reverse NFA: {len(cases)} searches matched")
