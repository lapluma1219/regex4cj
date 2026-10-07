"""Run acceptance stages and persist a commit-bound run status independently of counters."""
import datetime
import hashlib
import json
import os
import re
from pathlib import Path
import platform
import subprocess
import sys
import uuid
from feature_catalog import load, validate, documents

ROOT = Path(__file__).resolve().parents[1]
WORK = Path(os.environ['REGEX4CJ_LOCAL']) / 'work'
STATUS = WORK / 'verification-run.json'


def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


def output(args):
    proc = subprocess.run(args, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if proc.returncode:
        raise RuntimeError(f'{args}: {proc.stdout}')
    return proc.stdout.strip()


def save(state):
    temp = STATUS.with_suffix('.tmp')
    temp.write_text(json.dumps(state, ensure_ascii=False, indent=2) + '\n')
    temp.replace(STATUS)


def main():
    state = {'run_id': str(uuid.uuid4()), 'status': 'running', 'started_at': now(),
             'stages': [], 'scope': 'Selected Regex, syntax, literal/UTF-8 tools, PikeVM, reverse NFA, bounded backtracker and DFA contracts; not full workspace parity'}
    save(state)
    try:
        # Old counters must never be mistaken for this invocation's results.
        for name in ['feature-cases.json', 'functional-report.md', 'verification.json', 'showcase.json', 'classification.json',
                     'matching-failure.json', 'hir-failure.json', 'upstream-suite-failures.json', 'upstream-sample-skips.json',
                     'api-contract-failures.json', 'pike-failure.json', 'ast-failure.json', 'props-failure.json',
                     'error-span-failure.json', 'engine-edges-failure.json', 'dfa-failure.json',
                     'backtrack-failure.json', 'reverse-failure.json', 'literal-failure.json', 'utf8-failure.json']:
            (WORK / name).unlink(missing_ok=True)
        for failure in WORK.glob('*-failure*.json'):
            failure.unlink()
        state['commit'] = output(['git', 'rev-parse', 'HEAD']) if (ROOT / '.git').exists() else None
        state['dirty'] = bool(output(['git', 'status', '--porcelain'])) if state['commit'] else None
        state['environment'] = {'platform': platform.platform(), 'python': sys.version,
                                'cangjie': output(['cjc', '--version']),
                                'rust': output(['rustc', '--version']), 'cargo': output(['cargo', '--version'])}
        source_files = sorted(p for folder in ['port', 'cli', 'oracle', 'tests', 'scripts', 'examples'] for p in (ROOT / folder).rglob('*') if p.is_file() and not any(part in ('target', '__pycache__') for part in p.relative_to(ROOT).parts))
        state['tested_source_sha256'] = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in source_files}
        state['baseline'] = json.loads((ROOT / 'docs/baseline.json').read_text())
        save(state)
        catalog, cases = load()
        validate(catalog, cases)
        os.environ['REGEX4CJ_RUN_ID'] = state['run_id']
        stages = [('feature-catalog', [sys.executable, 'scripts/feature_catalog.py', '--check'], ROOT),
                  ('upstream-data', [sys.executable, 'scripts/check_upstream_data.py'], ROOT),
                  ('api-inventory', [sys.executable, 'scripts/audit_api_surface.py', '--check'], ROOT),
                  ('cangjie-api-inventory', [sys.executable, 'scripts/generate_api_catalog.py', '--check'], ROOT)]
        for name in ['unicode', 'categories', 'scripts', 'binary', 'case_fold', 'age_break']:
            stages.append(('data-' + name, [sys.executable, f'scripts/generate_{name}.py', '--check'], ROOT))
        stages += [('python-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tests/tooling', '-p', 'test_*.py'], ROOT)]
        for action in ['build', 'test']:
            stages.append(('rust-' + action, ['cargo', action, '--locked', '--manifest-path', 'oracle/Cargo.toml'], ROOT))
        instrumentation = ['--coverage'] if os.environ.get('REGEX4CJ_COVERAGE') == '1' else []
        for package in ['port', 'cli', 'examples/consumer']:
            stages.append((package + '-build', ['cjpm', 'build', *instrumentation], ROOT / package))
        for action in ['test', 'run']:
            stages.append(('consumer-' + action, ['cjpm', action, *(instrumentation if action == 'test' else [])], ROOT / 'examples/consumer'))
        for group in catalog['groups']:
            for feature in group['features']:
                stages.append((feature['id'], [sys.executable, 'tests/run_suite.py', feature['suite']], ROOT))
        stages.append(('named-functional-cases', [sys.executable, 'tests/run_feature_cases.py'], ROOT))
        registered = {name for name, _, _ in stages if name.startswith('verify')}
        discovered = {p.stem for p in (ROOT / 'tests/functional').rglob('verify*.py')}
        if registered != discovered:
            raise RuntimeError(f'Unregistered or missing verification suites: {registered ^ discovered}')
        stages.append(('coverage-ledger', [sys.executable, 'scripts/check_coverage.py'], ROOT))
        stages += [('showcase', [sys.executable, 'scripts/showcase.py'], ROOT),
                   ('classification', [sys.executable, 'scripts/classify.py', '--demo'], ROOT)]
        for name, command, cwd in stages:
            stage = {'name': name, 'command': command, 'status': 'running', 'started_at': now()}
            state['stages'].append(stage)
            save(state)
            print(f'\nAcceptance stage: {name}', flush=True)
            code = subprocess.call(command, cwd=cwd)
            stage.update(status='passed' if code == 0 else 'failed', exit_code=code, finished_at=now())
            save(state)
            if code:
                raise RuntimeError(f'{name} exited with {code}')
        state['checks'] = json.loads((WORK / 'verification.json').read_text())
        changed = [name for name, digest in state['tested_source_sha256'].items() if not (ROOT / name).is_file() or hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest]
        if changed:
            raise RuntimeError(f'Sources changed during verification: {changed}')
        state['status'] = 'passed'
    except (Exception, KeyboardInterrupt) as error:
        state['status'] = 'failed'
        state['error'] = str(error) or 'interrupted'
        raise
    finally:
        state['finished_at'] = now()
        save(state)
        catalog, cases = load()
        case_path = WORK / 'feature-cases.json'
        case_results = json.loads(case_path.read_text()) if case_path.exists() else {}
        if case_results.get('run_id') != state['run_id']:
            case_results = {}
        doc, _ = documents(catalog, cases, state, case_results)
        # Reports may live outside the repository when an output override is set.
        def report_link(match):
            target = match[1]
            path, marker, anchor = target.partition('#')
            absolute = (ROOT / 'docs' / path).resolve()
            relative = os.path.relpath(absolute, WORK)
            return '](' + relative + (marker + anchor if marker else '') + ')'
        doc = re.sub(r'\]\(([^)]+)\)', report_link, doc)
        (WORK / 'functional-report.md').write_text(doc)
    print(f'Complete acceptance passed. Report: {STATUS}', flush=True)


if __name__ == '__main__':
    main()
