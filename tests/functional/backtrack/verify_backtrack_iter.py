"""Non-overlapping BoundedBacktracker matches against regex-automata.

Each line is pattern:start:end:escaped-text. Empty matches advance the same
way as Searcher. A haystack past the visited budget is an error line, not a miss.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def check(args):
    rust, cj = run(RUST, args), run(CJ, args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout or rust.stderr != cj.stderr:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("backtrack-iter-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ["backtrack-iter", "1048576", "xa", "a"],
    ["backtrack-iter", "1048576", "aaa", "a+"],
    ["backtrack-iter", "1048576", "aaa", "a+?"],
    ["backtrack-iter", "1048576", "ab", "a*"],
    ["backtrack-iter", "1048576", "", "a*"],
    ["backtrack-iter", "1048576", "ab", ""],
    ["backtrack-iter", "1048576", "a中b", "中"],
    ["backtrack-iter", "1048576", "中", "a*"],
    ["backtrack-iter", "1048576", "a b", "a b"],
    ["backtrack-iter", "1048576", "xxbar", "foo|bar"],
    ["backtrack-iter", "1048576", "ab", "a|ab"],
    ["backtrack-iter", "1048576", "aaa", "a+", "a"],
    ["backtrack-iter", "1048576", "b", "a", "b"],
    ["backtrack-iter", "1048576", "xaa", "(?<n>a+)"],
    ["backtrack-iter", "1048576", "ab12cd", r"\d+"],
    ["backtrack-iter", "1048576", "b\na", "(?m)^a"],
    ["backtrack-iter", "1", "aaaa", "a+"],
    ["backtrack-iter", "1048576", "zzab", "[a-c]+"],
]

for args in cases:
    check(args)

print(f"backtrack iter: {len(cases)} commands matched")
