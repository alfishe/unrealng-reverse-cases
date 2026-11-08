#!/usr/bin/env python3
"""The screen against the beam (docs/runtime-analysis.md, section 8): when in the frame each routine writes the
screen, and what the television showed while CopyBackBuffer copied an update.

    python3 tools/fig_rt_beam.py

The beam is unreal-ng's 48K timing (kit/beam_timeline.py): the first paper line at frame T 16152, 224 T a line. A
write to line L before frame T 16152 + 224 L shows in this frame, after it in the next one.

Figures (docs/img/runtime/):
- beam-bins.png: for the scenes' screen writes, the routine x the time in the frame (32 bins), and each routine's
  share of writes that land behind the beam;
- beam-torn.png: the title (d1 100-200): the frame the television showed in the middle of one copy, rebuilt from the
  trace (each line as it was when the beam drew it), next to the map of its lines: copied for the new pose, still
  the old one, or not touched. CopyBackBuffer copies the even pixel lines of both thirds first, then the odd ones,
  so a torn frame is a comb of two poses, not a picture cut in two.
"""
import os
import sys
from collections import Counter, defaultdict

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import eprof  # noqa: E402
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402

PAPER_T, LINE_T, FRAME = 16152, 224, 69888
COPY_THIRD = 0x7FE3


def line_of(addr):
    a = addr - 0x4000
    return ((a >> 5) & 0xC0) | ((a >> 8) & 7) | ((a >> 2) & 0x38)


