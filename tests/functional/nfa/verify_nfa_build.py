"""HIR construction and reverse configuration against the Rust builders.

A successful HIR build prints ok. A parse failure stays on the syntax path.
A size-limit failure is CompiledTooBig, which is a different kind from a
parse error even when the automata wording differs.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def exact(args):
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("nfa-build-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


def both_fail(args, cangjie_mark, rust_mark):
    rust, cj = run(RUST, *args), run(CJ, *args)
    if rust.returncode or cj.returncode or cangjie_mark not in cj.stdout or rust_mark not in rust.stdout:
        failure = dict(args=args, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name("nfa-build-failure.json").write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


exact(("nfa-build", "10485760", "a+"))
exact(("nfa-rev-empty",))
exact(("nfa-rev-limit", "10485760", "a+"))
both_fail(("nfa-build", "0", "a+"), "CompiledTooBig", "exceeded limit")
both_fail(("nfa-build", "10485760", "["), "Syntax\tparse", "Syntax\tparse")
both_fail(("nfa-rev-limit", "0", "a+"), "exceeds size limit", "error building NFA")
print("nfa build: construction and reverse configuration matched")
