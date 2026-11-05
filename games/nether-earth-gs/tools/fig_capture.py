#!/usr/bin/env python3
"""Capture the raw frames that fig_screens.py and fig_compare.py turn into figures: every medium of the GS conversion
started the way a player starts it, and Nether Earth's own tape at the same moments, on two live gs_session.py
instances (muted). Reads orig/ and ../nether-earth/orig/NETHER.TAP only.

    python3 tools/fig_capture.py [--out work/stage2/shots] [--base-gs 12400] [--base-ne 12420] [--only gs|ne]

OUT/a: Pentagon 128 + GS 512 KB. The 2002 SCL (RUN "neart GS"), the TRD's HRUM boot menu and its three entries
(neart GS, Neart481, Neart482), Hood's 2017 tape from the 128 menu's Tape Loader (it hangs at the first sound in
play) and from 128 BASIC via PRINT USR 0 (it plays). OUT/ne: a 48K, no card, Nether Earth's NETHER.TAP.

Each shot:NAME is a 352 x 288 PNG (the border included, the screen at (48, 48)); the bot parts (play_gs.py, NE's
bot steering by keys) add OUT/{a,ne}/<dir>/tap-04 .. tap-08. About 50 000 emulated frames; a few minutes.
"""
import argparse
import os
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(ROOT, 'tools')
TRD = 'orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2002 Tron Z].trd'
TAP = 'orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2017 Hood, Tron Z].tap'
NE_TAP = '../nether-earth/orig/NETHER.TAP'

# Input scripts (re_session.py's format: frame, keys; '-' releases). The Pentagon 128 menu: CS+7 (up, wraps to
# TR-DOS), ENTER; then in TR-DOS RUN "neart GS" (the SCL) or RUN ENTER (the TRD's boot).
SCL_BOOT = """0 cs 7
6 -
20 ENTER
26 -
150 R
156 -
166 ss P
172 -
182 N
188 -
198 E
204 -
214 A
220 -
230 R
236 -
246 T
252 -
262 SPACE
268 -
278 cs G
284 -
294 cs S
300 -
310 ss P
316 -
326 ENTER
332 -
400 END
"""
TRD_BOOT = """0 cs 7
6 -
20 ENTER
26 -
150 R
156 -
166 ENTER
172 -
240 END
"""


def gs(*args):
    cmd = [sys.executable, os.path.join(TOOLS, 'gs_session.py')] + list(args)
    print('+', ' '.join(cmd[2:]), flush=True)
    out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    for line in out.stdout.splitlines():
        if 'Screenshot saved' not in line and 'Snapshot loaded' not in line:
            print('  ', line[:300])
    if out.returncode:
        sys.exit(out.stderr)


def play(work, shots, frames):
    cmd = [sys.executable, os.path.join(TOOLS, 'play_gs.py'), '--work', work, '--shots', shots, '--frames', str(frames)]
    print('+', ' '.join(cmd[1:]), flush=True)
    subprocess.run(cmd, cwd=ROOT, check=True, capture_output=True)


def typed(text, hold=4, gap=8):
    """key steps typing a word on the Spectrum keyboard (letters, digits, space)"""
    steps = []
    for ch in text:
        steps += ['key:%s:%d' % ('space' if ch == ' ' else ch, hold), 'run:%d' % gap]
    return steps


