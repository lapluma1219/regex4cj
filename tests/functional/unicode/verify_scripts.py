"""Compare Script and Script_Extensions against the pinned Rust implementation."""
import json
import random
from regex_test_support import ROOT, RUST, CJ, REPORT, compare, invoke

snapshot = json.loads((ROOT / 'data/unicode/scripts.json').read_text())
count = 0
mixed = 'Aé中αЖあアー\u0301٣🙂\u0378\ud7ff\ue000\U0010ffff'
for kind, short in [('Script', 'sc'), ('Script_Extensions', 'scx')]:
    for name, ranges in snapshot['tables'][kind].items():
        points = set()
        for a, b in ranges:
            points.update([a - 1, a, b, b + 1])
        chars = [chr(c) for c in sorted(points) if 0 < c <= 0x10ffff and not 0xd800 <= c <= 0xdfff]
        for i in range(0, len(chars), 500):
            for prefix in ['p', 'P']:
                compare('\\' + prefix + '{' + short + '=' + name + '}', ''.join(chars[i:i + 500]), 'captures')
                count += 1
        compare('\\P{' + short + '!=' + name + '}', mixed, 'captures')
        count += 1
    for alias, target in snapshot['aliases'][kind].items():
        if target not in snapshot['tables'][kind]:
            for pattern in ['\\p{' + short + '=' + alias + '}', '\\p{' + alias + '}']:
                assert invoke(RUST, 'find', pattern, '').returncode != 0, pattern
                assert invoke(CJ, 'find', pattern, '').returncode == 2, pattern
            continue
        sample = ''.join(chr(max(1, a)) for a, b in snapshot['tables'][kind][target] if b > 0) + mixed
        patterns = ['\\p{' + short + ':' + alias + '}']
        if kind == 'Script':
            patterns.append('\\p{' + alias + '}')
        for pattern in patterns:
            compare(pattern, sample, 'captures')
            count += 1
    print(kind + ' intervals and aliases passed', flush=True)

patterns = [r'\p{isGreek}+', r'\p{ SCRIPT = g_r-e e k }+', r'\p{scx=IsHira}',
            r'\p{Script_Extensions:Katakana}', r'\p{sc=Latn}', r'\p{scx!=Hira}',
            r'[\p{scx=Hira}--\p{sc=Hira}]', r'[\p{scx=Kana}&&\p{scx=Hira}]',
            r'[\p{Greek}&&\pL]+', r'\p{sc}', r'\p{cf}', r'\p{lc}',
            r'\p{scx=Hira}*?', r'(\p{Han}+)|(\p{Greek}+)']
for pattern in patterns:
    for text in ['', mixed, 'かなーカナαβ中文$']:
        compare(pattern, text, 'captures')
        count += 1
rng = random.Random(20261001)
names = list(snapshot['tables']['Script'])
for _ in range(80):
    a, b = rng.choice(names), rng.choice(names)
    pattern = '[\\p{scx=' + a + '}' + rng.choice(['&&', '--', '~~']) + '\\p{sc=' + b + '}]'
    sample = mixed + ''.join(chr(c) for c in (rng.randrange(1, 0x110000) for _ in range(30)) if not 0xd800 <= c <= 0xdfff)
    compare(pattern, sample, 'captures')
    count += 1

golden = [(r'\p{Han}+', 'A中文α', '1\t7\t中文\n'),
          (r'\p{sc=Hira}', 'ー', ''), (r'\p{scx=Hira}', 'ー', '0\t3\tー\n'),
          (r'\p{sc=Common}', 'ー', '0\t3\tー\n'),
          (r'\p{scx=Common}', 'ー', ''),
          (r'\p{scx=Kana}', 'ー', '0\t3\tー\n')]
for pattern, text, expected in golden:
    for binary in [RUST, CJ]:
        result = invoke(binary, 'find', pattern, text)
        assert result.returncode == 0 and result.stdout == expected.encode(), (pattern, result)
invalid = [r'\p{sc=}', r'\p{scx=NoSuch}', r'\p{gc=Greek}', r'\p{sc=L}',
           r'\p{sc=Unknown}', r'\p{scx=Hrkt}', r'\p{Script}', r'\p{scx}', r'\p{scx==Hira}']
for pattern in invalid:
    assert invoke(RUST, 'find', pattern, '').returncode != 0, pattern
    assert invoke(CJ, 'find', pattern, '').returncode == 2, pattern
for mode, extra in [('first', ()), ('is-match', ()), ('split', ()), ('replace-all', ('<$1>',))]:
    compare(r'(\p{scx=Hira}+)', 'aかなーα', mode, *extra)
report = json.loads(REPORT.read_text())
report.update(script_differential_passed=count, script_golden_passed=len(golden),
              script_invalid_rejected=len(invalid), script_api_checks_passed=4,)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('Script differential passed:', count, flush=True)
