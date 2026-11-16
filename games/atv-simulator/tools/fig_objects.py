#!/usr/bin/env python3
"""ATV Simulator's objects for doc 7: data sheets of the trail record, the item, the animation record and the
player's 50-byte record; a stretch of trail 1 decoded over the buffer of the trails recording; the motions of the
animation records run as AnimObject runs them; the two scrolls of a ride.

    python3 tools/fig_objects.py fig-sheets OUT.png              the trail record, the item, the animation record
    python3 tools/fig_objects.py fig-record OUT.png              the player's record $D772-$D7A3, byte by byte
    python3 tools/fig_objects.py fig-stretch SAMPLE.jsonl FRAME OUT.png
                                                                 the buffer of FRAME with every item's box
    python3 tools/fig_objects.py fig-motion OUT.png              the animation records' motions over 80 passes
    python3 tools/fig_objects.py fig-scroll VARS.jsonl OUT.png   TrackPos and SceneryPos along a ride

The bytes come from the case's build (build/game.bin at $6338, the trail resources through res_formats.load) and
from samples of a recording (work/docs/atC/sample.py: memory at the start of a frame). SAMPLE.jsonl needs the
ranges F03C-F71B (BufferP1), D70E-D7A7 (the records), 7CB4-7D33 (list A1 as InitListWidths left it), 7F80-7FB1
(list B1) and 811B-8122 (ListBase, ListIndexPtr, ListScroll). The stretch is drawn at the ListScroll each list was
walked with: the sample's TrackPos less the step Advance made after the walk is given by --scroll A,B.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import res_formats as RF  # noqa: E402

BASE = 0x6338


def font(size):
    from PIL import ImageFont
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf',
              '/System/Library/Fonts/Helvetica.ttc'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def image():
    mem = bytearray(0x10000)
    game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[BASE:BASE + len(game)] = game
    return mem


def sprite_sizes():
    """game sprite number -> (width in bytes, height, advance) from the game bank"""
    data = RF.load('sprites/game.bin')
    count = data[0]
    out = {}
    for i in range(count):
        off = RF.word(data, 4 + 2 * i)
        out[i] = (data[off], data[off + 1], data[off + 2])
    return out


# ---- data sheets --------------------------------------------------------------------------------------------------

def sheet(d, x, y, title, cells, f, fs, w=92):
    """a row of byte cells: (offset text, name, value text, colour)"""
    d.text((x, y), title, fill='black', font=f)
    y += 24
    for i, (off, name, val, col) in enumerate(cells):
        cx = x + i * (w + 2)
        d.rectangle((cx, y, cx + w, y + 70), fill=col, outline='black')
        d.text((cx + 4, y + 3), off, fill=(80, 80, 80), font=fs)
        for k, line in enumerate(name.split('\n')):
            d.text((cx + 4, y + 20 + 14 * k), line, fill='black', font=fs)
        d.text((cx + 4, y + 52), val, fill=(30, 30, 140), font=fs)
    return y + 76


def cmd_fig_sheets(path):
    from PIL import Image, ImageDraw
    mem = image()
    W, H = 1050, 760
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), 'The trail data: a record names two lists, a list is items of six bytes, an item may point at '
                    'an animation record', fill='black', font=fb)
    tr = 0x7C9C
    a, b, ln = (mem[tr + k] | mem[tr + k + 1] << 8 for k in (0, 2, 4))
    blue, green, grey, yellow, pink = (210, 225, 255), (215, 245, 210), (235, 235, 235), (255, 240, 170), (255, 215, 215)
    y = sheet(d, 10, 44, f'A trail record: Trail1 at TrailRecords ${tr:04X} (6 bytes; trails 1-4 in a row, '
                         'Trail5 $EE84, Trail6 $60AC)',
              [('+0', 'list A\nlo', f'${a & 255:02X}', blue), ('+1', 'list A\nhi', f'${a >> 8:02X}', blue),
               ('+2', 'list B\nlo', f'${b & 255:02X}', green), ('+3', 'list B\nhi', f'${b >> 8:02X}', green),
               ('+4', 'length\nlo', f'${ln & 255:02X}', grey), ('+5', 'length\nhi', f'${ln >> 8:02X}', grey)], f, fs)
    d.text((10, y + 2), f'list A ${a:04X}: the ground, the obstacles and the signs; list B ${b:04X}: the scenery; '
                        f'length ${ln:04X}: FinishDistance = ${ln:04X} - $48 = {ln - 0x48}', fill='black', font=fs)
    it = 0x7CB4 + 6 * 11
    dist = mem[it] | mem[it + 1] << 8
    y = sheet(d, 10, y + 34, f'An item: list A1 item 11 at ${it:04X} (6 bytes; $FF at +1 ends the list)',
              [('+0', 'distance\nlo', f'${mem[it]:02X}', blue), ('+1', 'distance\nhi', f'${mem[it + 1]:02X}', blue),
               ('+2', 'y: top row\nabove bottom', f'${mem[it + 2]:02X} = {mem[it + 2]}', yellow),
               ('+3', 'advance\n(InitListWidths)', f'${mem[it + 3]:02X}', yellow),
               ('+4', 'sprite\n(game bank)', f'${mem[it + 4]:02X}', green),
               ('+5', 'flags', f'${mem[it + 5]:02X}', pink)], f, fs)
    d.text((10, y + 2), f'distance {dist}: the dune $AB lifted to y 16, the second step of the staircase; the image '
                        'holds 0 at +3 and InitListWidths fills it (and +2 when 0) from the sprite',
           fill='black', font=fs)
    # the flags
    y += 30
    d.text((10, y), 'The item\'s flags (+5) and what PlaceItem makes of them in ItemFlags $8121', fill='black', font=f)
    y += 24
    rows = [('bit 0', 'the menu bank (MenuSprite) and attributes: the START and FINISH banners', 'ItemFlags bit 0'),
            ('bit 1', 'deferred to DeferredB: drawn after list B, before the ATV (behind it)', 'ItemFlags bit 5'),
            ('bit 2', 'deferred to DeferredA: drawn after the ATV (in front of it)', 'ItemFlags bit 6'),
            ('bit 3', 'masked (the sprite\'s mask cuts the picture behind)', 'ItemFlags bit 7'),
            ('bits 4-7', 'nonzero: +4/+5 are the address of an animation record', 'AnimObject $8A49'),
            ('none', 'drawn at once into the buffer, before AtvPhysics: the ground the wheels find', 'ItemFlags $02')]
    for k, (bit, what, to) in enumerate(rows):
        yy = y + 20 * k
        d.rectangle((10, yy, 1040, yy + 19), fill=(pink if k < 5 else blue), outline=(200, 200, 200))
        d.text((16, yy + 3), bit, fill='black', font=fs)
        d.text((100, yy + 3), what, fill='black', font=fs)
        d.text((820, yy + 3), to, fill=(30, 30, 140), font=fs)
    y += 20 * len(rows) + 20
    an = 0x8070
    cells = [('+0', 'sprite', f'${mem[an]:02X}', green), ('+1', 'ItemFlags', f'${mem[an + 1]:02X}', pink),
             ('+2', 'id\n(SeenIds)', f'${mem[an + 2]:02X}', grey),
             ('+3', 'x period', f'${mem[an + 3]:02X} = {mem[an + 3]}', blue),
             ('+4', 'x counter\nbit 7: back', f'${mem[an + 4]:02X}', blue),
             ('+5', 'y period', f'${mem[an + 5]:02X} = {mem[an + 5]}', yellow),
             ('+6', 'y counter\nbit 7: down', f'${mem[an + 6]:02X}', yellow),
             ('+7', 'steps: x hi\ny lo', f'${mem[an + 7]:02X}', (230, 220, 255)),
             ('+8', 'frame: period\nhi, step lo', f'${mem[an + 8]:02X}', green),
             ('+9', 'frame\ncounter', f'${mem[an + 9]:02X}', green),
             ('+10', 'end', f'${mem[an + 10]:02X}', grey)]
    y = sheet(d, 10, y, f'An animation record: Anim8070 at ${an:04X} (trail 3, list A3 item at $043A)', cells, f, fs,
              w=92)
    d.text((10, y + 2), 'A motion with period 0 is skipped, a period of $FF ends the record. Each pass a counter '
                        'counts up to the period, then down to 0: the item swings', fill='black', font=fs)
    d.text((10, y + 18), 'by period x step and back. x moves the item\'s distance (+0 of the item), y its y (+2), the '
                         'frame the record\'s sprite (+0 here).', fill='black', font=fs)
    im = im.crop((0, 0, W, y + 44))
    im.save(path)


# ---- the player record --------------------------------------------------------------------------------------------

FIELDS = [  # offset, length, name, group
    (0, 1, 'RiderJump', 'rider'), (1, 1, 'VSpeed', 'atv'), (2, 1, 'Mounted', 'rider'), (3, 1, 'AtvFrame', 'atv'),
    (4, 1, 'Facing', 'atv'), (5, 1, 'AtvX', 'atv'), (6, 1, 'AtvHeight', 'atv'), (7, 2, 'PrevHeight x2', 'atv'),
    (9, 1, 'Speed', 'atv'), (10, 2, 'Fuel', 'hud'), (12, 1, 'SpeedBarLen', 'hud'), (13, 1, 'FuelBar', 'hud'),
    (14, 1, 'JumpLatch', 'atv'), (15, 1, 'TurnLeft', 'atv'), (16, 1, 'TurnRight', 'atv'),
    (17, 1, 'RiderFrame', 'rider'), (18, 1, 'RiderFacing', 'rider'), (19, 1, 'RiderX', 'rider'),
    (20, 1, 'RiderHeight', 'rider'), (21, 2, 'RiderSaved X, H', 'rider'), (23, 3, 'Distance (TrackPos)', 'track'),
    (26, 2, 'DistanceIndex', 'track'), (28, 3, 'Scenery (SceneryPos)', 'track'), (31, 2, 'ScenIndex', 'track'),
    (33, 2, 'unused', 'none'), (35, 1, 'WheelieTimer', 'atv'), (36, 1, 'unused', 'none'),
    (37, 1, 'TumbleCount', 'atv'), (38, 1, 'FallPhase', 'rider'), (39, 1, 'ThrowSpeed', 'rider'),
    (40, 1, 'EngineNote', 'atv'), (41, 2, 'Bonus', 'hud'), (43, 3, 'LapTime', 'hud'),
    (46, 1, 'GroundBelow- Rider', 'rider'), (47, 3, 'unused', 'none')]
GROUPS = {'atv': ((255, 220, 200), 'the ATV'), 'rider': ((210, 225, 255), 'the rider'),
          'track': ((215, 245, 210), 'the place on the trail'), 'hud': ((255, 240, 170), 'fuel, bars, bonus, lap'),
          'none': ((235, 235, 235), 'read by no code')}


def cmd_fig_record(path):
    from PIL import Image, ImageDraw
    mem = image()
    W = 1050
    im = Image.new('RGB', (W, 520), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), 'The player\'s record: 50 bytes, Record $D772-$D7A3 (RecordP1 $D70E and RecordP2 $D740 copied '
                    'in and out each pass)', fill='black', font=fb)
    tmpl = mem[0xD7A7:0xD7A7 + 50]
    cw, ch, x0, y0 = 102, 64, 10, 44
    for off, n, name, g in FIELDS:
        col = GROUPS[g][0]
        for k in range(n):
            i = off + k
            r, c = divmod(i, 10)
            x, y = x0 + c * cw, y0 + r * (ch + 6)
            d.rectangle((x, y, x + cw - 3, y + ch), fill=col, outline='black')
            d.text((x + 4, y + 3), f'+{i} ${0xD772 + i:04X}', fill=(80, 80, 80), font=fs)
            label = name if k == 0 else '...'
            words, lines = label.split(' '), ['']
            for wd in words:
                if len(lines[-1]) + len(wd) > 13:
                    lines.append(wd)
                else:
                    lines[-1] = (lines[-1] + ' ' + wd).strip()
            for j, line in enumerate(lines[:2]):
                d.text((x + 4, y + 19 + 14 * j), line, fill='black', font=f)
            d.text((x + 4, y + 48), f'new: ${tmpl[i]:02X}', fill=(30, 30, 140), font=fs)
    y = y0 + 5 * (ch + 6) + 10
    for k, (g, (col, what)) in enumerate(GROUPS.items()):
        x = 10 + k * 205
        d.rectangle((x, y, x + 18, y + 16), fill=col, outline='black')
        d.text((x + 24, y + 1), what, fill='black', font=f)
    d.text((10, y + 28), '"new" is RecordTemplate $D7A7, the bytes InitRecords copies into both records before each '
                         'trail: frame $38, x $48, fuel $2000, the bars $40 and $90,', fill='black', font=fs)
    d.text((10, y + 44), 'the rider at x $18, the engine counter 1, the lap "000". Its last three bytes ($F3 $21 $50) '
                         'are GameEntry\'s first instruction, DI and LD HL: they land in unused bytes.',
           fill='black', font=fs)
    im = im.crop((0, 0, W, y + 66))
    im.save(path)


# ---- a stretch of trail 1 -----------------------------------------------------------------------------------------

def items_of(hexbytes, base):
    b = bytes.fromhex(hexbytes)
    out = []
    for i in range(0, len(b) - 1, 6):
        if b[i + 1] == 0xFF:
            break
        it = b[i:i + 6]
        out.append({'n': i // 6, 'addr': base + i, 'dist': it[0] | it[1] << 8, 'y': it[2], 'adv': it[3],
                    'sprite': it[4], 'flags': it[5], 'anim': bool(it[5] & 0xF0),
                    'ref': it[4] | it[5] << 8})
    return out


def cmd_fig_stretch(sample, frame, path, scroll=None):
    from PIL import Image, ImageDraw
    rows = [json.loads(x) for x in open(sample)]
    r = [x for x in rows if x['f'] == int(frame)][0]
    mem = image()
    sizes = sprite_sizes()
    buf = bytes.fromhex(r['F03C'])
    sa, sb = scroll
    la = items_of(r['7CB4'], 0x7CB4)
    lb = items_of(r['7F80'], 0x7F80)
    W, S, X0, Y0 = 1050, 5, 85, 70
    H = Y0 + 80 * S + 330
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), f'Trail 1 at TrackPos {sa}: BufferP1 at the start of trails frame {frame}, each item\'s box from '
                    'its list (x = distance - scroll)', fill='black', font=fb)
    d.text((10, 30), f'list A1 walked at ListScroll {sa}, list B1 at {sb} (SceneryPos = TrackPos / 4); '
                     'the box is x to x + advance, from row 80 - y down by the sprite\'s height', fill='black', font=f)
    for yy in range(80):
        for xx in range(176):
            if (buf[yy * 22 + xx // 8] >> (7 - xx % 8)) & 1:
                d.rectangle((X0 + xx * S, Y0 + yy * S, X0 + xx * S + S - 1, Y0 + yy * S + S - 1), fill='black')
            else:
                d.rectangle((X0 + xx * S, Y0 + yy * S, X0 + xx * S + S - 1, Y0 + yy * S + S - 1),
                            fill=(250, 248, 235))
    d.rectangle((X0 - 1, Y0 - 1, X0 + 176 * S, Y0 + 80 * S), outline=(120, 120, 120))
    for k in range(0, 177, 16):
        d.line((X0 + k * S, Y0 + 80 * S, X0 + k * S, Y0 + 80 * S + 6), fill='black')
        lab = str(k)
        tw = d.textlength(lab, font=fs)
        d.text((X0 + k * S - (tw if k == 176 else tw / 2), Y0 + 80 * S + 8), lab, fill='black', font=fs)
    for k in range(0, 81, 16):
        d.text((10, Y0 + (80 - k) * S - 7), f'y {k}', fill='black', font=fs)
    colA, colD, colB = (220, 40, 40), (200, 120, 0), (30, 120, 30)

    def box(it, scroll, col, tag, h):
        x = it['dist'] - scroll
        if x + it['adv'] < 0 or x >= 176:
            return None
        x1, x2 = max(0, x), min(176, x + it['adv'])
        top = 80 - it['y']
        d.rectangle((X0 + x1 * S, Y0 + top * S, X0 + x2 * S - 1, Y0 + min(80, top + h) * S - 1), outline=col,
                    width=3)
        d.text((X0 + x1 * S + 3, Y0 + top * S - 15), tag, fill=col, font=fs)
        return x
    lines = []
    for it in la:
        if it['anim']:
            spr, fl = mem[it['ref']], mem[it['ref'] + 1]
        else:
            spr, fl = it['sprite'], it['flags']
        h = sizes.get(spr, (0, it['y'], 0))[1]
        deferred = it['anim'] and (fl & 0x60) or (not it['anim'] and fl & 0x06)
        col = colD if deferred else colA
        x = box(it, sa, col, f"A{it['n']}", h)
        if x is not None:
            kind = 'anim $%04X' % it['ref'] if it['anim'] else 'sprite $%02X' % spr
            lines.append((col, f"A{it['n']} ${it['addr']:04X}: distance {it['dist']}, x {x}, y {it['y']}, advance "
                               f"{it['adv']}, {kind}, h {h}" + (', deferred (front)' if deferred else ', drawn: ground')))
    for it in lb:
        h = sizes.get(it['sprite'], (0, it['y'], 0))[1]
        x = box(it, sb, colB, f"B{it['n']}", h)
        if x is not None:
            lines.append((colB, f"B{it['n']} ${it['addr']:04X}: distance {it['dist']}, x {x}, y {it['y']}, advance "
                                f"{it['adv']}, sprite ${it['sprite']:02X}, h {h}: scenery"))
    y = Y0 + 80 * S + 30
    for k, (col, t) in enumerate(lines):
        d.text((10 + (k % 2) * 520, y + (k // 2) * 18), t, fill=col, font=fs)
    y += ((len(lines) + 1) // 2) * 18 + 14
    # the whole list A1 along the distance
    d.text((10, y), 'List A1 along the trail (0 to the length $0690): each mark an item at its distance, its height '
                    'its y; the shaded band is the 176-pixel window above', fill='black', font=f)
    y += 22
    L, X1, X2, base = 0x690, 40, 1030, y + 80
    sc = (X2 - X1) / L
    d.rectangle((X1 + sa * sc, y, X1 + (sa + 176) * sc, base), fill=(225, 235, 255))
    d.line((X1, base, X2, base), fill='black')
    for it in la:
        x = X1 + it['dist'] * sc
        col = colD if (it['anim'] or it['flags'] & 0x06) else colA
        d.rectangle((x, base - it['y'] * 1.6, x + max(2, it['adv'] * sc), base), outline=col, width=2)
    fin = 0x690 - 0x48
    d.line((X1 + fin * sc, y - 4, X1 + fin * sc, base + 4), fill=(0, 0, 0), width=2)
    d.text((X1 + fin * sc - 100, y - 4), f'FinishDistance {fin}', fill='black', font=fs)
    for k in range(0, L + 1, 200):
        d.text((X1 + k * sc - 8, base + 6), str(k), fill='black', font=fs)
    im = im.crop((0, 0, W, base + 26))
    im.save(path)


# ---- the motions --------------------------------------------------------------------------------------------------

def step(rec, item):
    """one AnimObject step ($8AA1-$8B9F) on rec (the record's bytes, a list) and item ({'dist','y'})"""
    def swing(pi, ci):
        period, c = rec[pi], rec[ci]
        if c & 0x80:
            c = (c & 0x7F) - 1
            if c:
                c |= 0x80
            rec[ci] = c
            return -1
        c += 1
        if c == period:
            c |= 0x80
        rec[ci] = c
        return 1
    if rec[3] == 0xFF:
        return
    if rec[3]:
        item['dist'] += swing(3, 4) * (rec[7] >> 4)
    if rec[5] == 0xFF:
        return
    if rec[5]:
        item['y'] += swing(5, 6) * (rec[7] & 15)
    if rec[8] == 0xFF:
        return
    period, stp = rec[8] >> 4, rec[8] & 15
    c = rec[9]
    if c & 0x80:
        c = (c & 0x7F) - 1
        rec[9] = c | 0x80 if c else c
        rec[0] -= stp
    else:
        c += 1
        rec[9] = c | 0x80 if c == period else c
        rec[0] += stp


def anim_bytes(name, addr):
    blocks, _ = RF.trail_parse(name, RF.load(name))
    base = RF.TRAILS[name][0]
    for blk in blocks:
        if blk[0] == 'anim' and blk[1] == addr:
            return list(blk[2]) + [0xFF] * 8
    raise SystemExit(f'no anim ${addr:04X} in {name}')


def cmd_fig_motion(path):
    from PIL import Image, ImageDraw
    picks = [('trails/trails14.bin', 0x8070, 'Anim8070: trail 3, sprite $BD, drawn (ground)'),
             ('trails/trails14.bin', 0x8065, 'Anim8065: trail 3, sprite $BD, drawn (ground)'),
             ('trails/trails14.bin', 0x804A, 'Anim804A: trail 3, sprite $BC, DeferredB (behind)'),
             ('trails/trail5.bin', 0xEFE5, 'AnimEFE5: trail 5, sprite $71, drawn (ground)'),
             ('trails/trail5.bin', 0xEFC6, 'AnimEFC6: trail 5, sprite $68, drawn (ground)'),
             ('trails/trail6.bin', 0x6225, 'Anim6225: trail 6, sprite $74, drawn (ground)')]
    N = 80
    W, rowh = 1050, 120
    im = Image.new('RGB', (W, 60 + rowh * len(picks) + 30), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), f'The animation records\' motions, run as AnimObject steps them: {N} passes from the image\'s '
                    'bytes (one step a pass while the item is walked)', fill='black', font=fb)
    d.text((10, 30), 'red: the distance offset (px), blue: the y offset (px), green: the sprite number offset; '
                     'the axis is passes', fill='black', font=f)
    X1, X2 = 400, 1030
    for k, (name, addr, title) in enumerate(picks):
        rec = anim_bytes(name, addr)
        raw = ' '.join(f'{b:02X}' for b in rec[:rec.index(0xFF, 3)])
        item = {'dist': 0, 'y': 0}
        s0 = rec[0]
        xs, ys, fr = [0], [0], [0]
        for _ in range(N):
            step(rec, item)
            xs.append(item['dist'])
            ys.append(item['y'])
            fr.append(rec[0] - s0)
        y0 = 60 + k * rowh
        d.text((10, y0 + 4), title, fill='black', font=f)
        d.text((10, y0 + 24), f'bytes: {raw}', fill=(60, 60, 60), font=fs)
        d.text((10, y0 + 42), f'distance {min(xs)}..{max(xs)}, y {min(ys)}..{max(ys)}, frame {min(fr)}..{max(fr)}',
               fill=(60, 60, 60), font=fs)
        lo, hi = min(xs + ys + fr), max(xs + ys + fr)
        span = max(1, hi - lo)
        top, bot = y0 + 6, y0 + rowh - 18

        def yv(v):
            return bot - (v - lo) * (bot - top) / span
        d.rectangle((X1, top, X2, bot), outline=(200, 200, 200))
        d.line((X1, yv(0), X2, yv(0)), fill=(210, 210, 210))
        d.text((X1 - 30, top - 2), str(hi), fill='black', font=fs)
        d.text((X1 - 30, bot - 12), str(lo), fill='black', font=fs)
        for series, col in ((fr, (30, 150, 30)), (ys, (40, 80, 220)), (xs, (220, 40, 40))):
            pts = [(X1 + i * (X2 - X1) / N, yv(v)) for i, v in enumerate(series)]
            d.line(pts, fill=col, width=2)
        if k == len(picks) - 1:
            for p in range(0, N + 1, 10):
                d.text((X1 + p * (X2 - X1) / N - 6, bot + 2), str(p), fill='black', font=fs)
    im.save(path)


