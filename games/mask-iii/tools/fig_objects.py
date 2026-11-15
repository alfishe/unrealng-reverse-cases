#!/usr/bin/env python3
"""MASK III's rooms, objects and rules as figures, for docs 7 and 10 (from the case's build and src/res, and from the
per-frame samples of work/docs/mxC/<recording>/vars.jsonl that work/docs/mxC/sample.py made).

    python3 tools/fig_objects.py room-decode OUT.png   room 0, screen 0: its RoomTable record, the 8 x 5 blocks over the
                                                       picture, one block taken apart, the two pick-ups
    python3 tools/fig_objects.py world OUT.png         the 16 rooms x 6 screens: enemy kind, pick-ups, exits, zone
    python3 tools/fig_objects.py record OUT.png        the 8 object records of rzx-00000 TTD frame 990, byte by byte
    python3 tools/fig_objects.py templates OUT.png     EnemyTemplates $BE3B: the 20 records with their pictures
    python3 tools/fig_objects.py jump OUT.png          Matt's jump: the model per pass (earth, moon) and rzx-00000
    python3 tools/fig_objects.py run OUT.png           the RZX run: energy, score, Matt's state, per segment
    python3 tools/fig_objects.py masks OUT.png         the ten masks: icon, level, colour, cost, where they lie
    python3 tools/fig_objects.py charges OUT.png       four masks at work: the slot's charges and what the mask moves
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib  # noqa: E402
import roommap  # noqa: E402

SAMPLES = os.path.join(CASE, 'work', 'docs', 'mxC')
SPRITES = os.path.join(CASE, 'src', 'res', 'sprites')
KIND_NAMES = {0: 'none', 1: 'flyer (2)', 2: 'faller (1)', 3: 'wave (6)', 4: 'walker (7)', 5: 'chaser (8)',
              6: 'kind 16', 7: 'riser (12)', 8: 'guard (13)', 9: 'boss (14)', 10: 'group 18/19'}
KIND_COLOURS = {0: '#f0f0f0', 1: '#c6dbef', 2: '#fdd0a2', 3: '#c7e9c0', 4: '#dadaeb', 5: '#fcbba1', 6: '#fff7bc',
                7: '#d9f0a3', 8: '#bcbddc', 9: '#fb6a4a', 10: '#fee391'}
MASKS = ['EMPTY', 'PENETRATOR', 'ULTRA FLASH', 'MIRAGE', 'HEALER', 'JACKRABBIT', 'LIFTER', 'BLASTER', 'BACKLASH',
         'LAVA SHOT', 'STREAMER']


def game():
    """the 64K as the build has it: build/game.bin at $6000"""
    mem = bytearray(65536)
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[0x6000:0x6000 + len(data)] = data
    return mem


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'axes.labelsize': 11, 'legend.fontsize': 10,
                         'xtick.labelsize': 10, 'ytick.labelsize': 10})
    return plt


def samples(rec):
    out = []
    for line in open(os.path.join(SAMPLES, rec, 'vars.jsonl')):
        r = json.loads(line)
        if len(r['obj']) == 608:
            r['o'] = bytes.fromhex(r['obj'])
            out.append(r)
    return out


def pickups(mem):
    out, a = [], 0x950E
    while mem[a] != 0xFF:
        out.append((mem[a] & 0x7F, mem[a + 1], mem[a + 2], mem[a + 3]))
        a += 4
    return out


def sprite_frame(name, w, h, frame=0, scale=1, ink=(255, 255, 255), paper=None):
    im = Image.open(os.path.join(SPRITES, name)).convert('L')
    fr = im.crop((frame * w * 8, 0, (frame + 1) * w * 8, h * 8))
    rgba = Image.new('RGBA', fr.size, paper + (255,) if paper else (0, 0, 0, 0))
    px, src = rgba.load(), fr.load()
    for y in range(fr.size[1]):
        for x in range(fr.size[0]):
            if src[x, y] > 127:
                px[x, y] = ink + (255,)
    return rgba.resize((fr.size[0] * scale, fr.size[1] * scale), Image.NEAREST)


def cmd_room_decode(out):
    mem = game()
    res = roommap.res_memory(0)
    room, screen = 0, 0
    rec = mem[0x953B:0x953B + 12]
    W, H = 1050, 780
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    big, mid, small = kitlib.font(20), kitlib.font(16), kitlib.font(14)
    d.text((16, 10), 'Room 0, screen 0 from its data: the record, the map blocks, one block, the pick-ups',
           fill=kitlib.TEXT, font=big)
    # the record
    names = ['left', 'right', 'pod', 'exit3', 'zone', 'arrive', 's0', 's1', 's2', 's3', 's4', 's5']
    d.text((16, 44), 'RoomTable $953B:', fill=kitlib.TEXT, font=mid)
    d.text((646, 88), 'enemy kind of screens 0-5', fill=kitlib.DIM, font=small)
    for i, (b, n) in enumerate(zip(rec, names)):
        x = 190 + i * 70
        col = (60, 40, 40) if i < 4 else (40, 60, 40) if i < 6 else (40, 40, 70)
        d.rectangle((x, 40, x + 62, 66), fill=col, outline=kitlib.DIM)
        d.text((x + 20, 44), '%02X' % b, fill=(255, 255, 255), font=mid)
        d.text((x + 2, 70), n, fill=kitlib.DIM, font=small)
    # the screen, 3x, with the block grid; draw_screen crops the top 16 pixel rows (character rows 0-1)
    scale = 3
    pic = roommap.draw_screen(res, room, screen, scale)
    pic = pic.convert('RGBA')
    icons = Image.open(os.path.join(SPRITES, 'mask-icons.png')).convert('L')
    for r, kind, x, y in pickups(mem):
        if r == room and x // 32 == screen:
            ic = sprite_frame('mask-icons.png', 2, 2, kind, scale, ink=(255, 255, 0))
            pic.alpha_composite(ic, ((x - 32 * screen) * 8 * scale, y * 8 * scale))
    del icons
    px0, py0 = 16, 110
    im.paste(pic.convert('RGB'), (px0, py0))
    base = 0x7600 + 240 * room + 8 * screen
    for by in range(5):
        for bx in range(8):
            blk = res[base + by * 48 + bx]
            x0 = px0 + bx * 32 * scale
            y0 = py0 + (by * 32 - 16) * scale
            top = max(y0, py0)
            d.rectangle((x0, top, x0 + 32 * scale - 1, y0 + 32 * scale - 1), outline=(255, 80, 80))
            d.text((x0 + 4, top + 2), '%02X' % blk, fill=(255, 120, 120), font=mid)
    d.text((px0, py0 + 144 * scale + 6),
           'Red: the block number in the map, 8 across x 5 rows of 4 x 4 characters; row 0\'s top half is hidden.', fill=kitlib.DIM, font=small)
    labs = ['%s at x $%02X, y $%02X' % (MASKS[kind], x, y) for r, kind, x, y in pickups(mem)
            if r == room and x // 32 == screen]
    d.text((px0, py0 + 144 * scale + 26), 'Yellow: the pick-ups of PickupTable $950E drawn by PlacePickup: '
           + '; '.join(labs), fill=(255, 255, 0), font=small)
    # one block taken apart
    blk = 0x06
    bx0, by0 = 800, 110
    d.text((bx0, by0), 'Block $%02X (row 1, col 7)' % blk, fill=kitlib.TEXT, font=mid)
    d.text((bx0, by0 + 22), '$8500 + 16 x $%02X = $%04X' % (blk, 0x8500 + 16 * blk), fill=kitlib.DIM, font=small)
    for cy in range(4):
        for cx in range(4):
            ch = res[0x8500 + 16 * blk + cy * 4 + cx]
            d.text((bx0 + cx * 52, by0 + 48 + cy * 22), '%02X' % ch, fill=(255, 255, 255), font=mid)
    one = Image.new('RGB', (32, 32))
    p1 = one.load()
    for cy in range(4):
        for cx in range(4):
            ch = res[0x8500 + 16 * blk + cy * 4 + cx]
            attr = res[0xEF00 + ch]
            br = bool(attr & 0x40)
            ink, paper = roommap.colour(attr & 7, br), roommap.colour((attr >> 3) & 7, br)
            for yy in range(8):
                b = res[0xE000 + 8 * ch + yy]
                for xx in range(8):
                    p1[cx * 8 + xx, cy * 8 + yy] = ink if b & (0x80 >> xx) else paper
    im.paste(one.resize((192, 192), Image.NEAREST), (bx0, by0 + 150))
    for k in range(5):
        d.line((bx0 + k * 48, by0 + 150, bx0 + k * 48, by0 + 342), fill=(90, 90, 110))
        d.line((bx0, by0 + 150 + k * 48, bx0 + 192, by0 + 150 + k * 48), fill=(90, 90, 110))
    d.text((bx0, by0 + 350), '16 character codes,\neach 8 bytes at\n$E000 + 8 x code and an\nattribute at $EF00 + code\n'
           '(bit 7: solid)', fill=kitlib.DIM, font=small)
    # the map bytes
    ty = 610
    d.text((16, ty), 'RoomMaps $7600 + 240 x room: screen 0 is map columns 0-7 (RoomScreen = 8 x screen)',
           fill=kitlib.TEXT, font=mid)
    for by in range(5):
        row = ' '.join('%02X' % res[base + by * 48 + bx] for bx in range(8))
        d.text((16, ty + 30 + by * 24), 'row %d  $%04X:  %s' % (by, base + by * 48, row), fill=(255, 140, 140),
               font=mid)
    d.text((560, ty + 30), 'record bytes: left FF (none), right FF (none),\npod 0A = room 10, exit 3 FF (never used),\n'
           'zone 00, arrival 44 = x $50 in screen 2\n(of the pod room 10), enemy kind 0 on screen 0',
           fill=kitlib.DIM, font=mid)
    im.save(out)
    print(out, im.size)


def cmd_world(out):
    plt = plt_setup()
    mem = game()
    fig, ax = plt.subplots(figsize=(10.5, 9.2), dpi=100)
    picks = pickups(mem)
    for r in range(16):
        rec = mem[0x953B + 12 * r:0x953B + 12 * r + 12]
        for s in range(6):
            k = rec[6 + s]
            ax.add_patch(plt.Rectangle((s, r), 1, 1, facecolor=KIND_COLOURS.get(k, '#fff'), edgecolor='#888', lw=0.6))
            ax.text(s + 0.5, r + 0.32, KIND_NAMES.get(k, str(k)) if k else '', ha='center', va='center', fontsize=10)
        here = [(x // 32, kind) for room, kind, x, y in picks if room == r]
        for n, (s, kind) in enumerate(here):
            k2 = sum(1 for s2, _ in here[:n] if s2 == s) - (0.5 if sum(1 for s2, _ in here if s2 == s) > 1 else -0.4)
            ax.text(s + 0.5, r + 0.5 + 0.3 * k2, MASKS[kind], ha='center', va='center', fontsize=10,
                    color='#b30000', weight='bold')
        ex = ['--' if e == 0xFF else str(e) for e in rec[:3]]
        arr = rec[5]
        arrival = '' if rec[2] == 0xFF else '(s%d x $%02X)' % ((arr & 0xE0) >> 5, (arr & 0x1F) * 4 + 0x40)
        ax.text(6.08, r + 0.5, ('zone %d   left %s  right %s  pod %s  %s' % (rec[4], ex[0], ex[1], ex[2], arrival)).replace('$', r'\$'),
                va='center', fontsize=10, family='monospace')
    ax.set_xlim(0, 10.6)
    ax.set_ylim(16, 0)
    ax.set_xticks([s + 0.5 for s in range(6)])
    ax.set_xticklabels(['screen %d\n(\\$%02X)' % (s, 8 * s) for s in range(6)])
    ax.xaxis.tick_top()
    ax.set_yticks([r + 0.5 for r in range(16)])
    ax.set_yticklabels(['room %d' % r for r in range(16)])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.tick_params(length=0)
    ax.set_title('The world as data: RoomTable \\$953B (enemy kind per screen, exits, zone, the pod\'s arrival) and '
                 'PickupTable \\$950E (red)', fontsize=11, pad=36)
    fig.tight_layout()
    fig.savefig(out)
    print(out)


RECORD_FIELDS = {0: 'kind / state (bit 7 placed, bit 6 dying)', 1: '-', 2: 'direction (bit 7 left)', 3: 'x',
                 4: 'y', 5: 'width (chars)', 6: 'height (chars)', 7: 'draw: row count', 8: '-', 9: 'draw: buffer lo',
                 10: 'draw: buffer hi', 11: 'draw: first char', 12: 'draw: frame lo', 13: 'draw: frame hi',
                 14: 'draw: save lo', 15: 'draw: save hi', 16: 'timer', 17: 'kind variable 1', 18: 'kind variable 2',
                 19: 'draw / Matt: edge flags', 20: 'score lo (BCD)', 21: 'score hi (BCD)', 22: 'picture lo',
                 23: 'picture hi', 24: 'animation step', 25: 'mode (frame size)', 26: 'animation mask', 27: 'dx',
                 28: 'dy', 29: 'no wall test', 30: 'damage', 31: 'once a screen', 32: 'colour', 33: 'hits / power',
                 34: 'shot hit flag (LIFTER $FF)', 35: 'slot number', 36: 'draw: row', 37: 'draw: row'}


def cmd_record(out):
    plt = plt_setup()
    fr = 990
    r = [s for s in samples('rzx-00000') if s['f'] == fr][0]
    o = r['o']
    fig, ax = plt.subplots(figsize=(10.5, 11.5), dpi=100)
    heads = ['Matt\n\\$A43F', 'shot\n\\$A465'] + ['obj %d\n\\$%04X' % (i, 0xA43F + 38 * i) for i in range(2, 8)]
    for c in range(8):
        for f in range(38):
            v = o[38 * c + f]
            used = f in (0, 2, 3, 4, 5, 6, 16, 17, 18, 20, 21, 22, 23, 24, 27, 28, 30, 33, 34)
            ax.add_patch(plt.Rectangle((c, f), 1, 1, facecolor='#deebf7' if used else '#f7f7f7', edgecolor='#aaa',
                                       lw=0.5))
            ax.text(c + 0.5, f + 0.5, '%02X' % v, ha='center', va='center', fontsize=10, family='monospace',
                    color='#000' if v else '#bbb')
    for f in range(38):
        ax.text(8.1, f + 0.5, ('+$%02X  %s' % (f, RECORD_FIELDS[f])).replace('$', r'\$'), va='center', fontsize=10)
    ax.set_xlim(0, 11.6)
    ax.set_ylim(38, 0)
    ax.set_xticks([c + 0.5 for c in range(8)])
    ax.set_xticklabels(heads)
    ax.xaxis.tick_top()
    ax.set_yticks([])
    for sp in ax.spines.values():
        sp.set_visible(False)
    ax.tick_params(length=0)
    ax.set_title('Objects \\$A43F at rzx-00000 TTD frame %d: 8 records of \\$26 bytes (blue: the fields the rules use)' % fr,
                 pad=40)
    fig.tight_layout()
    fig.savefig(out)
    print(out)


TEMPLATE_USE = ['faller (kind 1)', 'flyer (kind 2)', 'turret (kind 4)', 'turret shot (kind 5)', 'wave (kind 6)',
                'walker (kind 7)', 'chaser (kind 8)', 'kind 16\'s shot', 'riser (kind 12)', 'guard (kind 13)',
                'boss (kind 14)', 'boss shot (kind 15)', 'kind 16', 'kind 18', 'kind 19', 'kind 19 (last)',
                'explosion', 'big explosion', 'guard part 1', 'guard part 2']
PIC_FILES = {0xD260: ('faller.png', 2, 2), 0xD2E0: ('flyer.png', 3, 2), 0xD7A0: ('turret.png', 3, 2),
             0xD860: ('turret-shot.png', 1, 1), 0xD8A0: ('wave.png', 2, 2), 0xD960: ('walker.png', 2, 2),
             0xD9E0: ('chaser.png', 8, 3), 0xDAA0: ('kind16.png', 2, 3), 0xDBC0: ('guard.png', 4, 4),
             0xDEE0: ('boss.png', 4, 4), 0xDF60: ('boss-shot.png', 2, 2), 0xDB60: ('big.png', 4, 3),
             0xDE80: ('small.png', 2, 2), 0xDEA0: ('small.png', 2, 2, 1), 0xDEC0: ('small.png', 2, 2, 2),
             0xD440: ('explosion.png', 2, 2), 0xD4C0: ('explosion-big.png', 3, 2), 0xDC40: ('part1.png', 3, 3),
             0xDD60: ('part2.png', 3, 3)}


def cmd_templates(out):
    mem = game()
    W, rowh = 1050, 52
    H = 70 + 20 * rowh
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    mid, small = kitlib.font(16), kitlib.font(15)
    d.text((10, 8), 'EnemyTemplates $BE3B: 20 records of 12 bytes, copied by SetupObject $BFF5 into a new object',
           fill=kitlib.TEXT, font=kitlib.font(18))
    cols = [(10, 'rec'), (60, 'used by'), (262, 'picture'), (420, 'score'), (490, 'damage'), (570, 'hits'),
            (630, 'w x h'), (700, 'mode'), (760, 'colour'), (840, 'bytes')]
    for x, t in cols:
        d.text((x, 40), t, fill=kitlib.DIM, font=small)
    for i in range(20):
        r = mem[0xBE3B + 12 * i:0xBE3B + 12 * i + 12]
        y = 66 + i * rowh
        if i % 2:
            d.rectangle((0, y - 4, W, y + rowh - 6), fill=kitlib.PANEL)
        pic = r[2] | r[3] << 8
        d.text((10, y + 10), '%2d' % i, fill=kitlib.TEXT, font=mid)
        d.text((60, y + 10), TEMPLATE_USE[i], fill=kitlib.TEXT, font=mid)
        spec = PIC_FILES.get(pic)
        if spec:
            fname, w, h = spec[:3]
            frame = spec[3] if len(spec) > 3 else 0
            col = r[11]
            ink = (255, 255, 255) if col & 0x80 else tuple(roommap.colour(col & 7, True))
            if ink == (0, 0, 0):
                ink = (200, 200, 200)
            sc = 2 if h <= 2 else 1 if w > 4 else 2 if h * 8 * 2 <= rowh else 1
            spr = sprite_frame(fname, w, h, frame, sc, ink=ink)
            if spr.size[1] > rowh - 6:
                spr = spr.resize((spr.size[0] * (rowh - 6) // spr.size[1], rowh - 6), Image.NEAREST)
            im.paste(spr, (262, y - 2), spr)
        d.text((350, y + 10), '$%04X' % pic, fill=kitlib.DIM, font=small)
        d.text((420, y + 10), '%X' % (r[1] << 8 | r[0]), fill=(255, 220, 120), font=mid)
        d.text((490, y + 10), '%d' % r[4], fill=(255, 130, 130), font=mid)
        d.text((570, y + 10), '%d' % r[10], fill=(140, 200, 255), font=mid)
        d.text((630, y + 10), '%d x %d' % (r[7], r[8]), fill=kitlib.TEXT, font=mid)
        d.text((700, y + 10), '%d' % r[9], fill=kitlib.TEXT, font=mid)
        d.text((760, y + 10), 'random' if r[11] & 0x80 else '%d' % r[11], fill=kitlib.TEXT, font=mid)
        d.text((840, y + 10), ' '.join('%02X' % b for b in r[:6]) + '\n' + ' '.join('%02X' % b for b in r[6:]),
               fill=kitlib.DIM, font=small)
    im.save(out)
    print(out, im.size)


def jump_model(moon):
    """Matt's y offset per pass in a standing jump: state 5 from v = -9 up to v = 1, then state 6 down"""
    y, v, state, ys, passes = 0, -9, 5, [0], 0
    while passes < 60:
        passes += 1
        if state == 5:
            # the jump (MattFall $B7B5): on the moon v skips its step when PassCounter AND 3 is 0
            if not moon or passes % 4 != 0:
                v += 1
                if v == 1:
                    state, v = 6, 1
                    ys.append(y)
                    continue
            y += v
        else:
            y += v
            # the fall ($B8A7): on the moon v steps only when PassCounter AND 3 is 0
            if v != 8 and (not moon or passes % 4 == 0):
                v += 1
            if y >= 0:
                ys.append(0)
                break
        ys.append(y)
    return ys


