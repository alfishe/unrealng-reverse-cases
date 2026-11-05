#!/usr/bin/env python3
"""Doc 04 figure: does the '99's view copy tear on the Pentagon 128? Every CopyViewToScreen of an access trace, its
start against the frame and the screen line where the beam catches it (docs/img/loop/tear-band.png).

    python3 tools/fig_zs_tear.py --trace work/docs/zsA/rc/traces/8026_0-8326_0.uatr \
        [--trace work/docs/zsA/rc/traces/8000_0-8026_0.uatr] --out docs/img/loop/tear-band.png

A byte of the copy at screen line L, column c shows in the frame whose beam fetches it after the write (frame T
17944 + 224 L + 4 c on the Pentagon). A copy tears when one TV frame shows some of its lines new and others old:
the line where the bytes of the first frame that shows new bytes stop is the tear.
"""
import argparse
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import zsa_common as Z  # noqa: E402
import kitlib as K  # noqa: E402

COPY = 0xD071          # CopyViewToScreen
COPY_END = 0xD0B8      # its last byte (ClearScreen follows at $D0B9)


def copies(path):
    tr = K.access_trace(Z.UNREAL).load(path)
    out, cur = [], None
    for x in tr.instructions:
        if x.pc == COPY:
            cur = {'start': (x.frame, x.t), 'writes': []}
            out.append(cur)
        if cur is None or not (COPY <= x.pc <= COPY_END):
            continue
        for c in x.cycles:
            if c.tag in 'WE' and 0x4000 <= c.address < 0x5800:
                f, t = tr.cycle_t(x, c)
                cur['writes'].append((f, t, K.screen_line(c.address), c.address & 31))
    return [c for c in out if len(c['writes']) == 3200]


def analyse(c):
    f0, t0 = c['start']
    shown = {}
    for f, t, line, col in c['writes']:
        k = f if t <= Z.PAPER_T + line * Z.LINE_T + 4 * col else f + 1
        shown.setdefault(k, set()).add(line)
    first = min(shown)
    lines_first = shown[first]
    all_lines = set(l for _, _, l, _ in c['writes'])
    torn = None if lines_first == all_lines else max(lines_first) + 1
    return {'frame': f0, 't': t0, 'frames': sorted(shown), 'tear': torn, 'end': c['writes'][-1][:2]}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--trace', action='append', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    rows = []
    for path in args.trace:
        rows += [analyse(c) for c in copies(path)]
    rows.sort(key=lambda r: r['frame'])
    for r in rows:
        print(r)
    fig, ax = plt.subplots(figsize=(12, 5.6), dpi=110)
    fig.patch.set_facecolor('#15161b')
    ax.set_facecolor('#1c1d24')
    ax.tick_params(colors='#b8bcc8', labelsize=9)
    for s in ax.spines.values():
        s.set_color('#444')
    clean = [r for r in rows if r['tear'] is None]
    torn = [r for r in rows if r['tear'] is not None]
    ax.scatter([r['t'] for r in clean], [-6] * len(clean), s=40, color='#4caf50', marker='|', linewidths=2,
               label=f'{len(clean)} copies shown whole in one frame (no tear)')
    ax.scatter([r['t'] for r in torn], [r['tear'] for r in torn], s=34, color='#e5534b',
               label=f'{len(torn)} copies torn: the line where the new view stops in the first frame that shows it')
    # the boundary: a copy that starts at line 8 at frame T s finishes line L at about s + 386 (L - 8) (386 T a line,
    # 61736 T for 160 lines, plus an interrupt when one falls inside); the next frame's beam reaches line L at 71680 + 17944 + 224 L
    ax.axvline(Z.PAPER_T + 8 * Z.LINE_T, color='#ffffff', lw=0.8, ls=':')
    ax.text(Z.PAPER_T + 8 * Z.LINE_T + 500, 60, 'the beam reaches\nscreen line 8\n(the view\'s top)', color='#e8e8ee',
            fontsize=9)
    if clean:
        lo, hi = min(r['t'] for r in clean), max(r['t'] for r in clean)
        ax.axvspan(lo, hi, color='#4caf50', alpha=0.08)
        ax.text((lo + hi) / 2, 110, f'no tear: the copy starts after the beam\nhas passed line 8 ({lo}-{hi} here);\n'
                'the beam stays ahead of it to the frame\'s end,\nand in the next frame it stays ahead of the beam',
                ha='center', color='#a5d6a7', fontsize=9)
    early = [r for r in torn if r['t'] < Z.FRAME_T // 2]
    late = [r for r in torn if r['t'] >= Z.FRAME_T // 2]
    if early:
        r = early[0]
        ax.annotate('starts ahead of the beam; at 386 T a line\nagainst its 224 the beam overtakes it\n'
                    'near line 60 of the same frame', xy=(r['t'], r['tear']), xytext=(1500, 150), color='#ef9a9a',
                    fontsize=9, arrowprops=dict(arrowstyle='->', color='#ef9a9a', lw=0.8))
    if late:
        r = late[0]
        ax.annotate('starts at the frame\'s end: the next\nframe\'s beam catches it\nnear line 90',
                    xy=(r['t'], r['tear']), xytext=(52000, 150), color='#ef9a9a', fontsize=9,
                    arrowprops=dict(arrowstyle='->', color='#ef9a9a', lw=0.8))
    ax.set_xlim(0, Z.FRAME_T)
    ax.set_ylim(196, -14)
    ax.set_xlabel('frame T at which CopyViewToScreen ($D071) starts (71680 a frame, the interrupt at 0)',
                  color='#b8bcc8', fontsize=9)
    ax.set_ylabel('screen line of the tear', color='#b8bcc8', fontsize=9)
    ax.set_title(f'{len(rows)} view copies of r-critical: when a copy starts decides whether the screen tears',
                 color='#e8e8ee', fontsize=12, loc='left')
    ax.legend(loc='lower left', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print(args.out, len(rows), 'copies', len(torn), 'torn')


if __name__ == '__main__':
    main()