# ---- the two scrolls ----------------------------------------------------------------------------------------------

def cmd_fig_scroll(vars_path, path):
    from PIL import Image, ImageDraw
    pts = []
    for line in open(vars_path):
        r = json.loads(line)
        if r['f'] % 7:
            continue
        b = bytes.fromhex(r['D70E'])
        trail = bytes.fromhex(r['D6B6'])[0xD6BF - 0xD6B6]
        tp, sp, spd = b[24] | b[25] << 8, b[29] | b[30] << 8, b[9]
        pts.append((r['f'], tp, sp, spd, trail))
    pts = [p for p in pts if 280 <= p[0] <= 1800]
    W, H = 1050, 520
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    fb, f, fs = font(16), font(14), font(13)
    d.text((10, 8), 'Trail 1 in the trails recording: the two scrolls and the speed, sampled every 7th frame '
                    '(RecordP1 at the start of the frame)', fill='black', font=fb)
    X1, X2, T, B = 70, 1020, 50, 330
    f0, f1 = pts[0][0], pts[-1][0]

    def xv(fr):
        return X1 + (fr - f0) * (X2 - X1) / (f1 - f0)

    def yv(v):
        return B - v * (B - T) / 1700
    d.rectangle((X1, T, X2, B), outline=(180, 180, 180))
    for v in range(0, 1701, 200):
        d.text((20, yv(v) - 7), str(v), fill='black', font=fs)
        d.line((X1, yv(v), X2, yv(v)), fill=(235, 235, 235))
    d.line([(xv(p[0]), yv(p[1])) for p in pts], fill=(220, 40, 40), width=2)
    d.line([(xv(p[0]), yv(p[2])) for p in pts], fill=(30, 120, 30), width=2)
    d.line([(xv(p[0]), yv(p[2] * 4)) for p in pts], fill=(30, 120, 30), width=1)
    fin = 0x690 - 0x48
    d.line((X1, yv(fin), X2, yv(fin)), fill=(0, 0, 0))
    d.text((X1 + 6, yv(fin) - 16), f'FinishDistance {fin}', fill='black', font=fs)
    d.text((X1 + 6, T + 22), 'red: TrackPos (list A\'s scroll, px); dark green: SceneryPos (list B\'s); '
                              'thin green: SceneryPos x 4', fill='black', font=f)
    T2, B2 = 360, 480
    d.rectangle((X1, T2, X2, B2), outline=(180, 180, 180))
    for v in (0, 7, 14, 21):
        yy = B2 - v * (B2 - T2) / 21
        d.text((30, yy - 7), str(v), fill='black', font=fs)
        d.line((X1, yy, X2, yy), fill=(235, 235, 235))
    d.line([(xv(p[0]), B2 - p[3] * (B2 - T2) / 21) for p in pts], fill=(40, 80, 220), width=2)
    d.text((X1 + 6, T2 + 4), 'blue: Speed (0-21); a pass moves TrackPos by Speed / 2 px and SceneryPos by Speed / 8',
           fill='black', font=f)
    for fr in range((f0 // 100 + 1) * 100, f1 + 1, 100):
        d.text((xv(fr) - 12, B2 + 6), str(fr), fill='black', font=fs)
    d.text((X2 - 60, B2 + 22), 'frame', fill='black', font=fs)
    im.save(path)


def main():
    a = sys.argv[1:]
    scroll = None
    if '--scroll' in a:
        i = a.index('--scroll')
        scroll = tuple(int(v) for v in a[i + 1].split(','))
        del a[i:i + 2]
    if not a:
        sys.exit(__doc__)
    cmd = a[0]
    if cmd == 'fig-stretch':
        cmd_fig_stretch(a[1], a[2], a[3], scroll)
    else:
        {'fig-sheets': cmd_fig_sheets, 'fig-record': cmd_fig_record, 'fig-motion': cmd_fig_motion,
         'fig-scroll': cmd_fig_scroll}[cmd](*a[1:])


if __name__ == '__main__':
    main()
