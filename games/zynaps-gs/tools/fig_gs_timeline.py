#!/usr/bin/env python3
"""Docs 03 and 04 figures: what goes to the General Sound card when, from the port journal of the recording r1.

    python3 tools/fig_gs_timeline.py export --work work/zgsA/r1
    python3 tools/fig_gs_timeline.py upload --work work/zgsA/r1 --out docs/img/load/gs-upload.png
    python3 tools/fig_gs_timeline.py level  --work work/zgsA/r1 --out docs/img/loop/level-load.png
    python3 tools/fig_gs_timeline.py boot   --work work/zgsA/r1 --out docs/img/load/boot.png

r1 (work/stage2/r1/session.ttd) is a power-on recording of 4724 frames: the boot, the options menu, key 1, the title,
fire, level 1 in music mode. `export` asks the instance holding it (time_travel port_events, no replay) for every
OUT to the card's command port $BB and data port $B3, to the FDC's command register $1F and to $7FFD, into
work/zgsA/r1-*.json. The figures count them per frame:

upload: the whole recording. Lanes: the sectors the FDC was told to read (command #80), the bytes written to the
card's data port, each GS command at its frame (named as tools/gs_digest.py names it), the $7FFD writes (the page
at $C000); the stretches named by what they carry; the screen at six moments above.
boot: frames 0-1530 of r1, the same lanes, with the moment each block first ran.
level: the level change of r1 only (RoundStartHook to the first in-game FX), the same lanes, frame by frame.
"""
import argparse
import collections
import json
import os
import sys

import zgsplot as P
import zgslib as Z
from gs_digest import NAMES

plt = P.plt


def name(c):
    if 0x80 <= c <= 0x9F:
        return f'#{c:02X} play FX ch {c - 0x80}'
    return f'#{c:02X} {NAMES.get(c, "?")}'


def export(work):
    s = Z.session(work)
    for tag, port, mask, lim in (('gscmd', '0xBB', '0xFF', 5000), ('gsdata', '0xB3', '0xFF', 400000),
                                 ('fdc-cmd', '0x1F', '0xFF', 5000), ('p7ffd', '0x0000', '0x8002', 5000)):
        r = s.call('time_travel', {'action': 'port_events', 'event': 'out', 'port': port, 'port_mask': mask,
                                   'limit': lim, 'context': False}, ok=False)
        json.dump(r.structured, open(os.path.join(work, '..', f'r1-{tag}.json'), 'w'))
        print(tag, (r.text or '').splitlines()[0])


def load(work):
    base = os.path.join(work, '..')
    j = {t: json.load(open(os.path.join(base, f'r1-{t}.json')))['hits'] for t in ('gscmd', 'gsdata', 'fdc-cmd', 'p7ffd')}
    reads = collections.Counter(h['frame'] for h in j['fdc-cmd'] if h['value'] & 0xE0 == 0x80)
    data = collections.Counter(h['frame'] for h in j['gsdata'])
    return j, reads, data


SPANS = [  # from, to, label, text x, text y (the frames of r1's GS data runs; what each run is: the command before
    # it, the loader)
    (1524, 1850, 'title module (level 13)\n51 456 B, read from disk', 1450, 4.1),
    (2377, 2391, 'start jingle 9 946 B\nfrom bank 1', 2150, 4.55),
    (2473, 2792, 'level 1 module 59 392 B\nread from disk', 2640, 4.1),
    (2862, 2931, 'FX 1-10, 50 533 B\nfrom banks 1, 3, 4, 6', 3300, 4.55),
]
SHOTS = [(1450, 'options menu'), (1700, 'title module load:\nthe loading screen'), (2200, 'title pages'),
         (2392, 'game start: jingle'), (2650, 'level 1 load'), (3100, 'play, level 1')]


