"""size_limit pass/fail and dfa_size_limit match text against the pinned regex."""
import subprocess
from regex_test_support import RUST, CJ, ENV


def run(binary, args):
    return subprocess.run([str(binary), *args], env=ENV, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=30)


def check(args):
    rust = run(RUST, args)
    cj = run(CJ, args)
    assert rust.returncode == cj.returncode and rust.stdout == cj.stdout and rust.stderr == cj.stderr, (
        args, rust.returncode, cj.returncode, rust.stdout, cj.stdout, rust.stderr, cj.stderr)


count = 0
limits = [
    ('45000', r'\w'), ('50043', r'\w'), ('50044', r'\w'),
    ('1143', '.'), ('1144', '.'),
    ('279', 'a+'), ('280', 'a+'),
    ('279', '[a-z]'), ('280', '[a-z]'),
    ('303', r'(?-u)\w'), ('304', r'(?-u)\w'),
    ('239', ''), ('240', ''),
    ('207', '^a'), ('208', '^a'),
    ('5323', r'\d'), ('5324', r'\d'),
    ('0', 'a'), ('0', 'ab'), ('0', 'a|b'), ('0', '[a-j]'), ('0', 'a{10}'),
    ('0', '[a-k]'), ('0', 'a+'), ('0', 'a{11}'), ('0', '(a)'), ('0', 'a?'), ('0', ''),
]
for limit, pattern in limits:
    check(['limit-find', limit, pattern, 'a'])
    count += 1
for limit in ['0', '1', '64', '127', '128', '2097152']:
    for pattern, text in [('a', 'xa'), (r'\bcat\b', 'cat cats'), ('.', 'a中🙂b'), ('a+', 'aaa'), (r'(?m)^a', 'b\na')]:
        check(['dfa-find', limit, pattern, text])
        count += 1
check(['set-limit', '176', 'a', 'a'])
check(['set-limit', '0', 'a', 'a'])
count += 2
print('limit checks passed:', count)
