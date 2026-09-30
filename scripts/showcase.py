"""Readable end-to-end acceptance scenarios; the actual matching runs in Cangjie."""
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ENV = os.environ.copy()
if ENV.get('REGEX4CJ_DYLD_LIBRARY_PATH'):
    ENV['DYLD_LIBRARY_PATH'] = ENV['REGEX4CJ_DYLD_LIBRARY_PATH']


def decode(mode, output):
    if mode in ('find', 'first'):
        return [[int(a), int(b), text] for a, b, text in
                (line.split('\t', 2) for line in output.splitlines())]
    if mode == 'capture-name':
        parts = output.rstrip('\n').split('\t')
        return None if parts[1] == '-' else [int(parts[1]), int(parts[2]), bytes.fromhex(parts[3]).decode()]
    if mode == 'replace-all':
        return bytes.fromhex(output.strip()).decode()
    if mode == 'split':
        return [bytes.fromhex(line).decode() for line in output.splitlines()]
    raise ValueError('unknown showcase mode: ' + mode)


def main():
    cases = json.loads((ROOT / 'examples/showcase.json').read_text(encoding='utf-8'))
    results = []
    for number, case in enumerate(cases, 1):
        args = case['args']
        result = subprocess.run([str(ROOT / 'cli/target/release/bin/main'), *args],
                                env=ENV, capture_output=True, text=True, encoding='utf-8', timeout=30)
        if case.get('reject'):
            actual = '明确拒绝此模式' if result.returncode == 2 and result.stderr and not result.stdout else result.stdout
            ok = actual == '明确拒绝此模式'
            expected = '明确拒绝此模式'
        else:
            expected = case['expected']
            actual = decode(args[0], result.stdout) if result.returncode == 0 else result.stderr
            ok = result.returncode == 0 and actual == expected
        print('\n{}. {}'.format(number, case['title']), flush=True)
        print('   模式：' + args[1])
        print('   输入：' + json.dumps(args[2], ensure_ascii=False))
        if len(args) > 3:
            print('   参数：' + json.dumps(args[3:], ensure_ascii=False))
        print('   预期：' + json.dumps(expected, ensure_ascii=False))
        print('   实际：' + json.dumps(actual, ensure_ascii=False))
        print('   ' + ('PASS' if ok else 'FAIL') + ' — ' + case['note'], flush=True)
        results.append({'title': case['title'], 'passed': ok, 'expected': expected, 'actual': actual})
    local = Path(os.environ.get('REGEX4CJ_LOCAL', str(ROOT.parent / 'regex4cj-local')))
    report = local / 'work/showcase.json'
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps({'version': (ROOT / 'VERSION').read_text().strip(), 'cases': results}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    passed = sum(item['passed'] for item in results)
    print('\n场景验收：{}/{} 通过；报告：{}'.format(passed, len(results), report))
    return 0 if passed == len(results) else 1


if __name__ == '__main__':
    sys.exit(main())
