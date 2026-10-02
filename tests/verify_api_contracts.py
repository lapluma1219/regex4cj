"""Public API contracts omitted by the upstream matching-only suite.

Both programs execute real API calls, including native NUL/invalid UTF-8 values.
No Rust source checkout is needed; the oracle is pinned by Cargo.lock.
"""
import json
import subprocess
from regex_test_support import RUST, CJ, ENV, REPORT, compare


def batch(binary):
    result = subprocess.run([str(binary), 'api-audit'], env=ENV, capture_output=True, text=True, timeout=30)
    assert result.returncode == 0, result.stderr
    lines = [line.split('\t', 1) for line in result.stdout.splitlines()]
    assert all(len(line) == 2 for line in lines), result.stdout
    values = dict(lines)
    assert len(values) == len(lines), 'duplicate contract id'
    return values


rust, cj = batch(RUST), batch(CJ)
assert len(rust) == 2148, 'contract inventory changed; review expected coverage'
assert rust.keys() == cj.keys(), (rust.keys() - cj.keys(), cj.keys() - rust.keys())
failures = [{'case': key, 'rust': value, 'cangjie': cj[key]}
            for key, value in rust.items() if value != cj[key]]
if failures:
    REPORT.with_name('api-contract-failures.json').write_text(json.dumps(failures, ensure_ascii=False, indent=2) + '\n')
    raise AssertionError(failures)

# Every byte position, including positions inside 2-, 3- and 4-byte UTF-8 scalars.
count = 0
for text in ['éa', '中a', '🙂a', '中']:
    for start in range(len(text.encode()) + 1):
        for pattern in ['a', '.', '', r'\A', r'\z', r'\b', r'\B', r'(?-u:\b)', r'(?-u:\B)']:
            compare(pattern, text, 'find-at', str(start))
            compare(pattern, text, 'is-match-at', str(start))
            rust_set = subprocess.run([str(RUST), 'set-is-match-at', text, str(start), pattern],
                                      env=ENV, capture_output=True, timeout=15)
            cj_set = subprocess.run([str(CJ), 'set-is-match-at', text, str(start), pattern],
                                    env=ENV, capture_output=True, timeout=15)
            assert rust_set.returncode == cj_set.returncode == 0 and rust_set.stdout == cj_set.stdout, (
                pattern, text, start, rust_set.stdout, cj_set.stdout, cj_set.stderr)
            count += 3
report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update(api_contract_cases_passed=len(rust), api_offset_differential_passed=count,
              builder_combination_cases_passed=sum(k.startswith(('builder-s-', 'builder-ss-', 'builder-b-', 'builder-bs-')) for k in rust),
              lazy_iterator_cases_passed=sum(k.startswith(('byte-iter-', 'byte-capiter-', 'byte-splititer-', 'byte-splitn-', 'string-splitn-')) for k in rust),
              bytes_offset_contract_cases_passed=sum(k.startswith(('byte-at-', 'byte-isat-', 'byte-capat-', 'byte-setat-')) for k in rust))
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(f'API contract cases passed: {len(rust)}; offset differential checks passed: {count}', flush=True)
