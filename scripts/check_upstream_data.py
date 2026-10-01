"""Check vendored data integrity, revision and the exact suite input inventory."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'tests/upstream'
manifest = json.loads((DATA / 'manifest.json').read_text())
baseline = json.loads((ROOT / 'docs/baseline.json').read_text())
assert manifest['revision'] == baseline[manifest['repository']], 'upstream revision mismatch'
source = (ROOT / 'oracle/src/suite.rs').read_text().split('];', 1)[0]
required = {'testdata/' + name + '.toml' for name in re.findall(r'"([\w/-]+)"', source)}
assert required == {name for name in manifest['files'] if name.endswith('.toml')}, 'suite inventory mismatch'
for name, expected in manifest['files'].items():
    assert hashlib.sha256((DATA / name).read_bytes()).hexdigest() == expected, name
actual = {str(p.relative_to(DATA)) for p in (DATA / 'testdata').rglob('*') if p.is_file()}
assert actual == {name for name in manifest['files'] if name.startswith('testdata/')}, 'unexpected data files'
print(f'Pinned upstream data verified: {len(required)} test files')
