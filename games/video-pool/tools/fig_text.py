#!/usr/bin/env python3
"""The figures of doc 08 (HUD and text), drawn from the image and from the w1 recording (time_travel memory_at).

    python3 tools/fig_text.py hud     --work W1 --at 1060  --out docs/img/text/hud.png
    python3 tools/fig_text.py records --work W1            --out docs/img/text/records.png
    python3 tools/fig_text.py font    --work W1            --out docs/img/text/font.png
    python3 tools/fig_text.py hof     --work W1 --at 13790 --out docs/img/text/hof.png

W1 is a work folder whose instance holds w1 (re_session.py session.json), replayed from work/snaps/entry.z80 with
tests/inputs/w1.txt (work/docs/vpB/replay.py). The ROM's character set ($3D00) is read from the recording; the game's
bytes from work/mkgame/original.bin (64 KB, the address is the offset).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
import vplib  # noqa: E402

K = vplib.K
IMAGE = os.path.join(CASE, 'work', 'mkgame', 'original.bin')
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (100, 100, 108), (200, 200, 205)
COLS = [(214, 39, 40), (31, 119, 180), (44, 160, 44), (148, 103, 189), (255, 127, 14), (140, 86, 75),
        (227, 119, 194), (23, 190, 207)]
W = 1050
FONT, DIGITS, COPYRIGHT, CHARSET = 0xDEF4, 0xDFC4, 0x9F2E, 0x3D00

# (name, first, last) of the print-record files (src/res/text/README.md)
RECORD_FILES = [('HudTexts', 0x969D, 0x96E5), ('HudLastShot', 0x9740, 0x9753), ('GameOverTexts', 0x9890, 0x98B4),
                ('FrameBanner', 0x9B8E, 0x9BB7), ('PlayerBannerTexts', 0x9C8F, 0x9CA6),
                ('FoulTexts', 0x9CFD, 0x9D2B), ('ScoreBlank', 0xAA6A, 0xAA73), ('HofTitle', 0xAD4F, 0xAE91),
                ('PromptLeft', 0xB407, 0xB463), ('MenuTitle', 0xB484, 0xB604), ('KeysLine', 0xB65F, 0xB67D),
                ('VariationsTitle', 0xB74D, 0xB89B), ('PresentsTexts', 0xB936, 0xB96B),
                ('EditorTexts', 0xC54E, 0xC58C)]


def fonts():
    return K.font(15), K.font(13), K.font(19)


def image():
    return bytearray(open(IMAGE, 'rb').read())


def with_rom(a, mem):
    s = vplib.session(a.work)
    mem[0x3D00:0x4000] = vplib.read(s, 1060, 0x3D00, 0x300)
    return mem


def glyph_addr(c):
    if c == 0x7F:
        return COPYRIGHT
    if 0x30 <= c <= 0x39:
        return DIGITS + 8 * (c - 0x30)
    if 0x61 <= c <= 0x7A:
        return FONT + 8 * (c - 0x61)
    return CHARSET + 8 * (c - 0x20)


def draw_glyph(d, mem, c, x0, y0, sc, wide=False, ink=FG, paper=None):
    a = glyph_addr(c)
    for y in range(8):
        b = mem[a + y]
        for bit in range(8):
            on = b & (0x80 >> bit)
            if not on and paper is None:
                continue
            w = 2 if wide else 1
            px = x0 + bit * sc * w
            d.rectangle([px, y0 + y * sc, px + sc * w - 1, y0 + y * sc + sc - 1], fill=ink if on else paper)


def records(mem, lo, hi):
    out, a = [], lo
    while a <= hi:
        row, col, attr, n = mem[a], mem[a + 1], mem[a + 2], mem[a + 3]
        out.append((a, row, col, attr, bytes(mem[a + 4:a + 4 + n])))
        a += 4 + n
    return out


# ---------------------------------------------------------------------------------------------------------------
def fig_hud(a):
    f, fs, ft = fonts()
    s = vplib.session(a.work)
    shot = vplib.read(s, a.at, 0x4000, 6912)
    scr = K.render_screen(shot, 0).crop((0, 0, 256, 48)).resize((1024, 192), Image.NEAREST)
    img = Image.new('RGB', (W, 640), BG)
    d = ImageDraw.Draw(img)
    d.text((13, 12), 'The HUD: six print records and five numbers in rows 0-1',
           font=ft, fill=FG)
    d.text((13, 40), f'w1 frame {a.at}, rows 0-5, 4 x; each field with its cells, attribute and printer', font=f,
           fill=DIM)
    X0, Y0, C = 13, 150, 32
    img.paste(scr, (X0, Y0))
    for c in range(33):
        d.line([(X0 + c * C, Y0), (X0 + c * C, Y0 + 192)], fill=(150, 150, 150))
    for r in range(7):
        d.line([(X0, Y0 + r * C), (X0 + 1024, Y0 + r * C)], fill=(150, 150, 150))
    fields_top = [(0, 0, 3, '1up', 'HudOneUp $969D, $38', 0), (0, 3, 9, 'score 1', 'PrintHudNumber 0, $3A', 1),
                  (0, 12, 14, 'hi', 'HudHi $96B9, $38', 0), (0, 14, 20, 'hi score', 'PrintHudNumber 2', 1),
                  (0, 23, 26, '2up', 'HudTwoUp $96AB', 0), (0, 26, 32, 'score 2', 'PrintHudNumber 1', 1)]
    fields_bot = [(1, 0, 17, 'power box', 'DrawPowerBox $9395 + bar', 2, 200, 360),
                  (1, 17, 22, 'frame', 'HudFrame $96D4', 0, 420, 410),
                  (1, 22, 24, 'frame no.', 'PrintHudNumber 4', 1, 600, 360),
                  (1, 26, 31, 'shots', 'HudShots $96DD / last shot', 0, 760, 410),
                  (1, 31, 32, 'n', 'PrintHudNumber 3', 1, 880, 360),
                  (3, 20, 32, 'lives', 'DrawLives, cue sprites', 3, 640, 460),
                  (5, 0, 2, 'x1', 'DrawPocketMarks', 4, 13, 460)]
    for i, (r, c0, c1, name, how, k) in enumerate(fields_top):
        col = COLS[k]
        d.rectangle([X0 + c0 * C + 1, Y0 + r * C + 1, X0 + c1 * C - 1, Y0 + (r + 1) * C - 1], outline=col, width=3)
        ty = 70 + (i % 2) * 36
        tx = X0 + c0 * C
        d.line([(tx + 6, ty + 32), (tx + 6, Y0)], fill=col, width=2)
        d.text((tx, ty), name, font=f, fill=col)
        d.text((tx, ty + 17), how, font=fs, fill=FG)
    for i, (r, c0, c1, name, how, k, tx, ty) in enumerate(fields_bot):
        col = COLS[k]
        d.rectangle([X0 + c0 * C + 1, Y0 + r * C + 1, X0 + c1 * C - 1, Y0 + (r + 1) * C - 1], outline=col, width=3)
        lx = X0 + (c0 * C + c1 * C) // 2 if c1 - c0 < 6 else tx + 6
        d.line([(lx, Y0 + (r + 1) * C), (lx, ty - 2), (tx, ty - 2)], fill=col, width=2)
        d.text((tx, ty), name, font=f, fill=col)
        d.text((tx, ty + 17), how, font=fs, fill=FG)
    notes = ['How to read: the grid is the character cells; a box per field, its colour the kind: red a text record, '
             'blue a number,',
             'green the XorLine power box, purple sprites, orange the pocket marks. Rows 2-4 hold the messages, the '
             'potted row and the lives.',
             'Numbers: attribute $3A (red ink); scores as five digits and a fixed "0" (the score x 10), leading zeros; '
             'frame and shots none.',
             f'python3 tools/fig_text.py hud --work work/docs/vpB/w1 --at {a.at}']
    for i, t in enumerate(notes):
        d.text((13, 540 + i * 22), t, font=fs, fill=DIM if t.startswith('python3') else FG)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def fig_records(a):
    f, fs, ft = fonts()
    mem = with_rom(a, image())
    picks = [0x96D4, 0x9CFD, 0x9890, 0x9B8E]
    allrec = {}
    for name, lo, hi in RECORD_FILES:
        for r in records(mem, lo, hi):
            allrec[r[0]] = (name,) + r
    img = Image.new('RGB', (W, 740), BG)
    d = ImageDraw.Draw(img)
    d.text((13, 12), 'A print record: row, column, attribute, length, then the characters; no end marker',
           font=ft, fill=FG)
    d.text((13, 40), 'Four records of the image as bytes (top) and as PrintText $9E65 prints them (bottom)', font=f,
           fill=DIM)
    y = 75
    labels = ['row', 'col', 'attr', 'len']
    for addr in picks:
        if addr not in allrec:
            continue
        name, ad, row, col, attr, txt = allrec[addr]
        d.text((13, y), f'{name} ${ad:04X}: row {row}, column {col}, attribute ${attr:02X}'
               f'{" (bit 7: double width)" if attr & 0x80 else ""}, {len(txt)} characters', font=f, fill=FG)
        y += 24
        cells = [row, col, attr, len(txt)] + list(txt)
        cw = 40
        for i, b in enumerate(cells[:25]):
            x = 13 + i * cw
            col_ = COLS[i] if i < 4 else (230, 230, 230)
            d.rectangle([x, y, x + cw - 3, y + 44], fill=(255, 255, 255), outline=col_ if i < 4 else GRID, width=2)
            d.text((x + 5, y + 3), f'{b:02X}', font=f, fill=FG)
            lab = labels[i] if i < 4 else (chr(b) if 32 <= b < 127 else '.')
            src = '' if i < 4 else ('F' if 0x61 <= b <= 0x7A or 0x30 <= b <= 0x39 else 'R')
            d.text((x + 5, y + 24), lab + (' ' + src if src else ''), font=fs, fill=DIM)
        y += 52
        # printed
        sc = 3
        wide = bool(attr & 0x80)
        cx = 13
        paper = (205, 205, 205)
        for b in txt:
            draw_glyph(d, mem, b, cx, y, sc, wide=wide, ink=(0, 0, 0), paper=paper)
            cx += 16 * sc if wide else 8 * sc
        y += 8 * sc + 26
    notes = ['How to read: coloured boxes are the four header bytes; the rest are characters.',
             'F = the game\'s font (a-z $DEF4, 0-9 $DFC4); R = the ROM\'s CHAR_SET $3D00 (capitals, space, punctuation).',
             '$7F would be the copyright glyph $9F2E.',
             'Attribute bit 7 doubles each character across two cells: FOUL SHOT! and GAME OVER take twice their '
             'length.',
             'python3 tools/fig_text.py records --work work/docs/vpB/w1   (records read from work/mkgame/original.bin)']
    for i, t in enumerate(notes):
        d.text((13, 600 + i * 24), t, font=fs, fill=DIM if t.startswith('python3') else FG)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def fig_font(a):
    f, fs, ft = fonts()
    mem = with_rom(a, image())
    used = set()
    for name, lo, hi in RECORD_FILES:
        for r in records(mem, lo, hi):
            used.update(r[4])
    rom = sorted(c for c in used if not (0x61 <= c <= 0x7A or 0x30 <= c <= 0x39 or c == 0x7F) and 0x20 <= c < 0x80)
    img = Image.new('RGB', (W, 700), BG)
    d = ImageDraw.Draw(img)
    d.text((13, 12), 'Two fonts in one print routine: the game\'s 37 glyphs and the ROM\'s for the rest', font=ft,
           fill=FG)
    d.text((13, 40), 'PrintChar $9E7C: a-z Font $DEF4, 0-9 FontDigits $DFC4, $7F CopyrightGlyph $9F2E, others '
           'CHAR_SET + 8 (c - $20)', font=f, fill=DIM)
    sc, cw = 5, 56
    y = 80
    d.text((13, y), 'The game\'s font, $DEF4-$E013 (36 x 8 bytes):', font=f, fill=FG)
    y += 26
    chars = list(range(0x61, 0x7B)) + list(range(0x30, 0x3A))
    for i, c in enumerate(chars):
        x = 13 + (i % 18) * cw
        yy = y + (i // 18) * 70
        d.rectangle([x - 2, yy - 2, x + 8 * sc + 1, yy + 8 * sc + 1], fill=(225, 225, 225))
        draw_glyph(d, mem, c, x, yy, sc)
        d.text((x, yy + 8 * sc + 4), f'{chr(c)} {glyph_addr(c) & 0xFFFF:04X}', font=K.font(11), fill=DIM)
    y += 150
    d.text((13, y), 'Copyright, $9F2E (char $7F):', font=f, fill=FG)
    d.rectangle([13 - 2, y + 24, 13 + 8 * sc + 1, y + 26 + 8 * sc + 1], fill=(225, 225, 225))
    draw_glyph(d, mem, 0x7F, 13, y + 26, sc)
    d.text((400, y), 'The same letter both ways, double width (attribute bit 7):', font=f, fill=FG)
    for i, c in enumerate([0x66, 0x46]):
        x = 400 + i * 200
        d.rectangle([x - 2, y + 24, x + 16 * 4 + 1, y + 26 + 8 * 4 + 1], fill=(225, 225, 225))
        draw_glyph(d, mem, c, x, y + 26, 4, wide=True)
        d.text((x + 70, y + 40), f'{chr(c)} ({"game" if c > 0x60 else "ROM"})', font=fs, fill=DIM)
    y += 100
    d.text((13, y), f'The ROM glyphs the texts use ({len(rom)}), from CHAR_SET $3D00:', font=f, fill=FG)
    y += 26
    for i, c in enumerate(rom):
        x = 13 + (i % 18) * cw
        yy = y + (i // 18) * 70
        d.rectangle([x - 2, yy - 2, x + 8 * sc + 1, yy + 8 * sc + 1], fill=(225, 232, 245))
        draw_glyph(d, mem, c, x, yy, sc)
        lab = 'spc' if c == 0x20 else chr(c)
        d.text((x, yy + 8 * sc + 4), f'{lab} {glyph_addr(c):04X}', font=K.font(11), fill=DIM)
    notes = ['How to read: grey cells are the game\'s glyphs, blue cells the ROM\'s.',
             'Under each cell: the character and the address of its 8 bytes.',
             'The game\'s lower case is square and wide; the capitals are the Spectrum ROM\'s own.',
             'The texts mix them: FOUL SHOT! in capitals, the HUD in lower case.',
             'python3 tools/fig_text.py font --work work/docs/vpB/w1   (the ROM read from the recording)']
    for i, t in enumerate(notes):
        d.text((13, 576 + i * 22), t, font=fs, fill=DIM if t.startswith('python3') else FG)
    img.save(a.out)


# ---------------------------------------------------------------------------------------------------------------
def fig_hof(a):
    f, fs, ft = fonts()
    s = vplib.session(a.work)
    tab = vplib.read(s, a.at, 0xAC08, 3 * 71)
    orig = image()[0xAC08:0xAC08 + 3 * 71]
    img = Image.new('RGB', (W, 740), BG)
    d = ImageDraw.Draw(img)
    d.text((13, 12), 'The hall of fame: three slots of 71 bytes; ranking moves 9 bytes, the place stays', font=ft,
           fill=FG)
    d.text((13, 40), f'HofTable $AC08 in the image (left) and in w1 frame {a.at} after "vp" 270 (right)', font=f,
           fill=DIM)
    fields = [(0, 2, 'score', 0), (2, 9, 'name', 1), (9, 11, 'flag x,y', 2), (11, 13, 'pole x,y', 3),
              (13, 14, 'attr', 4), (14, 15, 'moves', 5), (15, 71, 'name bitmap 7 x 8', 6)]
    y = 80
    for slot in range(3):
        for k, data in enumerate((orig, tab)):
            rec = data[slot * 71:(slot + 1) * 71]
            x0 = 13 + k * 520
            score = rec[0] | rec[1] << 8
            name = bytes(rec[2:9]).decode('latin-1')
            d.text((x0, y), f'slot {slot + 1} ${0xAC08 + 71 * slot:04X}: "{name.strip()}" {score} '
                   f'(shown {score * 10})', font=f, fill=FG)
            yy = y + 24
            cw = 33
            for (lo, hi, nm, c) in fields[:6]:
                for i in range(lo, hi):
                    xx = x0 + i * cw
                    d.rectangle([xx, yy, xx + cw - 2, yy + 22], fill=(255, 255, 255), outline=COLS[c], width=2)
                    d.text((xx + 4, yy + 3), f'{rec[i]:02X}', font=fs, fill=FG)
                d.text((x0 + lo * cw, yy + 26), nm, font=K.font(11), fill=COLS[c])
            # the bitmap, 7 bytes x 8 lines, 3 x
            bx, by, sc = x0, yy + 48, 3
            for line in range(8):
                for b in range(7):
                    v = rec[15 + line * 7 + b]
                    for bit in range(8):
                        on = v & (0x80 >> bit)
                        d.rectangle([bx + (b * 8 + bit) * sc, by + line * sc, bx + (b * 8 + bit) * sc + sc - 1,
                                     by + line * sc + sc - 1], fill=(30, 30, 30) if on else (235, 235, 235))
            d.text((bx + 175, by + 4), '+$0F..+$46: the name bitmap (7 x 8)', font=K.font(11), fill=COLS[6])
        y += 140
    notes = ['How to read: one row per slot; the image\'s defaults left, w1 after the name entry right.',
             'Bytes +0..+8 (score, name) move down a slot when a new entry ranks above them.',
             'Bytes +9..+$0E (flag, pole, colour, moves) stay with the screen place.',
             'The bitmap is empty in the image; RenderName $AADF draws it: inverted glyphs, solid ink flag.',
             'Nothing writes the table to tape: the defaults return at every load.',
             f'python3 tools/fig_text.py hof --work work/docs/vpB/w1 --at {a.at}']
    for i, t in enumerate(notes):
        d.text((13, 520 + i * 22 + 80), t, font=fs, fill=DIM if t.startswith('python3') else FG)
    img.save(a.out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('figure', choices=['hud', 'records', 'font', 'hof'])
    p.add_argument('--out', required=True)
    p.add_argument('--work', required=True)
    p.add_argument('--at', type=int, default=1060)
    a = p.parse_args()
    {'hud': fig_hud, 'records': fig_records, 'font': fig_font, 'hof': fig_hof}[a.figure](a)
    print(a.out)


if __name__ == '__main__':
    main()
