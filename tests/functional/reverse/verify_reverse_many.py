"""Multi-pattern reverse search against dense DFA try_search_rev.

Pattern starts are enabled, so a numeric mode anchors to that pattern.
The offset is the match start. Unicode word boundaries stay out because
the dense reverse DFA refuses them.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(start, end, mode, text, patterns):
    args = ("nfa-rev-many", str(start), str(end), mode, text, *patterns)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("reverse-many-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    (0, 2, "no", "ab", ["a", "b", "ab"]),
    (0, 2, "yes", "ab", ["a", "b", "ab"]),
    (0, 2, "0", "ab", ["a", "b", "ab"]),
    (0, 2, "1", "ab", ["a", "b", "ab"]),
    (0, 2, "2", "ab", ["a", "b", "ab"]),
    (0, 2, "9", "ab", ["a", "b", "ab"]),
    (0, 8, "no", "xxbarfoo", ["foo", "bar"]),
    (2, 8, "no", "xxbarfoo", ["foo", "bar"]),
    (0, 5, "yes", "xxbar", ["foo", "bar"]),
    (0, 7, "1", "samwise", ["sam", "samwise"]),
    (0, 3, "no", "aaa", ["a+", "a"]),
    (1, 3, "no", "aaa", ["a+", "a"]),
    (0, 3, "no", "b\na", ["(?m)^a", "b"]),
    (0, 2, "no", "ba", ["a$", "^a"]),
    (0, 0, "no", "", ["a*", "b"]),
    (0, 5, "no", "a中b", ["中", "a"]),
    (1, 4, "no", "a中b", ["中"]),
    (0, 4, "no", "abab", ["(?:ab)+", "ab"]),
    (0, 4, "yes", "abab", ["ab", "(?:ab)+"]),
    (2, 4, "0", "abab", ["ab", "a"]),
    (0, 6, "no", "foobaz", ["baz", "foo", "oob"]),
    (0, 4, "no", "aaaa", ["a{2,4}", "a{3}"]),
    (0, 1, "no", "z", ["a", "b"]),
    (0, 3, "no", "a\nb", ["(?m)$", "(?m)^"]),
]

for start, end, mode, text, patterns in cases:
    compare(start, end, mode, text, patterns)
print(f"reverse many: {len(cases)} searches matched")
