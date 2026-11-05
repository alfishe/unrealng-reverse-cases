#!/usr/bin/env python3
"""Check the signature base and write its index (docs/signature-format.md, section 4).

    python3 kit/sig_index.py --check     # ids, hashes, masks, kinds, roles, variant links; exit 1 on a problem
    python3 kit/sig_index.py             # the check, then signatures/index.json and signatures/INDEX.md
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import siglib as S  # noqa: E402

REQUIRED = ('schema', 'id', 'kind', 'role', 'name', 'authors', 'year', 'tags', 'summary', 'found_in')


def check(base):
    problems, entries = [], {}
    for path in S.entry_dirs(base):
        eid = S.entry_id(path, base)
        bad = lambda text: problems.append(f'{eid}: {text}')
        try:
            sig, data = S.load_entry(path)
        except (OSError, ValueError) as e:
            bad(f'cannot read: {e}')
            continue
        for k in REQUIRED:
            if k not in sig:
                bad(f'no {k}')
        parts = eid.split('/')
        if len(parts) != 4:
            bad(f'the folder is {len(parts)} levels deep, not <domain>/<family>/<name>/<variant>')
        if parts[0] not in S.DOMAINS:
            bad(f'domain {parts[0]} is not in the format\'s list')
        if any(p != p.lower() or ' ' in p for p in parts):
            bad('folder names are lower case with no spaces')
        if sig.get('id') != eid:
            bad(f'id {sig.get("id")} is not its folder')
        if sig.get('schema') != S.SCHEMA:
            bad(f'schema {sig.get("schema")}')
        kind = sig.get('kind')
        if kind not in S.KINDS:
            bad(f'kind {kind}')
        if sig.get('role') not in S.ROLES:
            bad(f'role {sig.get("role")}')
        if kind in ('code', 'data'):
            if data is None:
                bad('no bytes')
                continue
            b = sig['bytes']
            if b.get('length') != len(data):
                bad(f'length {b.get("length")}, the file has {len(data)}')
            if b.get('sha1') != S.sha1(data):
                bad('sha1 differs from the file')
            if b.get('masked_sha1') != S.sha1(S.masked_bytes(data, sig)):
                bad('masked_sha1 differs from the file')
            if 'origin' not in sig:
                bad('no origin')
            last = -1
            for m in sorted(sig.get('mask', []), key=lambda m: m['offset']):
                if m.get('kind') not in S.MASK_KINDS:
                    bad(f'mask kind {m.get("kind")} at +{m["offset"]}')
                if m['offset'] < 0 or m['offset'] + m['length'] > len(data):
                    bad(f'mask +{m["offset"]}..+{m["offset"] + m["length"] - 1} outside the bytes')
                if m['offset'] <= last:
                    bad(f'mask ranges overlap at +{m["offset"]}')
                if m.get('kind') in S.NAMED_MASKS and not m.get('name'):
                    bad(f'{m["kind"]} at +{m["offset"]} has no name')
                if m.get('kind') in ('rel16', 'ext16', 'var16') and m['length'] != 2:
                    bad(f'{m["kind"]} at +{m["offset"]} is not 2 bytes')
                last = m['offset'] + m['length'] - 1
        if kind == 'format' and not os.path.exists(os.path.join(path, 'detect.py')):
            bad('a format entry with no detect.py')
        if not sig.get('found_in'):
            bad('found_in is empty')
        entries[eid] = (path, sig, data)
    for eid, (path, sig, data) in entries.items():
        for v in sig.get('variants', []):
            if v.get('id') not in entries:
                problems.append(f'{eid}: variant {v.get("id")} is not in the base')
            if v.get('relation') not in S.RELATIONS:
                problems.append(f'{eid}: relation {v.get("relation")}')
    return problems, entries


def index(entries):
    out = {'schema': S.SCHEMA, 'anchor_length': S.ANCHOR_LENGTH, 'entries': {}, 'by_sha1': {}, 'by_masked_sha1': {},
           'anchors': {}, 'by_role': {}, 'by_tag': {}, 'formats': []}
    for eid in sorted(entries):
        path, sig, data = entries[eid]
        row = {'kind': sig['kind'], 'role': sig['role'], 'name': sig['name'], 'tags': sig['tags'],
               'found_in': len(sig['found_in'])}
        if data is not None:
            row.update(length=len(data), sha1=sig['bytes']['sha1'], masked_sha1=sig['bytes']['masked_sha1'],
                       origin=sig['origin'])
            out['by_sha1'].setdefault(row['sha1'], []).append(eid)
            out['by_masked_sha1'].setdefault(row['masked_sha1'], []).append(eid)
            for off, key in S.anchors(data, sig):
                out['anchors'].setdefault(key, []).append([eid, off])
        out['entries'][eid] = row
        out['by_role'].setdefault(sig['role'], []).append(eid)
        for t in sig['tags']:
            out['by_tag'].setdefault(t, []).append(eid)
        if sig['kind'] == 'format':
            out['formats'].append(eid)
    return out


def index_md(entries):
    lines = ['# The signature base: every entry', '',
             'Generated by `kit/sig_index.py` from the entries\' `sig.json`; do not edit. The format: '
             '[docs/signature-format.md](../docs/signature-format.md).', '']
    groups = {}
    for eid in sorted(entries):
        groups.setdefault('/'.join(eid.split('/')[:2]), []).append(eid)
    for group, ids in groups.items():
        lines += [f'## {group}', '', '| Entry | Name | Kind, role | Bytes | Authors, year | Found in |',
                  '| --- | --- | --- | --- | --- | --- |']
        for eid in ids:
            path, sig, data = entries[eid]
            programs = sorted({f['program'] for f in sig['found_in'] if f.get('program')})
            link = '/'.join(eid.split('/')[2:])
            lines.append('| [%s](%s/sig.json) | %s | %s, %s | %s | %s | %s |' % (
                link, '/'.join(eid.split('/')), sig['name'].replace('|', '/'), sig['kind'], sig['role'],
                len(data) if data is not None else '', ', '.join(sig['authors']) + (
                    f', {sig["year"]}' if sig.get('year') else ''), ', '.join(programs)))
        lines.append('')
    return '\n'.join(lines)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--check', action='store_true', help='check only, write nothing')
    p.add_argument('--base', default=S.BASE)
    args = p.parse_args()
    problems, entries = check(args.base)
    for text in problems:
        print(text)
    if problems:
        print(f'signatures: {len(problems)} problem(s)')
        sys.exit(1)
    if not args.check:
        idx = index(entries)
        with open(os.path.join(args.base, 'index.json'), 'w') as f:
            json.dump(idx, f, indent=1, sort_keys=False)
            f.write('\n')
        open(os.path.join(args.base, 'INDEX.md'), 'w').write(index_md(entries))
        print(f'signatures: {len(entries)} entries, {len(idx["anchors"])} anchors: index.json, INDEX.md written')
    else:
        print(f'signatures: ok, {len(entries)} entries')


if __name__ == '__main__':
    main()
