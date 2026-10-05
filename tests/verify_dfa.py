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
    ("(?mR)^a", "b\r\na"),
    ("(?mR)a$", "a\r\nb"),
    ("(?mR)a$", "a\nb"),
    ("(?mR)^a", "b\na"),
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

queries = [
    ("dense", "0a", "0", "7", "no", "false", r"foo.+", "foo\nbar"),
    ("sparse", "0a", "0", "7", "no", "false", r"foo.+", "foo\nbar"),
    ("dense", "-", "0", "3", "no", "true", "a+", "aaa"),
    ("sparse", "-", "0", "8", "no", "true", "foo[0-9]+", "foo12345"),
    ("dense", "-", "0", "8", "no", "false", "foo[0-9]+", "foo12345"),
    ("dense", "-", "1", "4", "no", "false", "a+", "xaaa"),
    ("sparse", "-", "2", "3", "yes", "false", "a", "aba"),
    ("dense", "-", "1", "3", "yes", "false", "a", "aba"),
    ("dense", "20", "0", "3", "no", "false", "a+", "a a"),
    ("dense", "61", "0", "2", "no", "false", "b+", "ab"),
    ("sparse", "-", "0", "3", "1", "false", "a", "aaa"),
    ("dense", "-", "0", "2", "0", "false", "a|b", "ab"),
]
for kind, quit, start, end, mode, earliest, pattern, text in queries:
    args = ("dfa-query", kind, quit, start, end, mode, earliest, pattern, text)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

many = [
    ("dense", "0", "3", "no", "false", "aaa", ["a+", "a"]),
    ("sparse", "0", "3", "no", "false", "aaa", ["a", "a+"]),
    ("dense", "0", "2", "no", "false", "ab", ["ab", "a"]),
    ("sparse", "0", "2", "no", "false", "ab", ["a", "ab"]),
    ("dense", "0", "5", "no", "false", "xxbar", ["foo", "bar"]),
    ("sparse", "1", "4", "no", "false", "xaaa", ["a+", "b+"]),
    ("dense", "0", "3", "yes", "false", "aba", ["a", "b"]),
    ("sparse", "0", "3", "no", "true", "aaa", ["a+", "a"]),
    ("dense", "0", "5", "no", "false", "a中b", [".", "中"]),
    ("sparse", "0", "2", "1", "false", "ab", ["a", "b"]),
    ("dense", "0", "2", "9", "false", "ab", ["a", "b"]),
    ("dense", "0", "1", "no", "false", "b", ["^a", "b"]),
]
for kind, start, end, mode, earliest, text, patterns in many:
    args = ("dfa-many", kind, start, end, mode, earliest, text, *patterns)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

overlap = [
    ("dense", "0", "3", "no", "aaa", ["a+"]),
    ("sparse", "0", "3", "no", "aaa", ["a+"]),
    ("dense", "0", "3", "no", "aaa", ["a+", "a"]),
    ("sparse", "0", "3", "no", "aaa", ["a+", "a"]),
    ("dense", "0", "1", "no", "b", ["a*"]),
    ("sparse", "0", "2", "no", "ab", ["a", "b"]),
    ("dense", "0", "5", "no", "xxbar", ["foo", "bar"]),
    ("sparse", "0", "3", "yes", "aba", ["a", "b"]),
    ("dense", "1", "4", "no", "xaaa", ["a+"]),
    ("sparse", "0", "5", "no", "aaabb", ["a+", "b+"]),
]
for kind, start, end, mode, text, patterns in overlap:
    args = ("dfa-overlap", kind, start, end, mode, text, *patterns)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

hybrid = [
    ("-", "0", "3", "no", "false", "aaa", "a+"),
    ("-", "0", "11", "no", "false", "foobaz12345bar", "baz[0-9]+"),
    ("-", "0", "2", "no", "false", "ab", "a|ab"),
    ("-", "0", "3", "no", "true", "aaa", "a+"),
    ("-", "1", "4", "no", "false", "xaaa", "a+"),
    ("-", "0", "4", "no", "false", "b\r\na", "(?mR)^a"),
    ("0a", "0", "7", "no", "false", "foo\nbar", "foo.+"),
    ("-", "0", "3", "no", "false", " foo", r"\bfoo"),
]
for quit, start, end, mode, earliest, text, pattern in hybrid:
    args = ("hybrid", quit, start, end, mode, earliest, text, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

for text, pattern in (("aaa", "a+"), ("foobaz12345bar", "baz[0-9]+")):
    args = ("hybrid-reset", text, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                   rust_error=rust.stderr, cangjie_error=cj.stderr))

rust_small = run(RUST, "hybrid-small", "ababababab", "[ab]{6}")
cj_small = run(CJ, "hybrid-small", "26", "0", "ababababab", "[ab]{6}")
if rust_small.returncode or cj_small.returncode or not rust_small.stdout.startswith("error\tgave up searching at offset ") or not cj_small.stdout.startswith("error\tgave up searching at offset "):
    raise AssertionError(dict(rust=rust_small.stdout, cangjie=cj_small.stdout,
                               rust_error=rust_small.stderr, cangjie_error=cj_small.stderr))

print("dfa: %s patterns matched on dense and sparse, %s input queries, %s multi-pattern queries, %s overlapping queries, %s hybrid searches" % (
    len(cases), len(queries), len(many), len(overlap), len(hybrid)))
