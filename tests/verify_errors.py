"""Syntax and RegexSet error text must match the pinned regex Display."""
import subprocess
from regex_test_support import RUST, CJ, ENV

patterns = [
    '(', ')', '*', r'\p{', r'\x{', '[z-a]', r'[\q]', r'\p{Foo}', r'\p{scx=Nope}',
    r'\p{sc=Nope}', r'\p{gc=Nope}', r'\p{foo=bar}', '(?q)', '(?i-i)', '(?i-)',
    '(?--i)', '(?', r'\1', '(?=a)', '(?!a)', '(?<=a)', '(?<!a)', 'a{', 'a{2',
    'a{2,', 'a{x}', 'a{,}', 'a{2,x}', 'a{9999999999}', 'a{2,1}', '(?-u).',
    r'\x{}', r'\x{110000}', r'\x{D800}', r'\x{G}', r'\q', '(?<>a)', '(?<1>a)',
    '(?<a>a)(?<a>b)', r'\b{nope}', r'\b{', '(?)', '[]', '[',
    '[' * 251 + 'a' + ']' * 251, '(?i',
]


def run(binary, args):
    return subprocess.run([str(binary), *args], env=ENV, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=15)


count = 0
for pattern in patterns:
    rust = run(RUST, ['find', pattern, 'a'])
    cj = run(CJ, ['find', pattern, 'a'])
    assert rust.returncode != 0 and cj.returncode == 2 and not cj.stdout and rust.stderr == cj.stderr, (
        pattern, rust.stderr, cj.stderr)
    count += 1
for args in [
    ['set-matches', 'a', '('],
    ['set-matches', 'ok', '(?=a)'],
    ['set-limit', '175', 'a', 'a'],
]:
    rust = run(RUST, args)
    cj = run(CJ, args)
    assert rust.returncode != 0 and cj.returncode == 2 and not cj.stdout and rust.stderr == cj.stderr, (
        args, rust.stderr, cj.stderr)
    count += 1
print('error display checks passed:', count)
