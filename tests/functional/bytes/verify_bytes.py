"""Differential checks for regex::bytes::Regex against BytesRegex."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT

cases = [
    ('(?-u).', 'ff'),
    ('(?-u).', 'e4b8ad'),
    ('.', 'e4b8ad'),
    ('.', 'ff'),
    ('(?-u)[^a]', 'ff'),
    ('(?-u)[^a]', 'e4b8ad'),
    ('[^a]', 'e4b8ad'),
    ('[^a]', 'ff'),
    (r'(?-u)\x80', '80'),
    (r'(?-u)\x80', 'c280'),
    (r'\x80', 'c280'),
    (r'\x80', '80'),
    ('(?-u)\\W', 'ff20'),
    ('a', '61ff62'),
    ('b', '61ff62'),
    ('(?-u)a+', '6161ff'),
    ('(?m)^b', '610a62'),
    ('(?-u)(?m)$', '61ff'),
    ('中', 'e4b8ad'),
    ('中', 'e4b8'),
    ('(?-u)[\\x80]', '80'),
    ('(?-u)[\\x80]', 'c280'),
    ('[\\x80]', 'c280'),
    ('(?-u).', ''),
    ('a*', '616161'),
    ('(?-u)\\d', '35ff'),
    (r'\b', '61ff62'),
    (r'(?-u)\b', '61ff62'),
    ('(?-u)(?s).', '0a'),
    ('.', '0a'),
]


def run(cmd):
    return subprocess.run(cmd, env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)


more = [
    ['bytes-captures', '(a)(b)?', '61'],
    ['bytes-captures', '(a)(b)?', '6162'],
    ['bytes-captures', '(?<n>a)', '61'],
    ['bytes-captures', '(?-u)(.)', 'ff'],
    ['bytes-captures', 'a+', '616161'],
    ['bytes-replace', 'a+', '616161', '[$0]'],
    ['bytes-replace-all', '(?-u).', 'ff61', 'X'],
    ['bytes-replace-all', '(a)', '6161', 'z$1'],
    ['bytes-split', 'a', '616261'],
    ['bytes-split', '(?-u),', '612c622c'],
    ['bytes-set-matches', 'ff', '(?-u).', 'a'],
    ['bytes-set-matches', '61', 'a', 'b'],
    ['bytes-set-matches', '62', '(?-u)[^a]', 'b'],
    ['bytes-set-matches', '', 'a'],
]


count = 0
for pattern, hay in cases:
    rust = run([str(RUST), 'bytes-find', pattern, hay])
    cj = run([str(CJ), 'bytes-find', pattern, hay])
    assert rust.returncode == 0 and cj.returncode == 0 and rust.stdout == cj.stdout, (
        pattern, hay, rust.returncode, cj.returncode, rust.stdout, cj.stdout, rust.stderr, cj.stderr)
    count += 1

for args in more:
    rust = run([str(RUST), *args])
    cj = run([str(CJ), *args])
    assert rust.returncode == 0 and cj.returncode == 0 and rust.stdout == cj.stdout, (
        args, rust.returncode, cj.returncode, rust.stdout, cj.stdout, rust.stderr, cj.stderr)
    count += 1

rejected = ['(?-u).', r'(?-u)\x80', '(?-u)[^a]', '(?-u)[\\x80]']
for pattern in rejected:
    rust = run([str(RUST), 'find', pattern, 'a'])
    cj = run([str(CJ), 'find', pattern, 'a'])
    assert rust.returncode != 0 and cj.returncode == 2 and not cj.stdout, (pattern, rust.returncode, cj.returncode, cj.stderr)
    count += 1

report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update({'bytes_differential_passed': count})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('bytes differential passed:', count, flush=True)
