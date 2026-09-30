"""Behavioral differential tests for the explicitly supported regex subset."""
import json
import os
from pathlib import Path
import random
import subprocess

from regex_test_support import ROOT, RUST, CJ, ENV, REPORT, invoke, compare

patterns = ['', 'a', '中', '🙂', '.', '^', '$', '^$', '^a', 'a$', r'\Aa\z',
            'a|ab', 'ab|a', 'a|', '|a', 'a*', 'a*?', 'a+', 'a+?', 'a?', 'a??',
            '(ab|a)*b', '(a?)*', '(a?|b)*', '(a*?)*', '(a?)*?', '(a|aa)+',
            '(a|aa)+?', '(?:ab)+', '(a*)*', '(a?)+', '(a??)+', '(a|)*b',
            '.*', '.*?', '^.*$', '(中|🙂)+', r'a\+b\.txt', r'\n', r'\t',
            '(a$|b)', '(a|^)*', '($|a)*']
texts = ['', 'a', 'ab', 'aaa', 'baab', 'abab', '中a🙂中', 'a\nb', '\n', 'a+b.txt']
count = 0
for pattern in patterns:
    for text in texts:
        compare(pattern, text)
        count += 1
    if count % 100 == 0:
        print('matching fixed cases passed:', count, flush=True)

# Generate structured patterns, including nullable nested repetitions. Reproducible seed.
rng = random.Random(20260921)
def pattern(depth):
    if depth == 0:
        return rng.choice(['a', 'b', '中', '🙂', '.', '', r'\.', r'\n', '^', '$'])
    kind = rng.randrange(4)
    if kind == 0:
        return '(?:' + pattern(depth - 1) + '|' + pattern(depth - 1) + ')'
    if kind == 1:
        return '(?:' + pattern(depth - 1) + ')' + rng.choice(['*', '+', '?', '*?', '+?', '??'])
    if kind == 2:
        return pattern(depth - 1) + pattern(depth - 1)
    return pattern(0)
for _ in range(160):
    compare(pattern(3), ''.join(rng.choice('aab中🙂\n') for _ in range(rng.randrange(18))))
    count += 1

for p, text in [('a|ab', 'ab'), ('a+', 'aaa'), ('a+?', 'aaa'), ('', '中'),
                ('中', 'a中b'), ('^b', 'ab'), ('a', ''), ('.', '\n')]:
    compare(p, text, 'first')
    compare(p, text, 'is-match')

# Explicit user-visible expectations independent of oracle comparisons.
golden = [('中', 'a中b', '1\t4\t中\n'), ('a|ab', 'ab', '0\t1\ta\n'),
          ('a*', 'aaa', '0\t3\taaa\n'), ('', '中', '0\t0\t\n3\t3\t\n')]
for p, text, expected in golden:
    result = invoke(CJ, 'find', p, text)
    assert result.returncode == 0 and result.stdout == expected.encode(), (p, result)

# Unsupported valid Rust patterns must be rejected, never silently reinterpreted.
unsupported = ['a**']
for p in unsupported:
    assert invoke(RUST, 'find', p, 'aaa').returncode == 0, p
    result = invoke(CJ, 'find', p, 'aaa')
    assert result.returncode == 2 and result.stderr and not result.stdout, (p, result)
invalid = ['(', ')', '[', '*a', 'a\\', '(?:', '(?=a)', r'(a)\1']
for p in invalid:
    assert invoke(RUST, 'find', p, 'a').returncode != 0, p
    result = invoke(CJ, 'find', p, 'a')
    assert result.returncode == 2 and result.stderr and not result.stdout, (p, result)
for p in ['a' * 4097, '(' * 65 + 'a' + ')' * 65]:
    result = invoke(CJ, 'find', p, 'a')
    assert result.returncode == 2 and result.stderr, p[:30]

# Inputs that expose exponential backtracking and search-at-every-start implementations.
for p, text in [('(a|aa)*b', 'a' * 8000), ('(a?)*b', 'a' * 8000),
                ('a+b', 'a' * 8000 + 'b'), ('a' * 1000, 'a' * 1000)]:
    compare(p, text)
    count += 1
report = json.loads(REPORT.read_text())
report.update({'matching_differential_passed': count, 'find_and_is_match_checks_passed': 16,
               'matching_golden_passed': len(golden), 'unsupported_patterns_rejected': len(unsupported),
               'invalid_patterns_rejected': len(invalid), 'resource_limits_checked': 2,
               'cangjie_matching_engine_implemented': True,
               'matching_scope': 'restricted Unicode-scalar Thompson NFA; no Unicode-properties/flags/bytes/DFA',
               'limitations': ['CLI cannot transport NUL', 'findAll is eager',
                              'This is not full regex compatibility; see docs/milestone-3.md']})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
