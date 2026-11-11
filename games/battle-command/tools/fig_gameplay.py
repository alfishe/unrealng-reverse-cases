#!/usr/bin/env python3
"""Figures of doc 10 (gameplay logic).

  python3 tools/fig_gameplay.py password --score 4000 --done 1 docs/img/gameplay/save-code.png
  python3 tools/fig_gameplay.py debris --height 32 --vz 32,40,48,63 --vx 20 docs/img/gameplay/debris-flight.png
  python3 tools/fig_gameplay.py skeet --samples work/docs/bcC/skeet.jsonl --to 17250 docs/img/gameplay/skeet-path.gif

The save code: the 32-bit score and the ten mission flags packed into ten characters by EncodePassword $CE2E (bank 6),
computed here from the code's rules, not from a recording. 1050 px wide, fonts 11 pt or more.

The debris: one piece's height pass by pass under MoveDebris $D16B (bank 3): height += vz, freed when the height is
negative or vz - 5 overflows, else vz -= 5; the start vz of Debris $B6D1 is 32 + (Random AND 31). From the code.

The Skeet: the object table sampled from the play2 recording (TTD memory_at, $75F0, 24 x 60 bytes, one line of JSON a
sample: frame, the present records with type, heading +$22, X +$23, Y +$26, +$31-+$33); the tank (record 0) and the
type $89 record drawn from above, the Skeet's track growing picture by picture. A recording, not a model.
"""

import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib  # noqa: E402

W = 1050
BG = (20, 22, 26)
FG = (230, 230, 230)
DIM = (150, 150, 160)
SC = (90, 170, 250)      # score bits
FL = (250, 190, 70)      # mission flags
CK = (120, 220, 120)     # checksum
F11, F12, F14, F16 = (kitlib.font(n) for n in (11, 12, 14, 16))
ALPHABET = '9876543210ZYXWVUTSRQPONMLKJIHABCDEFG'


def encode(score, done):
    sb = score.to_bytes(4, 'little')
    flags = [0xFF if i + 1 in done else 0 for i in range(10)]
    nib = []
    for b in sb:
        nib += [b >> 4, b & 15]
    vals = [nib[i] | (flags[i] & 0x10) for i in range(8)]
    c = sb[0] ^ sb[1] ^ sb[2] ^ sb[3]
    vals.append((flags[8] & 1) | (flags[9] & 2) | (c & 7) << 2)
    vals.append((c >> 3) & 0x1F)
    return sb, flags, nib, c, vals


def fig_password(out, score, done):
    sb, flags, nib, c, vals = encode(score, done)
    img = Image.new('RGB', (W, 470), BG)
    dr = ImageDraw.Draw(img)
    dr.text((14, 10), 'The save code: score %d, missions done %s (EncodePassword $CE2E, worked from the code)'
            % (score, ','.join(map(str, done)) or 'none'), font=F16, fill=FG)
    # the score bytes
    dr.text((14, 46), 'Score $CC79, low byte first:', font=F14, fill=DIM)
    for i, b in enumerate(sb):
        x = 250 + i * 198
        dr.rectangle((x, 44, x + 188, 70), outline=SC)
        dr.text((x + 6, 48), 'byte %d = $%02X (%s %s)' % (i, b, format(b >> 4, '04b'), format(b & 15, '04b')),
                font=F12, fill=FG)
    dr.text((14, 84), 'checksum = XOR of the 4 bytes = $%02X = %s' % (c, format(c, '08b')), font=F14, fill=CK)
    # the ten values: 5 bits each
    top = 130
    dr.text((14, top), 'value', font=F12, fill=DIM)
    dr.text((14, top + 36), 'bits 4..0', font=F12, fill=DIM)
    dr.text((14, top + 120), 'char', font=F12, fill=DIM)
    cw = 96
    for i, v in enumerate(vals):
        x = 90 + i * cw
        dr.text((x + 30, top), '%d: %d' % (i, v), font=F12, fill=FG)
        for k in range(5):
            bit = (v >> (4 - k)) & 1
            if i < 8:
                col = FL if k == 0 else SC
            elif i == 8:
                col = CK if k < 3 else FL
            else:
                col = CK
            bx = x + 4 + k * 17
            dr.rectangle((bx, top + 30, bx + 15, top + 60), fill=col if bit else BG, outline=col)
            dr.text((bx + 4, top + 36), str(bit), font=F12, fill=BG if bit else col)
        if i < 8:
            lab = ('flag %d' % (i + 1), 'nibble %d' % i)
        elif i == 8:
            lab = ('chk 2..0', 'flag 10, 9')
        else:
            lab = ('chk 7..3', '')
        dr.text((x + 4, top + 66), lab[0], font=F11, fill=DIM)
        dr.text((x + 4, top + 82), lab[1], font=F11, fill=DIM)
        dr.rectangle((x + 22, top + 110, x + 66, top + 150), outline=FG)
        dr.text((x + 37, top + 118), ALPHABET[v], font=F16, fill=FG)
    code = ''.join(ALPHABET[v] for v in vals)
    y = top + 180
    dr.text((14, y), 'code: %s    (alphabet $CF5F: value 0 = "9", 10 = "Z", 29 = "A")' % code, font=F16, fill=FG)
    y += 40
    for col, t in ((SC, 'score nibble, Score byte n/2, high nibble first'),
                   (FL, 'mission flag: bit 4 of MissionsDone 1-8; bits 0, 1 for missions 9, 10'),
                   (CK, 'checksum bits: 3 in value 8, 5 in value 9 (covers the score only)')):
        dr.rectangle((14, y + 2, 30, y + 16), fill=col)
        dr.text((40, y), t, font=F12, fill=FG)
        y += 26
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out)
    print(out, code)


