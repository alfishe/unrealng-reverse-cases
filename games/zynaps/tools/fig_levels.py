#!/usr/bin/env python3
"""The level scripts at work and the twelve levels of r1 as figures (docs/10-gameplay-logic.md).

    python3 tools/fig_levels.py script [--npz work/zyB/w2-frames.npz --mem work/zyB/w2/start.bin --level 0]
    python3 tools/fig_levels.py levels [--npz work/zyB/r1-every10.npz]

  script  docs/img/play/script-level0.png: ScriptPC $81D8 frame by frame through one level of a recording, each
          step of the script a row (decoded from the memory at $6B8D the way ScriptStep $AD66 reads it), the active
          enemy records (slots 1-5) below: which command launched which wave, the 8 frames a count, the
          `anyenemies` wait at the end, `levelend`.
  levels  docs/img/play/levels-r1.png: the score, the level order index (+6 of the player record) and the big
          enemies' hit points (kind 12, +$0D) over r1, one sample every 10 frames.
"""
import argparse
import os

import numpy as np

import zybplot as P
import fig_weapons as W

SCRIPT_OPS = {0: 'nop', 1: 'scrollresume', 2: 'scrolloff', 3: 'starson', 4: 'starsoff', 5: 'levelend', 6: 'nop6',
              13: 'return', 14: 'save', 15: 'clearrows', 16: 'escapefirst', 17: 'anyenemies'}
SCRIPT_ARGS = {7: ('poke', 2), 8: ('copy', 2), 9: ('dec', 1), 10: ('inc', 1), 11: ('test', 1), 12: ('add', 2)}
CONDS = ['', 'z', 'nz', 'c', 'nc', 'p', 'm']
LEVEL_ORDER = [0, 1, 2, 7, 6, 5, 4, 8, 3, 9, 10, 11]   # $8003 (r1)


def w(m, a):
    return m[a] | m[a + 1] << 8


def decode_script(m, start):
    """[(address, wait, text)] from start to the first levelend (the format of tools/res_levels.py)"""
    out, a = [], start
    while True:
        t, op = m[a], m[a + 1]
        if op < 0x40:
            if op in SCRIPT_ARGS:
                name, n = SCRIPT_ARGS[op]
                text, size = name + ' ' + ' '.join('$%04X' % w(m, a + 2 + 2 * i) for i in range(n)), 2 + 2 * n
            else:
                text, size = SCRIPT_OPS.get(op, 'op %d' % op), 2
        elif op < 0x80 or op >= 0xC0:
            text, size = '%s %s$%04X' % ('jp' if op < 0x80 else 'call', CONDS[op & 0x3F] + ' ' if op & 0x3F else '',
                                         w(m, a + 2)), 4
        else:
            text, size = 'wave %d y %d' % (op & 0x3F, m[a + 2]), 3
        out.append((a, t, text))
        a += size
        if text == 'levelend':
            return out


def script(rec, mem, level):
    m = open(mem, 'rb').read()
    table = 0x6B2D + 8 * level
    start = w(m, table + 1)
    steps = decode_script(m, start)
    index = {a: k for k, (a, _, _) in enumerate(steps)}
    pc = rec.var(0x81D8) | rec.var(0x81D9) << 8
    F = rec.F
    ys = np.array([index.get(int(v), np.nan) for v in pc], float)
    seen = ~np.isnan(ys)
    last = int(F[seen][-1])
    P.style()
    fig, (ax, bx) = P.plt.subplots(2, 1, figsize=(14, 11), gridspec_kw={'height_ratios': [5, 1]}, sharex=True)
    ax.step(F[seen], ys[seen], where='post', color=P.COLOURS[0], lw=1.4)
    # a step runs when ScriptPC leaves it: the frame of each change, at the row of the step left
    ran = []
    wait = rec.var(0x81E1)
    for i in range(1, len(F)):
        if (pc[i] != pc[i - 1] or wait[i] < wait[i - 1]) and int(pc[i - 1]) in index:
            ran.append((int(F[i]), index[int(pc[i - 1])]))
    for k, (a, t, text) in enumerate(steps):
        col = (0.4, 1.0, 0.5) if text.startswith('wave') else P.TEXT
        ax.text(-60, k, f'${a:04X}  {t:3d}  {text}', ha='right', va='center', fontsize=8, family='monospace',
                color=col)
    for f, k in ran:
        text = steps[k][2]
        col = (0.4, 1.0, 0.5) if text.startswith('wave') else (1.0, 1.0, 0.6)
        ax.plot([f], [k], 'o', color=col, ms=4.5)
        if not text.startswith('wave') or k in (2, 3, 4):
            pass
    for f, k in ran:
        if steps[k][2].split()[0] in ('scrolloff', 'levelend', 'clearrows') or (
                steps[k][2] == 'anyenemies' and f in (min(g for g, j in ran if j == k), max(g for g, j in ran if j == k))):
            ax.annotate(f'{steps[k][2]} {f}', (f, k), (f - 150, k - 0.6), ha='right', fontsize=8.5, color=(1.0, 1.0, 0.6),
                        arrowprops=dict(arrowstyle='-', color=(1.0, 1.0, 0.6)))
    self_ran = ran
    ax.set_yticks([])
    ax.set_ylim(len(steps) - 0.5, -0.5)
    ax.set_xlim(-40, last + 150)
    ax.grid(axis='x')
    # the 8 frames a count: one example step marked
    ax.set_title(f'Level {level} script ($6B2D + 8 x {level}: script ${start:04X}) as {rec.name} ran it: ScriptPC '
                 f'$81D8 frame by frame;\nleft: address, wait in counts (one count = 8 frames), command; dots: '
                 f'a step run (green: a wave launched)', fontsize=11)
    busy = np.array([sum(1 for s, k, _, _ in rec.active(i) if 1 <= s <= 5 and k != 4) for i in range(len(F))])
    pods = np.array([sum(1 for s, k, _, _ in rec.active(i) if 1 <= s <= 5 and k == 4) for i in range(len(F))])
    bx.fill_between(F, 0, busy, step='post', color=(0.45, 0.6, 1.0), alpha=0.8, label='enemies and explosions')
    bx.fill_between(F, busy, busy + pods, step='post', color=(0.3, 0.9, 0.4), alpha=0.8, label='pods')
    bx.set_ylim(0, 5.5)
    bx.set_ylabel('slots 1-5')
    bx.legend(loc='upper left', fontsize=8.5)
    bx.set_xlabel(f'{rec.name} frame')
    fig.subplots_adjust(left=0.26, right=0.98, top=0.93, bottom=0.06, hspace=0.05)
    P.save(fig, P.out('play', f'script-level{level}.png'))
    for f, k in self_ran:
        print(f, f'${steps[k][0]:04X} {steps[k][2]}')


