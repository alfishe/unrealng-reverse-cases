#!/usr/bin/env python3
"""Difference report figure (work/diff/shell.md): from the load command to play, Nether Earth's tape against ANE's
disk, in seconds, from both cases' recordings.

    python3 tools/fig_diff_shell_load.py --out docs/img/diff/shell-load.png

The moments are read from the recordings, not typed:
  Nether Earth, the tape at ROM speed: ../nether-earth/work/ill3/load/load.json (both tape traps off; frame 0 = the
      tape starts; a sample every 30 frames to 1200, then every 200): the block each sample plays, N1's IX, the PC;
  Nether Earth, recording `play`: ../nether-earth/work/play/l1.json (first frames of N1 $FCDA, Start $A600, the
      menu tune $C4FD, PlayLoop $A69A; blocks 0-3 went through the emulator's fast-load trap, doc 03 3.3);
  ANE, recording d1: work/docR/d1/l1.json (first frames of UltraXOR's entry $5D97, LoaderMain $6221, the first
      LoaderInterrupt $6161, the boot menu's key 1 $B168, GameEntry $A5DA, MainMenu $C100, PlayLoop $A69A) and its
      input script work/docR/inputs/d1.txt (RUN ENTER at script frame 342, SPACE 6600, 1 7100, 0 9600; recording
      frame = script frame + 1601);
  ANE, the shortest path: d1's stages that run without the player, joined with no wait for the player (SPACE at the
      first LoaderInterrupt, each key as soon as its screen reads it). It is computed from d1, not recorded.
A 48K frame is 69 888 T (19.97 ms), a Pentagon frame 71 680 T (20.48 ms), both at 3.5 MHz.
"""
import argparse
import json
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from PIL import Image  # noqa: E402

import fig_diff_shell_common as C  # noqa: E402

NE_S, ANE_S = 69888 / 3.5e6, 71680 / 3.5e6
STAGE = {'rom': ('#7a7d8c', 'ROM / TR-DOS loads the BASIC'),
         'loader': ('#d9a441', 'the loader (N1; UltraXOR and its reader)'),
         'block': ('#e5534b', 'the game loads (tape block 4; the boot reads and unpacks)'),
         'show': ('#e07ad0', 'the authors\' show: intro, scroller, title cards'),
         'menu': ('#8e7cc3', 'a menu waits for the player'),
         'play': ('#4caf50', 'play')}


def first_frames(path):
    out = {}
    for r in json.load(open(path))['routines']:
        p = r.get('profile') or {}
        if p.get('first_frame') is not None:
            key = r['entry']
            out[key] = min(out.get(key, 1 << 30), p['first_frame'])
    return out


def ne_rows():
    samples = json.load(open(os.path.join(C.NE, 'work/ill3/load/load.json')))
    first_block = {}
    for s in samples:
        b = s['tape']['block']
        first_block.setdefault(b, s['frame'])
    # the game block's end: the last sample N1 still loads, the bytes left at its IX against the block's end
    loading = [s for s in samples if s['tape']['state'] == 'playing' and s['tape']['block'] == 4]
    last = loading[-1]
    menu = next(s['frame'] for s in samples if 0xC100 <= s['pc'] < 0xD6A8 and s['tape']['state'] == 'ended')
    left = 0xFCE9 - last['ix']
    end = last['frame'] + round(left * 8 / 1365 / NE_S)        # ~1365 bit/s: the ROM's average for this block
    f = first_frames(os.path.join(C.NE, 'work/play/l1.json'))
    menu_to_play = f['$A69A'] - f['$C4FD']       # the tune starts, the player presses 0 at once ...
    to_play_key = f['$A69A'] - 12814             # ... in `play` the tune stopped at 12814 (0), PlayLoop 27 later
    rom = [('rom', 0, first_block[2]), ('loader', first_block[2], first_block[4]), ('block', first_block[4], end),
           ('menu', end, end + 7), ('play', end + 7 + to_play_key, end + 7 + to_play_key + 120)]
    play = [('rom', 0, f['$FCDA']), ('block', f['$FCDA'], f['$A600']), ('menu', f['$A600'], f['$A69A']),
            ('play', f['$A69A'], f['$A69A'] + 120)]
    print(f'NE: ROM speed game start ~{end} (IX ${last["ix"]:04X} at {last["frame"]}, {left} bytes left; menu by '
          f'{menu}); play {end + 7 + to_play_key}; `play` recording: N1 {f["$FCDA"]}, Start {f["$A600"]}, PlayLoop '
          f'{f["$A69A"]} (menu to play {menu_to_play} frames with the tune)')
    return rom, play