def debris_flight(h0, vz):
    """Heights after each pass until MoveDebris frees the piece (the code's order: add, test, gravity)."""
    out, h = [h0], h0
    while True:
        h += vz
        if h < 0 or h > 32767:
            return out, len(out)
        out.append(h)
        v = vz - 5
        if v < -128:
            return out, len(out)
        vz = v


def fig_debris(out, h0, vzs, vx):
    H = 470
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'A debris piece under MoveDebris (bank 3 $D16B): height += vz, then vz -= 5; freed below the ground',
           font=F14, fill=FG)
    flights = [(v,) + debris_flight(h0, v) for v in vzs]
    top = max(max(f[1]) for f in flights)
    n = max(f[2] for f in flights)
    x0, y0, x1, y1 = 70, 50, W - 250, H - 60
    sx = (x1 - x0) / n
    sy = (y1 - y0) / (top * 1.05)
    for t in range(0, n + 1, 2):
        x = x0 + t * sx
        d.line([(x, y1), (x, y1 + 4)], fill=DIM)
        d.text((x - 6, y1 + 6), str(t), font=F11, fill=DIM)
    for hv in range(0, int(top * 1.05), 50):
        y = y1 - hv * sy
        d.line([(x0 - 4, y), (x1, y)], fill=(45, 48, 55))
        d.text((x0 - 40, y - 7), str(hv), font=F11, fill=DIM)
    d.line([(x0, y1), (x1, y1)], fill=FG)
    d.text((x0, y1 + 24), 'passes after the kill (one MoveDebris call a pass)', font=F12, fill=DIM)
    d.text((10, y0 - 18), 'height (world units)', font=F12, fill=DIM)
    cols = [SC, FL, CK, (240, 110, 110)]
    for k, (v, hs, life) in enumerate(flights):
        c = cols[k % len(cols)]
        pts = [(x0 + t * sx, y1 - h * sy) for t, h in enumerate(hs)]
        d.line(pts, fill=c, width=2)
        for p in pts:
            d.ellipse([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], fill=c)
        ly = 60 + 70 * k
        d.text((x1 + 20, ly), 'vz = %d at the kill' % v, font=F14, fill=c)
        d.text((x1 + 20, ly + 18), 'peak %d, freed at pass %d' % (max(hs), life), font=F12, fill=FG)
        d.text((x1 + 20, ly + 34), 'drift %d units at vx = %d' % (vx * life, vx), font=F12, fill=DIM)
    d.text((x1 + 20, H - 80), 'start height %d (hut)' % h0, font=F12, fill=DIM)
    d.text((x1 + 20, H - 62), 'vz = 32 + (Random AND 31)', font=F12, fill=DIM)
    os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
    img.save(out)
    print(out, [(v, max(hs), life) for v, hs, life in flights])


