#!/usr/bin/env python3
"""Figures of docs/06-rendering.md added by the fill pass (writer fillR). Each subcommand draws one figure.

  python3 tools/fig_render.py frames     docs/img/render/player-frames.png  the 25 player frames from the image, by
                                         role, and frames 0-11 as FlipPlayerFrames mirrors them
  python3 tools/fig_render.py walk       docs/img/render/walk-cycle.png  x2: the frame DrawPlayer showed, pass by pass
                                         (PlayerFrameShown $8269), with the player cut from the screen
  python3 tools/fig_render.py flip       docs/img/render/screen-change.png  x2 743-753: the screen before, during
                                         and after the build NextScreen asked for
  python3 tools/fig_render.py mask       docs/img/render/mask.png  c1 16200: the player behind the gantry, the shifted
                                         frame, the OpenCells mask, the result, and the 12 cells ColourCells visits
  python3 tools/fig_render.py small      docs/img/render/small-sprite.png  SmallSprites: sprite 7 (the ball) in its four
                                         pre-shifted copies, byte by byte
  python3 tools/fig_render.py element    docs/img/render/element-turret.png  ElementGunTurret $8681 byte by byte, and
                                         the cells and map values it leaves at row 14, column 20 of screen 0
  python3 tools/fig_render.py elements   docs/img/render/elements.png  all 62 scenery elements through the printer model
  python3 tools/fig_render.py stars      docs/img/render/stars.png  c1: screen 0's stars after two builds
  python3 tools/fig_render.py zoneend    docs/img/render/zone-end.png  w/024: the zone-end panel, before, printed,
                                         and with the bravery 1
  python3 tools/fig_render.py buffers    docs/img/render/save-buffers.png  WorkArea $B181-$B6D0: who keeps an image where,
                                         and the bytes in use at c1 16200 and x2 1790

Data: the image (work/mkgame/original.bin), and memory_at reads cached in work/docs/fillR/ (the `x2` reads from the
writer's own instance; the `c1` reads from the shared read-only instance).
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_docb as B  # noqa: E402

K = B.K
FILL = os.path.join(B.WORK, 'docs', 'fillR')
PLAYER = 0xEF80
ROLE = {0: 'walk', 1: 'walk', 2: 'walk', 3: 'walk, air', 4: 'walk', 5: 'walk, stand', 6: 'walk', 7: 'walk',
        8: 'walk', 9: 'walk, fall', 10: 'crouch', 11: 'death'}


def sprite_image(rows, width_bytes, scale, fg=(235, 235, 235), bg=(0, 0, 0)):
    """rows: a list of byte strings (one a pixel line) -> a PIL image scaled by scale"""
    h = len(rows)
    im = Image.new('RGB', (width_bytes * 8, h), bg)
    px = im.load()
    for y, row in enumerate(rows):
        for b in range(width_bytes):
            v = row[b]
            for x in range(8):
                if v >> (7 - x) & 1:
                    px[b * 8 + x, y] = fg
    return im.resize((im.width * scale, im.height * scale), Image.NEAREST)


def player_rows(mem, n, mirrored=False):
    a = PLAYER + 96 * n
    rows = [bytes(mem[a + 3 * y:a + 3 * y + 3]) for y in range(32)]
    if mirrored:
        rev = [int(f'{v:08b}'[::-1], 2) for v in range(256)]
        rows = [bytes([rev[r[2]], rev[r[1]], rev[r[0]]]) for r in rows]
    return rows


def canvas(w, h):
    im = Image.new('RGB', (w, h), K.BACKGROUND)
    return im, ImageDraw.Draw(im)


def title(d, text, sub=None):
    d.text((16, 10), text, fill=K.TEXT, font=K.font(16))
    if sub:
        d.text((16, 34), sub, fill=K.DIM, font=K.font(13))


def save(im, name):
    path = B.out('render', name)
    im.save(path)
    print('wrote', os.path.relpath(path, B.CASE), im.size)


def frames():
    mem = B.image()
    S = 3
    fw, fh = 24 * S, 32 * S
    gx, gy = 14, 58
    W = 16 + 12 * (fw + gx)
    rows_y = [70, 70 + fh + gy, 70 + 2 * (fh + gy)]
    H = rows_y[2] + fh + 80
    im, d = canvas(W, H)
    title(d, 'The player\'s 25 frames at $EF80: 12 poses, the same 12 in the exoskeleton (+12), and the trap\'s picture',
          'One frame = 24 x 32 pixels, 3 bytes a line, 96 bytes: frame n at $EF80 + 96 n. Drawn from the image, 3x.')
    f, fs = K.font(13), K.font(12)
    labels = ['frames 0-11: PlayerFrame A, ExoSuit $9ED8 = 0', 'frames 12-23: the same poses + $0C (ExoSuit = $0C)',
              'frame 24: the trap (Traps $9C15), then frames 0-10 as FlipPlayerFrames leaves them (facing left)']
    for r in range(3):
        d.text((16, rows_y[r] - 22), labels[r], fill=K.TEXT, font=f)
    for n in range(25):
        if n < 24:
            r, c = divmod(n, 12)
        else:
            r, c = 2, 0
        x, y = 16 + c * (fw + gx), rows_y[r]
        fg = (235, 235, 235) if n < 24 else (240, 200, 70)
        im.paste(sprite_image(player_rows(mem, n), 3, S, fg, (30, 30, 40)), (x, y))
        role = ROLE.get(n % 12, '') if n < 24 else 'trap'
        d.text((x, y + fh + 3), f'{n} ${PLAYER + 96 * n:04X}', fill=K.TEXT, font=fs)
        d.text((x, y + fh + 18), role, fill=K.DIM, font=fs)
    for n in range(11):
        x, y = 16 + (n + 1) * (fw + gx), rows_y[2]
        im.paste(sprite_image(player_rows(mem, n, True), 3, S, (120, 200, 255), (30, 30, 40)), (x, y))
        d.text((x, y + fh + 3), f'{n} mirrored', fill=(120, 200, 255), font=fs)
        d.text((x, y + fh + 18), ROLE[n], fill=K.DIM, font=fs)
    d.text((16, H - 26), 'white: as stored (facing right); blue: each line bit-reversed and its outer bytes swapped '
           '(6.7); yellow: frame 24 is never mirrored', fill=K.DIM, font=fs)
    save(im, 'player-frames.png')


def load(name):
    return json.load(open(os.path.join(FILL, name)))


def walk():
    d0 = load('x2-walkcycle.json')
    fr = sorted(d0['frames'].items(), key=lambda kv: int(kv[0]))
    keep, prev = [], None
    for f, v in fr:              # one picture per new frame drawn
        if v[0] != prev:
            keep.append((f, v))
        prev = v[0]
    keep = keep[1:]              # the first read is the state before the window
    S = 2
    cw, ch = 44, 40              # the cut round the player, in pixels
    per = 9
    rows = -(-len(keep) // per)
    cell_w, cell_h = cw * S + 26, ch * S + 46
    W = 16 + per * cell_w
    H = 78 + rows * cell_h + 34
    im, d = canvas(W, H)
    title(d, 'x2 frames 1415-1456: the walk cycle, frame 7, 8, 9, 0, 1 ... a new frame every 2 or 3 frames (one a pass)',
          'Walk $8295 draws WalkPhase (0-9, + 1 a step that moves) as the frame; the player moves 1 unit (2 pixels) a step.')
    fs = K.font(12)
    for i, (f, v) in enumerate(keep):
        shown, xy = int(v[0], 16), bytes.fromhex(v[1])
        x, y = xy[0], xy[1]
        scr = B.screen(bytes.fromhex(v[4]))
        px, py = 2 * x - 10, y - 4
        cut = scr.crop((px, py, px + cw, py + ch)).resize((cw * S, ch * S), Image.NEAREST)
        r, c = divmod(i, per)
        X, Y = 16 + c * cell_w, 74 + r * cell_h
        im.paste(cut, (X, Y))
        d.text((X, Y + ch * S + 3), f'frame {shown}', fill=(240, 200, 70), font=K.font(13))
        d.text((X, Y + ch * S + 20), f'x2 {f}  X ${x:02X}', fill=K.DIM, font=fs)
    d.text((16, H - 26), 'Each cut: 44 x 40 pixels round PlayerX, PlayerY at the start of the frame (memory_at), 2x; '
           'the label: PlayerFrameShown $8269.', fill=K.DIM, font=fs)
    save(im, 'walk-cycle.png')


def flip():
    d0 = load('x2-flip.json')
    fr = dict(d0['frames'])
    pics = [(743, 'f743: screen 0; the player at X $7F,\nclipped to one blank byte'),
            (746, 'f746: ClearPlayArea: the attributes\nblack first, then the pixel lines'),
            (748, 'f748: the elements print in layout order:\nthe floor and the ground first'),
            (750, 'f750: the radar dish and the missiles;\nno player on the screen'),
            (752, 'f752: the stars are in; the object lists\nare built; the build ends at T 21 399'),
            (756, 'f756: the next pass: DrawPlayer draws\nframe 3 at X 1, Y $70')]
    S = 1.25
    pw, ph = int(256 * S), int(192 * S)
    gx, gy = 16, 50
    W = 16 + 3 * (pw + gx)
    H = 74 + 2 * (ph + gy) + 10
    im, d = canvas(W, H)
    title(d, 'x2 frames 743-756: the screen change is drawn while the player watches, about 9 frames of building',
          'memory_at at the start of each frame; ScreenNumber $8523 0 -> 1 at f743 T 16 448, BuildScreen from T 18 863.')
    f = K.font(13)
    for i, (fn, cap) in enumerate(pics):
        v = fr[str(fn)]
        scr = B.screen(bytes.fromhex(v[3])).resize((pw, ph), Image.NEAREST)
        r, c = divmod(i, 3)
        X, Y = 16 + c * (pw + gx), 66 + r * (ph + gy)
        im.paste(scr, (X, Y))
        d.multiline_text((X, Y + ph + 4), cap, fill=K.TEXT, font=f, spacing=2)
    save(im, 'screen-change.png')


def grid(d, x, y, cols, rows, cell, colour=(90, 90, 110)):
    for c in range(cols + 1):
        d.line([(x + c * cell, y), (x + c * cell, y + rows * cell)], fill=colour, width=1)
    for r in range(rows + 1):
        d.line([(x, y + r * cell), (x + cols * cell, y + r * cell)], fill=colour, width=1)


def mask():
    v = load('x2-388.json')['frames']['389']
    M = B.image()
    n, (x, y) = int(v[0], 16), bytes.fromhex(v[1])
    kept = bytes.fromhex(v[3])
    mem = bytes.fromhex(v[4])
    shift = (2 * x) & 7
    col, row = x // 4, y // 8
    rows_frame = player_rows(M, n)
    shifted = []
    for r in rows_frame:
        w = ((r[0] << 16 | r[1] << 8 | r[2]) << 8) >> shift
        shifted.append(w.to_bytes(4, 'big'))
    kept_rows = [kept[4 * i:4 * i + 4] for i in range(32)]
    oc = mem[0x1B00:0x1E00]
    ac = mem[0x1E00:0x2100]
    at = mem[0x1800:0x1B00]
    S = 9
    cell = 8 * S
    pw = 4 * cell
    gx = 40
    W = 16 + 3 * (pw + gx)
    top = 74
    capH = 60
    H = top + 2 * (pw + capH) + 150
    im, d = canvas(W, H)
    title(d, 'x2 f388: behind the gantry pillar, OpenCells cuts the shifted frame cell by cell',
          f'Frame {n} at X ${x:02X} (pixel {2 * x}), Y ${y:02X}: cells rows {row}-{row + 3}, columns {col}-{col + 3}; '
          f'shift {shift}. Read at the start of f389 (draw at f388 T 41 571).')
    f, fs, fm = K.font(13), K.font(12), K.font(14)

    def slot(k):
        r, c = divmod(k, 3)
        return 16 + c * (pw + gx), top + r * (pw + capH)

    def bits(rows, nbytes, X, Y, fg):
        im.paste(sprite_image(rows, nbytes, S, fg, (30, 30, 40)), (X, Y))

    X, Y = slot(0)
    bits([r + b'\x00' for r in rows_frame], 4, X, Y, (235, 235, 235))
    grid(d, X, Y, 4, 4, cell)
    d.multiline_text((X, Y + pw + 4), f'1. frame {n} as stored at ${PLAYER + 96 * n:04X}:\n3 bytes a line, read with POP',
                     fill=K.TEXT, font=f)
    X, Y = slot(1)
    bits(shifted, 4, X, Y, (235, 235, 235))
    grid(d, X, Y, 4, 4, cell)
    d.multiline_text((X, Y + pw + 4), f'2. ShiftBuffer $78DC: each line\n{shift} pixels right, 4 bytes (BigShiftLeft2)',
                     fill=K.TEXT, font=f)
    X, Y = slot(2)
    for rr in range(4):
        for cc in range(4):
            val = oc[32 * (row + rr) + col + cc]
            box = [X + cc * cell, Y + rr * cell, X + (cc + 1) * cell - 1, Y + (rr + 1) * cell - 1]
            d.rectangle(box, fill=(150, 50, 45) if val == 0 else (60, 60, 75))
            d.text((box[0] + 18, box[1] + 26), f'${val:02X}', fill=K.TEXT, font=fm)
    grid(d, X, Y, 4, 4, cell)
    d.multiline_text((X, Y + pw + 4), '3. OpenCells $5B00 under the sprite:\nred $00 = scenery in front',
                     fill=K.TEXT, font=f)
    X, Y = slot(3)
    bits(kept_rows, 4, X, Y, (120, 200, 255))
    grid(d, X, Y, 4, 4, cell)
    d.multiline_text((X, Y + pw + 4), '4. after BigMaskRows: each byte ANDed\nwith its cell; kept in $B181',
                     fill=K.TEXT, font=f)
    X, Y = slot(4)
    scr = B.screen(mem[:6912])
    cut = scr.crop((col * 8, row * 8, col * 8 + 32, row * 8 + 32)).resize((pw, pw), Image.NEAREST)
    im.paste(cut, (X, Y))
    grid(d, X, Y, 4, 4, cell, (200, 200, 60))
    d.multiline_text((X, Y + pw + 4), '5. the screen there (x2 f389): the\npillar in front, the back edge seen',
                     fill=K.TEXT, font=f)
    X, Y = slot(5)
    for rr in range(4):
        for cc in range(4):
            i = 32 * (row + rr) + col + cc
            box = [X + cc * cell, Y + rr * cell, X + (cc + 1) * cell - 1, Y + (rr + 1) * cell - 1]
            black = ac[i] == 0
            d.rectangle(box, fill=(45, 120, 60) if black else (60, 60, 75))
            d.text((box[0] + 8, box[1] + 12), f'${ac[i]:02X}', fill=K.TEXT, font=fs)
            d.text((box[0] + 8, box[1] + 38), f'-> ${at[i]:02X}', fill=(240, 200, 70) if black else K.DIM, font=fs)
    grid(d, X, Y, 4, 4, cell)
    d.multiline_text((X, Y + pw + 4), '6. ColourCells: AttrCopy -> attribute;\ngreen $00 cells take $47 (6 of 16)',
                     fill=K.TEXT, font=f)
    l = 14
    a = PLAYER + 96 * n + 3 * l
    yy = top + 2 * (pw + capH) + 6
    msk = [oc[32 * (row + 1) + col + c] for c in range(4)]
    lines = [f'A worked line: line {l} of frame {n} (cell row {row + 1}).',
             f'   stored at ${a:04X}:          {M[a]:02X} {M[a + 1]:02X} {M[a + 2]:02X}',
             f'   shifted {shift} right:          ' + ' '.join(f'{b:02X}' for b in shifted[l]),
             f'   AND the cells of row {row + 1}:   ' + ' '.join(f'{b:02X}' for b in msk),
             f'   kept, XORed on:         ' + ' '.join(f'{b:02X}' for b in kept_rows[l])]
    for i, t in enumerate(lines):
        d.text((16, yy + 22 * i), t, fill=K.TEXT if i else (240, 200, 70), font=K.font(14))
    save(im, 'mask.png')


ELEMENT_NAMES = []


def element_names():
    if not ELEMENT_NAMES:
        src = open(os.path.join(B.CASE, 'src', 'game', 'screens.asm')).read()
        i = src.index('ElementTable:')
        for line in src[i:].splitlines()[1:]:
            if not line.strip().startswith('DEFW'):
                break
            ELEMENT_NAMES.extend(n.strip()[len('Element'):] for n in line.strip()[4:].split(','))
    return ELEMENT_NAMES


class FreeCanvas(B.Canvas):
    """the printer model without PrintChar's clip, for drawing an element on its own"""

    def put(self, d, e, ch, font, c, ctype, mark):
        a = (font + 8 * ch) & 0xFFFF
        self.cells[(B.s8(d & 0xFF), B.s8(e & 0xFF))] = (bytes(self.mem[a:a + 8]), c, ctype, mark)


