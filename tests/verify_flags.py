"""Lexically scoped m/s/U inline flags and their matching/capture semantics."""
import json
import random
from regex_test_support import RUST, CJ, REPORT, invoke, compare
patterns = ['(?m)^', '(?m)$', '(?m)^.*$', '(?m)^a$', '(?s).+', '(?s:.)',
            '(?s:.)(?-s:.)', '(?s)(.)(?-s)(.)', '(?U)a+', '(?U)a+?',
            '(?U)(a{1,3})', '(?U)(a{1,3}?)', '(?U)(a?)*', '(?U)(a??)*?',
            '(?s:a.b)c.d', '((?s)a.b)c.d', '(?s:a|b.c)', '(a(?s)b|c.d)e.f',
            '(?s)(?-s:a.b)c.d', '(?ms)^.+$', '(?msU)^(.*)$', '(?m-s:^a.$)',
            r'(?m)\A.*\z', r'(?ms)\A.*\z', '(?m:^)a(?m:$)', '(?s)[^a]',
            '(?U:a+)(a+)', '((?U)a+)(a+)', '(?U)(?-U:a+)(a+)', '(?m)(^)*',
            '(?s)', '(?m:)', '(?s)(?-s)', 'a(?s)|.', '(?m)^|$', '(?<x>(?s:.+?))',
            '(?U:a+)*', '(?U)(a(?-U)a+)+?', '(?s:(?-s).)|.', '(?m-sU:a.*$)']
texts = ['', 'a', 'aaaa', 'a\nb', 'a\n', '\na\n', 'a\r\nb', 'a\rb', '中\n🙂', 'c\ndexf']
count = 0
for p in patterns:
    for text in texts:
        compare(p, text)
        compare(p, text, 'captures')
        count += 2
    if count % 100 == 0: print('flag fixed cases passed:', count, flush=True)
rng = random.Random(20260925)
def pattern(depth):
    if depth == 0: return rng.choice(['a', '.', '^', '$', '中', '[ab]', ''])
    inner = pattern(depth-1)
    flag = rng.choice(['m', 's', 'U', 'msU', '-s', 'm-U', '-mU'])
    return rng.choice(['(?'+flag+':'+inner+')', '((?'+flag+')'+inner+')',
                       '('+inner+'|'+pattern(depth-1)+')'])+rng.choice(['', '+', '*?', '{0,2}'])
for _ in range(160):
    p = pattern(2)
    text = ''.join(rng.choice('aa中🙂\n\r') for _ in range(rng.randrange(16)))
    compare(p, text, 'captures')
    count += 1
api_checks = 0
for p, text in [('(?m)^a$', 'a\na\r\na'), ('(?s)(.)', 'a\n🙂'), ('(?U)(a+)', 'aaa')]:
    for mode, extra in [('first', ()), ('is-match', ()), ('split', ()), ('replace-all', ('<$1>',))]:
        compare(p, text, mode, *extra)
        api_checks += 1
golden = [('(?m)^a$', 'a\na\r\na', '0\t1\ta\n5\t6\ta\n'),
          ('(?U)a+', 'aaa', '0\t1\ta\n1\t2\ta\n2\t3\ta\n'),
          ('(?U)a+?', 'aaa', '0\t3\taaa\n'),
          ('(?s).', '🙂', '0\t4\t🙂\n')]
for p, text, expected in golden:
    r = invoke(CJ, 'find', p, text)
    assert r.returncode == 0 and r.stdout == expected.encode(), (p,r)
invalid = ['(?)', '(?-)', '(?m-)', '(?mm)', '(?m-m)', '(?m--s)', '(?s',
           '(?s:a', '(?s)*', 'a(?s)+', '(?U){2}', '(?q)', '(?m s)', '(?s-:.)']
for p in invalid:
    assert invoke(RUST, 'find', p, '').returncode != 0, p
    r = invoke(CJ, 'find', p, '')
    assert r.returncode == 2 and r.stderr and not r.stdout, (p,r)
unsupported = ['(?i)a', '(?x)a', '(?R).', '(?u)a', '(?-u:a)', '(?-i)a']
for p in unsupported:
    assert invoke(RUST, 'find', p, 'a').returncode == 0, p
    r = invoke(CJ, 'find', p, 'a')
    assert r.returncode == 2 and r.stderr and not r.stdout, (p,r)
report = json.loads(REPORT.read_text())
report.update({'flags_differential_passed': count, 'flags_api_checks_passed': api_checks,
               'flags_golden_passed': len(golden), 'flags_invalid_rejected': len(invalid),
               'flags_unsupported_rejected': len(unsupported),
               'matching_scope': 'Unicode-scalar NFA, classes, repeats, captures and scoped m/s/U flags; no Unicode properties/case folding/bytes/DFA',
               'limitations': ['CLI cannot transport NUL; native tests cover selected NUL cases',
                               'findAll/capturesAll/split are eager', 'ASCII capture names only',
                               'Only m/s/U flags; see docs/milestone-6.md for remaining scope']})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
