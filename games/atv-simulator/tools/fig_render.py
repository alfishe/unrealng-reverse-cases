#!/usr/bin/env python3
"""Doc 06's figures: the screen's layout in play, a sprite and its shifts, the ATV's and the rider's sprites, the cost
of a heavy pass by stage and the rotations measured against drawn.

    python3 tools/fig_render.py docs/img/render

layout.png       a screenshot of recording kb (frame 834, two players) with the areas the renderer writes: BufferP1
                 `$F03C` copied to `$4021` (lines 8-87), BufferP2 `$F71C` to `$48A1` (lines 104-183), the HUD
                 strips, the clock band and the side panel.
sprite-shift.png sprite 27 (`$1B`, the dune, 8 x 29, header `$9C58`) as its +3 byte says it lies: shift 0 to 7, each
                 computed the way ShiftLeftBy / ShiftRightBy move the bytes (RotateSpriteLeft / RotateSpriteRight one
                 bit, ShiftBytesRight / ShiftBytesLeft one byte when the shift wraps). Pixels from src/res/sprites.
atv-frames.png   the ATV's frames `$38`-`$4C` with their masks (AtvFrame + 1), the head-on frame `$5C`, the wheels
                 (`$4E`, `$4F`, `$79`, `$7A`) and the rider's frames with their masks (RiderFrame + 9 below 9, + 1
                 from 9). Pixels from src/res/sprites/game.png.
pass-cost.png    recording c1: a heavy pass, 81.1 % (Pass 15356:7833 to WaitFrames 15361:55067) by stage, from the entry
                 times of its routines in the trace; and three passes' rotation cost (PCs `$86C4-$8798`) split into the
                 measuring call PlaceItem makes before it sets SpriteX and the drawing calls
                 (work/docs/atB/rotcost.py). The numbers are in STAGES and ROT below.
"""
import csv
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
FRAME_T = 69888
SPR = os.path.join(CASE, 'src', 'res', 'sprites')


def sheet():
    im = Image.open(os.path.join(SPR, 'game.png'))
    rows = {}
    for r in csv.DictReader(open(os.path.join(SPR, 'game.csv'))):
        if r['kind'] != 'sprite':
            continue
        for n in r['numbers'].split():
            rows[int(n)] = r
    return im, rows


def bits(im, r):
    """The sprite's pixels as rows of 0/1 (index 1 ink), width x 8 wide"""
    x, y, w, h = int(r['x']), int(r['y']), int(r['width']) * 8, int(r['height'])
    px = im.load()
    return [[1 if px[x + i, y + j] == 1 else 0 for i in range(w)] for j in range(h)]


def draw_bits(d, rows, x0, y0, s, ink=(235, 235, 240), paper=(40, 40, 52), grid=True):
    for j, row in enumerate(rows):
        for i, b in enumerate(row):
            d.rectangle((x0 + i * s, y0 + j * s, x0 + i * s + s - 1, y0 + j * s + s - 1), fill=ink if b else paper)
    if grid:
        w = len(rows[0])
        for i in range(0, w + 1, 8):
            d.line((x0 + i * s, y0, x0 + i * s, y0 + len(rows) * s), fill=(90, 90, 110))


def layout(path):
    shot = Image.open(os.path.join(CASE, 'docs', 'img', 'play', 'kb-000834-split-screen.png')).convert('RGB')
    S = 2  # the shot is 512 x 384: 2 pixels a Spectrum pixel; drawn at 1.25 x that
    k = 1.25
    shot = shot.resize((int(512 * k), int(384 * k)), Image.NEAREST)
    H = 560
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    big, mid = K.font(15), K.font(12)
    d.text((14, 10), 'The screen in play: two buffers copied into two windows, the rest drawn on the screen',
           fill=K.TEXT, font=big)
    ox, oy = 14, 40
    im.paste(shot, (ox, oy))

    def box(x1, y1, x2, y2):  # Spectrum pixels
        f = S * k
        return (ox + x1 * f, oy + y1 * f, ox + (x2 + 1) * f - 1, oy + (y2 + 1) * f - 1)
    areas = [
        ((8, 8, 183, 87), (240, 90, 80), 'BufferP1 $F03C, 22 x 80 bytes -> $4021 (lines 8-87)',
         'CopyBufferP1 $8CDA: CopyLines, 1 760 LDI'),
        ((8, 104, 183, 183), (90, 200, 220), 'BufferP2 $F71C -> $48A1 (lines 104-183)',
         'CopyBufferP2 $8CE6: the same, two players only'),
        ((8, 0, 183, 7), (240, 200, 70), 'P1 HUD (HudY $BE): SPEED and FUEL bars',
         'SpeedBar, FuelBarStep: on the screen'),
        ((8, 184, 183, 191), (240, 200, 70), 'P2 HUD (HudY 6)', 'the same bars, bottom line'),
        ((32, 88, 159, 103), (120, 220, 120), 'the clock band: ClockTick, x $60 y $66',
         'BigDigit / ClockDigit: ModeCopyScreen'),
        ((200, 0, 255, 191), (200, 110, 230), 'the side panel: SCORE 1 and 2',
         'ShowScore: ModeXorScreen, digits only'),
    ]
    tx = ox + int(512 * k) + 20
    ty = 50
    for n, ((x1, y1, x2, y2), col, t1, t2) in enumerate(areas, 1):
        b = box(x1, y1, x2, y2)
        d.rectangle(b, outline=col, width=3)
        cx, cy = (b[0] + b[2]) / 2 if n not in (5, 6) else b[0] + 16, (b[1] + b[3]) / 2 if n not in (3, 4) else b[1] + 4
        if n in (3, 4):
            cx = b[0] + 250
        d.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=col)
        d.text((cx - 4, cy - 8), str(n), fill=(0, 0, 0), font=mid)
        d.ellipse((tx, ty, tx + 22, ty + 22), fill=col)
        d.text((tx + 7, ty + 3), str(n), fill=(0, 0, 0), font=mid)
        d.text((tx + 30, ty), t1.replace(' -> ', '\n-> ') if len(t1) > 44 else t1, fill=col, font=mid)
        d.text((tx + 30, ty + 36), t2, fill=K.DIM, font=mid)
        ty += 78
    d.text((14, H - 26), 'Recording kb, frame 834 (two players). One player: the bottom window shows the trail\'s '
           'name and nothing is copied there.', fill=K.DIM, font=mid)
    im.save(path)