def element_cells(n, d=0, e=0, free=True):
    M = B.image()
    cv = (FreeCanvas if free else B.Canvas)(M)
    st = {'font': 0xD7E0, 'ctype': 1, 'mark': 0, 'marks': []}
    end = B.print_string(cv, B.element_address(n, M), d, e, 0, st)
    return cv, st, end


def cells_image(cells, r0, c0, rows, cols, scale):
    sub = {(r - r0, c - c0): v for (r, c), v in cells.items() if 0 <= r - r0 < rows and 0 <= c - c0 < cols}
    return B.render_cells(sub, rows, cols).resize((cols * 8 * scale, rows * 8 * scale), Image.NEAREST)


def element():
    import fig_hud as Hd
    import matplotlib.pyplot as plt
    import numpy as np
    from matplotlib.patches import Rectangle
    M = B.image()
    cv, st, end = element_cells(5, 14, 20, free=False)
    a0 = B.element_address(5, M)
    fig = plt.figure(figsize=(B.WIDTH, 9.4))
    gs = fig.add_gridspec(2, 3, height_ratios=[0.9, 1.6], width_ratios=[1, 1, 1])
    ax = fig.add_subplot(gs[0, :])
    _, used = Hd.string_bytes(ax, a0, f'ElementGunTurret ${a0:04X} (element 5)')
    r0, c0, rows, cols = 13, 20, 5, 6
    ax = fig.add_subplot(gs[1, 0])
    ax.imshow(np.asarray(cells_image(cv.cells, r0, c0, rows, cols, 1)), interpolation='nearest',
              extent=(c0, c0 + cols, r0 + rows, r0))
    order = []
    for (r, c) in cv.cells:
        order.append((r, c))
    ax.set_xticks([c + 0.5 for c in range(c0, c0 + cols)])
    ax.set_xticklabels([str(c) for c in range(c0, c0 + cols)], fontsize=10)
    ax.set_yticks([r + 0.5 for r in range(r0, r0 + rows)])
    ax.set_yticklabels([str(r) for r in range(r0, r0 + rows)], fontsize=10)
    ax.set_title('the model: the cells it prints\n(columns across, rows down)', fontsize=11.5)
    ax = fig.add_subplot(gs[1, 1])
    ax.set_xlim(c0, c0 + cols)
    ax.set_ylim(r0 + rows, r0)
    for (r, c), (g, at, ct, mk) in cv.cells.items():
        col = (0.55, 0.55, 0.6) if ct == 1 else (0.9, 0.45, 0.2)
        ax.add_patch(Rectangle((c, r), 0.95, 0.95, color=col))
        ax.text(c + 0.47, r + 0.32, f'{ct}', ha='center', va='center', fontsize=11, color='black')
        ax.text(c + 0.47, r + 0.70, f'${at:02X}', ha='center', va='center', fontsize=10, color='black')
    ax.set_xticks([c + 0.5 for c in range(c0, c0 + cols)])
    ax.set_xticklabels([str(c) for c in range(c0, c0 + cols)], fontsize=10)
    ax.set_yticks([r + 0.5 for r in range(r0, r0 + rows)])
    ax.set_yticklabels([str(r) for r in range(r0, r0 + rows)], fontsize=10)
    ax.set_title('CellTypes (top) and attribute (bottom)\norange: kind 3, the turret; grey: 1, solid', fontsize=11.5)
    ax = fig.add_subplot(gs[1, 2])
    mem = open(os.path.join(B.WORK, 'docs', 'docA', 'c1', 'mem-at', '16200_4000.bin'), 'rb').read()
    scr = B.screen(mem[:6912])
    ax.imshow(np.asarray(scr.crop((c0 * 8, r0 * 8, (c0 + cols) * 8, (r0 + rows) * 8))), interpolation='nearest',
              extent=(c0, c0 + cols, r0 + rows, r0))
    ax.set_xticks([c + 0.5 for c in range(c0, c0 + cols)])
    ax.set_xticklabels([str(c) for c in range(c0, c0 + cols)], fontsize=10)
    ax.set_yticks([r + 0.5 for r in range(r0, r0 + rows)])
    ax.set_yticklabels([str(r) for r in range(r0, r0 + rows)], fontsize=10)
    ax.set_title('c1 frame 16200: the same cells\non screen 0 (layout record 14, 20, 5)', fontsize=11.5)
    n = Hd.legend(fig, used)
    B.suptitle(fig, 'Element 5, the gun turret, printed at row 14, column 20: 44 bytes, 18 cells; the first glyph '
               'is marked kind 3, the rest solid')
    fig.tight_layout(rect=(0, 0.04 * n, 1, 0.94), h_pad=2.5)
    B.save(fig, B.out('render', 'element-turret.png'))


