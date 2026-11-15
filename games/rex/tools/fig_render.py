#!/usr/bin/env python3
"""The figures of doc 6 (rendering), drawn from build/game.bin and from the recordings' screens.

    python3 tools/fig_render.py layout --scr work/stage1/c1/screens/001500.scr --out docs/img/render/layout.png
    python3 tools/fig_render.py build --room 0 --row 3 --col 6 --scr SCR --out docs/img/render/build-block.png
    python3 tools/fig_render.py shifts --out docs/img/render/shifts.png
    python3 tools/fig_render.py animchars --out docs/img/render/anim-chars.png
    python3 tools/fig_render.py sheet --calls work/docs/rxB/sprites-calls.json --out docs/img/render/sprites.png

layout: the screen's parts (the HUD, the play area, the side columns) on a real frame, beside the memory the
renderer uses ($D962-$FFFF) and the coordinate rules. build: one block of a room from the map byte to the pixels,
with every address the build writes. shifts: a sprite's pre-shifted copies, the frame list that picks one by X & 7,
and the mirrored draw through MirrorTable. animchars: the characters the main loop changes each pass, eight passes
simulated from the code. sheet: every picture DrawSprite drew in the recordings (the calls gathered from traces by
work/docs/rxB/collect_sprites.py), each with its address, size, frame list and caller.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_controls as FC  # noqa: E402
K = FC.K
WIDTH = FC.WIDTH

FONT = 0x5FE0
CHAR_FLAGS, CHAR_GFX, CHAR_ATTRS, BLOCK_DEFS, ROOM_MAPS = 0x62E0, 0x63E0, 0x6BE0, 0x6CE0, 0x75E0
BACK_BUFFER, ATTR_SHADOW, ROOM_GRID = 0xEB00, 0xE4FF, 0xE19F
MIRROR = 0xAD5D


def ink(attr):
    bright = attr >> 6 & 1
    return K.ink_colour(attr & 7, bright), K.ink_colour(attr >> 3 & 7, bright)


def draw_bytes(pic, x, y, data, width_bytes, scale, fg=(235, 235, 235), bg=(0, 0, 0)):
    """width_bytes x len/width rows of bitmap at (x, y), each pixel scale x scale"""
    d = ImageDraw.Draw(pic)
    rows = len(data) // width_bytes
    d.rectangle([x, y, x + width_bytes * 8 * scale - 1, y + rows * scale - 1], fill=bg)
    for r in range(rows):
        for b in range(width_bytes):
            v = data[r * width_bytes + b]
            for bit in range(8):
                if v & (0x80 >> bit):
                    px = x + (b * 8 + bit) * scale
                    d.rectangle([px, y + r * scale, px + scale - 1, y + (r + 1) * scale - 1], fill=fg)


def read_scr(path):
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = open(path, 'rb').read()[:6912]
    return mem


# ---------------------------------------------------------------------------------------------------------------

def cmd_layout(args):
    mem = read_scr(args.scr)
    scr = K.render_screen(mem).resize((512, 384), Image.NEAREST)
    pic = Image.new('RGB', (WIDTH, 560), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    FC.title(d, 'The screen and the memory behind it: the HUD, the 30 x 21 play area and the back buffer')
    x0, y0 = 12, 44
    pic.paste(scr, (x0, y0))
    # overlays
    hud = (x0, y0, x0 + 511, y0 + 47)
    d.rectangle(hud, outline=(255, 210, 70), width=2)
    play = (x0 + 16, y0 + 48, x0 + 16 + 480 - 1, y0 + 383)
    d.rectangle(play, outline=(80, 210, 120), width=2)
    for xx in (x0, x0 + 496):
        d.rectangle([xx, y0 + 48, xx + 15, y0 + 383], outline=(90, 150, 250), width=2)
    d.text((x0, y0 + 390), 'yellow: the HUD, lines 0-23 (DrawHud $A1A5 and its updaters)', fill=(255, 210, 70), font=fs)
    d.text((x0, y0 + 406), 'green: the play area, lines 24-191, columns 1-30 (BufferToScreen $A28A)', fill=(80, 210, 120),
           font=fs)
    d.text((x0, y0 + 422), 'blue: columns 0 and 31, never drawn, attribute $47 (CopyAttrs $C8BF)', fill=(90, 150, 250),
           font=fs)
    d.text((x0, y0 + 446), 'A sprite at (X, Y): screen pixel column X, screen line Y + 8.', fill=K.TEXT, font=fs)
    d.text((x0, y0 + 462), 'Buffer byte: $E8FF + 32 x Y + X / 8.', fill=K.TEXT,
           font=fs)
    d.text((x0, y0 + 478), 'Buffer column c (0-29) goes to screen column c + 1.', fill=K.TEXT, font=fs)
    # memory map
    regions = [
        (0xD962, 0xDE9E, 'SceneryCellList $D962: buffer, picture; $FF ends', (200, 110, 230)),
        (0xDE9F, 0xE19E, 'CellIndexMap $DE9F: list index, 32 x 24', (150, 90, 200)),
        (0xE19F, 0xE49E, 'RoomGrid $E19F: cell types (CharFlags), 32 x 24', (230, 90, 80)),
        (0xE49F, 0xE4FE, '', (70, 70, 80)),
        (0xE4FF, 0xE7FE, 'attribute shadow $E4FF (= $5800), play $E55F', (240, 200, 70)),
        (0xE7FF, 0xEAFF, 'origins: shots $E7FF, sparkle $E89F,\nsprites $E8FF, objects $E9FF', (110, 110, 130)),
        (0xEB00, 0xFFFF, 'BackBuffer $EB00-$FFFF: 168 lines x 32', (80, 210, 120)),
    ]
    mx, my, mh = 545, 44, 470
    lo, hi = 0xD962, 0x10000
    d.text((mx, my), 'Memory $D962-$FFFF in play', fill=K.TEXT, font=f)
    my += 24
    for a, b, label, col in regions:
        ya = my + (a - lo) * mh / (hi - lo)
        yb = my + (b + 1 - lo) * mh / (hi - lo)
        d.rectangle([mx, ya, mx + 40, yb - 1], fill=col)
        d.multiline_text((mx + 48, ya + max(0, (yb - ya) / 2 - 8)), label, fill=K.TEXT, font=fs)
    d.text((mx, my + mh + 6), 'A pass copies 168 x 30 = 5040 of the 5376 bytes.', fill=K.DIM, font=fs)
    pic.save(args.out)
    print(args.out)


# ---------------------------------------------------------------------------------------------------------------

def cmd_build(args):
    mem = FC.image()
    room, row, col = args.room, args.row, args.col
    map_addr = ROOM_MAPS + 70 * room + 10 * row + col
    code = mem[map_addr]
    block = BLOCK_DEFS + 9 * code
    chars = list(mem[block:block + 9])
    ix = BACK_BUFFER + 3 * 0x300 * 0 + row * 0x300 + col * 3
    pic = Image.new('RGB', (WIDTH, 700), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    FC.title(d, f'Room {room}, block row {row}, column {col}: the map byte to the pixels, with every address DrawRoom '
                f'writes')
    y = 42
    d.text((12, y), f'1. RoomMaps $75E0 + 70 x {room} + 10 x {row} + {col} = ${map_addr:04X} holds block ${code:02X}',
           fill=K.TEXT, font=fb)
    y += 24
    d.text((12, y), f'2. BlockDefs $6CE0 + 9 x ${code:02X} = ${block:04X}: ' + ' '.join(f'{c:02X}' for c in chars) +
           '  (3 rows of 3 characters)', fill=K.TEXT, font=fb)
    y += 34
    d.text((12, y), '3. Character c: bytes CharGraphics $63E0 + 8c, attribute CharAttrs $6BE0 + c, type CharFlags $62E0 + c', fill=K.TEXT, font=fb)
    y += 26
    sc = 5
    cell_w = 330
    rows = []
    for i, c in enumerate(chars):
        r, cc = divmod(i, 3)
        x = 12 + cc * cell_w
        yy = y + r * 120
        attr = mem[CHAR_ATTRS + c]
        fg, bg = ink(attr)
        draw_bytes(pic, x, yy, mem[CHAR_GFX + 8 * c:CHAR_GFX + 8 * c + 8], 1, sc, fg, bg)
        d.rectangle([x - 1, yy - 1, x + 8 * sc, yy + 8 * sc], outline=(90, 90, 100))
        buf = ix + r * 0x100 + cc
        off = buf - 0xEAFF
        k = (off & 0xE0) * 1 // 1
        shadow_index = ((off & 0xFFE0) >> 3) + (off & 0x1F)
        shadow = 0xE55F + shadow_index
        grid = 0xE1FF + shadow_index
        line = 24 + (buf - BACK_BUFFER) // 32
        scol = (buf - BACK_BUFFER) % 32 + 1
        listed = c not in (0, 1, 0x10, 0x71, 0x81, 0x91)
        tx = x + 8 * sc + 10
        d.text((tx, yy), f'char ${c:02X}: attr ${attr:02X}, type {mem[CHAR_FLAGS + c]}', fill=K.TEXT, font=fs)
        d.text((tx, yy + 16), f'buffer ${buf:04X} (+32 a line)', fill=(80, 210, 120), font=fs)
        d.text((tx, yy + 32), f'shadow ${shadow:04X}, grid ${grid:04X}', fill=(240, 200, 70), font=fs)
        d.text((tx, yy + 48), f'screen line {line}, column {scol}', fill=K.DIM, font=fs)
        d.text((tx, yy + 64), 'listed in SceneryCellList' if listed else 'not listed (blank or marker)',
               fill=(200, 110, 230) if listed else K.DIM, font=fs)
        rows.append((c, buf, shadow, grid, line, scol, listed))
    y += 3 * 120 + 6
    d.text((12, y), '4. BuildRoom then clears the buffer; DrawAnimCells redraws only the listed cells;', fill=K.TEXT,
           font=fb)
    y += 20
    d.text((12, y), '   BufferToScreen copies the buffer, CopyAttrs copies the shadow to $5860.', fill=K.TEXT, font=fb)
    y += 28
    if args.scr:
        smem = read_scr(args.scr)
        scr = K.render_screen(smem)
        # crop around the block: 3 x 3 characters at screen (line, column)
        l0 = 24 + row * 24
        c0 = col * 3 + 1
        box = (max(0, (c0 - 3) * 8), max(0, l0 - 16), min(256, (c0 + 6) * 8), min(192, l0 + 40))
        crop = scr.crop(box).resize(((box[2] - box[0]) * 3, (box[3] - box[1]) * 3), Image.NEAREST)
        pic.paste(crop, (12, y))
        bx = 12 + ((c0 * 8) - box[0]) * 3
        by = y + (l0 - box[1]) * 3
        d.rectangle([bx, by, bx + 24 * 3 - 1, by + 24 * 3 - 1], outline=(255, 210, 70), width=2)
        d.text((12 + crop.width + 16, y), f'5. On screen ({os.path.basename(args.scr)}): the block at lines {l0}-'
               f'{l0 + 23},', fill=K.TEXT, font=fs)
        d.text((12 + crop.width + 16, y + 16), f'columns {c0}-{c0 + 2} (yellow box), at 3x.', fill=K.TEXT, font=fs)
        y += crop.height + 10
    pic = pic.crop((0, 0, WIDTH, y + 8))
    pic.save(args.out)
    for r in rows:
        print('char %02X buffer %04X shadow %04X grid %04X line %d col %d listed %s' % r)
    print(args.out)


# ---------------------------------------------------------------------------------------------------------------

def cmd_shifts(args):
    mem = FC.image()
    pic_addr, frames_addr, w, h = 0x80F2, 0xAE5D, 3, 16
    frames = list(mem[frames_addr:frames_addr + 8])
    pic = Image.new('RGB', (WIDTH, 640), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    FC.title(d, 'SpriteRex $80F2, 3 x 16: four copies, four walk poses at 2-pixel steps; X & 7 picks one')
    y = 44
    d.text((12, y), 'ShiftFrames $AE5D: ' + ' '.join(f'{v:02X}' for v in frames) +
           '  (the offset of the copy for X & 7 = 0 ... 7)', fill=K.TEXT, font=fb)
    y += 30
    sc = 4
    for i, off in enumerate(sorted(set(frames))):
        x = 12 + i * 255
        data = mem[pic_addr + off:pic_addr + off + w * h]
        draw_bytes(pic, x, y + 20, data, w, sc)
        for b in range(1, w):
            d.line([x + b * 8 * sc, y + 20, x + b * 8 * sc, y + 20 + h * sc], fill=(60, 60, 80))
        sel = [str(k) for k in range(8) if frames[k] == off]
        d.text((x, y), f'${pic_addr + off:04X} (+{off}): X & 7 = {", ".join(sel)}', fill=K.TEXT, font=fs)
    y += 20 + h * sc + 20
    d.text((12, y), 'Facing left (A <> 0): DrawMirrored $B2C1 takes the list from its end (entry 7 - X & 7), sends each '
           'byte through MirrorTable $AD5D', fill=K.TEXT, font=f)
    y += 18
    d.text((12, y), '(bits reversed) and writes the bytes right to left, starting 2 bytes right of the address.',
           fill=K.TEXT, font=f)
    y += 26
    for i, xm in enumerate((0, 2, 4, 6)):
        off = frames[7 - xm]
        data = mem[pic_addr + off:pic_addr + off + w * h]
        out = bytearray(w * h)
        for r in range(h):
            for b in range(w):
                out[r * w + (w - 1 - b)] = mem[MIRROR + data[r * w + b]]
        x = 12 + i * 255
        draw_bytes(pic, x, y + 20, out, w, sc, fg=(120, 200, 255))
        d.text((x, y), f'X & 7 = {xm}: copy +{off}, mirrored', fill=K.TEXT, font=fs)
    y += 20 + h * sc + 20
    d.text((12, y), 'MirrorTable $AD5D: 256 bytes, entry n = n with its bits reversed (' +
           ', '.join(f'${n:02X} -> ${mem[MIRROR + n]:02X}' for n in (0x01, 0x03, 0x80, 0xC0)) + ').', fill=K.DIM,
           font=fs)
    y += 18
    d.text((12, y), 'The other lists: ShiftFrames2 $AE65 (the shield, 4 x 21, 84-byte copies), $AE6D (36-byte copies), '
           '$AE75 (8 copies of 16), $AE7D (22), $AE85.', fill=K.DIM, font=fs)
    pic = pic.crop((0, 0, WIDTH, y + 26))
    pic.save(args.out)
    print(args.out)


# ---------------------------------------------------------------------------------------------------------------

def cmd_animchars(args):
    mem = FC.image()
    sym = FC.symbols()
    steps = 8
    chars = {n: bytearray(mem[CHAR_GFX + 8 * n:CHAR_GFX + 8 * n + 8]) for n in (11, 26, 28, 68, 111, 127, 143, 250, 251,
                                                                                 252, 253, 254, 255)}
    counts = {'68': 0, '127': 0, '250': 0}
    lists = {'68': sym['FramesList1'], '127': sym['FramesList4'], '250': sym['FramesList2']}
    sizes = {'68': 8, '127': 8, '250': 16}
    history = []
    toggle = 0
    for s in range(steps):
        history.append({n: bytes(v) for n, v in chars.items()})
        for i in range(8):
            v = chars[111][i]
            chars[111][i] = ((v >> 1) | (v << 7)) & 0xFF
            v = chars[143][i]
            v = ((v << 1) | (v >> 7)) & 0xFF
            chars[143][i] = ((v << 1) | (v >> 7)) & 0xFF
        for n in (28, 26):  # RollCharDown: one line down
            c = chars[n]
            chars[n] = bytearray([c[7]]) + c[:7]
        c = chars[11]  # RollCharUp: one line up
        chars[11] = c[1:] + bytearray([c[0]])
        src = sym['AnimFramesA'] if toggle == 0 else sym['AnimFramesB']
        frames = mem[src:src + 32]
        for k in range(4):
            chars[252 + k] = bytearray(frames[8 * k:8 * k + 8])
        for key in ('250', '68', '127'):
            counts[key] += 2
            while True:
                a = lists[key] + counts[key]
                if mem[a] == 0xFF:
                    counts[key] = 0
                    continue
                break
            p = mem[a] | mem[a + 1] << 8
            data = mem[p:p + sizes[key]]
            if key == '250':
                chars[250] = bytearray(data[:8])
                chars[251] = bytearray(data[8:16])
            else:
                chars[int(key)] = bytearray(data)
        toggle ^= 1
    rows = [(111, 'char 111 $6758: RRC each line (main loop)'), (143, 'char 143 $6858: RLC twice each line'),
            (28, 'char 28 $64C0: RollCharDown $A7BA (a line down)'), (26, 'char 26 $64B0: RollCharDown'),
            (11, 'char 11 $6438: RollCharUp $A7A9 (a line up)'),
            (252, 'chars 252-255 $6BC0: AnimFramesA/B'),
            (250, 'chars 250-251 $6BB0: FramesList2 $A602'), (68, 'char 68 $6600: FramesList1 $A60C'),
            (127, 'char 127 $67D8: FramesList4 $A61A')]
    sc = 5
    pic = Image.new('RGB', (WIDTH, 60 + len(rows) * 52 + 40), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    fs = K.font(12)
    FC.title(d, 'The characters the main loop changes each pass, 8 passes simulated from the code (game.bin)')
    y = 44
    lw = 340
    for n, label in rows:
        attr = mem[CHAR_ATTRS + n]
        fg, bg = ink(attr)
        if bg == fg or attr & 7 == 0:
            fg = (235, 235, 235)
        d.text((12, y + 12), label, fill=K.TEXT, font=fs)
        for s in range(steps):
            x = lw + s * 84
            if n in (252, 250):
                width = 4 if n == 252 else 2
                data = b''.join(history[s][n + k] for k in range(width))
                for k in range(width):
                    draw_bytes(pic, x + k * 8 * 2, y, history[s][n + k], 1, 2, fg, bg)
            else:
                draw_bytes(pic, x, y, history[s][n], 1, sc, fg, bg)
        y += 52
    for s in range(steps):
        d.text((lw + s * 84, y), f'pass {s}', fill=K.DIM, font=fs)
    pic.save(args.out)
    print(args.out)


# ---------------------------------------------------------------------------------------------------------------

def cmd_sheet(args):
    mem = FC.image()
    sym = FC.symbols()
    labels = sorted((a, n) for n, a in sym.items())
    starts = [a for a, _ in labels]

    def name_of(addr):
        best = None
        for a, n in labels:
            if a <= addr:
                best = (a, n)
            else:
                break
        return best

    def next_label(addr):
        for a in starts:
            if a > addr:
                return a
        return addr + 0x100

    calls = json.load(open(args.calls))
    roots = {}
    odd = []
    for key, e in calls.items():
        de, hl, a, w, h, mirror, picture, caller = key.split()
        de, hl, w, h, mirror, picture, caller = (int(de, 16), int(hl, 16), int(w), int(h), int(mirror, 16),
                                                 int(picture, 16), int(caller, 16))
        fixed = bool(mirror & 0x80)
        pic = picture if fixed else de
        root = name_of(pic)
        if pic == 0x6018:  # the explosion: the menu copies 192 bytes from $E336 over DevLinkStub
            root = (0x6018, 'explosion (copied from $E336)')
        elif root is None or root[0] < 0x7F00 or root[0] >= 0x9400:
            odd.append((pic, w, h, e))
            continue
        r = roots.setdefault(root, {'n': 0, 'callers': set(), 'sizes': {}, 'lists': set(), 'mirror': False,
                                    'fixed': False, 'first': e['first']})
        r['n'] += e['n']
        cname = name_of(caller - 3)
        r['callers'].add(cname[1] if cname else f'${caller:04X}')
        r['sizes'][(w, h)] = r['sizes'].get((w, h), 0) + e['n']
        if fixed:
            r['fixed'] = True
        else:
            fl = name_of(hl)
            r['lists'].add(fl[1] if fl and fl[0] == hl else f'${hl:04X}')
        r['mirror'] |= int(a, 16) != 0
    sc = 2
    lw = 300
    plan = []
    for (addr, name), r in sorted(roots.items()):
        w, h = max(r['sizes'], key=r['sizes'].get)
        size = w * h
        end = 0x60D8 if addr == 0x6018 else next_label(addr)
        for lst in r['lists']:
            hl = sym.get(lst)
            if hl is not None:
                end = max(end, addr + max(mem[hl:hl + 8]) + size)
        count = max(1, min(32, (end - addr) // size))
        per_row = max(1, (WIDTH - lw - 12) // (w * 8 * sc + 6))
        lines = (count + per_row - 1) // per_row
        plan.append((addr, name, r, w, h, count, per_row, max(70, lines * (h * sc + 15) + 8), end))
    pic = Image.new('RGB', (WIDTH, 60 + sum(p[7] for p in plan) + 80), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    fs, f = K.font(11), K.font(13)
    FC.title(d, 'Every sprite sheet DrawSprite $B258 drew in the recordings, all its frames in address order')
    y = 40
    for addr, name, r, w, h, count, per_row, hh, end in plan:
        d.text((12, y), f'${addr:04X} {name}', fill=K.TEXT, font=f)
        sizes = ', '.join(f'{a} x {b}' for a, b in r['sizes'])
        d.text((12, y + 17), f'{sizes} bytes; {end - addr} bytes to ${end:04X}', fill=K.DIM, font=fs)
        how = ', '.join(sorted(r['lists'])) or ''
        if r['fixed']:
            how = (how + ', ' if how else '') + 'fixed frame'
        d.text((12, y + 31), how + (', mirrored' if r['mirror'] else ''), fill=K.DIM, font=fs)
        d.text((12, y + 45), 'by ' + ', '.join(sorted(r['callers'])) + f'; {r["n"]} calls', fill=(80, 210, 120),
               font=fs)
        for i in range(count):
            o = i * w * h
            px = lw + (i % per_row) * (w * 8 * sc + 6)
            py = y + (i // per_row) * (h * sc + 15)
            d.text((px, py), f'+{o}', fill=K.DIM, font=K.font(10))
            src = addr + o + (0xE336 - 0x6018 if addr == 0x6018 else 0)
            draw_bytes(pic, px, py + 13, mem[src:src + w * h], w, sc)
        y += hh
        d.line([12, y - 4, WIDTH - 12, y - 4], fill=(40, 40, 50))
    d.text((12, y + 4), f'{len(plan)} sheets from {sum(p[2]["n"] for p in plan)} calls in 22 recordings; frames cut at '
           'the most used size, at most 32 shown.', fill=K.DIM, font=f)
    if odd:
        d.text((12, y + 22), 'Calls with a picture outside the sprite area: ' + ', '.join(
            sorted({f'${p:04X} {w}x{h}' for p, w, h, _ in odd})), fill=(230, 90, 80), font=f)
    pic = pic.crop((0, 0, WIDTH, y + 46))
    pic.save(args.out)
    for addr, name, r, w, h, count, *_ in plan:
        print(f'{addr:04X} {name} {dict(r["sizes"])} {sorted(r["lists"])} fixed={r["fixed"]} mirror={r["mirror"]} '
              f'{sorted(r["callers"])} n={r["n"]} first={r["first"]} frames={count}')
    for o in odd:
        print('odd', hex(o[0]), o[1], o[2], o[3])
    print(args.out)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('layout')
    s.add_argument('--scr', required=True)
    s.add_argument('--out', required=True)
    s = sub.add_parser('build')
    s.add_argument('--room', type=int, default=0)
    s.add_argument('--row', type=int, default=3)
    s.add_argument('--col', type=int, default=6)
    s.add_argument('--scr')
    s.add_argument('--out', required=True)
    s = sub.add_parser('shifts')
    s.add_argument('--out', required=True)
    s = sub.add_parser('animchars')
    s.add_argument('--out', required=True)
    s = sub.add_parser('sheet')
    s.add_argument('--calls', required=True)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'layout': cmd_layout, 'build': cmd_build, 'shifts': cmd_shifts, 'animchars': cmd_animchars,
     'sheet': cmd_sheet}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
