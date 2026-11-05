#!/usr/bin/env python3
"""Doc 13 figure: where robots lose their time on the real map (docs/img/path/stuck-map.png).

    python3 tools/path_lab.py stuck --runs 300 --cap 3000 --out work/path/stuck.npz
    python3 tools/path_lab.py deep --out work/path/deep-stuck.json
    python3 tools/fig_path_stuck.py --stuck work/path/stuck.npz --deep work/path/deep-stuck.json \
        --out docs/img/path/stuck-map.png

The map of work/deep frame 3000 (robots and the ship removed, every factory neutral) in four bands of 128 columns.
The heat is the game turns robots spent on each anchor cell: 300 runs each of a bipod, a tracked and an anti-grav robot
with order 6 from a random free cell, each run ended at its door or after 3000 turns. The boxes are the long
stretches of work/deep where a robot with a moving order stayed within 12 columns for 6000+ frames.
"""
import argparse
import json
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.colors import LogNorm, ListedColormap  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#8a8d99'
DOOR_F, DOOR_W, DEEP = '#e5534b', '#d9a441', '#4fd1e8'
BAND = 128
MIN_TURNS = 50                # cells robots only walked across are left out


def terrain_classes(mp):
    t = mp & 0x1F
    c = np.zeros(mp.shape)
    c[t > 0] = 1                  # low ground a bipod walks on
    c[t >= 0x08] = 2              # stops a bipod
    c[t >= 0x0C] = 3              # stops tracks too
    c[t >= 0x0F] = 4              # stops every robot
    return c


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--stuck', required=True)
    p.add_argument('--deep', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    d = np.load(args.stuck, allow_pickle=True)
    mp = d['map']
    occ = sum(d[k] for k in d.files if k.startswith('occ_'))
    deep = json.load(open(args.deep))
    pts = d['points']
    doors_w = [(int(pts[5 * i]) | int(pts[5 * i + 1]) << 8, int(pts[5 * i + 2])) for i in range(4)]
    doors_f = [(int(pts[20 + 5 * i]) | int(pts[21 + 5 * i]) << 8, int(pts[22 + 5 * i])) for i in range(24)]
    stuck_runs = {k[len('arrived_'):]: int((d[k] < 0).sum()) for k in d.files if k.startswith('arrived_')}
    runs = {k: len(d['arrived_' + k]) for k in stuck_runs}
    classes = terrain_classes(mp)
    ground = ListedColormap(['#1c1d24', '#262833', '#3b3f4f', '#555a6e', '#8a8fa3'])
    heat = plt.get_cmap('inferno').copy()
    heat.set_bad(alpha=0)
    fig = plt.figure(figsize=(9.6, 8.4), dpi=100)
    fig.patch.set_facecolor(BG)
    norm = LogNorm(vmin=MIN_TURNS, vmax=max(occ.max(), MIN_TURNS * 10))
    for b in range(4):
        ax = fig.add_axes([0.06, 0.73 - b * 0.18, 0.92, 0.15])
        x0 = b * BAND
        ax.imshow(classes[:, x0:x0 + BAND], cmap=ground, vmin=0, vmax=4, extent=(x0 - 0.5, x0 + BAND - 0.5, 15.5, -0.5),
                  interpolation='nearest', aspect='auto')
        h = np.ma.masked_less(occ[:, x0:x0 + BAND], MIN_TURNS)
        im = ax.imshow(h, cmap=heat, norm=norm, extent=(x0 - 0.5, x0 + BAND - 0.5, 15.5, -0.5),
                       interpolation='nearest', aspect='auto', alpha=0.9)
        for (x, y), c in [(v, DOOR_F) for v in doors_f] + [(v, DOOR_W) for v in doors_w]:
            if x0 <= x < x0 + BAND:
                ax.add_patch(Rectangle((x - 0.5, y - 0.5), 1, 1, fill=False, ec=c, lw=1.6))
        for e in deep:
            if x0 <= e['xmin'] < x0 + BAND:
                ax.add_patch(Rectangle((e['xmin'] - 0.5, e['ymin'] - 1.5), e['xmax'] - e['xmin'] + 2,
                                       e['ymax'] - e['ymin'] + 2, fill=False, ec=DEEP, lw=1.2, ls='--'))
                ax.text(e['xmin'] + 0.2, e['ymax'] + 0.3, f"{e['slot']}", color=DEEP, fontsize=8, va='bottom',
                        weight='bold')
        ax.set_xlim(x0 - 0.5, x0 + BAND - 0.5)
        ax.set_ylim(15.5, -0.5)
        ax.set_facecolor(AX)
        ax.tick_params(colors=DIM, labelsize=7)
        ax.set_yticks([1, 8, 15])
        ax.set_xticks(range(x0, x0 + BAND + 1, 16))
        for s in ax.spines.values():
            s.set_color('#2c2e38')
        ax.set_ylabel('row', color=DIM, fontsize=7)
    ax.set_xlabel('map column', color=DIM, fontsize=8)
    cax = fig.add_axes([0.06, 0.055, 0.35, 0.015])
    cb = fig.colorbar(im, cax=cax, orientation='horizontal')
    cb.ax.tick_params(colors=DIM, labelsize=7)
    cb.set_label(f'game turns spent with the anchor on the cell, all runs ({MIN_TURNS}+ shown)', color=DIM, fontsize=8)
    lost = ', '.join(f'{k} {stuck_runs[k]}/{runs[k]}' for k in ('bipod', 'tracks', 'anti-grav') if k in runs)
    fig.suptitle(f'Order 6 on the real map: the robots that never reach their door ({lost})\n'
                 'pace in a few places in front of doors that need a detour, as robots of work/deep did',
                 color=FG, fontsize=11, y=0.985)
    legend = [('■ ground shades: walkable, stops a bipod, stops tracks, stops all (lighter = taller)', DIM),
              ('□ factory door', DOOR_F), ('□ warbase door', DOOR_W), ('┅ work/deep: robot slot N stayed within 12 columns 6000+ frames', DEEP)]
    for i, (t, c) in enumerate(legend):
        fig.text(0.45 if i else 0.45, 0.075 - 0.02 * i, t, color=c, fontsize=8)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, facecolor=fig.get_facecolor())
    print(args.out)


if __name__ == '__main__':
    main()
