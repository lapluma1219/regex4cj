"""Rebuild explicit Cangjie public declarations, not a compatibility percentage.

This declaration scanner is for the current source layout, not a full Cangjie
parser. Inherited members and enum variants are not counted as callables.
"""
import argparse
import collections
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def inventory():
    result = []
    for path in sorted((ROOT / 'port/src').glob('*.cj')):
        lines = path.read_text().splitlines()
        owner, exposed = '顶层函数', True
        for i, line in enumerate(lines):
            t = re.match(r'(public )?(class|enum|struct) (\w+)', line)
            if t:
                owner, exposed = t[3], bool(t[1])
                if exposed:
                    result.append(dict(owner=owner, name=owner, kind=t[2], signature=line.split(' {')[0],
                                       file=str(path.relative_to(ROOT)), line=i+1))
            m = re.match(r'(\s*)public\s+(?:(?:static|override)\s+)?(func\s+(\w+)|init\s*\(|(?:let|var)\s+(\w+))', line)
            if not m or (m[1] and not exposed):
                continue
            kind = 'field' if m[4] else 'constructor' if m[2].startswith('init') else 'method' if m[1] else 'function'
            signature = line.strip()
            if kind != 'field':
                j = i
                while '{' not in signature and j+1 < len(lines):
                    j += 1
                    signature += ' ' + lines[j].strip()
                signature = signature.split('{', 1)[0].rstrip()
            result.append(dict(owner=owner if m[1] else '顶层函数', name=m[4] or m[3] or 'init', kind=kind,
                               signature=signature, file=str(path.relative_to(ROOT)), line=i+1))
    return result

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--check', action='store_true'); args = ap.parse_args()
    items = inventory(); counts = collections.Counter(x['kind'] for x in items)
    callables = sum(counts[k] for k in ['method','constructor','function'])
    data = dict(scope='Explicit declarations in port/src/*.cj; not Rust parity or a completion percentage.',
                counts=dict(counts), callable_count=callables, items=items)
    doc = f'''# 当前仓颉公开接口清单

由`scripts/generate_api_catalog.py`从仓库源码生成；可用`--check`检查是否过期。

当前显式公开调用入口 **{callables}** 个，公开字段（含var） **{counts['field']}** 个；类型数量见下表。重复名称在不同类型/重载上分别计数，不计继承方法，不把枚举分支当作函数。

这是声明扫描，不是完整语言解析器，也不是原仓库覆盖率。主要库的170条固有方法映射仍见[接口审计](api-audit.md)，语法/自动机的差异见[复核结论](review-2026-10-04.md)。调用行为见[API](api.md)与[语法说明](hir.md)。

| 类别 | 数量 |
|---|---:|
'''
    for kind, count in sorted(counts.items()): doc += f'| {kind} | {count} |\n'
    for owner in sorted(set(x['owner'] for x in items)):
        doc += f'\n## {owner}\n\n| 声明 | 种类 | 实现 |\n|---|---|---|\n'
        for x in items:
            if x['owner'] != owner: continue
            sig = x['signature'].replace('|', '&#124;')
            doc += f"| `{sig}` | {x['kind']} | [{x['file']}:{x['line']}](../{x['file']}#L{x['line']}) |\n"
    outputs = {'docs/cangjie-api-inventory.json':json.dumps(data,ensure_ascii=False,indent=2)+'\n',
               'docs/api-catalog.md':doc}
    for name, text in outputs.items():
        p = ROOT / name
        if args.check:
            if not p.exists() or p.read_text() != text: raise SystemExit(f'Stale catalog: {name}')
        else: p.write_text(text)
    print(f'Cangjie declarations: {callables} callables, {counts["field"]} fields')

if __name__ == '__main__': main()