def elements():
    names = element_names()
    S = 2
    items = []
    for n in range(62):
        cv, st, _ = element_cells(n)
        if not cv.cells:
            items.append((n, None, 0, 0, st['marks']))
            continue
        rs = [k[0] for k in cv.cells]
        cs = [k[1] for k in cv.cells]
        r0, c0 = min(rs), min(cs)
        rows, cols = max(rs) - r0 + 1, max(cs) - c0 + 1
        items.append((n, cells_image(cv.cells, r0, c0, rows, cols, S), rows, cols, st['marks']))
    f = K.font(12)
    W = 1050
    x, y, shelf = 16, 70, 0
    places = []
    for n, img, rows, cols, marks in sorted(items, key=lambda t: -(t[2] or 0)):
        label = f'{n} {names[n]}'
        lw = int(f.getlength(label)) + 6
        w = max(img.width if img else 0, lw, 60)
        h = (img.height if img else 16) + 20
        if x + w > W - 10:
            x, y = 16, y + shelf + 12
            shelf = 0
        places.append((n, img, x, y, label, marks))
        x += w + 14
        shelf = max(shelf, h)
    H = y + shelf + 50
    im, d = canvas(W, H)
    title(d, 'The 62 scenery elements, each printed alone by the model of PrintString (2x, tallest first)',
          'Number and name from ElementTable $852E; 22 and 39 print no glyph (one $EB mark); 18 = 19 (one string).')
    for n, img, x, y, label, marks in places:
        d.text((x, y), label, fill=K.TEXT, font=f)
        if img:
            im.paste(img, (x, y + 18))
        else:
            d.text((x, y + 18), 'mark ' + ', '.join(f'kind {k}' for _, _, k in marks), fill=K.DIM, font=f)
    d.text((16, H - 26), 'python3 tools/fig_render.py elements: the image\'s element strings run through '
           'tools/fig_docb.py print_string, without the column clip', fill=K.DIM, font=f)
    save(im, 'elements.png')


