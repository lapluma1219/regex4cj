"""Unicode binary properties, alias precedence and category distinctions."""
import json
import random
from regex_test_support import ROOT, RUST, CJ, REPORT, compare, invoke

snapshot = json.loads((ROOT / 'data/unicode/binary_properties.json').read_text())
count = 0
mixed = 'Aa中é\u0345\u2160_09٣²🙂!$ \n\x7f\u200c\u0085\u00a0\U0010ffff'
for name, ranges in snapshot['classes'].items():
    points = set()
    for a, b in ranges:
        points.update([a - 1, a, b, b + 1])
    chars = [chr(c) for c in sorted(points) if 0 < c <= 0x10ffff and not 0xd800 <= c <= 0xdfff]
    for i in range(0, len(chars), 500):
        for prefix in ['p', 'P']:
            compare('\\' + prefix + '{' + name + '}', ''.join(chars[i:i + 500]), 'captures')
            count += 1
for alias, target in snapshot['aliases'].items():
    sample = ''.join(chr(max(1, a)) for a, b in snapshot['classes'][target] if b > 0) + mixed
    compare('\\p{' + alias + '}', sample, 'captures')
    count += 1
patterns = [r'\p{isAlphabetic}+', r'\p{ U_p-p e r }', r'\p{White中Space}',
            r'[\p{Alphabetic}--\pL]+', r'[\p{Uppercase}--\p{Lu}]',
            r'[\p{White_Space}~~\s]', r'[\p{XID_Continue}&&\p{Greek}]',
            r'(\p{Emoji}+)|(\p{Math}+)', r'\P{space}*?', r'\p{cf}', r'\p{sc}', r'\p{lc}']
for pattern in patterns:
    for text in ['', mixed]:
        compare(pattern, text, 'captures')
        count += 1
rng = random.Random(20261002)
for _ in range(40):
    a, b = rng.choice(list(snapshot['classes'])), rng.choice(list(snapshot['classes']))
    pattern = '[\\p{' + a + '}' + rng.choice(['&&', '--', '~~']) + '\\P{' + b + '}]'
    compare(pattern, mixed, 'captures')
    count += 1

golden = [(r'\p{Alphabetic}', '\u0345', '0\t2\t\u0345\n'),
          (r'\pL', '\u0345', ''),
          (r'\p{Uppercase}', '\u2160', '0\t3\t\u2160\n'),
          (r'\p{Lu}', '\u2160', ''),
          (r'\p{Emoji}+', 'a1🙂b', '1\t6\t1🙂\n'),
          (r'\p{White_Space}+', 'a\u0085\u00a0b', '1\t5\t\u0085\u00a0\n')]
for pattern, text, expected in golden:
    for binary in [RUST, CJ]:
        result = invoke(binary, 'find', pattern, text)
        assert result.returncode == 0 and result.stdout == expected.encode(), (pattern, result)
invalid = [r'\p{Alphabetic=Yes}', r'\p{Alphabetic=False}', r'\p{Uppercase:True}',
           r'\p{Emoji!=No}', r'\p{gc=Alphabetic}', r'\p{InCB}', r'\p{Indic_Conjunct_Break}',
           r'\p{NoSuchProperty}']
for pattern in invalid:
    assert invoke(RUST, 'find', pattern, '').returncode != 0, pattern
    result = invoke(CJ, 'find', pattern, '')
    assert result.returncode == 2 and result.stderr and not result.stdout, (pattern, result)
for mode, extra in [('first', ()), ('is-match', ()), ('split', ()), ('replace-all', ('<$1>',))]:
    compare(r'(\p{Alphabetic}+)', '中\u0345🙂abc', mode, *extra)
report = json.loads(REPORT.read_text())
report.update(binary_property_differential_passed=count, binary_property_golden_passed=len(golden),
              binary_property_invalid_rejected=len(invalid), binary_property_api_checks_passed=4,)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('Binary property differential passed:', count, flush=True)