def ane_rows():
    f = first_frames(os.path.join(C.ANE, 'work/docR/d1/l1.json'))
    enter, space, key1, key0 = 342 + 1601, 6600 + 1601, 7100 + 1601, 9600 + 1601
    d1 = [('rom', enter, f['$5D97']), ('loader', f['$5D97'], f['$6221']), ('show', f['$6221'], space),
          ('block', space, key1), ('menu', key1 - 2, key1), ('block', key1, f['$A5DA']), ('show', f['$A5DA'], f['$C100']),
          ('menu', f['$C100'], key0), ('block', key0, f['$A69A']), ('play', f['$A69A'], f['$A69A'] + 120)]
    d1 = [(k, a - enter, b - enter) for k, a, b in d1]
    # the shortest path: d1's own stage lengths, the player's waits cut out
    t, fast = 0, []
    for k, n in (('rom', f['$5D97'] - enter), ('loader', f['$6221'] - f['$5D97']), ('show', f['$6161'] - f['$6221']),
                 ('block', key1 - space), ('block', f['$A5DA'] - key1), ('show', f['$C100'] - f['$A5DA']),
                 ('block', f['$A69A'] - key0), ('play', 120)):
        fast.append((k, t, t + n))
        t += n
    print(f'ANE d1: ENTER {enter}, USR {f["$5D97"]}, loader {f["$6221"]}, first LoaderInterrupt {f["$6161"]}, '
          f'SPACE {space}, key 1 {key1} ($B168 {f["$B168"]}), GameEntry {f["$A5DA"]}, MainMenu {f["$C100"]}, '
          f'0 {key0}, PlayLoop {f["$A69A"]}; shortest path to play {fast[-1][1]} frames')
    return d1, fast


def thumb(path, keep_border=False):
    im = Image.open(path).convert('RGB')
    if keep_border:            # the 352 x 288 picture with its border: the tape's stripes are the point
        return im.resize((256, 210), Image.NEAREST)
    return im.resize((256, 192), Image.NEAREST)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=C.out_path('shell-load.png'))
    args = p.parse_args()
    ne_rom, ne_play = ne_rows()
    ane_d1, ane_fast = ane_rows()
    rows = [('Nether Earth: the tape at ROM speed', ne_rom, NE_S, C.NE_COL),
            ('Nether Earth: recording play\n(from power-on; blocks 0-3 fast-loaded)', ne_play, NE_S, C.NE_COL),
            ('ANE: recording d1\n(the intro watched to frame 8201)', ane_d1, ANE_S, C.ANE_COL),
            ('ANE: the shortest path\n(d1\'s stages, no waiting)', ane_fast, ANE_S, C.ANE_COL)]
    fig = plt.figure(figsize=(14, 13), dpi=100)
    gs = fig.add_gridspec(2, 1, height_ratios=[1.1, 1.5], hspace=0.22)
    ax = fig.add_subplot(gs[0])
    C.style(fig, (ax,))
    for i, (name, segs, sec, col) in enumerate(rows):
        y = len(rows) - 1 - i
        for k, a, b in segs:
            if k == 'play':
                ax.barh(y, 6, left=a * sec, height=0.55, color=STAGE[k][0], lw=0)
                ax.text(a * sec + 7, y, f'play at {a * sec:.1f} s (frame {a:,})'.replace(',', ' '), color=C.FG,
                        fontsize=9.5, va='center')
            else:
                ax.barh(y, (b - a) * sec, left=a * sec, height=0.55, color=STAGE[k][0], lw=0)
        ax.text(-4, y, name, color=col, fontsize=9.5, ha='right', va='center')
    ax.set_xlim(0, 320)
    ax.set_ylim(-0.7, len(rows) - 0.3)
    ax.set_yticks([])
    ax.set_xlabel('seconds from the ENTER of the load command (NE: LOAD ""; ANE: RUN "A_NETHER" in TR-DOS)',
                  color=C.DIM, fontsize=9)
    ax.set_title('To play: four and a half minutes of tape, or 26 seconds of disk, of which ANE spends most on its own '
                 'show', color=C.FG, fontsize=12.5, loc='left')
    from matplotlib.patches import Patch
    ax.legend(handles=[Patch(color=c, label=l) for c, l in STAGE.values()], loc='upper center', ncol=3, fontsize=8.5,
              bbox_to_anchor=(0.45, -0.13), frameon=False, labelcolor='#d6d8e0')

    # the screens on the way
    shots = [
        ('NE', os.path.join(C.NE, 'work/ill3/load/frames/06000.png'), 'the tape loads: black screen,\nstripes in the border (6000)', 'border'),
        ('NE', os.path.join(C.NE, 'work/ill3/tour/state-menu.png'), 'the main menu\n(tour frame 60)', False),
        ('NE', os.path.join(C.NE, 'work/ill3/tour/state-play.png'), 'play', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/eternity.png'), 'intro, Eternity logo\n(d1 2700)', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/star.png'), 'star + credits\n(d1 5000)', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/title.png'), 'title while the\ndisk reads (d1 8400)', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/boot.png'), 'boot menu\n(d1 8690)', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/card3.png'), 'title card 3\n(d1 9150)', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/menu.png'), 'game menu\n(d1 9216)', False),
        ('ANE', os.path.join(C.ANE, 'work/docR/shots2/play.png'), 'play\n(d1 13020)', False),
    ]
    sub = gs[1].subgridspec(2, 5, wspace=0.08, hspace=0.32)
    for i, (who, path, cap, crop) in enumerate(shots):
        a = fig.add_subplot(sub[i // 5, i % 5])
        a.imshow(thumb(path, crop))
        a.set_xticks([])
        a.set_yticks([])
        for s in a.spines.values():
            s.set_color(C.NE_COL if who == 'NE' else C.ANE_COL)
            s.set_linewidth(2)
        a.set_title(f'{who}: {cap}', color=C.NE_COL if who == 'NE' else C.ANE_COL, fontsize=9, pad=4)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print('wrote', args.out)


if __name__ == '__main__':
    sys.exit(main())
