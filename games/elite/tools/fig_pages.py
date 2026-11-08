#!/usr/bin/env python3
"""A labelled sheet of recorded screens (docs/08-hud-and-text.md): the pages and messages the text printer drew, from
the recordings' screen captures (work/<recording>/screens/FFFFFF.scr, one every 250 frames).

    python3 tools/fig_pages.py OUT.png --title TEXT RECORDING:FRAME:LABEL [RECORDING:FRAME:LABEL ...]

A shot TRACE.uatr:end:LABEL is the screen in an access trace's memory at its last instruction instead.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import rtplot as P  # noqa: E402
import zxscreen as Z  # noqa: E402


def screen(rec, frame):
    if rec.endswith('.uatr'):
        trace = K.access_trace().load(os.path.join(P.CASE, rec))
        return bytes(trace.memory_at(len(trace.instructions) - 1)[0x4000:0x5B00])
    return open(os.path.join(P.CASE, 'work', rec, 'screens', '%06d.scr' % int(frame)), 'rb').read()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('out')
    p.add_argument('shots', nargs='+')
    p.add_argument('--title', default='Recorded screens')
    p.add_argument('--columns', type=int, default=2)
    args = p.parse_args()
    shots = [s.split(':', 2) for s in args.shots]  # RECORDING:FRAME:LABEL
    cols = args.columns
    rows = (len(shots) + cols - 1) // cols
    fig, axes = P.figure(4.7 * cols, 3.85 * rows + 0.5, nrows=rows, ncols=cols)
    axes = axes.flatten() if hasattr(axes, 'flatten') else [axes]
    for ax in axes:
        ax.axis('off')
    for ax, (rec, frame, label) in zip(axes, shots):
        ax.imshow(Z.render(screen(rec, frame), 2), interpolation='nearest')
        where = os.path.basename(rec)[:-5] if rec.endswith('.uatr') else '%s %s' % (rec, frame)
        ax.set_title('%s: %s' % (where, label), fontsize=10)
    fig.suptitle(args.title, fontsize=12)
    fig.tight_layout()
    P.save(fig, args.out)


if __name__ == '__main__':
    main()
