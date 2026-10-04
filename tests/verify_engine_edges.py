"""Seeded differential regressions for syntax and new engine edge cases.

Compare the fixed original implementations directly, including rejection behavior.
"""
import json
import random
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT

count = 0

def check(args):
    global count
    outputs = []
    for binary in (RUST, CJ):
        proc = subprocess.run([str(binary), *args], capture_output=True, text=True, env=ENV, timeout=60)
        outputs.append((proc.returncode, proc.stdout, proc.stderr))
    if outputs[0] != outputs[1]:
        failure = dict(args=args, rust=outputs[0], cangjie=outputs[1])
        REPORT.with_name('engine-edges-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)
    count += 1

ps=[r'\b\b',r'\B\B',r'\b$',r'$\b',r'\b{start}\b',r'\b{end}',r'\b{start-half}',r'\b{end-half}',r'\Bfoo',r'foo\B','a|ba','a+?b','(a?)*','(a*)*','(?:|a)b','a{0}b','(?:a|ab)*b','[a&&b]','(?m:$)^','(?m:^)$','(?m:a$)b']
ps=[f'(?-u:{p})' if '\\b' in p or '\\B' in p else p for p in ps]
rng=random.Random(51005)
for _ in range(60):
 a=rng.choice(['a','b','[ab]','(?:a|ba)','a?','(?:|a)','a*?']);b=rng.choice(['a','b','a+','a+?','$','']);ps.append('(?:'+a+')'+rng.choice(['','*','+','?'])+b)
for p in ps:
 for t in rng.sample(['','a','ba','ab','aba','aaab','a\nb','éa','中ba','bbb',' a '],3):check(('dfa','dense',p,t))
for p in [r'[\x61-z]',r'[a-\x7A]',r'[\n-\r]',r'[\-a]',r'[.]','[-a]','((a))','(?i:(a))b','((?i)a)b','(?x:(?i)a) b',r'(?-u:[é])',r'(?-u:[\x{E9}])']:
 for mode in ['ast','ast-print','ast-translate']:
  check((mode,p,*(['true'] if mode=='ast-translate' else [])))
for p in ['*','a{3,2}',r'\q','(?ii:a)','(?<x>a)(?<x>b)','[z-a]','(?=a)','a{9999999999999999999999}','[',r'\xZZ',r'\p{Nope}*?*','(?-u:[é])*?*']:
 check(('ast',p))

for pattern in ['[]a]', '[^]a]', '(?mi:a)', '(?-mi:a)', '(?mi)a', '(?x)[ ^a]']:
    for mode in ['ast', 'ast-print', 'ast-translate']:
        check((mode, pattern, *(['true'] if mode == 'ast-translate' else [])))
for pattern, text in [('a|ba', 'ba'), ('a+?b', 'aab'), (r'(?-u:a\B)', 'ab'),
                      (r'(?-u:\b\bfoo)', ' foo'), ('^[a&&b]', 'a')]:
    check(('dfa', 'sparse', pattern, text))
for pattern in ['a(?i)b', '((?i)a)b', '(a(b))', '(?x:(?i)a) b', '[a-\\x7A]', 'a*?*']:
    check(('ast-translate', pattern, 'true'))
for pattern in ps[:21]:
    for text in ['aba', 'éa', 'a\nb']:
        check(('backtrack', '1048576', pattern, text))
for pattern in ['(?:ab|cd){2,4}', '(?:a?|b?)*', 'x[ab]{2,5}z', '(?:a{11}|b{11})',
                'a' * 101, '中' * 40, '(?:aa|ab|ac){5}', '(?i:foo)', '[a&&b]x']:
    for direction in ['prefix', 'suffix']:
        check(('literals', direction, pattern))
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report['engine_edge_differential_passed'] = count
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'Engine and syntax edge differential: {count} passed', flush=True)
