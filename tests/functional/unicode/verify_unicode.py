"""Unicode 16 shorthand classes: range boundaries, random scalars and set semantics."""
import json
import random
from regex_test_support import ROOT, RUST, CJ, REPORT, compare, invoke
snapshot=json.loads((ROOT/'data/unicode/perl_classes.json').read_text())
count=0
# Every recorded interval start/end and its neighbors, plus random scalars.
# This checks the observable class against Rust, independent of generated Cj code.
rng=random.Random(20260928)
for kind in ['d','s','w']:
    points={1,0x7f,0x80,0xd7ff,0xe000,0x10ffff}
    for a,b in snapshot['classes'][kind]:
        points.update([a-1,a,a+1,b-1,b,b+1])
    points.update(rng.randrange(1,0x110000) for _ in range(2000))
    scalars=[n for n in sorted(points) if 0<n<=0x10ffff and not 0xd800<=n<=0xdfff]
    for i in range(0,len(scalars),500):
        text=''.join(chr(n) for n in scalars[i:i+500])
        for p in ['\\'+kind,'\\'+kind.upper()]:
            compare(p,text,'captures');count+=1
    print('Unicode boundary class passed:',kind,flush=True)
patterns=[r'\d+',r'\D+',r'\w+',r'\W+',r'\s+',r'\S+',r'[\dA]+',r'[^\w]',
          r'[\w&&[^\d]]+',r'[\s--[\t\n]]+',r'[\D~~\W]',r'[\w--[:ascii:]]+',
          r'[\d-]',r'[\d--a]',r'[a\W]',r'(?U)(\w+)',r'(\d+)|(\s+)',r'[\w&&\W]',
          r'[\d\D]',r'[\s&&[:blank:]]']
texts=['','abc_09','中文é３٣²','e\u0301\u200c\u200d','\t\n\r\x0b\x0c \u0085\u00a0\u2028\u2029',
       '🙂!\u200b\ufeff','a\U0001ccf0\U0001ccf9b','\ud7ff\ue000\U0010ffff']
for p in patterns:
    for text in texts:
        compare(p,text,'captures');count+=1
for _ in range(80):
    a,b=rng.choice('dDsSwW'),rng.choice('dDsSwW')
    p='[\\'+a+rng.choice(['','&&','--','~~'])+'\\'+b+']'+rng.choice(['+','*?','{0,3}'])
    text=''.join(rng.choice('a09中é٣３²\u0301\u200c\u00a0🙂\n ') for _ in range(20))
    compare(p,text,'captures');count+=1
golden=[(r'\d+','A３٣²','1\t6\t３٣\n'),
        (r'\w+','中e\u0301\u200c🙂','0\t9\t中e\u0301\u200c\n'),
        (r'\s','a\u00a0b\u200b','1\t3\t\u00a0\n'),
        (r'\d','\U0001ccf0','0\t4\t\U0001ccf0\n')]
for p,text,expected in golden:
    r=invoke(CJ,'find',p,text)
    assert r.returncode==0 and r.stdout==expected.encode(),(p,r)
invalid=[r'[\d-a]',r'[a-\d]',r'[\w-\s]',r'[\S-中]']
for p in invalid:
    assert invoke(RUST,'find',p,'').returncode!=0,p
    r=invoke(CJ,'find',p,'')
    assert r.returncode==2 and r.stderr and not r.stdout,(p,r)
for mode,extra in [('first',()),('is-match',()),('split',()),('replace-all',('<$1>',))]:
    compare(r'(\d+)', 'a３٣b12',mode,*extra)
report=json.loads(REPORT.read_text())
report.update({'unicode_shorthand_differential_passed':count,'unicode_shorthand_golden_passed':len(golden),
               'unicode_shorthand_invalid_rejected':len(invalid),'unicode_shorthand_api_checks_passed':4,
               'unicode_version':'16.0.0', 'unicode_range_counts':{k:len(v) for k,v in snapshot['classes'].items()},
               'unicode_scope':'Pinned Unicode 16.0.0 shorthand tables'})
REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
