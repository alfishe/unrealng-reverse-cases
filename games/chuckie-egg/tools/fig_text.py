#!/usr/bin/env python3
"""The figures of doc 08 (HUD and text), drawn from the image and from the screens and events of the recordings.

    python3 tools/fig_text.py font      --out docs/img/text/font.png
    python3 tools/fig_text.py hud       --screen work/stage1/rec/levels-1-3/screens/000500.png --out docs/img/text/hud.png
    python3 tools/fig_text.py pages     --out docs/img/text/pages.png
    python3 tools/fig_text.py strings   --out docs/img/text/strings.png
    python3 tools/fig_text.py countdown --events work/docs/ceD/l13-events.json --out docs/img/text/countdown.png
    python3 tools/fig_text.py hiscore   --out docs/img/text/hiscore.png

The image is build/game.bin (`sh tools/build.sh`), the game block `$8214-$CBE7`. Every glyph is drawn from
CharacterSet `$84F0` + 8 x code, top row first, as PrintChar `$9C40` copies it. A screen file is one of the 256 x 192
PNGs `re_session.py capture` saves under work/stage1/rec/<recording>/screens/ (the screen at the start of the frame of
its name). The events file is written by tools/sound_events.py.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

GAME = os.path.join(CASE, 'build', 'game.bin')
ORG = 0x8214
W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)
CHARSET = 0x84F0
COLS = [(214, 39, 40), (31, 119, 180), (44, 160, 44), (148, 103, 189), (255, 127, 14), (140, 86, 75),
        (227, 119, 194), (23, 190, 207), (120, 120, 30)]
PAPER, INK = (0, 0, 0), (215, 215, 215)

# the code groups of the character set (src/game/graphics.asm)
GROUPS = [(0x00, 0x05, 'map cells'), (0x06, 0x0A, 'other'), (0x0B, 0x1D, 'HUD labels'), (0x1E, 0x1F, 'other'),
          (0x20, 0x5F, 'font, thin capitals'), (0x60, 0x7F, 'bold capitals'), (0x80, 0x8A, 'big CHUCKIE EGG'), (0x8B, 0x8E, 'other'),
          (0x8F, 0x96, 'A+F logo'), (0x97, 0x9A, 'key names'), (0x9B, 0x9D, 'LEVEL label'),
          (0x9E, 0xA7, 'HUD digits'), (0xA8, 0xB5, 'cage'), (0xB6, 0xB6, 'life'), (0xB7, 0xB7, 'cursor'),
          (0xB8, 0xCB, 'A&F lettering')]
GROUP_COLOURS = {'map cells': (255, 220, 170), 'HUD labels': (200, 230, 255), 'font, thin capitals': (235, 235, 235),
                 'bold capitals': (245, 225, 245), 'big CHUCKIE EGG': (255, 240, 170), 'A+F logo': (210, 245, 210),
                 'key names': (230, 215, 255), 'LEVEL label': (200, 230, 255), 'HUD digits': (180, 215, 255),
                 'cage': (255, 205, 205), 'life': (255, 190, 150), 'cursor': (255, 190, 150),
                 'A&F lettering': (210, 245, 210), 'other': (225, 225, 225)}


def game():
    data = open(GAME, 'rb').read()
    mem = bytearray(0x10000)
    mem[ORG:ORG + len(data)] = data
    return mem


def glyph(mem, code):
    return mem[CHARSET + 8 * code:CHARSET + 8 * code + 8]


def draw_glyph(img, mem, code, x, y, scale, ink=INK, paper=PAPER):
    px = img.load()
    for r, b in enumerate(glyph(mem, code)):
        for c in range(8):
            colour = ink if b >> (7 - c) & 1 else paper
            for dy in range(scale):
                for dx in range(scale):
                    px[x + c * scale + dx, y + r * scale + dy] = colour


def draw_text(img, mem, codes, x, y, scale, ink=INK, paper=PAPER):
    for i, code in enumerate(codes):
        draw_glyph(img, mem, code, x + 8 * scale * i, y, scale, ink, paper)


def group_of(code):
    for lo, hi, name in GROUPS:
        if lo <= code <= hi:
            return name
    return 'other'


def fig_font(a):
    mem = game()
    small, label, title = K.font(13), K.font(15), K.font(19)
    per_row, cw, scale = 16, 64, 5
    rows = (0xCC + per_row - 1) // per_row
    ch = 8 * scale + 30
    top, legend_h = 70, 92
    img = Image.new('RGB', (W, top + rows * ch + legend_h), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 12), 'The character set: codes 0-$CB, glyph at CharacterSet $84F0 + 8 x code', font=title, fill=FG)
    d.text((14, 40), 'Each cell: the code, then its eight bytes top row first; HudCharacters $89E0 is code $9E',
           font=label, fill=DIM)
    x0 = (W - per_row * cw) // 2
    for code in range(0xCC):
        r, c = divmod(code, per_row)
        x, y = x0 + c * cw, top + r * ch
        d.rectangle([x + 2, y, x + cw - 3, y + ch - 4], fill=GROUP_COLOURS[group_of(code)])
        d.text((x + 6, y + 2), f'${code:02X}', font=small, fill=FG)
        gx = x + (cw - 8 * scale) // 2
        d.rectangle([gx - 3, y + 17, gx + 8 * scale + 2, y + 22 + 8 * scale], fill=PAPER)
        draw_glyph(img, mem, code, gx, y + 20, scale, ink=(255, 255, 255))
    ly = top + rows * ch + 10
    names = [n for n in dict.fromkeys(g[2] for g in GROUPS)]
    lx = 14
    for n in names:
        tw = d.textlength(n, font=label)
        if lx + 26 + tw > W - 10:
            lx, ly = 14, ly + 26
        d.rectangle([lx, ly + 2, lx + 18, ly + 18], fill=GROUP_COLOURS[n], outline=GRID)
        d.text((lx + 24, ly + 1), n, font=label, fill=FG)
        lx += 24 + tw + 22
    img.save(a.out)


def fig_hud(a):
    screen = Image.open(a.screen).convert('RGB')
    scale = 4
    crop = screen.crop((0, 0, 256, 24)).resize((256 * scale, 24 * scale), Image.NEAREST)
    label, small, title = K.font(15), K.font(13), K.font(19)
    x0, y0 = (W - 256 * scale) // 2, 78
    img = Image.new('RGB', (W, 440), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 12), 'The HUD: screen rows 0-2, every field by its columns (level 1, one player)', font=title, fill=FG)
    d.text((14, 40), f'{os.path.relpath(a.screen, CASE)}, the screen at the start of the frame, x {scale}',
           font=label, fill=DIM)
    img.paste(crop, (x0, y0))
    cw = 8 * scale
    for c in range(33):
        d.line([x0 + c * cw, y0 - 6, x0 + c * cw, y0], fill=DIM)
    for c in range(0, 32, 2):
        d.text((x0 + c * cw + 8, y0 - 24), str(c), font=small, fill=DIM)
    for r in range(3):
        d.text((x0 - 26 if x0 > 26 else 2, y0 + r * cw + 8), str(r), font=small, fill=DIM)
    # the fields: (row, first column, last column, name, writer, label lane)
    fields = [(0, 0, 2, 'SCORE label', 'HudText $9764: $0B-$0D', 0),
              (0, 5, 10, 'player 1 score', 'AddScore $A3A7 at $4005', 1),
              (0, 12, 17, 'player 2 score', 'at $400C (+7)', 0),
              (0, 19, 24, 'player 3 score', 'at $4013', 1), (0, 26, 31, 'player 4 score', 'at $401A', 0),
              (1, 5, 10, 'spare lives', 'one $B6 a life, row 1', 2),
              (2, 0, 3, 'PLAYER', '$0E-$11', 3), (2, 4, 4, 'player', 'HudPlayer $976B', 4),
              (2, 7, 9, 'LEVEL', '$9B-$9D', 3), (2, 11, 12, 'level', 'HudLevel $9772, BCD', 4),
              (2, 15, 17, 'BONUS', '$1B-$1D', 3), (2, 19, 22, 'bonus', 'CountDown B=0, $4053', 4),
              (2, 25, 27, 'TIME', '$12-$14', 3), (2, 29, 31, 'time', 'CountDown B=1, $405D', 4)]
    yb = y0 + 3 * cw + 14
    for i, (row, c0, c1, name, writer, lane) in enumerate(fields):
        col = COLS[i % len(COLS)]
        xa, xb = x0 + c0 * cw + 2, x0 + (c1 + 1) * cw - 2
        d.rectangle([xa, y0 + row * cw, xb, y0 + (row + 1) * cw - 1], outline=col, width=2)
        y = yb + lane * 48
        tw = max(d.textlength(name, font=label), d.textlength(writer, font=small))
        tx = min(xa, W - 12 - tw)
        d.line([(xa + xb) // 2, y0 + (row + 1) * cw, (xa + xb) // 2, y], fill=col, width=1)
        d.text((tx, y + 2), name, font=label, fill=col)
        d.text((tx, y + 21), writer, font=small, fill=DIM)
    img.save(a.out)


def page(mem, base, width, rows, bottom_first):
    """the rows of a stored page, top row of the screen first"""
    out = [list(mem[base + width * k:base + width * (k + 1)]) for k in range(rows)]
    return out[::-1] if bottom_first else out


def fig_pages(a):
    mem = game()
    label, small, title = K.font(15), K.font(13), K.font(19)
    scale = 2
    cell = 8 * scale
    img = Image.new('RGB', (W, 520), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 12), 'Three pages as the bytes lay them out (the game font, two pixels a pixel)', font=title, fill=FG)
    panels = [('TitleText $9630', 'TitlePage $A420: 22 rows of 14, H 2-23', 0x9630, 14, 22, True, 1),
              ('InstructionsText $8390', 'InstructionsPage $A4C8: 11 rows of 32, H 3, 5 .. 23', 0x8390, 32, 11,
               True, 2),
              ('Congratulations $AD67', 'EnterHiScore $A80C: 11 rows of 15, H 23, 21 .. 3', 0xAD67, 15, 11, False, 2)]
    x = 14
    for name, how, base, width, rows, bottom_first, step in panels:
        y0 = 60
        d.text((x, y0), name, font=label, fill=FG)
        d.text((x, y0 + 20), how, font=small, fill=DIM)
        y = y0 + 46
        d.rectangle([x - 2, y - 2, x + width * cell + 1, y + 22 * cell + 1], fill=PAPER)
        for k, row in enumerate(page(mem, base, width, rows, bottom_first)):
            draw_text(img, mem, row, x, y + step * k * cell, scale)
        d.text((x, y + 22 * cell + 10), 'stored bottom row first' if bottom_first else 'stored top row first',
               font=small, fill=DIM)
        x += width * cell + 26
    img.save(a.out)


def fig_strings(a):
    mem = game()
    label, small, title = K.font(15), K.font(13), K.font(19)
    scale = 2
    cell = 8 * scale
    items = [('HiScoreTitle', 0xABF2, 16), ('RedefinePrompt', 0xAC02, 32), ('KeyLabels', 0xAC22, 50),
             ('KeyNames', 0xAC54, 40), ('TitleScroller', 0xAC7C, 78), ('InstructionsScroller', 0xACCA, 87),
             ('PlayersPrompt', 0xAD21, 30), ('GameOverMessage', 0xAD3F, 10), ('PlayerMessage', 0xAD49, 9),
             ('LevelMessage', 0xAD52, 8), ('OutOfTimeMessage', 0xAD5A, 13), ('HudText', 0x9764, 35)]
    per_line = 52
    lines = []
    for name, base, n in items:
        codes = list(mem[base:base + n])
        chunks = [codes[i:i + per_line] for i in range(0, n, per_line)]
        lines.append((name, base, n, chunks))
    h = 60 + sum(30 + len(ch) * (cell + 4) for _, _, _, ch in lines) + 10
    img = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 12), 'MenuTexts $ABF2-$AD66 and HudText $9764 in the game font, byte by byte', font=title, fill=FG)
    y = 50
    for name, base, n, chunks in lines:
        d.text((14, y + 4), f'{name}  ${base:04X}, {n} bytes', font=label, fill=FG)
        y += 26
        for ch in chunks:
            d.rectangle([14, y - 1, 14 + len(ch) * cell, y + cell], fill=PAPER)
            draw_text(img, mem, ch, 14, y, scale)
            y += cell + 4
        y += 4
    img.save(a.out)


def fig_countdown(a):
    ev = json.load(open(a.events))
    frame_t = ev['frame_t'] or 69888
    label, small, title = K.font(15), K.font(13), K.font(19)
    img = Image.new('RGB', (W, 700), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 12), 'Level 1 of levels-1-3: TIME and BONUS counted down by CountDown $A1B8', font=title, fill=FG)
    d.text((14, 40), 'One dot a call, at its frame and T-state (tools/sound_events.py); the value is what the HUD shows '
           'after the call', font=label, fill=DIM)
    cd = ev['countdown']
    first_level_end = min(x[0] for x in cd if x[3] == 0xA67D)
    f0 = min(x[0] for x in cd)
    # panel 1: the whole of level 1 in play
    px0, px1, py0, py1 = 80, W - 20, 90, 380
    fa, fb = f0 - 20, first_level_end + 30
    d.rectangle([px0, py0, px1, py1], outline=GRID)

    def fx(f):
        return px0 + (f - fa) / (fb - fa) * (px1 - px0)

    def vy(v):
        return py1 - v / 1000 * (py1 - py0)
    for v in range(0, 1001, 200):
        d.line([px0, vy(v), px1, vy(v)], fill=GRID)
        d.text((px0 - 44, vy(v) - 8), str(v), font=small, fill=DIM)
    for f in range((fa // 200 + 1) * 200, fb, 200):
        d.line([fx(f), py1, fx(f), py1 + 5], fill=DIM)
        d.text((fx(f) - 16, py1 + 8), str(f), font=small, fill=DIM)
    time_v, bonus_v = 900, 1000
    tpts, bpts, end_pts = [], [], []
    for f, t, b, caller in cd:
        if f > fb:
            break
        at = f + t / frame_t
        if b == 1:
            time_v -= 1
            tpts.append((at, time_v))
        elif caller == 0xA67D:
            bonus_v -= 10
            end_pts.append((at, bonus_v))
        else:
            bonus_v -= 10
            bpts.append((at, bonus_v))
    for pts, col, r in ((tpts, COLS[1], 1), (bpts, COLS[0], 2), (end_pts, COLS[2], 2)):
        for at, v in pts:
            d.ellipse([fx(at) - r, vy(v) - r, fx(at) + r, vy(v) + r], fill=col)
    for f, t, b, caller in ev['addscore']:
        if caller == 0x9A1E and fa <= f <= fb:
            d.line([fx(f + t / frame_t), py0, fx(f + t / frame_t), py1], fill=(150, 200, 150), width=1)
    lx = px0 + 330
    d.text((lx, py0 + 186), 'green lines: grain taken (AddScore B = 5 from $9A1E):', font=label, fill=(60, 140, 60))
    d.text((lx, py0 + 206), 'BonusDelay and TimeDelay = $FF, both clocks stop 255 slow ticks', font=label,
           fill=(60, 140, 60))
    d.text((lx, py0 + 126), f'TIME (B = 1, from $992C): {len(tpts)} steps of 1', font=label, fill=COLS[1])
    d.text((lx, py0 + 146), f'BONUS in play (B = 0, from $98F6): {len(bpts)} steps of 10', font=label,
           fill=COLS[0])
    d.text((lx, py0 + 166), f'BONUS at the level end (PlayLevelBonus, $A67D): {len(end_pts)} steps',
           font=label, fill=COLS[2])
    d.text((px1 - 60, py1 + 26), 'frame', font=small, fill=DIM)
    # panel 2: the level end, zoomed
    qx0, qx1, qy0, qy1 = 80, W - 20, 450, 650
    ends = [x for x in cd if x[3] == 0xA67D and x[0] <= first_level_end + 30]
    ea, eb = ends[0][0], ends[-1][0] + 1
    d.rectangle([qx0, qy0, qx1, qy1], outline=GRID)
    d.text((14, qy0 - 34), f'The level end zoomed: frames {ea}-{eb - 1}, one CountDown(0) + AddScore(1) + '
           'Beep(H 30, L 4) a step', font=label, fill=FG)
    top = end_pts[0][1] + 10 if end_pts else 900

    def gx(at):
        return qx0 + (at - ea) / (eb - ea) * (qx1 - qx0)

    def gy(v):
        return qy1 - v / max(10, top) * (qy1 - qy0)
    for f in range(ea, eb + 1):
        d.line([gx(f), qy0, gx(f), qy1], fill=GRID)
        if f < eb:
            n = sum(1 for x in ends if x[0] == f)
            d.text((gx(f) + 6, qy1 + 6), f'{f}: {n}', font=small, fill=DIM)
    for at, v in end_pts:
        v = max(v, 0)
        d.ellipse([gx(at) - 2, gy(v) - 2, gx(at) + 2, gy(v) + 2], fill=COLS[2])
    d.text((qx1 - 380, qy0 + 10), f'BONUS {top} -> past 000: {len(end_pts)} steps', font=label, fill=COLS[2])
    d.text((qx1 - 380, qy0 + 30), 'the last step goes under 000 and still pays 10', font=small, fill=DIM)
    d.text((qx0, qy1 + 26), 'frame: steps in that frame', font=small, fill=DIM)
    img.save(a.out)


def fig_hiscore(a):
    mem = game()
    label, small, title = K.font(15), K.font(13), K.font(19)
    img = Image.new('RGB', (W, 560), BG)
    d = ImageDraw.Draw(img)
    d.text((14, 12), 'HiScoreTable $97AF: ten entries of 16 bytes, the best first', font=title, fill=FG)
    # the record layout, one box a byte
    bx, by, bw = 14, 60, 62
    parts = [(0, 1, 'space', COLS[5]), (1, 9, 'name: 8 codes (here the A+F logo $8F-$96)', COLS[2]),
             (9, 10, 'space', COLS[5]), (10, 16, 'score: 6 ASCII digits $30-$39', COLS[1])]
    entry = mem[0x97AF:0x97BF]
    for i in range(16):
        x = bx + i * bw + 8
        d.rectangle([x, by, x + bw - 4, by + 72], outline=GRID, fill=(255, 255, 255))
        d.text((x + 4, by + 4), f'+{i}', font=small, fill=DIM)
        d.text((x + 4, by + 22), f'{entry[i]:02X}', font=label, fill=FG)
        g = Image.new('RGB', (24, 24), PAPER)
        draw_glyph(g, mem, entry[i], 0, 0, 3)
        img.paste(g, (x + 30, by + 42))
    for s, e, name, col in parts:
        xa, xb = bx + s * bw + 8, bx + e * bw + 4
        d.line([xa, by + 82, xb, by + 82], fill=col, width=3)
        d.text((xa, by + 88), name, font=small, fill=col)
    d.text((14, by + 116), 'CompareScore reads the digits at $97B9 + 16 k; DrawHiScores prints byte 0-15 of entry k '
           'at H 21 - 2 k, L 16-31', font=label, fill=FG)
    # an insert at place 3: the shift down
    y = by + 160
    d.text((14, y), 'An insert at place k (EnterHiScore $A80C): LDDR moves entries k .. 8 down one, entry 9 is lost; '
           'bytes 0-9', font=label, fill=FG)
    d.text((14, y + 20), 'are set to code 0 (blank), the six digits copied to 10-15; the name is typed into bytes 0-8 '
           '(the cursor $B7 from column 16)', font=label, fill=FG)
    names = ['HARRY', 'HEN', 'DUCK', 'EGG', 'GRAIN', 'LIFT', 'CAGE', 'LADDER', 'BONUS', 'TIME']
    scores = [52300, 41000, 30120, 22000, 15000, 9000, 6000, 3000, 2000, 1000]
    new = ('CE1', 27450)
    k = next(i for i, s in enumerate(scores) if new[1] > s)
    after_names = names[:k] + [new[0]] + names[k:9]
    after_scores = scores[:k] + [new[1]] + scores[k:9]
    cell = 16
    for col_i, (head, ns, ss) in enumerate((('before', names, scores), ('after the insert', after_names,
                                                                         after_scores))):
        x = 60 + col_i * 500
        d.text((x, y + 56), head, font=label, fill=FG)
        for r in range(10):
            yy = y + 82 + r * 26
            text = f'{ns[r]:<10}{ss[r]:06d}'
            codes = [ord(ch) for ch in text]
            d.rectangle([x - 1, yy - 1, x + 16 * cell, yy + cell], fill=PAPER)
            ink = (255, 255, 120) if (col_i == 1 and r == k) else INK
            if col_i == 0 and r == 9:
                ink = (230, 90, 80)
            draw_text(img, mem, codes, x, yy, 2, ink)
            d.text((x - 44, yy), f'{r}', font=small, fill=DIM)
            if col_i == 0 and r >= k and r < 9:
                d.line([x + 16 * cell + 10, yy + 8, x + 16 * cell + 60, yy + 34], fill=COLS[0], width=2)
        if col_i == 0:
            d.text((x + 16 * cell + 10, y + 82 + 9 * 26), 'lost', font=small, fill=COLS[0])
    d.text((14, y + 352), 'A made-up table; the new score 027450 beats 022000 at place 3 (strictly greater: a tie '
           'goes below)', font=small, fill=DIM)
    img.save(a.out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['font', 'hud', 'pages', 'strings', 'countdown', 'hiscore'])
    p.add_argument('--out', required=True)
    p.add_argument('--screen')
    p.add_argument('--events')
    a = p.parse_args()
    {'font': fig_font, 'hud': fig_hud, 'pages': fig_pages, 'strings': fig_strings, 'countdown': fig_countdown,
     'hiscore': fig_hiscore}[a.what](a)


if __name__ == '__main__':
    main()
