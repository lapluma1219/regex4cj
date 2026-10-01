"""Run the pinned regex crate's own acceptance tests.

The cases are the ones tests/suite_string.rs, suite_bytes.rs, suite_string_set.rs
and suite_bytes_set.rs actually execute, plus the handwritten checks in
tests/regression.rs and tests/replace.rs. Search options that those suites skip
stay skipped here too.
"""
import json
import os
from concurrent.futures import FIRST_COMPLETED, ProcessPoolExecutor, wait
import subprocess
from pathlib import Path

from regex_test_support import CJ, ENV, REPORT, RUST, compare, invoke

UPSTREAM = Path(os.environ['REGEX4CJ_LOCAL']) / 'upstream/regex/testdata'
FAILURES = REPORT.with_name('upstream-suite-failures.json')


def compile_fails(pattern):
    rust = invoke(RUST, 'find', pattern, '')
    cj = invoke(CJ, 'find', pattern, '')
    if rust.returncode == 0 or cj.returncode == 0 or rust.stdout or cj.stdout:
        raise AssertionError({
            'pattern': pattern,
            'rust_code': rust.returncode,
            'cangjie_code': cj.returncode,
            'rust_error': rust.stderr.decode(),
            'cangjie_error': cj.stderr.decode(),
        })


def handwritten():
    for pattern in ['(*)', '(?:?)', '(?)', '*', '(?m){1,1}', ' {2147483516}{2147483416}{5}']:
        compile_fails(pattern)
    compare('(((?x)))', '', 'is-match')
    compare(r'([a-f]){2}(?P<foo>[x-z])', 'abx', 'captures')
    compare(r'\bs(?:[ab])', '73e4', 'bytes-find')
    win = r'(?i:(?:\b|_)win(?:32|64|dows)?(?:\b|_))'
    compare(win, 'ubi-Darwin-x86_64.tar.gz', 'is-match')
    compare(win, 'ubi-Windows-x86_64.zip', 'is-match')
    duration = (
        r'(\d+\s?(years|year|y))?\s?(\d+\s?(months|month|m))?\s?'
        r'(\d+\s?(weeks|week|w))?\s?(\d+\s?(days|day|d))?\s?'
        r'(\d+\s?(hours|hour|h))?'
    )
    compare(duration, '', 'is-match')
    letters = [f'{chr(ord("a") + i)}A' for i in range(26)]
    compare('|'.join(letters), 'FUBAR', 'find')
    compare(r'[0-9]', 'age: 26', 'replace', 'Z')
    compare(r'[0-9]+', 'age: 26', 'replace', 'Z')
    compare(r'[0-9]', 'age: 26', 'replace-all', 'Z')
    compare(r'([^ ]+)[ ]+([^ ]+)', 'w1 w2', 'replace', '$2 $1')
    compare(r'([^ ]+)[ ]+([^ ]+)', 'w1 w2', 'replace', '$2 $$1')
    compare(
        r'(?P<first>[^ ]+)[ ]+(?P<last>[^ ]+)(?P<space>[ ]*)',
        'w1 w2 w3 w4', 'replace-all', '$last $first$space')
    compare(r'^[ \t]+|[ \t]+$', ' \t  trim me\t   \t', 'replace-all', '')
    compare(r'(.)(.)', 'ab', 'replace', '$1-$2')
    compare(r'([a-z]) ([a-z])', 'a b', 'replace-all', '$2 $1')
    compare(r'([a-z]+) ([a-z]+)', 'a b', 'replace-all', '$$1')
    compare(r'([a-z]+) ([a-z]+)', 'a b', 'replace-all', '$2 $$c $1')
    compare(r'([^ ]+)[ ]+([^ ]+)', 'w1 w2', 'replace-literal', '$2 $1', '1')
    compare(r'([^ ]+)[ ]+([^ ]+)', 'w1 w2', 'replace-literal', '$$1', '1')
    compare('foo', 'foobar', 'replace-all', '')
    compare(r'^', 'bar', 'replace', 'foo')
    compare(r'(.)', 'b', 'replace-all', '${1}a $1a')
    compare(r'[0-9]', 'age: 1234', 'replace-n', 'Z', '2')
    compare(r'([0-9])', 'age: 1234', 'replace-n', '${1}Z', '2')
    compare(r'(.)(?P<a>.)', 'ab', 'captures')
    compare(r'^(?P<name>.+)$', 'abc', 'captures')
    compare(r'(.)(?P<a>a)?(.)(?P<b>.)', 'abc', 'captures')
    compare(r'([a-z])(([a-z])|([0-9]))', 'a5', 'captures')
    text = ''.join('1' if i % 3 == 0 else '0' for i in range(100_000))
    text += '1' + ''.join('1' if i % 3 == 0 else '0' for i in range(20))
    rust = invoke(RUST, 'is-match', r'[01]*1[01]{20}$', text)
    cj = subprocess.run(
        [str(CJ), 'is-match', r'[01]*1[01]{20}$', text],
        env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=120)
    if rust.returncode != 0 or cj.returncode != 0 or rust.stdout != cj.stdout:
        raise AssertionError({
            'name': 'dfa_handles_pathological_case',
            'rust': rust.stdout.decode(),
            'cangjie': cj.stdout.decode(),
            'cangjie_error': cj.stderr.decode(),
        })


