#!/usr/bin/env python3
"""The fight frame by frame (docs/runtime-analysis.md, section 4): a heatmap of routine x frame and the stacked cost
of each frame by module, with the 3D updates and the spikes marked.

    python3 tools/fig_rt_frames.py [--scene combat]

Figures: docs/img/runtime/<scene>-heatmap.png, docs/img/runtime/<scene>-frames.png. The profile is the scene's
(tools/rtscenes.py); frame_self gives each routine's T in each frame, the calls log of ClearView the update starts.
"""
import argparse
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402
import rtscenes as S  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--scene', default='combat')
    ap.add_argument('--rows', type=int, default=26)
    a = ap.parse_args()
    sc = S.scene(a.scene)
    p = S.profile(sc)
    f0 = p['frames'][0]
    fs = p['frame_self']
    n = len(next(iter(fs.values())))
    names = sorted(fs, key=lambda k: -sum(fs[k]))[:a.rows]
    mat = np.array([fs[k] for k in names], dtype=float)
    updates = [f0 + t // S.FRAME_T for t, _d in p['calls'].get('ClearView', [])]
    copies = [f0 + t // S.FRAME_T for t, _d in p['calls'].get('CopyBackBuffer', [])]

    # 1. heatmap
    fig, ax = P.figure(9, 8)
    im = ax.imshow(mat, aspect='auto', cmap='inferno', interpolation='nearest',
                   extent=(f0 - 0.5, f0 + n - 0.5, len(names) - 0.5, -0.5), vmin=0, vmax=S.FRAME_T)
    ax.set_yticks(range(len(names)))
    ax.set_yticklabels(names, fontsize=8)
    for u in updates:
        ax.axvline(u, color=P.EXEC, lw=0.6, alpha=0.7)
    ax.set_xlabel('frame of %s (green lines: a 3D update starts, ClearView)' % sc[2], fontsize=9)
    cb = fig.colorbar(im, ax=ax, fraction=0.025, pad=0.01)
    cb.set_label('T-states in the frame (69888 = the whole frame)', fontsize=9)
    ax.set_title('%s, routine x frame: CopyThird and ClearView pulse once an update\n(every 6-7 frames); '
                 'SoundSweep fills whole frames while the laser fires' % sc[1], fontsize=10)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/%s-heatmap.png' % a.scene)

    # 2. stacked per frame by module
    mods = {}
    for k, row in fs.items():
        m = P.module(p['routines'][k]['module'])
        if m.startswith('data:'):
            m = 'other'
        mods.setdefault(m, np.zeros(n))
        mods[m] += np.array(row)
    order = sorted(mods, key=lambda m: -mods[m].sum())
    cols = P.colours([m for m in order if m != 'halt'], {'halt': P.OTHER})
    fig, ax = P.figure(9, 7.6)
    bottom = np.zeros(n)
    xs = np.arange(f0, f0 + n)
    for m in order:
        ax.bar(xs, mods[m], bottom=bottom, width=1.0, color=cols[m], label=P.module_label(m), edgecolor='none')
        bottom += mods[m]
    for u in updates:
        ax.axvline(u - 0.5, color=P.TEXT, lw=0.5, alpha=0.5)
    snd = mods.get('sound', np.zeros(n))
    peaks = [i for i in range(n) if snd[i] > 0.5 * S.FRAME_T]
    if peaks:
        ax.annotate('the laser\'s sweep: %d frames over half sound' % len(peaks), (xs[peaks[0]], S.FRAME_T * 1.02),
                    xytext=(xs[peaks[0]] + 5, S.FRAME_T * 1.12), fontsize=9, color=P.TEXT,
                    arrowprops={'arrowstyle': '->', 'color': P.TEXT})
    ax.set_ylim(0, S.FRAME_T * 1.25)
    ax.axhline(S.FRAME_T, color=P.WRITE, lw=0.8, ls='--')
    ax.set_xlim(f0 - 0.5, f0 + n - 0.5)
    ax.set_xlabel('frame of %s (thin lines: a 3D update starts; %d updates in %d frames)' % (sc[2], len(updates), n),
                  fontsize=9)
    ax.set_ylabel('T-states in the frame', fontsize=9)
    ax.legend(ncol=2, fontsize=8, loc='upper center', bbox_to_anchor=(0.45, -0.13), frameon=False)
    ax.set_title('%s: every frame is full (69888 T); inside an update what fills it changes:\n'
                 'the 3D drawing, the copy at its end, the scanner, the waits' % sc[1], fontsize=10)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/%s-frames.png' % a.scene)
    gaps = np.diff(sorted(set(updates)))
    print('updates', len(updates), 'gaps (frames):', dict(zip(*np.unique(gaps, return_counts=True))))
    print('copies', len(copies))


if __name__ == '__main__':
    main()
