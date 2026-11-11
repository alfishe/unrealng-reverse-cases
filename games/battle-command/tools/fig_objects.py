#!/usr/bin/env python3
"""Figures of docs 07 and 10 (objects, gameplay): drawn from src/res and from memory samples of the recordings
(tools/ttd_sample.py, one JSON line a frame).

    python3 tools/fig_objects.py header OUT.png                       # mission 1's header, byte by byte
    python3 tools/fig_objects.py record OUT.png --player F.jsonl:FRAME --other F.jsonl:FRAME:SLOT
    python3 tools/fig_objects.py world OUT.png --samples F.jsonl [--slots 7,12] [--to FRAME]
    python3 tools/fig_objects.py player OUT.png --samples F.jsonl --from A --to B
    python3 tools/fig_objects.py armour OUT.png --samples F.jsonl --from A --to B

Every figure is 1050 pixels wide, its fonts 11 pt or more.
"""
import argparse
import json
import os
import struct
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib  # noqa: E402
import res_missions  # noqa: E402

W = 1050
BG = (20, 22, 26)
FG = (230, 230, 230)
DIM = (150, 150, 160)
F11, F12, F14, F16 = (kitlib.font(n) for n in (11, 12, 14, 16))

# The header fields of a mission block ($DBC5-$DBFF): name, first, length, colour, what reads it
HEADER = [
    ('mission number', 0xDBC5, 1, (230, 120, 120), 'LoadMissionHeader $84FE checks it'),
    ('tape name', 0xDBC6, 10, (150, 150, 160), "the block's name"),
    ('half extents X, Y', 0xDBD0, 2, (120, 200, 120), 'BoundaryCheck $D4B8'),
    ('unread', 0xDBD2, 5, (80, 80, 90), 'no code reads them'),
    ('templates', 0xDBD7, 2, (230, 190, 90), 'ObjectSetType $BD41'),
    ('object count', 0xDBD9, 1, (240, 150, 60), 'ActivateMissionObjects $BBF1'),
    ('object list', 0xDBDA, 2, (240, 150, 60), 'ActivateMissionObjects $BBF1'),
    ('segment count', 0xDBDC, 1, (100, 170, 240), 'SegmentVisibility $AD45'),
    ('first switch object', 0xDBDD, 1, (100, 170, 240), 'list index, $B622 (0 none)'),
    ('first switchable segment', 0xDBDE, 1, (100, 170, 240), 'SegmentVisibility, $B61E'),
    ('switch table', 0xDBDF, 2, (100, 170, 240), 'KillSwitchObject $B61E'),
    ('goal hook', 0xDBE1, 2, (240, 90, 200), 'called every pass ($6A66)'),
    ('player: heading word, X, Y', 0xDBE3, 8, (90, 230, 230), 'to $7611 = record 0 +$21'),
    ('model library', 0xDBEB, 2, (190, 140, 240), 'fig_models.py'),
    ('end of the restored part', 0xDBED, 2, (150, 150, 160), 'LoadMission $84C1'),
    ('word', 0xDBEF, 2, (80, 80, 90), 'not named'),
    ('Helicarrier pad block', 0xDBF1, 12, (240, 120, 240), 'to $7E82 (pad X +7, Y +10)'),
    ('byte to $CAAF', 0xDBFD, 1, (150, 150, 160), 'MissionSetup $8598'),
    ('clock start: minutes, hours', 0xDBFE, 2, (230, 230, 120), 'to $68EB, $68EC'),
]

# Mission 1's object types by what the templates make of them (step and hit handlers, model, score)
ROLES = {
    'tree (KillTree $B612)': ([0, 1], (60, 170, 60)),
    'hill (BoxRect16)': ([20, 21, 22, 23], (110, 110, 70)),
    'building': ([4, 5, 6, 13, 15, 16, 17, 18, 32], (200, 200, 200)),
    'enemy vehicle': ([3, 7, 9, 26, 29, 30], (240, 80, 80)),
    'gun emplacement': ([14], (240, 160, 40)),
    'depot (3000-4000)': ([2, 11], (100, 170, 240)),
    'goal: fuel dump': ([33], (255, 60, 255)),
    'flag (spawner)': ([19], (255, 255, 120)),
}


def canvas(h):
    img = Image.new('RGB', (W, h), BG)
    return img, ImageDraw.Draw(img)