def fig_skeet(out, samples, end):
    import json
    rows = [json.loads(line) for line in open(samples)]
    rows = [r for r in rows if r['frame'] <= end]
    tank = [next(x for x in r['recs'] if x['r'] == 0) for r in rows]
    sk = [next((x for x in r['recs'] if x['type'] == 0x89), None) for r in rows]
    pts = [(x['x'], x['y']) for x in tank] + [(x['x'], x['y']) for x in sk if x]
    x0, x1 = min(p[0] for p in pts) - 150, max(p[0] for p in pts) + 150
    y0, y1 = min(p[1] for p in pts) - 150, max(p[1] for p in pts) + 150
    H = 640
    top, left, side = 60, 30, H - 90
    sc = side / max(x1 - x0, y1 - y0)

    def at(x, y):
        return left + (x - x0) * sc, top + side - (y - y0) * sc

    def arrow(d, x, y, h, col, n=40):
        import math
        a = h / 256 * 2 * math.pi
        px, py = at(x, y)
        d.line((px, py, px + n * math.sin(a), py - n * math.cos(a)), fill=col, width=3)
        d.ellipse((px - 6, py - 6, px + 6, py + 6), fill=col)

    frames = []
    track = []
    first = next(i for i, x in enumerate(sk) if x)
    for i, r in enumerate(rows):
        im = Image.new('RGB', (W, H), BG)
        d = ImageDraw.Draw(im)
        d.text((14, 12), 'The Skeet ($89) seen from above: play2, frames %d-%d, a sample every 2 frames' %
               (rows[0]['frame'], rows[-1]['frame']), font=F16, fill=FG)
        d.rectangle((left, top, left + side, top + side), outline=(60, 60, 70))
        for gx in range((x0 // 256 + 1) * 256, x1, 256):
            d.line((at(gx, y0)[0], top, at(gx, y0)[0], top + side), fill=(40, 42, 48))
        for gy in range((y0 // 256 + 1) * 256, y1, 256):
            d.line((left, at(x0, gy)[1], left + side, at(x0, gy)[1]), fill=(40, 42, 48))
        if sk[i]:
            track.append(at(sk[i]['x'], sk[i]['y']))
        if len(track) > 1:
            d.line(track, fill=FL, width=2)
        t = tank[i]
        arrow(d, t['x'], t['y'], t['h'], SC)
        if sk[i]:
            arrow(d, sk[i]['x'], sk[i]['y'], sk[i]['h'], FL, 24)
        tx = left + side + 30
        d.text((tx, top), 'frame %d' % r['frame'], font=F16, fill=FG)
        d.text((tx, top + 30), 'tank (record 0)', font=F14, fill=SC)
        d.text((tx, top + 50), 'X %d  Y %d  heading %d' % (t['x'], t['y'], t['h']), font=F12, fill=FG)
        d.text((tx, top + 84), 'Skeet (record %s, type $89)' % (sk[i]['r'] if sk[i] else '-'), font=F14, fill=FL)
        if sk[i]:
            s_ = sk[i]
            d.text((tx, top + 104), 'X %d  Y %d  heading %d' % (s_['x'], s_['y'], s_['h']), font=F12, fill=FG)
            d.text((tx, top + 122), '+$31 count %d   +$32 turn %d   +$33 rounds %d' %
                   (s_['s31'], s_['s32'] - 256 if s_['s32'] > 127 else s_['s32'], s_['s33']), font=F12, fill=FG)
        else:
            d.text((tx, top + 104), 'not fired yet', font=F12, fill=DIM)
        notes = ['SkeetFire: heading = tank + 128 (behind),', 'turn +8 a pass for 9 passes (SkeetZigZag),',
                 'then 8 straight (SkeetStraight); then turns of', '17 passes, the side changing, and straights',
                 'of 16; 64 world units a pass.', '', 'grid: 256 world units (1 coarse unit)',
                 'north is up: heading 0 = +Y']
        for k, line in enumerate(notes):
            d.text((tx, top + 170 + 18 * k), line, font=F12, fill=DIM)
        frames.append(im)
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=[80] * (len(frames) - 1) + [2500], loop=0,
                   optimize=True)
    print('%s: %d pictures (the Skeet from picture %d)' % (out, len(frames), first))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('password')
    p.add_argument('--score', type=int, default=4000)
    p.add_argument('--done', default='1')
    p.add_argument('out')
    p = sub.add_parser('debris')
    p.add_argument('--height', type=int, default=32)
    p.add_argument('--vz', default='32,40,48,63')
    p.add_argument('--vx', type=int, default=20)
    p.add_argument('out')
    p = sub.add_parser('skeet')
    p.add_argument('--samples', required=True)
    p.add_argument('--to', type=int, default=17250)
    p.add_argument('out')
    a = ap.parse_args()
    if a.cmd == 'password':
        fig_password(a.out, a.score, [int(x) for x in a.done.split(',') if x])
    elif a.cmd == 'debris':
        fig_debris(a.out, a.height, [int(x) for x in a.vz.split(',')], a.vx)
    elif a.cmd == 'skeet':
        fig_skeet(a.out, a.samples, a.to)


if __name__ == '__main__':
    main()
