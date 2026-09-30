"""Rule labels are application data; the Cangjie RegexSet computes membership."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def read_rules(path):
    rules = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(rules, list) or any(not isinstance(r, dict) or
            not isinstance(r.get('pattern'), str) or not isinstance(r.get('label'), str) for r in rules):
        raise ValueError('规则文件必须为包含 label 和 pattern 字符串的 JSON 数组')
    if len(rules) > 256:
        raise ValueError('本版最多支持 256 条规则')
    return rules


def classify(rules, text):
    env = os.environ.copy()
    if env.get('REGEX4CJ_DYLD_LIBRARY_PATH'):
        env['DYLD_LIBRARY_PATH'] = env['REGEX4CJ_DYLD_LIBRARY_PATH']
    result = subprocess.run([str(ROOT / 'cli/target/release/bin/main'), 'set-matches', text,
                             *[r['pattern'] for r in rules]], env=env, capture_output=True,
                            text=True, encoding='utf-8', timeout=30)
    if result.returncode:
        raise ValueError(result.stderr.strip())
    return [int(line.split('\t')[1]) for line in result.stdout.splitlines() if line.startswith('hit\t')]


def display(rules, text, ids):
    print('文本：' + json.dumps(text, ensure_ascii=False))
    print('命中编号：' + json.dumps(ids))
    print('分类标签：' + json.dumps([rules[i]['label'] for i in ids], ensure_ascii=False))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('text', nargs='?')
    p.add_argument('--rules', type=Path, default=ROOT / 'examples/classification-rules.json')
    p.add_argument('--demo', action='store_true')
    a = p.parse_args()
    rules = read_rules(a.rules)
    if not a.demo:
        if a.text is None: p.error('请提供文本；可用单引号传入空字符串')
        display(rules, a.text, classify(rules, a.text))
        return 0
    cases = json.loads((ROOT / 'examples/classification-cases.json').read_text())
    results = []
    for case in cases:
        ids = classify(rules, case['text'])
        display(rules, case['text'], ids)
        ok = ids == case['expected_ids']
        print('预期编号：{}；{}\n'.format(case['expected_ids'], 'PASS' if ok else 'FAIL'), flush=True)
        results.append(dict(text=case['text'], expected_ids=case['expected_ids'], actual_ids=ids, passed=ok))
    work = Path(os.environ.get('REGEX4CJ_LOCAL', ROOT.parent / 'regex4cj-local')) / 'work'
    work.mkdir(parents=True, exist_ok=True)
    (work / 'classification.json').write_text(json.dumps(results, ensure_ascii=False, indent=2) + '\n')
    print('多规则分类验收：{}/{} 通过'.format(sum(r['passed'] for r in results), len(results)))
    return 0 if all(r['passed'] for r in results) else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.TimeoutExpired) as error:
        print('分类失败：' + str(error), file=sys.stderr)
        sys.exit(2)
