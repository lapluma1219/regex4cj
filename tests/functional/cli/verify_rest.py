"""Half matches, captures, which, timing rows, memory, and DFA byte budget.

Timing values are measured on each side, so only the label is required to
exist. Memory numbers count each implementation's own tables; the shared
check is that a Unicode class costs more than its ASCII form, and that a
1-byte DFA budget fails while a large budget succeeds.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=60)


def compare(args):
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout or rust.stderr != cj.stderr:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("rest-failure.json").write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


def compare_table(args):
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stderr != cj.stderr:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                                  rust_error=rust.stderr, cangjie_error=cj.stderr))
    def split(text):
        rows, body = [], []
        for line in text.splitlines(True):
            if line.startswith("search time:") or line.startswith("total matches:"):
                rows.append(line)
            else:
                body.append(line)
        return rows, "".join(body)
    rust_rows, rust_body = split(rust.stdout)
    cj_rows, cj_body = split(cj.stdout)
    rust_total = [row for row in rust_rows if row.startswith("total matches:")]
    cj_total = [row for row in cj_rows if row.startswith("total matches:")]
    rust_time = [row for row in rust_rows if row.startswith("search time:")]
    cj_time = [row for row in cj_rows if row.startswith("search time:")]
    if rust_body != cj_body or rust_total != cj_total or not rust_time or not cj_time:
        raise AssertionError(dict(args=args, rust=rust.stdout, cangjie=cj.stdout))


def budget(limit, pattern):
    rust, cj = run(RUST, "dfa-budget", limit, pattern), run(CJ, "dfa-budget", limit, pattern)
    if rust.returncode or cj.returncode:
        raise AssertionError(dict(limit=limit, rust=rust.stdout, cangjie=cj.stdout,
                                  rust_error=rust.stderr, cangjie_error=cj.stderr))
    rust_kind = rust.stdout.split("\t", 1)[0]
    cj_kind = cj.stdout.split("\t", 1)[0]
    if rust_kind != cj_kind:
        raise AssertionError(dict(limit=limit, rust=rust.stdout, cangjie=cj.stdout))
    return rust_kind


def memory(engine, pattern):
    rust, cj = run(RUST, "memory", engine, pattern), run(CJ, "memory", engine, pattern)
    if rust.returncode or cj.returncode:
        raise AssertionError(dict(engine=engine, pattern=pattern, rust=rust.stdout, cangjie=cj.stdout,
                                  rust_error=rust.stderr, cangjie_error=cj.stderr))
    return int(rust.stdout.strip()), int(cj.stdout.strip())


cases = [
    ("cli-half", "dense", "-p", "a+", "-y", "xxaaa"),
    ("cli-half", "dense", "-p", "a", "-y", "abaca"),
    ("cli-half", "sparse", "-p", "foo|bar", "-y", "xxbar"),
    ("cli-half", "hybrid", "-p", "a+", "-y", "xxaaa"),
    ("cli-capture", "pikevm", "-p", "(?<n>a+)", "-y", "baaa"),
    ("cli-capture", "pikevm", "-p", "(a)|(b)", "-y", "b"),
    ("cli-capture", "backtrack", "-p", "(a)(b)", "-y", "zab"),
    ("cli-capture", "meta", "-p", "(a)(b)", "-y", "zab"),
    ("cli-capture", "lite", "-p", r"(\d+)", "-y", "a12b"),
    ("cli-capture", "regex", "-p", "(a)|(b)", "-y", "b"),
    ("cli-which", "pikevm", "-p", "a", "-p", "b", "-y", "ab"),
    ("cli-which", "pikevm", "-p", "a", "-p", "z", "-y", "ab"),
    ("cli-which", "dense", "-p", "foo", "-p", "bar", "-y", "xxbar"),
    ("cli-which", "meta", "-p", "a+", "-p", "b+", "-y", "xxaaa"),
    ("cli-which", "hybrid", "-p", "a", "-p", "c", "-y", "ab"),
    ("cli-which", "sparse", "-p", "a", "-p", "b", "-y", "b"),
]

for args in cases:
    compare(args)

compare_table(("cli-find", "pikevm", "--table", "-p", "a", "-y", "abaca"))
compare_table(("cli-find", "dense", "--table", "-p", "a+", "-y", "xxaaa"))
compare_table(("cli-find", "meta", "--table", "-p", "foo|bar", "-y", "xxbar"))

if budget("1", "a+") != "error":
    raise AssertionError("a 1-byte DFA budget should fail")
if budget("50000000", "a+") != "ok":
    raise AssertionError("a large DFA budget should succeed")

for engine, wide, narrow in (
    ("pikevm", r"\w", r"(?-u:\w)"),
    ("backtrack", r"\w", r"(?-u:\w)"),
    ("dense", "foo|bar|baz", "a"),
    ("meta", "foo|bar|baz", "a"),
):
    wide_rust, wide_cj = memory(engine, wide)
    narrow_rust, narrow_cj = memory(engine, narrow)
    if wide_rust <= narrow_rust or wide_cj <= narrow_cj or wide_cj <= 0 or narrow_cj <= 0:
        raise AssertionError(dict(engine=engine, wide=(wide_rust, wide_cj), narrow=(narrow_rust, narrow_cj)))

print(f"rest: {len(cases)} commands, timing rows, byte budget, and memory ordering matched")