def lanes(ax, j, reads, data, lo, hi, events=True, cmd_every=False):
    fr = list(range(lo, hi + 1))
    top = max(data.values())
    ax.bar(fr, [data.get(f, 0) / top * 0.9 for f in fr], width=1.0, bottom=2, color='#d9a441', linewidth=0)
    rmax = max(reads.values())
    ax.bar(fr, [reads.get(f, 0) / rmax * 0.9 for f in fr], width=1.0, bottom=3, color='#4fa3ff', linewidth=0)
    pg = [(h['frame'], h['value'] & 7) for h in j['p7ffd'] if lo <= h['frame'] <= hi]
    for f, b in pg:
        ax.plot([f, f], [0.05, 0.95], color=P.COLOURS[b % len(P.COLOURS)], lw=1.2)
    seen = set()
    for h in j['gscmd']:
        f = h['frame']
        if lo <= f <= hi:
            ax.plot([f], [1.5], marker='|', ms=14, color='#e5534b')
            if cmd_every and (f, h['value']) not in seen:
                seen.add((f, h['value']))
    ax.set_yticks([0.5, 1.5, 2.45, 3.45])
    ax.set_yticklabels(['$7FFD write\n(colour = bank)', 'GS command', f'GS data bytes\n(max {top}/frame)',
                        f'FDC read sector\n(max {rmax}/frame)'], fontsize=8.5)
    ax.set_ylim(-0.1, 4.2)
    ax.set_xlim(lo, hi)
    ax.grid(axis='x', alpha=0.3)


def upload(work, out):
    j, reads, data = load(work)
    P.style()
    fig = plt.figure(figsize=(12, 7.2), dpi=80)
    gs = fig.add_gridspec(2, 6, height_ratios=[1.0, 2.2], hspace=0.35)
    lo, hi = 0, 4724
    for i, (f, lab) in enumerate(SHOTS):
        a = fig.add_subplot(gs[0, i])
        a.imshow(Z.render(Z.cached(work, f)))
        a.set_xticks([])
        a.set_yticks([])
        a.set_title(f'{lab}\nframe {f}', fontsize=8.5)
    ax = fig.add_subplot(gs[1, :])
    lanes(ax, j, reads, data, lo, hi)
    for a, b, lab, tx, ty in SPANS:
        ax.annotate(lab, xy=((a + b) / 2, 2.95), xytext=(tx, ty),
                    ha='center', va='bottom', fontsize=8, arrowprops=dict(arrowstyle='-', color=P.DIM, lw=0.6))
        ax.axvspan(a, b, color='#d9a441', alpha=0.08)
    ax.text(400, 4.1, 'the boot: 321 sectors,\nnothing to the card', ha='center', va='bottom', fontsize=8)
    ax.text(3800, 1.75, 'play: 3 or 4 commands an effect\n(#2E, #40, #81 or #45, #39)', ha='center', va='bottom',
            fontsize=8)
    ax.set_ylim(-0.1, 5.3)
    ax.set_xlabel('frame of r1 (50 a second)')
    fig.suptitle('Nothing reaches the card until the menu is left; then the title module, the jingle and the level '
                 '1 module\nand FX go up in three bursts, and play sends only a few commands an effect', fontsize=11)
    fig.savefig(out, bbox_inches='tight')
    print(out)


def level(work, out):
    j, reads, data = load(work)
    P.style()
    lo, hi = 2400, 3010
    fig = plt.figure(figsize=(12, 6.4), dpi=80)
    gs = fig.add_gridspec(2, 5, height_ratios=[1.0, 2.1], hspace=0.35)
    for i, (f, lab) in enumerate([(2410, 'PREPARE FOR COMBAT'), (2475, 'module from disk'),
                                  (2880, 'FX from the banks'), (2945, 'play screen redrawn'),
                                  (3000, 'play')]):
        a = fig.add_subplot(gs[0, i])
        a.imshow(Z.render(Z.cached(work, f)))
        a.set_xticks([])
        a.set_yticks([])
        a.set_title(f'{lab}\nframe {f}', fontsize=8.5)
    ax = fig.add_subplot(gs[1, :])
    lanes(ax, j, reads, data, lo, hi)
    marks = [(2469, 0.5, 'RoundStartHook\npages bank 1', 2405, 4.45), (2471, 1.5, '#23 #F3 reset', 2440, 3.75),
             (2473, 1.5, '#30 #D1 load module', 2505, 4.45), (2792, 1.5, '#D2 end', 2775, 4.45),
             (2794, 1.5, '#38 load FX x10', 2830, 4.45), (2931, 1.5, '#2B #2A #31\nplay module', 2905, 4.45),
             (2951, 1.5, 'first FX', 2975, 4.45)]
    for f, y, lab, tx, ty in marks:
        ax.annotate(lab, xy=(f, y), xytext=(tx, ty), fontsize=7.5, ha='center', va='bottom',
                    arrowprops=dict(arrowstyle='-', color=P.DIM, lw=0.6))
    ax.annotate('', xy=(2469, 4.15), xytext=(2933, 4.15), arrowprops=dict(arrowstyle='<->', color=P.TEXT))
    ax.text(2650, 3.98, '464 frames (9.3 s) without play', ha='center', va='top', fontsize=9)
    ax.set_ylim(-0.1, 5.4)
    ax.set_xlabel('frame of r1')
    fig.suptitle('The level change stops the game for 464 frames: the module read from 163 sectors and sent byte by byte, '
                 'then\nthe 10 FX from the RAM banks; the page writes are the loader switching banks 7, 3, 4, 6',
                 fontsize=11)
    fig.savefig(out, bbox_inches='tight')
    print(out)


