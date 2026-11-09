#!/usr/bin/env python3
"""Figures of docs/08-hud-and-text.md (writer mpB). Each subcommand draws one figure into docs/img/hud/.

  python3 tools/fig_hud.py panel   panel.png   the HUD of i1 frame 1200 (docs/img/play/i1-rock-point-a.png), 2 screen
                                               pixels a Spectrum pixel, every field numbered with address and routine
  python3 tools/fig_hud.py fonts   fonts.png   the three fonts of the print code from src/res/fonts/*.png, labelled
  python3 tools/fig_hud.py pages   pages.png   the title, options, heroes and bonus pages from docs/img/play
  python3 tools/fig_hud.py entry   entry.png   the hi-score entry (g1 4300) and the table after it (h1 4700)
  python3 tools/fig_hud.py all
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_rendering as R  # noqa: E402

K = R.K
W = R.W
F, FB, FS = R.F, R.FB, R.FS
R.OUT = os.path.join(R.CASE, 'docs', 'img', 'hud')
PLAY = R.PLAY
RES = os.path.join(R.CASE, 'src', 'res', 'fonts')
YEL = (255, 210, 70)

# (number, x0, y0, x1, y1 in Spectrum pixels, label)
FIELDS = [
    (1, 0, 0, 15, 15, 'player icon HudPlayerIcon $9469 at $4000 (HudDraw $9136)'),
    (2, 2, 16, 15, 23, '1P / 2P labels HudText1P $93F4, HudText2P $93F9; the current one inverted ($91D2)'),
    (3, 16, 0, 79, 7, 'hi-score: THE GREATEST $88C2 + its point $88AC, x $10 y 1 (HudHiScore $91DD)'),
    (4, 16, 16, 79, 23, 'score $B272, 4 BCD bytes + "-" + point letter, x $10 y $11 (HudPrintScore $92DA)'),
    (5, 80, 0, 143, 7, 'lives $B284: up to 4 buggy icons, attributes $580A-$5811 (HudLives $9263)'),
    (6, 80, 8, 143, 15, 'course marks: the sector-end letters E J P U Z of HudPanel $9481 (BlitRows)'),
    (7, 85, 16, 143, 23, 'progress: a dot every 2 px from x $57 to 2 x point + $56, y $13 (HudProgress $92AA)'),
    (8, 155, 0, 207, 7, 'TIME: $B285-$B286, 4 BCD digits at x $B3 y 1 (HudPrintTime $922A, once a second)'),
    (9, 158, 8, 207, 15, 'POINT: $B27C as a letter at x $C2 y 9 (HudPrintPoint $9247; "@" = none yet)'),
    (10, 155, 16, 207, 23, 'course name x $9B y $11: HudTextBeginner $940F / HudTextChampion $941B'),
    (11, 216, 0, 255, 23, 'lamps $B27E: col 27 the lamp, 28-31 the hidden DANGER! / CAUTION (HudLamps $927E)'),
]


def fig_panel():
    shot = Image.open(os.path.join(PLAY, 'i1-rock-point-a.png')).convert('RGB')
    hud = shot.crop((0, 0, 512, 48)).resize((1024, 96), Image.NEAREST)
    s = 4  # screen px a Spectrum pixel in the enlarged crop
    top = 70
    im, d = R.canvas(top + 96 + 40 + 24 * len(FIELDS) + 40)
    R.title(d, 'The HUD, rows 0-2 (i1 frame 1200, Beginner, before point A)',
            '4 screen pixels a Spectrum pixel; each number marks one field, listed below with its address')
    x0 = 13
    im.paste(hud, (x0, top))
    for n, a, b, c, e, _ in FIELDS:
        d.rectangle([x0 + a * s, top + b * s, x0 + (c + 1) * s - 1, top + (e + 1) * s - 1], outline=YEL, width=2)
    # numbers under the panel, one row, at each field's left edge
    for n, a, b, c, e, _ in FIELDS:
        yy = top + 96 + 6 + (14 if b >= 8 else 0) + (14 if b >= 16 else 0)
        d.text((x0 + a * s + 2, yy), str(n), font=FS, fill=YEL)
    y = top + 96 + 52
    for n, a, b, c, e, label in FIELDS:
        d.text((16, y), '%2d  %s' % (n, label), font=FS, fill=K.TEXT)
        if FS.getlength('%2d  %s' % (n, label)) > W - 24:
            print('TOO WIDE: field %d' % n)
        y += 24
    d.text((16, y + 6), 'Colours: HudAttributes $9621 (rows 0-2). The panel 3-7 and 11 are cell colours, no sprite.',
           font=FS, fill=K.DIM)
    R.save(im.crop((0, 0, W, y + 34)), 'panel.png')


def fig_fonts():
    names = [('FontSmall $F100, font 0: 4 px wide (I 4, M/W 6, space 2), 5 rows, step 6; colours its cells',
              'FontSmall.png'),
             ('FontBold $F400, font 1: 6 px wide (I 5, M/W 6, space 5), 6 rows, step 9; colours its cells',
              'FontBold.png'),
             ('FontPlain $F700, font 2: 6 px wide, 6 rows, step 8; leaves the colours alone', 'FontPlain.png')]
    ims = [Image.open(os.path.join(RES, f)).convert('RGB') for _, f in names]
    sc = []
    for i in ims:
        k = max(1, (W - 32) // i.size[0])
        sc.append(i.resize((i.size[0] * k, i.size[1] * k), Image.NEAREST))
    h = 70 + sum(i.size[1] + 40 for i in sc) + 40
    im, d = R.canvas(h)
    R.title(d, 'The three fonts of the print code, glyphs $20-$7F (from src/res/fonts)',
            'Each glyph is 8 bytes, one a row, top first; base + 8 x code; font 3 is the ROM font $3C00')
    y = 70
    for (label, _), i in zip(names, sc):
        d.text((16, y), label, font=FS, fill=K.TEXT)
        im.paste(i, (16, y + 24))
        y += i.size[1] + 40
    R.save(im.crop((0, 0, W, y)), 'fonts.png')


def grid(shots, name, ttl, sub):
    s = 1
    top = 70
    im, d = R.canvas(top + 2 * (384 + 34) + 10)
    R.title(d, ttl, sub)
    for k, (f, label) in enumerate(shots):
        x = 8 + (k % 2) * (512 + 10)
        y = top + (k // 2) * (384 + 34)
        d.text((x, y), label, font=FS, fill=K.TEXT)
        im.paste(Image.open(os.path.join(PLAY, f)).convert('RGB'), (x, y + 24))
    R.save(im, name)


def fig_pages():
    grid([('a1-title.png', 'title page (a1 frame 100): TitleText $8413'),
          ('a1-options.png', 'options page (a1 700): OptionsText $84FA'),
          ('a1-heroes-table.png', 'heroes page (a1 300): HeroesDrawTables $8AE0'),
          ('i1-bonus-e.png', 'sector bonus E (i1 5400): SectorBonus $A4EE')],
         'pages.png', 'The menu pages and the bonus screen, as the recordings show them',
         '2 screen pixels a Spectrum pixel; the frames are those of WALKTHROUGH 6.1')


def fig_entry():
    grid([('g1-heroes-entry.png', 'the entry prompt (g1 4300): HiScoreEntry $8B8F'),
          ('h1-initials.png', 'the initials typed (h1 4500): EntryFieldEdit'),
          ('h1-heroes-after-entry.png', 'the tables after the entry (h1 4700)'),
          ('h2-greatest-name.png', 'THE GREATEST: the name typed over the old (h2 700)')],
         'entry.png', 'The hi-score entry: prompt, initials, the tables after, THE GREATEST',
         '2 screen pixels a Spectrum pixel; frames as in WALKTHROUGH 6.1')


FIGS = {'panel': fig_panel, 'fonts': fig_fonts, 'pages': fig_pages, 'entry': fig_entry}

if __name__ == '__main__':
    names = sys.argv[1:] or ['all']
    for n in (FIGS if names == ['all'] else names):
        FIGS[n]()
