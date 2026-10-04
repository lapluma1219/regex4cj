"""Public PikeVM: pattern id, span, captures, anchoring and search bounds.

The oracle is regex-automata' PikeVM from the pinned regex revision. Bounds are
byte offsets into the original haystack, so look-around can see text outside
the searched range.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(*args):
    r, c = run(RUST, *args), run(CJ, *args)
    if r.returncode or c.returncode or r.stdout != c.stdout:
        failure = dict(args=args, rust=r.stdout, cangjie=c.stdout,
                       rust_error=r.stderr, cangjie_error=c.stderr,
                       rust_code=r.returncode, cangjie_code=c.returncode)
        REPORT.with_name('pike-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


cases = [
    (0, 2, 'false', 'ab', 'a'),
    (0, 2, 'true', 'xa', 'a'),
    (0, 2, 'false', 'xa', 'a'),
    (0, 3, 'false', 'b\na', '(?m)^a'),
    (0, 3, 'true', 'b\na', '(?m)^a'),
    (0, 7, 'false', 'samwise', 'sam|samwise'),
    (0, 2, 'false', 'ab', 'ab', 'a'),
    (0, 2, 'false', 'ab', 'b', 'a'),
    (0, 9, 'false', 'id=123456', r'(?<id>[0-9]{6})'),
    (3, 6, 'false', 'foo123bar', r'\b123\b'),
    (3, 6, 'true', 'foo123bar', r'\b123\b'),
    (3, 6, 'false', 'foo123bar', '123'),
    (0, 2, 'false', 'abcd', 'abc'),
    (0, 4, 'true', 'abcd', 'abc'),
    (0, 0, 'true', '', 'a*'),
    (1, 3, 'false', 'zab', 'ab'),
    (0, 3, 'true', 'zab', 'ab'),
    (4, 7, 'true', 'foo bar', r'\bbar'),
    (0, 6, 'false', '123456', r'([0-9]{3})([0-9]{3})'),
]
count = 0
for start, end, anchored, text, *patterns in cases:
    compare('pike', str(start), str(end), anchored, text, *patterns)
    count += 1
# A bound inside a scalar is a caller error. The pinned PikeVM reports no match
# for this particular range; the public API rejects it instead of dropping it.
mid_scalar = run(CJ, 'pike', '1', '2', 'false', 'é', 'a')
assert mid_scalar.returncode == 2 and 'UTF-8 boundary' in mid_scalar.stderr, mid_scalar
reversed_range = run(CJ, 'pike', '2', '1', 'false', 'ab', 'a')
assert reversed_range.returncode == 2 and 'invalid search range' in reversed_range.stderr, reversed_range
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update(pike_cases_passed=count, pike_invalid_rejected=2)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'PikeVM: {count} searches matched, 2 invalid ranges rejected', flush=True)
