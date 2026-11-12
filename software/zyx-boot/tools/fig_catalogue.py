#!/usr/bin/env python3
"""Doc 7's figures: the TR-DOS catalogue as the menu reads it, and the three layouts of a page.

    python3 tools/fig_catalogue.py entries OUT.png --work W --frame F [--count N]
        the catalogue at Catalogue $9D00 in a recording (TTD memory_at on the instance of W), one entry a row:
        the 16 bytes, the fields, and what ListCatalogue makes of it (the colour, the page and the letter)
    python3 tools/fig_catalogue.py pages OUT.png A.png:LABEL B.png:LABEL ...
        screens (kit/screen_shot.py) side by side, each with its label

The verdict follows ListCatalogue $65C7, PrintColumn $668E and IsBootFile $6737: a first byte 0 ends the
catalogue, 1 is a deleted entry; "boot    B" is never listed; type B is listed (green); type C with 192 sectors
(+13 = $C0) is listed (yellow); anything else is skipped. 24 files a page: 1-12 in one column, 13-24 in two
(half rounded up in the first), the letters A-X down the first column, then the second.
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

CATALOGUE = 0x9D00
BG, FG, DIM = (18, 18, 24), (225, 225, 225), (140, 140, 150)
GREEN, YELLOW, RED, GREY = (90, 210, 90), (230, 210, 60), (220, 90, 90), (120, 120, 130)


def memory_at(work, frame, address, length, t=None):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)
    body = {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': address, 'length': length}
    if t is not None:
        body['tinframe'] = t
    r = session.call('time_travel', body, ok=False)
    data = (r.structured or {}).get('hex')
    if r.is_error or not data:
        raise SystemExit(f'memory_at {frame}: {r.text}')
    return bytes.fromhex(data)


def verdicts(cat):
    """[(index, entry bytes, verdict, colour)] as the menu reads the catalogue, page and letter for the listed"""
    out, listed = [], 0
    for i in range(128):
        e = cat[16 * i:16 * i + 16]
        if e[0] == 0:
            out.append((i, e, 'the end: first byte 0, ListCatalogue stops', DIM))
            break
        if e[0] == 1:
            out.append((i, e, 'deleted (first byte 1): SkipDeleted', GREY))
            continue
        if e[:9] == b'boot    B':
            out.append((i, e, 'boot B: IsBootFile, never listed', GREY))
            continue
        kind = chr(e[8])
        if kind == 'B' or (kind == 'C' and e[13] == 0xC0):
            page, n = divmod(listed, 24)
            listed += 1
            colour = GREEN if kind == 'B' else YELLOW
            what = 'BASIC: RUN' if kind == 'B' else 'CODE, 192 sectors: GO TO ... CODE'
            out.append((i, e, 'page %d, %s  %s' % (page + 1, chr(0x41 + n), what), colour))
        else:
            out.append((i, e, 'type %s, %d sectors: not listed' % (kind, e[13]), RED))
    return out


def cmd_entries(args):
    cat = memory_at(args.work, args.frame, CATALOGUE, 0x800)
    rows = verdicts(cat)
    show = rows if len(rows) <= args.count else rows[:args.count - 6] + [None] + rows[-5:]
    f, fb = K.font(13), K.font(15)
    lh = 21
    w = 1050
    h = 92 + lh * (len(show) + 1) + 70
    im = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(im)
    d.text((12, 10), 'The TR-DOS catalogue of tests/disks/many.scl at Catalogue $9D00, as Start read it '
                     '(c3 frame %d)' % args.frame, font=fb, fill=FG)
    d.text((12, 32), 'Each entry 16 bytes: name 8, type 1, start 2, length 2, sectors 1, first sector 1, track 1. '
                     'The colour of the',
           font=f, fill=DIM)
    d.text((12, 50), 'bytes the menu tests: green type, yellow sectors (+13), blue the first byte (0 end, 1 deleted).',
           font=f, fill=DIM)
    x0 = [12, 62, 470, 560, 1050]
    y = 80
    for x, t in zip(x0, ('entry', 'bytes  (+0 ... +15)', 'name', 'what the menu does')):
        d.text((x, y), t, font=f, fill=DIM)
    y += lh
    for r in show:
        if r is None:
            d.text((x0[1], y), '... the same pattern for the entries between ...', font=f, fill=DIM)
            y += lh
            continue
        i, e, text, colour = r
        d.text((x0[0], y), '%3d $%04X' % (i, CATALOGUE + 16 * i), font=f, fill=DIM)
        x = x0[1] + 60
        for k, b in enumerate(e):
            c = FG
            if k == 0 and b in (0, 1):
                c = (110, 160, 240)
            elif k == 8:
                c = GREEN
            elif k == 13:
                c = YELLOW
            d.text((x, y), '%02X' % b, font=f, fill=c)
            x += 22 if k not in (7, 8, 12) else 30
        name = ''.join(chr(b) if 32 <= b < 128 else '.' for b in e[:8])
        d.text((x0[2] + 30, y), '"%s"' % name, font=f, fill=FG)
        d.text((x0[3] + 40, y), text, font=f, fill=colour)
        y += lh
    listed = sum(1 for r in rows if r[3] in (GREEN, YELLOW))
    d.text((12, y + 10), '%d entries read (the last one the end marker), %d listed: page 1 the first 24 (two columns, '
                         '12 + 12), page 2 the rest (%d: one column).' % (len(rows), listed,
                                                                        listed - 24 if listed > 24 else 0),
           font=f, fill=FG)
    d.text((12, y + 32), 'Drawn by: python3 tools/fig_catalogue.py entries %s --work %s --frame %d'
           % (os.path.relpath(args.out, ROOT), args.work, args.frame), font=f, fill=DIM)
    im.save(args.out)
    print(args.out, im.size)


def cmd_pages(args):
    shots = []
    for s in args.shots:
        path, _, label = s.partition(':')
        shots.append((Image.open(path).convert('RGB'), label))
    gap, top = 12, 52
    sw = (1050 - gap * (len(shots) + 1)) // len(shots)
    ims = [im.resize((sw, sw * im.height // im.width), resample=Image.NEAREST) for im, _ in shots]
    h = top + max(i.height for i in ims) + 40
    out = Image.new('RGB', (1050, h), BG)
    d = ImageDraw.Draw(out)
    f, fb = K.font(13), K.font(15)
    d.text((gap, 10), args.title, font=fb, fill=FG)
    x = gap
    for im, (_, label) in zip(ims, shots):
        d.text((x, 32), label, font=f, fill=FG)
        out.paste(im, (x, top))
        x += sw + gap
    d.text((gap, h - 26), 'Drawn by: python3 tools/fig_catalogue.py pages (screens by kit/screen_shot.py)', font=f,
           fill=DIM)
    out.save(args.out)
    print(args.out, out.size)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('entries')
    s.add_argument('out')
    s.add_argument('--work', required=True)
    s.add_argument('--frame', type=int, required=True)
    s.add_argument('--count', type=int, default=40)
    s.set_defaults(fn=cmd_entries)
    s = sub.add_parser('pages')
    s.add_argument('out')
    s.add_argument('shots', nargs='+')
    s.add_argument('--title', default='The three layouts of a page')
    s.set_defaults(fn=cmd_pages)
    a = ap.parse_args()
    a.fn(a)


if __name__ == '__main__':
    main()
