"""Syntax error kind and byte spans versus regex-syntax, without changing Display."""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT

patterns = [
    'a', '(', ')', 'a)', '*', '{', '+', '?', '(?)', '(?i)*', '[z-a]', r'\q', r'\x{', r'\x{}',
    r'\x{110000}', '(?i-i)', '(?--i)', '(?i-)', '(?<>a)', '(?<1>a)', '(?<id>a)(?<id>b)',
    'a{2,1}', 'a{', 'a{x}', 'a{,}', 'a{2,x}', r'\1', '(?=a)', r'\p{Foo}', r'\p{sc=Nope}',
    '(?-u:\\pL)', '(?-u:\\xFF)', '中(', '中)', '中*', '(?i',
    '[' * 251 + 'a' + ']' * 251,
]


def run(binary, pattern):
    return subprocess.run([str(binary), 'syntax-error', pattern], env=ENV,
                          capture_output=True, text=True, timeout=30)


count = 0
for pattern in patterns:
    rust, cj = run(RUST, pattern), run(CJ, pattern)
    if rust.returncode or cj.returncode or rust.stdout != cj.stdout:
        failure = dict(pattern=pattern, rust=rust.stdout, cangjie=cj.stdout,
                       rust_error=rust.stderr, cangjie_error=cj.stderr,
                       rust_code=rust.returncode, cangjie_code=cj.returncode)
        REPORT.with_name('error-span-failure.json').write_text(
            json.dumps(failure, ensure_ascii=False, indent=2))
        raise AssertionError(failure)
    count += 1
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report['error_span_cases_passed'] = count
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'syntax error spans matched: {count}', flush=True)
