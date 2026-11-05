#!/usr/bin/env python3
"""The graphics of the two games side by side, for the resources part of docs/13 (work/diff/resources.md): the
sprite blocks, the fonts and where the font and the menu tune lie in each image. Every picture is drawn from the
bytes the two builds leave (tools/diff_res.py reads the same), each side through its own case's converter
(NE's tools/res_formats.py, ANE's tools/game_res.py).

    python3 tools/fig_diff_res_gfx.py sprites   docs/img/diff/res-sprites.png
    python3 tools/fig_diff_res_gfx.py font      docs/img/diff/res-font.png
    python3 tools/fig_diff_res_gfx.py memory    docs/img/diff/res-memory.png
    python3 tools/fig_diff_res_gfx.py all
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
R = os.path.abspath(os.path.join(CASE, '..', '..'))
NE_TOOLS = os.path.join(R, 'games', 'nether-earth', 'tools')
sys.path.insert(0, os.path.join(R, 'kit'))
sys.path.insert(0, HERE)
sys.path.insert(0, NE_TOOLS)
import kitlib as K  # noqa: E402
import diff_res as D  # noqa: E402
import game_res  # noqa: E402  (ANE's converter)
import res_formats  # noqa: E402  (NE's converter)
import game_text  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'diff')
SAME, CHANGED, ONLY = K.EXEC, K.WRITE_FADE[2], K.READ       # one meaning per hue in every res-* figure
BG, FG, DIM, PANEL = K.BACKGROUND, K.TEXT, K.DIM, K.PANEL


def scaled(image, s):
    return image.convert('RGB').resize((image.width * s, image.height * s), Image.NEAREST)


def title(d, y, text, sub=None):
    d.text((14, y), text, fill=FG, font=K.font(17))
    if sub:
        d.text((14, y + 24), sub, fill=DIM, font=K.font(12))


def legend(d, x, y, items):
    f = K.font(12)
    for colour, text in items:
        d.rectangle([x, y + 2, x + 12, y + 14], outline=colour, width=2)
        d.text((x + 18, y), text, fill=DIM, font=f)
        x += 18 + int(d.textlength(text, font=f)) + 22
    return x


# ------------------------------------------------------------------------------------------------------ sprites

def cmd_sprites(args):
    n, a = D.Side('NE'), D.Side('ANE')
    rows = {r['name']: r for r in D.sec_sprites(n, a)}
    files = [f for f, _ in sorted(n.files.items(), key=lambda kv: kv[1][0]) if f.startswith('gfx/sprites/')]
    files.append('gfx/view-edges.bin')
    s, cols = 2, 6
    cell_w, cell_h = 150, 122
    top = 86
    W = 14 + cols * cell_w + 10
    H = top + ((len(files) + cols - 1) // cols) * cell_h + 50
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    same = sum(1 for f in files if rows[f]['status'] == 'same')
    title(d, 10, 'All %d sprite blocks and the view edges are the same bytes in both games' % (len(files) - 1),
          "each pair: NE left, ANE right, each from its own build by its own converter; %d of %d pairs equal"
          % (same, len(files)))
    legend(d, 14, 58, [(SAME, 'same bytes, same address'), (CHANGED, 'changed (none)'),
                       (ONLY, 'only in one game (none)')])
    f, tiny = K.font(11), K.font(10)
    for i, name in enumerate(files):
        x0, y0 = 14 + (i % cols) * cell_w, top + (i // cols) * cell_h
        na, nb = n.files[name]
        aa, ab = a.files[name]
        if name.endswith('view-edges.bin'):
            pn, pa = res_formats.edges_to_png(nb), game_res.edges_to_png(ab)
        else:
            pn, pa = res_formats.sprite_to_png(nb), game_res.sprite_to_png(ab)
        pn, pa = scaled(pn, s), scaled(pa, s)
        colour = SAME if rows[name]['status'] == 'same' else CHANGED
        d.rectangle([x0, y0, x0 + cell_w - 8, y0 + cell_h - 8], fill=PANEL, outline=colour, width=1)
        d.text((x0 + 4, y0 + 2), os.path.basename(name)[:-4], fill=FG, font=f)
        d.text((x0 + 4, y0 + 15), '$%04X  %s' % (na, '=' if na == aa else '$%04X' % aa), fill=DIM, font=tiny)
        y = y0 + 30
        out.paste(pn, (x0 + 4, y))
        out.paste(pa, (x0 + 4 + pn.width + 6, y))
    d.text((14, H - 22), 'python3 tools/fig_diff_res_gfx.py sprites  (rows: python3 tools/diff_res.py --section '
           'sprites --all)', fill=DIM, font=tiny)
    path = args.out or os.path.join(OUT, 'res-sprites.png')
    out.save(path)
    print(path, out.size)


# --------------------------------------------------------------------------------------------------------- font

def glyph(data, s, ink, paper):
    im = Image.new('RGB', (8, 8), paper)
    px = im.load()
    for y in range(8):
        for x in range(8):
            if data[y] & (0x80 >> x):
                px[x, y] = ink
    return im.resize((8 * s, 8 * s), Image.NEAREST)


LOOKALIKE = {0x41, 0x42, 0x43, 0x45, 0x48, 0x4B, 0x4D, 0x4F, 0x50, 0x54, 0x58, 0x59}   # А В С Е Н К М О Р Т Х У


def cmd_font(args):
    n, a = D.Side('NE'), D.Side('ANE')
    na, nb, aa, ab = D.font_pair(n, a)
    s, cell_w, cell_h = 3, 56, 104
    top = 104
    W = 14 + 16 * cell_w + 10
    H = top + 4 * cell_h + 84
    out = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(out)
    changed = sum(1 for g in range(64) if nb[8 * g:8 * g + 8] != ab[8 * g:8 * g + 8])
    title(d, 10, 'ANE redrew %d of the 64 glyphs: Russian letters on the Latin codes, a lighter stroke' % changed,
          'each cell: code, NE glyph (Font $%04X + 8 x (code - $20)) above ANE glyph (GameFont $%04X + ...), the '
          'character each draws' % (na, aa))
    legend(d, 14, 58, [(SAME, 'same bytes (3: space, ] and the up arrow)'), (CHANGED, 'redrawn')])
    f, tiny = K.font(12), K.font(11)
    d.text((14, 80), 'letter colours under ANE\'s glyph: green a Russian letter on the Latin look-alike, orange one '
           'on another code, grey a digit or sign kept', fill=DIM, font=tiny)
    for g in range(64):
        code = 0x20 + g
        x0, y0 = 14 + (g % 16) * cell_w, top + (g // 16) * cell_h
        x, y = nb[8 * g:8 * g + 8], ab[8 * g:8 * g + 8]
        colour = SAME if x == y else CHANGED
        d.rectangle([x0, y0, x0 + cell_w - 6, y0 + cell_h - 6], fill=PANEL, outline=colour, width=2)
        d.text((x0 + 4, y0 + 2), '$%02X' % code, fill=DIM, font=tiny)
        out.paste(glyph(x, s, (230, 230, 230), (40, 40, 52)), (x0 + 4, y0 + 17))
        out.paste(glyph(y, s, (230, 230, 230), (40, 40, 52)), (x0 + 4, y0 + 17 + 8 * s + 4))
        ne_char = {0x40: '\u00a9', 0x5E: '\u2191', 0x5F: '_'}.get(code, chr(code))
        letter = game_text.GLYPHS.get(code)
        d.text((x0 + 8 * s + 9, y0 + 22), ne_char, fill=FG, font=f)
        if letter and code != 0x40:
            lc = SAME if code in LOOKALIKE else CHANGED
            if code == 0x33:
                letter = '3/З'
            d.text((x0 + 8 * s + 7, y0 + 22 + 8 * s + 4), letter, fill=lc, font=f)
        else:
            d.text((x0 + 8 * s + 9, y0 + 22 + 8 * s + 4), ne_char, fill=DIM, font=f)
    y = top + 4 * cell_h + 4
    d.text((14, y), 'NE (Argus 1987): a bold font, Latin capitals. ANE (1998): the same 64 codes, %d redrawn; no '
           'Latin letter is left,' % changed, fill=DIM, font=tiny)
    d.text((14, y + 16), 'so a Latin key name prints in Russian letters (SYM SH as "ЯУМ ЯН"). Й, Ё and Ъ have no '
           'glyph: the texts write И and Е.', fill=DIM, font=tiny)
    d.text((14, y + 32), 'The font moved from $%04X to $%04X (figure res-memory.png).' % (na, aa), fill=DIM,
           font=tiny)
    d.text((14, H - 22), 'python3 tools/fig_diff_res_gfx.py font  (rows: python3 tools/diff_res.py --section font)',
           fill=DIM, font=tiny)
    path = args.out or os.path.join(OUT, 'res-font.png')
    out.save(path)
    print(path, out.size)


# ------------------------------------------------------------------------------------------------------- memory

def cmd_memory(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import Rectangle, FancyArrowPatch
    n, a = D.Side('NE'), D.Side('ANE')

    def span(side, first, last_exclusive):
        return first, last_exclusive

    ne_font = n.by_name['Font']['addr']
    ane_font = a.by_name['GameFont']['addr']
    tune_lo = n.by_name['MenuMusic']['addr']
    tune_hi = n.by_name['ConstructionMenu']['addr']
    sprites = (n.files['gfx/sprites/tracks-x.bin'][0], n.by_name['SpriteSpare']['addr'])
    level = (n.files['map/scenery-west.bin'][0], n.by_name['ShapeMixedWallH']['end'])
    orders = (n.by_name['OrderNames']['addr'], n.by_name['OrderName8']['end'])
    ane_spare = (a.by_name['FontSpare1']['addr'], a.by_name['ConstructionMenu']['addr'])
    music_hooks = (a.by_name['MusicInterrupt']['addr'], a.by_name['SprTracksX']['addr'])
    bg = tuple(c / 255 for c in BG)
    fg, dim = tuple(c / 255 for c in FG), tuple(c / 255 for c in DIM)
    fig, ax = plt.subplots(figsize=(12, 4.6), dpi=100)
    fig.patch.set_facecolor(bg)
    ax.set_facecolor(bg)
    lanes = {'NE': 1.6, 'ANE': 0.4}
    rgb = lambda c: tuple(v / 255 for v in c)  # noqa: E731
    blocks = [
        ('NE', (0x5B00, 0xFCE9), (60, 60, 75), 'NE game image $5B00-$FCE8 (48K): sprites, order names, level, '
         'menu tune $%04X-$%04X, font $%04X' % (tune_lo, tune_hi - 1, ne_font)),
        ('ANE', (0x6731, 0xD7D8), (60, 60, 75), 'ANE game block $6731-$D7D7: the same sprites, order names and '
         'level; GameFont $%04X' % ane_font),
        ('NE', sprites, (90, 110, 130), 'sprites'), ('ANE', sprites, (90, 110, 130), 'sprites'),
        ('NE', level, (90, 130, 90), 'level'), ('ANE', level, (90, 130, 90), 'level'),
        ('NE', orders, (150, 120, 70), 'orders'), ('ANE', orders, (150, 120, 70), 'orders'),
        ('NE', (ne_font, ne_font + 512), SAME, 'Font'),
        ('NE', (tune_lo, tune_hi), K.WRITE_FADE[1], 'menu tune'),
        ('ANE', ane_spare, (110, 110, 120), ''),
        ('ANE', (ane_font, ane_font + 512), SAME, 'GameFont'),
        ('ANE', music_hooks, K.READ, 'AY hooks'),
    ]
    for lane, (lo, hi), colour, label in blocks:
        y = lanes[lane]
        big = label.startswith(('NE game', 'ANE game'))
        ax.add_patch(Rectangle((lo, y - (0.32 if big else 0.25)), hi - lo, 0.64 if big else 0.5,
                               facecolor=rgb(colour), edgecolor='none', alpha=0.45 if big else 0.95,
                               zorder=1 if big else 2))
        label = label.replace('$', r'\$')
        if big:
            ax.text(lo, y + 0.36, label, color=fg, fontsize=10, va='bottom')
        elif label:
            below = lane == 'ANE' or label != 'level'
            ax.text((lo + hi) / 2, y - 0.3 if below else y + 0.3, label, color=fg, fontsize=8.5, ha='center',
                    va='top' if below else 'bottom')
    arrows = [((ne_font + 256, lanes['NE'] - 0.27), (ane_font + 256, lanes['ANE'] + 0.27),
               'the font moves to \\$%04X,\nwhere the beeper tune was' % ane_font),
              ((tune_lo + 400, lanes['NE'] - 0.27), (music_hooks[0] + 200, lanes['ANE'] + 0.27),
               'the tune goes to bank 1 (AY TAIGA);\nits hooks and the IM 2 table take\nthe font\'s old place \\$6780')]
    for (p, q, text) in arrows:
        ax.add_patch(FancyArrowPatch(p, q, arrowstyle='-|>', mutation_scale=14, color=rgb(K.WRITE_FADE[0]),
                                     lw=1.4, zorder=3, connectionstyle='arc3,rad=0.0'))
    ax.text(0xD000, 1.0, arrows[0][2], color=rgb(K.WRITE_FADE[0]), fontsize=9, ha='left', va='center')
    ax.text(0x5C00, 1.0, arrows[1][2], color=rgb(K.WRITE_FADE[0]), fontsize=9, ha='left', va='center')
    ax.set_xlim(0x5A00, 0x10000)
    ax.set_ylim(-0.25, 2.35)
    ax.set_yticks([lanes['ANE'], lanes['NE']])
    ax.set_yticklabels(['ANE', 'NE'], color=fg, fontsize=11)
    ticks = [0x5B00, 0x6780, 0x8000, 0xA000, tune_lo, 0xD7D8, 0xE000, 0xFCE9]
    ax.set_xticks(ticks)
    ax.set_xticklabels([r'\$%04X' % t for t in ticks], color=dim, fontsize=8.5, rotation=0)
    for sp in ax.spines.values():
        sp.set_color(dim)
    ax.tick_params(colors=dim)
    ax.set_title('Same sprites, level and order names at the same addresses; the font and the menu tune swap places',
                 color=fg, fontsize=13, loc='left')
    fig.text(0.01, 0.015, 'addresses from both src/game/game.ann; python3 tools/fig_diff_res_gfx.py memory',
             color=dim, fontsize=8)
    fig.tight_layout(rect=(0, 0.03, 1, 1))
    path = args.out or os.path.join(OUT, 'res-memory.png')
    fig.savefig(path, facecolor=bg)
    print(path)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('what', choices=['sprites', 'font', 'memory', 'all'])
    p.add_argument('--out')
    args = p.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for w in (['sprites', 'font', 'memory'] if args.what == 'all' else [args.what]):
        globals()['cmd_' + w](args if args.what != 'all' else argparse.Namespace(out=None))


if __name__ == '__main__':
    main()
