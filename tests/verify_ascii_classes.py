"""POSIX ASCII class tables, Unicode complement and parser fallback."""
import json
import random
from regex_test_support import RUST, CJ, REPORT, compare, invoke
names = ['alnum','alpha','ascii','blank','cntrl','digit','graph','lower','print','punct','space','upper','word','xdigit']
texts = ['', ''.join(chr(i) for i in range(1,128)), 'AZaz09_中🙂é１２٣\u00a0', 'a-b:\n\t 123']
count = 0
for name in names:
    positive = '[[:'+name+':]]'
    for p in [positive, '[[:^'+name+':]]', '[^[:'+name+':]]',
              '([[:'+name+':]]+)', '[[:'+name+':]&&[a-z0-9]]', '[[:'+name+':]~~[:digit:]]']:
        for text in texts:
            compare(p,text,'captures'); count += 1
    print('POSIX class cases passed:', count, flush=True)
fallback = ['[[:digitt:]]','[[:DIGIT:]]','[[:digit]]','[[:^digitt:]]', '[[:]]',
            '[:digit:]', '[[:alpha:]_]', '[a[:digit:]z]',
            '[[:digit:]-a]', '[-[:digit:]]', '[[:space:]--[:blank:]]',
            '[[:^ascii:]&&[^中]]','[[[:digit:]]]', '[[:digit:]&&[:alpha:]]', '[[:digit:]--[:^digit:]]']
for p in fallback:
    for text in texts:
        compare(p,text,'captures'); count += 1
rng = random.Random(20260927)
for _ in range(100):
    a,b = rng.choice(names),rng.choice(names)
    p = '[[:'+a+':]'+rng.choice(['','&&','--','~~'])+'[:'+rng.choice(['','^'])+b+':]]'+rng.choice(['+','{0,2}','*?'])
    text = ''.join(rng.choice('Aa09_中é🙂\n\t! ') for _ in range(rng.randrange(20)))
    compare(p,text,'captures'); count += 1
golden = [('[[:digit:]]+', 'a12٣４b', '1\t3\t12\n'),
          ('[[:^ascii:]]+', 'a中🙂b', '1\t8\t中🙂\n'),
          ('[[:blank:]]', '\t\n ', '0\t1\t\t\n2\t3\t \n'),
          ('[[:xdigit:]]+', 'G0aFz', '1\t4\t0aF\n'),
          ('[[:digitt:]]+', ':digitt中', '0\t7\t:digitt\n')]
for p,text,expected in golden:
    r=invoke(CJ,'find',p,text)
    assert r.returncode==0 and r.stdout==expected.encode(),(p,r)
invalid=['[[:digit:]', '[[[:digit:]]','[a-[:digit:]]','[[:digit:]&&]x[']
for p in invalid:
    assert invoke(RUST,'find',p,'').returncode!=0,p
    r=invoke(CJ,'find',p,'')
    assert r.returncode==2 and r.stderr and not r.stdout,(p,r)
for mode,extra in [('first',()),('is-match',()),('split',()),('replace-all',('<$1>',))]:
    compare('([[:digit:]]+)', 'a12b34', mode,*extra)
report=json.loads(REPORT.read_text())
report.update({'ascii_classes_differential_passed':count,'ascii_classes_golden_passed':len(golden),
               'ascii_classes_invalid_rejected':len(invalid),'ascii_classes_api_checks_passed':4,
               'ascii_classes_scope':'14 POSIX ASCII classes, Unicode complement, nested fallback; see docs/milestone-8.md'})
REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
