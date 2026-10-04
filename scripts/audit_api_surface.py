"""Extract the pinned top-level inherent-method surface and its curated mapping.

This is a source inventory, not a Rust parser or a semantic coverage percentage.
--upstream regenerates from verified Git objects; --check needs only this repo.
Trait/macro/feature contracts are reviewed separately in docs/api-audit.md.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = ROOT / 'docs/api-audit-inventory.json'
SOURCES = ['src/regex/string.rs', 'src/regex/bytes.rs', 'src/regexset/string.rs',
           'src/regexset/bytes.rs', 'src/builders.rs', 'src/lib.rs', 'src/bytes.rs',
           'src/error.rs', 'src/pattern.rs', 'Cargo.toml']


def camel(name):
    words = name.split('_')
    return words[0] + ''.join(word.title() for word in words[1:])


def mapping(scope, owner, method):
    byte = scope == 'bytes'
    cjtype = {'Regex': 'BytesRegex' if byte else 'Regex',
              'Match': 'BytesMatch' if byte else 'RegexMatch',
              'Captures': 'BytesCaptures' if byte else 'Captures',
              'CaptureLocations': 'CaptureLocations', 'SetMatches': 'SetMatches',
              'RegexSet': 'BytesRegexSet' if byte else 'RegexSet',
              'RegexBuilder': 'BytesRegexBuilder' if byte else 'RegexBuilder',
              'RegexSetBuilder': 'BytesRegexSetBuilder' if byte else 'RegexSetBuilder'}[owner]
    member = camel(method)
    status, note = '有样例验证', '证据仅覆盖所列测试的输入，不代表任意输入的等价证明。'
    evidence = ['tests/verify_api_contracts.py']
    if owner == 'Regex':
        member = {'new':'init', 'find_iter':'findIter',
                  'captures_iter':'capturesIter',
                  'split':'splitIter', 'splitn':'splitNIter',
                  'replacen':'replaceN', 'read_captures_at':'capturesReadAt',
                  'locations':'captureLocations'}.get(method, member)
        if method in ['read_captures_at','locations']:
            status, note = '有明确差异', '上游 doc(hidden) 的历史别名；仓颉使用对应的新名称。'
        if method in ['replace','replace_all','replacen']:
            evidence = ['tests/verify_bytes.py' if byte else 'tests/verify_text_ops.py', 'tests/verify_api_contracts.py']
            note = '模板走此方法；NoExpand 用 replaceLiteral，闭包用 replaceWith；无通用 Replacer trait 或 Cow 借用优化。'
        if method in ['find','is_match','captures','new']:
            evidence = ['tests/verify_upstream_suite.py', 'tests/verify_bytes.py' if byte else 'tests/verify_captures.py']
        if method in ['shortest_match','shortest_match_at']:
            status, note = '有明确差异', '早停终点允许依赖内部引擎；不承诺逐输入与 Rust meta 的终点相等，也不承诺数学最短。'
            evidence = ['tests/verify_syntax.py'] if not byte else []
        if method in ['capture_names','captures_len','static_captures_len','as_str','capture_locations']:
            evidence = ['examples/consumer/src/api_test.cj', 'tests/verify_captures.py']
            if byte and method in ['static_captures_len','capture_names','as_str']:
                status, note, evidence = '有样例验证', 'bytes metadata 已有专项样例对照。', ['tests/verify_api_contracts.py']
        if byte and method in ['find_at','is_match_at','captures_at']:
            status, note, evidence = '有样例验证', '覆盖原始字节、NUL、非法 UTF-8 和逐字节非零起点。', ['tests/verify_api_contracts.py']
    elif owner == 'Match':
        member = {'as_bytes':'bytes','range':'start'}.get(method, member)
        if method in ['range','as_bytes','start','end']:
            status, note = '有明确差异', '使用公开字段读取；range 用 start/end 构造。bytes 为可变数组，不是 Rust 只读借用切片。'
        if method in ['is_empty','len']:
            evidence = ['examples/consumer/src/api_test.cj']
            if byte: status, note, evidence = '有样例验证', 'bytes 空匹配和长度有专项测试。', ['tests/verify_api_contracts.py','examples/consumer/src/api_test.cj']
    elif owner == 'Captures':
        member = {'len':'size'}.get(method, member)
        evidence = ['tests/verify_captures.py','tests/verify_text_ops.py'] if not byte else ['tests/verify_bytes.py','examples/consumer/src/api_test.cj']
        if method in ['extract','expand','len']:
            status, note = '有明确差异', 'extract 用运行时数量并返回含组0的数组；expand 返回新结果而非追加缓冲；len 用 size 字段。'
        if byte and method in ['extract','iter']:
            status, note, evidence = '有样例验证', '有 bytes 固定组提取和组迭代差分，及缺席组/结束/变长拒绝的原生测试。', ['tests/verify_api_contracts.py','examples/consumer/src/api_test.cj']
        if method == 'expand':
            member, status = 'expandInto', '有样例验证'
            note = '向已有StringBuilder或ArrayList追加展开结果，保留前缀；原expand便捷接口仍返回新结果。'
            evidence = ['tests/verify_api_contracts.py','examples/consumer/src/append_builder_test.cj']
    elif owner == 'CaptureLocations':
        member = {'len':'size','pos':'get'}.get(method, member)
        if method != 'get': status, note = '有明确差异', 'len 对应 size 字段；doc(hidden) pos 别名对应 get。'
    elif owner == 'RegexSet':
        member = {'new':'init','empty':'init','read_matches_at':'matchesReadAt'}.get(method, member)
        evidence = ['tests/verify_sets.py','tests/verify_upstream_suite.py','tests/verify_api_contracts.py']
        if method in ['empty','read_matches_at']:
            status, note = '有明确差异', 'empty 用空数组构造；doc(hidden) read_matches_at 使用 matchesReadAt 名称。'
        if byte and method in ['matches_at','is_match_at']:
            status, note, evidence = '有样例验证', 'bytes Set 非零起点和原始字节组合已专项对照。', ['tests/verify_api_contracts.py']
    elif owner == 'SetMatches':
        evidence = ['tests/verify_sets.py','examples/consumer/src/set_test.cj']
        if method == 'iter':
            status, note = '有样例验证', 'SetMatchesIter 支持 next/nextBack 交错、耗尽后持续 None、clone 后独立游标；不复刻 Rust 借用或 IntoIterator trait。'
            evidence = ['tests/verify_api_contracts.py','examples/consumer/src/set_test.cj']
    else:
        member = 'init' if method == 'new' else member
        evidence = ['examples/consumer/src/api_test.cj','tests/verify_syntax.py','tests/verify_limits.py']
        if method == 'new' and owner == 'RegexSetBuilder':
            status, note = '有样例验证', '支持直接从规则数组构造并保留快照，也保留无参构造和pattern追加；build时编译。'
            evidence = ['tests/verify_api_contracts.py','examples/consumer/src/append_builder_test.cj']
        elif method == 'dfa_size_limit':
            status, note = '有明确差异', '不是上游 DFA 缓存限额：字符串 Regex 使用步进缓存；bytes 忽略；Set 不提供同等 DFA。'
        elif method == 'line_terminator':
            status, note = '有明确差异', '参数为 Rune，再检查 0..255；上游参数为 u8。'
        elif method == 'size_limit':
            status, note = '有明确差异', '模拟上游 Thompson 构造预算并通过部分阈值对照；不保证所有启发式/限额接受边界相等。'
        elif byte and method not in ['new','build','case_insensitive','unicode'] or owner == 'RegexSetBuilder' and method not in ['new','build','case_insensitive']:
            status, note, evidence = '有样例验证', '四种 Builder 显式设置全部选项，覆盖16组配置、6种模式；有限样例不证明所有组合。', ['tests/verify_api_contracts.py']
        elif method in ['new','build','case_insensitive']:
            evidence = ['tests/verify_api_contracts.py']
    return cjtype, member, status, note, evidence


def cj_symbols():
    symbols = {}
    for file in sorted((ROOT/'port/src').glob('*.cj')):
        owner = None
        for n, line in enumerate(file.read_text().splitlines(), 1):
            m = re.match(r'(?:public )?class (\w+)', line)
            if m: owner = m[1]
            m = re.match(r'\s*public (?:(?:override )?func|let|var) (\w+)', line)
            if not m and re.match(r'\s*public init\(', line):
                symbols.setdefault(f'{owner}.init', {'file':str(file.relative_to(ROOT)), 'line':n})
                if re.match(r'\s*public init\(patterns: Array<String>\)', line):
                    symbols[f'{owner}.init'] = {'file':str(file.relative_to(ROOT)), 'line':n}
            if m: symbols[f'{owner}.{m[1]}'] = {'file':str(file.relative_to(ROOT)), 'line':n}
    return symbols


def build(upstream):
    revision = json.loads((ROOT/'docs/baseline.json').read_text())['https://github.com/rust-lang/regex']
    methods, sources, types = [], {}, []
    symbols = cj_symbols()
    for file in SOURCES:
        raw = subprocess.check_output(['git','-C',str(upstream),'show',revision+':'+file])
        sources[file] = hashlib.sha256(raw).hexdigest()
        owner = None
        scope = 'bytes' if '/bytes.rs' in file else 'string'
        for n,line in enumerate(raw.decode().splitlines(),1):
            m=re.match(r'pub\(crate\) mod (\w+)',line)
            if m: scope=m[1]
            m=re.match(r'\s*pub (struct|enum|trait) (\w+)',line)
            if m: types.append({'scope':scope,'name':m[2],'kind':m[1],'file':file,'line':n})
            m=re.match(r'\s*impl(?:<.*>)?\s+(\w+)(?:<.*>)?\s*\{',line)
            if m: owner=m[1]
            m=re.match(r'\s*pub fn (\w+)',line)
            if not m or owner is None or file not in SOURCES[:5]: continue
            name=m[1]; cjtype,member,status,note,evidence=mapping(scope,owner,name)
            key=f'{cjtype}.{member}'
            assert key in symbols, key
            methods.append({'id':f'{scope}::{owner}::{name}', 'upstream_file':file,'upstream_line':n,
                            'cangjie':key,'implementation':symbols[key], 'status':status,'note':note,'evidence':evidence})
    return {'revision':revision,'source_sha256':sources,'public_declarations':types,'methods':methods,
            'additional_surface':'Root escape, macros, traits and feature gates are classified in docs/api-audit.md; these method counts are NOT a completion percentage.'}


def render(data):
    lines = ['# 顶层接口逐项对应表', '', '由 `scripts/audit_api_surface.py --upstream PATH` 从固定 Git 提交提取。状态定义、trait 与宏审计见 [审计说明](api-audit.md)。样例验证不等于完整语义证明；170 是方法条目数，不是完成率。', '']
    group = None
    for row in data['methods']:
        current = row['id'].rsplit('::', 1)[0]
        if current != group:
            group = current
            lines += ['## ' + group, '', '| 上游方法 | 仓颉入口 | 状态 | 差异或证据 |', '|---|---|---|---|']
        source = f"https://github.com/rust-lang/regex/blob/{data['revision']}/{row['upstream_file']}#L{row['upstream_line']}"
        impl = row['implementation']
        local = '../' + impl['file'] + '#L' + str(impl['line'])
        evidence = '、'.join(f"[{Path(p).name}](../{p})" for p in row['evidence'])
        detail = row['note'] + (' 验证：' + evidence if evidence else '')
        lines.append(f"| [{row['id'].rsplit('::',1)[1]}]({source}) | [{row['cangjie']}]({local}) | {row['status']} | {detail} |")
    return '\n'.join(lines) + '\n'


def check(data):
    revision=json.loads((ROOT/'docs/baseline.json').read_text())['https://github.com/rust-lang/regex']
    assert data['revision']==revision
    symbols=cj_symbols()
    assert len({row['id'] for row in data['methods']})==len(data['methods'])
    for row in data['methods']:
        assert row['cangjie'] in symbols, row
        assert symbols[row['cangjie']]==row['implementation'], 'Regenerate line references: '+row['cangjie']
        for path in row['evidence']: assert (ROOT/path).is_file(), path
    print(f"API inventory checked: {len(data['methods'])} inherent methods; traits/macros reviewed separately")


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--upstream',type=Path)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    if args.upstream:
        data=build(args.upstream)
        SNAPSHOT.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
        (ROOT/'docs/api-audit-methods.md').write_text(render(data))
    else: data=json.loads(SNAPSHOT.read_text())
    check(data)
    assert (ROOT/'docs/api-audit-methods.md').read_text() == render(data), 'Regenerate the method table'
