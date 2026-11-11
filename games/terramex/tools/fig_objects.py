#!/usr/bin/env python3
"""The figures of doc 07 (the rooms, creatures, items and variables), from src/res, the built image and samples.

    python3 tools/fig_objects.py docs/img/objects

Writes into the folder:
- room-31.png: room $31 decoded: the picture, its back-tile grid, its three creature records and its item record;
- creature-record.png: one 4-byte RoomCreatures record unpacked into the 10 bytes of CreatureRecords;
- creature-types.png: the eight creature types, their sprite frames, counts and rooms;
- item-places.png: where the 31 ItemPlaces records put the items on the map, and one record decoded;
- run-course.png: the RZX run's room, score, lives, held item and gifts from work/stage1/rzx/vars.bin
  ($5B00-$5CFF every 250 RZX frames).
"""
import os
import sys
from collections import Counter

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_rooms as FR  # noqa: E402

BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
W = 1050
YEL, CYAN, GREEN, RED, ORANGE, BLUE, PINK = ((255, 220, 90), (90, 210, 230), (120, 220, 120), (240, 110, 100),
                                            (250, 170, 70), (120, 160, 255), (230, 130, 220))
TYPES = ['none', 'walker', 'climber', 'leftflier', 'rightflier', 'drop', 'still', 'riser', 'scenery']
HANDLERS = ['NoCreature $BEDC', 'WalkerCreature $BEDD', 'ClimberCreature $BF22', 'LeftFlier $BF67',
            'RightFlier $BFBB', 'DropCreature $BFF6', 'StillCreature $C054', 'RiserCreature $C069',
            'PlaceCreature $C135']
ITEMS = ['Unicycle', 'Flashgun', 'Cricket Ball', 'Spurs', 'Beer Barrel', 'Umbrella', 'Bellows', 'Party Manifesto',
         'Cannon', 'Barrel Medium', 'Vacuum Cleaner', 'ACME Bridge', 'Flute', 'Silver Lining', 'Spring', 'Formula',
         'Switch', 'Button', 'Battery', 'Coat Hanger', 'Trampoline', 'Atomic Pile', 'Anti Rad. Pills', 'Cup of tea',
         'Energy Crystal', 'Basket', 'Balloon', 'Barrel Big', 'Barrel Small', 'Silver Cross', 'Basket 2', 'Lift']
IMG = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
ORG = 0x7200


def mem(a, n):
    return IMG[a - ORG:a - ORG + n]