def capture_gs(out, base):
    w = os.path.join(out, 'a')
    os.makedirs(w, exist_ok=True)
    p = lambda name: os.path.join(w, name)  # noqa: E731
    with zipfile.ZipFile(os.path.join(ROOT, 'orig', 'NE_GS_TZ.zip')) as z:
        open(os.path.join(ROOT, p('ne-gs.scl')), 'wb').write(z.read('NE_GS_TZ.SCL'))
    open(os.path.join(ROOT, p('ne-gs.trd')), 'wb').write(open(os.path.join(ROOT, TRD), 'rb').read())
    open(os.path.join(ROOT, p('scl-boot.txt')), 'w').write(SCL_BOOT)
    open(os.path.join(ROOT, p('trd-boot.txt')), 'w').write(TRD_BOOT)

    gs('launch', '--work', w, '--port-base', str(base), '--model', 'PENTAGON', '--card', 'gs', '--card-ram', '512k')
    try:
        s = lambda *steps: gs('steps', '--work', w, *steps)  # noqa: E731
        s('run:100', 'save:' + p('poweron.szx'), 'shot:' + p('p-128menu'))
        # the SCL: RUN "neart GS" from TR-DOS, the GS-512 loading screen, the menu, key 0
        s('run:150', 'insert:' + p('ne-gs.scl'), 'script:' + p('scl-boot.txt'), 'shot:' + p('scl-a-trdos-run'),
          'run:300', 'shot:' + p('scl-b-loading'), 'run:900', 'shot:' + p('scl-c-loading'),
          'run:2000', 'shot:' + p('scl-d-menu'), 'save:' + p('scl-menu.szx'),
          'key:0:6', 'run:300', 'shot:' + p('scl-e-play'))
        # the TRD: the HRUM boot menu, then each of its entries from the same snapshot
        s('load:' + p('poweron.szx'), 'run:50', 'insert:' + p('ne-gs.trd'), 'script:' + p('trd-boot.txt'),
          'run:300', 'shot:' + p('trd-a-boot'), 'run:200', 'shot:' + p('trd-b-boot'), 'save:' + p('trd-bootmenu.szx'))
        s('key:3:6', 'run:100', 'shot:' + p('n482-a'), 'run:300', 'shot:' + p('n482-b'), 'run:500', 'shot:' + p('n482-c'),
          'load:' + p('trd-bootmenu.szx'), 'key:2:6', 'run:100', 'shot:' + p('n481-a'), 'run:200', 'shot:' + p('n481-b'),
          'run:400', 'shot:' + p('n481-c'), 'run:1500', 'shot:' + p('n481-d'), 'regs')
        s('load:' + p('trd-bootmenu.szx'), 'key:1:6', 'run:600', 'shot:' + p('trd-gs-a'), 'run:2600', 'shot:' + p('trd-gs-b'))
        # the tape from the 128 menu's Tape Loader: music prompt, loading, menu, then the bot until the hang
        s('load:' + p('poweron.szx'), 'run:20', 'key:enter:6', 'insert:' + TAP, 'tape:play', 'run:400', 'shot:' + p('tl-a'),
          'run:1100', 'shot:' + p('tl-b'), 'key:1:6', 'run:150', 'shot:' + p('tl-c'), 'run:500', 'shot:' + p('tl-d'),
          'run:2400', 'shot:' + p('tl-e'), 'save:' + p('tl-menu.szx'))
        os.makedirs(os.path.join(ROOT, p('hang')), exist_ok=True)
        play(w, p('hang'), 800)
        s('shot:' + p('tl-hang'), 'regs', 'run:500', 'shot:' + p('tl-hang-500'), 'regs')
        # the tape from 128 BASIC: PRINT USR 0 (48 BASIC with paging free), LOAD "", music ON
        s('load:' + p('poweron.szx'), 'run:20', 'key:down:4', 'run:20', 'shot:' + p('u-b'), 'key:enter:4', 'run:60',
          *typed('print usr 0'), 'key:enter:4', 'run:100', 'shot:' + p('u-c'),
          'key:j:4', 'run:10', 'key:symbol+p:4', 'run:10', 'key:symbol+p:4', 'run:10', 'shot:' + p('u-d'),
          'key:enter:4', 'insert:' + TAP, 'tape:play', 'run:300', 'shot:' + p('u-e'), 'run:200', 'key:1:6',
          'run:3000', 'shot:' + p('u-f'), 'run:10000', 'shot:' + p('u-g'), 'save:' + p('u-menu.szx'))
        os.makedirs(os.path.join(ROOT, p('uplay')), exist_ok=True)
        play(w, p('uplay'), 1100)
    finally:
        gs('stop', '--work', w)


def capture_ne(out, base):
    w = os.path.join(out, 'ne')
    os.makedirs(w, exist_ok=True)
    p = lambda name: os.path.join(w, name)  # noqa: E731
    gs('launch', '--work', w, '--port-base', str(base), '--model', '48K', '--card', 'none')
    try:
        s = lambda *steps: gs('steps', '--work', w, *steps)  # noqa: E731
        s('run:150', 'shot:' + p('ne-a'), 'key:j:4', 'run:10', 'key:symbol+p:4', 'run:10', 'key:symbol+p:4', 'run:10',
          'key:enter:4', 'insert:' + NE_TAP, 'tape:play', 'run:1500', 'shot:' + p('ne-b'), 'run:3000', 'shot:' + p('ne-c'),
          'run:4000', 'shot:' + p('ne-d'), 'run:6000', 'shot:' + p('ne-e'), 'save:' + p('ne-menu.szx'),
          'key:0:5', 'run:300', 'shot:' + p('ne-play'))
        # the menu title cycles its colour: six frames 20 apart (nm3 is the yellow phase)
        s('load:' + p('ne-menu.szx'), *[x for i in range(1, 7) for x in ('run:20', 'shot:' + p('nm%d' % i))])
        s('load:' + p('ne-menu.szx'))
        os.makedirs(os.path.join(ROOT, p('play')), exist_ok=True)
        play(w, p('play'), 900)
    finally:
        gs('stop', '--work', w)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--out', default='work/stage2/shots')
    ap.add_argument('--base-gs', type=int, default=12400)
    ap.add_argument('--base-ne', type=int, default=12420)
    ap.add_argument('--only', choices=['gs', 'ne'])
    a = ap.parse_args()
    if a.only != 'ne':
        capture_gs(a.out, a.base_gs)
    if a.only != 'gs':
        capture_ne(a.out, a.base_ne)


if __name__ == '__main__':
    main()
