"""Character class, set algebra and counted-repetition differential regression."""
import json
import random
from regex_test_support import RUST, CJ, REPORT, invoke, compare

patterns = [
    '[a-z]', '[a-z]+', '[^a]', '[^a]+', '[a-zA-Z0-9_]+', '[aa-cb-de]',
    '[-a]', '[a-]', '[--a]', '[]a]', '[^]]', r'[\[\]\\\-]+', r'[\n\t]',
    '[中-文]+', '[🙂-🙃]+', '[^中🙂]+', '[a&&b]', '[a-z&&[^aeiou]]+',
    '[a-z--[a-f]]+', '[a-f~~d-z]+', '[[a-c][x-z]]+', '[a-c&&b-d~~c-e]',
    '[a-c~~b-d&&c-e]', '[a-c--b-d--c-e]', '[&&a]', '[a&&]', '[a~~]',
    '[^a&&a]', '[^a--a]', '[a-z&&[^b-d]x]', '[a-b-c]', '[--0]', '[a&~]+',
    'a{0}', 'a{1}', 'a{2}', 'a{2,4}', 'a{2,4}?', 'a{0,3}', 'a{0,3}?',
    'a{2,}', 'a{2,}?', 'a{0,}', 'a{0,}?', 'a{0002}', '(a?){2,4}',
    '(a??){2,4}?', '(a|ab){1,3}', '(ab|a){1,3}', '(a?){0,}', '(a?|b){0,}',
    '(a?){2,}', '(){0}', '(){3,5}', '(?:){2,}', '(^|a){0,3}',
    '[a-z]{0,3}?', '[^a]{1,2}', '(中|🙂){2,3}', '(a{0,2}){2,3}',
    '(a{0,2}?){2,3}?', '(a|b){0,2}c', '(a?){2,4}b',
    '[A-Z]{2}-[0-9]{3}', '^[A-Z]{2}-[0-9]{3}$', '}', ']',
]
texts = ['', 'a', 'aaaaa', 'ababc', 'z0_A-', ']\\[]', 'abcxyz', '\n\t', 'a中🙂文🙃b',
         'order=AB-123; order=CD-456']
count = 0
for p in patterns:
    for text in texts:
        compare(p, text)
        count += 1
    if count % 100 == 0:
        print('class/repetition fixed cases passed:', count, flush=True)

rng = random.Random(20260922)
def make_class(depth):
    if depth == 0:
        return rng.choice(['[a-c]', '[^b]', '[中🙂]', '[0-9]', r'[\t\n]', '[^a-c]'])
    return '[' + make_class(depth - 1) + rng.choice(['', '&&', '--', '~~']) + make_class(depth - 1) + ']'
def make_pattern(depth):
    if depth == 0:
        return rng.choice(['a', 'b', '', '.', '中', '[^b]', '[a-c]'])
    if rng.randrange(2):
        return '(?:' + make_pattern(depth - 1) + ')' + rng.choice(['{0}', '{2}', '{0,3}', '{1,3}?', '{2,}', '{0,}?'])
    return '(?:' + make_pattern(depth - 1) + '|' + make_pattern(depth - 1) + ')'
for i in range(200):
    p = make_class(2) + rng.choice(['+', '{0,3}', '{1,2}?']) if i % 2 else make_pattern(3)
    text = ''.join(rng.choice('aabc09中🙂\n\t') for _ in range(rng.randrange(24)))
    compare(p, text)
    count += 1

# Boundary scalar values test range complement, surrogate exclusion and UTF-8 offsets.
for p in ['[^a]', '[\ud7ff-\ue000]', '[\ue000-\U0010ffff]', '[^\ud7ff-\ue000]', '[\u0080-\u07ff]']:
    compare(p, 'a\u007f\u0080\u07ff\u0800\ud7ff\ue000\uffff\U00010000\U0010ffff')
    count += 1

# Independent golden output, including the original user-facing order-number example.
golden = [('[A-Z]{2}-[0-9]{3}', 'order=AB-123; order=CD-456', '6\t12\tAB-123\n20\t26\tCD-456\n'),
          ('[中🙂]{2}', 'a中🙂b', '1\t8\t中🙂\n'),
          ('a{2,3}?', 'aaaaa', '0\t2\taa\n2\t4\taa\n'),
          ('[a-z&&[^aeiou]]+', 'abcde', '1\t4\tbcd\n'),
          ('[a--a]', 'a', '')]
for p, text, expected in golden:
    r = invoke(CJ, 'find', p, text)
    assert r.returncode == 0 and r.stdout == expected.encode(), (p, r)
    compare(p, text, 'first')
    compare(p, text, 'is-match')

invalid = ['[]', '[^]', '[z-a]', '[a-[b]]', '[a', '[a\\', r'[\A]', r'[\z]',
           'a{3,2}', 'a{,}', 'a{', 'a{2', 'a{2,x}', 'a{1,2,3}', '{2}', 'a{999999999999999999999999}']
for p in invalid:
    rust = invoke(RUST, 'find', p, '')
    assert rust.returncode != 0, ('fixture unexpectedly valid in Rust', p)
    result = invoke(CJ, 'find', p, '')
    assert result.returncode == 2 and result.stderr and not result.stdout, (p, result)
for p in ['a{ 2 }', 'a{2}*']:
    compare(p, 'aaa')
    count += 1
limits = [('[' * 251 + 'a' + ']' * 251, 'nested')]
for p, message in limits:
    r = invoke(CJ, 'find', p, '')
    assert r.returncode == 2 and message in r.stderr.decode() and not r.stdout, (p, r)
    assert invoke(RUST, 'find', p, '').returncode != 0, p

for p, text in [('[a-c]{1000}', 'a' * 1000), ('[a-c]*z', 'a' * 8000),
                ('(a?){0,20}b', 'a' * 500), ('a{0}b', 'ab')]:
    compare(p, text)
    count += 1
report = json.loads(REPORT.read_text())
report.update({'class_repetition_differential_passed': count, 'class_repetition_golden_passed': len(golden),
               'class_repetition_api_checks_passed': 10, 'class_repetition_invalid_rejected': len(invalid),
               'class_repetition_unsupported_rejected': 0,
               'class_repetition_resource_limits_checked': len(limits),
               'matching_scope': 'Unicode-scalar NFA with class set algebra and counted repetitions; no properties/flags/bytes/DFA'})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
