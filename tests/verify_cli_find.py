"""regex-cli find match pikevm: match lines and exit status.

The line is pattern:start:end:escaped-text, using the same byte escaping as
bstr's escape_bytes. Timing tables are outside this comparison. A passing
corpus accepts only this locked 1-point leaf.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def check(args):
    rust, cj = run(RUST, args), run(CJ, args)
    if rust.returncode != cj.returncode or rust.stdout != cj.stdout or rust.stderr != cj.stderr:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("cli-find-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    ["cli-find", "pikevm", "-p", "a", "-y", "xa"],
    ["cli-find", "pikevm", "-p", "a+", "-y", "aaa"],
    ["cli-find", "pikevm", "-p", "foo|bar", "-y", "xxbar"],
    ["cli-find", "pikevm", "-p", "a|ab", "-y", "ab"],
    ["cli-find", "pikevm", "-p", "(?<n>a+)", "-y", "baaa"],
    ["cli-find", "pikevm", "-p", "中", "-y", "a中b"],
    ["cli-find", "pikevm", "-p", "a*", "-y", "a"],
    ["cli-find", "pikevm", "-p", "a*", "-y", ""],
    ["cli-find", "pikevm", "-p", "", "-y", "ab"],
    ["cli-find", "pikevm", "-p", "a*", "-y", "中"],
    ["cli-find", "pikevm", "-p", r"a b", "-y", "a b"],
    ["cli-find", "pikevm", "-p", r"a\tb", "-y", "a\tb"],
    ["cli-find", "pikevm", "-p", "a+", "-p", "a", "-y", "aaa"],
    ["cli-find", "pikevm", "-p", "a", "-p", "b", "-y", "b"],
    ["cli-find", "pikevm", "-p", "z", "-y", "ab"],
    ["cli-find", "dense", "-p", "a", "-y", "a"],
    ["cli-find", "dense", "-p", "a", "-y", "abaca"],
    ["cli-find", "dense", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "backtrack", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "backtrack", "-p", "foo|bar", "-y", "xxbar"],
    ["cli-find", "meta", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "meta", "-p", "a*", "-y", "ab"],
    ["cli-find", "lite", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "lite", "-p", r"\w+", "-y", "a_b"],
    ["cli-find", "lite", "-p", "a", "-p", "b", "-y", "ab"],
    ["cli-find", "onepass", "-p", "a+", "-y", "aaa"],
    ["cli-find", "onepass", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "sparse", "-p", "a", "-y", "abaca"],
    ["cli-find", "sparse", "-p", "foo|bar", "-y", "xxbar"],
    ["cli-find", "hybrid", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "hybrid", "-p", "a*", "-y", "ab"],
    ["cli-find", "regex", "-p", "a+", "-y", "xxaaa"],
    ["cli-find", "regex", "-p", "a|ab", "-y", "ab"],
    ["cli-find", "regex", "-p", "a*", "-y", "ab"],
    ["cli-find", "regex", "-p", "a", "-p", "b", "-y", "ab"],
    ["cli-find", "pikevm", "-p", "(", "-y", "a"],
    ["cli-find", "pikevm", "-p", "(?=a)", "-y", "a"],
    ["cli-find", "pikevm", "-y", "a"],
    ["cli-find", "pikevm", "-p", "a"],
]

for args in cases:
    check(args)

print(f"cli find pikevm: {len(cases)} commands matched")
