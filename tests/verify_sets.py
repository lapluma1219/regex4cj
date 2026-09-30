"""RegexSet contract: all overlapping pattern IDs, compared with Rust and singles."""
import json
import random
import subprocess
import time
from regex_test_support import ROOT, RUST, CJ, ENV, REPORT


def invoke(binary, mode, patterns, text):
    return subprocess.run([str(binary), mode, text, *patterns], env=ENV,
                          capture_output=True, timeout=30)


def compare(patterns, text):
    match_output = b''
    for mode in ['set-matches', 'set-is-match']:
        rust = invoke(RUST, mode, patterns, text)
        cj = invoke(CJ, mode, patterns, text)
        if mode == 'set-matches': match_output = cj.stdout
        if rust.returncode != 0 or cj.returncode != 0 or rust.stdout != cj.stdout:
            failure = dict(patterns=patterns, text=text, mode=mode,
                           rust=rust.stdout.decode(), cangjie=cj.stdout.decode(),
                           rust_error=rust.stderr.decode(), cangjie_error=cj.stderr.decode())
            REPORT.with_name('set-failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2))
            raise AssertionError(failure)
    return match_output


fixed = [[], [''], ['', '^$', 'a*'], ['a', 'a', 'aa'], ['foo', 'bar', 'foobar', 'foo'],
         ['退款', '发票', '[A-Z]{2}-[0-9]{3}'], ['a|ab', 'ab', 'b'], ['a.*z', 'b', 'z'],
         ['a*?', 'a+', '(a?)*'], ['(?m)^a$', r'\Aa\z', '$'],
         [r'\bcat\b', r'\B', r'\b'], [r'\p{Han}', r'\p{Alphabetic}', r'\p{Emoji}'],
         [r'\p{sc=Hira}', r'\p{scx=Hira}', '[[:digit:]]', r'\d'],
         ['(?<x>a+)', '(a)?b', 'a{0}', '(?s).', '(?U)a+'],
         [r'[a-z&&[^aeiou]]+', r'[a-z--[aeiou]]', '[a-c~~b-d]']]
texts = ['', 'a', 'ab', 'aaa', 'bar foobar foo', 'a\na\n', 'cat cats cat',
         '中文🙂٣ー', '订单 AB-123 需要退款和发票', 'a xx b zz', '\ud7ff\ue000\U0010ffff']
count = 0
for patterns in fixed:
    for text in texts:
        compare(patterns, text)
        count += 2
rng = random.Random(20260930)
atoms = ['a', 'b', '中', '[a-z]', r'\d', r'\p{Han}', '.', '[^a]', '(a|ab)', r'\b', '(?:)']
for _ in range(120):
    patterns = [rng.choice(atoms) + rng.choice(['', '?', '*', '+?', '{0,2}'])
                for _ in range(rng.randrange(1, 7))]
    # Repeating a boundary is valid in the pinned Rust implementation.
    text = ''.join(rng.choice(['a', 'b', '中', '٣', ' ', '\n', '🙂']) for _ in range(rng.randrange(20)))
    output = compare(patterns, text)
    hits = {int(line.split(b'\t')[1]) for line in output.splitlines() if line.startswith(b'hit\t')}
    for i, pattern in enumerate(patterns):
        single = subprocess.run([str(CJ), 'is-match', pattern, text], env=ENV, capture_output=True, timeout=15)
        assert single.returncode == 0 and (single.stdout == b'true\n') == (i in hits), (patterns, text, i, single)
    count += 2

# Golden expectations independent of the oracle.
golden = [([], '', []), (['', '^$', 'a*'], '', [0, 1, 2]),
          (['foo', 'bar', 'foo', 'foobar'], 'bar foobar foo', [0, 1, 2, 3]),
          (['退款', '发票', '[A-Z]{2}-[0-9]{3}'], '订单 AB-123 退款', [0, 2])]
for patterns, text, ids in golden:
    output = invoke(CJ, 'set-matches', patterns, text)
    expected = ('patterns\t{}\nany\t{}\nall\t{}\n'.format(len(patterns), str(bool(ids)).lower(), str(len(ids) == len(patterns)).lower()) +
                ''.join('hit\t{}\n'.format(i) for i in ids)).encode()
    assert output.returncode == 0 and output.stdout == expected, (patterns, output)
for patterns in [['ok', '('], ['ok', '(?i)a'], ['ok', r'\p{age=16.0}']]:
    r = invoke(CJ, 'set-matches', patterns, 'ok')
    assert r.returncode == 2 and b'pattern 1:' in r.stderr and not r.stdout, r
limits = [(['a'] * 257, b'256 patterns'), (['a' * 4000] * 17, b'65536 pattern bytes'),
          (['a{10000}'] * 2, b'16384 states')]
for patterns, message in limits:
    r = invoke(CJ, 'set-matches', patterns, '')
    assert r.returncode == 2 and message in r.stderr and not r.stdout, r

# Process-level measurements include startup and compilation, not just search.
measurements = []
for n in [8, 64, 256]:
    patterns = ['key{:03d}'.format(i) for i in range(n)]
    text = 'x' * 4096 + 'key000 key{:03d}'.format(n - 1)
    row = {'patterns': n, 'text_bytes': len(text.encode())}
    expected = None
    for label, binary in [('rust', RUST), ('cangjie', CJ)]:
        start = time.perf_counter()
        r = invoke(binary, 'set-matches', patterns, text)
        row[label + '_process_seconds'] = round(time.perf_counter() - start, 6)
        assert r.returncode == 0, r
        if expected is None: expected = r.stdout
        else: assert r.stdout == expected, r
    measurements.append(row)
    count += 1
REPORT.with_name('set-benchmark.json').write_text(json.dumps({'scope': 'one process per measurement; includes startup, compile and scan; no throughput claim', 'measurements': measurements}, indent=2) + '\n')
report = json.loads(REPORT.read_text())
report.update(regex_set_differential_passed=count, regex_set_golden_passed=len(golden),
              regex_set_error_checks_passed=6, regex_set_single_regex_baseline_cases=120)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('RegexSet differential passed:', count, flush=True)
