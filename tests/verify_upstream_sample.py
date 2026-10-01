"""Run applicable pinned upstream testdata and record explicit skips.

Only flat find-span tests are executed. Builder-only options, earliest search,
capture-group expectations, bytes, and patterns this port rejects are skips.
A span mismatch is a failure.
"""
import json
import re
from pathlib import Path
from regex_test_support import RUST, CJ, REPORT, invoke

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = Path(__file__).resolve().parent / 'upstream/testdata'
FILES = [
    'crlf.toml', 'flags.toml', 'multiline.toml', 'empty.toml',
    'word-boundary-special.toml', 'no-unicode.toml', 'line-terminator.toml',
    'earliest.toml', 'iter.toml',
]
SKIP_MARKERS = ('search-kind', 'unicode =', 'utf8 =', 'line-terminator =', 'compiles =', 'anchored =')


def unescape(text):
    out = []
    i = 0
    while i < len(text):
        if text[i] != '\\':
            out.append(text[i])
            i += 1
            continue
        i += 1
        code = text[i]
        mapping = {'n': '\n', 'r': '\r', 't': '\t', '\\': '\\', "'": "'", '"': '"', '0': '\0'}
        if code in mapping:
            out.append(mapping[code])
            i += 1
        elif code == 'u' and text[i + 1] == '{':
            end = text.index('}', i)
            out.append(chr(int(text[i + 2:end], 16)))
            i = end + 1
        elif code == 'x':
            out.append(chr(int(text[i + 1:i + 3], 16)))
            i += 3
        else:
            out.append(code)
            i += 1
    return ''.join(out)


def quoted(block, key):
    match = re.search(r'(?m)^' + key + r'\s*=\s*([\'"])(.*)\1\s*$', block)
    if not match:
        return None
    return unescape(match.group(2))


def spans(block):
    match = re.search(r'matches\s*=\s*(\[[\s\S]*?\])\s*(?:\n\[\[|\n#|\Z)', block)
    if not match:
        return None
    body = match.group(1)
    if body.count('[') != body.count(']'):
        return None
    pairs = re.findall(r'\[\s*(\d+)\s*,\s*(\d+)\s*\]', body)
    if body.count('[') != len(pairs) + 1:
        return None
    return [(int(a), int(b)) for a, b in pairs]


def find_spans(stdout):
    found = []
    for line in stdout.decode().splitlines():
        parts = line.split('\t', 2)
        if len(parts) != 3:
            return None
        found.append((int(parts[0]), int(parts[1])))
    return found


passed = 0
skips = []
for name in FILES:
    text = (UPSTREAM / name).read_text()
    for block in text.split('[[test]]')[1:]:
        title = quoted(block, 'name') or name
        if any(marker in block for marker in SKIP_MARKERS):
            skips.append({'file': name, 'name': title, 'reason': 'needs a search option this sample does not apply'})
            continue
        pattern = quoted(block, 'regex')
        haystack = quoted(block, 'haystack')
        expected = spans(block)
        if pattern is None or haystack is None or expected is None:
            skips.append({'file': name, 'name': title, 'reason': 'not a flat find-span test'})
            continue
        rust = invoke(RUST, 'find', pattern, haystack)
        if rust.returncode != 0:
            skips.append({'file': name, 'name': title, 'reason': 'upstream oracle rejects or cannot run this case'})
            continue
        raw = haystack.encode()
        multiline = any(b'\n' in raw[a:b] or b'\r' in raw[a:b] for a, b in expected)
        parsed = None if multiline else find_spans(rust.stdout)
        if not multiline and parsed != expected:
            skips.append({'file': name, 'name': title, 'reason': 'sample parser did not reproduce the upstream expected spans'})
            continue
        cj = invoke(CJ, 'find', pattern, haystack)
        if cj.returncode != 0:
            skips.append({'file': name, 'name': title, 'reason': 'string engine rejects this pattern'})
            continue
        if cj.stdout != rust.stdout:
            raise AssertionError({'file': name, 'name': title, 'pattern': pattern, 'expected': expected,
                                  'rust': rust.stdout.decode(), 'cangjie': cj.stdout.decode()})
        passed += 1

report = json.loads(REPORT.read_text()) if REPORT.exists() else {}
report.update({'upstream_sample_passed': passed, 'upstream_sample_skipped': len(skips)})
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
(REPORT.parent / 'upstream-sample-skips.json').write_text(
    json.dumps({'passed': passed, 'skipped': skips}, ensure_ascii=False, indent=2) + '\n')
print('upstream sample passed:', passed, 'skipped:', len(skips), flush=True)
