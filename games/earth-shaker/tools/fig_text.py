#!/usr/bin/env python3
"""Doc 08: the figures of the HUD and the texts, drawn from the built image (build/game.bin, `$6D42-$FFFF`), the
resources (build/res) and the screens the stage-1 captures saved (work/stage1/<rec>/screens/NNNNNN.scr).

    python3 tools/fig_text.py font       docs/img/text/font.png: codes $20-$7F, who prints each
    python3 tools/fig_text.py panel      docs/img/text/panel.png: rows 22-23 of rzx-earth01 frame 2500, every field
    python3 tools/fig_text.py strings    docs/img/text/strings.png: every string in its colour, address, place
    python3 tools/fig_text.py names      docs/img/text/cave-names.png: the 32 names as CaveIntro centres them
    python3 tools/fig_text.py hiscore    docs/img/text/hiscore-table.png: the 75 bytes of HiScoreTable, before and
                                         after the hiscore recording's entry
    python3 tools/fig_text.py screens    docs/img/text/text-screens.png: the stage-1 screenshots of the text screens
    python3 tools/fig_text.py all
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

IMG = os.path.join(CASE, 'docs', 'img', 'text')
BASE = 0x6D42
GAME = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
BG, FG, DIM = (22, 22, 28), (235, 235, 235), (150, 150, 160)
PAL = [(0, 0, 0), (0, 0, 205), (205, 0, 0), (205, 0, 205), (0, 205, 0), (0, 205, 205), (205, 205, 0), (205, 205, 205)]
BRI = [(0, 0, 0), (0, 0, 255), (255, 0, 0), (255, 0, 255), (0, 255, 0), (0, 255, 255), (255, 255, 0), (255, 255, 255)]


def mem(a, n=1):
    return GAME[a - BASE:a - BASE + n]


def res(name):
    return open(os.path.join(CASE, 'build', 'res', name), 'rb').read()


def glyph_addr(code):
    """PrintText's glyph: Font - 256 + 8 x code ($BC00 + 8k)"""
    return 0xBC00 + 8 * code


def draw_glyph(img, x, y, code, scale, ink, paper=None):
    d = ImageDraw.Draw(img)
    g = mem(glyph_addr(code), 8)
    for r in range(8):
        for b in range(8):
            on = g[r] >> (7 - b) & 1
            c = ink if on else paper
            if c is not None:
                d.rectangle([x + b * scale, y + r * scale, x + (b + 1) * scale - 1, y + (r + 1) * scale - 1], fill=c)


def draw_text(img, x, y, text, scale, ink, paper=None):
    for i, ch in enumerate(text):
        draw_glyph(img, x + i * 8 * scale, y, ch if isinstance(ch, int) else ord(ch), scale, ink, paper)


def attr_colours(a):
    pal = BRI if a & 0x40 else PAL
    return pal[a & 7], pal[a >> 3 & 7]


def save(img, name):
    os.makedirs(IMG, exist_ok=True)
    p = os.path.join(IMG, name)
    img.save(p)
    print(p, img.size)


def title(d, text, f, y=8, x=10):
    d.text((x, y), text, font=f, fill=FG)


# ------------------------------------------------------------------------------------------------------------ font
TEXTS = ['scroller', 'cave-names', 'password-prompt', 'key-prompts', 'game-over', 'menu', 'win', 'hud-labels',
         'hud-line', 'control']


def font_users():
    used = {}
    for t in TEXTS:
        data = res(f'texts/{t}.bin')
        if t == 'menu':  # the DEMO MODE line ($AB27, 17 bytes) is no longer printed
            data = data[:0x27] + data[0x38:]
        for b in data:
            if b:
                used.setdefault(b, set()).add('T')
    used.setdefault(0x2D, set()).add('T')  # HI-SCORES title (DEFM at $8D5D)
    for b in b'HI-SCORES':
        used.setdefault(b, set()).add('T')
    for c in range(0x30, 0x3A):
        used.setdefault(c, set()).add('D')
    for c in (0x63, 0x64):  # AntiGravIcon / AntiGravIconOff through PrintGlyph
        used.setdefault(c, set()).add('I')
    keys = res('tables/keys.bin')
    for i in range(40):
        used.setdefault(keys[i * 3 + 2], set()).add('K')
    for i in range(40):  # EnterName / EnterPassword keep space and $40-$5A: the KeyTable's space and A-Z
        k = keys[i * 3 + 2]
        if k == 0x20 or 0x40 <= k < 0x5B:
            used.setdefault(k, set()).add('N')
    return used