BOOT_MARKS = [  # frame, lane y, label, text x, text y: the first run of each address (time_travel find_event exec)
    (150, 0.5, 'BASIC USR 23882\n$5D4A (150)', 60, 4.45),
    (175, 3.0, 'block 0 at $7E2C (175):\nthe loading screen', 190, 3.75),
    (287, 3.0, 'block 1 at $D29F\n(287): bank 1', 320, 4.45),
    (385, 3.0, 'bank 3 raw\n(310-385)', 400, 3.75),
    (460, 3.0, 'block 2 at $BED4\n(460): bank 4', 520, 4.45),
    (548, 3.0, 'block 3 at $BED4\n(548): bank 6', 610, 3.75),
    (684, 3.0, 'block 4 at $607C\n(684): the game', 740, 4.45),
    (746, 0.5, 'fade out\n$5D9F (746)', 840, 3.75),
    (812, 0.5, 'options menu\n$6D60 (812)', 960, 4.45),
    (1500, 0.5, 'key 1: the\ninstaller $61A8 (1500)', 1380, 4.45),
]


def boot(work, out):
    j, reads, data = load(work)
    P.style()
    lo, hi = 0, 1530
    fig = plt.figure(figsize=(12, 6.6), dpi=80)
    gs = fig.add_gridspec(2, 6, height_ratios=[1.0, 2.1], hspace=0.35)
    for i, (f, lab) in enumerate([(120, 'TR-DOS'), (205, 'block 0 fades in'), (400, 'banks loading'),
                                  (700, 'block 4 unpacking'), (780, 'fade out'), (1000, 'options menu')]):
        a = fig.add_subplot(gs[0, i])
        a.imshow(Z.render(Z.cached(work, f)))
        a.set_xticks([])
        a.set_yticks([])
        a.set_title(f'{lab}\nframe {f}', fontsize=8.5)
    ax = fig.add_subplot(gs[1, :])
    lanes(ax, j, reads, data, lo, hi)
    for k, (f, y, lab, tx, ty) in enumerate(BOOT_MARKS):
        ax.annotate(lab, xy=(f, y), xytext=(f + 15, 4.1 + 0.75 * (k % 3)), fontsize=7.5, ha='center',
                    va='bottom', arrowprops=dict(arrowstyle='-', color=P.DIM, lw=0.6))
    ax.set_ylim(-0.1, 6.5)
    ax.set_xlabel('frame of r1 (from power-on)')
    fig.suptitle('The boot: 321 sectors in six reads, each Trush block run where it landed (the $7FFD writes page '
                 'its bank);\nthe card gets nothing, the menu waits from frame 812', fontsize=11)
    fig.savefig(out, bbox_inches='tight')
    print(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('what', choices=['export', 'upload', 'level', 'boot'])
    ap.add_argument('--work', required=True)
    ap.add_argument('--out')
    a = ap.parse_args()
    if a.what == 'export':
        export(a.work)
    elif a.what == 'upload':
        upload(a.work, a.out or P.out('load', 'gs-upload.png'))
    elif a.what == 'boot':
        boot(a.work, a.out or P.out('load', 'boot.png'))
    else:
        level(a.work, a.out or P.out('loop', 'level-load.png'))


if __name__ == '__main__':
    main()
