"""HIR properties and HIR-built PikeVM versus the pinned Rust libraries."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(mode, *args):
    rust, cangjie = run(RUST, mode, *args), run(CJ, mode, *args)
    if rust.returncode or cangjie.returncode or rust.stdout != cangjie.stdout:
        failure = dict(args=(mode, *args), rust=rust.stdout, cangjie=cangjie.stdout,
                       rust_error=rust.stderr, cangjie_error=cangjie.stderr,
                       rust_code=rust.returncode, cangjie_code=cangjie.returncode)
        REPORT.with_name('props-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


patterns = [
    'a', '(a)', '(a)|(b)', '(a)(b)|(c)(d)', '(a)|b', 'a|(b)', '(b)*', '(b)+',
    '^', 'a*', '[a&&b]', r'\w', r'\p{Cyrillic}', 'foo', 'f+', '(foo)', r'^a$', r'a*^',
    r'\b', 'foo|bar|baz', 'a|b|c', '', r'(?m)^', r'(?mR:$)', r'(?s).', r'(?-u:\w)',
    '中文', r'(?<id>[0-9]{6})', 'a|ab', r'\P{any}',
]
for pattern in patterns:
    compare('hir-props', pattern, 'true')
compare('hir-props', r'(?-u:\xFF)', 'false')
compare('hir-props', r'(?-u)\xE2\x98\x83', 'false')

searches = [
    ('(?<id>[0-9]{6})', 'id=123456', '0', '9', 'false'),
    ('sam|samwise', 'samwise', '0', '7', 'false'),
    (r'(?m)^a', 'b\na', '0', '3', 'false'),
    (r'\bbar', 'foo bar', '4', '7', 'false'),
    ('ab', 'zab', '0', '3', 'true'),
    ('a|ab', 'ab', '0', '2', 'false'),
]
hir_searches = 0
for pattern, text, start, end, anchored in searches:
    direct = run(CJ, 'pike', start, end, anchored, text, pattern)
    built = run(CJ, 'pike-hir', start, end, anchored, text, pattern)
    if direct.returncode or built.returncode or direct.stdout != built.stdout:
        raise AssertionError((pattern, direct.stdout, built.stdout, built.stderr))
    hir_searches += 1

report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update(hir_property_cases_passed=len(patterns) + 2, hir_pike_cases_passed=hir_searches)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'HIR properties: {len(patterns) + 2} matched; HIR PikeVM: {hir_searches}', flush=True)