def cmd_jump(out):
    plt = plt_setup()
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.6), dpi=100)
    ax = axes[0]
    for moon, lab, c in ((False, 'earth: v + 1 every pass', '#d62728'), (True, 'the moon (zone 2): rising v + 1 on 3 passes in 4, falling 1 in 4',
                                                                       '#1f77b4')):
        ys = jump_model(moon)
        ax.plot(range(len(ys)), [-y for y in ys], marker='o', ms=3, color=c, label=lab)
    ax.set_xlabel('pass')
    ax.set_ylabel('height above the start (pixels)')
    ax.set_title(r'The model (MattFall \$B7B5, \$B8A7), standing jump')
    ax.set_ylim(-2, 64)
    ax.set_yticks(range(0, 50, 10))
    ax.legend(loc='upper center', fontsize=10)
    ax.grid(alpha=0.3)
    ax = axes[1]
    s = [r for r in samples('rzx-00000') if 852 <= r['f'] <= 892]
    colours = {1: '#7f7f7f', 5: '#d62728', 6: '#1f77b4', 8: '#2ca02c'}
    xs = [r['f'] for r in s]
    ys = [r['o'][4] for r in s]
    ax.plot(xs, ys, color='#999', lw=1)
    for st, c in colours.items():
        pts = [(r['f'], r['o'][4]) for r in s if r['o'][0] == st]
        if pts:
            ax.scatter(*zip(*pts), color=c, s=22, zorder=3, label='state %d' % st)
    ax.invert_yaxis()
    ax.set_xlabel('rzx-00000 TTD frame')
    ax.set_ylabel(r'Matt y (\$A443, decimal)')
    ax.set_title('Measured: a jump onto a ledge, frames 852-892')
    ax.legend(loc='lower right')
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(out)
    print(out)


