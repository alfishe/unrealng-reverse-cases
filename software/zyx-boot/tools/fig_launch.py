#!/usr/bin/env python3
"""Doc 10's figures: the launch line RunLetter writes, and ExitFade pass by pass.

    python3 tools/fig_launch.py line OUT.png --work W --before F --after F
        line 1 of the BASIC ($5D3B, 30 bytes) before and after RunLetter (TTD memory_at), each byte with its meaning
    python3 tools/fig_launch.py fade OUT.png --work W --trace T.uatr
        the screen at ExitFade's start, then after each of its 8 passes: the model (ExitFade's loops in Python) and
        the recording (memory_at at each DEC D $6E94 of the trace) compared byte for byte; a zoom of the file list
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import fig_catalogue as FC  # noqa: E402
K = FC.K
from PIL import Image, ImageDraw  # noqa: E402

TOKENS = {0xF9: 'RANDOM.', 0xC0: 'USR', 0xB0: 'VAL', 0xEA: 'REM', 0xF7: 'RUN', 0xEC: 'GO TO', 0xAF: 'CODE',
          0x0D: 'ENTER', 0x22: '"', 0x3A: ':'}


def meaning(i, b):
    if i == 0:
        return 'line hi'
    if i == 1:
        return 'line lo'
    if i in (2, 3):
        return 'length' if i == 2 else ''
    if i == 29:
        return 'ENTER'
    if b in TOKENS:
        return TOKENS[b]
    if 32 <= b < 128:
        return "'%s'" % chr(b)
    return ''


def cmd_line(args):
    a = FC.memory_at(args.work, args.before, 0x5D3B, 30)
    b = FC.memory_at(args.work, args.after, 0x5D3B, 30)
    f, fs, fb = K.font(14), K.font(13), K.font(15)
    cw = 34
    w = 1050
    im = Image.new('RGB', (w, 300), FC.BG)
    d = ImageDraw.Draw(im)
    d.text((12, 10), 'Line 1 of the BASIC at $5D3B: RANDOMIZE USR VAL "15619": REM : RUN "name" -- what RunLetter '
                     'changes', font=fb, fill=FC.FG)
    for row, (data, label, y) in enumerate(((a, 'before (c3 frame %d)' % args.before, 50),
                                            (b, 'after (c3 frame %d)' % args.after, 150))):
        d.text((12, y), label, font=f, fill=FC.DIM)
        for i, v in enumerate(data):
            x = 12 + i * cw
            changed = row == 1 and a[i] != v
            box = (x, y + 22, x + cw - 4, y + 48)
            d.rectangle(box, outline=FC.YELLOW if changed else (70, 70, 80), fill=(60, 50, 20) if changed else None)
            d.text((x + 4, y + 27), '%02X' % v, font=f, fill=FC.YELLOW if changed else FC.FG)
            d.text((x + 2, y + 52 + (i % 2) * 14), meaning(i, v), font=fs, fill=FC.DIM)
    d.text((12, 240), 'Yellow: the bytes RunLetter wrote: LaunchToken $5D4C (RUN $F7 or GO TO $EC), LaunchName '
                      '$5D4E (8 bytes),', font=f, fill=FC.FG)
    d.text((12, 258), 'LaunchSuffix $5D57 (a space, or CODE $AF for GO TO). Drawn by: python3 tools/fig_launch.py line '
                      '--work %s' % args.work, font=f, fill=FC.FG)
    im.save(args.out)
    print(args.out)


def exit_fade_pass(scr):
    s = bytearray(scr)
    hl = 0
    while hl < 0x1800:
        for direction in (0, 1):
            for _ in range(16):
                x, y = s[hl], s[hl + 1]
                if direction == 0:
                    s[hl], s[hl + 1] = x >> 1, (y << 1) & 0xFF
                else:
                    s[hl], s[hl + 1] = (x << 1) & 0xFF, y >> 1
                hl += 2
    return bytes(s)


def cmd_fade(args):
    sys.path.insert(0, FC.KIT)
    mod = K.access_trace(None)
    tr = mod.load(args.trace)
    moments = []
    first = None
    for x in tr.instructions:
        if x.pc == 0x6E72 and first is None:
            first = (x.frame, x.t)
        if x.pc == 0x6E94:
            moments.append((x.frame, x.t))
    scr = FC.memory_at(args.work, first[0], 0x4000, 0x1B00, first[1])
    model = [scr[:0x1800]]
    for _ in range(8):
        model.append(exit_fade_pass(model[-1]))
    rec = [scr[:0x1800]] + [FC.memory_at(args.work, f, 0x4000, 0x1800, t) for f, t in moments]
    same = [m == r for m, r in zip(model, rec)]
    print('passes:', len(moments), 'model = recording:', same)
    attrs = scr[0x1800:]
    # zoom: character rows 6-9, columns 4-19 (the first file names) at 3x
    cols, crow0, crows, z = (4, 22), 6, 3, 2
    pw = (cols[1] - cols[0]) * 8 * z
    ph = crows * 8 * z
    gap = 14
    per_row = 3
    w = 1050
    top = 64
    h = top + 3 * (ph + 30) + 70
    out = Image.new('RGB', (w, h), FC.BG)
    d = ImageDraw.Draw(out)
    f, fb = K.font(13), K.font(15)
    d.text((12, 10), 'ExitFade pass by pass: the file list of c3 page 2 (character rows 6-8, columns 4-21, 2x)',
           font=fb, fill=FC.FG)
    d.text((12, 32), 'Each pass moves every bit one place: line pairs alternate, bytes of a pair move in (RR, RL) '
                     'or out (RL, RR).', font=f, fill=FC.DIM)
    for k in range(9):
        full = K.render_screen(rec[k] + attrs, 0)
        crop = full.crop((cols[0] * 8, crow0 * 8, cols[1] * 8, (crow0 + crows) * 8))
        crop = crop.resize((pw, ph), resample=Image.NEAREST)
        x = 12 + (k % per_row) * (pw + gap)
        y = top + (k // per_row) * (ph + 30)
        label = 'start (frame %d T %d)' % first if k == 0 else 'after pass %d (frame %d T %d)' % (k, *moments[k - 1])
        d.text((x, y), label, font=f, fill=FC.FG)
        out.paste(crop, (x, y + 18))
    d.text((12, h - 46), 'Model = recording after every pass: %s. Pass 8 leaves all 6144 bytes 0; the attributes '
                         'stay.' % ('yes' if all(same) else 'NO'), font=f, fill=FC.FG)
    d.text((12, h - 26), 'Drawn by: python3 tools/fig_launch.py fade --work %s --trace %s'
           % (args.work, os.path.relpath(args.trace, ROOT)), font=f, fill=FC.DIM)
    out.save(args.out)
    print(args.out, out.size)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('line')
    s.add_argument('out')
    s.add_argument('--work', required=True)
    s.add_argument('--before', type=int, required=True)
    s.add_argument('--after', type=int, required=True)
    s.set_defaults(fn=cmd_line)
    s = sub.add_parser('fade')
    s.add_argument('out')
    s.add_argument('--work', required=True)
    s.add_argument('--trace', required=True)
    s.set_defaults(fn=cmd_fade)
    a = ap.parse_args()
    a.fn(a)


if __name__ == '__main__':
    main()
