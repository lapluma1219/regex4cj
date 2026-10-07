"""Functional test catalog: explicit cases, legacy suite evidence, and API ownership.

No test-file presence or name occurrence is interpreted as behavioral coverage.
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load():
    catalog = json.loads((ROOT / 'tests/catalog/features.json').read_text())
    cases = [case for group in catalog['groups'] for case in json.loads((ROOT / group['cases']).read_text())]
    return catalog, cases


def validate(catalog, cases):
    groups = catalog['groups']
    ids = [g['id'] for g in groups]
    assert len(ids) == len(set(ids)), 'duplicate group'
    suites = [f['suite'] for g in groups for f in g['features']]
    assert len(suites) == len(set(suites)), 'duplicate suite ownership'
    discovered = {str(p.relative_to(ROOT)) for p in (ROOT / 'tests/functional').rglob('verify*.py')}
    # Named cases have their own runner, not a legacy suite.
    assert set(suites) == discovered, f'unmapped suites: {set(suites) ^ discovered}'
    sources = [p for g in groups for p in g['source_files']]
    assert len(sources) == len(set(sources)), 'duplicate source ownership'
    assert set(sources) == {str(p.relative_to(ROOT)) for p in (ROOT / 'port/src').glob('*.cj')}, 'source ownership changed'
    case_ids = [c['id'] for c in cases]
    assert len(case_ids) == len(set(case_ids)), 'duplicate case ID'
    for c in cases:
        assert c['group'] in ids and c['feature'] and c['basis'], c
        assert c['expect_error'] or isinstance(c['expected_stdout'], str), c
    declarations = json.loads((ROOT / 'docs/cangjie-api-inventory.json').read_text())['items']
    for case in cases:
        for ref in case.get('api_refs', []):
            matches = [i for i in declarations if i['owner'] + '.' + i['name'] == ref and i['kind'] in ('method', 'function')]
            assert len(matches) == 1, f'unknown or ambiguous API reference: {ref}'
    native = json.loads((ROOT / 'tests/catalog/native.json').read_text())
    actual = {(str(p.relative_to(ROOT)), m[1])
              for p in (ROOT/'examples/consumer/src').glob('*test.cj')
              for m in re.finditer(r'@Test\s+func\s+(\w+)', p.read_text())}
    listed = {(n['file'], n['id']) for n in native}
    assert len(listed) == len(native) and listed == actual, 'native test catalog drift'
    assert all(n['group'] in ids for n in native), 'unknown native group'
    return suites


def api_group(item, groups):
    name = item['name'].lower()
    owner = item['owner'].lower()
    # Override source ownership for public operations implemented in shared files.
    if any(x in name or x in owner for x in ('replace', 'split', 'expand')):
        return 'text'
    if item['file'] == 'port/src/nfa.cj' and 'capture' in name:
        return 'capture'
    return next(g['id'] for g in groups if item['file'] in g['source_files'])


def documents(catalog, cases, run=None, case_results=None):
    groups = catalog['groups']
    stages = {s['name']: s['status'] for s in (run or {}).get('stages', [])}
    results = {c['id']: c['status'] for c in (case_results or {}).get('cases', [])}
    lines = ['# 按功能阅读测试', '',
             '运行命令见 [README](../README.md)，已归档结果见 [测试结果](test-coverage.md)。本页是自动生成的案例目录，静态目录不表示实际运行结果。', '',
             '本目录区分**功能组 → 特性 → 具体案例**与尚未细分的批量回归证据。一个脚本可以覆盖多个特性；其通过不能证明整组功能完整。', '',
             '具名案例含输入、操作和独立预期，同时与固定 Rust 版本对照。批量套件保持原断言、固定种子、语料和跳过规则，不重复计数。', '',
             '当前全部公开声明均有功能归属，但归属不是行为验证。逐接口特性审计尚未完成。完整声明见 [接口清单](api-catalog.md)，案例中的 `api_refs` 记录已核实的部分特性关联。', '',
             '范围边界以 [当前能力](status.md) 为准：不支持与未验证分开看；下列未验证项不表示功能不存在。', '']
    if run:
        lines += [f"运行编号：`{run['run_id']}`；本次结果：**{run['status']}**。未运行与失败分开显示。", '', run.get('scope', '完整验收'), '']
    native = json.loads((ROOT / 'tests/catalog/native.json').read_text())
    for g in groups:
        lines += [f"## {g['title']}", '', '### 已具名的特性与案例', '']
        selected = [c for c in cases if c['group'] == g['id']]
        if not selected:
            lines += ['尚未拆出独立 JSON 案例；已有仓颉原生案例与批量证据见下方，不据此宣称全部特性通过。', '']
        else:
            lines += ['| 案例 | 特性 | 输入（规则；文本） | 结果 |', '|---|---|---|---|']
            for c in selected:
                inp = json.dumps(c.get('args', [c['pattern'], c['text']]), ensure_ascii=False).replace('|', '&#124;')
                lines += [f"| `{c['id']}` | {c['feature']} | `{inp}` | {results.get(c['id'], ('未执行' if run else '未运行（静态目录）'))} |"]
            lines += ['', f"操作、附加参数及完整预期见 [案例数据](../{g['cases']})。", '']
        lines += ['### 保留的批量回归证据', '', '| 验证范围 | 测试文件 | 本次套件结果 |', '|---|---|---|']
        for f in g['features']:
            lines += [f"| {f['title']} | [{f['id']}](../{f['suite']}) | {stages.get(f['id'], ('未执行' if run else '未运行（静态目录）'))} |"]
        lines += ['', '### 仓颉原生特性案例', '', '| 特性 | 测试函数 | 执行证据 |', '|---|---|---|']
        for n in native:
            if n['group'] == g['id']:
                lines += [f"| {n['feature']} | [{n['id']}](../{n['file']}) | consumer-test 整套：{stages.get('consumer-test', ('未执行' if run else '未运行（静态目录）'))} |"]
        lines += ['', '**未验证清单：** 尚未逐项关联所有公开接口与具体断言；未穷举配置交互、异常分支及极端输入。已有明确限制见当前能力文档。', '']
    lines += ['## 构建与交付（不计为功能特性通过）', '',
              '完整验收另执行数据一致性、接口清单、Python 工具测试、Rust/仓颉构建、仓颉原生测试及演示。', '',
              '跨平台、性能基准及代码分支覆盖率未纳入本流程。验收摘要与测量口径见 [测试结果](test-coverage.md)。运行方式见 [README](../README.md)。', '',
              '报告只展示实际执行结果，不生成原仓库完成百分比，也不把套件通过提升成全部特性通过。', '']
    items = json.loads((ROOT / 'docs/cangjie-api-inventory.json').read_text())['items']
    api = ['# 公开接口的功能归属', '', '由当前声明清单生成。包括重载、字段与类型；每条独立保留。', '',
           '**归属不等于测试覆盖。** 现有批量案例可能调用这些接口，但尚未逐条核实到具体断言，已经核实调用路径的接口关联到具名案例；其余标为待审计。关联只证明所列特性，不代表接口全部行为覆盖。', '',
           '| 功能组 | 类型 | 声明 | 源码 | 逐接口行为证据 |', '|---|---|---|---|---|']
    for item in items:
        group = api_group(item, groups)
        sig = item['signature'].replace('|','&#124;')
        refs = [c['id'] for c in cases if item['owner'] + '.' + item['name'] in c.get('api_refs', [])]
        evidence = '部分特性案例：' + ', '.join('`'+ref+'`' for ref in refs) if refs else '待逐项审计'
        api += [f"| {next(g['title'] for g in groups if g['id']==group)} | {item['owner']} | `{sig}` | [{item['file']}:{item['line']}](../{item['file']}#L{item['line']}) | {evidence} |"]
    return '\n'.join(lines), '\n'.join(api)+'\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--run', type=Path)
    ap.add_argument('--cases', type=Path)
    ap.add_argument('--output', type=Path)
    args = ap.parse_args()
    catalog, cases = load()
    suites = validate(catalog, cases)
    run = json.loads(args.run.read_text()) if args.run else None
    case_results = json.loads(args.cases.read_text()) if args.cases else None
    if run is not None:
        assert case_results and run['run_id'] == case_results['run_id'], 'case results belong to a different run'
    doc, api = documents(catalog, cases, run, case_results)
    outputs = {args.output: doc} if args.output else {ROOT/'docs/testing.md':doc}
    for path, content in outputs.items():
        if args.check:
            assert path.exists() and path.read_text() == content, f'stale catalog: {path}'
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    print(f'Functional catalog: {len(catalog["groups"])} groups; {len(cases)} named cases; {len(suites)} preserved suites. No coverage percentage inferred.')


if __name__ == '__main__':
    main()