def levels(rec):
    F = rec.F
    idx = rec.var(0x7FA2)
    score = np.array([int(''.join(f'{b:02X}' for b in rec.V[i, 0:4])) for i in range(len(F))])
    P.style()
    fig, (ax, bx) = P.plt.subplots(2, 1, figsize=(14, 7.5), sharex=True, gridspec_kw={'height_ratios': [3, 2]})
    starts = [0] + [int(F[i]) for i in range(1, len(F)) if idx[i] != idx[i - 1]] + [int(F[-1])]
    for k in range(len(starts) - 1):
        lv = LEVEL_ORDER[idx[np.searchsorted(F, starts[k])]]
        for a in (ax, bx):
            a.axvspan(starts[k], starts[k + 1], color=P.COLOURS[lv % len(P.COLOURS)], alpha=0.12)
        ax.text((starts[k] + starts[k + 1]) / 2, 0.97, f'idx {idx[np.searchsorted(F, starts[k])]}\nlevel {lv}',
                transform=ax.get_xaxis_transform(), ha='center', va='top', fontsize=8.5)
    ax.plot(F, score, color=P.COLOURS[0], lw=1.4)
    ax.set_ylabel('score')
    ax.set_ylim(0, score.max() * 1.25)
    runs, cur = [], None
    for i in range(len(F)):
        b = [(s, int(rec.slot(i, s)[0x0D])) for s, k, _, _ in rec.active(i) if k == 12]
        if b:
            if cur is None:
                cur = [[], []]
            cur[0].append(int(F[i]))
            cur[1].append(b[0][1])
        elif cur is not None:
            runs.append(cur)
            cur = None
    for fr, hp in runs:
        bx.plot(fr, hp, color=(0.75, 0.45, 0.95), lw=1.6)
        end = 'killed' if hp[-1] <= 1 and fr[-1] + 10 < starts[-1] and not any(
            fr[-1] < s <= fr[-1] + 20 for s in starts[1:]) else f'left at {hp[-1]}'
        bx.text(fr[0], 50, f'{fr[0]}', fontsize=8, color=(0.75, 0.45, 0.95))
        bx.text(fr[-1], hp[-1] + 3, end, fontsize=8, color=P.TEXT)
    bx.set_ylim(0, 60)
    bx.set_ylabel('big enemy +$0D')
    bx.set_xlabel('r1 frame (a sample every 10 frames)')
    ax.set_title(f'r1 through the twelve levels: the score (top), the level order index +6 and LevelOrder $8003\'s '
                 f'level (bands), the big enemies\' 48 hit points worn down (bottom, {len(runs)} big enemies)',
                 fontsize=10.5)
    fig.tight_layout()
    P.save(fig, P.out('play', 'levels-r1.png'))
    for fr, hp in runs:
        print('big', fr[0], fr[-1], hp[0], hp[-1])
    print('starts', starts)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what')
    p.add_argument('--npz')
    p.add_argument('--mem', default=os.path.join(P.CASE, 'work', 'zyB', 'w2', 'start.bin'))
    p.add_argument('--level', type=int, default=0)
    a = p.parse_args()
    if a.what == 'script':
        script(W.Rec(a.npz or os.path.join(P.CASE, 'work', 'zyB', 'w2-frames.npz')), a.mem, a.level)
    else:
        levels(W.Rec(a.npz or os.path.join(P.CASE, 'work', 'zyB', 'r1-every10.npz')))


if __name__ == '__main__':
    main()