def sprite_img(sheet, frame, scale=2, ink=(255, 255, 255), paper=None):
    d = sheet[frame * 72:frame * 72 + 72]
    im = Image.new('RGBA', (24, 24), paper + (255,) if paper else (0, 0, 0, 0))
    px = im.load()
    for x in range(24):
        for y in range(24):
            if d[(x // 8) * 24 + y] & (0x80 >> (x % 8)):
                px[x, y] = ink + (255,)
    return im.resize((24 * scale, 24 * scale), Image.NEAREST)


def title(d, text, sub=None):
    d.text((12, 8), text, font=K.font(22), fill=(240, 240, 240))
    if sub:
        d.text((12, 38), sub, font=K.font(16), fill=(170, 170, 180))


def cell(d, x, y, w, h, text, fill=PANEL, ink=TEXT, size=16, outline=(70, 70, 85)):
    d.rectangle((x, y, x + w, y + h), fill=fill, outline=outline)
    f = K.font(size)
    tw = d.textlength(text, font=f)
    d.text((x + (w - tw) / 2, y + (h - size) / 2 - 1), text, font=f, fill=ink)


def creature_fields(rec):
    b0, b1, b2, b3 = rec
    return dict(type=b0 & 15, hit=b0 >> 7, hitframe=(b0 >> 4) & 7, frame=b1, x=b2, y=b3 & 0x7F, dir=b3 >> 7)


def room_31(r, out):
    room = 0x31
    o = Image.new('RGB', (W, 640), BG)
    d = ImageDraw.Draw(o)
    title(d, 'Room $31 decoded: everything the game keeps for one room',
          'From src/res and the built image: the grid, the creature records, the item record, the per-room tables')
    pic = FR.room_image(r, room).resize((512, 256), Image.NEAREST)
    o.paste(pic, (12, 70))
    recs = [mem(0xC152 + 12 * room + 4 * k, 4) for k in range(3)]
    cols = [CYAN, ORANGE, PINK]
    f16, f14 = K.font(16), K.font(14)
    for k, rec in enumerate(recs):
        c = creature_fields(rec)
        x, y = 12 + c['x'] * 2, 70 + c['y'] * 2
        d.rectangle((x, y, x + 48, y + 48), outline=cols[k], width=2)
        lx = x - 92 if k == 2 else x + 2
        d.text((lx, y - 18 if k != 2 else y + 4), f'creature {k}', font=f14, fill=cols[k])
    rec_addr = 0xB99D + 3 * 21
    it = mem(rec_addr, 3)
    ix, iy = (it[2] & 3) * 64 + (it[1] & 0xE0) // 4, (it[2] & 0xFC) * 2
    d.rectangle((12 + ix * 2 - 2, 70 + iy * 2 - 2, 12 + ix * 2 + 50, 70 + iy * 2 + 50), outline=YEL, width=2)
    d.text((12 + ix * 2 + 56, 70 + iy * 2 + 4), 'item 21', font=f14, fill=YEL)
    # the grid
    gy = 340
    d.text((12, gy), 'RoomGrids $D600 + 32 x $31 = $DC20: 8 x 4 back-tiles', font=f16, fill=TEXT)
    grid = mem(0xD600 + 32 * room, 32)
    for b in range(32):
        cell(d, 12 + (b % 8) * 64, gy + 24 + (b // 8) * 30, 62, 28, f'${grid[b]:02X}', size=16)
    d.text((12, gy + 150), 'A back-tile is 4 x 4 tiles (BackTiles $C600 + 16 x index):', font=f14, fill=DIM)
    d.text((12, gy + 168), '32 x 16 tiles, 256 x 128 pixels: the play window.', font=f14, fill=DIM)
    # the creature records
    x0 = 540
    d.text((x0, 70), 'RoomCreatures $C152 + 12 x $31 = $C3A6', font=f16, fill=TEXT)
    for k, rec in enumerate(recs):
        for j in range(4):
            cell(d, x0 + 40 + j * 54, 96 + k * 32, 52, 28, f'{rec[j]:02X}', ink=cols[k], size=17)
        d.text((x0, 100 + k * 32), f'#{k}', font=f16, fill=cols[k])
        d.text((x0 + 266, 100 + k * 32), f'${0xC3A6 + 4 * k:04X}', font=f14, fill=DIM)
    hy = 200
    heads = ['#', 'type', 'frame', 'X', 'Y', 'dir', 'hit', 'hitframe']
    ws = [26, 124, 58, 46, 46, 40, 36, 70]
    xx = x0
    for h_, w_ in zip(heads, ws):
        d.text((xx, hy), h_, font=f14, fill=DIM)
        xx += w_
    for k, rec in enumerate(recs):
        c = creature_fields(rec)
        vals = [str(k), f'{c["type"]} {TYPES[c["type"]]}', f'${c["frame"]:02X}', f'${c["x"]:02X}', f'${c["y"]:02X}',
                str(c['dir']), str(c['hit']), str(c['hitframe'])]
        xx = x0
        for v, w_ in zip(vals, ws):
            d.text((xx, hy + 22 + k * 24), v, font=f14, fill=cols[k])
            xx += w_
    iy0 = 310
    d.text((x0, iy0), f'ItemPlaces record 21 at ${rec_addr:04X}: {it[0]:02X} {it[1]:02X} {it[2]:02X}', font=f16,
           fill=YEL)
    d.text((x0, iy0 + 24), f'room ${it[0] & 0x7F:02X}, taken {it[0] >> 7}, item {it[1] & 31} '
           f'({ITEMS[it[1] & 31]}),', font=f14, fill=YEL)
    d.text((x0, iy0 + 42), f'X ${ix:02X}, Y ${iy:02X}', font=f14, fill=YEL)
    ty = 386
    d.text((x0, ty), 'The per-room tables, indexed by the room number', font=f16, fill=TEXT)
    script = mem(0xB7EC + 2 * room, 2)
    hints = mem(0xA6E6, 72)
    rows = [
        ('RoomScripts $B7EC + 2 x R', f'word ${script[1]:02X}{script[0]:02X}: no script'),
        ('ThinkHints $A6E6 + R', f'${hints[room]:02X}: no idea'),
        ('CheckpointRooms $9AF5', 'listed: saves the respawn' if room in mem(0x9AF5, 45) else 'not listed'),
        ('AltTilesetRooms $9AC6', 'listed' if room in mem(0x9AC6, 15) else 'not listed: normal tiles'),
        ('ItemPlaces $B99D (31 x 3)', 'one record: 21'),
        ('level, column', f'{room // 12}, {room % 12}'),
    ]
    for i, (a, b) in enumerate(rows):
        d.text((x0, ty + 26 + i * 24), a, font=f14, fill=DIM)
        d.text((x0 + 250, ty + 26 + i * 24), b, font=f14, fill=TEXT)
    d.text((12, 600), 'Cyan, orange, pink: creatures 0, 1, 2 at their start places (their first frame); yellow: the item.',
           font=f14, fill=DIM)
    d.text((12, 618), 'python3 tools/fig_objects.py docs/img/objects', font=f14, fill=DIM)
    o.save(os.path.join(out, 'room-31.png'))


def creature_record(out):
    rec = mem(0xC152 + 12 * 0x31, 4)
    o = Image.new('RGB', (W, 520), BG)
    d = ImageDraw.Draw(o)
    title(d, 'One creature record, packed and unpacked: room $31, creature 0 (the drop)',
          'RoomCreatures $C3A6 (4 bytes) -> DecodeRoomCreatures $BE42 -> CreatureRecords $BE24 (10 bytes)')
    f14, f16 = K.font(14), K.font(16)
    fields = {0: [(7, 7, 'hit', RED), (6, 4, 'hitframe', ORANGE), (3, 0, 'type', CYAN)],
              1: [(7, 0, 'first frame', GREEN)], 2: [(7, 0, 'X', BLUE)],
              3: [(7, 7, 'dir', PINK), (6, 0, 'Y', YEL)]}
    bw = 30
    for j in range(4):
        bx = 20 + j * 256
        d.text((bx, 70), f'byte {j}  ${0xC3A6 + j:04X} = ${rec[j]:02X}', font=f16, fill=TEXT)
        for hi, lo, name, col in fields[j]:
            x1 = bx + (7 - hi) * bw
            x2 = bx + (8 - lo) * bw - 2
            d.rectangle((x1, 96, x2, 150), fill=tuple(c // 4 for c in col), outline=col)
            for bit in range(lo, hi + 1):
                bxx = bx + (7 - bit) * bw
                d.text((bxx + 10, 100), str((rec[j] >> bit) & 1), font=K.font(18), fill=(240, 240, 240))
            d.text((x1 + 3, 128), name, font=f14, fill=col)
    out_bytes = [rec[0] & 15, rec[0] & 15, rec[0] & 0x80, (rec[0] >> 4) & 7, rec[1], rec[2], rec[3] & 0x7F,
                 rec[3] & 0x80, 0, 0]
    names = ['+0 type', '+1 type', '+2 hit', '+3 hitframe', '+4 frame', '+5 X', '+6 Y', '+7 counter', '+8 timer',
             '+9 unused']
    cols = [CYAN, CYAN, RED, ORANGE, GREEN, BLUE, YEL, PINK, DIM, DIM]
    exprs = ['b0 & $0F', 'b0 & $0F', 'b0 & $80', 'b0>>4 & 7', 'b1', 'b2', 'b3 & $7F', 'b3 & $80', '0', '0']
    srcx = [20 + 5 * 30 + 60, 20 + 5 * 30 + 60, 20 + 15, 20 + 60, 276 + 120, 532 + 120, 788 + 30 + 105, 788 + 15,
            None, None]
    y2 = 250
    live = bytes.fromhex('050580045c90180b0100')
    for i in range(10):
        x = 20 + i * 101
        cell(d, x, y2, 97, 34, f'{out_bytes[i]:02X}', ink=cols[i], size=19)
        d.text((x + 2, y2 + 40), names[i], font=f14, fill=cols[i])
        d.text((x + 2, y2 + 58), exprs[i], font=f14, fill=DIM)
        cell(d, x, y2 + 120, 97, 30, f'{live[i]:02X}', ink=cols[i], size=17)
        if srcx[i] is not None:
            d.line((srcx[i], 152, x + 48, y2 - 4), fill=tuple(c * 2 // 3 for c in cols[i]), width=2)
    d.text((20, y2 + 84), 'Row 1: CreatureRecords $BE24 + 10 x k (k = 0), as DecodeRoomCreatures writes it on every '
           'room entry (+7 to +9 zero).', font=f14, fill=TEXT)
    d.text((20, y2 + 160), 'Row 2: the same record live, rzx24750 frame 0 (memory_at: the state at the frame\'s '
           'start): the counter +7 = $0B,', font=f14, fill=TEXT)
    d.text((20, y2 + 180), 'the timer +8 = 1: the drop is falling and acts every pass (CreatureTimer $BFA0 holds '
           'the timer at 1).', font=f14, fill=TEXT)
    d.text((20, y2 + 206), '+7 steps the animation (bits 0-2) and keeps the direction (bit 7); +8 is the placed / '
           'wait timer.', font=f14, fill=DIM)
    d.text((20, y2 + 236), 'python3 tools/fig_objects.py docs/img/objects', font=f14, fill=DIM)
    o.save(os.path.join(out, 'creature-record.png'))


def creature_types(r, out):
    table = r['rooms/table.bin']
    sheet = r['sprites/creatures.bin']
    per = {t: [] for t in range(9)}
    for room in range(72):
        for k in range(3):
            rec = table[room * 12 + 4 * k:room * 12 + 4 * k + 4]
            if rec[0] & 15:
                per[rec[0] & 15].append((room, rec))
    rowh = 72
    o = Image.new('RGB', (W, 92 + 8 * rowh + 30), BG)
    d = ImageDraw.Draw(o)
    title(d, 'The eight creature types: handler, sprite frames, count and rooms',
          'From src/res/rooms/rooms.txt (RoomCreatures $C152) and src/res/sprites/creatures.png')
    f14, f16 = K.font(14), K.font(16)
    moves = {1: 'X +-2 a pass, turns at walls, X 0 or $E6', 2: 'Y +-2 a pass, turns at floors, Y 0 or $66',
             3: 'random wait unseen, then X -2 a pass across', 4: 'random wait unseen, then X +2 a pass across',
             5: 'random wait, falls 2 px a pass, splash, sound 5', 6: 'animates in place (the snakes stop it)',
             7: '16-step rise and sink, random pause', 8: 'placed every pass: never moves'}
    for t in range(1, 9):
        y = 80 + (t - 1) * rowh
        if t % 2:
            d.rectangle((0, y - 4, W, y + rowh - 6), fill=(20, 20, 28))
        lst = per[t]
        frames = Counter(rec[1] for _, rec in lst)
        f0 = frames.most_common(1)[0][0]
        d.text((10, y + 2), f'{t} {TYPES[t]}', font=K.font(18), fill=YEL)
        d.text((10, y + 26), HANDLERS[t], font=f14, fill=DIM)
        d.text((10, y + 44), f'{len(lst)} records', font=f14, fill=TEXT)
        n = 1 if t == 8 else 4
        for i in range(n):
            o.paste(sprite_img(sheet, f0 - 0x40 + i), (200 + i * 54, y + 6), sprite_img(sheet, f0 - 0x40 + i))
        d.text((200, y + 54 - 2), f'${f0:02X}' + ('' if n == 1 else f'-${f0 + 3:02X}'), font=f14, fill=DIM)
        d.text((420, y + 4), moves[t], font=f16, fill=TEXT)
        rooms = sorted({room for room, _ in lst})
        txt = ' '.join(f'${x:02X}' for x in rooms)
        if len(txt) > 64:
            txt = txt[:64].rsplit(' ', 1)[0] + ' ...'
        d.text((420, y + 28), 'rooms ' + txt, font=f14, fill=DIM)
        others = [f'${f:02X}' for f, _ in frames.most_common() if f != f0]
        if others:
            d.text((420, y + 46), 'other first frames: ' + ' '.join(others[:10]), font=f14, fill=DIM)
    d.text((10, 92 + 8 * rowh + 4), 'python3 tools/fig_objects.py docs/img/objects', font=f14, fill=DIM)
    o.save(os.path.join(out, 'creature-types.png'))


def item_places(r, out):
    places = r['tables/item-places.bin']
    isheet = r['sprites/items.bin']
    cw, ch = 86, 64
    o = Image.new('RGB', (W, 120 + 6 * (ch + 4) + 190), BG)
    d = ImageDraw.Draw(o)
    title(d, 'ItemPlaces $B99D: where the 31 records put the items at the start of a game',
          'Room R = 12 x level + column, each item drawn in its room with its record number; red: taken at the start')
    f14 = K.font(14)
    per = {}
    for i in range(31):
        b0, b1, b2 = places[3 * i:3 * i + 3]
        per.setdefault(b0 & 0x7F, []).append((i, b1 & 31, i == 20))
    for room in range(72):
        lv, col = divmod(room, 12)
        x, y = 12 + col * cw, 74 + lv * (ch + 4)
        th = FR.room_image(r, room).resize((cw - 2, ch - 2), Image.LANCZOS)
        th = Image.blend(th, Image.new('RGB', th.size, (0, 0, 0)), 0.65)
        o.paste(th, (x, y))
        d.text((x + 2, y), f'{room:02X}', font=f14, fill=(200, 200, 200))
        for j, (i, item, taken) in enumerate(per.get(room, [])):
            col_ = (240, 110, 100) if taken else (255, 230, 0)
            sp = sprite_img(isheet, item, scale=1, ink=col_)
            o.paste(sp, (x + 28 + j * 28, y + 16), sp)
            d.text((x + 28 + j * 28, y + 42), str(i), font=f14, fill=col_)
    y0 = 74 + 6 * (ch + 4) + 10
    rec = places[45:48]
    d.text((12, y0), f'Record 15 at $B9CA: {rec[0]:02X} {rec[1]:02X} {rec[2]:02X} (room $21, Barrel Small)',
           font=K.font(16), fill=TEXT)
    fields = [(0, [(7, 7, 't', RED), (6, 0, 'room', CYAN)]),
              (1, [(7, 5, 'X bits 5-3', BLUE), (4, 0, 'item', GREEN)]),
              (2, [(7, 2, 'Y / 8', YEL), (1, 0, 'X 7-6', BLUE)])]
    bw = 30
    for j, fl in fields:
        bx = 12 + j * 260
        for hi, lo, name, col in fl:
            x1, x2 = bx + (7 - hi) * bw, bx + (8 - lo) * bw - 2
            d.rectangle((x1, y0 + 28, x2, y0 + 84), fill=tuple(c // 4 for c in col), outline=col)
            for bit in range(lo, hi + 1):
                d.text((bx + (7 - bit) * bw + 10, y0 + 32), str((rec[j] >> bit) & 1), font=K.font(18),
                       fill=(240, 240, 240))
            d.text((x1 + 3, y0 + 62), name, font=f14, fill=col)
    x = (rec[2] & 3) * 64 + (rec[1] & 0xE0) // 4
    y = (rec[2] & 0xFC) * 2
    d.text((800, y0 + 30), f'item = ${rec[1]:02X} & $1F = {rec[1] & 31}', font=f14, fill=GREEN)
    d.text((800, y0 + 50), f'X = {rec[2] & 3} x 64 + ${rec[1] & 0xE0:02X} / 4 = ${x:02X}', font=f14, fill=BLUE)
    d.text((800, y0 + 70), f'Y = (${rec[2]:02X} & $FC) x 2 = ${y:02X}', font=f14, fill=YEL)
    d.text((12, y0 + 100), 'PlaceItem $B95F decodes a record into an item slot. PickUpItem $BB6C sets bit 7 of byte 0 '
           'when the item is taken:', font=f14, fill=DIM)
    d.text((12, y0 + 120), 'the record then matches no room. ResetItems $B932 clears every bit 7 at a new game; '
           'GameInit sets record 20\'s again.', font=f14, fill=DIM)
    d.text((12, y0 + 150), 'python3 tools/fig_objects.py docs/img/objects', font=f14, fill=DIM)
    o.save(os.path.join(out, 'item-places.png'))


def run_course(out):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    raw = open(os.path.join(CASE, 'work', 'stage1', 'rzx', 'vars.bin'), 'rb').read()
    n = len(raw) // 512
    idx = range(1, n)  # sample 0 is before play
    fr = [250 * i for i in idx]
    g = lambda i, a: raw[512 * i + a - 0x5B00]  # noqa: E731
    room = [g(i, 0x5C01) for i in idx]
    lives = [g(i, 0x5B97) for i in idx]
    held = [g(i, 0x5B98) for i in idx]
    gifts = [g(i, 0x5C3D) for i in idx]
    score = [int.from_bytes(raw[512 * i + 0x118:512 * i + 0x11C], 'little') for i in idx]
    loads = [sum(1 for b in raw[512 * i + 0x7C:512 * i + 0x97] if b != 0xFF) for i in idx]
    plt.rcParams.update({'font.size': 11, 'axes.facecolor': '#16161e', 'figure.facecolor': '#0e0e14',
                         'text.color': '#d2d2dc', 'axes.labelcolor': '#d2d2dc', 'xtick.color': '#d2d2dc',
                         'ytick.color': '#d2d2dc', 'axes.edgecolor': '#555566'})
    fig, ax = plt.subplots(5, 1, figsize=(10.5, 11), dpi=100, sharex=True,
                           gridspec_kw={'height_ratios': [2.2, 1, 0.7, 3.4, 0.9]})
    fig.suptitle('The RZX run, sampled every 250 RZX frames (work/stage1/rzx/vars.bin: \\$5B00-\\$5CFF '
                 'at the frame\'s start)', fontsize=13)
    ax[0].scatter(fr, room, s=9, c='#5ad2e6')
    ax[0].set_ylabel('Room \\$5C01')
    ax[0].set_yticks(range(0, 72, 12))
    ax[0].set_yticklabels([f'\\${v:02X}' for v in range(0, 72, 12)])
    ax[1].plot(fr, score, c='#ffdc5a', drawstyle='steps-post')
    ax[1].set_ylabel('Score \\$5C18')
    ax[2].plot(fr, lives, c='#f06e64', drawstyle='steps-post')
    ax[2].set_ylabel('Lives \\$5B97')
    ax[2].set_ylim(0, 5)
    hx = [f for f, h in zip(fr, held) if h != 0xFF]
    hy = [h for h in held if h != 0xFF]
    ax[3].scatter(hx, hy, s=9, c='#78dc78')
    ax[3].set_ylabel('HeldItem \\$5B98')
    used = sorted(set(hy))
    ax[3].set_yticks(used)
    ax[3].set_yticklabels([f'{u} {ITEMS[u]}' for u in used], fontsize=10)
    ax[4].plot(fr, gifts, c='#e682dc', drawstyle='steps-post', label='GiftCount \\$5C3D')
    ax[4].plot(fr, loads, c='#78a0ff', drawstyle='steps-post', label='bearers loaded')
    ax[4].legend(loc='upper left', fontsize=9, facecolor='#16161e', edgecolor='#555566')
    ax[4].set_xlabel('RZX frame')
    for a in ax:
        a.grid(alpha=0.2)
    fig.tight_layout()
    fig.savefig(os.path.join(out, 'run-course.png'))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CASE, 'docs', 'img', 'objects')
    os.makedirs(out, exist_ok=True)
    r = FR.resources()
    room_31(r, out)
    creature_record(out)
    creature_types(r, out)
    item_places(r, out)
    run_course(out)


if __name__ == '__main__':
    main()
