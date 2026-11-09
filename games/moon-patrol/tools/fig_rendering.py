#!/usr/bin/env python3
"""Figures of docs/06-rendering.md (writer mpB). Each subcommand draws one figure into docs/img/rendering/.

  python3 tools/fig_rendering.py bands    bands.png    the screen of i1 frame 450 cut into its six bands, with each
                                                     band's scroller, step and colour byte
  python3 tools/fig_rendering.py slots    slots.png    the buggy ($E140) and the rock ($DB10) in their four
                                                     pre-shifted slots, byte boundaries marked
  python3 tools/fig_rendering.py drawers  drawers.png  one slot of a sprite of each of the ten drawers, at scale,
                                                     with W x H and the slot formula
  python3 tools/fig_rendering.py scroll   scroll.png   the three scenery strips as 34 columns, the 32 on the screen
                                                     at a life start, the feed column, and the road's feed columns
  python3 tools/fig_rendering.py erase    erase.png    the rock pass by pass: erase, move, draw ahead, band roll
  python3 tools/fig_rendering.py crater   crater.png   RoadFeedWallA / WallB byte by byte and the V they make on the
                                                     road, against the crater of i1 frame 450
  python3 tools/fig_rendering.py wheels   wheels.png   the three wheels' paths from WheelPaths $AC31 (32 steps)
  python3 tools/fig_rendering.py shots    shots.png    the forward and upward shots of one press from (x $38, y $92)
  python3 tools/fig_rendering.py drawer   drawer.png   DrawSprite40x23 at work (a model of its row loop): the buggy
                                                     at x $3A, line $89, after 1, 8, 16 and 23 lines, with the
                                                     line table entry, screen address and source bytes of each
  python3 tools/fig_rendering.py blit     blit.png     BlitRows: TitleMoon $6132 (10 x 25 bytes) and where it lands
                                                     on the title screen (a1-title.png)
  python3 tools/fig_rendering.py pass     pass.png     one main-loop pass as a bar of T-states in call order, at the
                                                     three SpeedGovernor delays, frame interrupts marked
  python3 tools/fig_rendering.py odd      odd.png      the oddities: wreck piece 1's slots from $6350 (logo bytes) and
                                                     slot 0 of explosion frame 1 ($6500) against slot 1
  python3 tools/fig_rendering.py all

Data: the image work/mkgame/original.bin and the screenshots of docs/img/play (512 x 384, two pixels a Spectrum
pixel). No emulator is needed.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.normpath(os.path.join(CASE, '..', '..', 'kit')))
import kitlib as K  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'rendering')
MEM = open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb').read()
PLAY = os.path.join(CASE, 'docs', 'img', 'play')
W = 1050
F = K.font(17)
FB = K.font(19)
FS = K.font(16)
INK = (235, 235, 235)
GRID = (70, 70, 90)
BYTE = (150, 90, 90)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, name)
    im.save(p, optimize=True)
    print(p, im.size)


def canvas(h):
    im = Image.new('RGB', (W, h), K.BACKGROUND)
    return im, ImageDraw.Draw(im)


def bits(addr, wbytes, lines):
    return [[(MEM[addr + y * wbytes + b] >> (7 - x)) & 1 for b in range(wbytes) for x in range(8)]
            for y in range(lines)]


def draw_bits(d, x0, y0, grid, s, fg=INK, bytelines=True):
    h = len(grid)
    w = len(grid[0])
    d.rectangle([x0, y0, x0 + w * s, y0 + h * s], fill=(0, 0, 0))
    for y, row in enumerate(grid):
        for x, v in enumerate(row):
            if v:
                d.rectangle([x0 + x * s, y0 + y * s, x0 + x * s + s - 1, y0 + y * s + s - 1], fill=fg)
    if s >= 4:
        for x in range(w + 1):
            c = BYTE if (bytelines and x % 8 == 0) else GRID
            if x % 8 == 0 or s >= 6:
                d.line([x0 + x * s, y0, x0 + x * s, y0 + h * s], fill=c)
        d.line([x0, y0 + h * s, x0 + w * s, y0 + h * s], fill=GRID)
        d.line([x0, y0, x0 + w * s, y0], fill=GRID)
    return w * s, h * s


def title(d, text, sub=None):
    for t, f in ((text, FB), (sub or '', FS)):
        if f.getlength(t) > W - 24:
            print('TOO WIDE: ' + t)
    d.text((16, 12), text, font=FB, fill=K.TEXT)
    if sub:
        d.text((16, 38), sub, font=FS, fill=K.DIM)


# ---------------------------------------------------------------- bands
def fig_bands():
    shot = Image.open(os.path.join(PLAY, 'i1-crater.png')).convert('RGB')
    s = 1.5
    sw, sh = int(512 * s), int(384 * s)
    shot = shot.resize((sw, sh), Image.NEAREST)
    top = 70
    im, d = canvas(top + sh + 20)
    title(d, 'The screen in six bands (i1 frame 450, Beginner, a crater coming in)',
          '3 screen pixels a Spectrum pixel. Right: rows, lines, scroller and step a pass, colour byte')
    im.paste(shot, (16, top))
    bands = [(0, 3, 'HUD', 'rows 0-2, lines 0-23', 'HudDraw, no scroll', 'HudAttributes $9621'),
             (3, 8, 'sky', 'rows 3-7, lines 24-63', 'no scroll', '+0 = $07'),
             (8, 12, 'far band', 'rows 8-11, lines 64-95', 'ScrollFarBand: 1 px', '+1 = $02, every pass'),
             (12, 16, 'middle band', 'rows 12-15, lines 96-127', 'ScrollMiddleBand: 2 px', '+2 = $14'),
             (16, 20, 'near band', 'rows 16-19, lines 128-159', 'ScrollNearBand: 2 px', '+3 = $20; y < $89 only'),
             (20, 24, 'road', 'rows 20-23, lines 160-191', 'ScrollRoad: 4 px', '+4 = $34')]
    px = 3  # screen pixels a Spectrum pixel line
    x0 = 16 + sw + 10
    cols = [(230, 230, 230), (120, 120, 255), (230, 80, 80), (90, 210, 90), (90, 210, 90), (230, 210, 60)]
    for i, (r0, r1, name, rows, who, col) in enumerate(bands):
        y0 = top + r0 * 8 * px
        y1 = top + r1 * 8 * px
        d.rectangle([16, y0, 16 + sw - 1, y1 - 1], outline=cols[i], width=2)
        d.line([16 + sw, (y0 + y1) // 2, x0, (y0 + y1) // 2], fill=cols[i], width=2)
        ty = y0 + 4
        d.text((x0 + 4, ty), name, font=F, fill=cols[i])
        d.text((x0 + 4, ty + 20), rows, font=FS, fill=K.TEXT)
        d.text((x0 + 4, ty + 38), who, font=FS, fill=K.TEXT)
        d.text((x0 + 4, ty + 56), col, font=FS, fill=K.DIM)
    save(im, 'bands.png')


# ---------------------------------------------------------------- slots
def fig_slots():
    im, d = canvas(700)
    title(d, 'Pre-shifted slots: one frame stored four times, 2 pixels further right each time',
          'White = a set bit. Red lines = byte boundaries. The drawer picks the slot from x AND 6.')
    y = 76
    d.text((16, y), 'Sprite 0, the buggy: DrawSprite40x23, 5 bytes x 23 lines, slots 128 bytes apart from $E140',
           font=F, fill=K.TEXT)
    y += 28
    x = 16
    s = 6
    for k in range(4):
        a = 0xE140 + 128 * k
        d.text((x, y), 'slot %d at $%04X' % (k, a), font=FS, fill=K.TEXT)
        d.text((x, y + 18), 'x AND 6 = %d' % (2 * k), font=FS, fill=K.DIM)
        w, h = draw_bits(d, x, y + 40, bits(a, 5, 23), s)
        x += w + 20
    y += 40 + 23 * s + 30
    d.text((16, y), 'Sprite $0F, the rock: DrawSprite24x12, 3 bytes x 12 lines, slots 36 bytes apart from $DB10',
           font=F, fill=K.TEXT)
    y += 28
    x = 16
    s = 8
    for k in range(4):
        a = 0xDB10 + 36 * k
        d.text((x, y), 'slot %d at $%04X' % (k, a), font=FS, fill=K.TEXT)
        d.text((x, y + 18), 'x AND 6 = %d' % (2 * k), font=FS, fill=K.DIM)
        w, h = draw_bits(d, x, y + 40, bits(a, 3, 12), s)
        x += w + 60
    save(im.crop((0, 0, W, y + 40 + 12 * s + 14)), 'slots.png')


# ---------------------------------------------------------------- drawers
DRAWERS = [  # name, sprite, graphics, W, H, slot size, formula
    ('DrawSprite16x4 $AFDD', '$11 mine', 0xD9D0, 2, 4, 8, '8 slots: (x AND 7) x 8'),
    ('DrawSprite16x8 $B003', '$40 small boulder', 0xD590, 2, 8, 16, '4 slots: (x AND 6) x 8'),
    ('DrawSprite16x9 $B02A', '$3D wheel', 0x63E0, 2, 9, 18, '8 slots: (x AND 7) x 18'),
    ('DrawSprite24x8Attr $B069', '$01 saucer', None, 3, 8, 24, '4 slots: (x AND 6) x 12, 3 x 2 cells'),
    ('DrawSprite24x8 $B0BA', '$14 low flyer', 0xD710, 3, 8, 24, '8 slots: (x AND 7) x 24'),
    ('DrawSprite24x12 $B0E2', '$0F rock', 0xDB10, 3, 12, 36, '4 slots: (x AND 6) x 18'),
    ('DrawSprite24x16 $B10D', '$10 bomb crater', 0xDA50, 3, 16, 48, '4 slots: (x AND 6) x 24'),
    ('DrawSprite24x16Attr $B115', '$0B spinner', 0xDBA0, 3, 16, 48, '4 slots: (x AND 6) x 24, 3 x 3 cells'),
    ('DrawSprite32x16 $B184', '$64 green plant', 0xC450, 4, 16, 64, '4 slots: (x AND 6) x 32'),
    ('DrawSprite40x23 $B1C8', '$13 tank', 0xD7D0, 5, 23, 128, '4 slots: (x AND 6) x 64'),
]


def sprite_gfx(n):
    a = 0xB2D6 + 4 * n
    return MEM[a + 2] | MEM[a + 3] << 8


def fig_drawers():
    im, d = canvas(900)
    title(d, 'The ten drawers, each with slot 0 of one of its sprites (from SpriteTable $B2D6)',
          '4 screen pixels a Spectrum pixel; red lines = byte boundaries; W x H in bytes x lines')
    s = 4
    x, y = 16, 76
    rowh = 0
    col = 0
    for name, spr, g, wb, h, size, form in DRAWERS:
        if g is None:
            g = sprite_gfx(int(spr[1:3], 16))
        cellw = 500
        d.text((x, y), name, font=F, fill=K.TEXT)
        d.text((x, y + 20), '%s, $%04X: %d x %d, slot %d bytes' % (spr, g, wb, h, size), font=FS, fill=K.DIM)
        d.text((x, y + 38), form, font=FS, fill=K.DIM)
        bw, bh = draw_bits(d, x, y + 60, bits(g, wb, h), s)
        rowh = max(rowh, 60 + bh + 18)
        col += 1
        if col == 2:
            col = 0
            x = 16
            y += rowh
            rowh = 0
        else:
            x += cellw + 10
    save(im.crop((0, 0, W, y + 4)), 'drawers.png')


# ---------------------------------------------------------------- scroll
def strip_bits(addr):
    """34 columns of 32 bytes (one per line) -> 32 rows of 272 bits"""
    rows = [[0] * 272 for _ in range(32)]
    for c in range(34):
        for ln in range(32):
            v = MEM[addr + 32 * c + ln]
            for b in range(8):
                rows[ln][c * 8 + b] = (v >> (7 - b)) & 1
    return rows


def fig_scroll():
    im, d = canvas(720)
    title(d, 'The scenery strips: 34 columns of 8 pixels, 32 on the screen, the next fed in',
          '3 screen px a pixel. Blue: the 32 columns drawn at a life start. Yellow: the first feed')
    s = 3
    y = 80
    strips = [('HillsStrip $EBC0: the far band, lines 64-95', 0xEBC0, 'ScrollFarBand: 1 px a pass, a column every 8',
               (230, 80, 80)),
              ('MountainsStrip $E340: the middle band (scenery 0)', 0xE340, 'ScrollMiddleBand: 2 px a pass, a column every 4',
               (90, 210, 90)),
              ('MoonBaseStrip $E780: the middle band (scenery $FF)', 0xE780, 'ScrollMiddleBand: 2 px a pass, a column every 4',
               (230, 210, 60))]
    x0 = 16
    for name, a, how, col in strips:
        d.text((x0, y), name, font=F, fill=K.TEXT)
        d.text((x0 + 560, y), how, font=FS, fill=K.DIM)
        y += 24
        draw_bits(d, x0, y, strip_bits(a), s, fg=col, bytelines=False)
        d.rectangle([x0 - 1, y - 1, x0 + 256 * s, y + 32 * s], outline=(90, 160, 255), width=2)
        d.rectangle([x0 + 256 * s, y - 3, x0 + 264 * s, y + 32 * s + 2], outline=(255, 230, 90), width=2)
        for c in (0, 8, 16, 24, 31, 32, 33):
            d.text((x0 + c * 8 * s + 2, y + 32 * s + 4), str(c), font=FS, fill=K.DIM)
        y += 32 * s + 30
    d.text((x0, y), 'The road, lines 160-175: the 8-pixel columns GroundProfile $B232 points at (8 screen px a pixel)',
           font=F, fill=K.TEXT)
    y += 26
    x = x0
    for name, a in (('RoadFeed $A9AF', 0xA9AF), ('RoadFeedWallA $A9CF', 0xA9CF), ('RoadFeedWallB $A9EF', 0xA9EF)):
        g = [[(MEM[a + ln] >> (7 - b)) & 1 for b in range(8)] for ln in range(16)]
        d.text((x, y), name, font=FS, fill=K.TEXT)
        draw_bits(d, x, y + 20, g, 8, fg=(90, 210, 90))
        x += 200
    gx = x + 30
    d.text((gx, y), 'WallA then WallB, side by side: the V', font=FS, fill=K.TEXT)
    g = [[(MEM[0xA9CF + ln] >> (7 - b)) & 1 for b in range(8)] + [(MEM[0xA9EF + ln] >> (7 - b)) & 1 for b in range(8)]
         for ln in range(16)]
    draw_bits(d, gx, y + 20, g, 8, fg=(90, 210, 90))
    save(im.crop((0, 0, W, y + 20 + 16 * 8 + 12)), 'scroll.png')


# ---------------------------------------------------------------- erase
def fig_erase():
    rock = bits(0xDB10, 3, 12)
    im, d = canvas(560)
    title(d, 'Erase on a scrolling band: the rock (y $94, the near band) over three passes, from x $C0',
          'Each panel: 40 pixels of lines 148-159 around the rock, 6 screen pixels a Spectrum pixel; x labels in hex')
    s = 6
    passes = [('n: on the road', 0xC0, 0xBC, 0), ('n + 1: in the air', 0xBC, 0xB8, 2), ('n + 2: in the air', 0xB8, 0xB4, 2)]
    lo = 0xB0
    span = 40
    stages = ['1 erase at stored x', '2 draw at new x + step', '3 after the band roll']
    y = 76
    for name, old, new, step in passes:
        d.text((16, y), 'pass ' + name + ': stored x $%02X -> $%02X, step %d' % (old, new, step), font=F, fill=K.TEXT)
        y += 24
        x = 16
        for k, st in enumerate(stages):
            field = [[0] * span for _ in range(12)]

            def put(px, f=field):
                for yy in range(12):
                    for xx in range(24):
                        if rock[yy][xx] and 0 <= px - lo + xx < span:
                            f[yy][px - lo + xx] ^= 1
            if k == 0:
                pass  # erased: nothing left
            elif k == 1:
                put(new + step)
            else:
                put(new)
            draw_bits(d, x, y + 20, field, s, bytelines=False)
            d.text((x, y), st, font=FS, fill=K.TEXT)
            mark = {0: old, 1: new + step, 2: new}[k]
            mx = x + (mark - lo) * s
            d.line([mx, y + 18, mx, y + 20 + 12 * s + 4], fill=(255, 210, 70), width=2)
            d.text((mx + 3, y + 20 + 12 * s + 4), '$%02X' % mark, font=FS, fill=(255, 210, 70))
            x += span * s + 26
        y += 20 + 12 * s + 34
    save(im.crop((0, 0, W, y)), 'erase.png')


# ---------------------------------------------------------------- crater
def fig_crater():
    shot = Image.open(os.path.join(PLAY, 'i1-crater.png')).convert('RGB')
    crop = shot.crop((2 * 216, 2 * 152, 2 * 256, 2 * 184)).resize((40 * 8, 32 * 8), Image.NEAREST)
    im, d = canvas(470)
    title(d, 'A crater: two feed columns, back to back, against the screen (i1 frame 450)',
          '8 screen pixels a Spectrum pixel. Left: lines 160-175 of the two columns. Right: x 216-255, lines 152-183')
    y = 76
    x = 16
    for name, addr, a in (('WallA', '$A9CF', 0xA9CF), ('WallB', '$A9EF', 0xA9EF)):
        g = [[(MEM[a + ln] >> (7 - b)) & 1 for b in range(8)] for ln in range(16)]
        d.text((x, y), name, font=FS, fill=K.TEXT)
        d.text((x, y + 18), addr, font=FS, fill=K.DIM)
        draw_bits(d, x, y + 40, g, 8, fg=(90, 210, 90))
        x += 8 * 8 + 16
    tx = x + 6
    d.text((tx, y + 18), 'line  A  B', font=FS, fill=K.TEXT)
    for i in range(16):
        d.text((tx, y + 40 + i * 16 - 4), '%d  %02X %02X' % (160 + i, MEM[0xA9CF + i], MEM[0xA9EF + i]),
               font=FS, fill=K.DIM)
    cx = tx + 140
    d.text((cx, y + 18), 'the screen: i1-crater.png', font=FS, fill=K.TEXT)
    im.paste(crop, (cx, y + 40))
    d.line([cx - 4, y + 40 + 8 * 8, cx + 324, y + 40 + 8 * 8], fill=(255, 210, 70), width=1)
    d.text((cx + 330, y + 40 + 8 * 8 - 9), 'line 160: the edge', font=FS, fill=(255, 210, 70))
    d.line([cx - 4, y + 40 + 10 * 8 + 4, cx + 324, y + 40 + 10 * 8 + 4], fill=(90, 160, 255), width=1)
    d.text((cx + 330, y + 40 + 10 * 8 - 4), 'line 162: the probe', font=FS, fill=(90, 160, 255))
    d.text((cx + 330, y + 40 + 24 * 8 - 4), 'line 175: the bottom', font=FS, fill=K.DIM)
    save(im.crop((0, 0, W, y + 40 + 256 + 14)), 'crater.png')


# ---------------------------------------------------------------- wheels
def fig_wheels():
    im, d = canvas(520)
    title(d, 'The three wheels at a death: WheelPaths $AC31, 32 steps, 4 steps a pass (buggy at x $38)',
          '3 screen pixels a Spectrum pixel; one dot a step, the number every 4th step (a pass); y $97 is the start')
    s = 3
    ox, oy = 40, 90
    d.rectangle([ox, oy, ox + 256 * s, oy + 140 * s], outline=GRID)
    for yy in range(0, 141, 20):
        d.text((ox + 256 * s + 6, oy + yy * s - 8), 'line %d' % (40 + yy), font=FS, fill=K.DIM)
    d.line([ox, oy + (160 - 40) * s, ox + 256 * s, oy + (160 - 40) * s], fill=(230, 210, 60), width=2)
    d.text((ox + 4, oy + (160 - 40) * s + 4), 'line 160: the road', font=FS, fill=(230, 210, 60))
    bx = 0x38
    starts = [(0x97, bx + 1), (0x97, bx + 0x0A), (0x97, bx + 0x16)]
    cols = [(230, 90, 80), (90, 200, 120), (90, 150, 250)]
    names = ['left wheel $3C', 'middle wheel $3D', 'right wheel $3E']
    for w in range(3):
        y, x = starts[w]
        pts = [(x, y)]
        for st in range(32):
            a = 0xAC31 + 6 * st + 2 * w
            dy = MEM[a]
            dy = dy - 256 if dy > 127 else dy
            dx = MEM[a + 1]
            dx = dx - 256 if dx > 127 else dx
            y -= dy
            x += dx
            if not 0 <= x <= 255:
                break
            pts.append((x, y))
        xy = [(ox + px_ * s + 8 * s // 2 * 2, oy + (py - 40) * s) for px_, py in pts]
        d.line(xy, fill=cols[w], width=2)
        for i, p in enumerate(xy):
            d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=cols[w])
            if i % 4 == 0 and i:
                dx_ = (-16 if (i // 4) % 2 else 6) if w == 1 else 4
                d.text((p[0] + dx_, p[1] - 16 if w != 1 else p[1] - 8), str(i // 4), font=FS, fill=cols[w])
        d.text((ox + 6, oy + 6 + 20 * w), names[w], font=FS, fill=cols[w])
    save(im.crop((0, 0, W, oy + 140 * s + 12)), 'wheels.png')


# ---------------------------------------------------------------- shots
def fig_shots():
    im, d = canvas(400)
    title(d, 'One press of fire from the start (buggy x $38, y $92): both shots, pass by pass',
          '3 screen pixels a Spectrum pixel; x 32-200, lines 60-156; the buggy as drawn (slot 0 at x $38, line $89)')
    s = 3
    ox, oy = 16, 80
    x0, y0, wx, hy = 32, 60, 168, 97
    d.rectangle([ox, oy, ox + wx * s, oy + hy * s], fill=(0, 0, 0), outline=GRID)
    g = bits(0xE140, 5, 23)
    for yy in range(23):
        for xx in range(40):
            if g[yy][xx]:
                px_, py = 0x38 + xx - x0, 0x89 + yy - y0
                d.rectangle([ox + px_ * s, oy + py * s, ox + px_ * s + s - 1, oy + py * s + s - 1], fill=(200, 200, 200))
    for k in range(0, 16, 2):
        x = 0x58 + 6 * k
        if x - x0 + 6 > wx:
            break
        c = K.WRITE_FADE[min(k // 3, 5)]
        for i in range(6):
            px_, py = x + i - x0, 0x94 - y0
            d.rectangle([ox + px_ * s, oy + py * s, ox + px_ * s + s - 1, oy + py * s + s - 1], fill=c)
        d.text((ox + (x - x0) * s, oy + (0x94 - y0) * s + 6), str(k), font=FS, fill=c)
    for k in range(0, 13, 2):
        y = 0x84 - 4 * k
        c = K.WRITE_FADE[min(k // 2, 5)]
        for i in range(4):
            px_, py = 0x41 - x0, y + i - y0
            d.rectangle([ox + px_ * s, oy + py * s, ox + px_ * s + s - 1, oy + py * s + s - 1], fill=c)
        d.text((ox + (0x41 - x0) * s + 6, oy + (y - y0) * s - 2), str(k), font=FS, fill=c)
    tx = ox + wx * s + 20
    for i, t in enumerate(['forward: y $93, x $58 at the press,', 'drawn on line $94 (148), 6 px,',
                           '+6 a pass, freed at x $B8 (16 passes)',
                           '', 'upward: y $84, x $40 at the press,', 'drawn at x $41, 4 lines,',
                           '4 up a pass, ends above line $18', '', 'every 2nd pass shown;', 'number = passes after the press']):
        d.text((tx, oy + i * 22), t, font=FS, fill=K.TEXT)
    save(im.crop((0, 0, W, oy + hy * s + 12)), 'shots.png')


def fig_drawer():
    im, d = canvas(700)
    title(d, 'DrawSprite40x23 at work: sprite 0 at x $3A, y $89 (slot 1, $E1C0), line by line',
          'A model of the row loop $B1EC-$B20D from the tables: bytes 7-11 of lines $89-$9F, '
          '6 screen pixels a pixel')
    g = bits(0xE1C0, 5, 23)
    s_ = 6
    stops = [1, 8, 16, 23]
    x0, y0 = 16, 80
    pw = 40 * s_ + 12
    for k, n in enumerate(stops):
        x = x0 + k * (pw + 6)
        field = [[0] * 40 for _ in range(23)]
        for yy in range(n):
            field[yy] = list(g[yy])
        d.text((x, y0), 'after %d line%s' % (n, '' if n == 1 else 's'), font=FS, fill=K.TEXT)
        draw_bits(d, x, y0 + 22, field, s_)
        yy = n - 1
        d.rectangle([x - 2, y0 + 22 + yy * s_ - 2, x + 40 * s_ + 2, y0 + 22 + yy * s_ + s_ + 1],
                    outline=(255, 210, 70), width=2)
    y = y0 + 22 + 23 * s_ + 24
    d.text((16, y), 'Each turn of the loop (B\' counts 23 lines):', font=F, fill=K.TEXT)
    y += 26
    rows = []
    for ln in (0, 1, 7, 15, 22):
        line = 0x89 + ln
        te = 0xFC00 + 2 * line
        addr = MEM[te] | MEM[te + 1] << 8
        src = 0xE1C0 + 5 * ln
        rows.append('line %3d ($%02X): table $%04X = $%04X, + column 7 -> $%04X-$%04X; XOR %s from $%04X' % (
            line, line, te, addr, addr + 7, addr + 11, ' '.join('%02X' % MEM[src + i] for i in range(5)), src))
    for t in rows:
        d.text((16, y), t, font=FS, fill=K.DIM)
        y += 22
    y += 8
    d.text((16, y), 'The screen address jumps by $100 a line inside a cell and wraps at each cell edge:',
           font=FS, fill=K.TEXT)
    d.text((16, y + 22), 'the line table hides the layout.', font=FS, fill=K.TEXT)
    save(im.crop((0, 0, W, y + 52)), 'drawer.png')


def fig_blit():
    shot = Image.open(os.path.join(PLAY, 'a1-title.png')).convert('RGB')
    im, d = canvas(520)
    title(d, 'BlitRows $AFAB: TitleMoon copied byte for byte to the title screen',
          'Left: TitleMoon $6132, 10 bytes x 25 lines, 4 screen px a pixel. Right: a1-title.png (frame 20)')
    y = 76
    g = bits(0x6132, 10, 25)
    d.text((16, y), 'TitleMoon $6132-$622B', font=FS, fill=K.TEXT)
    draw_bits(d, 16, y + 24, g, 4)
    d.text((16, y + 24 + 100 + 10), 'BlitTop 24, BlitBottom 49,', font=FS, fill=K.DIM)
    d.text((16, y + 24 + 100 + 30), 'BlitX $58 (byte 11), width 10', font=FS, fill=K.DIM)
    sx = 16 + 320 + 30
    sc = 512 / 512
    im.paste(shot, (sx, y + 24))
    bx0, by0 = sx + 2 * 88, y + 24 + 2 * 24
    d.rectangle([bx0 - 2, by0 - 2, bx0 + 2 * 80 + 1, by0 + 2 * 25 + 1], outline=(255, 210, 70), width=2)
    d.text((sx + 4, y), 'a1-title.png: the copy at x 88-167, lines 24-48', font=FS, fill=(255, 210, 70))
    d.line([16 + 320, y + 24 + 50, bx0 - 2, by0 + 25], fill=(255, 210, 70), width=1)
    save(im.crop((0, 0, W, y + 24 + 384 + 12)), 'blit.png')


PASS = [('TuneToggle..HudPrintTime', 400), ('ScrollFarBand', 36996), ('BuggyErase/Update, wheels, shots', 1100),
        ('ObjectListRun + handlers + drawers', 6000), ('SceneryColoursRepaint', 5222), ('ScrollNearBand', 66598),
        ('ScrollMiddleBand', 71269), ('SpeedGovernor', None), ('ScrollRoad', 118924), ('HoldCheck', 81),
        ('SpeedGovernor', None)]


def fig_pass():
    im, d = canvas(580)
    title(d, 'One main-loop pass in T-states, routines in call order, at the three governor delays',
          'Own T a call from doc 12 (work/game window); interrupts and contention not included; ticks every 69 888 T')
    cols = {'ScrollFarBand': (230, 80, 80), 'ScrollMiddleBand': (90, 210, 90), 'ScrollNearBand': (60, 160, 90),
            'ScrollRoad': (230, 210, 60), 'SpeedGovernor': (150, 150, 170), 'SceneryColoursRepaint': (200, 110, 230)}
    scale = (W - 120) / 400000
    y = 84
    lx = 16
    for name in ('ScrollFarBand', 'SceneryColoursRepaint', 'ScrollNearBand', 'ScrollMiddleBand', 'ScrollRoad',
                 'SpeedGovernor'):
        if lx + 20 + FS.getlength(name) > W - 16:
            lx, y = 16, y + 22
        d.rectangle([lx, y + 3, lx + 14, y + 17], fill=cols[name])
        d.text((lx + 20, y), name, font=FS, fill=K.TEXT)
        lx += 20 + int(FS.getlength(name)) + 18
    d.rectangle([lx, y + 3, lx + 14, y + 17], fill=(90, 150, 250))
    d.text((lx + 20, y), 'the other routines', font=FS, fill=K.TEXT)
    y += 50
    for label, loops in (('forward (x > $38): 1 loop', 1), ('centre (x = $38): $02EE loops', 0x2EE),
                         ('back (x < $38): $05DC loops', 0x5DC)):
        d.text((16, y), label, font=F, fill=K.TEXT)
        y += 26
        x = 30
        tot = 0
        for name, t in PASS:
            if t is None:
                t = 26 * loops + 120
            w = t * scale
            c = cols.get(name, (90, 150, 250))
            d.rectangle([x, y, x + max(w, 1) - 1, y + 34], fill=c)
            if w > FS.getlength(name) + 8:
                d.text((x + 4, y + 8), name, font=FS, fill=(0, 0, 0))
            x += w
            tot += t
        d.text((x + 6, y + 8), '%d T' % tot, font=FS, fill=K.TEXT)
        for f in range(0, 8):
            tx = 30 + f * 69888 * scale
            if tx > W - 30:
                break
            d.line([tx, y + 36, tx, y + 44], fill=K.DIM)
            d.text((tx + 2, y + 44), '%d' % f, font=FS, fill=K.DIM)
        y += 90
    d.text((16, y), 'Numbers under the bars: frames of 69 888 T. Not drawn: the interrupt, about 16 600 T', font=FS,
           fill=K.DIM)
    d.text((16, y + 22), 'a frame in i1 with the tune notes, and whatever else makes the measured 7.05 frames a pass',
           font=FS, fill=K.DIM)
    d.text((16, y + 44), '(forward; i1 frames 300-4700, frames between two PassCount steps; centre 7.61, back 8.17).',
           font=FS, fill=K.DIM)
    save(im.crop((0, 0, W, y + 74)), 'pass.png')


def fig_odd():
    im, d = canvas(520)
    title(d, 'Two oddities in the sprite sheets, from the image',
          'Left: sprite $3C (wreck piece 1), 8 slots of 2 x 9 from $6350. Right: explosion frame 1, slots 0 and 1')
    s = 6
    y = 76
    x = 16
    for k in range(8):
        a = 0x6350 + 18 * k
        col = (230, 120, 90) if a < 0x638A else INK
        d.text((x, y), 'slot %d' % k, font=FS, fill=K.TEXT)
        d.text((x, y + 18), '$%04X' % a, font=FS, fill=K.DIM)
        draw_bits(d, x, y + 40, bits(a, 2, 9), s, fg=col)
        if a < 0x638A < a + 18:
            yy = (0x638A - a) // 2
            d.line([x - 2, y + 40 + yy * s, x + 16 * s + 2, y + 40 + yy * s], fill=(255, 210, 70), width=2)
        x += 16 * s + 6
        if k == 3:
            x = 16
            y += 40 + 9 * s + 20
    d.text((16, y + 40 + 9 * s + 12), 'orange = bytes of TitlePatrol (to $6389);', font=FS, fill=(230, 120, 90))
    d.text((16, y + 40 + 9 * s + 32), 'yellow line = $638A, the piece\'s own bytes', font=FS, fill=(255, 210, 70))
    x = 16 + 4 * (16 * s + 6) + 30
    y = 76
    for k, a in ((0, 0x6500), (1, 0x6580)):
        d.text((x, y), 'frame 1, slot %d' % k, font=FS, fill=K.TEXT)
        d.text((x, y + 18), '$%04X' % a, font=FS, fill=K.DIM)
        draw_bits(d, x, y + 40, bits(a, 5, 23), 5)
        x += 40 * 5 + 20
    save(im.crop((0, 0, W, max(76 + 40 + 23 * 5 + 20, 76 + 2 * (40 + 9 * s + 20) + 40))), 'odd.png')


FIGS = {'bands': fig_bands, 'slots': fig_slots, 'drawers': fig_drawers, 'scroll': fig_scroll, 'erase': fig_erase,
        'crater': fig_crater, 'drawer': fig_drawer, 'blit': fig_blit, 'pass': fig_pass, 'odd': fig_odd, 'wheels': fig_wheels, 'shots': fig_shots}

if __name__ == '__main__':
    names = sys.argv[1:] or ['all']
    for n in (FIGS if names == ['all'] else names):
        FIGS[n]()
