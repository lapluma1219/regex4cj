"""Run instrumented acceptance in a fresh copy; aggregate executable lines only.

Compiler instrumentation reports execution, not correctness or Rust parity.
Public declaration mapping deliberately leaves unmatched entries unmeasured.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def parse_gcov(paths):
    lines, functions = {}, {}
    for path in paths:
        source, pending = None, None
        for row in path.read_text(errors='replace').splitlines():
            if ':Source:' in row:
                raw = row.split(':Source:', 1)[1]
                if '/port/src/' not in raw and not raw.startswith('port/src/'):
                    source = None
                else:
                    source = 'port/src/' + Path(raw).name
            if not source:
                continue
            match = re.match(r'function (.+) called (\d+)', row)
            if match:
                pending = int(match[2])
                continue
            match = re.match(r'\s*([^:]+):\s*(\d+):(.*)', row)
            if not match or int(match[2]) == 0:
                continue
            key = (source, int(match[2]))
            if pending is not None:
                functions[key] = max(functions.get(key, 0), pending)
                pending = None
            count = match[1].strip().rstrip('*')
            if count in ('#####', '=====') or count.isdigit():
                lines[key] = lines.get(key, False) or (count.isdigit() and int(count) > 0)
    return lines, functions


def summarize(paths, inventory):
    lines, functions = parse_gcov(paths)
    if not lines:
        raise RuntimeError('No library coverage records; check gcda/gcno pairing')
    files = []
    for source in sorted({s for s, _ in lines}):
        relevant = {n: hit for (s, n), hit in lines.items() if s == source}
        files.append(dict(file=source, executable_lines=len(relevant), hit_lines=sum(relevant.values()),
                          missed_lines=[n for n, hit in sorted(relevant.items()) if not hit]))
    entries = []
    for item in inventory:
        if item['kind'] not in ('method', 'function', 'constructor'):
            continue
        calls = functions.get((item['file'], item['line']))
        entries.append(dict(**item, execution='unmeasured' if calls is None else 'hit' if calls else 'missed'))
    return dict(scope='Execution coverage of this implementation, not behavior completeness or Rust parity.',
                executable_lines=len(lines), hit_lines=sum(lines.values()),
                line_percent=round(100 * sum(lines.values()) / len(lines), 2),
                public_entries=len(entries), public_hit=sum(e['execution']=='hit' for e in entries),
                public_missed=sum(e['execution']=='missed' for e in entries),
                public_unmeasured=sum(e['execution']=='unmeasured' for e in entries),
                files=files, entries=entries)


def prepare_workspace(source, destination):
    for folder in ["port", "cli", "oracle", "tests", "scripts", "examples", "data", "docs"]:
        shutil.copytree(source/folder, destination/folder,
                        ignore=shutil.ignore_patterns("target", "__pycache__", "cov_output", "*.gcda", "*.gcno", "*.gcov"))
    # Showcase reads the release version when writing its result.
    shutil.copy2(source/"VERSION", destination/"VERSION")


def main():
    output = ROOT / '.build/coverage'
    output.mkdir(parents=True, exist_ok=True)
    sandbox = Path(tempfile.mkdtemp(prefix='run-', dir=output))
    (output/'latest.json').unlink(missing_ok=True)
    prepare_workspace(ROOT, sandbox)
    print(f'Running full instrumented acceptance; log: {output / "latest.log"}', flush=True)
    env = os.environ.copy()
    env.update(REGEX4CJ_LOCAL=str(sandbox/'.build'), REGEX4CJ_COVERAGE='1')
    env.setdefault('CARGO_TARGET_DIR', str(ROOT/'.build/work/rust-target'))
    log = output/'latest.log'
    with log.open('w') as stream:
        result = subprocess.run(['bash', 'scripts/run.sh', 'verify'], cwd=sandbox, env=env,
                                stdout=stream, stderr=subprocess.STDOUT)
    if result.returncode:
        raise SystemExit(f'Coverage acceptance failed: {log}; workspace: {sandbox}')
    # Native tests and CLI each use independently compiled library profiles.
    pairs = [(sandbox/'0-regex4cj.gcda', sandbox/'cli'),
             (sandbox/'examples/consumer/0-regex4cj.gcda', sandbox/'examples/consumer/cov_output/regex_consumer')]
    for data, target in pairs:
        if not data.exists():
            data = target/'0-regex4cj.gcda'
        if not data.exists() or not (target/'0-regex4cj.gcno').exists():
            raise RuntimeError(f'Missing instrumentation: {data} or {target}')
        if data != target/data.name:
            shutil.copy2(data, target/data.name)
    with log.open('a') as stream:
        subprocess.run(['cjcov', '-r', '.', '-s', 'port/src', '-o', 'coverage-report', '-j', '-b',
                        '--html-details', '-k'], cwd=sandbox, env=env, stdout=stream, stderr=subprocess.STDOUT, check=True)
    inventory = json.loads((sandbox/'docs/cangjie-api-inventory.json').read_text())['items']
    report = summarize(sandbox.rglob('*.gcov'), inventory)
    run = json.loads((sandbox/'.build/work/verification-run.json').read_text())
    report.update(run_id=run['run_id'], status=run['status'], environment=run['environment'],
                  tested_source_sha256=run['tested_source_sha256'], workspace=str(sandbox))
    changed = [name for name, digest in report['tested_source_sha256'].items()
               if not (ROOT/name).exists() or hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest]
    if changed:
        raise RuntimeError(f'Source changed during coverage run: {changed}')
    (output/'latest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print(f"Coverage acceptance passed: {report['hit_lines']}/{report['executable_lines']} lines ({report['line_percent']}%).")
    print(f"Public entries: {report['public_hit']} hit, {report['public_missed']} missed, {report['public_unmeasured']} unmeasured.")
    print(f'Report: {output / "latest.json"}; detailed HTML: {sandbox / "coverage-report"}')


if __name__ == '__main__':
    main()
