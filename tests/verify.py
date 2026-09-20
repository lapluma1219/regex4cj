"""Cross-language acceptance tests. No Python regex is used as the oracle."""
import os
import json
import random
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUST = Path(os.environ['CARGO_TARGET_DIR']) / 'debug/regex-oracle'
CJ = ROOT / 'port/target/release/bin/main'

def run(binary, *args):
    env = os.environ.copy()
    if env.get('REGEX4CJ_DYLD_LIBRARY_PATH'):
        env['DYLD_LIBRARY_PATH'] = env['REGEX4CJ_DYLD_LIBRARY_PATH']
    return subprocess.check_output([str(binary), *args], timeout=10, env=env)

fixed = ['', 'a+b.txt', '中文(测试)', '🙂.*', '\\.+*?()|[]{}^$#&-~', '%!/@', '\n\t\r', 'e\u0301', 'a=b']
cases = fixed + [chr(i) for i in range(1, 128)]
rng = random.Random(20260920)
alphabet = 'abZ019\\.+*?()|[]{}^$#&-~%! /@\n\t中é🙂'
cases += [''.join(rng.choice(alphabet) for _ in range(rng.randrange(80))) for _ in range(200)]
for text in cases:
    rust, cj = run(RUST, 'escape', text), run(CJ, 'escape', text)
    assert rust == cj, (repr(text), rust, cj)
assert run(CJ, 'escape', 'a+b.txt') == b'a\\+b\\.txt\n'
# Additional property: the escaped expression matches the entire original text literally.
for text in ['a+b.txt', '中文(测试)', '🙂.*', '%!/@']:
    escaped = run(CJ, 'escape', text).decode()[:-1]
    expected = f'0\t{len(text.encode())}\t{text}\n'.encode()
    assert run(RUST, 'find', r'\A(?:' + escaped + r')\z', text) == expected

# Future matching-engine acceptance fixtures. These run ONLY on Rust for now.
fixtures = [
    ('[A-Z]{2}-[0-9]{3}', 'order=AB-123; order=CD-456', '6\t12\tAB-123\n20\t26\tCD-456\n'),
    ('中', 'a中b', '1\t4\t中\n'),
    ('a|ab', 'ab', '0\t1\ta\n'),
    ('a+?', 'aaa', '0\t1\ta\n1\t2\ta\n2\t3\ta\n'),
    ('', '中', '0\t0\t\n3\t3\t\n'),
    ('[0-9]+', 'abc', ''),
]
for pattern, text, expected in fixtures:
    assert run(RUST, 'find', pattern, text) == expected.encode(), (pattern, text)
report = {'escape_differential_passed': len(cases), 'literal_roundtrip_passed': 4,
          'rust_only_matching_fixtures_passed': len(fixtures),
          'cangjie_matching_engine_implemented': False,
          'limitations': ['CLI cannot transport NUL; arbitrary bytes API is not implemented',
                         'Passing escape tests does not establish matching-engine compatibility']}
(Path(os.environ['REGEX4CJ_LOCAL']) / 'work/verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(report, ensure_ascii=False, indent=2))
