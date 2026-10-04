"""Public HIR slice: compare normalized structure and every node's byte lengths.

Scope is deliberately smaller than regex-syntax: no look, dot or alternation.
The fixed Rust library independently parses/builds each input.
"""
import json
import random
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
        REPORT.with_name('hir-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)
    return r.stdout


constructors = compare('hir-constructors').splitlines()
assert len(constructors) == 205
assert len({line.split('\t')[0] for line in constructors}) == 205
patterns = [
    '', 'abc', '中文🙂', r'\x00', r'\x{10FFFF}', r'\x{D7FF}\x{E000}',
    '[0-9]{6}', 'a{0}', '(a){0}', '(?:){9,}', '(){2,}', '(){0,}',
    '[a&&b]', '[a&&b]*', '[a&&b]{0}', '[a&&b]z',
    '[a]', '[中]', '[a-cb-e]', '[^a]', r'\w', r'\p{Greek}',
    r'[\x{D7FF}-\x{E000}]', '[a中🙂]', r'(?-u:[a-z])', r'(?-u:\w)',
    '(?i:a)', '(?i:中)', '(?i-u:a)', '(?i-u:[a-c])',
    'ab(cd)ef', '(?<x>a)(b)?', '(?<名字>中)+?', '(?:ab)(?:cd)',
    'a{2,4}?', '(?U:a+)', '(a{4294967295}){4294967295}',
    '((a{4294967295}){4294967295}){4294967295}',
    '(?x: a #comment\n b )', r'(?-u:é)', r'(?-u:\x7F)',
]
rng = random.Random(20261004)
atoms = ['a', '中', '[0-9]', '[a-z]', '(ab)', '(?:é)', '(?<n>z)', '[a&&b]', '()']
for _ in range(120):
    # One atom per repeated expression avoids duplicate named capture errors.
    atom = rng.choice(atoms)
    patterns.append('x' + '(?:' + atom + ')' + rng.choice(['', '?', '*', '+?', '{0}', '{1}', '{2,3}']) + 'y')
count = 0
for pattern in patterns:
    for utf8 in ['true', 'false']:
        compare('hir', pattern, utf8)
        count += 1
for pattern in [r'(?-u:\xFF)', r'(?-u:[\x80-\xFF])', r'(?-u:[^a])']:
    compare('hir', pattern, 'false')
    count += 1
# Distinguish invalid patterns from valid patterns outside the public slice.
for pattern in ['a|bc', '.', '^a', r'\bword']:
    r, c = run(RUST, 'hir', pattern, 'true'), run(CJ, 'hir', pattern, 'true')
    assert r.returncode == 0 and c.returncode == 2 and 'public HIR slice' in c.stderr, (pattern, r, c)
for pattern in ['(', '[z-a]', 'a{4,2}', r'(?-u:\xFF)']:
    r, c = run(RUST, 'hir', pattern, 'true'), run(CJ, 'hir', pattern, 'true')
    assert r.returncode == c.returncode == 2, (pattern, r, c)
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update(hir_constructor_cases_passed=205, hir_parse_cases_passed=count,
              hir_unsupported_rejected=4, hir_invalid_rejected=4)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'HIR: {count} parse cases, 205 constructors, 4 explicit unsupported and 4 invalid rejected', flush=True)
