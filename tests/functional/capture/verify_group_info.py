"""Capture length, static length, and names against regex::Regex.

SetMatches bidirectional iteration is already compared by the API contract
audit. This file covers the shared capture-metadata half of that contract for
both string and bytes regexes. A passing corpus does not close the coarse item.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT

patterns = [
    "a", "(a)", "(a)(b)", "(a)|(b)", "(?:a)(b)", "(a)?", "(a)*", "(a)+",
    "()", "(?<name>a)", "(?P<x>a+)(?<y>b*)", "(?<gone>a){0}(?<live>b)",
    "(a){0}", "(中)", "(a)(b)?", "((a)b)", "(?<x>a)|(?<y>b)", "(?<empty>)",
    "a|b", "(?i)(A)", "(?m)(^a)",
]


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


count = 0
for mode in ("group-info", "bytes-group-info"):
    for pattern in patterns:
        rust, cj = run(RUST, mode, pattern), run(CJ, mode, pattern)
        if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
            failure = dict(mode=mode, pattern=pattern, rust=rust.stdout, cangjie=cj.stdout,
                           rust_error=rust.stderr, cangjie_error=cj.stderr,
                           rust_code=rust.returncode, cangjie_code=cj.returncode)
            REPORT.with_name("group-info-failure.json").write_text(
                json.dumps(failure, ensure_ascii=False, indent=2))
            raise AssertionError(failure)
        count += 1

print(f"group info: {count} patterns matched")