def small():
    M = B.image()
    base = 0xED40
    n = 7
    S = 10
    gx = 90
    cw = 16 * S
    W = 16 + 4 * (cw + gx)
    top = 92
    H = top + 8 * S + 12 + 8 * 22 + 60
    im, d = canvas(W, H)
    title(d, 'SmallSprites $ED40: sprite 7, the ball, as four copies, one per 2-pixel phase of X',
          'Copy k (k = X AND 3): 16 bytes at $ED40 + 64 x 7 + 16 k, 8 lines of 2 bytes, read with POP, XORed, no mask.')
    f, fm = K.font(13), K.font(13)
    for k in range(4):
        a = base + 64 * n + 16 * k
        rows = [bytes(M[a + 2 * i:a + 2 * i + 2]) for i in range(8)]
        X = 16 + k * (cw + gx)
        d.text((X, top - 22), f'copy {k} at ${a:04X}', fill=(240, 200, 70), font=f)
        im.paste(sprite_image(rows, 2, S, (120, 220, 240), (30, 30, 40)), (X, top))
        grid(d, X, top, 2, 1, 8 * S, (90, 90, 110))
        for i, r in enumerate(rows):
            d.text((X, top + 8 * S + 10 + 22 * i), f'+{2 * i:X}   {r[0]:02X} {r[1]:02X}', fill=K.TEXT, font=fm)
    d.text((16, H - 30), 'Copies 0-1: an 8 x 8 ball shifted 0 and 2 pixels; copies 2-3: a 6 x 6 ball shifted 4 and 6. '
           'The ball shrinks at two phases.', fill=K.DIM, font=f)
    save(im, 'small-sprite.png')