def cmd_font(_a):
    used = font_users()
    f, fs = K.font(14), K.font(12)
    sc, cw, ch = 4, 64, 92
    W = 16 * cw + 20
    H = 64 + 6 * ch + 120
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The font Font $BD00-$BFFF: codes $20-$7F, glyph = $BC00 + 8 x code; the frame says who prints it', f)
    d.text((10, 30), 'drawn from build/game.bin by tools/fig_text.py font', font=fs, fill=DIM)
    cols = {'T': (60, 200, 90), 'D': (80, 160, 255), 'I': (255, 170, 40), 'K': (230, 80, 200), 'N': (60, 220, 220)}
    for code in range(0x20, 0x80):
        i = code - 0x20
        x, y = 10 + (i % 16) * cw, 60 + (i // 16) * ch
        u = used.get(code, set())
        kinds = [k for k in 'TDIKN' if k in u]
        frame = cols[kinds[0]] if kinds else (90, 90, 100)
        d.text((x + 2, y), f'${code:02X}', font=fs, fill=FG)
        ctext = chr(code) if 0x20 < code < 0x7F else ('sp' if code == 0x20 else '')
        d.text((x + 40, y), ctext, font=fs, fill=DIM)
        gx, gy = x + 14, y + 18
        d.rectangle([gx - 3, gy - 3, gx + 8 * sc + 2, gy + 8 * sc + 2], outline=frame, width=2)
        draw_glyph(img, gx, gy, code, sc, (255, 255, 255), (0, 0, 0))
        d.text((x + 2, y + 58), f'{glyph_addr(code):04X}', font=fs, fill=DIM)
        d.text((x + 40, y + 58), ''.join(k for k in 'TDIKN' if k in u), font=fs, fill=frame)
    y = 60 + 6 * ch + 4
    legend = [('T', 'printed by a text (menu, HUD line, names, scroller, ...)'), ('D', 'a digit: PrintDigits $832A'),
              ('I', 'an icon by PrintGlyph: AntiGravIcon $BF18 (c), AntiGravIconOff $BF20 (d)'),
              ('K', 'a key name on the redefine screen (KeyTable $A900: c CAPS, s SYMBOL, e ENTER)'),
              ('N', 'may be typed into a name or a password (the KeyTable\'s space and A-Z; digits are refused, no key gives @)')]
    for j, (k, t) in enumerate(legend):
        d.rectangle([12, y + j * 20 + 3, 24, y + j * 20 + 15], outline=cols[k], width=2)
        d.text((32, y + j * 20), f'{k}: {t}', font=fs, fill=FG)
    d.rectangle([700, y + 3, 712, y + 15], outline=(90, 90, 100), width=2)
    d.text((720, y), 'grey: never printed', font=fs, fill=FG)
    save(img, 'font.png')


# ------------------------------------------------------------------------------------------------------------ panel
def screen(rec, frame):
    return open(os.path.join(CASE, 'work', 'stage1', rec, 'screens', f'{frame:06d}.scr'), 'rb').read()


def scr_rows(data, r0, r1, scale):
    img = K.render_screen(b'\0' * 0x4000 + data + b'\0' * (0xC000 - len(data)))
    img = img.crop((0, r0 * 8, 256, r1 * 8))
    return img.resize((256 * scale, (r1 - r0) * 8 * scale), Image.NEAREST)


def cmd_panel(_a):
    rec, frame = 'rzx01', 2500
    data = screen(rec, frame)
    sc = 4
    strip = scr_rows(data, 21, 24, sc)  # rows 21-23
    f, fs = K.font(14), K.font(12)
    W, top = 1050, 250
    H = top + strip.height + 175
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The panel: rows 22-23 under the play window, every field with its variable and its writer', f)
    d.text((10, 30), f'rzx-earth01 frame {frame} (the stage-1 capture\'s screen, cave 1 in play; row 21 is the window\'s'
           ' last line); 4 x; tools/fig_text.py panel', font=fs, fill=DIM)
    x0 = (W - strip.width) // 2
    img.paste(strip, (x0, top))
    for c in range(0, 33, 1):
        xx = x0 + c * 8 * sc
        d.line([xx, top - 6, xx, top - 1], fill=(110, 110, 120))
        if c < 32 and c % 2 == 0:
            d.text((xx + 6, top - 22), str(c), font=fs, fill=DIM)
    for r, name in ((21, 'row 21'), (22, 'row 22'), (23, 'row 23')):
        d.text((x0 - 62, top + (r - 21) * 8 * sc + 10), name, font=fs, fill=DIM)
    # (col0, col1, label lines, above?)
    fields = [
        (1, 2, ['cave', 'CaveDigits $FD7E', 'ShowCounters'], 0),
        (4, 4, ['gem icon', 'a: IconGlyphs'], 1),
        (5, 6, ['gems needed', 'GemsNeededDigits', '$FD9E, ShowCounters'], 0),
        (8, 9, ['gems taken', 'GemDigits $FD82', 'CountGem $8394'], 1),
        (11, 12, ['b + lives', 'Lives $FD93', 'ShowCounters'], 0),
        (14, 15, ['anti-gravity', 'e + c/d icon', 'AntiGravStartScan'], 1),
        (17, 18, ['steps left', 'AntiGravDigits', '$FD8B, AntiGravPass'], 0),
        (20, 25, ['SCORE:', 'HudLine $BCE0', 'ShowHudLine'], 1),
        (26, 31, ['score', 'ScoreDigits $FD94', 'ShowScore $8342'], 0),
    ]
    ybar = top + 1 * 8 * sc
    yrow = top + 2 * 8 * sc
    for c0, c1, lines, alt in fields:
        xa, xb = x0 + c0 * 8 * sc, x0 + (c1 + 1) * 8 * sc
        d.rectangle([xa, yrow, xb - 1, yrow + 8 * sc - 1], outline=(255, 80, 80), width=2)
        ly = top + strip.height + 18 + alt * 70
        xm = (xa + xb) // 2
        d.line([xm, yrow + 8 * sc, xm, ly - 2], fill=(255, 80, 80))
        for j, t in enumerate(lines):
            w = d.textlength(t, font=fs)
            tx = max(4, min(W - w - 4, xm - w / 2))
            d.text((tx, ly + j * 16), t, font=fs, fill=FG if j == 0 else DIM)
    # the time bar
    d.rectangle([x0, ybar + 2 * sc, x0 + 256 * sc - 1, ybar + 6 * sc - 1], outline=(255, 220, 60), width=2)
    notes = ['Row 22, pixel lines 2-5 ($52C0, $53C0, $54C0, $55C0): the time bar. FillTimeBar $8654 fills it with $FF;',
             'ShiftTimeBar $8691 moves lines 0-7 of the row one pixel left every fourth pass (TimerStep $86DE); the',
             'cave ends when $52C0 is 0. Its colours are row 1 of BarAttrs $BC92 (BarColours $9224); row 2 of',
             'BarAttrs colours the line below. The digit fields are printed by PrintDigits $832A, glyph $BD80 + 8 x digit.']
    for j, t in enumerate(notes):
        d.text((10, 60 + j * 18), t, font=fs, fill=FG)
    d.text((10, 60 + 4 * 18 + 8), 'Red boxes: the fields of row 23; the yellow box: the bar\'s four lines. The labels: '
           'what, the variable, the routine that writes it.', font=fs, fill=DIM)
    save(img, 'panel.png')


# ------------------------------------------------------------------------------------------------------------ strings
# (label, address, length, row, column, attribute, printer)
STRINGS = [
    ('MenuTexts', 0xAB00, 18, 11, 4, 0x44, 'ShowMenuTexts'),
    ('MenuRedefineText', 0xAB12, 21, 13, 4, 0x46, 'ShowMenuTexts'),
    ('ControlTexts', 0xEC95, 24, 15, 4, 0x47, 'ShowControlTexts'),
    ('JoystickText', 0xECAD, 24, 17, 4, 0x46, 'ShowControlTexts'),
    ('MenuQuitText', 0xAB38, 17, 19, 4, 0x44, 'ShowMenuTexts'),
    ('MenuCopyrightText', 0xAB49, 32, 23, 0, 0x47, 'ShowMenuTexts'),
    ('MenuDemoText', 0xAB27, 17, None, None, 0x47, 'none since 1990'),
    ('HiScoresTitle', 0x8D5D, 9, 10, 11, 0x47, 'ShowHiScoreTitle'),
    ('EnterPasswordText', 0x9AE8, 32, 0, 0, 0x43, 'ShowPasswordPrompt'),
    ('KeyPrompts', 0xA978, 19, 6, 5, 0x44, 'RedefineKeys'),
    ('PromptRight', 0xA98B, 19, 8, 5, 0x44, 'RedefineKeys'),
    ('PromptUp', 0xA99E, 19, 10, 5, 0x44, 'RedefineKeys'),
    ('PromptDown', 0xA9B1, 19, 12, 5, 0x44, 'RedefineKeys'),
    ('PromptFire', 0xA9C4, 19, 14, 5, 0x44, 'RedefineKeys'),
    ('HudLabels', 0xBB00, 5, 6, 11, 0x46, 'ShowLevelLivesScore'),
    ('LivesLeftText', 0xBB05, 11, 10, 9, 0x44, 'ShowLevelLivesScore'),
    ('ScoreText', 0xBB10, 6, 12, 9, 0x42, 'ShowLevelLivesScore'),
    ('HudLine', 0xBCE0, 32, 23, 0, None, 'ShowHudLine'),
    ('GameOverTexts', 0xAA4E, 9, 8, 12, 0x44, 'ShowGameOver'),
    ('YouScoredText', 0xAA57, 10, 10, 8, 0x45, 'ShowGameOver'),
    ('ReachedLevelText', 0xAA61, 17, 12, 7, 0x45, 'ShowGameOver'),
    ('WinTexts', 0xAB6A, 26, 7, 3, 0x04, 'ShowWinTexts'),
    ('WinText2', 0xAB84, 31, 9, 1, 0x05, 'ShowWinTexts'),
    ('WinText3', 0xABA3, 8, 11, 10, 0x05, 'ShowWinTexts'),
    ('WinText4', 0xABAB, 32, 13, 0, 0x03, 'ShowWinTexts'),
    ('WinText5', 0xABCB, 28, 15, 2, 0x03, 'ShowWinTexts'),
    ('WinText6', 0xABE7, 32, 17, 0, 0x03, 'ShowWinTexts'),
    ('WinText7', 0xAC07, 30, 21, 1, 0x06, 'ShowWinTexts'),
    ('WinText8', 0xAC25, 9, 23, 22, 0x06, 'ShowWinTexts'),
    ('Credits', 0xAC2E, 49, None, None, 0x47, 'none (1988)'),
]


def cmd_strings(_a):
    f, fs = K.font(14), K.font(12)
    sc = 2
    rowh = 8 * sc + 20
    W = 1050
    H = 70 + len(STRINGS) * rowh + 10
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'Every printed string of the image, in the game\'s font and the colour its printer gives it', f)
    d.text((10, 30), 'left: the label, the address and the length; right: row,column and the printer; drawn from '
           'build/game.bin by tools/fig_text.py strings', font=fs, fill=DIM)
    hud_attr = res('tables/bar-attrs.bin')[32:]
    for i, (lab, a, n, r, c, at, who) in enumerate(STRINGS):
        y = 60 + i * rowh
        d.text((10, y + 4), f'{lab}', font=fs, fill=FG)
        d.text((10, y + 18), f'${a:04X} {n}', font=fs, fill=DIM)
        tx = 170
        data = mem(a, n)
        if n > 32:
            data = data[:32]
        for k, b in enumerate(data):
            attr = at if at is not None else hud_attr[k]
            ink, paper = attr_colours(attr)
            draw_glyph(img, tx + k * 8 * sc, y + 2, b, sc, ink, (0, 0, 0))
        place = f'{r},{c}' if r is not None else 'never'
        d.text((tx + 32 * 8 * sc + 10, y + 4), place, font=fs, fill=FG)
        d.text((tx + 32 * 8 * sc + 10, y + 18), who, font=fs, fill=DIM)
    save(img, 'strings.png')