SEGMENTS = ['rzx-00000', 'rzx-04000', 'rzx-08000', 'rzx-12000', 'rzx-16000', 'rzx-20000', 'rzx-24000', 'rzx-28000',
            'rzx-32000', 'rzx-36000']


def cmd_run(out):
    plt = plt_setup()
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 8.6), dpi=100, sharex=True,
                             gridspec_kw={'height_ratios': [3, 2, 2]})
    for k, rec in enumerate(SEGMENTS):
        s = [r for r in samples(rec) if r['f'] < 4000]
        x = [4000 * k + r['f'] for r in s]
        axes[0].plot(x, [int(r['energy'], 16) for r in s], lw=0.8, color='#d62728')
        sc = []
        for r in s:
            try:
                sc.append(int(r['score'], 10))
            except ValueError:
                sc.append(float('nan'))
        axes[1].plot(x, sc, lw=0.9, color='#1f77b4')
        axes[2].scatter(x[::4], [int(r['room'][0:2], 16) + int(r['room'][6:8], 16) / 48 for r in s][::4], s=1,
                        color='#2ca02c')
        dead = [4000 * k + r['f'] for i, r in enumerate(s) if r['dying'] != '00' and (i == 0 or s[i - 1]['dying'] == '00')]
        for d in dead:
            for ax in axes:
                ax.axvline(d, color='#555', lw=0.8, ls=':')
        for ax in axes:
            ax.axvline(4000 * k, color='#ccc', lw=0.6)
        axes[2].text(4000 * k + 60, 15.3, rec[4:], fontsize=10, color='#555')
    axes[0].set_ylabel(r'Energy \$AEA6')
    axes[0].set_ylim(-5, 262)
    axes[1].set_ylabel(r'Score \$AE41')
    axes[2].set_ylabel('room + screen / 6')
    axes[2].set_ylim(-0.5, 16)
    axes[2].set_xlabel('RZX frame (each segment from its own state; dotted: Matt starts to die)')
    axes[0].set_title('The ZXDB RZX run, ten segments of 4000 frames: energy, score and the room')
    for ax in axes:
        ax.grid(alpha=0.25)
    fig.tight_layout()
    fig.savefig(out)
    print(out)