BUFFERS = [(0xB101, 0xB180, 'NoSaveBuffer', 'zeros: draw only'),
           (0xB181, 0xB200, 'player', 'DrawPlayer'),
           (0xB201, 0xB400, 'traps 1-4', '$80 each'),
           (0xB401, 0xB4F0, 'blasts 1-5', '$30 each'),
           (0xB4F1, 0xB520, 'missile', 'homing'),
           (0xB521, 0xB640, 'aliens 1-6', '$30 each'),
           (0xB641, 0xB6A0, 'pad', 'flicker 2'),
           (0xB6A1, 0xB6D0, 'idle', 'missile')]


def buffers():
    reads = [('c1 frame 13000: the menu', 'c1-work.json', '13000', [(0xB181, 0xB3C0, 'menu stars 1-12, $30 each')]),
             ('c1 frame 16200: play, screen 0', 'c1-work16200.json', '16200', []),
             ('x2 frame 1790: screen 3, an alien', 'x2-work.json', '1790', [])]
    lo, hi = 0xB101, 0xB6D0
    W = 1050
    x0, x1 = 16, W - 16
    sc = (x1 - x0) / (hi - lo + 1)
    top = 112
    bh = 54
    H = top + bh + 40 + len(reads) * 74 + 60
    im, d = canvas(W, H)
    title(d, 'The save buffers $B101-$B6D0: one fixed slot per moving thing, so a drawer never searches',
          'Top: the owner of each slot (the address its caller passes in HL or IY). Below: the bytes not 0 at three '
          'moments.')
    f, fs = K.font(12), K.font(11)
    cols = [(90, 150, 250), (90, 200, 120), (240, 200, 70), (230, 90, 80), (200, 110, 230), (70, 210, 220),
            (250, 150, 60), (160, 160, 180)]

    def X(a):
        return x0 + (a - lo) * sc
    for i, (a, b, name, sub) in enumerate(BUFFERS):
        d.rectangle([X(a), top, X(b + 1) - 2, top + bh], outline=cols[i], width=2)
        if X(b + 1) - X(a) > 110:
            d.text((X(a) + 4, top + 6), name, fill=cols[i], font=f)
            d.text((X(a) + 4, top + 22), sub, fill=K.DIM, font=fs)
            d.text((X(a) + 4, top + bh - 16), f'${a:04X}', fill=K.TEXT, font=fs)
        else:
            ty = top - 36 if i % 2 else top - 20
            lab = f'{name} {sub} ${a:04X}'
            tx = min(X(a), W - 16 - fs.getlength(lab))
            d.text((tx, ty), lab, fill=cols[i], font=fs)
            d.line([(X(a) + 2, ty + 14), (X(a) + 2, top)], fill=cols[i], width=1)
    y = top + bh + 40
    for label, fn, fr, extra in reads:
        data = bytes.fromhex(load(fn)['frames'][fr][0])
        d.text((x0, y - 18), label, fill=K.TEXT, font=f)
        d.rectangle([x0, y, x1, y + 30], fill=(30, 30, 40))
        for i, v in enumerate(data):
            if v:
                xx = X(lo + i)
                d.line([(xx, y), (xx, y + 30)], fill=(240, 200, 70), width=1)
        for a, b, name in extra:
            d.rectangle([X(a), y - 2, X(b + 1), y + 32], outline=(230, 90, 80), width=2)
            d.text((X(b + 1) + 6, y + 8), name, fill=(230, 90, 80), font=f)
        y += 74
    d.text((x0, H - 28), 'Yellow tick: a byte not 0 (memory_at). The menu reuses the area for 12 stars; ClearWorkArea '
           'zeroes it at every build.', fill=K.DIM, font=f)
    save(im, 'save-buffers.png')