def intro_column(name):
    """CaveIntro $92D4: B = the length without trailing spaces; C = ((21 - B) AND $FE) / 2 + 5"""
    b = len(name.rstrip(b' '))
    return ((21 - b) & 0xFE) // 2 + 5


def cmd_names(_a):
    f, fs = K.font(14), K.font(12)
    names = res('texts/cave-names.bin')
    sc = 1
    W, rowh = 1050, 22
    H = 70 + 16 * rowh + 40
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The 32 cave names (CaveNames $9700, 20 bytes each): the intro line and the password of each cave', f)
    d.text((10, 30), 'each drawn on a 32-column row 8 as CaveIntro $92D4 places it (grey: the screen\'s 32 columns, '
           'yellow tick: column 16); tools/fig_text.py names', font=fs, fill=DIM)
    for n in range(32):
        nm = names[n * 20:n * 20 + 20]
        col = intro_column(nm)
        x0 = 10 + (n // 16) * 520
        y = 60 + (n % 16) * rowh
        d.text((x0, y + 2), f'{n + 1:2d}', font=fs, fill=FG)
        d.text((x0 + 24, y + 2), f'C={col:2d}', font=fs, fill=DIM)
        sx = x0 + 74
        d.rectangle([sx, y, sx + 32 * 8 * 1.7 - 1, y + 13], fill=(0, 0, 0), outline=(70, 70, 80))
        tmp = Image.new('RGB', (256, 8), (0, 0, 0))
        draw_text(tmp, col * 8, 0, nm, 1, (255, 255, 255))
        tmp = tmp.resize((int(256 * 1.7), 14), Image.NEAREST)
        img.paste(tmp, (sx, y))
        d.line([sx + int(128 * 1.7), y - 2, sx + int(128 * 1.7), y + 15], fill=(255, 220, 60))
    save(img, 'cave-names.png')


# ------------------------------------------------------------------------------------------------------------ hiscore
def cmd_hiscore(a):
    f, fs = K.font(14), K.font(12)
    before = res('tables/hiscores.bin')
    after = bytes(a.after) if a.after else None
    tables = [('as loaded (hiscores.csv)', before)] + ([('after the hiscore recording\'s entry (frame 6685: 009835, the 7 keys typed: H H A G E N T)', after)]
                                                      if after else [])
    cw, rh = 30, 26
    W = 1050
    H = 80 + len(tables) * (5 * rh + 60) + 20
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'HiScoreTable $FD14: 5 records of 15 bytes, 6 score digits (one byte 0-9 each) then 9 name characters',
          f)
    d.text((10, 30), 'blue: the digits (byte values, not ASCII); green: the name (ASCII); tools/fig_text.py hiscore',
           font=fs, fill=DIM)
    y = 60
    for name, tb in tables:
        d.text((10, y), name, font=f, fill=FG)
        y += 24
        for r in range(5):
            rec = tb[r * 15:r * 15 + 15]
            d.text((10, y + r * rh + 5), f'${0xFD14 + r * 15:04X}  {r + 1}', font=fs, fill=DIM)
            for k, b in enumerate(rec):
                x = 100 + k * cw
                colr = (40, 70, 140) if k < 6 else (35, 110, 55)
                d.rectangle([x, y + r * rh, x + cw - 3, y + r * rh + rh - 4], fill=colr)
                d.text((x + 4, y + r * rh + 4), f'{b:02X}', font=fs, fill=FG)
            # as shown
            sx = 100 + 15 * cw + 30
            rowimg = Image.new('RGB', (16 * 8, 8), (0, 0, 0))
            ink = BRI[(6 - r) if r < 5 else 7]
            ink = attr_colours(0x41 + (5 - r))[0]
            draw_text(rowimg, 0, 0, bytes(0x30 + v for v in rec[:6]), 1, ink)
            draw_text(rowimg, 7 * 8, 0, rec[6:], 1, ink)
            rowimg = rowimg.resize((16 * 8 * 2, 16), Image.NEAREST)
            img.paste(rowimg, (sx, y + r * rh + 2))
        y += 5 * rh + 30
    save(img, 'hiscore-table.png')


