#!/usr/bin/env python3
"""Who drives the beeper in a frame of play: the effect player and the explosion noise (docs/09-sound.md 9.5).

    python3 tools/fig_beeper.py [--trace work/zyB/w2/traces/701_0-705_0.uatr --frames 702,703,704]

Reads an access trace of w2 (kit/routine_anim.py --work work/zyB/w2 --window 701:0-705:0 made it on the w2
instance) and draws docs/img/sound/beeper-frame.png: one row a TV frame, the T-states 0-69887 across.

  - the band: which code ran at each moment, by its address: EffectPlay and RequestEffect ($B2F0-$B445), the jobs of
    EventDispatch ($AC07-$AD65), the play loop ($B1B4-$B1FF), everything else (the play interrupt's pass: the
    objects, the strips, the drawing);
  - the ticks above it: every OUT ($FE) of the frame, coloured by the instruction that wrote it (RowBeep in the
    playfield drawing $86D7, ObjectBeep in ObjectStrips $8FBD, SlotBeep in RunObjects $949C, the effect's tone
    $B35E, the border at $AA91), drawn up when bit 4 (the speaker) is set, down when clear.
"""
import argparse
import os
import sys

import zybplot as P

sys.path.insert(0, os.path.normpath(os.path.join(P.CASE, '..', '..', 'kit')))
import kitlib as K  # noqa: E402

FRAME_T = 69888
BANDS = [('EffectPlay $B30C (the effect\'s tone loop)', 0xB2F0, 0xB445, (0.35, 0.95, 0.45)),
         ('the jobs of EventDispatch $AC07', 0xAC07, 0xAD65, (0.40, 0.60, 1.00)),
         ('the play loop $B1B4', 0xB1B4, 0xB1FF, (0.55, 0.55, 0.55))]
OTHER = ('the play interrupt\'s pass (objects, strips, drawing)', (0.85, 0.45, 0.20))
SOURCES = {0x86D7: ('RowBeep $7F7E (playfield rows)', (1.0, 0.85, 0.3)),
           0x8FBD: ('ObjectBeep $7F82 (object strips)', (0.95, 0.4, 0.9)),
           0x949C: ('SlotBeep $7F86 (RunObjects)', (0.3, 0.85, 1.0)),
           0xB35E: ('the effect\'s tone', (0.35, 0.95, 0.45))}
SHORT = {v[0]: v[0].split(' ')[0] for v in SOURCES.values()}
SHORT["the effect's tone"] = 'tone'


def band_of(pc):
    for k, (_, lo, hi, _) in enumerate(BANDS):
        if lo <= pc <= hi:
            return k
    return len(BANDS)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--trace', default=os.path.join(P.CASE, 'work', 'zyB', 'w2', 'traces', '701_0-705_0.uatr'))
    p.add_argument('--frames', default='702,703,704')
    a = p.parse_args()
    frames = [int(v) for v in a.frames.split(',')]
    trace = K.access_trace(None).load(a.trace)
    P.style()
    fig, axes = P.plt.subplots(len(frames), 1, figsize=(14, 2.3 * len(frames) + 1.2), sharex=True)
    counts = {}
    for ax, f in zip(axes, frames):
        ins = [i for i in trace.instructions if i.frame == f]
        spans, cur, start = [], None, 0
        for i in ins:
            b = band_of(i.pc)
            if b != cur:
                if cur is not None:
                    spans.append((start, i.t, cur))
                cur, start = b, i.t
        spans.append((start, FRAME_T, cur))
        for s, e, b in spans:
            col = BANDS[b][3] if b < len(BANDS) else OTHER[1]
            ax.axvspan(s, e, ymin=0.0, ymax=0.32, color=col, lw=0)
        tone = sum(e - s for s, e, b in spans if b == 0)
        n = {}
        for i in ins:
            for c in i.cycles:
                if c.tag == 'O' and c.address & 0xFF == 0xFE:
                    src = SOURCES.get(i.pc, ('other', (0.7, 0.7, 0.7)))
                    up = c.value & 0x10
                    ax.plot([i.t, i.t], [0.45, 0.95 if up else 0.62], color=src[1], lw=1.2)
                    n[src[0]] = n.get(src[0], 0) + 1
        counts[f] = n
        ax.set_ylim(0, 1)
        ax.set_yticks([])
        ax.set_ylabel(f'frame {f}', rotation=0, ha='right', va='center')
        ax.text(FRAME_T, 1.02, f'EffectPlay {tone} T ({100 * tone / FRAME_T:.0f} %), OUT ($FE): ' +
                ', '.join(f'{v} {SHORT.get(k, k)}' for k, v in sorted(n.items())), ha='right', va='bottom',
                fontsize=8.5, color=P.TEXT)
    axes[-1].set_xlim(0, FRAME_T)
    axes[-1].set_xlabel('T-state in the TV frame (48K, 69888 T)')
    handles = [P.plt.Rectangle((0, 0), 1, 1, color=c) for _, _, _, c in BANDS] + [P.plt.Rectangle((0, 0), 1, 1, color=OTHER[1])]
    labels = [b[0] for b in BANDS] + [OTHER[0]]
    handles += [P.plt.Line2D([0], [0], color=c, lw=2) for _, c in SOURCES.values()]
    labels += [f'OUT: {name}' for name, _ in SOURCES.values()]
    fig.legend(handles, labels, loc='lower center', ncol=3, fontsize=8.5, frameon=False)
    fig.suptitle(f'w2 frames {frames[0]}-{frames[-1]}: the laser effect (requested at {frames[0]}:23772) sounds only in the time the '
                 'play interrupt leaves; the explosion of slot 1\n(StartExplosion at 703) opens the noise channels: the '
                 'toggles per row, strip and slot write 0 at 702 and sound from 703. Long tick = speaker bit 4 set',
                 fontsize=11)
    fig.subplots_adjust(left=0.08, right=0.98, top=0.86, bottom=0.2, hspace=0.35)
    path = P.out('sound', 'beeper-frame.png')
    P.save(fig, path)
    for f, n in counts.items():
        print(f, n)


if __name__ == '__main__':
    main()
