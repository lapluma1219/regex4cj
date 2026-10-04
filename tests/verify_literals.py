"""Prefix and suffix literal extraction against regex-syntax Extractor defaults."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(kind, pattern):
    args = ("literals", kind, pattern)
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("literal-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


patterns = [
    "abc",
    "foo|bar",
    "ab*c",
    "a*",
    "a*?",
    "a+",
    "a?",
    "a??",
    "a{3}",
    "a{10}",
    "a{11}",
    "a{3,5}",
    "a{0}",
    "a+b",
    "foo(bar|baz)",
    "^abc",
    "abc$",
    ".",
    r"\d",
    "[abc]",
    "[a-c]",
    "[a-j]",
    "[a-k]",
    "中",
    "[中]",
    "(?-u:[a-c])",
    "a" * 150,
    "|".join(f"x{i}" for i in range(250)),
    "|".join(f"x{i}" for i in range(251)),
    r"[a&&b]",
    "(?:ab){2}",
    "sam|samwise",
]

for pattern in patterns:
    compare("prefix", pattern)
    compare("suffix", pattern)

print(f"literal extraction: {len(patterns)} patterns, prefix and suffix")
