"""One-pass, meta, regex-lite, rure, and DFA image round-trip.

Each command is compared with the corresponding Rust entry. A bad DFA image
is rejected by the Cangjie loader; regex-automata's wire format is different,
so that rejection is checked on its own.
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
        REPORT.with_name("products-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ("onepass", "a+", "aaa"),
    ("onepass", "a+", "xxaaa"),
    ("onepass", "abc", "zzabc"),
    ("onepass", "(a)(b)", "ab"),
    ("onepass", "^a", "ab"),
    ("onepass", "a$", "ba"),
    ("onepass", "(?m)^a", "b\na"),
    ("onepass", "a*[ab]", "aaab"),
    ("onepass", "a*a", "aaa"),
    ("onepass", "(^|$)a", "a"),
    ("meta", "a+", "xxaaa"),
    ("meta", "a*[ab]", "aaab"),
    ("meta", "foo|bar", "xxbar"),
    ("meta", "(?m)^a", "b\na"),
    ("lite", r"\w+", "a_b"),
    ("lite", r"\w", "é"),
    ("lite", r"\d+", "a12b"),
    ("lite", r"\bword\b", "word "),
    ("lite", r"\p{L}", "a"),
    ("rure", "a+", "xxaaa"),
    ("rure", "(a)(b)", "zab"),
    ("rure", "z", "ab"),
    ("dfa-image", "a+", "xxaaa"),
    ("dfa-image", "foo|bar", "xxbar"),
    ("dfa-image", "(?m)^a", "b\na"),
]

for args in cases:
    compare(args)

bad = run(CJ, "dfa-image-bad")
if bad.returncode or bad.stdout != "error\tinvalid DFA serialization\n":
    raise AssertionError(dict(stdout=bad.stdout, code=bad.returncode))
print(f"products: {len(cases)} commands matched, bad image rejected")
