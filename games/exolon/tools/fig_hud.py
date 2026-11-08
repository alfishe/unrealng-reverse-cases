"""Figures of docs/08-hud-and-text.md (docs agent B).

  python3 tools/fig_hud.py strings   docs/img/hud/strings-hud.png, strings-menu.png  HudText, MenuText: bytes by code
                                     kind, the model's rendering, the recording
  python3 tools/fig_hud.py glyphs    docs/img/hud/glyphs.png, tiles.png  the font and the logo; the tile area
  python3 tools/fig_hud.py screens   docs/img/hud/screens.png  the menus and texts as the recordings show them
  python3 tools/fig_hud.py writers   docs/img/hud/writers-hud.png  kit/writers_map.py on x1 frame 184, laid out
                                     900 px wide (the full views at 1x, the HUD rows at 3x, the kit's legend)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402
import numpy as np  # noqa: E402

KIND_COLOUR = {
    'glyph': (0.85, 0.85, 0.85), 'move': (0.45, 0.75, 1.0), 'new line': (0.3, 0.55, 0.9), 'ink': (1.0, 0.75, 0.3),
    'at': (0.4, 0.9, 0.5), 'attribute': (0.95, 0.5, 0.2), 'repeat': (0.8, 0.5, 1.0), 'repeat end': (0.8, 0.5, 1.0),
    'call': (1.0, 0.4, 0.6), 'run across': (0.6, 0.9, 0.9), 'run down': (0.6, 0.9, 0.9), 'glyph set': (0.9, 0.9, 0.3),
    'space': (0.6, 0.6, 0.6), 'cell type': (0.95, 0.3, 0.3), 'drawn': (0.7, 0.4, 0.3), 'empty': (0.7, 0.4, 0.3),
    'mark cell': (0.95, 0.3, 0.3), 'end': (0.5, 0.5, 0.5),
}


def string_bytes(ax, hl, title, per_row=16):
    """the bytes of the string at hl (sub-strings not followed), each coloured by its code's kind"""
    M = B.image()
    cv = B.Canvas(M)
    st = {'font': 0xD7E0, 'ctype': 1, 'mark': 0, 'marks': []}
    B.print_string(cv, hl, 0, 0, 0, st)
    top = [(a, n, k) for a, n, k, d in cv.log if d == 0]
    end = top[-1][0] + 1
    used = set()
    for a, n, k in top:
        for i in range(n):
            j = a + i - hl
            r, c = divmod(j, per_row)
            col = KIND_COLOUR[k]
            ax.add_patch(Rectangle((c, r), 0.95, 0.9, color=col, alpha=0.85 if i == 0 else 0.45))
            v = M[a + i]
            txt = chr(v) if (k in ('glyph',) and 0x20 < v < 0x5B) else f'{v:02X}'
            ax.text(c + 0.47, r + 0.5, txt, ha='center', va='center', fontsize=11, color='black',
                    family='DejaVu Sans Mono')
        used.add(k)
    rows = -(-(end - hl) // per_row)
    ax.set_xlim(0, per_row)
    ax.set_ylim(rows, 0)
    ax.set_yticks([r + 0.5 for r in range(rows)])
    ax.set_yticklabels([f'${hl + per_row * r:04X}' for r in range(rows)], fontsize=10.5, family='DejaVu Sans Mono')
    ax.set_xticks([c + 0.47 for c in range(per_row)])
    ax.set_xticklabels([f'+{c:X}' for c in range(per_row)], fontsize=10)
    ax.xaxis.tick_top()
    ax.set_title(f'{title}: {end - hl} bytes, {len(top)} codes (bright: the code byte, pale: its operands)',
                 fontsize=12)
    return cv, used


def legend(fig, used):
    kinds = [k for k in B.KINDS if k in used]
    handles = [Rectangle((0, 0), 1, 1, color=KIND_COLOUR[k]) for k in kinds]
    fig.legend(handles, kinds, loc='lower center', ncol=min(len(kinds), 6), frameon=False)
    return -(-len(kinds) // 6)


def strings():
    B.style()
    # HudText: the bytes, then the model and the recording, each rows 22-23 full width
    fig = plt.figure(figsize=(B.WIDTH, 7.6))
    gs = fig.add_gridspec(3, 1, height_ratios=[2.2, 0.55, 0.55])
    ax = fig.add_subplot(gs[0])
    cv, used = string_bytes(ax, 0x76A2, 'HudText $76A2')
    ax = fig.add_subplot(gs[1])
    im = B.render_cells(cv.cells, 2, 32, 22, 0)
    ax.imshow(np.asarray(im), interpolation='nearest', aspect='equal')
    ax.set_title('the model: rows 22-23 (the score sub-string $AD82 followed)', fontsize=11.5)
    ax.set_xticks([])
    ax.set_yticks([])
    ax = fig.add_subplot(gs[2])
    m = B.snapshot_ram('x1', 250)
    ax.imshow(np.asarray(B.screen(m))[176:192], interpolation='nearest', aspect='equal')
    ax.set_title('x1 frame 250: rows 22-23 (the numbers by PrintCharAttr)', fontsize=11.5)
    ax.set_xticks([])
    ax.set_yticks([])
    rows = legend(fig, used)
    B.suptitle(fig, 'HudText through PrintString $AF2B: every byte is a glyph or a code; the model of the printer '
               'draws what x1 shows')
    fig.tight_layout(rect=(0, 0.045 * rows, 1, 0.93))
    B.save(fig, B.out('hud', 'strings-hud.png'))
    # MenuText: the bytes, then the model and h1's menu side by side
    fig = plt.figure(figsize=(B.WIDTH, 12))
    gs = fig.add_gridspec(2, 2, height_ratios=[1.45, 1])
    ax = fig.add_subplot(gs[0, :])
    cv, used = string_bytes(ax, 0x6E17, 'MenuText $6E17')
    ax = fig.add_subplot(gs[1, 0])
    im = B.render_cells(cv.cells)
    ax.imshow(np.asarray(im), interpolation='nearest')
    marked = [(r, c) for (r, c), v in cv.cells.items() if v[2] == 1]
    ax.set_title(f'the model: the menu\n({len(marked)} cells get CellTypes 1 from $E8 01)', fontsize=11.5)
    ax.set_xticks([])
    ax.set_yticks([])
    ax = fig.add_subplot(gs[1, 1])
    ax.imshow(np.asarray(B.scr_file(os.path.join(B.WORK, 'h1', 'screens', '008000.scr'))), interpolation='nearest')
    ax.set_title('h1 frame 8000: the menu as drawn,\nthe stars on free cells', fontsize=11.5)
    ax.set_xticks([])
    ax.set_yticks([])
    rows = legend(fig, used)
    B.suptitle(fig, 'MenuText through PrintString $AF2B: the same codes build the menu; the model draws what h1 '
               'shows')
    fig.tight_layout(rect=(0, 0.03 * rows, 1, 0.95), h_pad=3)
    B.save(fig, B.out('hud', 'strings-menu.png'))


class TileCanvas(B.Canvas):
    def __init__(self, mem):
        super().__init__(mem)
        self.addresses = set()

    def put(self, d, e, ch, font, c, ctype, mark):
        if not e & 0x20:
            self.addresses.add((font + 8 * ch) & 0xFFFF)
        super().put(d, e, ch, font, c, ctype, mark)


def glyphs():
    M = B.image()
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 8.4))
    gs = fig.add_gridspec(2, 1, height_ratios=[1.5, 1])
    ax = fig.add_subplot(gs[0])
    codes = list(range(0x20, 0x5B))
    per = 15
    nrow = -(-len(codes) // per)
    img = np.zeros((nrow * 14, per * 10))
    for i, ch in enumerate(codes):
        r, c = divmod(i, per)
        a = 0xD7E0 + 8 * ch
        for y in range(8):
            for x in range(8):
                img[r * 14 + y + 1, c * 10 + x + 1] = M[a + y] >> (7 - x) & 1
    ax.imshow(img, cmap='gray', interpolation='nearest')
    for i, ch in enumerate(codes):
        r, c = divmod(i, per)
        ax.text(c * 10 + 5, r * 14 + 9.4, f'{ch:02X}', fontsize=11, ha='center', va='top', color=B.COLOURS[0])
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_title(f'Font $D8E0: codes $20-$5A, {len(codes)} glyphs of 8 x 8 (FontBase $D7E0 + 8 x code)')
    ax = fig.add_subplot(gs[1])
    cv = B.Canvas(M)
    st = {'font': 0xD7E0, 'ctype': 1, 'mark': 0, 'marks': []}
    B.print_string(cv, 0x70FF, 0, 0, 0x46, st)
    rows = [r for r, _ in cv.cells]
    cols = [c for _, c in cv.cells]
    im = B.render_cells(cv.cells, max(rows) + 1, max(cols) + 1)
    ax.imshow(np.asarray(im), interpolation='nearest')
    fonts = sorted({B.word(M, a + 1) for a, n, k, d in cv.log if k == 'glyph set'})
    ax.set_title('LogoText $70FF: the logo, ' + str(len(cv.cells)) + ' cells from glyph set ' +
                 ', '.join(f'${f:04X}' for f in fonts))
    ax.set_xticks([])
    ax.set_yticks([])
    B.suptitle(fig, 'One 8 x 8 font for all the text, and one logo printed from its own glyph set')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('hud', 'glyphs.png'))
    # the tile area and who draws from it
    lo, hi = 0xDAB8, 0xED40
    users = {}
    for el in range(62):
        tc = TileCanvas(M)
        st = {'font': 0xD7E0, 'ctype': 1, 'mark': 0, 'marks': []}
        B.print_string(tc, B.element_address(el), 4, 4, 0x47, st)
        for a in tc.addresses:
            if lo <= a < hi:
                users.setdefault(a, set()).add(el)
    n = (hi - lo) // 8
    per = 32
    rows = -(-n // per)
    img = np.zeros((rows * 10, per * 10, 3))
    for i in range(n):
        a = lo + 8 * i
        r, c = divmod(i, per)
        col = np.array((0.95, 0.85, 0.3)) if a in users else np.array((0.45, 0.45, 0.5))
        for y in range(8):
            for x in range(8):
                if M[a + y] >> (7 - x) & 1:
                    img[r * 10 + y + 1, c * 10 + x + 1] = col
    fig, ax = plt.subplots(figsize=(B.WIDTH, 7.6))
    ax.imshow(img, interpolation='nearest')
    ax.set_yticks([r * 10 + 4.5 for r in range(0, rows, 2)])
    ax.set_yticklabels([f'${lo + 8 * per * r:04X}' for r in range(0, rows, 2)], family='DejaVu Sans Mono')
    ax.set_xticks([c * 10 + 4.5 for c in range(0, per, 4)])
    ax.set_xticklabels([f'+${8 * c:X}' for c in range(0, per, 4)])
    k = len(users)
    ax.set_title(B.wrap(f'{n} cells of 8 bytes, {per} a row; yellow = printed by one of the 62 scenery elements '
                        f'({k} cells), grey = no element prints it (the logo glyphs from $E6B0 among them)', 105),
                 fontsize=11.5)
    B.suptitle(fig, 'The tile area $DAB8-$ED3F: 4.6 KB of glyphs that the scenery elements window into with $E6 '
               '(22 glyph-set bases)')
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    B.save(fig, B.out('hud', 'tiles.png'))


SHEET = [('m1', 250, 'define keys (m1 250)'), ('h1', 8000, 'menu (h1 8000)'), ('x1', 2750, 'GAME OVER (x1 2750)'),
         ('h1', 6500, 'name entry (h1 6500)'), ('h1', 7000, 'Hall of Fame (h1 7000)'),
         ('h1', 7750, 'Hall of Fame, scrolled (h1 7750)'), ('w/124', 750, 'CONGRATULATIONS (w/124 750)'),
         ('w/124', 1000, 'bonus screen (w/124 1000)')]


def screens():
    B.style()
    fig, axs = plt.subplots(3, 3, figsize=(B.WIDTH, 9.6))
    for ax in axs.flat[len(SHEET):]:
        ax.axis('off')
    for ax, (rec, f, name) in zip(axs.flat, SHEET):
        ax.imshow(np.asarray(B.scr_file(os.path.join(B.WORK, rec, 'screens', f'{f:06d}.scr'))),
                  interpolation='nearest')
        ax.set_title(name, fontsize=11)
        ax.set_xticks([])
        ax.set_yticks([])
    B.suptitle(fig, 'Every text screen is PrintString output over the same font and frame pieces '
               '(saved screens of m1, h1, x1 and the warp run w/124)')
    fig.tight_layout(rect=(0, 0, 1, 0.94), h_pad=2.6)
    B.save(fig, B.out('hud', 'screens.png'))


def writers():
    """kit/writers_map.py renders 1572 px (two 3x views and its legend at 11-12 px); laid out again 900 px wide so
    that nothing is scaled down: the two views at 1x, the HUD rows 22-23 of both at 3x, the kit's legend as drawn"""
    import subprocess
    from PIL import Image, ImageDraw
    raw = os.path.join(B.DOCB, 'writers-hud-raw.png')
    subprocess.run([sys.executable, os.path.join(B.KIT, 'writers_map.py'), '--work', 'work/docs/docB/x1', '--window',
                    '184:0-185:0', '--listing', 'build/game.lst', '--out', raw, '--view', 'screen', '--scale', '3',
                    '--title', 'raw'], cwd=B.CASE, check=True)
    src = Image.open(raw).convert('RGB')
    gap, top, s = 12, 34, 3                      # the kit's layout: panels at (gap, top), 768 x 576 each
    views = [src.crop((gap + k * (256 * s + gap), top, gap + k * (256 * s + gap) + 256 * s, top + 192 * s))
             for k in range(2)]
    legend = src.crop((0, top + 192 * s + 22, 430, src.height))
    W = 900
    title_f, cap_f = B.K.font(16), B.K.font(13)
    H = 70 + 192 + 26 + 2 * (48 + 26) + legend.height + 10
    out = Image.new('RGB', (W, H), B.K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((gap, 8), 'x1 frame 184: the HUD is two printers: PrintString for the labels and the score,', fill=B.K.TEXT,
           font=title_f)
    d.text((gap, 30), 'PrintCharAttr for the numbers (kit/writers_map.py, one frame traced)', fill=B.K.TEXT,
           font=title_f)
    y = 62
    x = gap
    for v, cap in zip(views, ('the screen at the frame\'s end', 'who wrote each byte (by routine)')):
        out.paste(v.resize((256, 192), Image.NEAREST), (x, y))
        d.rectangle([x, y + 176, x + 255, y + 191], outline=(255, 255, 255))
        d.text((x, y + 196), cap, fill=B.K.DIM, font=cap_f)
        x += 256 + 3 * gap
    d.text((x, y), 'The boxed rows 22-23 are\nenlarged 3x below.\n\nRed: PrintCharLine (the\nlabels, the score)\n'
           'Blue: PrintCharAttrLine\n(the four numbers)\nGreen: ClearScreenAttr', fill=B.K.TEXT, font=cap_f)
    y += 192 + 26
    for v, cap in zip(views, ('rows 22-23 as shown, 3x', 'rows 22-23, the writers, 3x')):
        out.paste(v.crop((0, 176 * s, 256 * s, 192 * s)), (gap, y))
        d.text((gap, y + 50), cap, fill=B.K.DIM, font=cap_f)
        y += 48 + 26
    out.paste(legend, (0, y))
    path = B.out('hud', 'writers-hud.png')
    out.save(path)
    print('wrote', os.path.relpath(path, B.CASE), f'{out.width}x{out.height}')


if __name__ == '__main__':
    {'strings': strings, 'glyphs': glyphs, 'screens': screens, 'writers': writers}[sys.argv[1]]()