def star_cells(scr):
    """Cells holding glyph 3 of TileSetE840 (one pixel at line 4, bit 4) on a black paper: DrawStars' stars."""
    out = []
    for r in range(22):
        for c in range(32):
            a = 0x1800 + 32 * r + c
            lines = [scr[((r & 0x18) << 8) | (k << 8) | ((r & 7) << 5) | c] for k in range(8)]
            if lines == [0, 0, 0, 0, 0x10, 0, 0, 0] and scr[a] & 0x38 == 0:
                out.append((r, c))
    return out


def stars():
    a = bytes.fromhex(load('c1-16200.json')['frames']['16200'][5])
    b = bytes.fromhex(load('c1-18950.json')['frames']['18950'][0])
    sa, sb = set(star_cells(a)), set(star_cells(b))
    S = 2
    pw, ph = 256 * S, 192 * S
    gap = 12
    W = 8 + 2 * pw + gap + 8
    H = 74 + ph + 170
    im, d = canvas(W, H)
    title(d, f'c1 screen 0 built twice: {len(sa)} stars, then {len(sb)}; only {len(sa & sb)} cells hold a star both times',
          'DrawStars $A2D5: three random columns a row, a star only where AttrCopy is 0 (black, empty); ink random 2-7.')
    f = K.font(13)
    for i, (scr, mine, other, cap) in enumerate([(a, sa, sb, 'c1 16200: the first visit (16129-16139 build)'),
                                                 (b, sb, sa, 'c1 18950: the second build of screen 0')]):
        X, Y = 8 + i * (pw + gap), 70
        im.paste(B.screen(scr).resize((pw, ph), Image.NEAREST), (X, Y))
        for r, c in mine:
            col = (255, 80, 80) if (r, c) in other else (240, 200, 70)
            d.rectangle([X + c * 8 * S, Y + r * 8 * S, X + (c + 1) * 8 * S - 1, Y + (r + 1) * 8 * S - 1],
                        outline=col, width=2)
        d.text((X, Y + ph + 6), cap, fill=K.TEXT, font=f)
    y = Y + ph + 32
    d.rectangle([12, y + 2, 26, y + 16], outline=(240, 200, 70), width=2)
    d.text((34, y), 'yellow box: a star cell (glyph 3 of TileSetE840 on black paper) found on this build only',
           fill=K.TEXT, font=f)
    d.rectangle([12, y + 24, 26, y + 38], outline=(255, 80, 80), width=2)
    d.text((34, y + 22), 'red box: a cell that holds a star on both builds', fill=K.TEXT, font=f)
    d.text((12, y + 48), 'How to read: the scenery is the same; the stars move because Random runs on.', fill=K.DIM, font=f)
    d.text((12, y + 70), 'Expected: 22 rows x 3 tries x 392 / 704 black cells = about 37 stars a build.', fill=K.DIM, font=f)
    d.text((12, y + 92), 'Command: python3 tools/fig_render.py stars (memory_at of the read-only c1 at the starts of '
           'frames 16200 and 18950).', fill=K.DIM, font=f)
    save(im, 'stars.png')