def shifted(rows, s):
    """The sprite's rows as they lie at shift s: s bits to the right inside the width (the last byte has room)"""
    out = []
    for row in rows:
        w = len(row)
        out.append([0] * s + row[:w - s])
    return out


def sprite_shift(path, im, rows):
    r = rows[27]
    px = bits(im, r)
    H = 560
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    big, mid = K.font(15), K.font(12)
    d.text((14, 10), 'Sprite 27 ($1B, a dune\'s slope): a 4-byte header, then 8 x 29 bytes; +3 says how far right '
           'they lie', fill=K.TEXT, font=big)
    # header
    hx, hy = 14, 44
    fields = [('+0', '$08', 'width (bytes)'), ('+1', '$1D', 'height (29 lines)'), ('+2', '$37', 'advance (55)'),
              ('+3', 's', 'shift now (0 to 7)')]
    for i, (o, v, t) in enumerate(fields):
        x = hx + i * 200
        d.rounded_rectangle((x, hy, x + 190, hy + 50), 6, fill=K.PANEL, outline=(70, 70, 85))
        d.text((x + 8, hy + 6), f'$9C58 {o}  {v}', fill=(240, 200, 70), font=mid)
        d.text((x + 8, hy + 26), t, fill=K.TEXT, font=mid)
    d.text((hx + 810, hy + 6), '+4: the bytes, a line', fill=K.TEXT, font=mid)
    d.text((hx + 810, hy + 26), 'at a time, bit 7 left', fill=K.TEXT, font=mid)
    s = 3
    x0, y0 = 14, 116
    for sh in range(8):
        col, row = sh % 4, sh // 4
        x, y = x0 + col * 258, y0 + row * 180
        draw_bits(d, shifted(px, sh), x, y + 22, s)
        d.text((x, y), f'shift {sh}', fill=(240, 200, 70) if sh in (0, 4) else K.TEXT, font=mid)
    d.text((14, H - 66), 'A step of 1 is one RotateSpriteLeft / RotateSpriteRight over all 232 bytes (about 9 500 T '
           'here).', fill=K.DIM, font=mid)
    d.text((14, H - 46), 'A wrap (0 to 7, 7 to 0) adds ShiftBytesRight / ShiftBytesLeft. Grid: a line a byte.',
           fill=K.DIM, font=mid)
    d.text((14, H - 26), 'c1 15357:41623: four RotateSpriteLeft calls take it from shift 4 to 0 (yellow). Pixels: '
           'src/res/sprites/game.png.', fill=K.DIM, font=mid)
    out.save(path)


def atv_frames(path, im, rows):
    groups = [
        ('the ATV, AtvFrame $38-$4C (body) and + 1 (mask): upright, then the front rising', list(range(56, 78))),
        ('head-on $5C / $5D (the turn), the wheels $4E $4F $79 $7A', [92, 93, 78, 79, 121, 122]),
        ('the rider: frames 0-8 and their masks 9-17, riding $59 / $5A', list(range(0, 18)) + [89, 90]),
    ]
    s = 2
    H = 760
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    big, mid, small = K.font(15), K.font(12), K.font(11)
    d.text((14, 10), 'The ATV and the rider: every sprite DrawAtv and DrawRider use (2 x, a grid line a byte)',
           fill=K.TEXT, font=big)
    y = 40
    for title, nums in groups:
        d.text((14, y), title, fill=(240, 200, 70), font=mid)
        y += 22
        x = 14
        rowh = 0
        for n in nums:
            r = rows[n]
            px = bits(im, r)
            w, h = len(px[0]) * s, len(px) * s
            if x + w > W - 14:
                x = 14
                y += rowh + 24
                rowh = 0
            draw_bits(d, px, x, y + 16, s, grid=False)
            d.text((x, y), f'${n:02X}', fill=K.TEXT, font=small)
            x += w + 14
            rowh = max(rowh, h + 16)
        y += rowh + 30
    out.save(path)


