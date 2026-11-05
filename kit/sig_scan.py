#!/usr/bin/env python3
"""Scan an image against the signature base (docs/signature-format.md, sections 3.8 and 4).

    python3 kit/sig_scan.py IMAGE --base ADDR [--bank N] [--out hits.json] [--ann] [--all]

IMAGE is any binary, loaded at ADDR (a 64 K image: --base 0). Every 12-byte window is looked up in the index's
anchors, the hits are grouped by entry and implied start, each group gets the full match (exact, masked with
consistent rel16 words, or a candidate when at least half the entry's anchors hit), and every format detector runs.
Prints a table; --out writes the hits as JSON, --ann prints the exact and masked hits' entries and labels as .ann
lines at the found addresses. Candidates are listed only with --all when fewer than half the anchors hit.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import siglib as S  # noqa: E402


def scan(mem, base, sigbase=S.BASE, bank=None, show_all=False):
    idx = json.load(open(os.path.join(sigbase, 'index.json')))
    k = idx['anchor_length']
    anchors = idx['anchors']
    total = {}
    for key, items in anchors.items():
        for eid, off in items:
            total[eid] = total.get(eid, 0) + 1
    groups = {}
    for p in range(0, len(mem) - k + 1):
        items = anchors.get(mem[p:p + k].hex())
        if items:
            for eid, off in items:
                groups.setdefault((eid, p - off), set()).add(off)
    hits = []
    cache = {}

    def entry(eid):
        if eid not in cache:
            cache[eid] = S.load_entry(os.path.join(sigbase, *eid.split('/')))
        return cache[eid]

    for (eid, start), offs in sorted(groups.items(), key=lambda g: (g[0][1], g[0][0])):
        sig, data = entry(eid)
        hit = S.match_at(sig, data, mem, start, base)
        if hit is None:
            continue
        hit['anchors'] = f'{len(offs)}/{total[eid]}'
        if hit['match'] == 'candidate' and len(offs) * 2 < total[eid] and not show_all:
            continue
        hit['bank'] = bank
        hits.append(hit)
    # the entries with no anchors: only an exact copy finds them
    for eid, row in idx['entries'].items():
        if eid in total or 'sha1' not in row:
            continue
        sig, data = entry(eid)
        at = mem.find(data)
        while at >= 0:
            hit = S.match_at(sig, data, mem, at, base)
            hit.update(anchors='0/0', bank=bank)
            hits.append(hit)
            at = mem.find(data, at + len(data))
    for eid in idx['formats']:
        detect = S.load_detector(os.path.join(sigbase, *eid.split('/'), 'detect.py'))
        for d in detect(bytes(mem), base):
            hits.append({'id': eid, 'address': S.hexaddr(d['address']), 'match': 'format', 'length': d['length'],
                         'name': d.get('name'), 'values': d.get('fields', {}), 'bank': bank})
    hits.sort(key=lambda h: (S.addr(h['address']), h['id']))
    return hits


def ann_lines(hits, sigbase=S.BASE):
    out = []
    for h in hits:
        if h['match'] not in ('exact', 'masked'):
            continue
        sig, data = S.load_entry(os.path.join(sigbase, *h['id'].split('/')))
        a0 = S.addr(h['address'])
        out.append(f'# {h["id"]}: {sig["name"]} ({h["match"]}, delta {h["delta"]})' +
                   (f'; stored here, runs at {h["runs_at"]}' if h.get('runs_at') else ''))
        rows = [(e['offset'], 'c ' + e['name'], e.get('summary') or '') for e in sig.get('entries', [])]
        rows += [(l['offset'], l['name'], l.get('comment') or '') for l in sig.get('labels', [])]
        for off, name, comment in sorted(rows, key=lambda r: (r[0], not r[1].startswith('c '))):
            out.append(f'${(a0 + off) & 0xFFFF:04X} {name}'.rstrip() + (f' ; {comment}' if comment else ''))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('image')
    p.add_argument('--base', required=True, help='the address of the image\'s first byte')
    p.add_argument('--bank', type=int)
    p.add_argument('--out')
    p.add_argument('--ann', action='store_true')
    p.add_argument('--all', action='store_true', help='also candidates with fewer than half the anchors')
    p.add_argument('--signatures', default=S.BASE)
    args = p.parse_args()
    mem = open(args.image, 'rb').read()
    hits = scan(mem, S.addr(args.base), args.signatures, args.bank, args.all)
    if args.out:
        with open(args.out, 'w') as f:
            json.dump(hits, f, indent=1)
            f.write('\n')
    if args.ann:
        print('\n'.join(ann_lines(hits, args.signatures)))
        return
    print('%-6s %-10s %-7s %-9s %s' % ('addr', 'match', 'delta', 'anchors', 'entry'))
    for h in hits:
        extra = ''
        if h['match'] == 'candidate':
            extra = f'  ({len(h["differs"])} bytes differ' + (f'; {h["note"]}' if h.get('note') else '') + ')'
        elif h.get('runs_at'):
            extra = f'  (stored here, runs at {h["runs_at"]})'
        elif h['match'] == 'format':
            extra = f'  {h.get("name") or ""} ({h["length"]} bytes)'
        print('%-6s %-10s %-7s %-9s %s%s' % (h['address'], h['match'], h.get('delta', ''), h.get('anchors', ''),
                                             h['id'], extra))


if __name__ == '__main__':
    main()