def zoneend():
    a = load('w024-zone.json')['frames']
    b = load('w024-zone2.json')['frames']
    pics = [(a['516'], 'f516: the last pass of screen 24;\nscore 000000'),
            (b['521'], 'f521: ZoneBonusText still printing\n(PrintString from f517 T 918)'),
            (b['577'], 'f577: the "1" at row 8, column 14:\n10000; the lives digit 9 at 12, 13')]
    S = 1.25
    pw, ph = int(256 * S), int(192 * S)
    gx = 14
    W = 16 + 3 * (pw + gx)
    H = 74 + ph + 120
    im, d = canvas(W, H)
    title(d, 'w/024 frames 516-577: the zone end prints one digit and one "1" into a fixed panel',
          'ZoneEnd $A817 at f517 T 918; 9 lives x 1000, then 80 x 125 points from f521 (no suit); BonusScreen at f577.')
    f = K.font(13)
    for i, (v, cap) in enumerate(pics):
        scr = B.screen(bytes.fromhex(v[0])).resize((pw, ph), Image.NEAREST)
        X, Y = 16 + i * (pw + gx), 66
        im.paste(scr, (X, Y))
        sc = bytes.fromhex(v[1]).decode()
        d.multiline_text((X, Y + ph + 4), cap + f'\nScore $AD8A: {sc}', fill=K.TEXT, font=f, spacing=2)
    d.text((16, H - 26), 'Command: python3 tools/fig_render.py zoneend (memory_at of the warp clone w/024 at the starts of '
           'frames 516, 521, 577).', fill=K.DIM, font=K.font(12))
    save(im, 'zone-end.png')


def main():
    B.style()
    {'frames': frames, 'walk': walk, 'flip': flip, 'mask': mask, 'element': element, 'elements': elements, 'small': small, 'buffers': buffers, 'stars': stars, 'zoneend': zoneend}[sys.argv[1]]()


if __name__ == '__main__':
    main()
