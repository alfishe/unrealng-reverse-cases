#!/usr/bin/env python3
"""Doc 01's figures: the screens around play, the five stages, the key moments, the HUD labelled, the maps.

    python3 tools/fig_design.py front docs/img/design/front.png
    python3 tools/fig_design.py stages docs/img/design/stages.png
    python3 tools/fig_design.py moments1 docs/img/design/moments-1.png
    python3 tools/fig_design.py moments2 docs/img/design/moments-2.png
    python3 tools/fig_design.py hud docs/img/design/hud.png
    python3 tools/fig_design.py maps docs/img/design/maps.png
    python3 tools/fig_design.py items docs/img/design/items.png
    python3 tools/fig_design.py route1 docs/img/design/route-stage1.png

The screens are those of the recordings: docs/img/play/*.png (taken with kit/screen_shot.py from c1, menu, the
stage walks and rzx-r1), and the screens the recording tool saved every 500 frames or so into
work/stage2/rec/<recording>/screens/ (rzx-r1 .. rzx-r5, joystick, ending). The HUD figure is c1 frame 15476's
top 48 lines (docs/img/play/stage1-start.png), with the fields' cells from the stage code (src/stage1/hud.asm). The
maps figure scales the four map figures of tools/fig_rooms.py (docs/img/maps/stageN.png).
"""
import sys

from PIL import Image, ImageDraw

from figmyth import P, W, F, TEXT, DIM, HI, canvas, save, sheet, rec_screen

PLAY = lambda name: P('docs', 'img', 'play', name)  # noqa: E731


def front(out):
    items = [
        (PLAY('c1-04400-countdown.png'), 'loading screen, countdown 0:15:7\nc1 frame 4400 (signal speed)'),
        (PLAY('c1-05000-loading.png'), 'countdown near its end 0:03:3\nc1 frame 5000'),
        (PLAY('logo.png'), 'the front: logo over static stars\nc1 frame 7834'),
        (PLAY('credits.png'), 'credits, page 1 of 7\nc1 frame 7938'),
        (PLAY('menu.png'), 'the menu: the highlight moves by itself\nc1 frame 8310'),
        (rec_screen('joystick', 218), 'SELECT JOYSTICK\njoystick frame 218'),
        (PLAY('define-keys.png'), 'DEFINE KEYS: UP ... FIRE\nmenu frame 146'),
        (PLAY('press-play.png'), 'PRESS PLAY ON TAPE (a stage load)\nc1 frame 8726'),
        (PLAY('stage1-title.png'), 'STOP THE TAPE and the stage title\nc1 frame 15026'),
        (PLAY('hud-game-over.png'), 'the HUD\'s GAME OVER after the last life\ns1-right frame 4000'),
        (PLAY('game-over.png'), 'the game-over menu: restart, credits\ns4-right frame 4000'),
        (rec_screen('rzx-r5', 5663), 'WELL DONE: the end of the game\nrzx-r5 frame 5663'),
    ]
    sheet(items, out, 'Myth: every screen outside play, from the tape to the ending',
          'Twelve screens of four recordings (c1 48K from power-on; menu, joystick from c1\'s menu; rzx-r5 the RZX run '
          'replayed).\nEach caption: what it is, the recording and the frame.', cols=3)


