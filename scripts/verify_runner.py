"""Run acceptance stages and persist a commit-bound run status independently of counters."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import uuid

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
             'stages': [], 'scope': 'Selected string/bytes Regex, RegexSet, AST/HIR and forward PikeVM contracts; not full workspace parity'}
    save(state)
    try:
        # Old counters must never be mistaken for this invocation's results.
        for name in ['verification.json', 'showcase.json', 'classification.json',
                     'matching-failure.json', 'hir-failure.json', 'upstream-suite-failures.json', 'upstream-sample-skips.json',
                     'api-contract-failures.json', 'pike-failure.json', 'ast-failure.json', 'props-failure.json',
                     'error-span-failure.json']:
            (WORK / name).unlink(missing_ok=True)
        state['commit'] = output(['git', 'rev-parse', 'HEAD']) if (ROOT / '.git').exists() else None
        state['dirty'] = bool(output(['git', 'status', '--porcelain'])) if state['commit'] else None
        state['environment'] = {'platform': platform.platform(), 'python': sys.version,
                                'cangjie': output(['cjc', '--version']),
                                'rust': output(['rustc', '--version']), 'cargo': output(['cargo', '--version'])}
        source_files = sorted(p for folder in ['port', 'cli', 'oracle', 'tests', 'scripts', 'examples'] for p in (ROOT / folder).rglob('*') if p.is_file() and not any(part in ('target', '__pycache__') for part in p.relative_to(ROOT).parts))
        state['tested_source_sha256'] = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in source_files}
        state['baseline'] = json.loads((ROOT / 'docs/baseline.json').read_text())
        save(state)
        stages = [('upstream-data', [sys.executable, 'scripts/check_upstream_data.py'], ROOT),
                  ('api-inventory', [sys.executable, 'scripts/audit_api_surface.py', '--check'], ROOT),
                  ('cangjie-api-inventory', [sys.executable, 'scripts/generate_api_catalog.py', '--check'], ROOT)]
        for name in ['unicode', 'categories', 'scripts', 'binary', 'case_fold', 'age_break']:
            stages.append(('data-' + name, [sys.executable, f'scripts/generate_{name}.py', '--check'], ROOT))
        stages += [('python-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-p', 'test_category_generator.py'], ROOT)]
        for action in ['build', 'test']:
            stages.append(('rust-' + action, ['cargo', action, '--locked', '--manifest-path', 'oracle/Cargo.toml'], ROOT))
        for package in ['port', 'cli', 'examples/consumer']:
            stages.append((package + '-build', ['cjpm', 'build'], ROOT / package))
        for action in ['test', 'run']:
            stages.append(('consumer-' + action, ['cjpm', action], ROOT / 'examples/consumer'))
        for name in ['verify', 'verify_matching', 'verify_classes', 'verify_captures', 'verify_text_ops',
                     'verify_flags', 'verify_case', 'verify_escapes', 'verify_ascii_classes', 'verify_unicode',
                     'verify_boundaries', 'verify_properties', 'verify_scripts', 'verify_binary', 'verify_syntax',
                     'verify_errors', 'verify_limits', 'verify_bytes', 'verify_upstream_sample',
                     'verify_upstream_suite', 'verify_sets', 'verify_api_contracts', 'verify_hir',
                     'verify_ast', 'verify_pike', 'verify_props', 'verify_error_spans']:
            stages.append((name, [sys.executable, f'tests/{name}.py'], ROOT))
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
    print(f'Complete acceptance passed. Report: {STATUS}', flush=True)


if __name__ == '__main__':
    main()
