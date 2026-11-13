#!/usr/bin/env python3
"""What the recordings' L1 builds say about an address: the runs of the instruction there per build, and for a
routine entry its callers (call sites), its reads, writes and ports, merged over every build case.json names.
The first run writes an index (work/stage2/l1index.json) so later queries are quick.

    python3 tools/l1q.py ADDR [ADDR ...]       # runs per build; for a routine entry: callers, memory, ports
    python3 tools/l1q.py --reads ADDR          # the routines (entries) that read or write the byte ADDR
    python3 tools/l1q.py --index               # rebuild the index (after new recordings)

ADDR is hex ($8DFE or 8DFE): RAM 5 at $4000, RAM 2 at $8000, RAM 0 at $C000 (the RAM 1 music: --page 1).
"""
import argparse
import json
import os

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDEX = os.path.join(CASE, 'work', 'stage2', 'l1index.json')
BASE = {5: 0x4000, 2: 0x8000, 0: 0xC000, 1: 0xC000}


def builds():
    c = json.load(open(os.path.join(CASE, 'case.json')))
    out = list(dict.fromkeys(c['read_builds'] + c['code_builds']))
    extra = os.path.join(CASE, 'work', 'stage2', 'l1extra.txt')  # stage 2 recordings, one build a line
    if os.path.exists(extra):
        out += [x.strip() for x in open(extra) if x.strip() and x.strip() not in out]
    return out


def ranges(rs):
    return [(r['page'], r['from'], r['to']) for r in rs]


def build_index():
    runs, rout = {}, {}
    for b in builds():
        d = json.load(open(os.path.join(CASE, 'work', b, 'l1.json')))
        name = b.split('/')[-1]
        for a, page, op, kind, n, *_ in d['instructions']:
            if page in BASE:
                runs.setdefault(f'{page}:{a}', {})[name] = n
        idx = d['routines']
        for c in d['calls']:
            callee = idx[c['callee']]
            key = f"{callee['page']}:{callee['entry']}"
            e = rout.setdefault(key, {'callers': {}, 'reads': set(), 'writes': set(), 'in': set(), 'out': set()})
            for s in c['sites']:
                e['callers'][s] = e['callers'].get(s, 0) + c['count']
        for r in idx:
            key = f"{r['page']}:{r['entry']}"
            e = rout.setdefault(key, {'callers': {}, 'reads': set(), 'writes': set(), 'in': set(), 'out': set()})
            p = r.get('profile') or {}
            e['reads'] |= set(ranges(p.get('reads', [])))
            e['writes'] |= set(ranges(p.get('writes', [])))
            e['in'] |= {x if isinstance(x, str) else json.dumps(x) for x in p.get('ports_in', [])}
            e['out'] |= {x if isinstance(x, str) else json.dumps(x) for x in p.get('ports_out', [])}
        print('indexed', b)
    for e in rout.values():
        for k in ('reads', 'writes', 'in', 'out'):
            e[k] = sorted(e[k])
    json.dump({'runs': runs, 'routines': rout}, open(INDEX, 'w'))


def page_of(a, page):
    if page is not None:
        return page
    return 5 if a < 0x8000 else 2 if a < 0xC000 else 0


def merge(rs):
    """(page, from, to) ranges merged where they touch"""
    out = []
    for page, lo, hi in sorted((p, int(f[1:], 16), int(t[1:], 16)) for p, f, t in rs):
        if out and out[-1][0] == page and lo <= out[-1][2] + 1:
            out[-1][2] = max(out[-1][2], hi)
        else:
            out.append([page, lo, hi])
    return ', '.join(f'${lo:04X}-${hi:04X}' + (f'(p{page})' if page not in (5, 2, 0) else '') for page, lo, hi in out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('addr', nargs='*')
    ap.add_argument('--page', type=int)
    ap.add_argument('--reads', action='store_true')
    ap.add_argument('--index', action='store_true')
    a = ap.parse_args()
    if a.index or not os.path.exists(INDEX):
        build_index()
    ix = json.load(open(INDEX))
    for s in a.addr:
        addr = int(s.lstrip('$'), 16)
        page = page_of(addr, a.page)
        key = f'{page}:${addr:04X}'
        if a.reads:
            hits = []
            for k, e in ix['routines'].items():
                for kind in ('reads', 'writes'):
                    for p, f, t in e[kind]:
                        if p == page and int(f[1:], 16) <= addr <= int(t[1:], 16):
                            hits.append(f'{k.split(":")[1]} {kind}')
            print(f'${addr:04X}:', ', '.join(sorted(set(hits))) or 'no routine')
            continue
        r = ix['runs'].get(key, {})
        print(f'${addr:04X} (page {page}): {sum(r.values())} runs in {len(r)} builds: ' +
              ', '.join(f'{b} {n}' for b, n in sorted(r.items())[:12]) + (' ...' if len(r) > 12 else ''))
        e = ix['routines'].get(key)
        if e:
            print('  callers:', ', '.join(f'{s} x{n}' for s, n in sorted(e['callers'].items())) or 'none (a root)')
            print('  reads:  ', merge(e['reads']))
            print('  writes: ', merge(e['writes']))
            if e['in'] or e['out']:
                print('  ports in:', ', '.join(e['in'])[:300], ' out:', ', '.join(e['out'])[:300])


if __name__ == '__main__':
    main()