def load_suite():
    proc = subprocess.run(
        [str(RUST), 'suite-emit', str(UPSTREAM)],
        env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180)
    if proc.returncode != 0:
        raise AssertionError(proc.stderr.decode())
    records = []
    for line in proc.stdout.splitlines():
        if line:
            records.append(json.loads(line))
    return records


def check(rec):
    patterns = rec['patterns']
    if any('\0' in pattern for pattern in patterns):
        return {'name': rec['name'], 'error': 'pattern contains NUL'}
    limit = '-' if rec['limit'] is None else str(rec['limit'])
    args = [
        str(CJ), 'suite-run', rec['api'], rec['op'],
        '1' if rec['unicode'] else '0',
        '1' if rec['casei'] else '0',
        str(rec['term']), limit, rec['hay'], *patterns,
    ]
    try:
        cj = subprocess.run(args, env=ENV, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90)
    except subprocess.TimeoutExpired:
        return {'name': rec['name'], 'api': rec['api'], 'op': rec['op'], 'error': 'timeout',
                'patterns': patterns}
    if rec['code'] == 0:
        if cj.returncode != 0 or cj.stdout.decode() != rec['out']:
            return {
                'name': rec['name'], 'api': rec['api'], 'op': rec['op'], 'patterns': patterns,
                'hay': rec['hay'], 'expected': rec['out'], 'cangjie': cj.stdout.decode(),
                'cangjie_error': cj.stderr.decode(), 'cangjie_code': cj.returncode,
            }
    elif cj.returncode == 0 or cj.stdout:
        return {
            'name': rec['name'], 'api': rec['api'], 'op': rec['op'], 'patterns': patterns,
            'hay': rec['hay'], 'expected_code': rec['code'], 'cangjie': cj.stdout.decode(),
            'cangjie_error': cj.stderr.decode(), 'cangjie_code': cj.returncode,
        }
    return None


def main():
    handwritten()
    print('handwritten upstream checks passed', flush=True)
    records = load_suite()
    print('upstream suite cases:', len(records), flush=True)
    failures = []
    done = 0
    next_index = 0
    workers = min(4, os.cpu_count() or 1)
    with ProcessPoolExecutor(max_workers=workers) as pool:
        inflight = {}
        while next_index < len(records) and len(inflight) < workers:
            inflight[pool.submit(check, records[next_index])] = next_index
            next_index += 1
        while inflight and len(failures) < 8:
            finished, _ = wait(inflight, return_when=FIRST_COMPLETED)
            for future in finished:
                inflight.pop(future)
                done += 1
                failure = future.result()
                if failure:
                    failures.append(failure)
                if done % 100 == 0 or done == len(records):
                    print(f'suite {done}/{len(records)} failures {len(failures)}', flush=True)
            while next_index < len(records) and len(inflight) < workers and len(failures) < 8:
                inflight[pool.submit(check, records[next_index])] = next_index
                next_index += 1
    if failures or next_index < len(records):
        if not failures:
            failures.append({'error': 'suite stopped before the last case', 'next': next_index})
        FAILURES.write_text(json.dumps(failures, ensure_ascii=False, indent=2) + '\n')
        raise AssertionError(failures)
    report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
    report['upstream_suite_passed'] = len(records)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print('upstream suite passed:', len(records), flush=True)


if __name__ == '__main__':
    main()
