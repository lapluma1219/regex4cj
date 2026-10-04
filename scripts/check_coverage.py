"""Check the weighted ledger. Only 验收通过 adds points. Do not treat this sum as a published percentage."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / 'docs/coverage/ledger.json'
ALLOWED = {'未开始', '实现中', '有差异', '验收通过'}


def main():
    data = json.loads(LEDGER.read_text())
    items = data['items']
    ids = [item['id'] for item in items]
    if len(ids) != len(set(ids)):
        raise SystemExit('duplicate ledger id')
    total = sum(item['weight'] for item in items)
    if total != 100:
        raise SystemExit(f'weights sum to {total}, expected 100')
    accepted = 0
    for item in items:
        if item['status'] not in ALLOWED:
            raise SystemExit(f"bad status for {item['id']}")
        if item['status'] == '验收通过':
            if not item['evidence']:
                raise SystemExit(f"{item['id']} is accepted without evidence")
            for path in item['evidence']:
                if not (ROOT / path).is_file():
                    raise SystemExit(f'missing evidence {path}')
            accepted += item['weight']
    locked = data['locked_before_implementation']
    for key in ('A5', 'C4', 'E'):
        if key not in locked or not locked[key].strip():
            raise SystemExit(f'{key} selection is not locked')
    print(f'coverage ledger: weight 100, accepted {accepted}, locked A5/C4/E')


if __name__ == '__main__':
    main()