def stages(out):
    items = [
        (rec_screen('rzx-r1', 0), 'STAGE ONE: THE ROAD TO HELL\nrzx-r1 frame 0'),
        (PLAY('stage1-start.png'), 'stage 1: the graveyard over the caves\nc1 frame 15476'),
        (rec_screen('rzx-r1', 30834), 'STAGE TWO: GREECE FOUR HUNDRED BC\nrzx-r1 frame 30834'),
        (rec_screen('rzx-r2', 2017), 'stage 2: the temple and the statues\nrzx-r2 frame 2017'),
        (rec_screen('rzx-r3', 0), 'STAGE THREE: SCANDINAVIA 500 AD\nrzx-r3 frame 0'),
        (rec_screen('rzx-r3', 2625), 'stage 3: the longship under lightning\nrzx-r3 frame 2625'),
        (rec_screen('rzx-r4', 0), 'STAGE FOUR: EGYPT 3000 BC\nrzx-r4 frame 0'),
        (rec_screen('rzx-r4', 548), 'stage 4: the pyramid\'s steps\nrzx-r4 frame 548'),
        (rec_screen('rzx-r5', 0), 'STAGE FIVE: DUEL WITH DAMERON\nrzx-r5 frame 0'),
        (rec_screen('rzx-r5', 1003), 'stage 5: the intro text over the stars\nrzx-r5 frame 1003'),
        (rec_screen('rzx-r5', 2501), 'stage 5: Dameron\'s first form\nrzx-r5 frame 2501'),
        (rec_screen('rzx-r5', 3003), 'stage 5: a later form, red\nrzx-r5 frame 3003'),
    ]
    sheet(items, out, 'The five stages: each title, then play',
          'The RZX run replayed with L1 (rzx-r1 .. rzx-r5), and c1 for stage 1\'s first room.\n'
          'Stages 1-4 are flip-screen rooms; stage 5 is a duel over a star field with no rooms.', cols=3)


def moments1(out):
    items = [
        (rec_screen('rzx-r1', 510), 'stage 1 start: room 2 of the surface\nrzx-r1 frame 510'),
        (rec_screen('rzx-r1', 1015), 'the item window (SPACE): boxes framed\nrzx-r1 frame 1015'),
        (rec_screen('rzx-r1', 2010), 'a skeleton warrior risen from the ground\nrzx-r1 frame 2010'),
        (PLAY('c1-16005-strike.png'), 'the hero strikes; urns and hanging bodies\nc1 frame 16005'),
        (PLAY('stage1-life-lost.png'), 'a life lost: the hero bursts\ndeaths frame 2775'),
        (rec_screen('rzx-r1', 13594), 'the demon\'s cave: skull face, fire floor\nrzx-r1 frame 13594'),
        (PLAY('rzx-r1-15300-demon.png'), 'the winged demon in flight\nrzx-r1 frame 15300'),
        (PLAY('rzx-r1-15400-demon-burst.png'), 'the demon falls apart in a burst\nrzx-r1 frame 15400'),
        (rec_screen('rzx-r1', 19528), 'the green dragon\'s room (grid 2)\nrzx-r1 frame 19528'),
        (rec_screen('rzx-r1', 27033), 'five icons: rings flash, master icon shown\nrzx-r1 frame 27033'),
        (PLAY('rzx-r1-30200-teleport.png'), 'the teleport pad: the stage exit\'s stars\nrzx-r1 frame 30200'),
        (rec_screen('rzx-r2', 3646), 'stage 2: the harpy\nrzx-r2 frame 3646'),
    ]
    sheet(items, out, 'Key moments of play, stage 1 (and the harpy of stage 2)',
          'c1, deaths and the RZX run replayed (rzx-r1, rzx-r2). The first appearance of each mechanic, '
          'each boss and its end.', cols=3)


def moments2(out):
    items = [
        (rec_screen('rzx-r2', 11021), 'stage 2: the hydra rises from the pool\nrzx-r2 frame 11021'),
        (rec_screen('rzx-r2', 13504), 'the hydra, three necks\nrzx-r2 frame 13504'),
        (rec_screen('rzx-r2', 18219), 'stage 2 near its exit: the temple again\nrzx-r2 frame 18219'),
        (rec_screen('rzx-r3', 8576), 'stage 3: the funeral pyre in the swamp\nrzx-r3 frame 8576'),
        (rec_screen('rzx-r3', 11012), 'the dragon breathing fire\nrzx-r3 frame 11012'),
        (rec_screen('rzx-r3', 14505), 'the giant on the throne (grid 2)\nrzx-r3 frame 14505'),
        (rec_screen('rzx-r4', 2548), 'stage 4: a tomb with swinging blades\nrzx-r4 frame 2548'),
        (rec_screen('rzx-r4', 18006), 'the mummy in its corridor\nrzx-r4 frame 18006'),
        (rec_screen('rzx-r4', 20528), 'the pharaoh\'s head, the stage boss\nrzx-r4 frame 20528'),
        (rec_screen('rzx-r5', 2003), 'stage 5: the duel, first form yellow\nrzx-r5 frame 2003'),
        (rec_screen('rzx-r5', 4541), 'Dameron beaten: his head gone\nrzx-r5 frame 4541'),
        (rec_screen('rzx-r5', 6037), 'WELL DONE, the last screen\nrzx-r5 frame 6037'),
    ]
    sheet(items, out, 'Key moments of play, stages 2-5: the bosses and the ending',
          'The RZX run replayed with L1 (rzx-r2 .. rzx-r5): another player\'s complete game, every key change '
          'met.', cols=3)