# c1, a heavy pass (81.1 %; the heaviest, 15412, is 91.3 %, doc 04 4.7): entry times of its stages (frame, T) from the trace (work/docs/atB/tr.py)
STAGES = [
    ('Pass, clock', (15356, 7833)),
    ('ClearBufferP1', (15356, 12634)),
    ('Update: lists A and B, physics', (15356, 24829)),
    ('FlushDeferredB', (15359, 41287)),
    ('DrawAtvAndRider', (15359, 41335)),
    ('FlushDeferredA (START sign)', (15360, 23378)),
    ('finish, Advance, score, fuel', (15361, 329)),
    ('CopyBufferP1', (15361, 12149)),
    ('FlushAttrs', (15361, 53171)),
    ('end (WaitFrames)', (15361, 55067)),
]
# c1, rotation cost (PC $86C4-$8798) in T: pass start frame, the whole pass, the measuring call, the drawing calls
ROT = [('15055 (light)', 481790, 72493, 13582), ('15349', 489025, 142944, 10705),
       ('15356 (heavy)', 489383, 121974, 56450)]


def pass_cost(path):
    H = 560
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    big, mid, small = K.font(15), K.font(12), K.font(11)
    d.text((14, 10), 'c1, a heavy pass (15356, 81.1 %) by stage (T), and where the sprite rotations go', fill=K.TEXT, font=big)
    t = [f * FRAME_T + tt for _, (f, tt) in STAGES]
    t0, t1 = t[0], t[-1]
    x0, x1, y = 14, W - 14, 50
    scale = (x1 - x0) / (t1 - t0)
    cols = [(120, 120, 135), (90, 160, 255), (80, 200, 110), (200, 110, 230), (240, 90, 80), (240, 200, 70),
            (90, 200, 220), (230, 140, 60), (160, 160, 175)]
    for i in range(len(STAGES) - 1):
        a, b = x0 + (t[i] - t0) * scale, x0 + (t[i + 1] - t0) * scale
        d.rectangle((a, y, max(a + 1, b - 1), y + 40), fill=cols[i])
    for f in range(15357, 15362):
        x = x0 + (f * FRAME_T - t0) * scale
        d.line((x, y - 6, x, y + 46), fill=K.TEXT)
        d.text((x + 3, y - 18), f'frame {f}', fill=K.DIM, font=small)
    ly = y + 56
    for i in range(len(STAGES) - 1):
        cx, cy = 14 + (i % 3) * 345, ly + (i // 3) * 22
        d.rectangle((cx, cy + 3, cx + 12, cy + 15), fill=cols[i])
        n = f'{t[i + 1] - t[i]:,}'.replace(',', ' ')
        d.text((cx + 18, cy), f'{STAGES[i][0]}: {n} T', fill=K.TEXT, font=small)
    d.text((14, ly + 72), f'Pass 15356:7833 to 15361:55067 = {t1 - t0:,} T of work (5.7 frames); '
           'the pass ends with the 7th frame.'.replace(',', ' '), fill=K.DIM, font=mid)
    # rotation bars
    by = 260
    d.text((14, by - 26), 'Rotation (PC $86C4-$8798) per pass: the measuring call in PlaceItem (red) against the '
           'drawing calls (green), T', fill=K.TEXT, font=mid)
    bx0, bw = 200, W - 214
    m = max(r[1] for r in ROT)
    for i, (name, total, meas, draw) in enumerate(ROT):
        yy = by + i * 90
        d.text((14, yy + 8), f'pass {name}', fill=K.TEXT, font=mid)
        d.rectangle((bx0, yy, bx0 + bw * total / m, yy + 36), fill=K.PANEL, outline=(70, 70, 85))
        a = bx0 + bw * meas / m
        d.rectangle((bx0, yy, a, yy + 36), fill=(200, 70, 60))
        d.rectangle((a, yy, a + bw * draw / m, yy + 36), fill=(70, 180, 90))
        d.text((bx0 + 6, yy + 40), f'measure {meas:,} T ({100 * meas / total:.1f} %), draw {draw:,} T '
               f'({100 * draw / total:.1f} %), pass {total:,} T'.replace(',', ' '), fill=K.DIM, font=small)
    d.text((14, H - 26), 'Command: python3 tools/fig_render.py docs/img/render (numbers from the c1 trace, '
           'work/docs/atB/rotcost.py).', fill=K.DIM, font=small)
    im.save(path)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CASE, 'docs', 'img', 'render')
    os.makedirs(out, exist_ok=True)
    im, rows = sheet()
    layout(os.path.join(out, 'layout.png'))
    sprite_shift(os.path.join(out, 'sprite-shift.png'), im, rows)
    atv_frames(os.path.join(out, 'atv-frames.png'), im, rows)
    pass_cost(os.path.join(out, 'pass-cost.png'))


if __name__ == '__main__':
    main()
