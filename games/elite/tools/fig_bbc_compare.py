#!/usr/bin/env python3
"""The figures of docs/bbc-comparison.md besides the ship overlays (tools/fig_bbc_ships.py).

    python3 tools/fig_bbc_compare.py work/bbc [formats] [galaxy] [market] [dashboard] [docking] [kills]   # all when none

- formats:   the ship header, the Spectrum's 23 bytes beside the BBC disc's 20, the same values joined by a line,
             the Asp's values in both (src/res/ships/ships.txt; the disc's elite-ships-*.asm).
- galaxy:    the Spectrum's galactic chart (d1 1500) with the 256 systems the BBC's seeds and twist place drawn
             over it; galaxy 2 with the galactic jump's two arrivals (tools/galaxy.py).
- market:    Diso's stock at f1's arrival by MakeMarket and by the BBC's GVL, and Lave's first stock in the two
             commander records (DefaultCommander, NA%), beside the Spectrum's market page (t1 400).
- dashboard: the Spectrum's dashboard (f1) above the BBC's (the cassette's P.DIALS.bin, mode 5, its palette TVT1),
             and the two scanners overlaid.
- docking:   the nose directions and the slot rotations each docking test accepts (CollideStation, ISDK).
- kills:     a kill's score against the BBC Master's kill points, and the rating's steps on both.

BBC_DIR is the folder of the BBC sources (bbc-comparison.md lists them); P.DIALS.bin is read from BBC_DIR/img/.
"""
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import bbc_compare as BC  # noqa: E402
import galaxy as G  # noqa: E402
import kitlib as K  # noqa: E402
import rtplot as P  # noqa: E402
import zxscreen as Z  # noqa: E402

W = 900
OUT = os.path.join(CASE, 'docs', 'img', 'bbc')
ORANGE, CYAN, WHITE = (255, 150, 50), (80, 210, 230), (235, 235, 240)


def rgb(c):
    return tuple(int(255 * v) for v in c[:3])


def wrap(d, text, font, width):
    out, line = [], ''
    for word in text.split():
        cand = (line + ' ' + word).strip()
        if d.textlength(cand, font=font) > width and line:
            out.append(line)
            line = word
        else:
            line = cand
    return out + ([line] if line else [])


