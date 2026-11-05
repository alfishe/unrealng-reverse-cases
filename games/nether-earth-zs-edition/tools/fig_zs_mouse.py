#!/usr/bin/env python3
"""Doc 05 figure: the '99 run with a Kempston mouse fitted (docs/img/controls/mouse-test.png).

Draws work/docs/zsA/mouse99/ (written by work/docs/zsA/mouse99.py, a live run from power-on on PENTAGON, mouse
fitted and decoded at $FADF / $FBDF / $FFDF): four screens, the menu and LOAD MAP before and after the mouse was
moved and clicked, with the values read from memory under each (the pointer $DD74 / $DD75, LOAD MAP's index, the
operand at $C27F, the mouse ports); under them the 177 status polls, one every 25 frames, coloured by unreal-ng's
device.in_use (a program read a mouse port within the last 50 frames), with the phases of the run.

    python3 tools/fig_zs_mouse.py --out docs/img/controls/mouse-test.png
"""
import argparse
import json
import os
import sys
from collections import OrderedDict

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fig_common import font  # noqa: E402

ROOT = os.path.dirname(HERE)
RUN = os.path.join(ROOT, 'work', 'docs', 'zsA', 'mouse99')
BG, FG, DIM, NO, YES = (21, 22, 27), (230, 230, 230), (184, 188, 200), (90, 110, 150), (240, 80, 70)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    d = json.load(open(os.path.join(RUN, 'mouse99.json')))
    r = d['res']
    shots = [('menu-before.png', 'the menu (frame 3020): pointer (8,8)'),
             ('menu-after-mouse.png', 'mouse moved (80,60), clicked: pointer (%d,%d)' %
              tuple(r['menu_after_clicks']['pointer'])),
             ('loadmap-before.png', 'LOAD MAP (frame 3383): index 0'),
             ('loadmap-after-mouse.png', 'mouse moved (120,-90), clicked: index %d' %
              r['loadmap_after_mouse']['index'])]
    w, h = 352, 288
    pad, head = 12, 66
    sheet = Image.new('RGB', (4 * w + 5 * pad, head + h + 40 + 150), BG)
    dr = ImageDraw.Draw(sheet)
    ft, fc, fs = font(18), font(13), font(12)
    dr.text((pad, 10), "The '99 with a Kempston mouse fitted: no stage reads a mouse port, the menu pointer and "
            "LOAD MAP ignore the mouse", fill=FG, font=ft)
    dr.text((pad, 36), "(the mouse ports did change: $FBDF 31 -> 111 -> 231, $FFDF 85 -> 145 -> 55; only Q A O P "
            "and SPACE move the menus)", fill=DIM, font=fc)
    for i, (f, cap) in enumerate(shots):
        x = pad + i * (w + pad)
        sheet.paste(Image.open(os.path.join(RUN, f)).convert('RGB'), (x, head))
        dr.text((x, head + h + 6), cap, fill=FG, font=fc)
    # the polls
    y0 = head + h + 46
    log = d['log']
    first, last = log[0][0], log[-1][0]
    x0, x1 = pad + 10, sheet.width - pad - 10
    scale = (x1 - x0) / (last - first)
    dr.text((pad, y0), f"device.in_use at each of the {len(log)} polls (frames {first}-{last}): "
            f"{sum(1 for e in log if e[2] == 'true')} true", fill=FG, font=fc)
    for f, _, u in log:
        x = x0 + (f - first) * scale
        dr.rectangle([x - 1, y0 + 24, x + 1, y0 + 44], fill=YES if u == 'true' else NO)
    phases = OrderedDict()
    for f, p, _ in log:
        if p == 'key':
            continue
        phases.setdefault(p, [f, f])
        phases[p][1] = f
    for i, (p, (fa, fb)) in enumerate(phases.items()):
        xa, xb = x0 + (fa - first) * scale, x0 + (fb - first) * scale
        yy = y0 + 52 + (i % 3) * 16
        dr.line([xa, yy + 6, max(xb, xa + 2), yy + 6], fill=DIM, width=2)
        dr.text((xa, yy + 8), p, fill=DIM, font=fs)
    ly = sheet.height - 26
    dr.rectangle([pad, ly, pad + 14, ly + 14], fill=NO)
    dr.text((pad + 20, ly), 'false: no mouse port read within 50 frames', fill=FG, font=fs)
    dr.rectangle([pad + 330, ly, pad + 344, ly + 14], fill=YES)
    dr.text((pad + 350, ly), 'true (never; the control program reading $FBDF turns it true within 30 frames)',
            fill=FG, font=fs)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    sheet.save(a.out)
    print(a.out, sheet.size)


if __name__ == '__main__':
    main()
