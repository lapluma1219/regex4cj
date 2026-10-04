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
# Every byte offset is legal, including positions inside UTF-8 scalars.
for text in ['éa', '中a', '🙂a']:
    for start in range(len(text.encode()) + 1):
        for end in range(start, len(text.encode()) + 1):
            for anchored in ['true', 'false']:
                for patterns in [[], [''], ['a'], ['.'], ['a', '']]:
                    compare('pike', str(start), str(end), anchored, text, *patterns)
                    count += 1
overlap = [
    ('foobar', r'\w+', r'\d+', r'\pL+', 'foo', 'bar', 'barfoo', 'foobar'),
    ('samwise', 'sam', 'samwise'),
    ('', 'a*', 'b'),
    ('aaa', 'a+', 'b'),
    ('abc', 'a', 'bc', 'ab', 'z'),
]
for text, *patterns in overlap:
    compare('pike-overlap', text, *patterns)
    count += 1
earliest = [
    ('aaa', 'a+'),
    ('aaa', 'a*'),
    ('aaa', 'a?'),
    ('aaa', 'a{3}'),
    ('xyz', 'a+'),
    ('aaa', 'a', 'a+'),
    ('aaa', 'a+', 'a'),
    ('id=123456', r'(?<id>[0-9]{6})'),
    ('foobar', 'foo', 'foobar', 'bar'),
    ('ab', 'a|ab'),
]
for text, *patterns in earliest:
    compare('pike-earliest', text, *patterns)
    count += 1
reversed_range = run(CJ, 'pike', '2', '1', 'false', 'ab', 'a')
assert reversed_range.returncode == 2 and 'invalid search range' in reversed_range.stderr, reversed_range
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update(pike_cases_passed=count, pike_invalid_rejected=1)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'PikeVM: {count} searches matched, 1 invalid range rejected', flush=True)
