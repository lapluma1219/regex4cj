"""Decode the tab-separated capture test protocol for a human-readable demo."""
import json
import sys

def decode(value):
    return bytes.fromhex(value).decode('utf-8')

for raw in sys.stdin:
    fields = raw.rstrip('\n').split('\t')
    kind = fields[0]
    if kind == 'groups':
        print('分组数（包括完整匹配 0）：' + fields[1])
    elif kind == 'name':
        print('组 {} 的名称：{}'.format(fields[1], decode(fields[2])))
    elif kind == 'match':
        print('匹配：')
    elif kind in ('group', 'named'):
        label = fields[1] if kind == 'group' else decode(fields[1])
        if fields[2] == '-':
            print('  {}：未参与匹配'.format(label))
        else:
            print('  {}：[{}, {}) {}'.format(label, fields[2], fields[3],
                  json.dumps(decode(fields[4]), ensure_ascii=False)))
