"""Concrete syntax: spans and node shape versus regex-syntax, then HIR lowering.

The AST keeps grouping and bracket form. Lowering must agree with Hir.parse.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT


def run(binary, *args):
    return subprocess.run([str(binary), *args], env=ENV, capture_output=True, text=True, timeout=30)


def compare(*args):
    r, c = run(RUST, *args), run(CJ, *args)
    if r.returncode or c.returncode or r.stdout != c.stdout:
        failure = dict(args=args, rust=r.stdout, cangjie=c.stdout,
                       rust_error=r.stderr, cangjie_error=c.stderr,
                       rust_code=r.returncode, cangjie_code=c.returncode)
        REPORT.with_name('ast-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)


review_patterns = [r'\x{4E2D}', r'\u{1}', r'\U{1F642}', r'\x{0}', r'\U0001F642', r'(?-u:é)', r'(?i-u:é)', r'(?-u:中)', r'(?i-u:🙂)',
                   r'(?-u:\x{E9})', r'(?-u:\u00E9)',
                   r'\b{start}', r'\b{end}', r'\b{start-half}', r'\b{end-half}',
                   r'\<', r'\>', r'(?-u:\b{start})', r'\b{2}']
for pattern in review_patterns:
    compare('ast', pattern)
    compare('ast-print', pattern)
    r, c = run(RUST, 'hir', pattern, 'true'), run(CJ, 'ast-hir', pattern)
    assert r.returncode == c.returncode == 0 and r.stdout == c.stdout, (pattern, r, c)

patterns = [
    '', '(?<id>[0-9]{6})', 'a|b', '(?:a)', 'a*', 'a+', 'a?', 'a{2,3}', '^$', r'\b', '.',
    'ab', '(a)', 'a{2}', 'a{2,}', 'a??', '(?P<id>a)', 'a|', '|b', '()', '[abc]', '[^a]', '[a-c]',
    r'\A\z', r'\B', '中文', '(a)(b)', 'a|ab',
    r'\d', r'\D', r'\s', r'\S', r'\w', r'\W', r'\pL', r'\PL', r'\p{Greek}', r'\p{sc=Greek}',
    r'\p{sc:Greek}', r'\p{sc!=Greek}', r'\n', r'\r', r'\t', r'\a', r'\f', r'\v', r'\x61', r'\x{61}',
    r'\u0061', r'\U00000061', r'\*', r'\%', '(?i:a)', '(?i)a', '(?m)^', '(?m:$)', '(?s).', '(?-u:\\w)',
    '(?R:^)', '(?mR:^)', '(?U)a?', '(?U:a??)', '(?x: a)', '(?x: a b)', '(?x:a | b)', '(?x:a ?)',
    '(?x:a{2, 3})', '(?x:a#c\nb)', '(?i)a|b', '(?i:[^a])', '(?-u:\\d)', '(?mR:.)',
    '[a&&b]', '[ab&&b]', '[a--b]', '[a~~b]', '[a&&[bc]]', r'[\d&&\w]', '[a&&b&&c]',
    '[[:digit:]]', '[[:^alpha:]]', '[a[:digit:]]', '[[:word:]&&[:digit:]]',
    r'(?-u:\xFF)', r'\p{NotAProperty}', r'(?-u:.)', r'(?-u:\D)', r'(?-u:\pL)',
]
for pattern in patterns:
    compare('ast', pattern)
lowered = 0
for pattern in ['(?<id>[0-9]{6})', 'a|b', '(?:a)', 'a*', 'ab', '(a)', '^', '.', '[abc]', '[^a]',
                '[a-c]', 'a{2,3}', 'a??', '()', 'a|ab', '(?i:a)', '(?i)a', '(?m)^', '(?m:$)', '(?s).',
                '(?-u:\\w)', '(?R:^)', '(?mR:^)', '(?U)a?', '(?U:a??)', '(?x: a b)', '(?i)a|b',
                '(?i:[^a])', '(?-u:\\d)', r'\d', r'\D', r'\w', r'\pL', r'\p{Greek}', r'\p{sc!=Greek}',
                '(?i:\\pL)', '(?mR:.)', '(?-u:\\b)', '[a&&b]', '[ab&&b]', '[a--b]', '[a~~b]',
                '[a&&[bc]]', r'[\d&&\w]', '[a&&b&&c]', '(?i:[a&&b])',
                '[[:digit:]]', '[[:^alpha:]]', '[a[:digit:]]', '(?i:[[:upper:]])']:
    direct, via_ast = run(CJ, 'hir', pattern, 'true'), run(CJ, 'ast-hir', pattern)
    if direct.returncode or via_ast.returncode or direct.stdout != via_ast.stdout:
        raise AssertionError((pattern, direct.stdout, via_ast.stdout, via_ast.stderr))
    lowered += 1
for pattern in patterns:
    compare('ast-print', pattern)
for pattern, utf8 in [(r'(?-u:\xFF)', 'true'), (r'\p{NotAProperty}', 'true'), (r'(?-u:.)', 'true'),
                      (r'(?-u:\D)', 'true'), (r'(?-u:\pL)', 'true'), (r'(?-u:\xFF)', 'false'),
                      (r'(?-u:\w)', 'false'), (r'\p{sc=Nope}', 'true')]:
    compare('ast-translate', pattern, utf8)
# The three-digit octal domain, independently parsed, printed and lowered.
# Include class and range endpoints: printing alone once hid a wrong class.
octal_patterns = ["\\" + format(code, "03o") for code in range(512)]
octal_patterns += ["[" + pattern + "]" for pattern in octal_patterns]
octal_patterns += [r'[\0-\7]', r'[\77-\100]', r'[\177-\200]', r'[\377-\777]',
                   r'\0', r'\00', r'\0001', r'\1234', r'\78', r'[\78]',
                   r'(?i:[\141])', r'(?-u:[\377])', r'(?-u:\377)',
                   r'(?x:[\1 23])', r'(?x:\1 23)']
for pattern in octal_patterns:
    compare('ast-octal', pattern)
# Octal remains opt-in; enabling it must not change default rejection behavior.
for pattern in [r'(?i:[\141])', r'(?i:[\141-\172])', r'(?i:\141)', r'(?i:[^\141])']:
    for text in ['AazZ', 'bB', 'ſK', '中', '']:
        compare('octal-find', pattern, text)
for pattern in [r'\1', r'[\1]', r'[\0-\7]']:
    r, c = run(RUST, 'ast', pattern), run(CJ, 'ast', pattern)
    assert r.returncode == c.returncode == 2 and r.stderr == c.stderr, (pattern, r, c)
printed = run(CJ, 'ast-print', '(?<id>[0-9]{6})')
assert printed.returncode == 0 and printed.stdout.strip() == '(?<id>[0-9]{6})', printed
again = run(CJ, 'hir', printed.stdout.strip(), 'true')
original = run(CJ, 'hir', '(?<id>[0-9]{6})', 'true')
assert again.stdout == original.stdout
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update(ast_octal_cases_passed=len(octal_patterns), ast_review_regressions_passed=len(review_patterns), ast_cases_passed=len(patterns), ast_hir_cases_passed=lowered)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'AST: {len(patterns)} shapes matched, {lowered} lowered to the same HIR', flush=True)
