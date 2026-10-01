"""Differential checks for x/R/u, boundaries, Age, offsets and shortest match."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT, compare, invoke

kelvin = '\u212a'
omega = '\u03a9'
cases = [
    ('(?x)a b', 'ab'),
    ('(?x)a #c\nb', 'ab'),
    ('(?x)[a b]', 'a b'),
    ('(?x)a{1, 2}', 'aa'),
    ('a{ 2 }', 'aa'),
    ('a**', 'aaa'),
    ('a{2}*', 'aaa'),
    ('(?R).', 'a\r\nb'),
    ('(?mR)^b', 'a\r\nb'),
    ('(?mR)$', 'a\r\n'),
    ('(?-u)\\w', 'a'),
    ('(?-u)\\w', omega),
    ('(?-u)\\d', '5'),
    ('(?-u)\\d', '٥'),
    ('(?-u)(?i)k', 'K'),
    ('(?-u)(?i)k', kelvin),
    ('(?-u)é', 'é'),
    ('(?-u)(?i)é', 'É'),
    (r'\b{start}a', 'ba a'),
    (r'\<a', 'ba a'),
    (r'\b{end}a', 'ab a'),
    (r'\b{start-half}a', 'a'),
    ('(?<名>a)', 'a'),
    (r'(?u)\w', omega),
    (r'\p{age=1.1}', 'A'),
    (r'\p{age=16.0}', 'A'),
    (r'\p{gcb=cr}', '\r'),
    (r'\p{wb=aletter}', 'a'),
    (r'\p{sb=cr}', '\r'),
    (r'[\p{age=16.0}]', 'A'),
]
count = 0
for pattern, text in cases:
    compare(pattern, text)
    compare(pattern, text, 'captures')
    count += 2
for pattern, text, start in [(r'\ba', 'ba', '1'), (r'\bchew\b', 'eschew', '2'), ('a+', 'aaaaa', '2')]:
    compare(pattern, text, 'find-at', start)
    compare(pattern, text, 'is-match-at', start)
    compare(pattern, text, 'shortest-at', start)
    count += 3
for pattern, text in [('a+', 'aaaaa'), ('a*', 'aaa'), ('ab', 'ab')]:
    compare(pattern, text, 'shortest')
    count += 1
for pattern in ['a', '(a)|(b)', '(a)(b)|(c)(d)', '(a)|b', 'a|(b)', '(b)*', '(b)+']:
    rust = subprocess.run([str(RUST), 'static-len', pattern], env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    cj = subprocess.run([str(CJ), 'static-len', pattern], env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    assert rust.returncode == 0 and cj.returncode == 0 and rust.stdout == cj.stdout, (pattern, rust.stdout, cj.stdout, cj.stderr)
    count += 1
for args in [
    ['octal-find', r'\101', 'A'],
    ['term-find', '13', '(?m)^b', 'a\rb'],
    ['term-find', '228', '(?m)a$', 'a中'],
    ['nest-find', '0', 'a', 'a'],
    ['nest-find', '1', 'ab', 'ab'],
    ['set-is-match-at', 'ba', '1', r'\ba'],
    ['set-matches-at', 'ba', '1', 'a', r'\ba'],
]:
    rust = subprocess.run([str(RUST), *args], env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    cj = subprocess.run([str(CJ), *args], env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    assert rust.returncode == 0 and cj.returncode == 0 and rust.stdout == cj.stdout, (args, rust.stdout, cj.stdout, rust.stderr, cj.stderr)
    count += 1
for args in [['nest-find', '0', 'ab', 'ab'], ['term-find', '228', '.', 'a']]:
    rust = subprocess.run([str(RUST), *args], env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    cj = subprocess.run([str(CJ), *args], env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    assert rust.returncode != 0 and cj.returncode == 2 and not cj.stdout, (args, rust.returncode, cj.returncode, cj.stderr)
    count += 1
invalid = ['(?-u).', '(?-u)\\W', '(?-u)[^a]', '(?-u)[é]', r'(?-u)\p{L}', r'\p{age=na}',
           r'\B{start}', r'\b{Start}', '(?=a)']
for pattern in invalid:
    assert invoke(RUST, 'find', pattern, 'a').returncode != 0, pattern
    result = invoke(CJ, 'find', pattern, 'a')
    assert result.returncode == 2 and result.stderr and not result.stdout, (pattern, result)
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update({
    'syntax_differential_passed': count,
    'syntax_invalid_rejected': len(invalid),
    'matching_scope': 'Unicode-scalar NFA with x/R/u, Age, break properties, offset search and shortest match; no bytes or DFA',
})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('syntax differential passed:', count, flush=True)