def block(n=1):
    path = os.path.join(CASE, 'src', 'res', 'missions')
    name = sorted(f for f in os.listdir(path) if f.startswith('%02d-' % n) and f.endswith('.txt'))[0]
    return res_missions.from_text(open(os.path.join(path, name)).read())


def samples(path):
    return {d['frame']: d for d in (json.loads(x) for x in open(path))}


def s24(b):
    return int.from_bytes(b, 'little', signed=True)


def fig_header(out):
    d = block(1)
    org = res_missions.ORG
    img, dr = canvas(560)
    dr.text((14, 10), 'Mission 1 (Blast Em Mission): the 59 header bytes $DBC5-$DBFF, one colour a field', font=F16,
            fill=FG)
    cell, x0, y0 = 58, 14, 46
    colour = {}
    for name, a, n, c, _ in HEADER:
        for i in range(n):
            colour[a + i] = c
    for i in range(0x3B):
        a = org + i
        r, k = divmod(i, 16)
        x, y = x0 + 64 + k * cell, y0 + 22 + r * 34
        if k == 0:
            dr.text((x0, y + 6), '$%04X' % a, font=F12, fill=DIM)
        c = colour.get(a, (60, 60, 60))
        dr.rectangle([x, y, x + cell - 4, y + 28], fill=tuple(v // 3 for v in c), outline=c)
        dr.text((x + 14, y + 6), '%02X' % d[i], font=F14, fill=FG)
    for k in range(16):
        dr.text((x0 + 64 + k * cell + 18, y0), '+%X' % k, font=F11, fill=DIM)
    y = y0 + 22 + 4 * 34 + 14
    col = 0
    for j, (name, a, n, c, who) in enumerate(HEADER):
        v = d[a - org:a - org + n]
        if n == 2 and name not in ('half extents X, Y',):
            val = '$%04X' % (v[0] | v[1] << 8)
        elif name == 'tape name':
            val = '"%s"' % v.decode('ascii')
        elif n == 1 or name == 'half extents X, Y':
            val = ' '.join(str(b) for b in v)
        else:
            val = v.hex(' ').upper()
        xx = 14 + col * 520
        yy = y + (j % 10) * 33
        dr.rectangle([xx, yy + 3, xx + 12, yy + 15], fill=c)
        dr.text((xx + 20, yy), '$%04X %s: %s' % (a, name, val), font=F12, fill=FG)
        dr.text((xx + 20, yy + 15), who, font=F11, fill=DIM)
        if j % 10 == 9:
            col += 1
    img.save(out)


RECORD_FIELDS = [
    (0x00, 1, 'list index ($FF: not from the list)'), (0x01, 1, 'type'),
    (0x02, 1, 'state: b7 present, b6 wreck, b5 debris'), (0x03, 1, 'flags: b0 step on, b4 evictable'),
    (0x04, 1, 'draw variant (DrawObject)'), (0x05, 2, 'height'), (0x07, 1, 'speed'),
    (0x08, 2, 'wreck model (drawn when b6 is set)'), (0x0A, 1, 'debris pieces, wreck pitch'),
    (0x0B, 2, 'box half width (x)'), (0x0D, 2, 'box half height'), (0x0F, 2, 'box half depth (y)'),
    (0x11, 1, 'turn step (mission code)'), (0x12, 1, 'top speed'), (0x13, 1, 'hit points'),
    (0x14, 1, 'damage it does'), (0x15, 1, 'unnamed'), (0x16, 2, 'radius'), (0x18, 2, 'step handler'),
    (0x1A, 2, 'collision handler'), (0x1C, 2, 'model'), (0x1E, 2, 'score'), (0x20, 1, 'serial'),
    (0x21, 2, 'heading (fraction, byte)'), (0x23, 3, 'X (24 bits)'), (0x26, 3, 'Y (24 bits)'),
    (0x29, 2, 'unnamed, pitch (BoxTilted)'), (0x2B, 6, 'view-space position (TransformObjects)'),
    (0x31, 10, 'per-type state'), (0x3B, 1, 'collision slot'),
]


def fig_record(out, player, other):
    pf, pfr = player.rsplit(':', 1)
    of, ofr, slot = other.split(':')
    p = bytes.fromhex(samples(pf)[int(pfr)]['75F0'])[0:60]
    o = bytes.fromhex(samples(of)[int(ofr)]['75F0'])[60 * int(slot):60 * int(slot) + 60]
    img, dr = canvas(36 + 26 * len(RECORD_FIELDS) + 50)
    dr.text((14, 8), 'The object record: 60 bytes a slot at $75F0 + 60 n; record 0 (the tank) and record %s (an '
            'enemy, type %d)' % (slot, o[1]), font=F14, fill=FG)
    hx = [14, 74, 380, 640]
    dr.text((hx[0], 34), 'offset', font=F12, fill=DIM)
    dr.text((hx[1], 34), 'field', font=F12, fill=DIM)
    dr.text((hx[2], 34), 'record 0, %s frame %s' % (os.path.basename(pf).split('-')[0], pfr), font=F12, fill=DIM)
    dr.text((hx[3], 34), 'record %s, %s frame %s' % (slot, os.path.basename(of).split('-')[0], ofr), font=F12,
            fill=DIM)
    y = 56
    for off, n, name in RECORD_FIELDS:
        tpl = 0x02 <= off <= 0x1F
        dr.rectangle([hx[0] - 4, y - 2, W - 10, y + 21], fill=(32, 38, 30) if tpl else (34, 30, 40))
        dr.text((hx[0], y + 2), '+$%02X' % off, font=F12, fill=FG)
        dr.text((hx[1], y + 2), name, font=F12, fill=FG)
        for rec, x in ((p, hx[2]), (o, hx[3])):
            v = rec[off:off + n]
            if n == 2 and off in (0x18, 0x1A, 0x1C, 0x08):
                txt = '$%04X' % (v[0] | v[1] << 8)
            elif off == 0x21:
                txt = '%s: heading %d of 256' % (v.hex(' ').upper(), v[1])
            elif n == 2:
                txt = '%s = %d' % (v.hex(' ').upper(), v[0] | v[1] << 8)
            elif n == 3:
                txt = '%s = %d' % (v.hex(' ').upper(), s24(v))
            else:
                txt = v.hex(' ').upper()
            dr.text((x, y + 2), txt, font=F12, fill=FG)
        y += 26
    dr.rectangle([14, y + 10, 26, y + 22], fill=(32, 38, 30))
    dr.text((32, y + 8), 'green rows: +$02-+$1F, copied from the type\'s 30-byte template by ObjectSetType $BD41',
            font=F12, fill=FG)
    img.save(out)


def fig_world(out, sample_path, slots, last):
    d = block(1)
    m = res_missions.parse(d)
    S = 12
    ex, ey = m['head']['extent'][0], m['head']['extent'][1]
    top = 40
    mw, mh = (2 * ex + 10) * S, (2 * ey + 10) * S
    img, dr = canvas(top + mh + 20)
    cx, cy = 10 + mw // 2, top + mh // 2

    def pt(x, y):
        return cx + x * S, cy - y * S
    dr.text((14, 8), 'Mission 1 from its block: segments, the %d listed objects by role, the paths of the death '
            'recording' % len(m['objects']), font=F14, fill=FG)
    dr.rectangle([pt(-ex, ey), pt(ex, -ey)], outline=(90, 110, 90))
    dr.rectangle([pt(-ex - 4, ey + 4), pt(ex + 4, -ey - 4)], outline=(160, 60, 60))
    for k in range(-ex - 4, ex + 5, 4):
        dr.line([pt(k, -ey - 4), pt(k, -ey - 4.5)], fill=DIM)
    for s in m['segments']:
        (x1, y1), (x2, y2) = m['vertices'][s[0]], m['vertices'][s[1]]
        dr.line([pt(x1, y1), pt(x2, y2)], fill=(170, 170, 170), width=4)
    role_of = {}
    for name, (types, c) in ROLES.items():
        for t in types:
            role_of[t] = c
    for o in m['objects']:
        x = struct.unpack('<h', bytes(o[4:6]))[0] / 256
        y = struct.unpack('<h', bytes(o[6:8]))[0] / 256
        c = role_of.get(o[1], (120, 120, 120))
        px, py = pt(x, y)
        r = 6 if o[1] in (33, 14) else 4
        dr.ellipse([px - r, py - r, px + r, py + r], fill=c)
        if o[1] not in (0, 1, 20, 21, 22, 23):
            dr.text((px + 6, py - 7), str(o[1]), font=F11, fill=c)
    pp = m['head']['pad-params']
    # the pad words ($7E89 / $7E8C) are the mid and high bytes of X and Y: world = word x 256, coarse = word / 4
    hx = struct.unpack('<h', bytes(pp[7:9]))[0] / 4
    hy = struct.unpack('<h', bytes(pp[10:12]))[0] / 4
    a, b = pt(hx, hy)
    dr.rectangle([a - 7, b - 7, a + 7, b + 7], outline=(240, 120, 240), width=3)
    # paths
    if sample_path:
        sm = samples(sample_path)
        frames = sorted(f for f in sm if f <= last)
        colours = [(80, 240, 240), (255, 120, 60), (255, 230, 60), (160, 255, 120)]
        for k, slot in enumerate([0] + slots):
            pts = []
            for f in frames:
                t = bytes.fromhex(sm[f]['75F0'])
                r = t[60 * slot:60 * slot + 60]
                if not r[2] & 0x80 or (slot and r[1] not in (7, 9, 26, 29, 30, 3)):
                    if pts:
                        dr.line(pts, fill=colours[k], width=2)
                    pts = []
                    continue
                q = pt(s24(r[0x23:0x26]) / 1024, s24(r[0x26:0x29]) / 1024)
                if pts and abs(q[0] - pts[-1][0]) + abs(q[1] - pts[-1][1]) > 2 * S:
                    if len(pts) > 1:
                        dr.line(pts, fill=colours[k], width=2)
                    pts = []
                pts.append(q)
            if pts:
                dr.line(pts, fill=colours[k], width=2)
                dr.ellipse([pts[-1][0] - 3, pts[-1][1] - 3, pts[-1][0] + 3, pts[-1][1] + 3], fill=colours[k])
    # legend
    lx, ly = 14 + mw + 10, top + 6
    for name, (types, c) in ROLES.items():
        dr.ellipse([lx, ly + 3, lx + 10, ly + 13], fill=c)
        dr.text((lx + 16, ly), name, font=F12, fill=FG)
        runs, k = [], 0
        while k < len(types):
            j = k
            while j + 1 < len(types) and types[j + 1] == types[j] + 1:
                j += 1
            runs.append(str(types[k]) if j == k else '%d-%d' % (types[k], types[j]))
            k = j + 1
        dr.text((lx + 16, ly + 15), 'types ' + ', '.join(runs), font=F11, fill=DIM)
        ly += 36
    for txt, c in (('grey: the 10 segments', (170, 170, 170)),
                   ('magenta: Helicarrier pad', (240, 120, 240)),
                   ('green: extents 28 x 22', (90, 110, 90)),
                   ('red: 4 more, desertion', (160, 60, 60))):
        dr.text((lx, ly), txt, font=F12, fill=c)
        ly += 20
    if sample_path:
        ly += 8
        dr.text((lx, ly), 'paths, death %d-%d:' % (frames[0], frames[-1]), font=F12, fill=FG)
        ly += 20
        names = ['record 0: the tank'] + ['record %d: enemy' % s for s in slots]
        for k, n in enumerate(names):
            dr.line([lx, ly + 8, lx + 20, ly + 8], fill=colours[k], width=3)
            dr.text((lx + 26, ly), n, font=F12, fill=FG)
            ly += 20
    dr.text((lx, ly + 10), 'one grid unit = 1 coarse unit', font=F11, fill=DIM)
    dr.text((lx, ly + 25), '= 1024 world units', font=F11, fill=DIM)
    img.save(out)


def chart(dr, box, xs, series, x0, x1, title):
    l, t, r, b = box
    dr.rectangle(box, outline=(80, 80, 90))
    dr.text((l + 6, t + 4), title, font=F12, fill=FG)
    for name, ys, c, lo, hi in series:
        pts = [(l + (x - x0) * (r - l) / (x1 - x0), b - 8 - (y - lo) * (b - t - 30) / (hi - lo)) for x, y in
               zip(xs, ys)]
        dr.line(pts, fill=c, width=2)
    return box


def fig_player(out, sample_path, a, b):
    sm = samples(sample_path)
    fr = [f for f in sorted(sm) if a <= f <= b]
    sp, yy, fuel, fail = [], [], [], []
    for f in fr:
        r = bytes.fromhex(sm[f]['75F0'])[0:60]
        v = r[7] - 256 if r[7] > 127 else r[7]
        sp.append(v)
        yy.append(s24(r[0x26:0x29]))
        fu = bytes.fromhex(sm[f]['7C57'])
        fuel.append(min(33, fu[0] | fu[1] << 8))
        fail.append(sm[f]['7BF9'])
    img, dr = canvas(640)
    dr.text((14, 8), 'The tank in the fuel recording, frames %d-%d: speed $75F7, Y $7616, fuel $7C57 (a POKE set '
            'it to 32 at frame 7704)' % (a, b), font=F14, fill=FG)
    L, R = 80, W - 20
    boxes = [(L, 40, R, 210), (L, 225, R, 395), (L, 410, R, 580)]
    data = [('speed (+$07)', sp, (240, 200, 80), 0, 48), ('Y (+$26, 24 bits)', yy, (80, 220, 240), min(yy),
                                                            max(yy)),
            ('fuel ($7C57)', fuel, (240, 110, 110), 0, 33)]
    for box, (name, ys, c, lo, hi) in zip(boxes, data):
        chart(dr, box, fr, [(name, ys, c, lo, hi)], a, b, name)
        dr.text((14, box[1] + 30), str(hi), font=F11, fill=DIM)
        dr.text((14, box[3] - 18), str(lo), font=F11, fill=DIM)
        prev = None
        for f, y in zip(fr, ys):
            if prev is not None and y != prev:
                x = L + (f - a) * (R - L) / (b - a)
                dr.line([x, box[3] - 4, x, box[3]], fill=c)
            prev = y
    # marks
    marks = ((7704, 'POKE fuel = 32 (16128 before, clipped)'), (7852, 'fuel 0'),
             (next((f for f, v in zip(fr, fail) if v != '0000'), b), 'failure: $7BF9 = $CCED'))
    for j, (f, txt) in enumerate(marks):
        x = L + (f - a) * (R - L) / (b - a)
        dr.line([x, 40, x, 580 + 16 * (j == 2)], fill=(200, 200, 200))
        lab = '%d %s' % (f, txt)
        tx = x + 4 if j == 0 else x - 8 - dr.textlength(lab, font=F11)
        dr.text((tx, 584 + 16 * (j == 2)), lab, font=F11, fill=FG)
    dr.text((L, 618), 'frames (a sample of frame F is the state at its start); the ticks under each line mark a '
            'change: one a pass', font=F11, fill=DIM)
    img.save(out)


def fig_armour(out, sample_path, a, b):
    sm = samples(sample_path)
    fr = [f for f in sorted(sm) if a <= f <= b]
    img, dr = canvas(400)
    dr.text((14, 8), 'The armour $8301-$8304 over frames %d-%d of %s' % (a, b, os.path.basename(sample_path)),
            font=F14, fill=FG)
    names = ['$8301 side 1', '$8302 side 2 (front)', '$8303 side 3', '$8304 top']
    cols = [(240, 120, 120), (240, 200, 80), (120, 220, 120), (100, 170, 240)]
    L, R = 80, W - 220
    box = (L, 40, R, 360)
    for k in range(4):
        ys = [bytes.fromhex(sm[f]['8301'])[k] for f in fr]
        chart(dr, box, fr, [(names[k], ys, cols[k], 0, 128)], a, b, '')
        dr.line([R + 20, 60 + 24 * k + 8, R + 40, 60 + 24 * k + 8], fill=cols[k], width=3)
        dr.text((R + 46, 60 + 24 * k), names[k], font=F12, fill=FG)
    dr.text((14, 66), '127', font=F11, fill=DIM)
    dr.text((14, 342), '0', font=F11, fill=DIM)
    dr.text((L, 366), 'frames %d-%d' % (a, b), font=F11, fill=DIM)
    img.save(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('what')
    p.add_argument('out')
    p.add_argument('--player')
    p.add_argument('--other')
    p.add_argument('--samples')
    p.add_argument('--slots', default='')
    p.add_argument('--from', dest='a', type=int, default=0)
    p.add_argument('--to', dest='b', type=int, default=10 ** 9)
    a = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    if a.what == 'header':
        fig_header(a.out)
    elif a.what == 'record':
        fig_record(a.out, a.player, a.other)
    elif a.what == 'world':
        fig_world(a.out, a.samples, [int(s) for s in a.slots.split(',') if s], a.b)
    elif a.what == 'player':
        fig_player(a.out, a.samples, a.a, a.b)
    elif a.what == 'armour':
        fig_armour(a.out, a.samples, a.a, a.b)
    else:
        raise SystemExit('header, record, world, player or armour')


if __name__ == '__main__':
    main()