def titled(height, title, size=17):
    """a 900 px canvas with the title wrapped at its top; returns (image, draw, y below the title)"""
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    lines = wrap(probe, title, K.font(size), W - 20)
    top = 10 + 23 * len(lines) + 8
    im = Image.new('RGB', (W, top + height), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for i, line in enumerate(lines):
        d.text((10, 10 + 23 * i), line, fill=K.TEXT, font=K.font(size))
    return im, d, top


def scr(rec, frame):
    for sub in ('frames', 'screens'):
        p = os.path.join(CASE, 'work', rec, sub, '%06d.scr' % frame)
        if os.path.isfile(p):
            return Z.render(open(p, 'rb').read(), 1).convert('RGB')
    raise SystemExit('no screen %s %d' % (rec, frame))


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    im.save(path)
    print('wrote', os.path.relpath(path, CASE), im.size)


# --- formats

SPECTRUM_HEADER = [(0, 1, 'cargo from a canister (high nibble)', ['cargo']), (1, 1, 'size: the collision box', ['size']),
                   (2, 1, 'laser: the chance to fire', []), (3, 1, 'vertices', ['V']), (4, 1, 'edges', ['E']),
                   (5, 1, 'faces', ['F']), (6, 1, 'top speed', ['speed']), (7, 1, 'maximum energy', ['energy']),
                   (8, 2, 'bounty, tenths', ['bounty']), (10, 1, 'launches; the kind launched', ['missiles']),
                   (11, 1, 'distance to draw as a dot', ['vis']), (12, 2, 'vertices offset', []),
                   (14, 2, 'edges offset', ['eoff']), (16, 2, 'faces offset', ['foff']), (18, 1, 'behaviour', []),
                   (19, 1, 'normals scale', ['scale']), (20, 1, 'laser vertex', ['gun']),
                   (21, 2, 'combat score, halved', [])]
BBC_HEADER = [(0, 1, 'max. canisters on demise', ['cargo']), (1, 2, 'targetable area', ['size']),
              (3, 1, 'edges offset, low', ['eoff']), (4, 1, 'faces offset, low', ['foff']),
              (5, 1, 'max. edge count', []), (6, 1, 'gun vertex', ['gun']),
              (7, 1, 'explosion count', []), (8, 1, 'vertices', ['V']), (9, 1, 'edges', ['E']),
              (10, 2, 'bounty, tenths', ['bounty']), (12, 1, 'faces', ['F']), (13, 1, 'visibility distance', ['vis']),
              (14, 1, 'max. energy', ['energy']), (15, 1, 'max. speed', ['speed']), (16, 1, 'edges offset, high', ['eoff']),
              (17, 1, 'faces offset, high', ['foff']), (18, 1, 'normals scale', ['scale']),
              (19, 1, 'laser power, missiles', ['missiles'])]
BBC_KEYS = ['Max. canisters on demise', 'Targetable area', 'Edges data offset (low)', 'Faces data offset (low)',
            'Max. edge count', 'Gun vertex', 'Explosion count', 'Number of vertices', 'Number of edges', 'Bounty',
            'Number of faces', 'Visibility distance', 'Max. energy', 'Max. speed', 'Edges data offset (high)',
            'Faces data offset (high)', 'Normals are scaled by', 'Laser power']


def formats(bbc):
    sp = BC.spectrum_ships()['Asp']['header']
    bs = BC.bbc_ships(bbc)['ASP_MK_2']['fields']
    row, x_sp, x_bbc, bw = 26, 10, 520, 370
    im, d, top = titled(23 * row + 110, "One header, two layouts: the Spectrum keeps the BBC's values (the Asp's shown) "
                        "but in another order, stores plain counts where the BBC stores 4 and 6 times them, and adds "
                        "the behaviour and a combat score")
    f13, f14, f15 = K.font(13), K.font(14), K.font(15)
    d.text((x_sp, top), "Spectrum, 23 bytes (Asp at $61CC)", fill=K.TEXT, font=f15)
    d.text((x_bbc, top), 'BBC disc, 20 bytes (SHIP_ASP_MK_2)', fill=K.TEXT, font=f15)
    y0 = top + 28
    keys = sorted({k for *_, ks in SPECTRUM_HEADER + BBC_HEADER for k in ks})
    colour = {k: rgb(P.PALETTE[i % len(P.PALETTE)]) for i, k in enumerate(keys)}
    boxes = {}

    def bbc_value(i):
        v = next((v for key, v in bs.items() if key.startswith(BBC_KEYS[i])), '')
        nums = [int(n) for n in __import__('re').findall(r'\d+', v)]
        key = BBC_KEYS[i]
        if key in ('Number of vertices', 'Number of faces', 'Gun vertex'):
            return '%d = %d x %d' % (nums[0], nums[-1], nums[1])          # stored = count x 6 or 4
        if key == 'Max. edge count':
            return '%d = 4 x %d + 1' % (nums[0], nums[-1])
        if key == 'Explosion count':
            return '%d = 4 x %d + 6' % (nums[-1], nums[0])
        if key == 'Normals are scaled by':
            return '%d (x%d)' % (nums[1], nums[-1])
        if key == 'Laser power':
            return '%s; %s missile' % (v, bs.get('Missiles', '?'))
        return v

    for side, fields, x in (('sp', SPECTRUM_HEADER, x_sp), ('bbc', BBC_HEADER, x_bbc)):
        for i, (off, ln, name, ks) in enumerate(fields):
            ya, yb = y0 + off * row, y0 + (off + ln) * row - 3
            col = colour[ks[0]] if ks else (70, 70, 85)
            d.rectangle([x, ya, x + bw, yb], outline=col, fill=tuple(v // 6 for v in col))
            if side == 'sp':
                val = sp[off] if ln == 1 else sp[off] | sp[off + 1] << 8
                text = '%d' % val
            else:
                text = bbc_value(i)
            d.text((x + 6, ya + 4), '+%02d' % off, fill=K.DIM, font=f13)
            d.text((x + 42, ya + 3), name, fill=K.TEXT if ks else K.DIM, font=f14)
            d.text((x + bw - 6 - d.textlength(text, font=f14), ya + 3), text, fill=col if ks else K.DIM, font=f14)
            for k in ks:
                boxes.setdefault(k, {}).setdefault(side, []).append((ya + yb) / 2)
    for k, sides in boxes.items():
        for ya in sides.get('sp', []):
            for yb in sides.get('bbc', []):
                d.line([(x_sp + bw + 2, ya), (x_sp + bw + 30, ya), (x_bbc - 30, yb), (x_bbc - 2, yb)],
                       fill=colour[k], width=2)
    y = y0 + 23 * row + 8
    for line in wrap(d, 'Grey: no counterpart. The Spectrum laser byte is a chance to fire (250 of 255); the BBC '
                     "byte is the laser's power and the missiles. The BBC vertices follow the header, so it has no "
                     'vertices offset; the Spectrum keeps the area\'s side (60), the BBC its square (3600).',
                     f13, W - 20):
        d.text((10, y), line, fill=K.DIM, font=f13)
        y += 18
    save(im, 'formats.png')


# --- galaxy

def galaxy(bbc):
    chart = scr('d1', 1500)
    g1, g2 = G.systems(1), G.systems(2)
    s = 3
    im, d, top = titled(192 * s + 128 * s + 130, "The galaxy: the BBC's seeds and twist put all 256 systems on "
                        "the Spectrum's dots; only the galactic jump's arrival differs (galaxy 2)")
    f13, f14 = K.font(13), K.font(14)
    x0 = (W - 256 * s) // 2
    im.paste(chart.resize((256 * s, 192 * s), Image.NEAREST), (x0, top))
    hits = 0
    px = chart.load()
    for sy in g1:
        X, Y = sy['x'], sy['y'] // 2 + 24
        on = sum(px[X, Y]) > 300
        hits += on
        cx, cy = x0 + X * s + 1, top + Y * s + 1
        d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], outline=ORANGE if on else CYAN)
    y = top + 192 * s + 4
    for line in wrap(d, "d1 1500, the Spectrum's galactic chart at 3x. Rings: the positions from the BBC's seeds "
                     "(NA%%) and twist (TT54), orange on a lit dot (%d of 256; the one cyan ring is under the "
                     "cursor's circle)" % hits, f13, W - 20):
        d.text((10, y), line, fill=K.DIM, font=f13)
        y += 18
    # galaxy 2, as the chart lays it
    y += 14
    gy = y
    d.rectangle([x0 - 1, gy - 1, x0 + 256 * s, gy + 128 * s], outline=(60, 60, 72))
    for sy in g2:
        cx, cy = x0 + sy['x'] * s, gy + (sy['y'] // 2) * s
        d.rectangle([cx - 1, cy - 1, cx + 1, cy + 1], fill=(150, 150, 160))
    cur = (20, 173)
    sp, bb = G.nearest(g2, *cur), G.nearest(g2, 96, 96)

    def label(x, y_, text, col):
        tw = d.textlength(text, font=f14)
        d.rectangle([x - 2, y_ - 1, x + tw + 2, y_ + 17], fill=K.BACKGROUND)
        d.text((x, y_), text, fill=col, font=f14)

    for (x, y_), col in ((cur, WHITE), ((96, 96), CYAN)):
        cx, cy = x0 + x * s, gy + (y_ // 2) * s
        d.line([(cx - 9, cy), (cx + 9, cy)], fill=col, width=2)
        d.line([(cx, cy - 9), (cx, cy + 9)], fill=col, width=2)
    for sy, col in ((sp, ORANGE), (bb, CYAN)):
        cx, cy = x0 + sy['x'] * s, gy + (sy['y'] // 2) * s
        d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], outline=col, width=2)
    label(x0 + sp['x'] * s + 14, gy + (sp['y'] // 2) * s + 4, 'Inoran: the Spectrum', ORANGE)
    label(x0 + 20 * s + 14, gy + (173 // 2) * s - 26, 'the cursor', WHITE)
    label(x0 + bb['x'] * s + 14, gy + (bb['y'] // 2) * s - 22, 'Ororra: the BBC', CYAN)
    y = gy + 128 * s + 4
    for line in wrap(d, "Galaxy 2, laid out as the chart draws it (x, y / 2; tools/galaxy.py). The jump keeps the "
                     "chart cursor where Lave was (20, 173): the Spectrum arrives at the system nearest it, Inoran "
                     "(%d, %d); the BBC at the one nearest (96, 96), Ororra (%d, %d)"
                     % (sp['x'], sp['y'], bb['x'], bb['y']), f13, W - 20):
        d.text((10, y), line, fill=K.DIM, font=f13)
        y += 18
    save(im, 'galaxy.png')


# --- market

def bbc_market(economy, fluctuation):
    """GVL's stock (cassette): base quantity + (fluctuation AND mask) - or + product, negative 0, AND 63"""
    img = G.image()
    out = []
    for i in range(17):
        base, factor, quantity, mask = (G.byte(img, G.COMMODITIES + 4 * i + k) for k in range(4))
        product = (economy * (factor & 0x1F)) & 0xFF
        a = (quantity + (fluctuation & mask)) & 0xFF
        stock = (a + product) & 0xFF if factor & 0x80 else (a - product) & 0xFF
        out.append(0 if stock & 0x80 else stock & 0x3F)
    out[16] = 0
    return out


GOODS = ['Food', 'Textiles', 'Radioactives', 'Slaves', 'Liquor/Wines', 'Luxuries', 'Narcotics', 'Computers',
         'Machinery', 'Alloys', 'Firearms', 'Furs', 'Minerals', 'Gold', 'Platinum', 'Gem-Stones', 'Alien Items']


def bbc_first_stock(bbc):
    """NA%'s AVL+0 to AVL+16 (the cassette's commander file): Lave's stock at the start"""
    import re
    out = {}
    for line in open(os.path.join(bbc, 'elite-source.asm'), encoding='utf-8', errors='replace'):
        m = re.match(r'\s*EQUB\s+(\d+)\s*\\\s*AVL\+(\d+)\s', line)
        if m:
            out[int(m.group(2))] = int(m.group(1))
    return [out[i] for i in range(17)]


def market(bbc):
    g1 = G.systems(1)
    diso = next(s for s in g1 if s['name'] == 'Diso')
    img = G.image()
    sp_diso = [stock for _price, stock in G.market(diso['economy'], 0xA6)]
    tables = [(['Diso (f1):', 'MakeMarket', 'and GVL'], None, sp_diso, bbc_market(diso['economy'], 0xA6)),
              (['Lave, first:', 'the two', 'records'], None, [G.byte(img, 0xD232 + 0x4A + i) for i in range(17)],
               bbc_first_stock(bbc))]
    shot = scr('t1', 400).resize((512, 384), Image.NEAREST)
    row = 21
    im, d, top = titled(max(384 + 44, 18 * row + 80), "The market: the same prices on both; a positive factor's "
                        "stock is one tonne less on the Spectrum (INC A / NEG for SEC / SBC), and Lave's first "
                        "stock is another set of numbers")
    f13, f14 = K.font(13), K.font(14)
    im.paste(shot, (10, top))
    for i, line in enumerate(wrap(d, "t1 400: Lave's market page on the Spectrum, the first stock of the "
                                  "record", f13, 512)):
        d.text((10, top + 388 + 18 * i), line, fill=K.DIM, font=f13)
    x = 538
    d.text((x, top), 'stock: Spectrum / BBC', fill=K.TEXT, font=f14)
    cols = [x + 122, x + 240]
    for c, (name, how, _sp, _bb) in zip(cols, tables):
        for i, part in enumerate(name):
            d.text((c, top + 20 + 16 * i), part, fill=K.DIM, font=f13)
    y0 = top + 20 + 16 * 3 + 8
    diffs = [0, 0]
    for i, good in enumerate(GOODS):
        y = y0 + i * row
        d.text((x, y), good, fill=K.TEXT, font=f14)
        for k, (c, (_n, _h, sp, bb)) in enumerate(zip(cols, tables)):
            same = sp[i] == bb[i]
            diffs[k] += not same
            text = '%d' % sp[i] if same else '%d / %d' % (sp[i], bb[i])
            d.text((c, y), text, fill=K.DIM if same else ORANGE, font=f14)
    d.text((x, y0 + 17 * row + 6), 'orange: they differ (%d and %d of 17)' % tuple(diffs), fill=ORANGE, font=f13)
    save(im, 'market.png')


# --- dashboard

def bbc_dials(bbc):
    data = open(os.path.join(bbc, 'img', 'P.DIALS.bin'), 'rb').read()
    pal = [(0, 0, 0), (255, 0, 0), (255, 255, 0), (0, 255, 0)]       # TVT1: black, red, yellow, green
    im = Image.new('RGB', (256, 56))
    for r in range(7):
        for col in range(32):
            for line in range(8):
                b = data[r * 256 + col * 8 + line]
                for i in range(4):
                    c = ((b >> (7 - i)) & 1) << 1 | ((b >> (3 - i)) & 1)
                    im.putpixel((col * 8 + 2 * i, r * 8 + line), pal[c])
                    im.putpixel((col * 8 + 2 * i + 1, r * 8 + line), pal[c])
    return im


def dashboard(bbc, frame=2000):
    sp = scr('f1', frame).crop((0, 128, 256, 192))
    bb = bbc_dials(bbc)
    s = 3
    sp_px, bb_px = sp.load(), bb.load()
    spl = {(x, yy) for x in range(66, 182) for yy in range(10, 61) if min(sp_px[x, yy]) > 150 and
           not (x >= 164 and yy < 26) and not (x >= 176 and yy >= 34)}   # the white dots, not the compass, the S
    bbl = {(x, yy) for x in range(54, 200) for yy in range(3, 54) if bb_px[x, yy] == (255, 0, 0) and
           not (x >= 180 and yy < 24)}                      # the red dots, not the compass

    def size(pts):
        xs, ys = [p[0] for p in pts], [p[1] for p in pts]
        return max(xs) - min(xs) + 1, max(ys) - min(ys) + 1

    (sw, sh), (bw, bh) = size(spl), size(bbl)
    im, d, top = titled(64 * s + 56 * s + 72 * s + 84, "The dashboard: the same gauges in the same "
                        "order on both; the BBC's panel is 8 rows shorter, its scanner wider and flatter (%d x %d pixels against "
                        "the Spectrum's %d x %d) and red, its compass a tall frame" % (bw, bh, sw, sh))
    f13 = K.font(13)
    x0 = (W - 256 * s) // 2
    y = top
    im.paste(sp.resize((256 * s, 64 * s), Image.NEAREST), (x0, y))
    d.text((x0, y + 64 * s + 4), 'Spectrum: f1 %d, the bottom 64 rows of the screen at 3x' % frame, fill=K.DIM,
           font=f13)
    y += 64 * s + 30
    im.paste(bb.resize((256 * s, 56 * s), Image.NEAREST), (x0, y))
    d.text((x0, y + 56 * s + 4), 'BBC: P.DIALS.bin (cassette), 7 rows of mode 5, its pixels doubled to 256 wide, at 3x',
           fill=K.DIM, font=f13)
    y += 56 * s + 30
    # the scanners overlaid, centres aligned

    def centre(pts):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        return (min(xs) + max(xs)) // 2, (min(ys) + max(ys)) // 2

    (sx, sy), (bx, by) = centre(spl), centre(bbl)
    ov = Image.new('RGB', (160, 72), (0, 0, 0))
    o = ov.load()
    shift = [(p[0] - sx + 80, p[1] - sy + 36) for p in spl]
    bshift = {(p[0] - bx + 80, p[1] - by + 36) for p in bbl}
    sset = set(shift)
    for p in sset | bshift:
        if 0 <= p[0] < 160 and 0 <= p[1] < 72:
            o[p] = WHITE if p in sset and p in bshift else (ORANGE if p in sset else CYAN)
    ox = (W - 160 * s) // 2
    im.paste(ov.resize((160 * s, 72 * s), Image.NEAREST), (ox, y))
    d.text((10, y + 72 * s + 4), 'The scanners overlaid, centres aligned, at 3x: orange the Spectrum only, cyan the '
           'BBC only, white both', fill=K.DIM, font=f13)
    save(im, 'dashboard.png')


# --- docking

def docking(bbc):
    fig, (ax, bx) = P.figure(9.6, 4.8, ncols=2, gridspec_kw={'width_ratios': [1.15, 1]})
    sp = math.degrees(math.asin(30 / 127))           # CollideStation: each of 2 x nose x, y high bytes below $3C
    bb = math.degrees(math.acos(86 / 96))            # ISDK: nosev_z hi beyond 214 (-86 of 96)
    ax.add_patch(P.plt.Rectangle((-sp, -sp), 2 * sp, 2 * sp, fill=True, alpha=0.25, color=P.WRITE,
                                 label='Spectrum: each part below 30/127 (%.1f°)' % sp))
    ax.add_patch(P.plt.Circle((0, 0), bb, fill=False, lw=2, color=P.READ, label='BBC: within %.1f° of the axis' % bb))
    ax.set_xlim(-32, 32)
    ax.set_ylim(-32, 32)
    ax.set_aspect('equal')
    ax.set_xlabel("station's nose off our line of flight, sideways (°)", fontsize=9)
    ax.set_ylabel('up and down (°)', fontsize=9)
    ax.legend(fontsize=8.5, loc='lower center', bbox_to_anchor=(0.5, -0.42), frameon=False)
    ax.set_title('The nose: a square on the Spectrum,\na cone on the BBC', fontsize=10)
    slot = math.degrees(math.acos(80 / 96))          # ISDK: |roofv_x| hi at least 80 of 96
    th = [math.radians(t) for t in range(0, 361)]
    bx.remove()
    bx = fig.add_subplot(1, 2, 2, projection='polar')
    bx.set_facecolor(P.BACKGROUND)
    bx.fill_between(th, 0.55, 0.75, color=P.WRITE, alpha=0.35)
    for c in (0, 180):
        t = [math.radians(v) for v in range(c - int(slot), c + int(slot) + 1)]
        bx.fill_between(t, 0.85, 1.05, color=P.READ, alpha=0.8)
    bx.set_ylim(0, 1.1)
    bx.set_yticks([])
    bx.tick_params(colors=P.DIM, labelsize=8)
    bx.text(math.radians(90), 0.25, 'Spectrum:\nany rotation', ha='center', fontsize=8.5, color=P.WRITE)
    bx.text(math.radians(270), 0.25, 'BBC: the roof\nwithin %.1f°\nof level' % slot, ha='center', fontsize=8.5,
            color=P.READ)
    bx.set_title('The slot: the Spectrum does not read it', fontsize=10)
    fig.suptitle("Docking: the Spectrum's nose test is a square well inside the BBC's cone, and it accepts the "
                 'slot at any angle', fontsize=11)
    P.save(fig, os.path.join(OUT, 'docking.png'))


# --- kills

def kills(bbc):
    ships = [('Thargoid', 1024, 2.664), ('Asp', 416, 1.082), ('Cobra / Python pirate', 448, 1.164),
             ('Fer-de-Lance', 384, 1.250), ('Cobra trader', 256, 0.914), ('Python trader', 256, 0.664),
             ('Krait, Sidewinder, Hermit', 128, 0.332), ('missile', 224, 0.582), ('Thargon', 50, 0.129),
             ('Viper', 40, 0.102)]
    fig, (ax, bx) = P.figure(9.6, 5.6, ncols=2, gridspec_kw={'width_ratios': [1.6, 1]})
    ys = range(len(ships))
    ax.barh([y - 0.2 for y in ys], [s[1] / 256 for s in ships], height=0.38, color=P.WRITE,
            label='Spectrum: half the +$15 word, in 256ths')
    ax.barh([y + 0.2 for y in ys], [s[2] for s in ships], height=0.38, color=P.READ,
            label='BBC Master: KWL% / KWH%')
    for y, s in zip(ys, ships):
        ax.text(s[1] / 256 + 0.05, y - 0.2, '%.2f' % (s[1] / 256), va='center', fontsize=8.5, color=P.TEXT)
        ax.text(s[2] + 0.05, y + 0.2, '%.2f  (x%.2f)' % (s[2], s[1] / 256 / s[2]), va='center', fontsize=8.5,
                color=P.DIM)
    ax.set_yticks(list(ys))
    ax.set_yticklabels([s[0] for s in ships], fontsize=9)
    ax.invert_yaxis()
    ax.set_xlim(0, 4.9)
    ax.set_xlabel('one kill, in BBC kills', fontsize=9)
    ax.legend(fontsize=8.5, loc='lower right', frameon=False)
    ax.set_title('A kill: 1.5 times the Master\'s points\nfor most ships', fontsize=10)
    ranks = ['Competent', 'Dangerous', 'Deadly', 'Elite']
    spec = [(1, 3), (3, 11), (11, 26), (26, 40)]
    bbcr = [(1, 2), (2, 10), (10, 25), (25, 40)]
    for i, (name, a, b) in enumerate(zip(ranks, spec, bbcr)):
        col = P.PALETTE[i]
        bx.bar(0, a[1] - a[0], bottom=a[0], width=0.6, color=col, alpha=0.8)
        bx.bar(1, b[1] - b[0], bottom=b[0], width=0.6, color=col, alpha=0.8)
        for xb, (lo, hi) in ((0, a), (1, b)):
            span = ('%d and up' % lo if hi >= 40 else '%d' % lo if hi - lo == 1 else '%d-%d' % (lo, hi - 1))
            sep = ' ' if hi - lo <= 2 else '\n'
            bx.text(xb, (lo + min(hi, 34)) / 2, name + sep + span, ha='center', va='center',
                    fontsize=8 if sep == ' ' else 8.5, color=(0.05, 0.05, 0.08))
    bx.set_xticks([0, 1])
    bx.set_xticklabels(['Spectrum:\nscore, top byte', 'BBC:\nTALLY+1'], fontsize=9)
    bx.set_ylim(0, 34)
    bx.set_ylabel('the byte the rank is read from', fontsize=9)
    bx.set_title('The ranks: each step\none higher on the Spectrum', fontsize=10)
    fig.suptitle('Kills and the rating: the Spectrum scores a kill by the ship and puts each rank one step later',
                 fontsize=11)
    P.save(fig, os.path.join(OUT, 'kills.png'))


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    bbc = sys.argv[1]
    for name in sys.argv[2:] or ['formats', 'galaxy', 'market', 'dashboard', 'docking', 'kills']:
        globals()[name](bbc)


if __name__ == '__main__':
    main()
