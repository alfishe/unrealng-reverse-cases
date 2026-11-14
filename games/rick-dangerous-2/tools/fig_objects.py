#!/usr/bin/env python3
"""The figures of doc 07 (objects).

    python3 tools/fig_objects.py section --level 1 --section 6 docs/img/objects/section.png
    python3 tools/fig_objects.py records --work W --at F[:T] docs/img/objects/records.png
    python3 tools/fig_objects.py kind --level 1 --kind 1 docs/img/objects/kind.png
    python3 tools/fig_objects.py play --work W --from F --to T [--step 2] [--title T] docs/img/play/objects.gif

section: one section of a level decoded byte by byte from the level's resources (src/res/levels/levelN): its
8-byte entry in SectionTable, its exit list and its map entry list with the trigger boxes, every byte in a box and
its meaning under it; beside them the section's map (fig_rooms.draw_section) with the entries and boxes marked.

records: the two object tables at one moment of a recording (TTD memory_at): every live record of table A (`$7B8F`,
24 bytes) and table B (`$7C20`, 23 bytes), a box a byte, the field names over them.

kind: one trap kind of a level: its record in KindRecords (the kind table's word), its path and second path decoded
step by step (the y and x offset a pass, drawn as a trajectory), and its animation's frames drawn from the level's
sprites through SpriteFrameMap.

play: a GIF of a recording, one picture every --step frames: the screen with a box over every live object (table A
yellow, table B red, Rick green, the bullet and the detonator white), and the records decoded beside it.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_rooms as FR  # noqa: E402
import fig_render as FRN  # noqa: E402
import zxscreen  # noqa: E402

W = 1050
YEL, RED, GRN, CYA, WHT = (240, 210, 80), (240, 90, 80), (90, 200, 120), (80, 200, 230), (230, 230, 230)

LEVEL_TABLES = {1: 0xED6D, 2: 0xED6D, 3: 0xEBED, 4: 0xEAED, 5: 0xECED}


def session_mem(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def mem(frame, addr, n, t=0):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                         'offset': addr, 'length': n}, ok=False)
        return bytes.fromhex((r.structured or {})['hex'])
    return mem


def byte_row(d, x, y, items, f, fs, bw=40, bh=26):
    """items: [(bytes, label, colour)]: a group of boxes and a label under the group, the group as wide as its
    label; returns the x after it"""
    for bs, label, col in items:
        lines = label.split('\n')
        lw = max(d.textlength(ln, font=fs) for ln in lines) + 8
        gw = max(len(bs) * bw, lw)
        step = gw / len(bs)
        for i, v in enumerate(bs):
            x0 = x + i * step
            d.rectangle((x0, y, x0 + step - 4, y + bh), fill=K.PANEL, outline=col)
            d.text((x0 + step / 2 - 9, y + 5), '%02X' % v, fill=col, font=f)
        for k, ln in enumerate(lines):
            d.text((x, y + bh + 4 + 15 * k), ln, fill=K.DIM, font=fs)
        x += gw + 4
    return x


def entry_meaning(rec):
    k, row, col, par = rec
    x = (col & 31) * 8 + (4 if col & 0x20 else 0)
    if k >= 0x74:
        what = 'bonus start' if k == 0x78 else 'bonus stop' if k == 0x7C else 'enemy, beh. %d' % (k & 3)
    else:
        what = 'kind %d' % k
    pb = par >> 2 & 15
    name = {8: 'treasure', 10: 'ammunition', 11: 'detonators'}.get(pb)
    if k >= 0x74 and k not in (0x78, 0x7C):
        ptxt = 'patrol %d passes' % ((pb + 1) * 8)
    else:
        ptxt = name or 'behaviour $%02X' % (par & 0x3C)
    return [
        ([k], '$%02X:\n%s' % (k, what), YEL if k < 0x74 else (CYA if k in (0x78, 0x7C) else RED)),
        ([row], 'row %d' % row, K.TEXT),
        ([col], 'x %d%s\n%s' % (x, ' y+3' if col & 0x40 else '', 'on view' if col & 0x80 else 'by a box'), K.TEXT),
        ([par], '%d box%s\n%s%s' % (par & 3, '' if (par & 3) == 1 else 'es', ptxt,
                                    '\none-shot' if par & 0x40 else ''), K.TEXT),
    ]


def box_meaning(bx):
    who = [n for b, n in enumerate(['Rick', 'bullet', 'blast', 'punch', 'enemy', 'trap', 'every pass']) if bx[3] >> b & 1]
    return [
        ([bx[0]], 'x %d' % bx[0], DIMBOX),
        ([bx[1]], 'row %d' % bx[1], DIMBOX),
        ([bx[2]], '%dx%d\ncells' % ((bx[2] >> 4) + 1, (bx[2] & 15) + 1), DIMBOX),
        ([bx[3]], '\n'.join(who), DIMBOX),
    ]


DIMBOX = (170, 150, 210)


def fig_section(a):
    b = FR.level_bytes(a.level)
    sec = b['level/sections.bin']
    tab = LEVEL_TABLES[a.level]
    ent = sec[8 * a.section:8 * a.section + 8]
    eo, oo = ent[4] << 8 | ent[5], ent[6] << 8 | ent[7]
    exits, objects = FR.parse_lists(sec, (eo, oo))
    f, fs, fb = K.font(14), K.font(12), K.font(16)
    rows = 3 + len(objects)
    img = Image.new("RGB", (W, 140 + rows * 84), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Level %d section %d, byte by byte (SectionTable $%04X + 8 x %d = $%04X)'
           % (a.level, a.section, tab, a.section, tab + 8 * a.section), fill=K.TEXT, font=fb)
    y = 44
    d.text((14, y), 'the entry', fill=K.TEXT, font=f)
    byte_row(d, 110, y, [
        (ent[0:2], 'map: Maps\n+ $%04X' % (ent[0] << 8 | ent[1]), GRN), (ent[2:3], 'pad', K.DIM),
        (ent[3:4], 'limit\n%d' % ent[3], GRN),
        (ent[4:6], 'exits:\n$%04X' % (tab + eo), GRN),
        (ent[6:8], 'objects:\n$%04X' % (tab + oo), GRN)], f, fs)
    y += 74
    d.text((14, y), 'exits', fill=K.TEXT, font=f)
    x = 110
    for e in exits:
        side = 'left' if e[0] & 1 else 'right'
        x = byte_row(d, x, y, [([e[0]], 'flags $%02X\n%s%s' % (e[0], side, ', END' if e[0] & 0x80 else ''), CYA),
                               ([e[1]], 'feet\nrow %d' % e[1], CYA), ([e[2]], 'to\nsect. %d' % e[2], CYA),
                               ([e[3]], 'arrive\nrow %d' % e[3], CYA)], f, fs) + 8
    byte_row(d, x, y, [([sec[eo + 4 * len(exits)]], 'end', K.DIM)], f, fs)
    y += 74
    d.text((14, y), 'objects', fill=K.TEXT, font=f)
    for rec, boxes in objects:
        x = byte_row(d, 110, y, entry_meaning(rec), f, fs) + 10
        for bx in boxes:
            x = byte_row(d, x, y, box_meaning(bx), f, fs) + 10
        y += 84
    byte_row(d, 110, y, [([0], 'end', K.DIM)], f, fs)
    # the map beside
    m, _ex = FR.draw_section(b, a.section)
    sc = 1
    m = m.resize((m.width * sc, m.height * sc), Image.NEAREST)
    mx = W - m.width - 14
    img.paste(m, (mx, 44))
    d.text((mx, 44 + m.height + 4), 'the section (map rows 2 on, %d x)\nyellow: traps and pickups,\ndots: their boxes'
           % sc, fill=K.DIM, font=fs)
    img = img.crop((0, 0, W, max(y + 60, 44 + m.height + 60)))
    img.save(a.out)
    print(a.out, img.size)


A_FIELDS = ['kind', 'x', 'y', '', 'sprite', '', 'flags', 'wid', 'hgt', 'delay', 'anim', '', 'entry', '', 'step',
            'path', '', 'path2', '', 'anim2', '', 'kind2', 'dx', 'dy']
B_FIELDS = ['kind', 'x', 'y', '', 'sprite', '', 'xstep', '', '', 'walk', 'anim', '', 'entry', '', 'vy', '', 'yfrac',
            'climb', 'pstep', 'plen', 'dying', 'drift', 'stun']


def draw_record(d, x, y, rec, fields, col, fs, f):
    bw = 41
    for i, v in enumerate(rec):
        d.text((x + i * bw + 2, y), fields[i], fill=K.DIM, font=fs)
        d.rectangle((x + i * bw, y + 16, x + i * bw + bw - 3, y + 40), fill=K.PANEL, outline=col)
        d.text((x + i * bw + 7, y + 20), '%02X' % v, fill=col, font=f)


def fig_records(a):
    mem = session_mem(a.work)
    fr, _, t = a.at.partition(':')
    fr, t = int(fr), int(t or 0)
    ta = mem(fr, 0x7B8F, 6 * 24)
    tb = mem(fr, 0x7C20, 4 * 23)
    f, fs, fb = K.font(13), K.font(11), K.font(16)
    img = Image.new('RGB', (W, 760), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), a.title or 'The object tables at frame %d' % fr, fill=K.TEXT, font=fb)
    y = 44
    d.text((14, y), 'table A ($7B8F, 6 records of 24 bytes): traps and pickups', fill=YEL, font=f)
    y += 22
    for i in range(6):
        r = ta[24 * i:24 * i + 24]
        d.text((14, y + 20), '$%04X' % (0x7B8F + 24 * i), fill=K.TEXT if r[0] else K.DIM, font=fs)
        draw_record(d, 62, y, r, A_FIELDS, YEL if r[0] else K.DIM, fs, f)
        y += 48
    y += 10
    d.text((14, y), 'table B ($7C20, 4 records of 23 bytes): enemies', fill=RED, font=f)
    y += 22
    for i in range(4):
        r = tb[23 * i:23 * i + 23]
        d.text((14, y + 20), '$%04X' % (0x7C20 + 23 * i), fill=K.TEXT if r[0] else K.DIM, font=fs)
        draw_record(d, 62, y, r, B_FIELDS, RED if r[0] else K.DIM, fs, f)
        y += 48
    d.text((14, y + 4), 'A record with +0 = 0 is free (grey: its old bytes stay). Words are little-endian '
           '(y = y lo + 256 x y hi).', fill=K.DIM, font=fs)
    img = img.crop((0, 0, W, y + 30))
    img.save(a.out)
    print(a.out, img.size)


def decode_path(b, addr, base, limit=400):
    """[(dx, dy) a pass] until the jump, and the step list [(count, dx, dy) or ('fx', n)]"""
    data = b
    p = addr - base
    steps, passes = [], []
    while len(steps) < 60:
        c = data[p]
        if c == 0xFF:
            steps.append(('fx', data[p + 1]))
            p += 2
            continue
        if c == 0:
            steps.append(('jump', data[p + 1] | data[p + 2] << 8))
            break
        v = data[p + 1]
        dx, dy = v >> 4, v & 15
        dx = dx - 16 if dx & 8 else dx
        dy = dy - 16 if dy & 8 else dy
        dx, dy = (8 if dx == 7 else dx), (8 if dy == 7 else dy)
        steps.append((c, dx, dy))
        passes += [(dx, dy)] * c
        p += 2
    return steps, passes[:limit]


def decode_anim(data, addr, base):
    p = addr - base
    out = []
    while len(out) < 40:
        c = data[p]
        if c == 0xFF:
            out.append(('jump', data[p + 1] | data[p + 2] << 8))
            break
        if c == 0xFD:
            out.append(('fx', data[p + 1]))
            p += 2
        elif c >= 0x80:
            out.append((data[p + 1], max(1, c & 0x7F)))
            p += 2
        else:
            out.append((c, 1))
            p += 1
    return out


def fig_kind(a):
    b = FR.level_bytes(a.level)
    kinds = b['level/kinds.bin']
    anims, paths, recs = b['level/anims.bin'], b['level/paths.bin'], b['level/kinds-2.bin']
    hdr = {1: (0xF205, 0xF269, 0xF4BA, 0xF668)}[a.level]
    ra = kinds[2 * a.kind] | kinds[2 * a.kind + 1] << 8
    rec = recs[ra - hdr[3]:ra - hdr[3] + 11]
    frame_map = b['level/frame-map.bin']
    sprites = b['level/sprites.bin']
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 900), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Level %d trap kind %d: KindTable word $%04X, its record, its paths and its animation'
           % (a.level, a.kind, ra), fill=K.TEXT, font=fb)
    w2 = lambda i: rec[i] | rec[i + 1] << 8  # noqa: E731
    byte_row(d, 14, 44, [
        (rec[0:1], 'width\n%d' % rec[0], YEL), (rec[1:2], 'height\n%d' % rec[1], YEL),
        (rec[2:3], '+0 bits: %s\nswitch: +0 OR $%02X' % (', '.join(n for bt, n in ((6, 'deadly'), (7, 'platform'))
                                                                  if rec[2] >> bt & 1) or 'none', (rec[2] & 0x3F) * 4 & 0xFF), YEL),
        (rec[3:5], 'path\n$%04X' % w2(3), GRN), (rec[5:7], 'anim\n$%04X' % w2(5), CYA),
        (rec[7:9], 'path2\n$%04X' % w2(7), GRN), (rec[9:11], 'anim2\n$%04X' % w2(9), CYA)], f, fs)
    y = 120
    for label, pa in (('path', w2(3)), ('path2', w2(7))):
        if not 0 <= pa - hdr[2] < len(paths):
            d.text((14, y), '%s $%04X: outside TrapPaths: a 7-byte record, the next record\'s bytes, never used'
                   % (label, pa), fill=K.DIM, font=f)
            y += 30
            continue
        steps, passes = decode_path(paths, pa, hdr[2])
        txt = ' '.join(('fx %d' % s[1]) if s[0] == 'fx' else ('jump $%04X' % s[1]) if s[0] == 'jump'
                       else '%dx(%+d,%+d)' % s for s in steps)
        d.text((14, y), '%s $%04X: %s' % (label, pa, txt), fill=GRN, font=f)
        # trajectory: y offset by pass
        cx, cy, cw, ch = 14, y + 22, W - 28, 150
        d.rectangle((cx, cy, cx + cw, cy + ch), fill=K.PANEL)
        ys, yy = [0], 0
        for dx, dy in passes:
            yy += dy
            ys.append(yy)
        lo, hi = min(ys + [0]), max(ys + [8])
        n = max(1, len(ys) - 1)
        pts = [(cx + 6 + i * (cw - 12) / n, cy + 28 + (v - lo) * (ch - 36) / (hi - lo or 1)) for i, v in enumerate(ys)]
        if len(pts) > 1:
            d.line(pts, fill=GRN, width=2)
        d.text((cx + 6, cy + 4), 'y offset by pass (down is down): %d passes, %d to %d px'
               % (n, lo, hi), fill=K.DIM, font=fs)
        y = cy + ch + 14
    for label, aa in (('anim', w2(5)), ('anim2', w2(9))):
        if not 0 <= aa - hdr[1] < len(anims):
            d.text((14, y), '%s $%04X: outside TrapAnims: a 7-byte record, never used' % (label, aa), fill=K.DIM,
                   font=f)
            y += 30
            continue
        items = decode_anim(anims, aa, hdr[1])
        d.text((14, y), '%s $%04X:' % (label, aa), fill=CYA, font=f)
        x = 14
        y += 22
        for it in items:
            if it[0] in ('fx', 'jump'):
                d.text((x, y + 30), ('fx %d' if it[0] == 'fx' else 'jump\n$%04X') % it[1], fill=CYA, font=fs)
                x += 54
                continue
            fr, n = it
            if fr == 0x7F or frame_map[fr - 1] == 0x7F:
                d.rectangle((x, y, x + 47, y + 41), outline=K.DIM)
                d.text((x + 4, y + 12), 'hidden', fill=K.DIM, font=fs)
            else:
                sp = frame_map[fr - 1]
                pix = FRN.sprite_pixels(sprites[128 * (sp & 0x7F):128 * (sp & 0x7F) + 128])
                im = Image.new('RGB', (24, 21), (0, 0, 0))
                px = im.load()
                for r, line in enumerate(pix[:21]):
                    for c, v in enumerate(line):
                        px[c, r] = {0: (0, 0, 0), 1: (230, 230, 230), 3: (40, 60, 40)}[v]
                if sp & 0x80:
                    im = im.transpose(Image.FLIP_LEFT_RIGHT)
                img.paste(im.resize((48, 42), Image.NEAREST), (x, y))
            d.text((x, y + 44), 'f%d %dp' % (fr, n), fill=K.TEXT, font=fs)
            x += 56
            if x > W - 60:
                x = 14
                y += 70
        y += 78
    img = img.crop((0, 0, W, y))
    img.save(a.out)
    print(a.out, img.size)


def fig_play(a):
    mem = session_mem(a.work)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    pictures = []
    for fr in range(a.start, a.end + 1, a.step):
        scr = mem(fr, 0x4000, 6912)
        ta, tb = mem(fr, 0x7B8F, 6 * 24), mem(fr, 0x7C20, 4 * 23)
        rk = mem(fr, 0x9BAB, 0x1C)
        top = mem(fr, 0x88CF, 1)[0]
        img = Image.new('RGB', (W, 440), K.BACKGROUND)
        img.paste(zxscreen.render(scr, 2).convert('RGB'), (4, 30))
        d = ImageDraw.Draw(img)
        d.text((8, 6), a.title, fill=K.TEXT, font=fb)

        def box(x, y, w, h, col):
            # view y 72 = screen row 8 px (view row 9 is the screen's row 1)
            sy = y - 64
            if -h < sy < 192:
                d.rectangle((4 + 2 * x, 30 + 2 * sy, 4 + 2 * (x + w) - 1, 30 + 2 * (sy + h) - 1), outline=col, width=2)
        lines = []
        for i in range(6):
            r = ta[24 * i:24 * i + 24]
            if r[0]:
                y = r[2] | r[3] << 8
                box(r[1], y, r[7], r[8], YEL)
                lines.append((YEL, 'A%d kind $%02X x %3d y %3d  %dx%d  path $%04X' % (
                    i, r[0], r[1], y, r[7], r[8], r[0x0F] | r[0x10] << 8)))
        for i in range(4):
            r = tb[23 * i:23 * i + 23]
            if r[0]:
                y = r[2] | r[3] << 8
                box(r[1] + 4, y, 16, 21, RED)
                st = 'dying' if r[0x14] else 'stunned' if r[0x16] else 'climbing' if r[0x11] else 'walking'
                lines.append((RED, 'B%d kind $%02X x %3d y %3d  step %+d  %s' % (
                    i, r[0], r[1], y, (r[6] & 0x7F) - (0x80 if r[6] & 0x40 else 0), st)))
        rx, ry = rk[1], rk[2] | rk[3] << 8
        box(rx + 4, ry, 16, 21, GRN)
        lines.append((GRN, 'Rick x %3d y %3d' % (rx, ry)))
        if rk[9]:
            box(rk[10], rk[11] | rk[12] << 8, 8, 4, WHT)
            lines.append((WHT, 'bullet x %d' % rk[10]))
        if rk[18]:
            box(rk[19], rk[20] | rk[21] << 8, 16, 8, WHT)
            lines.append((WHT, 'detonator x %d' % rk[19]))
        px = 530
        d.text((px, 30), 'frame %d   view top row %d' % (fr, top), fill=K.TEXT, font=fb)
        for j, (col, t) in enumerate(lines):
            d.text((px, 58 + 20 * j), t, fill=col, font=fs)
        d.text((px, 400), 'yellow: table A, red: table B, green: Rick', fill=K.DIM, font=fs)
        pictures.append(img)
    K.save_gif(a.out, pictures, [a.step * 20] * (len(pictures) - 1) + [2000])
    print(a.out, len(pictures), 'pictures')


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('section')
    p.add_argument('--level', type=int, default=1)
    p.add_argument('--section', type=int, default=6)
    p.add_argument('out')
    p.set_defaults(fn=fig_section)
    p = sub.add_parser('records')
    p.add_argument('--work', required=True)
    p.add_argument('--at', required=True)
    p.add_argument('--title', default='')
    p.add_argument('out')
    p.set_defaults(fn=fig_records)
    p = sub.add_parser('kind')
    p.add_argument('--level', type=int, default=1)
    p.add_argument('--kind', type=int, default=1)
    p.add_argument('out')
    p.set_defaults(fn=fig_kind)
    p = sub.add_parser('play')
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=2)
    p.add_argument('--title', default='The objects at work')
    p.add_argument('out')
    p.set_defaults(fn=fig_play)
    a = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    a.fn(a)


if __name__ == '__main__':
    main()
