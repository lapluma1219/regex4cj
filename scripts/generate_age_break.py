"""Import pinned Unicode Age and break properties, or regenerate offline.

Age queries are cumulative from V1_1 through the requested age. Break
properties are exact sets. Unassigned age is an alias that stays an error.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

from generate_categories import parse_table
from generate_unicode import ROOT, REV, VERSION

SNAPSHOT = ROOT / 'data/unicode/age_break.json'
OUTPUT = ROOT / 'port/src/unicode_age_break.cj'
UPSTREAM = Path('regex-syntax/src/unicode_tables')
AGES = [
    'V1_1', 'V2_0', 'V2_1', 'V3_0', 'V3_1', 'V3_2', 'V4_0', 'V4_1', 'V5_0',
    'V5_1', 'V5_2', 'V6_0', 'V6_1', 'V6_2', 'V6_3', 'V7_0', 'V8_0', 'V9_0',
    'V10_0', 'V11_0', 'V12_0', 'V12_1', 'V13_0', 'V14_0', 'V15_0', 'V15_1',
    'V16_0',
]
BREAKS = [
    ('grapheme', 'grapheme_cluster_break.rs', 'Grapheme_Cluster_Break'),
    ('word', 'word_break.rs', 'Word_Break'),
    ('sentence', 'sentence_break.rs', 'Sentence_Break'),
]


def validate(data):
    if data['revision'] != REV or data['unicode_version'] != VERSION:
        raise ValueError('unexpected source version')
    if data['age_order'] != AGES:
        raise ValueError('age order drifted from the pinned chronological list')
    if set(data['ages']) != set(AGES):
        raise ValueError('age tables do not match the chronological list')
    if set(data['breaks']) != {'grapheme', 'word', 'sentence'}:
        raise ValueError('unexpected break properties')
    for ranges in list(data['ages'].values()) + [
        item for group in data['breaks'].values() for item in group['sets'].values()
    ]:
        last = -1
        for low, high in ranges:
            if not (0 <= low <= high <= 0x10FFFF and low > last):
                raise ValueError('invalid or overlapping scalar ranges')
            if low <= 0xDFFF and high >= 0xD800:
                raise ValueError('surrogate in scalar table')
            last = high
    for alias, target in data['age_aliases'].items():
        if target != 'Unassigned' and target not in data['ages']:
            raise ValueError('unknown age alias target: ' + target)
    if 'unassigned' not in data['age_aliases'] or data['age_aliases']['unassigned'] != 'Unassigned':
        raise ValueError('unassigned age alias missing')
    for group in data['breaks'].values():
        for target in group['aliases'].values():
            if target not in group['sets']:
                raise ValueError('break alias is not an exact set: ' + target)


def names_and_sets(text):
    header = text.split('];', 1)[0]
    found = re.findall(r'\("([A-Za-z0-9_]+)", ([A-Z0-9_]+)\),', header)
    if not found:
        raise ValueError('missing BY_NAME table')
    sets = {}
    for name, const in found:
        sets[name] = parse_table(text, const)
    return sets


def aliases(text, title):
    chunk = text.split('"%s",' % title, 1)[1].split('&[', 1)[1].split('],', 1)[0]
    found = {}
    for line in chunk.splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r'\s*\("([^"]+)", "([A-Za-z0-9_]+)"\),\s*', line)
        if not match:
            raise ValueError('unrecognized alias: ' + line)
        found[match[1]] = match[2]
    if not found:
        raise ValueError('empty alias table: ' + title)
    return found


def read_upstream(path):
    if subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD'], text=True).strip() != REV:
        raise ValueError('upstream checkout is not the pinned revision')
    data = {
        'revision': REV,
        'unicode_version': VERSION,
        'sources': {},
        'age_order': AGES,
        'ages': {},
        'age_aliases': {},
        'breaks': {},
    }
    files = ['age.rs', 'property_values.rs'] + [name for _, name, _ in BREAKS]
    texts = {}
    for name in files:
        file = str(UPSTREAM / name)
        raw = (path / file).read_bytes()
        committed = subprocess.check_output(['git', '-C', str(path), 'show', REV + ':' + file])
        if raw != committed:
            raise ValueError('modified upstream table: ' + name)
        text = raw.decode()
        if 'Unicode version: ' + VERSION + '.' not in text:
            raise ValueError('unexpected Unicode version: ' + name)
        data['sources'][name] = hashlib.sha256(raw).hexdigest()
        texts[name] = text
    data['ages'] = names_and_sets(texts['age.rs'])
    data['age_aliases'] = aliases(texts['property_values.rs'], 'Age')
    for key, filename, title in BREAKS:
        sets = names_and_sets(texts[filename])
        data['breaks'][key] = {
            'sets': sets,
            'aliases': {alias: target for alias, target in aliases(texts['property_values.rs'], title).items()
                        if target in sets},
        }
    validate(data)
    return data


def ranges(lines, values):
    lines[-1] += ' return CharSet(['
    for low, high in values:
        lines.append('            0x%X, 0x%X,' % (low, high))
    lines.append('        ])')


def render(data):
    lines = [
        'package regex4cj',
        '',
        '// Generated by scripts/generate_age_break.py; do not edit.',
        '// Unicode ' + VERSION + '; source revision ' + REV + '.',
        '// See data/unicode/LICENSE-UNICODE and THIRD_PARTY_NOTICES.md.',
        '// Age is the chronological union through the requested version.',
        '// Break properties are exact sets and do not perform segmentation.',
        'func unicodeAge(name: String): CharSet {',
        '    let canonical = match (name) {',
    ]
    grouped = {}
    for alias, target in sorted(data['age_aliases'].items()):
        grouped.setdefault(target, []).append(alias)
    for target, names in grouped.items():
        lines.append('        case ' + ' | '.join('"%s"' % item for item in names) + ' => "' + target + '"')
    lines += [
        '        case _ => throw Exception("Unicode property value not found: " + name)',
        '    }',
        '    if (canonical == "Unassigned") {',
        '        throw Exception("Unicode property value not found: " + name)',
        '    }',
        '    let result = CharSet()',
        '    for (age in [' + ', '.join('"%s"' % age for age in data['age_order']) + ']) {',
        '        result.unionWith(ageSet(age))',
        '        if (age == canonical) {',
        '            return result',
        '        }',
        '    }',
        '    throw Exception("Unicode property value not found: " + name)',
        '}',
        '',
        'func ageSet(name: String): CharSet {',
        '    match (name) {',
    ]
    for age in data['age_order']:
        lines.append('        case "%s" =>' % age)
        ranges(lines, data['ages'][age])
    lines += [
        '        case _ => throw Exception("Unicode property value not found: " + name)',
        '    }',
        '}',
        '',
    ]
    functions = {
        'grapheme': 'graphemeClusterBreak',
        'word': 'wordBreak',
        'sentence': 'sentenceBreak',
    }
    for key, function in functions.items():
        group = data['breaks'][key]
        lines += ['func %s(name: String): CharSet {' % function, '    match (name) {']
        grouped = {}
        for alias, target in sorted(group['aliases'].items()):
            grouped.setdefault(target, []).append(alias)
        for target, names in grouped.items():
            lines.append('        case ' + ' | '.join('"%s"' % item for item in names) + ' =>')
            ranges(lines, group['sets'][target])
        lines += [
            '        case _ => throw Exception("Unicode property value not found: " + name)',
            '    }',
            '}',
            '',
        ]
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--upstream', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = read_upstream(args.upstream) if args.upstream else json.loads(SNAPSHOT.read_text())
    validate(data)
    snapshot = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    output = render(data)
    if args.check:
        if args.upstream and SNAPSHOT.read_text() != snapshot:
            raise ValueError('snapshot differs from upstream')
        if OUTPUT.read_text() != output:
            raise ValueError('generated age/break table is stale')
    else:
        if args.upstream:
            SNAPSHOT.write_text(snapshot)
        OUTPUT.write_text(output)


if __name__ == '__main__':
    main()