HUD_FIELDS = [  # (label, column, row, width, height in cells, colour, where)
    ('score: 6 digits', 6, 1, 6, 1, (255, 230, 90), 'Score $F9FB + ScoreHigh $F9FD'),
    ('amount', 15, 1, 2, 1, (120, 220, 255), 'the selected item\'s count'),
    ('energy bar', 20, 1, 8, 1, (255, 120, 220), 'Energy $FE3F, 0-46'),
    ('lives', 1, 3, 6, 2, (200, 150, 255), 'Lives $FE61, 6 boxes'),
    ('carried items', 8, 3, 15, 2, (130, 230, 150), 'CarriedItems $7F17, selected at col 15'),
    ('teleport icons', 25, 3, 6, 2, (255, 170, 90), 'PiecesMask $FE51, 5 rings'),
]


def hud(out):
    src = Image.open(PLAY('stage1-start.png')).convert('RGB').resize((256, 192), Image.NEAREST).crop((0, 0, 256, 48))
    scale = 4
    zoom = src.resize((256 * scale, 48 * scale), Image.NEAREST)
    x0 = (W - zoom.width) // 2
    im, d, y0 = canvas(620, 'The HUD: six fields in the top six character rows',
                       'c1 frame 15476 (stage 1 just in play), screen lines 0-47 at 4 x.\nBoxes: the character cells '
                       'each field\'s routine writes (src/stage1/hud.asm).')
    im.paste(zoom, (x0, y0))
    lab_y = y0 + zoom.height + 30
    for i, (label, col, row, w, h, colour, where) in enumerate(HUD_FIELDS):
        bx, by = x0 + col * 8 * scale, y0 + row * 8 * scale
        d.rectangle([bx - 2, by - 2, bx + w * 32 + 1, by + h * 32 + 1], outline=colour, width=3)
        lx = 30 + (i % 3) * 335
        ly = lab_y + (i // 3) * 92
        d.line([(bx + w * 16, by + h * 32 + 2), (bx + w * 16, y0 + zoom.height + 8), (lx + 60, ly - 4)],
               fill=colour, width=2)
        d.text((lx, ly), label, font=F(16), fill=colour)
        d.text((lx, ly + 24), where, font=F(13), fill=DIM)
        d.text((lx, ly + 42), f'cells: column {col}, row {row}, {w} x {h}', font=F(13), fill=DIM)
    d.text((16, lab_y + 200), 'The rest of the strip is the HUD picture $7000 (48 lines) drawn once at the stage\'s '
           'start;', font=F(13), fill=TEXT)
    d.text((16, lab_y + 220), 'the six fields are the only cells the stage code writes again in play.',
           font=F(13), fill=TEXT)
    save(im.crop((0, 0, W, lab_y + 250)), out)


def maps(out):
    pics = [Image.open(P('docs', 'img', 'maps', f'stage{n}.png')).convert('RGB') for n in (1, 2, 3, 4)]
    im, d, y = canvas(2000, 'The four room stages as one contact sheet (stage 5 has no rooms)',
                      'Drawn by tools/fig_rooms.py from src/res/stageN (graphics.txt, the rooms and the placements); '
                      'scaled to the page.\nEach magenta dot is a placement: its number is the kind (doc 07).')
    names = ['stage 1, The Road To Hell: 3 grids, 22 rooms', 'stage 2, Greece 400 BC: 3 grids, 15 rooms',
             'stage 3, Scandinavia 500 AD: 3 grids, 16 rooms', 'stage 4, Egypt 3000 BC: 9 grids, 29 rooms']
    for pic, name in zip(pics, names):
        s = min((W - 32) / pic.width, 700 / pic.height)
        p = pic.resize((int(pic.width * s), int(pic.height * s)), Image.LANCZOS)
        d.text((16, y), name, font=F(16), fill=HI)
        im.paste(p, (16, y + 24))
        y += p.height + 40
    save(im.crop((0, 0, W, y)), out)




ICON_TABLES = {1: (0x7F3B, 9), 2: (0x7F00, 8), 3: (0x7F2F, 10), 4: (0x7F75, 10), 5: (0x7E8B, 9)}
BASE = 0x6C3F


def icon(block, address, scale):
    """A 2 x 16 item icon (16 x 16 pixels, 1 bit, rows top first) of a stage block."""
    im = Image.new('RGB', (16, 16), (0, 0, 0))
    for y in range(16):
        for b in range(2):
            v = block[address - BASE + y * 2 + b]
            for k in range(8):
                if v & (0x80 >> k):
                    im.putpixel((b * 8 + k, y), (240, 240, 240))
    return im.resize((16 * scale, 16 * scale), Image.NEAREST)


def items(out):
    scale = 4
    im, d, y = canvas(900, 'The carried items of each stage: the icon of every item kind',
                      'ItemIcons of each stage block (build/stageN.bin): one word a kind, 2 x 16 bytes an icon, kind 4 '
                      'the blank box.\nKind numbers are the code\'s (CarriedItems holds kinds); what a kind does is '
                      'in doc 10.')
    for n in range(1, 6):
        block = open(P('build', f'stage{n}.bin'), 'rb').read()
        table, count = ICON_TABLES[n]
        d.text((16, y + 26), f'stage {n}', font=F(16), fill=HI)
        d.text((16, y + 48), f'ItemIcons ${table:04X}', font=F(13), fill=DIM)
        for k in range(count):
            a = block[table - BASE + 2 * k] | block[table - BASE + 2 * k + 1] << 8
            x = 200 + k * 84
            im.paste(icon(block, a, scale), (x, y))
            d.text((x, y + 68), f'kind {k}', font=F(13), fill=TEXT)
            d.text((x, y + 86), f'${a:04X}', font=F(13), fill=DIM)
        y += 120
    save(im.crop((0, 0, W, y)), out)


# The RZX run's stage 1 rooms, in the order it first enters them: (key, RZX frame, note). Keys: 'g0-N' grid 0 room N,
# 's-N' the shaft (grid 1) room N, 'arena' grid 2. From work/stage2/rzx/state.tsv (window column/row per frame).
ROUTE1 = [('g0-2', 2313, 'start'), ('g0-1', 3413, ''), ('g0-0', 4654, ''), ('g0-3', 5786, ''), ('g0-9', 6053, ''),
          ('g0-10', 6269, ''), ('g0-4', 6569, ''), ('g0-5', 6784, ''), ('g0-11', 10419, ''), ('g0-8', 12239, ''),
          ('g0-7', 13049, ''), ('g0-13', 15397, ''), ('g0-12', 15566, 'the demon'), ('g0-14', 18603, ''),
          ('g0-15', 19838, ''), ('g0-16', 20126, ''), ('g0-17', 21000, ''), ('arena', 21364, 'the dragon'),
          ('s-0', 26299, 'the shaft'), ('s-1', 26982, ''), ('s-2', 27055, '')]
# every room change of the run (the same source), for the connections drawn between the rooms
ROUTE1_PATH = ('g0-2 g0-1 g0-2 g0-1 g0-0 g0-1 g0-2 g0-3 g0-9 g0-10 g0-9 g0-3 g0-4 g0-5 g0-4 g0-3 g0-4 g0-3 g0-4 g0-3 '
               'g0-9 g0-10 g0-9 g0-10 g0-11 g0-10 g0-9 g0-8 g0-7 g0-8 g0-7 g0-13 g0-12 g0-13 g0-14 g0-13 g0-14 g0-13 '
               'g0-14 g0-15 g0-16 g0-17 arena g0-17 g0-16 g0-17 g0-16 g0-15 g0-14 g0-13 g0-14 g0-13 g0-7 g0-8 g0-7 '
               's-0 s-1 s-2 g0-7 g0-13 g0-14 g0-13 g0-14 g0-15 g0-14 g0-13 g0-7 g0-8 g0-9 g0-8 g0-9 g0-10 g0-9 g0-3 '
               'g0-2').split()


def route1(out):
    src = Image.open(P('docs', 'img', 'maps', 'stage1-rooms.png')).convert('RGB')
    tiles = {}
    for i in range(22):
        key = f'g0-{i}' if i < 18 else (f's-{i - 18}' if i < 21 else 'arena')
        x, y = 10 + 234 * (i % 4), 26 + 174 * (i // 4)
        tiles[key] = src.crop((x, y, x + 224, y + 144))
    tw, th, gap = 116, 75, 10
    place = {f'g0-{n}': (1 + n % 6, n // 6) for n in range(18)}
    place.update({'s-0': (0, 0), 's-1': (0, 1), 's-2': (0, 2), 'arena': (7, 2)})
    rowh = th + 52
    im, d, y0 = canvas(3 * rowh + 330, 'Stage 1: the rooms in the order the RZX run first enters them',
                       'Grid 0 (18 rooms, 6 a row) in the middle, the shaft (grid 1, 3 rooms) on the left, the '
                       'dragon\'s arena (grid 2) on the right.\nA grey line joins two rooms the run walks between; '
                       'the number is the order of the first visit; the frame is the RZX frame.')
    centre = {}
    for key, (c, r) in place.items():
        x, y = 16 + c * (tw + gap), y0 + 8 + r * rowh
        centre[key] = (x + tw // 2, y + th // 2)
    for a, b in {tuple(sorted(p)) for p in zip(ROUTE1_PATH, ROUTE1_PATH[1:])}:
        d.line([centre[a], centre[b]], fill=(120, 120, 135), width=5)
    first = {k: (n + 1, f, note) for n, (k, f, note) in enumerate(ROUTE1)}
    for key, (c, r) in place.items():
        x, y = 16 + c * (tw + gap), y0 + 8 + r * rowh
        im.paste(tiles[key].resize((tw, th), Image.LANCZOS), (x, y))
        name = 'arena' if key == 'arena' else ('room ' if key.startswith('g0') else 'shaft ') + key.split('-')[1]
        d.text((x, y + th + 3), name, font=F(13), fill=TEXT)
        if key in first:
            n, f, note = first[key]
            d.text((x + 64, y + th + 3), str(f), font=F(13), fill=DIM)
            if note:
                d.text((x, y + th + 20), note, font=F(13), fill=HI)
            d.ellipse((x - 6, y - 6, x + 22, y + 22), fill=HI)
            d.text((x + 8, y + 8), str(n), font=F(14), fill=(20, 20, 26), anchor='mm')
        else:
            d.text((x + 64, y + th + 3), 'never', font=F(13), fill=DIM)
    y = y0 + 8 + 3 * rowh + 8
    notes = [
        'RZX frame 2313: the stage starts in room 2 (the start window, blocks 22, 0) with energy 46 and 5 lives.',
        '15566-18329: the demon\'s cave (room 12): the stone face, the fire floor, the winged demon from the pit.',
        '21364-22408: through room 17\'s right edge into the dragon\'s arena (grid 2), and back with the dragon '
        'beaten.',
        '26299-28106: through room 7\'s left edge into the shaft (grid 1), down its three rooms, out at the bottom '
        'right into room 7.',
        '28929: room 15 again; the five teleport icons are taken and the master icon lies here (rzx-r1 frame 27033).',
        '31539-32896: back to room 2 with the master icon; the teleport pad ends the stage (rzx-r1 frame 30200).',
        'Room 6 has no exit: no window reaches it from another (rooms.txt), and no run enters it.']
    for line in notes:
        d.text((16, y), line, font=F(13), fill=TEXT)
        y += 22
    save(im.crop((0, 0, W, y + 10)), out)


if __name__ == '__main__':
    cmd, out = sys.argv[1], sys.argv[2]
    {'front': front, 'stages': stages, 'moments1': moments1, 'moments2': moments2, 'hud': hud,
     'maps': maps, 'items': items, 'route1': route1}[cmd](out)
