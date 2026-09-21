"""Unicode general-category aliases, scalar intervals and property grammar."""
import json
import random
from regex_test_support import ROOT,RUST,CJ,REPORT,compare,invoke
snapshot=json.loads((ROOT/'data/unicode/general_categories.json').read_text())
count=0
texts=['','Aa中é\u0301_09٣²🙂!$ \n\x7f','\ud7ff\ue000\U0010ffff','\u0378\U0001ccf0']
for name,ranges in snapshot['classes'].items():
    for text in texts:
        for prefix in ['p','P']:
            compare('\\'+prefix+'{'+name+'}',text,'captures');count+=1
    points=set()
    for a,b in ranges: points.update([a-1,a,b,b+1])
    chars=[chr(c) for c in sorted(points) if 0<c<=0x10ffff and not 0xd800<=c<=0xdfff]
    for i in range(0,len(chars),500):
        compare('\\p{gc='+name+'}', ''.join(chars[i:i+500]),'captures');count+=1
    print('general category passed:',name,flush=True)
for alias,target in snapshot['aliases'].items():
    if target=='Surrogate':continue
    for p in ['\\p{'+alias+'}', '\\p{gc:'+alias+'}']:
        compare(p,texts[1],'captures');count+=1
patterns=[r'\pL+',r'\PN',r'\p{gc!=Lu}',r'\P{gc!=Lu}',r'\p{General_Category=Letter}',
          r'\p{isLu}',r'\p{ l U }',r'\p{Uppercase-Letter}',r'\p{L中}',r'\p{gc=isN}',
          r'[\pL&&[^\p{Lu}]]+',r'[\pN--\d]',r'(\p{M})?',r'\p{Any}',r'\P{Any}',
          r'\p{ASCII}',r'\p{Assigned}',r'\P{Assigned}',r'\p{gc=Any}',r'\p{gc=ASCII}',
          r'\p{gc=Assigned}',r'\p{sc}',r'\p{cf}',r'\p{lc}',r'[\pL-]']
for p in patterns:
    for text in texts:
        compare(p,text,'captures');count+=1
rng=random.Random(20260930)
for _ in range(80):
    a,b=rng.choice(list(snapshot['classes'])),rng.choice(list(snapshot['classes']))
    p='[\\p{'+a+'}'+rng.choice(['&&','--','~~'])+'\\P{'+b+'}]'
    text=''.join(chr(c) for c in [rng.randrange(1,0x110000) for _ in range(20)] if not 0xd800<=c<=0xdfff)
    compare(p,text,'captures');count+=1
golden=[(r'\pL+','A中3','0\t4\tA中\n'),(r'\p{N}+','a²٣','1\t5\t²٣\n'),
        (r'\p{gc!=L}+','ab12','2\t4\t12\n'),(r'\P{gc!=L}+','ab12','0\t2\tab\n')]
for p,text,out in golden:
    r=invoke(CJ,'find',p,text)
    assert r.returncode==0 and r.stdout==out.encode(),(p,r)
invalid=[r'\p',r'\p{}',r'\p{L',r'\p{gc=}',r'\p{gc=NoSuch}',r'\p{Surrogate}',r'\p{Cs}',
         r'\p{isc}',r'[a-\pL]',r'[\pL-a]',r'\p{gc==Lu}']
for p in invalid:
    assert invoke(RUST,'find',p,'').returncode!=0,p
    r=invoke(CJ,'find',p,'')
    assert r.returncode==2 and r.stderr and not r.stdout,(p,r)
unsupported=[r'\p{age=16.0}']
for p in unsupported:
    assert invoke(RUST,'find',p,'').returncode==0,p
    r=invoke(CJ,'find',p,'')
    assert r.returncode==2 and r.stderr and not r.stdout,(p,r)
for mode,extra in [('first',()),('is-match',()),('split',()),('replace-all',('<$1>',))]:
    compare(r'(\pL+)', '中🙂abc',mode,*extra)
report=json.loads(REPORT.read_text())
report.update({'general_category_differential_passed':count,'general_category_golden_passed':len(golden),
               'general_category_invalid_rejected':len(invalid),'general_category_unsupported_rejected':len(unsupported),
               'general_category_api_checks_passed':4,
               'matching_scope':'Unicode-scalar NFA with general categories, d/s/w, b/B and m/s/U; no scripts/binary properties/case folding/bytes/DFA',
               'general_category_scope':'37 categories plus Any/ASCII/Assigned; see docs/milestone-11.md'})
REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
