"""Unicode word/nonword boundary assertions and zero-width iteration."""
import json
import random
from regex_test_support import RUST,CJ,REPORT,compare,invoke
patterns=[r'\b',r'\B',r'\b\w+\b',r'\B\w+\B',r'\bcat\b',r'(\b)',r'(\B)',
          r'(\b)*',r'(\B)+',r'(\b)?',r'(\b){2,4}',r'(\B){0,3}?',r'\b|\B',
          r'(\b|a)*',r'(\B|.)+',r'\b(\w+)|\B(.)',r'(?m)^\b.*\b$',r'(?s)\B.\B',
          r'(?U)\b\w+\b',r'\A\B\z',r'\b\b',r'\b\B',r'\b{2}',r'\b.\b',
          r'\b{start}',r'\b{end}',r'\b{start-half}',r'\b{end-half}',r'\<',r'\>',r'(?-u:\b)']
texts=['','a','ab','!','!!',' cat cats cat ','中文🙂abc','e\u0301','\u0301',
       '\u200c\u200d','٣３_','\nabc\n','🙂🙂','\u00a0a\u00a0']
count=0
for p in patterns:
    for text in texts:
        compare(p,text,'captures');count+=1
rng=random.Random(20260929)
for _ in range(100):
    p=rng.choice(patterns)
    text=''.join(rng.choice('ab中٣_\u0301\u200c🙂! \n') for _ in range(rng.randrange(25)))
    compare(p,text);count+=1
golden=[(r'\b','中🙂a','0\t0\t\n3\t3\t\n7\t7\t\n8\t8\t\n'),
        (r'\B','🙂','0\t0\t\n4\t4\t\n'),(r'\B','','0\t0\t\n'),
        (r'\b','e\u0301','0\t0\t\n3\t3\t\n'),
        (r'\bcat\b','cat cats cat','0\t3\tcat\n9\t12\tcat\n')]
for p,text,expected in golden:
    r=invoke(CJ,'find',p,text)
    assert r.returncode==0 and r.stdout==expected.encode(),(p,r)
checks=0
for p in [r'\b',r'\B',r'\b(\w+)\b']:
    for mode,extra in [('first',()),('is-match',()),('split',()),('replace-all',('<$1>',))]:
        compare(p,'中文🙂abc !',mode,*extra);checks+=1
for p in [r'[\b]',r'[\B]']:
    assert invoke(RUST,'find',p,'').returncode!=0
    r=invoke(CJ,'find',p,'')
    assert r.returncode==2 and r.stderr and not r.stdout,(p,r)
unsupported=[]
for p in unsupported:
    assert invoke(RUST,'find',p,'a').returncode==0,p
    r=invoke(CJ,'find',p,'a')
    assert r.returncode==2 and r.stderr and not r.stdout,(p,r)
report=json.loads(REPORT.read_text())
report.update({'word_boundary_differential_passed':count,'word_boundary_golden_passed':len(golden),
               'word_boundary_api_checks_passed':checks,'word_boundary_invalid_rejected':2,
               'word_boundary_unsupported_rejected':len(unsupported),
               'matching_scope':'Unicode-scalar NFA with d/s/w, b/B and m/s/U; no property syntax/case folding/bytes/DFA',
               'word_boundary_scope':'Unicode 16 b/B at scalar boundaries'})
REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
