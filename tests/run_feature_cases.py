"""Execute named functional cases with independent expectations and Rust comparison."""
import json
import sys
import os
import subprocess
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent / 'support'))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from feature_catalog import load
from regex_test_support import ROOT, RUST, CJ, ENV, invoke


def main():
    path = Path(os.environ['REGEX4CJ_LOCAL']) / 'work/feature-cases.json'
    result = {'run_id': os.environ['REGEX4CJ_RUN_ID'], 'cases': []}
    _, cases = load()
    for case in cases:
        record = {'id': case['id'], 'group': case['group'], 'feature': case['feature'], 'status': 'failed'}
        try:
            args = ([case['operation'], case['text'], *case['pattern']] if isinstance(case['pattern'], list)
                    else [case['operation'], case['pattern'], case['text'], *case['extra']])
            args = case.get('args', args)
            rust, cj = [subprocess.run([str(b), *args], env=ENV, capture_output=True, timeout=15) for b in (RUST, CJ)]
            if case['expect_error']:
                ok = rust.returncode != 0 and cj.returncode == 2 and bool(cj.stderr) and not cj.stdout
            else:
                expected = case['expected_stdout'].encode()
                ok = rust.returncode == cj.returncode == 0 and rust.stdout == cj.stdout == expected
            record.update(status='passed' if ok else 'failed', rust_code=rust.returncode, cangjie_code=cj.returncode,
                          rust_stdout=rust.stdout.decode(), cangjie_stdout=cj.stdout.decode(),
                          rust_stderr=rust.stderr.decode(), cangjie_stderr=cj.stderr.decode())
        except Exception as error:
            record['error'] = str(error)
        result['cases'].append(record)
        path.write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    failed = [c['id'] for c in result['cases'] if c['status'] != 'passed']
    if failed:
        raise SystemExit(f'Failed named cases: {failed}; see {path}')
    print(f'{len(cases)} named functional cases passed')


if __name__ == '__main__':
    main()