SCREENS = [('menu', 'the menu: ShowMenuTexts $8A3C, menu.png'), ('redefine', 'the key prompts $A978, redefine.png'),
           ('hiscores', 'the high scores: ShowHiScoreTable $B26C, hiscores.png'),
           ('hiscore-entered', 'during the entry (frame 5000): 009835 HH, hiscore-entered.png'),
           ('intro-cave01', 'the cave intro: CaveIntro $92D4, intro-cave01.png'),
           ('time-running-out', 'the panel late in a cave: time-running-out.png'),
           ('game-over', 'game over: ShowGameOver $8B7F, game-over.png'), ('win', 'the win: ShowWinTexts $A815, win.png')]


def cmd_screens(_a):
    f, fs = K.font(14), K.font(12)
    W, cell_h = 1050, 384 + 28
    H = 40 + 4 * cell_h
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    title(d, 'The text screens as the stage-1 recordings left them (docs/img/play, 2x); tools/fig_text.py screens', f)
    for i, (name, cap) in enumerate(SCREENS):
        x = 6 + (i % 2) * 522
        y = 40 + (i // 2) * cell_h
        d.text((x, y), cap, font=fs, fill=FG)
        img.paste(Image.open(os.path.join(CASE, 'docs', 'img', 'play', name + '.png')).convert('RGB'), (x, y + 22))
    save(img, 'text-screens.png')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['font', 'panel', 'strings', 'names', 'hiscore', 'screens', 'all'])
    p.add_argument('--after', type=lambda s: bytes.fromhex(s), help='the 75 bytes of HiScoreTable after the entry')
    a = p.parse_args()
    cmds = {'font': cmd_font, 'panel': cmd_panel, 'strings': cmd_strings, 'names': cmd_names, 'hiscore': cmd_hiscore, 'screens': cmd_screens}
    for k in (cmds if a.what == 'all' else [a.what]):
        cmds[k](a)


if __name__ == '__main__':
    main()
