"""Execute one registered functional suite with shared helpers on the import path."""
from pathlib import Path
import runpy
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
sys.path.insert(0, str(ROOT / 'tests/support'))
from feature_catalog import load, validate

if __name__ == '__main__':
    catalog, cases = load()
    suites = validate(catalog, cases)
    if len(sys.argv) != 2 or sys.argv[1] not in suites:
        raise SystemExit('Usage: python3 tests/run_suite.py REGISTERED_SUITE_PATH (use scripts/env.sh first)')
    target = ROOT / sys.argv[1]
    sys.argv = [str(target)]
    runpy.run_path(str(target), run_name='__main__')
