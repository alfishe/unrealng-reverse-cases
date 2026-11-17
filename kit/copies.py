#!/usr/bin/env python3
"""The copy loops of an L1 (`dataflow.copies`: LDIR / LDDR and the loops that move bytes one by one) with the frames
they ran in: what moves where at a program's entry, a relocation, a buffer flush.

    python3 kit/copies.py L1 [L1 ...] [--min N] [--at LO-HI] [--src LO-HI] [--dst LO-HI] [--group] [--top N]
                          [--listing LST] [--json OUT]

A line a copy: the copying instruction, its routine (the L1's, named from --listing when given), source, destination
and length (hex, inclusive ranges), the direction (+ up, - down), the count (how many times that same copy ran), and
the frames: the first and last frame the copying instruction ran (its routine's executes ranges in the L1's
profiles; the L1 holds no frame for each copy, so an instruction that ran many copies gives the same frames to each:
build a window, kit/rs.py build --from-frame F --to-frame G, to tell them apart), plus the trips of the loop round it
when the L1 has one. --group: a line an instruction instead (the copies, the runs, the bytes moved, the source and
destination spans, the lengths). --min N keeps copies of N bytes or more (default 1); --at / --src / --dst keep
those whose instruction / source / destination range meets LO-HI (hex). Sorted by the first frame, then the
instruction. --top N prints the first N lines; --json OUT writes every line kept.

ATV Simulator stage 1 (c1): `$D7E0` moves `$F850` to `$5B00`, 1 451 bytes, frame 14 100 (the game's entry relocates
its blocks); the many short copies of `$8CF3` are the play buffer's.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib  # noqa: E402


def hexa(text):
    return int(str(text).lstrip('$'), 16)


def instruction_frames(doc):
    """{address: [first, last, routine index]} over the L1's routines' executes ranges (frames as the L1 gives them,
    the recording's numbering)"""
    out = {}
    for i, r in enumerate(doc['routines']):
        p = r['profile']
        if not p.get('entries') and not p.get('active_frames') and not p.get('tstates'):
            continue
        f0, f1 = p.get('first_frame', 0), p.get('last_frame', 0)
        for x in p.get('executes', ()):
            lo, hi = hexa(x['from']), hexa(x['to'])
            for a in range(lo, hi + 1 if hi >= lo else 0x10000):
                got = out.get(a)
                if got is None:
                    out[a] = [f0, f1, i]
                else:
                    got[0], got[1] = min(got[0], f0), max(got[1], f1)
    return out


def loop_at(doc, address):
    """the innermost loop of the L1 whose header..latch holds address, or None"""
    best = None
    for lp in doc.get('loops', ()):
        lo, hi = hexa(lp['header']), hexa(lp['latch'])
        if lo <= address <= hi and lp.get('passes') and (best is None or hi - lo < best[0]):
            best = (hi - lo, lp)
    return best[1] if best else None


def meets(lo, hi, want):
    return want is None or (lo <= want[1] and hi >= want[0])


def copies(doc, name='', at=None, src=None, dst=None, least=1):
    """[dict] of the L1's copies kept by the filters"""
    frames = instruction_frames(doc)
    out = []
    for c in doc.get('dataflow', {}).get('copies', ()):
        a, s, d, n, step = hexa(c['at']), hexa(c['src']), hexa(c['dst']), c['length'], c.get('dir', 1)
        s_lo, s_hi = (s, s + n - 1) if step >= 0 else (s - n + 1, s)
        d_lo, d_hi = (d, d + n - 1) if step >= 0 else (d - n + 1, d)
        if n < least or not meets(a, a, at) or not meets(s_lo, s_hi, src) or not meets(d_lo, d_hi, dst):
            continue
        f = frames.get(a)
        lp = loop_at(doc, a)
        out.append({'l1': name, 'at': a, 'routine': doc['routines'][f[2]]['entry'] if f else None,
                    'src': [s_lo, s_hi], 'dst': [d_lo, d_hi], 'length': n, 'dir': step, 'count': c.get('count', 1),
                    'frames': [f[0], f[1]] if f else None,
                    'trips': [lp['min_trips'], lp['max_trips']] if lp else None})
    out.sort(key=lambda x: ((x['frames'] or [1 << 30])[0], x['at'], x['src'][0]))
    return out


def grouped(rows):
    """a dict an instruction: copies, runs, bytes moved, spans, lengths, frames"""
    by = {}
    for r in rows:
        g = by.setdefault((r['l1'], r['at']), {'l1': r['l1'], 'at': r['at'], 'routine': r['routine'], 'copies': 0,
                                               'runs': 0, 'bytes': 0, 'src': [0xFFFF, 0], 'dst': [0xFFFF, 0],
                                               'lengths': [1 << 30, 0], 'frames': r['frames']})
        g['copies'] += 1
        g['runs'] += r['count']
        g['bytes'] += r['count'] * r['length']
        for k in ('src', 'dst'):
            g[k] = [min(g[k][0], r[k][0]), max(g[k][1], r[k][1])]
        g['lengths'] = [min(g['lengths'][0], r['length']), max(g['lengths'][1], r['length'])]
    return sorted(by.values(), key=lambda g: ((g['frames'] or [1 << 30])[0], g['at']))


def span(r):
    return '$%04X-$%04X' % tuple(r)


def frames_text(f):
    return '-' if not f else (str(f[0]) if f[0] == f[1] else f'{f[0]}-{f[1]}')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('l1', nargs='+')
    ap.add_argument('--min', type=int, default=1, help='copies of N bytes or more')
    ap.add_argument('--at', type=kitlib.hex_range)
    ap.add_argument('--src', type=kitlib.hex_range)
    ap.add_argument('--dst', type=kitlib.hex_range)
    ap.add_argument('--group', action='store_true', help='a line an instruction')
    ap.add_argument('--top', type=int)
    ap.add_argument('--json')
    kitlib.add_listing_arg(ap)
    a = ap.parse_args()
    names = kitlib.listing(a.listing, a)
    rows = []
    for path in a.l1:
        with open(path) as f:
            doc = json.load(f)
        label = os.path.basename(os.path.dirname(os.path.abspath(path))) if len(a.l1) > 1 else ''
        rows += copies(doc, label, a.at, a.src, a.dst, a.min)
    out = grouped(rows) if a.group else rows
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(out, f, indent=1)
    shown = out[:a.top] if a.top else out
    who = (lambda r: (r['l1'] + ' ') if r['l1'] else '')
    for r in shown:
        routine = names.routine(r['at']) if a.listing else (r['routine'] or '-')
        if a.group:
            lengths = str(r['lengths'][0]) if r['lengths'][0] == r['lengths'][1] else '%d-%d' % tuple(r['lengths'])
            print(f"{who(r)}${r['at']:04X} {routine}: {r['copies']} copies, {r['runs']} runs, {r['bytes']} bytes; "
                  f"src {span(r['src'])}, dst {span(r['dst'])}, length {lengths}; frames {frames_text(r['frames'])}")
        else:
            trips = '' if not r['trips'] else ' (loop trips %d-%d)' % tuple(r['trips']) \
                if r['trips'][0] != r['trips'][1] else ' (loop trips %d)' % r['trips'][0]
            print(f"{who(r)}${r['at']:04X} {routine}: {span(r['src'])} -> {span(r['dst'])} {r['length']} bytes "
                  f"{'+' if r['dir'] >= 0 else '-'} x{r['count']}; frames {frames_text(r['frames'])}{trips}")
    total = len(rows)
    print(f"{total} cop{'y' if total == 1 else 'ies'} kept" +
          (f", {len(out)} instructions" if a.group else '') + (f", {len(shown)} shown" if len(shown) < len(out) else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
