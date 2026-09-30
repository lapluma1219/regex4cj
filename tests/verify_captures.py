"""Capture slots, group metadata and repeated/nullable path priority regression."""
import json
import random
from regex_test_support import RUST, CJ, REPORT, invoke, compare

patterns = [
    '', '(a)', '(a)(b)', '(a)|(b)', '((a)b)', '(?:a)(b)', '(a)?(b)?',
    '(a*)', '(a*?)', '(a)*', '(a)+', '(a)?', '()', '(()?)*', '(())+',
    '(a?)*', '(a??)*', '(a?)+', '((a?)*)', '(a|aa)*', '(aa|a)*',
    '(a|(b))*', '(a(b)?)+', '((a)|(b))+', '(a(b)?){2,4}', '(a(b)?){2,4}?',
    '((a)?b)*', '((a)|ab)*b', '(a*)*', '(a*?)*?', '((a|)*)',
    '(a){0}', '(a){0}(b)', '((a){0})', '(){10000}', '(()?){3,5}',
    '(?<gone>a){0}(?<live>b)', '(?<outer>(?<inner>a)?b)+', '(?P<x>a+)(?<y>b*)',
    '(?<x.y>a)', '(?<x[0]>a)', '(?<x>a)|(?<y>b)', '(?<empty>)',
    '([a--a])', '((a)[a--a])|(b)', '(中)(🙂)?', '(.*)', '(a$)|(^b)',
    '(^)*', '((^)?)*', '((a){0}){0}', '(?<x>a)(?<y>b)?',
]
texts = ['', 'a', 'b', 'ab', 'aba', 'aabbaa', 'aaaaab', 'a中🙂b', '\n\t', 'ab ab']
count = 0
for p in patterns:
    for text in texts:
        compare(p, text, 'captures')
        count += 1
    compare(p, 'abab', 'capture-first')
    count += 1
    if count % 110 == 0:
        print('capture fixed cases passed:', count, flush=True)
rng = random.Random(20260923)
def pattern(depth):
    if depth == 0:
        return rng.choice(['a', 'b', '', '.', '中', '[ab]', '[a--a]', '^', '$'])
    mode = rng.randrange(4)
    child = pattern(depth - 1)
    if mode == 0:
        return '(' + child + ')' + rng.choice(['*', '+', '?', '*?', '{0}', '{2,4}', '{1,3}?'])
    if mode == 1:
        return '(' + child + '|' + pattern(depth - 1) + ')'
    if mode == 2:
        return '(' + child + ')(' + pattern(depth - 1) + ')'
    return '(?:' + child + ')'
for i in range(300):
    p = pattern(3)
    text = ''.join(rng.choice('aab中🙂\n') for _ in range(rng.randrange(18)))
    compare(p, text, 'captures')
    count += 1
for p, text in [('(a|aa)*b', 'a'*1000+'b'), ('(a?)*', 'a'*500),
                ('(?<x>中🙂)+', '中🙂'*100), ('(a){0}(b){0}(c)', 'c')]:
    compare(p, text, 'captures')
    count += 1
# Independent golden output distinguishes absent groups from captured empty strings.
golden = [
    ('(a)?(b*)', '', 'groups\t3\nmatch\ngroup\t0\t0\t0\t\ngroup\t1\t-\ngroup\t2\t0\t0\t\n'),
    ('(中)(🙂)', 'a中🙂b', 'groups\t3\nmatch\ngroup\t0\t1\t8\te4b8adf09f9982\ngroup\t1\t1\t4\te4b8ad\ngroup\t2\t4\t8\tf09f9982\n'),
]
for p, text, expected in golden:
    result = invoke(CJ, 'captures', p, text)
    assert result.returncode == 0 and result.stdout == expected.encode(), (p, result)
name_checks = 0
for p, text in [('(?<x>a)(?<y>b)?', 'a'), ('(?<x>a*)', ''), ('(?<x>a)', 'b'),
                ('(?<gone>a){0}(?<live>b)', 'b'), ('(?<x[0]>中)', '中')]:
    for name in ['x', 'y', 'gone', 'live', 'x[0]', '', 'missing']:
        rust = invoke(RUST, 'capture-name', p, text, name)
        cj = invoke(CJ, 'capture-name', p, text, name)
        assert rust.returncode == cj.returncode == 0 and rust.stdout == cj.stdout, (p, name, rust, cj)
        name_checks += 1
invalid = ['(?<x>a)(?<x>b)', '(?<x>a){0}(?<x>b)', '(?<>a)', '(?<0x>a)',
           '(?<a-b>a)', '(?P<x', '(?<x', '(?<x>a']
for p in invalid:
    assert invoke(RUST, 'captures', p, '').returncode != 0, p
    result = invoke(CJ, 'captures', p, '')
    assert result.returncode == 2 and result.stderr and not result.stdout, (p, result)
unicode_names = ['(?<名字>a)', '(?<é>a)']
for p in unicode_names:
    compare(p, 'a', 'captures')
    count += 1
compare('()'*128, '', 'captures')
limit = invoke(CJ, 'captures', '()'*129, '')
assert limit.returncode == 2 and b'capture' in limit.stderr, limit
workspace_pattern = '()'*100 + 'a{6000}'
limit = invoke(CJ, 'captures', workspace_pattern, '')
assert limit.returncode == 2 and b'workspace' in limit.stderr, limit
compare(workspace_pattern, '', 'find')
report = json.loads(REPORT.read_text())
report.update({'capture_differential_passed': count + 1, 'capture_golden_passed': len(golden),
               'capture_name_checks_passed': name_checks, 'capture_invalid_rejected': len(invalid),
               'capture_unicode_names_passed': len(unicode_names),
               'capture_resource_limits_checked': 2,
               'limitations': ['CLI cannot transport NUL', 'findAll/capturesAll are eager',
                               'This is not full regex compatibility; see docs/milestone-3.md'],
               'matching_scope': 'Unicode-scalar NFA, classes, counted repetitions and captures; no properties/flags/bytes/DFA'})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
