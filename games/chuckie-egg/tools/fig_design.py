#!/usr/bin/env python3
"""Doc 01's figures (the game as a player meets it), 1050 pixels wide, into docs/img/design/.

    python3 tools/fig_design.py screens                   # every screen and mode, from docs/img/play/*.png
    python3 tools/fig_design.py moments                   # the key moments of a game, from docs/img/play/*.png
    python3 tools/fig_design.py playscreen --work W       # level 1 with its parts labelled (memory_at, levels-1-9 420)
    python3 tools/fig_design.py cast                      # Harry, the hens, the duck and the map cells, from src/res
    python3 tools/fig_design.py world                     # the eight maps with the hens' starts and the lift shafts
    python3 tools/fig_design.py cycle                     # what each level 1-96 gets, from the rules of the code

The screenshots are recording frames taken with kit/screen_shot.py (WALKTHROUGH 6.1 and doc 01's tables); the maps
and sprites come from src/res (res_formats.py), the hens' starts from src/res/tables/HenTable.csv, the lifts from
LiftTable.csv. The rules of `cycle` are those of SetupLevel $AE9C, MoveHen $911E, MainLoop $9935, MoveDuck $A0C8 and
TakeEggOrGrain $99DF (doc 01, 1.7 and 1.10).
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
import res_formats as rf  # noqa: E402

PLAY = os.path.join(CASE, 'docs', 'img', 'play')
MAPS = os.path.join(CASE, 'docs', 'img', 'maps')
OUT = os.path.join(CASE, 'docs', 'img', 'design')
WIDTH = 1050
BG, PANEL, TEXT, DIM = K.BACKGROUND, K.PANEL, K.TEXT, K.DIM
ACCENT = (250, 200, 80)
INK = [(0, 0, 0), (0, 0, 215), (215, 0, 0), (215, 0, 215), (0, 215, 0), (0, 215, 215), (215, 215, 0),
       (215, 215, 215)]


def font(size):
    return K.font(size)


def title_block(draw, text, sub=None):
    draw.text((12, 10), text, fill=TEXT, font=font(20))
    if sub:
        draw.text((12, 38), sub, fill=DIM, font=font(14))


def tile(name):
    """a docs/img/play screenshot (scale 2) at scale 1"""
    im = Image.open(os.path.join(PLAY, name + '.png')).convert('RGB')
    return im.resize((256, 192), Image.NEAREST)


def sheet(tiles, title, sub, out, cols=4):
    """tiles: (png name, caption line 1, caption line 2)"""
    gap, top, cap = 6, 64, 40
    rows = (len(tiles) + cols - 1) // cols
    im = Image.new('RGB', (WIDTH, top + rows * (192 + cap + gap) + 6), BG)
    d = ImageDraw.Draw(im)
    title_block(d, title, sub)
    x0 = (WIDTH - cols * 256 - (cols - 1) * gap) // 2
    for i, (name, line1, line2) in enumerate(tiles):
        x = x0 + (i % cols) * (256 + gap)
        y = top + (i // cols) * (192 + cap + gap)
        im.paste(tile(name), (x, y))
        d.text((x + 2, y + 194), f'{i + 1}. {line1}', fill=TEXT, font=font(14))
        d.text((x + 2, y + 212), line2, fill=DIM, font=font(13))
    os.makedirs(OUT, exist_ok=True)
    im.save(out)
    print(out, im.size)


def screens(_a):
    tiles = [
        ('title', 'title, high scores', 'tour-type2 200'),
        ('instructions', 'instructions, key types', 'tour-type2 300'),
        ('redefine', 'redefine: Q A O P M', 'tour-redefine 450'),
        ('players-prompt', '1,2,3 OR 4 PLAYERS ?', 'tour-type2 500'),
        ('player-turn', 'PLAYER 1 scrolls in', 'tour-type2 700'),
        ('level1', 'play: level 1, one player', 'levels-1-3 500'),
        ('level1-two-players', 'play: two players', 'tour-type2 900'),
        ('level1-four-players', 'play: four players', 'tour-redefine 1150'),
        ('level-end-bonus', 'level end: bonus to score', 'levels-1-9 2016'),
        ('level-end-boxes', 'level end: BoxZoom', 'levels-1-9 2080'),
        ('level-message', 'LEVEL 2 scrolls in', 'levels-1-9 2170'),
        ('out-of-time', 'OUT OF TIME !', 'tour-redefine 8750'),
        ('player2-turn', 'the next player\'s turn', 'tour-redefine 9050'),
        ('game-over', 'GAME OVER', 'idle-1p 14 600'),
        ('name-prompt', 'a high score: the name', 'gameover-name 39 450'),
        ('title-new-entry', 'the title, CE1 first', 'gameover-name 39 700'),
    ]
    sheet(tiles, "The screens: the menu pages, play, the level end, a life lost, the game over",
          'each the Spectrum screen at the end of the frame named under it (recording, frame); kit/screen_shot.py',
          os.path.join(OUT, 'screens.png'))


def moments(_a):
    tiles = [
        ('first-egg', 'the first egg: 100', 'levels-1-9 574'),
        ('jump', 'a jump to the right', 'levels-1-9 610'),
        ('climb', 'a ladder: up, frame 13-16', 'levels-1-9 712'),
        ('level-drawn', 'level 2: no hens yet', 'levels-1-9 2300'),
        ('lift-ride', 'level 3: a lift ride', 'levels-1-9 5800'),
        ('extra-life-before', '9 900 points, 5 lives', 'levels-1-9 7980'),
        ('extra-life', '10 000: 6 lives (7985)', 'levels-1-9 7990'),
        ('level8', 'level 8: three hens', 'levels-1-9 17 253'),
        ('hen-death', 'a hen kills: Harry gone', 'idle-1p 7250'),
        ('fall-death', 'a fall into a floor gap', 'fall-death 2710'),
        ('time-zero', 'TIME 000', 'tour-redefine 8600'),
        ('level9', 'level 9: no hens, caged', 'levels-1-9 23 546'),
        ('duck-out', 'level 9: the duck is out', 'levels-1-9 23 700'),
        ('duck-free', 'the duck closes in', 'levels-1-9 24 300'),
        ('level10', 'level 10: level 2\'s map', 'levels-1-9 25 490'),
        ('name-typed', 'the name typed: CE1', 'gameover-name 39 600'),
    ]
    sheet(tiles, 'Key moments of a game, from the first egg to the duck and the high score',
          'each the Spectrum screen at the end of the frame named under it (recording, frame); kit/screen_shot.py',
          os.path.join(OUT, 'moments.png'))


# ---------------------------------------------------------------------------------------------------------------
# the play screen, labelled

def memory_at(work, frame, address, length):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'offset': address,
                                     'length': length}, ok=False)
    data = (r.structured or {}).get('hex')
    if r.is_error or not data:
        raise SystemExit(f'memory_at {frame} {address:04X}: {r.text}')
    return bytes.fromhex(data)


def playscreen(a):
    frame = a.frame
    mem = memory_at(a.work, frame, 0x4000, 0x1B00)
    var = memory_at(a.work, frame, 0x72D8, 0xA0)  # HarryX ... PhrasePtr
    screen = K.render_screen(bytes(0x4000) + mem + bytes(0x10000 - 0x5B00), 0x4000)
    hx, hy = var[0], var[1]
    duck = (var[0x7348 - 0x72D8], var[0x7349 - 0x72D8])
    hens = []
    for k in range(5):
        x, y, s = var[0x7357 - 0x72D8 + 4 * k:0x7357 - 0x72D8 + 4 * k + 3]
        if x != 0xFF:
            hens.append((x, y, s))
    print(f'frame {frame}: Harry ({hx}, {hy}) duck {duck} hens {hens}')
    S = 3
    big = screen.resize((256 * S, 192 * S), Image.NEAREST)
    im = Image.new('RGB', (WIDTH, 64 + 192 * S + 150), BG)
    d = ImageDraw.Draw(im)
    title_block(d, 'The play screen: three HUD rows over the 32 x 21 map',
                f'levels-1-9 frame {frame} (level 1), scaled by 3: the screen and the records read with memory_at at '
                'the start of the frame')
    ox, oy = 12, 64
    im.paste(big, (ox, oy))
    f = font(14)

    def box(x, y, w, h, n, colour=ACCENT, where='a'):
        d.rectangle((ox + x * S, oy + y * S, ox + (x + w) * S - 1, oy + (y + h) * S - 1), outline=colour, width=2)
        tw = 9 * len(str(n)) + 6
        tx, ty = {'a': (ox + x * S + 2, oy + y * S - 17), 'r': (ox + (x + w) * S + 3, oy + y * S + 4),
                  'l': (ox + x * S - tw - 3, oy + y * S + 4)}[where]
        d.rectangle((tx, ty, tx + 9 * len(str(n)) + 6, ty + 16), fill=colour)
        d.text((tx + 3, ty), str(n), fill=(0, 0, 0), font=f)

    # screen y (0 at the top) of a sprite: Harry's y is its top, a hen's y its bottom line
    box(0, 0, 88, 8, 1, where='r')             # SCORE and the score
    box(32, 8, 56, 8, 2, where='r')            # life icons, row 1
    box(0, 16, 40, 8, 3, where='r')            # PLAYER n
    box(56, 16, 48, 8, 4, where='r')           # LEVEL nn
    box(120, 16, 64, 8, 5, where='r')          # BONUS
    box(200, 16, 56, 8, 6, where='l')          # TIME
    box(0, 24, 32, 40, 7, where='r')           # the cage: map rows 16-20, columns 0-3
    box(hx, 191 - hy, 16, 16, 8)               # Harry
    for x, y, s in hens:
        box(x, 191 - y - 15, 16, 16, 9, (90, 220, 230))
    # an egg, the grain, a ladder and a platform of level 1's map (src/res/maps/Level1.txt)
    cells = rf.map_in(open(os.path.join(rf.RES, 'maps', 'Level1.txt'), 'rb').read())
    live = memory_at(a.work, frame, 0x61A8, 672)
    marks = {3: 10, 4: 11, 1: 12, 5: 13}
    done = set()
    for r in range(20, -1, -1):
        for c in range(32):
            code = live[r * 32 + c]
            if code in marks and code not in done and not (code == 5 and r == 0):
                if code == 1 and r > 10:
                    continue
                done.add(code)
                w = 16 if code == 1 else (24 if code == 5 else 8)
                box(c * 8, 24 + (20 - r) * 8, w, 8, marks[code], (240, 120, 200))
    eggs_live = sum(1 for b in live if b == 3)
    print(f'eggs in the live map {eggs_live}, in Level1.txt {sum(1 for b in cells if b == 3)}')
    # the legend on the right
    lx, ly = ox + 256 * S + 14, oy
    legend = [
        ('1', 'SCORE: six digits, ScoreScreenAddr'),
        ('2', 'life icons $B6, row 1 (lives - 1)'),
        ('3', 'PLAYER n (HudText $9764)'),
        ('4', 'LEVEL nn: level + 1, two digits'),
        ('5', 'BONUS: 1000 x level, counts down'),
        ('6', 'TIME 900, counts down to 000'),
        ('7', 'the cage: map codes $A8-$B5'),
        ('8', f'Harry at ({hx}, {hy}), 16 x 16'),
        ('9', 'a hen: walks, climbs, pecks'),
        ('10', 'an egg (map code 3): 100'),
        ('11', 'grain (4): 50, stops the clocks'),
        ('12', 'a ladder (1 and 2)'),
        ('13', 'a platform brick (5)'),
    ]
    fl = font(13)
    for n, text in legend:
        d.text((lx, ly), n, fill=ACCENT, font=f)
        lines = [text] if len(text) <= 27 else [text[:text.rfind(' ', 0, 27)], text[text.rfind(' ', 0, 27) + 1:]]
        for k, ln in enumerate(lines):
            d.text((lx + 26, ly + 1 + k * 15), ln, fill=TEXT, font=fl)
        ly += 15 * len(lines) + 9
    notes = [
        'How to read: the screen of levels-1-9 at frame %d, tripled. Yellow boxes are the HUD fields and the cage,' % frame,
        'cyan boxes the hens at their records (Hens $7357: x, y of the bottom line), the box 8 Harry at HarryX / HarryY',
        '(the top line), the pink boxes one cell of each map kind, from the live map $61A8 at that frame.',
        'The point: everything is on one screen. The map is 21 character rows (rows 3-23 of the screen), the HUD the',
        'three rows above it; the HUD shows all four players\' scores in one row when more than one plays.',
        'python3 tools/fig_design.py playscreen --work work/docs/ceA/l19 --frame %d' % frame,
    ]
    y = oy + 192 * S + 10
    for k, t in enumerate(notes):
        d.text((12, y + k * 22), t, fill=DIM if t.startswith('python3') else TEXT, font=font(14))
    out = os.path.join(OUT, 'playscreen.png')
    os.makedirs(OUT, exist_ok=True)
    im.save(out)
    print(out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# the cast

def frames_of(path):
    data = rf.png_to_sheet(open(os.path.join(rf.RES, path), 'rb').read())
    return [data[i:i + 32] for i in range(0, len(data), 32)]


def glyphs():
    data = rf.png_to_sheet(open(os.path.join(rf.RES, 'graphics', 'CharacterSet.png'), 'rb').read())
    data += rf.png_to_sheet(open(os.path.join(rf.RES, 'graphics', 'HudCharacters.png'), 'rb').read())
    return data


def sprite_image(frame, ink, scale):
    im = Image.new('RGB', (16, 16), (0, 0, 0))
    px = im.load()
    for r in range(16):
        for b in range(16):
            byte = frame[r * 2 + b // 8]
            if byte >> (7 - b % 8) & 1:
                px[b, r] = ink
    return im.resize((16 * scale, 16 * scale), Image.NEAREST)


def glyph_image(g, code, ink, scale):
    im = Image.new('RGB', (8, 8), (0, 0, 0))
    px = im.load()
    for r in range(8):
        for b in range(8):
            if g[code * 8 + r] >> (7 - b) & 1:
                px[b, r] = ink
    return im.resize((8 * scale, 8 * scale), Image.NEAREST)


def cast(_a):
    spr = frames_of('sprites/Sprites.png')
    hen = frames_of('sprites/HenSprites.png')
    g = glyphs()
    S = 4
    im = Image.new('RGB', (WIDTH, 760), BG)
    d = ImageDraw.Draw(im)
    title_block(d, 'The cast: Harry, the hens, the duck, and the five map cells he meets',
                'from src/res/sprites and src/res/graphics, in the game\'s colours; frame numbers of DrawSprite / DrawHen')
    f, fs = font(14), font(13)
    yellow, cyan = INK[6], INK[5]

    def row(y, label, sub, items):
        d.text((12, y), label, fill=ACCENT, font=f)
        d.text((12, y + 18), sub, fill=DIM, font=fs)
        x = 12
        for img, cap in items:
            im.paste(img, (x, y + 40))
            d.text((x, y + 40 + img.size[1] + 3), cap, fill=TEXT, font=fs)
            x += max(img.size[0] + 14, 9 * len(cap) + 10)
    row(64, 'Harry (yellow, attribute 6)', 'walking right 0-3, left 4-7, climbing 13-16: HarryFrame + HarryDir',
        [(sprite_image(spr[n], yellow, S), str(n)) for n in list(range(0, 8)) + list(range(13, 17))])
    row(200, 'The hens (cyan, attribute 5)', 'walking left 0 and 4, right 1 and 5; climbing 2-3; pecking left 6, '
        'right 7 (HenSprites)',
        [(sprite_image(hen[n], cyan, S), str(n)) for n in range(8)])
    row(336, 'The duck (yellow) and the blank frame', 'frames 8-9 facing right, 10-11 facing left; frame 12 is '
        '32 zero bytes, drawn to erase',
        [(sprite_image(spr[n], yellow, S), str(n)) for n in range(8, 13)])
    cage = Image.new('RGB', (32 * 3, 40 * 3), (0, 0, 0))
    codes = [[0xA8, 0xA9, 0, 0], [0xAA, 0xAB, 0xAC, 0xAD], [0xAE, 0xAF, 0xB0, 0xB1], [0xAE, 0xAF, 0xB0, 0xB1],
             [0xB2, 0xB3, 0xB4, 0xB5]]
    cells = rf.map_in(open(os.path.join(rf.RES, 'maps', 'Level1.txt'), 'rb').read())
    rows_top = [cells[r * 32:r * 32 + 4] for r in range(20, 15, -1)]
    for r, codes_row in enumerate(rows_top):
        for c, code in enumerate(codes_row):
            if code:
                cage.paste(glyph_image(g, code, yellow, 3), (c * 24, r * 24))
    del codes
    attrs = {int(r[0]): int(r[1]) for r in rf.csv_rows(open(os.path.join(rf.RES, 'tables',
                                                                           'CellAttributes.csv'), 'rb').read())}
    items = [(glyph_image(g, c, INK[attrs[c] & 7], 6), f'{c}:{n}') for c, n in
             ((1, 'ladder'), (2, 'ladder'), (3, 'egg'), (4, 'grain'), (5, 'brick'))]
    items.append((cage, 'the cage, $A8-$B5'))
    row(472, 'The map cells (8 x 8, scale 6) and the cage (scale 3)', 'live map codes: 0 empty, 1 and 2 a '
        'ladder\'s columns, 3 egg, 4 grain, 5 brick; the cage $A8-$B5', items)
    notes = ['How to read: each picture is one frame or cell as the image stores it; under it, its frame or code.',
             'The point: the cast is 25 frames of 16 x 16 and five cells; the duck is drawn by Harry\'s DrawSprite.',
             'python3 tools/fig_design.py cast']
    for k, t in enumerate(notes):
        d.text((12, 690 + k * 20), t, fill=DIM if t.startswith('python3') else TEXT, font=f)
    out = os.path.join(OUT, 'cast.png')
    os.makedirs(OUT, exist_ok=True)
    im.save(out)
    print(out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# the world: the eight maps

def world(_a):
    hens = {}
    for r in rf.csv_rows(open(os.path.join(rf.RES, 'tables', 'HenTable.csv'), 'rb').read()):
        if r[0] == '0':
            continue
        n = int(r[1]) // 4
        hens[int(r[0])] = [(int(r[2 + 4 * k]), int(r[3 + 4 * k]), int(r[4 + 4 * k])) for k in range(5)][:n]
        hens[int(r[0])] = (hens[int(r[0])], [(int(r[2 + 4 * k]), int(r[3 + 4 * k]), int(r[4 + 4 * k]))
                                             for k in range(5)])
    lifts = {}
    for r in rf.csv_rows(open(os.path.join(rf.RES, 'tables', 'LiftTable.csv'), 'rb').read()):
        if r[0] != 'current':
            lifts[int(r[0])] = int(r[2])
    gap, top, cap = 10, 64, 46
    tw, th = 512, 336
    sc = 0.5
    w, h = int(tw * sc), int(th * sc)
    cols = 4
    im = Image.new('RGB', (WIDTH, top + 2 * (h + cap + gap) + 140), BG)
    d = ImageDraw.Draw(im)
    title_block(d, 'The eight maps, the hens\' starting places and the lift shafts',
                'docs/img/maps/LevelN.png (tools/fig_maps.py, src/res/maps) at half size; the hens of HenTable, the lifts '
                'of LiftTable')
    x0 = (WIDTH - cols * w - (cols - 1) * gap) // 2
    f, fs = font(14), font(13)
    for n in range(1, 9):
        m = Image.open(os.path.join(MAPS, f'Level{n}.png')).convert('RGB').resize((w, h), Image.NEAREST)
        x = x0 + ((n - 1) % cols) * (w + gap)
        y = top + ((n - 1) // cols) * (h + cap + gap)
        im.paste(m, (x, y))
        k = w / 256
        lx = lifts[n]
        if lx != 255:
            d.rectangle((x + lx * k, y, x + (lx + 16) * k, y + h - 1), outline=(240, 240, 240), width=1)
        used, all5 = hens[n]
        for i, (hx, hy, _s) in enumerate(all5):
            top_line = 191 - hy - 15 - 24
            box = (x + hx * k, y + top_line * k, x + (hx + 16) * k, y + (top_line + 16) * k)
            if i < len(used):
                d.rectangle(box, outline=(90, 220, 230), width=2)
            elif 0 <= top_line < 168:
                for xx in range(int(box[0]), int(box[2]), 4):
                    d.point((xx, box[1]), fill=(230, 230, 230))
                    d.point((xx, box[3]), fill=(230, 230, 230))
        levels = ', '.join(str(n + 8 * j) for j in range(4)) + ' ...'
        d.text((x + 2, y + h + 3), f'map {n}: levels {levels}', fill=TEXT, font=f)
        d.text((x + 2, y + h + 22), f'{len(used)} hens, ' + ('no lift' if lx == 255 else f'lift at x {lx}'),
               fill=DIM, font=fs)
    notes = ['How to read: one map a tile, the 21 rows of the play area (screen rows 3-23). A cyan box is a hen\'s',
             'start (x, y of its bottom line, HenTable). A white frame is the lift shaft (LiftTable): two platforms',
             'rise in it. Dotted lines: the other records of the row, used from level 25 on (five hens).',
             'The point: eight maps serve every level (map = ((level - 1) AND 7) + 1); what changes from round to',
             'round is the hens, the duck and the clocks (1.10).',
             'python3 tools/fig_design.py world']
    yy = top + 2 * (h + cap + gap) + 8
    for i, t in enumerate(notes):
        d.text((12, yy + i * 22), t, fill=DIM if t.startswith('python3') else TEXT, font=f)
    out = os.path.join(OUT, 'world.png')
    os.makedirs(OUT, exist_ok=True)
    im.save(out)
    print(out, im.size)


# ---------------------------------------------------------------------------------------------------------------
# the cycle of repeats

def level_rules(level):
    """level 1 and up, as the code decides (Level = level - 1)"""
    L = level - 1
    hens_rows = [2, 3, 3, 4, 4, 4, 3, 3]
    if 8 <= L <= 15:
        hens = 0
    elif L >= 24:
        hens = 5
    else:
        hens = hens_rows[L & 7]
    return {
        'map': (L & 7) + 1,
        'hens': hens,
        'duck': 'free' if L >= 8 else 'caged',
        'henticks': 2 if L >= 0x20 else 3,
        'time': 100 * (9 - min(L // 16, 5)),
        'egg': 100 * (1 + min(L // 4, 9)),
        'bonus': 1000 * min(L + 1, 9),
        'lift': (L & 7) + 1 in (3, 4, 5, 6, 7),
    }


def cycle(_a):
    levels = list(range(1, 97))
    rows = [('map', 'map 1-8'), ('hens', 'hens'), ('duck', 'duck'), ('henticks', 'hen period'),
            ('time', 'TIME at start'), ('bonus', 'BONUS at start'), ('egg', 'an egg scores')]
    cw, rh, left, top = 9, 34, 150, 70
    im = Image.new('RGB', (WIDTH, top + len(rows) * rh + 230), BG)
    d = ImageDraw.Draw(im)
    title_block(d, 'The cycle of repeats: what each level 1-96 gets',
                'from the rules of SetupLevel $AE9C, MoveHen $911E, MainLoop $9935, MoveDuck $A0C8, TakeEggOrGrain '
                '$99DF')
    f, fs = font(14), font(12)

    def shade(v, lo, hi, base):
        t = 0 if hi == lo else (v - lo) / (hi - lo)
        return tuple(int(30 + t * (c - 30)) for c in base)
    for i, (key, label) in enumerate(rows):
        y = top + i * rh
        d.text((12, y + 8), label, fill=TEXT, font=f)
        vals = [level_rules(n)[key] for n in levels]
        nums = [v for v in vals if isinstance(v, int)]
        for j, v in enumerate(vals):
            x = left + j * cw
            if key == 'duck':
                col = (215, 215, 0) if v == 'free' else (60, 60, 70)
            elif key == 'map':
                col = (90, 150, 250) if level_rules(levels[j])['lift'] else (70, 90, 140)
            elif key == 'henticks':
                col = (230, 90, 80) if v == 2 else (90, 60, 60)
            elif key == 'time':
                col = shade(v, 400, 900, (90, 200, 120))
            elif key == 'hens':
                col = shade(v, 0, 5, (90, 220, 230))
            else:
                col = shade(v, min(nums), max(nums), (240, 200, 70))
            d.rectangle((x, y + 4, x + cw - 2, y + rh - 4), fill=col)
            if key in ('map', 'hens') and (cw >= 9):
                d.text((x + 1, y + 9), str(v), fill=(0, 0, 0), font=fs)
        # value changes, written over the row
        last = None
        for j, v in enumerate(vals):
            if key in ('time', 'egg', 'bonus') and v != last and (key != 'bonus' or v in (1000, 9000)):
                d.text((left + j * cw + 1, y + 9), str(v), fill=(0, 0, 0), font=fs)
            last = v
    y = top + len(rows) * rh + 4
    for j, n in enumerate(levels):
        if n == 1 or n % 8 == 1:
            d.line((left + j * cw - 1, top, left + j * cw - 1, y), fill=(200, 200, 200))
            d.text((left + j * cw + 1, y + 2), str(n), fill=TEXT, font=fs)
    d.text((left, y + 20), 'level', fill=DIM, font=fs)
    notes = ['How to read: one column a level; white lines at levels 1, 9, 17, ... (each round of the eight maps).',
             'Map: its number, light blue when it has a lift. Hens: how many. Duck: yellow when it flies.',
             'Hen period: red when a hen moves every 2 slow ticks, not 3. TIME, BONUS, egg: brighter is more.',
             'The point: the maps cycle every 8 levels. 9-16: no hens, the duck free. 17-24: the hens and the duck.',
             '25 on: five hens; 33 on: faster hens. The time drops 100 every 16 levels to 400 at 81; the egg value',
             'rises every 4 levels to 1000 at 37; the starting bonus rises 1000 a level to 9000 at 9.',
             'python3 tools/fig_design.py cycle']
    for k, t in enumerate(notes):
        d.text((12, y + 46 + k * 22), t, fill=DIM if t.startswith('python3') else TEXT, font=f)
    out = os.path.join(OUT, 'cycle.png')
    os.makedirs(OUT, exist_ok=True)
    im.save(out)
    print(out, im.size)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['screens', 'moments', 'playscreen', 'cast', 'world', 'cycle', 'all'])
    p.add_argument('--work', help='playscreen: the re_session work folder holding levels-1-9')
    p.add_argument('--frame', type=int, default=420)
    a = p.parse_args()
    todo = ['screens', 'moments', 'cast', 'world', 'cycle'] if a.what == 'all' else [a.what]
    for w in todo:
        globals()[w](a)


if __name__ == '__main__':
    main()
