#!/usr/bin/env python3
"""Doc 08: the font, the HUD, the window frames, the texts and the menus, drawn from the image, the resources and the
recordings' screenshots.

    python3 tools/fig_text.py font       docs/img/text/font.png: the ROM font as PrintGlyph makes it bold
    python3 tools/fig_text.py hud        docs/img/text/hud.png: the top third labelled (tools 6332)
    python3 tools/fig_text.py frames     docs/img/text/frames.png: the frame and separator tiles, a box built
    python3 tools/fig_text.py texts      docs/img/text/texts.png: GameTexts byte by byte and FindText's walk
    python3 tools/fig_text.py menufmt    docs/img/text/menu-format.png: the OPTIONS description against its screen
    python3 tools/fig_text.py dialogs    docs/img/text/dialogs.png: every menu and dialog of the recordings
    python3 tools/fig_text.py budget     docs/img/text/budget.png: the budget window, each field with its variable
    python3 tools/fig_text.py evaluation docs/img/text/evaluation.png: the evaluation window labelled
    python3 tools/fig_text.py all

The image is work/mkgame/original.bin (the game as the loader leaves it); the ROM font is the 48K ROM of the unreal-ng
checkout (kitlib.unreal_root()/data/rom/48.rom); the screenshots are the recordings' (work/stage1/rec/NAME/screens).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'text')
REC = os.path.join(CASE, 'work', 'stage1', 'rec')
W = 1050
BG, PANEL, TXT, DIM = (20, 20, 28), (34, 34, 46), (230, 230, 236), (150, 150, 165)
HOT, ACC, GRN, RED = (255, 200, 70), (90, 170, 255), (110, 220, 120), (240, 100, 90)
ICON_TILES, ICON_ATTRS, GAME_TEXTS = 0xE850, 0xF4F8, 0x5FC6


def image():
    return bytearray(open(os.path.join(CASE, 'work', 'mkgame', 'original.bin'), 'rb').read())


def rom():
    return open(os.path.join(K.unreal_root(), 'data', 'rom', '48.rom'), 'rb').read()


def shot(rec, frame_name):
    """a screenshot at 1x (the recordings keep 512 x 384)"""
    path = os.path.join(REC, rec, 'screens', frame_name)
    im = Image.open(path).convert('RGB')
    return im.resize((256, 192), Image.NEAREST)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    im.save(path, optimize=True)
    print(os.path.relpath(path, CASE), im.size)


def glyph(rom_bytes, code, bold):
    rows = []
    for y in range(8):
        b = rom_bytes[0x3C00 + 8 * code + y]
        rows.append((b | (b >> 1)) if bold else b)
    return rows


def draw_bits(d, x, y, rows, scale, ink, paper=None, width=8):
    for r, b in enumerate(rows):
        for c in range(width):
            on = b & (0x80 >> c)
            if on or paper:
                d.rectangle((x + c * scale, y + r * scale, x + (c + 1) * scale - 1, y + (r + 1) * scale - 1),
                            fill=ink if on else paper)


def used_characters():
    """every character code the texts print: src/res/text (bit 7 cleared), the digits and the inline texts"""
    used = set(range(0x30, 0x3A)) | {0x20, 0x24, 0x2D}
    base = os.path.join(CASE, 'src', 'res', 'text')
    for root, _, files in os.walk(base):
        for f in files:
            if not f.endswith('.txt'):
                continue
            for line in open(os.path.join(root, f), encoding='utf-8'):
                if line.startswith('#'):
                    continue
                s = line.rstrip('\n')
                if s.startswith(('header', 'separator', 'end')):
                    continue
                if '"' in s:
                    s = s[s.index('"') + 1:s.rindex('"')]
                out, i = [], 0
                while i < len(s):
                    if s[i] == '{':
                        j = s.index('}', i)
                        i = j + 1
                        continue
                    out.append(ord(s[i]))
                    i += 1
                used |= {c for c in out if 0x20 <= c < 0x80}
    return used


# ------------------------------------------------------------------------------------------------ font

def cmd_font(_a):
    r = rom()
    used = used_characters()
    f, fs, fb = K.font(15), K.font(13), K.font(17)
    scale, cell = 3, 30
    gx = [40, 40 + 16 * cell + 50]
    im = Image.new('RGB', (W, 760), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The ROM font, as stored (left) and as PrintGlyph $F754 draws it: each line OR itself shifted right',
           fill=TXT, font=fb)
    d.text((14, 34), f'white: the {len(used)} of 96 characters that appear in the game\'s texts; dark: never printed '
           '(src/res/text scanned)', fill=DIM, font=f)
    for k, bold in enumerate((False, True)):
        x0, y0 = gx[k], 96
        d.text((x0, y0 - 30), 'ROM $3D00-$3FFF (RomFont + 8 n)' if not bold else 'on screen: line OR (line >> 1)',
               fill=HOT if bold else ACC, font=f)
        for col in range(16):
            d.text((x0 + col * cell + 8, y0 - 10 + 0), f'{col:X}', fill=DIM, font=fs)
        for row in range(6):
            d.text((x0 - 34, y0 + 12 + row * cell + 5), f'${2 + row:X}0', fill=DIM, font=fs)
            for col in range(16):
                code = 0x20 + row * 16 + col
                x, y = x0 + col * cell, y0 + 10 + row * cell
                d.rectangle((x, y, x + 25, y + 25), fill=(245, 245, 245) if code in used else (52, 52, 64))
                draw_bits(d, x + 1, y + 1, glyph(r, code, bold), scale, (0, 0, 0) if code in used else (150, 150, 165))
    # the worked example: 'S' and 'W'
    y0 = 300
    d.text((14, y0), 'Worked example: the letters S ($53) and W ($57), byte by byte (RomFont $3C00 + 8 x code)',
           fill=TXT, font=fb)
    for k, code in enumerate((0x53, 0x57)):
        x0 = 30 + k * 510
        rows = glyph(r, code, False)
        d.text((x0, y0 + 32), f"'{chr(code)}' at ${0x3C00 + 8 * code:04X}", fill=ACC, font=f)
        d.text((x0 + 150, y0 + 32), 'ROM   >> 1   OR', fill=DIM, font=f)
        for i, b in enumerate(rows):
            s = b >> 1
            o = b | s
            y = y0 + 56 + i * 44
            draw_bits(d, x0, y, [b], 5, (230, 230, 230), (60, 60, 75))
            draw_bits(d, x0, y + 5, [b], 5, (230, 230, 230), (60, 60, 75))
            d.text((x0 + 46, y + 10), f'${b:02X}', fill=TXT, font=fs)
            d.text((x0 + 100, y + 10), f'${s:02X}', fill=DIM, font=fs)
            d.text((x0 + 150, y + 10), f'${o:02X}', fill=HOT, font=fs)
            draw_bits(d, x0 + 200, y, [o], 5, HOT, (60, 60, 75))
            draw_bits(d, x0 + 200, y + 5, [o], 5, HOT, (60, 60, 75))
        if k == 0:
            d.text((x0, y0 + 56 + 8 * 44 + 4), 'one line = 8 pixels: the OR makes every vertical stroke 2 pixels wide, '
                   'a bold face from the thin ROM font', fill=DIM, font=fs)
        big = glyph(r, code, True)
        draw_bits(d, x0 + 300, y0 + 60, big, 16, (0, 0, 0), (245, 245, 245))
    save(im, 'font.png')


# ------------------------------------------------------------------------------------------------ HUD

def cmd_hud(_a):
    sc = shot('tools', '006332-commercial.png')
    top = sc.crop((0, 0, 256, 64)).resize((256 * 3, 64 * 3), Image.NEAREST)
    f, fs, fb = K.font(14), K.font(13), K.font(17)
    im = Image.new('RGB', (W, 640), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The top third: menu bar, tool palette, status box, and the routine behind each field',
           fill=TXT, font=fb)
    d.text((14, 34), 'tools recording frame 6332 (the screenshot), 3 x; character rows 0-7, columns 0-31',
           fill=DIM, font=f)
    x0, y0 = 140, 70
    im.paste(top, (x0, y0))
    for c in range(0, 32, 4):
        d.text((x0 + c * 24 + 2, y0 - 16), f'{c}', fill=DIM, font=fs)
    for r in range(8):
        d.text((x0 - 26, y0 + r * 24 + 4), f'{r}', fill=DIM, font=fs)
    S = 24

    def box(r, c, w, h, colour):
        d.rectangle((x0 + c * S, y0 + r * S, x0 + (c + w) * S - 1, y0 + (r + h) * S - 1), outline=colour, width=2)

    fields = [  # row, col, width, height, colour, label anchor side, text
        (0, 0, 32, 1, ACC, 'menu bar: StatusBarText $5F16 (PrintInline), attribute $07; a click on row 0 opens the menu '
         'by column (OpenMenuAt $640E)'),
        (1, 2, 28, 2, GRN, 'tool palette: DrawToolIcons $5DD2, 14 icons of 2 x 2 icon tiles; the current one inverted '
         '(ShowTool $6D90), the ones Funds cannot pay checkered (GreyUnaffordable $6DDA)'),
        (2, 0, 1, 1, RED, 'the scroll corner (StatusBarText\'s "+", ScrollClick $6CBF)'),
        (4, 1, 19, 1, HOT, 'tool name and price: PrintToolName $6305, GameTexts[CurrentTool $6D50], A = 19: 20 columns'),
        (4, 23, 8, 1, (200, 130, 240), 'date: PrintDate $5FAE, MonthNames[Month $8F9B] and Year $8F9C in 4 digits'),
        (5, 1, 12, 1, (90, 220, 220), 'city name: 12 letters at CityName $5F68, inside the inline text'),
        (5, 17, 7, 1, DIM, '"FUNDS $": the same inline text (DrawNameFunds $5F60)'),
        (5, 24, 7, 1, (250, 150, 60), 'funds: PrintFunds $5F80, Funds $8F97 (24 bits) by PrintNumber24 $65C1'),
        (6, 1, 29, 1, (240, 120, 180), 'advice: ShowAdvice $9997, GameTexts[23 + Advice $9996], A = 29: 30 columns'),
    ]
    ly = y0 + 8 * S + 20
    for i, (r, c, w, h, col, text) in enumerate(fields):
        box(r, c, w, h, col)
        cx = x0 + (c + w / 2) * S
        d.line((cx, y0 + (r + h) * S, cx, y0 + (r + h) * S + 4), fill=col, width=2)
        tag = str(i + 1)
        k = sum(1 for f2 in fields[:i] if f2[0] == r)
        tx, ty = x0 + 32 * S + 8 + k * 22, y0 + r * S + 3
        d.rectangle((tx, ty, tx + 17, ty + 18), fill=col)
        d.text((tx + 4, ty + 1), tag, fill=(0, 0, 0), font=fs)
        d.rectangle((20, ly + i * 36, 38, ly + i * 36 + 18), fill=col)
        d.text((24, ly + i * 36 + 1), tag, fill=(0, 0, 0), font=fs)
        words, line, lines = text.split(), '', []
        for wd in words:
            if len(line) + len(wd) + 1 > 118:
                lines.append(line)
                line = wd
            else:
                line = (line + ' ' + wd).strip()
        lines.append(line)
        for k, ln in enumerate(lines):
            d.text((48, ly + i * 36 + k * 16), ln, fill=TXT, font=fs)
    save(im, 'hud.png')


# ------------------------------------------------------------------------------------------------ frames

def icon_rows(mem, n):
    return list(mem[ICON_TILES + 8 * n: ICON_TILES + 8 * n + 8])


def cmd_frames(_a):
    mem = image()
    f, fs, fb = K.font(14), K.font(13), K.font(17)
    im = Image.new('RGB', (W, 520), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'Window frames: eight icon tiles a box, three a separator, row by row (DrawBoxRow $5ED3)', fill=TXT, font=fb)
    d.text((14, 34), 'tiles from IconTiles $E850 + 8 n of the image; the inside of a box (tile $20 in the middle '
           'operand) is skipped', fill=DIM, font=f)
    x, y = 30, 80
    for n in range(0x38, 0x43):
        d.rectangle((x - 2, y - 2, x + 8 * 6 + 1, y + 8 * 6 + 1), fill=(70, 70, 90))
        draw_bits(d, x, y, icon_rows(mem, n), 6, (255, 255, 255), (0, 0, 0))
        role = {0x38: 'top left', 0x39: 'top', 0x3A: 'top right', 0x3B: 'right', 0x3C: 'bot. right', 0x3D: 'bottom',
                0x3E: 'bot. left', 0x3F: 'left', 0x40: 'sep. left', 0x41: 'sep.', 0x42: 'sep. right'}[n]
        d.text((x, y + 54), f'${n:02X}', fill=HOT, font=fs)
        d.text((x, y + 70), role, fill=DIM, font=fs)
        x += 90
    # a small box built: 10 x 5 with a separator on row 2 (as DrawMenu draws one)
    y0 = 200
    d.text((14, y0), 'A box of width 10, height 5 as DrawBox $5E97 builds it (row by row), and a separator row '
           '(DrawMenuSeparator)', fill=TXT, font=f)
    order = [(0x38, 0x39, 0x3A)] + [(0x3F, 0x20, 0x3B)] * 3 + [(0x3E, 0x3D, 0x3C)]
    S = 24
    bx, by = 40, y0 + 34
    for r, (lt, mid, rt) in enumerate(order):
        tiles = [lt] + [mid] * 8 + [rt]
        if r == 2:
            tiles = [0x40] + [0x41] * 8 + [0x42]
        for c, t in enumerate(tiles):
            if t != 0x20:
                draw_bits(d, bx + c * S, by + r * S, icon_rows(mem, t), 3, (255, 255, 255), (0, 0, 0))
            else:
                d.rectangle((bx + c * S, by + r * S, bx + c * S + S - 1, by + r * S + S - 1), fill=(0, 0, 0))
        d.text((bx + 10 * S + 14, by + r * S + 4),
               'separator: $40, 8 x $41, $42 (BoxDims = 32 in a menu)' if r == 2 else
               f'row {r}: left ${tiles[0]:02X}, {8} x ' + ('skipped (the inside)' if tiles[1] == 0x20 else
                                                         f'${tiles[1]:02X}') + f', right ${tiles[-1]:02X}',
               fill=TXT, font=fs)
    yy = by + 5 * S + 26
    for i, line in enumerate([
            'DrawBox reads 4 bytes (row, column, width, height): the PrintInline code $FD R C W H, or a call with HL.',
            'Each DrawBoxRow call writes its three tile numbers into the operands of LD A,n at $5EE9, $5EF9 and $5F07',
            '(self-modifying code), then draws left, BoxDims-2 middle tiles and right; PrintRow + 1 after the row.',
            'The tiles take the current PrintAttr (DrawIconHere), not their own IconAttrs entry: a frame has the',
            "window's colour ($44 green on black for a menu, $47 white for a full-screen window, $38 the status box)."]):
        d.text((30, yy + i * 20), line, fill=TXT, font=fs)
    save(im, 'frames.png')


# ------------------------------------------------------------------------------------------------ texts

def cmd_texts(_a):
    mem = image()
    f, fs, fb = K.font(14), K.font(13), K.font(17)
    im = Image.new('RGB', (W, 560), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'GameTexts $5FC6: strings end with bit 7 set on their last letter; FindText $6317 counts the '
           'ends', fill=TXT, font=fb)
    d.text((14, 34), 'the first 70 bytes of the image, 14 a row: gold = a byte with bit 7 (the end of a string); '
           'below, the letter it prints', fill=DIM, font=f)
    x0, y0, cw = 110, 70, 66
    n, a = 0, GAME_TEXTS
    for row in range(5):
        d.text((14, y0 + row * 52 + 4), f'${a:04X}', fill=DIM, font=fs)
        for col in range(14):
            b = mem[a]
            end = b & 0x80
            x, y = x0 + col * cw, y0 + row * 52
            d.rectangle((x, y, x + cw - 6, y + 44), fill=(110, 80, 20) if end else PANEL)
            d.text((x + 8, y + 3), f'${b:02X}', fill=HOT if end else TXT, font=f)
            ch = chr(b & 0x7F)
            d.text((x + 8, y + 23), repr(ch)[1:-1] if ch != ' ' else '(sp)', fill=ACC, font=fs)
            if end:
                d.text((x + 34, y + 23), f'#{n}', fill=HOT, font=fs)
                n += 1
            a += 1
    y1 = y0 + 5 * 52 + 20
    lines = [
        'FindText(table, A): with A = 0 the table start is the string; else walk the bytes and count those with',
        'bit 7; when the count reaches A, the string starts one byte later.',
        'Worked example, PrintToolName with CurrentTool = 2 (POWER LINES):',
        '  $5FC6 "BULLDOZE $1": the end $B1 at $5FD0, count 1;  $5FD1 "ROAD $10": the end $B0 at $5FD8, count 2 = A,',
        '  so HL = $5FD9, the "P" of "POWER LINES $5"; PrintPadded prints it at row 4, column 1 and pads to 20 columns with '
        'spaces.',
        'Cost: FindText reads every byte before the string: 42 T a byte (61 at an end), uncontended. The advice',
        '"TORNADO DETECTED", index 49, walks 815 bytes: some 35 000 T, half a frame, more while the ULA fetches.',
    ]
    for i, ln in enumerate(lines):
        d.text((30, y1 + i * 22), ln, fill=TXT if i != 2 else HOT, font=fs)
    save(im, 'texts.png')


# ------------------------------------------------------------------------------------------------ the menu format

KIND = {0: ('text', DIM), 1: ('toggle', GRN), 2: ('action', ACC), 3: ('separator', (200, 130, 240)), 4: ('end', RED),
        8: ('number', HOT)}


def parse_menu(mem, a):
    """the items of a description at a: [(address, kind, bytes)]"""
    items = [(a, 'header', mem[a:a + 1])]
    p = a + 1
    while True:
        k = mem[p]
        q = p + 1
        if k == 1:
            q += 2
        elif k == 2:
            q += 2
        if k in (0, 1, 2, 8):
            while not mem[q] & 0x80:
                c = mem[q]
                q += {5: 5, 6: 6, 7: 4}.get(c, 1)
            q += 1
        items.append((p, k, mem[p:q]))
        p = q
        if k == 4:
            break
    return items


def cmd_menufmt(_a):
    mem = image()
    f, fs, fb = K.font(14), K.font(13), K.font(17)
    sc = shot('menus', '014409-option-auto-budget-toggled.png').resize((512, 384), Image.NEAREST)
    im = Image.new('RGB', (W, 760), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'A menu description: OptionsMenu $A32F, one item after another, against the menu it draws',
           fill=TXT, font=fb)
    d.text((14, 34), 'kind byte first: 0 text, 1 toggle + flag, 2 action + routine, 3 separator, 4 end, 8 number; '
           'bit 7 ends a text', fill=DIM, font=f)
    im.paste(sc, (W - 512 - 10, 64))
    d.text((W - 512 - 10, 64 + 388), 'menus recording frame 14409 (2 x)', fill=DIM, font=fs)
    y = 64
    for addr, kind, bs in parse_menu(mem, 0xA32F):
        if kind == 'header':
            d.text((14, y), f'${addr:04X}  {bs[0]:02X}', fill=TXT, font=fs)
            d.text((170, y), f'header: first line {bs[0]} (+1 = row 9)', fill=DIM, font=fs)
            y += 22
            continue
        name, col = KIND[kind]
        hexs = ' '.join(f'{b:02X}' for b in bs[:6]) + (' ..' if len(bs) > 6 else '')
        text = ''.join(chr(b & 0x7F) for b in bs[1 + (2 if kind in (1, 2) else 0):]) if kind in (0, 1, 2, 8) else ''
        d.rectangle((10, y - 1, 520, y + 19), fill=PANEL)
        d.text((14, y), f'${addr:04X}', fill=DIM, font=fs)
        d.text((70, y), hexs, fill=col, font=fs)
        extra = ''
        if kind in (1, 2):
            extra = f' ${bs[2] << 8 | bs[1]:04X}'
        d.text((300, y), f'{name}{extra}', fill=col, font=fs)
        y += 22
        if text.strip():
            d.text((84, y - 2), f'"{text.strip()[:30]}"', fill=TXT, font=fs)
            y += 20
    y = max(y, 470) + 10
    for i, ln in enumerate([
            'DrawMenu $67C3 draws the items from the header line + 1 down, one screen row each, text at column 1.',
            'A toggle prints ON or OFF at column 24 by its flag byte (AutoBulldoze $A32B, AutoBudget $A32C, SoundOn '
            '$A32D, DemolishWait $A32E).',
            'Every selectable item (toggle, action, number) goes into MenuItems $674A: its row and its address; RunMenu '
            'moves',
            'the highlight (attributes XOR $46: $44 green on black becomes $02 red, as on AUTO-BULLDOZE) and on SPACE',
            'flips the flag, jumps to the routine, or edits the number in place. EXIT MENU is action $6703: the RET at '
            'the end of',
            'ShowMenu, so the jump returns from RunMenu and the menu closes.']):
        d.text((14, y + i * 20), ln, fill=TXT, font=fs)
    save(im, 'menu-format.png')


# ------------------------------------------------------------------------------------------------ the dialogs

DIALOGS = [  # rec, screenshot, caption
    ('levels', '001139-level-menu.png', 'the level menu (UiTask), levels 1139'),
    ('tools', '000088-creating-landscape.png', 'CREATING LANDSCAPE, tools 88'),
    ('menus', '020528-system-menu.png', 'SYSTEM, menus 20528'),
    ('menus', '013854-about.png', 'ABOUT SIM CITY, menus 13854'),
    ('menus', '014409-option-auto-budget-toggled.png', 'OPTIONS, menus 14409'),
    ('menus', '015767-speed-menu.png', 'SIMULATION SPEED, menus 15767'),
    ('menus', '018484-disasters-menu.png', 'DISASTERS, menus 18484'),
    ('menus', '018965-windows-menu.png', 'WINDOWS, menus 18965'),
    ('menus', '019866-budget.png', 'FISCAL BUDGET, menus 19866'),
    ('menus', '020323-evaluation.png', 'EVALUATION, menus 20323'),
    ('tools', '011069-select-power-type.png', 'SELECT TYPE (power station), tools 11069'),
    ('menus', '028346-start-new-city.png', 'ARE YOU SURE ?, menus 28346'),
    ('menus', '020662-saving-menu.png', 'SAVING MENU, menus 20662'),
    ('menus', '020710-save-name.png', 'the file name, menus 20710'),
    ('menus', '020866-save-start-tape.png', 'START TAPE AND PRESS SPACE, menus 20866'),
    ('menus', '023647-load-searching.png', 'SEARCHING, menus 23647'),
    ('menus', '026140-old-landscape.png', 'USE OLD LANDSCAPE, menus 26140'),
    ('levels', '001397-city-name-metro.png', 'INPUT NEW CITY NAME, levels 1397'),
]


def cmd_dialogs(_a):
    fs, fb = K.font(13), K.font(17)
    cols, tw, th = 3, 336, 252
    rows = (len(DIALOGS) + cols - 1) // cols
    im = Image.new('RGB', (W, 50 + rows * (th + 30)), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), f'Every menu and dialog the recordings opened ({len(DIALOGS)}), each from its screenshot',
           fill=TXT, font=fb)
    for i, (rec, name, cap) in enumerate(DIALOGS):
        r, c = divmod(i, cols)
        x, y = 12 + c * (tw + 10), 44 + r * (th + 30)
        path = os.path.join(REC, rec, 'screens', name)
        if not os.path.isfile(path):
            print('missing', path)
            continue
        sc = Image.open(path).convert('RGB').resize((tw, th), Image.NEAREST)
        im.paste(sc, (x, y))
        d.text((x, y + th + 4), cap, fill=TXT, font=fs)
    save(im, 'dialogs.png')


# ------------------------------------------------------------------------------------------------ budget, evaluation

def labelled(rec, name, title, sub, labels, out):
    """a screenshot at 2 x with labels to the right: labels = [(row, col, width, text, colour)]"""
    f, fs, fb = K.font(14), K.font(13), K.font(17)
    sc = Image.open(os.path.join(REC, rec, 'screens', name)).convert('RGB').resize((512, 384), Image.NEAREST)
    im = Image.new('RGB', (W, 470), BG)
    d = ImageDraw.Draw(im)
    d.text((14, 10), title, fill=TXT, font=fb)
    d.text((14, 34), sub, fill=DIM, font=f)
    x0, y0 = 14, 70
    im.paste(sc, (x0, y0))
    lx = x0 + 512 + 22
    for i, (r, c, w, text, col) in enumerate(labels):
        d.rectangle((x0 + c * 16, y0 + r * 16, x0 + (c + w) * 16 - 1, y0 + r * 16 + 15), outline=col, width=2)
        ly = y0 + 4 + i * 390 // max(1, len(labels))
        d.line((x0 + (c + w) * 16, y0 + r * 16 + 8, lx - 4, ly + 8), fill=col, width=1)
        d.text((lx, ly), text, fill=col, font=fs)
    save(im, out)


def cmd_budget(_a):
    labels = [
        (3, 26, 5, 'TaxRate $91E4 (byte in the text, max 20): EditNumber', HOT),
        (5, 21, 8, 'TaxIncome $930E: PopLastYear / 100 x TaxRate', ACC),
        (11, 8, 6, 'TransportCost $9311 (request)', GRN),
        (11, 16, 6, 'TransportFunded $9317 (allocated)', GRN),
        (11, 26, 5, 'TransportPercent $9256 (max 100)', HOT),
        (12, 8, 6, 'PoliceCost $9313 / PoliceFunded $9319', GRN),
        (13, 8, 6, 'FireCost $9315 / FireFunded $931B', GRN),
        (17, 21, 8, 'CashFlow $9320 = TaxIncome - FundedTotal', ACC),
        (18, 21, 8, 'FundsBefore $9323 (Funds when opened)', ACC),
        (20, 21, 8, 'FundsAfter $9326: what Funds becomes', (250, 150, 60)),
        (22, 4, 25, 'GO WITH THESE FIGURES: action $6703', (200, 130, 240)),
    ]
    labelled('menus', '020006-budget-tax.png',
             'The budget window: every number is reprinted by BudgetHook $9346 while a field is edited',
             'menus recording frame 20006 (2 x): the tax rate being edited, 20 % (blue); PrintBudget $94A4 positions',
             labels, 'budget.png')


def cmd_evaluation(_a):
    labels = [
        (5, 12, 3, 'PollYes $992F: of 100 draws (0-1023) below CityScore', GRN),
        (6, 12, 3, 'PollNo $9930: the others', GRN),
        (10, 9, 3, 'Problems $9803: each 0-100, red ($42) from 20', RED),
        (12, 9, 3, 'taxes: 4 x (TaxRate - 3), here 4 x 20 - 12 = 68', RED),
        (15, 20, 8, 'LastPop $8E8A: the last census (PrintNumberVar)', ACC),
        (16, 20, 8, 'Migration $978F = PopLastYear - PopYearBefore', ACC),
        (17, 20, 9, 'CityValueLast $81E0 = 3460, then "000" (x 1000)', ACC),
        (19, 15, 10, 'GameTexts[17 + Category $975F]', HOT),
        (20, 15, 8, 'GameTexts[14 + Level $A518]', HOT),
        (21, 15, 4, 'CityScore $98FA = 4 (250 - 3 ProblemSum), clamped: 0', (250, 150, 60)),
    ]
    labelled('menus', '020323-evaluation.png',
             'The evaluation window: poll, problems and figures, printed by Evaluate $9737 (the hook)',
             'menus recording frame 20323 (2 x); EvaluationText $95D7 holds the fixed words, "CATAGORY" as spelt',
             labels, 'evaluation.png')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    cmds = {'font': cmd_font, 'hud': cmd_hud, 'frames': cmd_frames, 'texts': cmd_texts, 'menufmt': cmd_menufmt,
            'dialogs': cmd_dialogs, 'budget': cmd_budget, 'evaluation': cmd_evaluation}
    p.add_argument('what', choices=list(cmds) + ['all'])
    a = p.parse_args()
    for k in (cmds if a.what == 'all' else [a.what]):
        cmds[k](a)


if __name__ == '__main__':
    main()
