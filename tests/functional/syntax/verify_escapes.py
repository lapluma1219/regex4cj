"""Unicode scalar escape parsing, class endpoints and malformed input."""
import json
import random
from regex_test_support import CJ, RUST, REPORT, compare, invoke
patterns = [r'\x41', r'\u0041', r'\U00000041', r'\x{41}', r'\u{41}', r'\U{41}',
            r'\x{000000000000000000041}', r'\x7f', r'\x80', r'\xFF', r'\u4e2d',
            r'\U0001F642', r'\x{10ffff}', r'\uD7FF', r'\uE000', r'\a\f\v',
            r'[\x41-\x5A]+', r'[^\u4e2d]', r'[\u{1f642}-\U0001F643]',
            r'[\x00-\xFF&&[^\n]]+', r'[\a\f\v]', r'\x{2E}+', r'\x41B',
            r'(?s)(\x0a.)', r'(?m)^\x41$', r'(\u0041|\x42){1,2}', r'\x{0}']
texts = ['', 'AABZ', 'A\nB', 'A中🙂🙃', '\x07\x0c\x0b', '\x7f\x80ÿ', '\ud7ff\ue000\U0010ffff', '..B']
count = 0
for p in patterns:
    for text in texts:
        compare(p, text, 'captures')
        count += 1
rng = random.Random(20260926)
for _ in range(150):
    code = rng.choice([1,7,11,12,65,127,128,255,0x7ff,0x800,0xd7ff,0xe000,0x1f642,0x10ffff])
    c = chr(code)
    forms = ['\\x{%x}'%code, '\\u{%X}'%code, '\\U%08X'%code]
    if code <= 0xffff: forms.append('\\u%04x'%code)
    if code <= 255: forms.append('\\x%02x'%code)
    escaped = rng.choice(forms)
    p = rng.choice([escaped+'+', '['+escaped+']', '('+escaped+')?', '[^'+escaped+']'])
    compare(p, 'a'+c+c+'中', 'captures')
    count += 1
invalid = [r'\x', r'\x4', r'\xGG', r'\u123', r'\U0000000', r'\x{}',
           r'\u{}', r'\U{}', r'\x{41', r'\x{ 41}', r'\x{41 }', r'\x{+41}',
           r'\x{110000}', r'\uD800', r'\uDFFF', r'\UFFFFFFFF', r'\x{FFFFFFFFFFFFFFFF}',
           r'\x{d800}', r'[\x5A-\x41]', r'[\uD800]', r'\u１２３４', r'\x{é}']
for p in invalid:
    assert invoke(RUST, 'find', p, '').returncode != 0, p
    r = invoke(CJ, 'find', p, '')
    assert r.returncode == 2 and r.stderr and not r.stdout, (p,r)
golden = [(r'\u4e2d\U0001F642', 'a中🙂b', '1\t8\t中🙂\n'),
          (r'\xFF', 'ÿ', '0\t2\tÿ\n'),
          (r'\x{2e}', '.', '0\t1\t.\n')]
for p,text,expected in golden:
    r = invoke(CJ,'find',p,text)
    assert r.returncode == 0 and r.stdout == expected.encode(), (p,r)
for mode,extra in [('first',()),('is-match',()),('split',()),('replace-all',('<$1>',))]:
    compare(r'(\u4e2d)', 'a中b中', mode, *extra)
report = json.loads(REPORT.read_text())
report.update({'scalar_escape_differential_passed': count, 'scalar_escape_invalid_rejected': len(invalid),
               'scalar_escape_golden_passed': len(golden), 'scalar_escape_api_checks_passed': 4,
               'scalar_escape_scope': 'x/u/U fixed and braced scalar escapes plus a/f/v'})
REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2),flush=True)