def bins_figure():
    keys = ['title', 'station', 'combat', 'galaxy']
    rows = defaultdict(lambda: np.zeros(32))
    behind = defaultdict(lambda: [0, 0])
    for k in keys:
        p = S.profile(S.scene(k))
        for t, addr, r in p['screen_writes']:
            ft = t % FRAME
            rows[r][ft * 32 // FRAME] += 1
            if addr < 0x5800:
                L = line_of(addr)
                b = behind[r]
                b[0] += 1
                b[1] += ft >= PAPER_T + L * LINE_T
    names = sorted(rows, key=lambda r: -rows[r].sum())[:16]
    fig, axes = P.figure(14, 6.4, nrows=1, ncols=2, gridspec_kw={'width_ratios': [3, 1]})
    ax = axes[0]
    mat = np.array([rows[n] / max(1, rows[n].max()) for n in names])
    ax.imshow(mat, aspect='auto', cmap='magma', interpolation='nearest', extent=(0, FRAME, len(names) - 0.5, -0.5))
    ax.axvspan(PAPER_T, PAPER_T + 192 * LINE_T, color=P.EXEC, alpha=0.08)
    ax.axvline(PAPER_T, color=P.EXEC, lw=0.8)
    ax.axvline(PAPER_T + 192 * LINE_T, color=P.EXEC, lw=0.8)
    ax.axvline(1812, color=P.WRITE, lw=0.8, ls='--')
    ax.text(1812, len(names) - 0.6, ' INT', color=P.WRITE, fontsize=8, va='bottom')
    ax.text(PAPER_T, len(names) - 0.6, ' paper line 0', color=P.EXEC, fontsize=8, va='bottom')
    ax.text(PAPER_T + 192 * LINE_T, len(names) - 0.6, 'line 191 ', color=P.EXEC, fontsize=8, va='bottom', ha='right')
    ax.set_yticks(range(len(names)))
    ax.set_yticklabels(['%s (%d)' % (n, rows[n].sum()) for n in names], fontsize=8)
    ax.set_xlabel('frame T of the write (32 bins; each row scaled to its own peak)')
    ax.set_title('When each routine writes the screen (title, station, combat, galactic chart): nobody waits for '
                 'the beam;\nthe only gap is the interrupt (frame T 1812 to about 4500)', fontsize=10)
    ax = axes[1]
    vals = [100 * behind[n][1] / behind[n][0] if behind[n][0] else 0 for n in names]
    ax.barh(range(len(names)), vals, color=P.HOT)
    for i, v in enumerate(vals):
        ax.text(v, i, ' %.0f %%' % v, va='center', fontsize=8)
    ax.set_yticks(range(len(names)))
    ax.set_yticklabels([])
    ax.invert_yaxis()
    ax.set_xlim(0, 100)
    ax.set_xlabel('% of its pixel writes\nbehind the beam')
    ax.set_title('Shown a frame late', fontsize=10)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/beam-bins.png')


def torn_figure():
    t = eprof.load(S.work('d1'), '100:0-200:0')
    ins = t.instructions
    mem = bytearray(t.memory_at(0))
    # the writes into the bitmap with their absolute T, and the CopyThird calls' spans
    writes = []
    copies = []
    cur = None
    for i, x in enumerate(ins):
        at = x.frame * FRAME + x.t // max(1, t.units_per_t)
        if x.pc == COPY_THIRD:
            cur = at
        for c in x.cycles:
            if c.tag == 'W' and 0x4000 <= c.address < 0x5000:
                writes.append((at, c.address, c.value))
        if cur is not None and eprof.opcode(x)[:1] == [0xC9] and 0x7FE3 <= x.pc < 0x8042:
            copies.append((cur, at))
            cur = None
    # group the four CopyThird calls of a CopyBackBuffer
    groups = []
    for c in copies:
        if groups and c[0] - groups[-1][1] < 2000:
            groups[-1][1] = c[1]
        else:
            groups.append([c[0], c[1]])
    # build each candidate frame's line states and keep the most mixed
    w_by_line = defaultdict(list)
    for at, addr, v in writes:
        w_by_line[line_of(addr)].append((at, addr, v))
    cand = []
    for g0, g1 in groups:
        for f in range(g0 // FRAME, g1 // FRAME + 1):
            states = []
            for L in range(128):
                bt = f * FRAME + PAPER_T + L * LINE_T
                ws = [w for w in w_by_line[L] if g0 <= w[0] <= g1]
                if not ws:
                    states.append(0)
                elif max(w[0] for w in ws) <= bt:
                    states.append(1)  # copied before the beam came: the new pose
                elif min(w[0] for w in ws) > bt:
                    states.append(2)  # copied after the beam: the old pose shown
                else:
                    states.append(3)  # the beam met the copy inside the line
            n1, n2 = states.count(1), states.count(2)
            cand.append((min(n1, n2), f, g0, g1, states))
    cand.sort(key=lambda c: -c[0])
    _score, f, g0, g1, states = cand[0]
    # the picture the TV showed: each line as memory held it at its beam time
    mem2 = bytearray(t.memory_at(0))
    shown = np.zeros((128, 256), dtype=np.uint8)
    events = sorted(writes)
    k = 0
    for L in range(128):
        bt = f * FRAME + PAPER_T + L * LINE_T
        while k < len(events) and events[k][0] <= bt:
            mem2[events[k][1]] = events[k][2]
            k += 1
        a = 0x4000 | ((L & 0xC0) << 5) | ((L & 7) << 8) | ((L & 0x38) << 2)
        for col in range(32):
            b = mem2[a + col]
            for bit in range(8):
                shown[L, col * 8 + bit] = (b >> (7 - bit)) & 1
    fig, axes = P.figure(13, 4.2, nrows=1, ncols=2, gridspec_kw={'width_ratios': [2, 1]})
    ax = axes[0]
    img = np.zeros((128, 256, 3))
    img[:] = P.PANEL
    for L in range(128):
        colour = {0: (0.85, 0.85, 0.85), 1: P.EXEC, 2: P.READ, 3: P.WRITE}[states[L]]
        img[L][shown[L] == 1] = colour
    ax.imshow(img, interpolation='nearest')
    ax.set_xticks([])
    ax.set_yticks([0, 32, 64, 96, 127])
    ax.set_ylabel('pixel line')
    ax.set_title('Frame %d of d1 as the television showed it, the copy %d T in' % (f, f * FRAME + PAPER_T - g0),
                 fontsize=10)
    ax = axes[1]
    strip = np.zeros((128, 12, 3))
    for L in range(128):
        strip[L, :] = {0: (0.3, 0.3, 0.35), 1: P.EXEC, 2: P.READ, 3: P.WRITE}[states[L]]
    ax.imshow(strip, aspect='auto', interpolation='nearest')
    ax.set_xticks([])
    ax.set_yticks([0, 32, 64, 96, 127])
    c = Counter(states)
    ax.set_title('the lines: %d new (green), %d old (blue),\n%d cut by the beam (yellow), %d not copied' % (
        c[1], c[2], c[3], c[0]), fontsize=9)
    fig.suptitle('A torn frame of the title: the even lines already hold the new pose, the odd ones the old: '
                 'CopyBackBuffer\'s order makes the tear a comb', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/beam-torn.png')
    torn = sum(1 for cc in cand if cc[0] > 0)
    print('copies %d, displayed frames during copies %d, with both new and old lines %d' % (
        len(groups), len(cand), torn))
    durations = [g1 - g0 for g0, g1 in groups]
    print('copy duration T: median %d, min %d, max %d' % (np.median(durations), min(durations), max(durations)))


def main():
    bins_figure()
    torn_figure()


if __name__ == '__main__':
    main()
