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
for patterns in [['ok', '('], ['ok', '(?=a)'], ['ok', r'\p{age=na}']]:
    r = invoke(CJ, 'set-matches', patterns, 'ok')
    rust = invoke(RUST, 'set-matches', patterns, 'ok')
    assert r.returncode == 2 and rust.returncode != 0 and r.stderr == rust.stderr and not r.stdout, (r.stderr, rust.stderr)
compare(['a'] * 257, '')
compare(['a{10000}', 'a{10000}'], 'a')
count += 4

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
def repeat_find(times):
    result = subprocess.run(
        [str(CJ), 'repeat-find', r'\p{L}+', '字' * 200, str(times)],
        env=ENV, capture_output=True, timeout=120)
    assert result.returncode == 0, result
    rows = {}
    match_line = None
    for raw in result.stdout.decode().splitlines():
        key, _, value = raw.partition('\t')
        if key in ('compile_ns', 'search_ns', 'repeats'):
            rows[key] = int(value)
        else:
            match_line = raw
    assert rows.get('repeats') == times and match_line, result.stdout
    return rows, match_line
timing, match_line = repeat_find(40)
start, end, text = match_line.split('\t', 2)
assert (start, end, text) == ('0', '600', '字' * 200), match_line
benchmark = {
    'scope': 'set rows are one process each and include startup, compile and scan. repeat-find times compile and search inside one process.',
    'measurements': measurements,
    'repeat_find': {
        'pattern': r'\p{L}+',
        'text': 'U+5B57 repeated 200 times',
        'repeats': timing['repeats'],
        'compile_seconds': round(timing['compile_ns'] / 1e9, 6),
        'search_seconds': round(timing['search_ns'] / 1e9, 6),
        'note': 'compile_seconds is Regex construction. search_seconds is 40 finds after that construction. Process startup is excluded. This is not a throughput claim.',
    },
}
REPORT.with_name('set-benchmark.json').write_text(json.dumps(benchmark, indent=2) + '\n')
report = json.loads(REPORT.read_text())
report.update(regex_set_differential_passed=count, regex_set_golden_passed=len(golden),
              regex_set_error_checks_passed=3, regex_set_single_regex_baseline_cases=120)
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('RegexSet differential passed:', count, flush=True)
