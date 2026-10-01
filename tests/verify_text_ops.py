"""Replacement interpolation, callbacks and split differential verification."""
import json
import random
from regex_test_support import RUST, CJ, REPORT, invoke, compare
count = 0
def check(p, text, mode, *extra):
    global count
    compare(p, text, mode, *extra)
    count += 1

patterns = ['', 'a', 'a*', '(a)?', '(a|ab)', '(ab|a)', '(a(b)?)+',
            '(?<word>[a-z]+)', '(?<x.y>a)', '(?<x[0]>a)', '(中|🙂)', '^|$', '[,;]+']
texts = ['', 'ababa', 'a中🙂b', ',a;;b,', 'ab\ncd']
for p in patterns:
    for text in texts:
        check(p, text, 'split')
        for limit in [0, 1, 2, 4]:
            check(p, text, 'split-n', str(limit))
        check(p, text, 'replace-all', '<$0>:$1:${word}:$$')
        check(p, text, 'replace', '${1}suffix')
        check(p, text, 'replace-n', '$0$0', '2')
        check(p, text, 'replace-literal', '$0${word}$$', '0')
        check(p, text, 'replace-with', '2')
    print('text operation cases passed:', count, flush=True)
# Longest reference, braces, invalid/incomplete references, numeric parsing and UTF-8.
templates = ['$', '$$', '$$$', '$$$$', '$0', '$1', '$01', '$0001', '$1a', '${1}a',
             '$word', '$word_', '${word}tail', '$x.y', '${x.y}', '${x[0]}', '${}', '${+1}',
             '${-1}', '${ 1}', '${1 }', '${+0001}', '${+}', '${18446744073709551616}',
             '$9999999999999999999999999', '${word', '${${1}}', '${missing}', '$中',
             '${中}', '\\$1', '\n$0\t', '🙂${word}中', '$. $! $- $[', '${0}${1}${2}']
p = '(?<word>a)(?<x.y>b)?(?<x[0]>c*)'
for template in templates:
    check(p, 'a abcc', 'replace-all', template)
    check(p, 'abcc', 'expand', template)
for limit in [0, 1, 2, 10]:
    check('(a)', 'aaaa', 'replace-n', '$1!', str(limit))
    check('(a)', 'aaaa', 'replace-literal', '$1!', str(limit))
    check('(a)', 'aaaa', 'replace-with', str(limit))
check('z', 'abc', 'expand', '$0')
check('', '中🙂', 'replace-with', '0')
rng = random.Random(20260924)
for _ in range(150):
    p = rng.choice(patterns)
    text = ''.join(rng.choice('aabc中🙂,;\n') for _ in range(rng.randrange(20)))
    template = ''.join(rng.choice(templates) for _ in range(rng.randrange(4)))
    check(p, text, 'replace-n', template, str(rng.randrange(4)))
    check(p, text, 'split-n', str(rng.randrange(6)))
# Independent user-visible expectations; protocol hex preserves empty fields/newlines.
def encoded(parts):
    return ''.join(x.encode().hex()+'\n' for x in parts).encode()
golden = [
    ('replace-all', '(?<prefix>[A-Z]{2})-[0-9]{3}', 'AB-123 CD-456', ('${prefix}-***',), ['AB-*** CD-***']),
    ('replace-all', '', '中🙂', ('-',), ['-中-🙂-']),
    ('replace-all', '(a)', 'a', ('$1x|${1}x|$$',), ['|ax|$']),
    ('split', ',', ',a,,b,', (), ['', 'a', '', 'b', '']),
    ('split', '', '中🙂', (), ['', '中', '🙂', '']),
    ('split-n', ',', 'a,b,c', ('2',), ['a', 'b,c']),
    ('split-n', ',', 'a,b,c', ('0',), []),
]
for mode, p, text, extra, expected in golden:
    r = invoke(CJ, mode, p, text, *extra)
    assert r.returncode == 0 and r.stdout == encoded(expected), (mode, r)
negative = [('split-n', ('-1',)), ('replace-n', ('x', '-1')),
            ('replace-literal', ('x', '-1')), ('replace-with', ('-1',))]
for mode, extra in negative:
    r = invoke(CJ, mode, 'a', 'a', *extra)
    assert r.returncode == 2 and b'nonnegative' in r.stderr and not r.stdout, r
# Literal substitution and splitting must not allocate captures or hit their guard.
large = '()'*100+'a{6000}'
check(large, '', 'replace-all', 'literal')
check(large, '', 'replace-literal', '$0', '0')
check(large, '', 'split')
report = json.loads(REPORT.read_text())
report.update({'text_operations_differential_passed': count,
               'text_operations_golden_passed': len(golden),
               'text_operations_negative_limits_rejected': len(negative),
               'text_operations_scope': 'template/literal/callback replacement, expand, eager split and splitN'})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
