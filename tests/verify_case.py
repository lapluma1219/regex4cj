"""Unicode simple case folding for inline i, including class algebra order."""
import json
from regex_test_support import RUST, CJ, REPORT, invoke, compare

patterns = [
    '(?i)a', '(?i)K', '(?i)σ', '(?i)ß', '(?i)SS', '(?i)[^k]', '(?i)[a&&A]',
    '(?i)[a-z--c]', '(?i)[[:lower:]]', '(?i)[[:^lower:]]', '(?i)[[:ascii:]]',
    r'(?i)\p{Ll}', r'(?i)\d', r'(?i)\w', '(?i)(?<n>a)', 'a(?i)b', '(?i:a)b',
    '(?i)(?-i:a)', '(?i)[A-C]', '(?i)a+', '(?im)^a$', '(?i)[[^c]&&a-z]',
    '(?i)[a-z--[c]]', r'(?i)[\d]', '(?i)[a-c&&b]', 'a', '(?i)', '(?-i)A',
    r'(?i)\ba\b', '(?i)[A-Z]', r'(?i)\P{Ll}',
]
texts = [
    '', 'a', 'A', 'b', 'k', 'K', '\u212a', 'σ', 'Σ', 'ς', 'ß', 'ẞ', 'SS',
    'c', 'C', 'd', 'D', '1', '\n', 'Ab', 'aB', 'AaA', 'ſ',
]
count = 0
for pattern in patterns:
    for text in texts:
        compare(pattern, text)
        count += 1
    if count % 100 == 0:
        print('case fold fixed cases passed:', count, flush=True)
for pattern, text in [('(?i)(?<n>a)', 'A'), ('(?i)(σ)', 'Σ'), ('(?i)[a-z--c]', 'D')]:
    compare(pattern, text, 'captures')
    compare(pattern, text, 'replace-all', '<$0>')
    count += 2


def compare_set(text, patterns):
    rust = invoke(RUST, 'set-matches', text, patterns[0], *patterns[1:])
    cj = invoke(CJ, 'set-matches', text, patterns[0], *patterns[1:])
    if rust.returncode != 0 or cj.returncode != 0 or rust.stdout != cj.stdout:
        raise AssertionError({
            'patterns': patterns, 'text': text,
            'rust': rust.stdout.decode(), 'cangjie': cj.stdout.decode(),
            'rust_error': rust.stderr.decode(), 'cangjie_error': cj.stderr.decode(),
        })


compare_set('AB cd', ['(?i)ab', 'cd'])
compare_set('K', ['(?i)k', 'x'])
count += 2

golden = [
    ('(?i)a', 'A', b'0\t1\tA\n'),
    ('(?i)ß', 'SS', b''),
    ('(?i)ß', 'ẞ', '0\t3\tẞ\n'.encode()),
    ('(?i)[^k]', 'K', b''),
    ('(?i)[a-z--c]', 'C', b''),
    ('a(?i)b', 'Ab', b''),
    ('(?i)K', '\u212a', '0\t3\t\u212a\n'.encode()),
]
for pattern, text, expected in golden:
    result = invoke(CJ, 'find', pattern, text)
    assert result.returncode == 0 and result.stdout == expected, (pattern, result)

for pattern in ['(?ii)a', '(?i-i-i)a']:
    assert invoke(RUST, 'find', pattern, 'a').returncode != 0, pattern
    result = invoke(CJ, 'find', pattern, 'a')
    assert result.returncode == 2 and result.stderr and not result.stdout, (pattern, result)

report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update({
    'case_fold_differential_passed': count,
    'case_fold_golden_passed': len(golden),
    'case_fold_invalid_rejected': 2,
    'case_folding': 'Unicode simple case folding when unicode is on; ASCII A-Z folding when unicode is off',
})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({k: report[k] for k in report if k.startswith('case_fold')}, ensure_ascii=False), flush=True)