MASK_INFO = {1: ('held', 'through walls, no touch damage', '1 / 2 passes'),
             2: ('held', 'nothing (a RET)', '0'), 3: ('held', 'nothing (a RET)', '0'),
             4: ('held', 'Energy + 2 a pass', '1 a pass'),
             5: ('press', 'shot, power 1; up: long jump', '1; jump 1 / 5'),
             6: ('press', 'shot, power 1; lifts the target', '8 a shot'),
             7: ('press', 'shot, power 3', '1 a shot'), 8: ('press', 'shot, power 2', '1 a shot'),
             9: ('press', 'shot, power 6', '1 a shot'), 10: ('press', 'shot, power 1', '1 a shot')}


def cmd_masks(out):
    mem = game()
    W, rowh = 1050, 50
    H = 64 + 10 * rowh + 10
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    mid, small = kitlib.font(16), kitlib.font(15)
    d.text((10, 8), 'The ten masks: MaskIcons $D580, MaskLevels $AF3B, MaskColours $AF46, FireMask $BCE0, PickupTable',
           fill=kitlib.TEXT, font=kitlib.font(17))
    for x, t in ((10, 'kind'), (60, 'icon'), (110, 'name'), (250, 'level'), (310, 'fire'), (370, 'what it does'),
                 (690, 'charges'), (830, 'lies in (room, screen)')):
        d.text((x, 36), t, fill=kitlib.DIM, font=small)
    picks = pickups(mem)
    for k in range(1, 11):
        y = 60 + (k - 1) * rowh
        if k % 2:
            d.rectangle((0, y - 4, W, y + rowh - 6), fill=kitlib.PANEL)
        col = mem[0xAF46 + k]
        ink = tuple(roommap.colour(col & 7, True)) if col & 7 else (200, 200, 200)
        ic = sprite_frame('mask-icons.png', 2, 2, k, 2, ink=ink)
        im.paste(ic, (56, y + 2), ic)
        how, what, cost = MASK_INFO[k]
        d.text((10, y + 10), '%d' % k, fill=kitlib.TEXT, font=mid)
        d.text((110, y + 10), MASKS[k], fill=ink, font=mid)
        d.text((250, y + 10), '%d' % mem[0xAF3B + k], fill=kitlib.TEXT, font=mid)
        d.text((310, y + 10), how, fill=kitlib.TEXT, font=mid)
        d.text((370, y + 10), what, fill=kitlib.TEXT, font=small)
        d.text((690, y + 10), cost, fill=kitlib.TEXT, font=small)
        where = ', '.join('%d/%d' % (r, x // 32) for r, kk, x, yy in picks if kk == k)
        d.text((830, y + 10), where or '(none)', fill=kitlib.DIM, font=small)
    im.save(out)
    print(out, im.size)


def slot_charges(r, kind):
    """the BCD charges of the first slot holding mask kind (None when none does)"""
    b = bytes.fromhex(r['slots'])
    for i in range(4):
        if b[4 * i + 1] == kind:
            c = b[4 * i + 2]
            return (c >> 4) * 10 + (c & 15)
    return None


CHARGE_PANELS = [
    ('rzx-16000', 255, 430, 4, 'HEALER held: Energy + 2 and a charge a pass', 'energy', r'Energy \$AEA6'),
    ('rzx-00000', 2505, 2625, 1, 'PENETRATOR held: a charge every second pass, Matt walks the stairs through walls',
     'x', r'Matt x \$A442'),
    ('rzx-12000', 1290, 1432, 5, 'JACKRABBIT: the long jump (state 7), a charge every 5 passes', 'y',
     r'Matt y \$A443 (up)'),
    ('rzx-12000', 2090, 2225, 6, 'LIFTER: 8 charges a shot, each lifted walker + 100 points', 'score', 'Score'),
]


def cmd_charges(out):
    plt = plt_setup()
    fig, axes = plt.subplots(4, 1, figsize=(10.5, 11.0), dpi=100)
    for ax, (rec, a, b, kind, title, what, label) in zip(axes, CHARGE_PANELS):
        s = [r for r in samples(rec) if a <= r['f'] <= b]
        xs = [r['f'] for r in s]
        ch = [slot_charges(r, kind) for r in s]
        ax.step(xs, [c if c is not None else 0 for c in ch], where='post', color='#d62728', lw=1.6,
                label='charges of the %s slot' % MASKS[kind])
        ax.set_ylabel('charges (BCD as decimal)')
        ax.set_ylim(-3, 103)
        ax2 = ax.twinx()
        if what == 'energy':
            ys = [int(r['energy'], 16) for r in s]
        elif what == 'x':
            ys = [r['o'][3] for r in s]
        elif what == 'y':
            ys = [r['o'][4] for r in s]
            ax2.invert_yaxis()
        else:
            ys = [int(r['score'], 10) for r in s]
        ax2.plot(xs, ys, color='#1f77b4', lw=1.2, label=label)
        ax2.set_ylabel(label, color='#1f77b4')
        ax.set_title('%s (%s, frames %d-%d)' % (title, rec, a, b))
        ax.set_xlabel('TTD frame')
        ax.grid(alpha=0.3)
        h1, l1 = ax.get_legend_handles_labels()
        h2, l2 = ax2.get_legend_handles_labels()
        ax.legend(h1 + h2, l1 + l2, loc='lower left', fontsize=10)
    fig.tight_layout()
    fig.savefig(out)
    print(out)


def main():
    cmd, out = sys.argv[1], sys.argv[2]
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    {'room-decode': cmd_room_decode, 'world': cmd_world, 'record': cmd_record, 'templates': cmd_templates,
     'jump': cmd_jump, 'run': cmd_run, 'masks': cmd_masks, 'charges': cmd_charges}[cmd](out)


if __name__ == '__main__':
    main()
