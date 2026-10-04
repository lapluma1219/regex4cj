"""Dense and sparse DFA spans against regex-automata dfa::regex::Regex.

Unicode word boundaries must be a build error on both sides. The numeric DFA
state count is not compared.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=60)


def compare(kind, pattern, text):
    args = ("dfa", kind, pattern, text)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("dfa-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("a+", "aaa"),
    ("a+?", "aaa"),
    ("a*", "b"),
    ("a*?", "aaa"),
    ("", "ab"),
    ("", ""),
    ("a|ab", "ab"),
    ("ab|a", "ab"),
    ("sam|samwise", "samwise"),
    ("^a", "ba"),
    ("^a", "ab"),
    ("a$", "ba"),
    ("a$", "ab"),
    ("a*$", "b"),
    ("(?m)^a", "b\na"),
    ("(?m)a$", "a\nb"),
    ("(?m)a$", "a\na"),
    (".", "中"),
    (".*", "ab"),
    (".*?", "ab"),
    ("中+", "a中中b"),
    ("a中", "xa中"),
    (r"\d+", "ab12cd"),
    (r"(?-u:\d+)", "ab12cd"),
    (r"(?-u:\bfoo\b)", " foo "),
    (r"(?-u:\bfoo\b)", "afoo "),
    ("(?i:a+)", "bAAa"),
    ("(a+)+", "aaa"),
    ("(a|b)+", "abba"),
    ("foo|bar", "xxbar"),
    ("a{2,4}", "aaaa"),
    ("a{3}", "aa"),
    ("z", "ab"),
    ("baz[0-9]+", "foobaz12345bar"),
    ("a+", "x" + ("a" * 20)),
]

for kind in ("dense", "sparse"):
    for pattern, text in cases:
        compare(kind, pattern, text)

for kind in ("dense", "sparse"):
    rust = run(RUST, "dfa", kind, r"\bfoo", " foo")
    cj = run(CJ, "dfa", kind, r"\bfoo", " foo")
    if rust.returncode or cj.returncode or not rust.stdout.startswith("error") or not cj.stdout.startswith("error"):
        raise AssertionError(dict(kind=kind, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

print("dfa: %s patterns matched on dense and sparse" % len(cases))
