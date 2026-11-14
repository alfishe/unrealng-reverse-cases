#!/usr/bin/env python3
"""The figures of doc 08 (the HUD and the texts).

    python3 tools/fig_hud.py font docs/img/hud/font.png
    python3 tools/fig_hud.py hud --work W --at F docs/img/hud/hud.png
    python3 tools/fig_hud.py letters --work W --from F --to T [--step 3] [--title T] docs/img/play/letters.gif

font: the 40 glyphs at Glyphs `$7080` (build/game.bin, the game image from `$7080`), 8 x 8, each with its number,
its address and the byte a text stores for it (glyph + `$34`): 0-9 the digits, 10 the bolt, 11 the detonator, 12
Rick's head, 13-38 A-Z, 39 the blank; and one glyph's 8 bytes in binary.

hud: the HUD row (screen row 0) at one moment of a recording (TTD memory_at), drawn 4 times, with the four fields'
columns, their attributes and the variables they show (Score `$7F1D`, Detonators `$8B3D`, Ammunition `$8B3C`,
Lives `$8B3B`).

letters: a GIF of the falling letters (DropText), one picture every --step frames: the screen, and the letter
records at `$7B8F` (8 bytes each: glyph, column, y, its fraction, the speed, the delay, the row it stops at) as
MoveLetter leaves them.
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
import zxscreen  # noqa: E402

W = 1050
ORG = 0x7080


def glyph_image(g, sc, ink=(230, 230, 230), paper=(0, 0, 0)):
    im = Image.new('RGB', (8, 8), paper)
    px = im.load()
    for y in range(8):
        for x in range(8):
            if g[y] >> (7 - x) & 1:
                px[x, y] = ink
    return im.resize((8 * sc, 8 * sc), Image.NEAREST)


def char_of(n):
    if n < 10:
        return str(n)
    if 13 <= n <= 38:
        return chr(ord('A') + n - 13)
    return {10: 'bolt', 11: 'det.', 12: 'life', 39: 'blank'}[n]


def fig_font(a):
    img_bytes = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    glyphs = img_bytes[0:40 * 8]
    f, fs, fb = K.font(13), K.font(11), K.font(16)
    img = Image.new('RGB', (W, 520), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Glyphs $7080: 40 glyphs of 8 x 8, the HUD\'s and the texts\' one font', fill=K.TEXT, font=fb)
    sc, cw, ch = 4, 100, 70
    for n in range(40):
        col, row = n % 10, n // 10
        x, y = 14 + col * cw, 44 + row * ch
        img.paste(glyph_image(glyphs[8 * n:8 * n + 8], sc), (x, y))
        d.text((x + 38, y), '%d %s' % (n, char_of(n)), fill=K.TEXT, font=fs)
        d.text((x + 38, y + 14), '$%04X' % (ORG + 8 * n), fill=K.DIM, font=fs)
        d.text((x + 38, y + 28), 'byte $%02X' % ((n + 0x34) & 0xFF), fill=K.DIM, font=fs)
    y0 = 44 + 4 * ch + 10
    n = 13
    g = glyphs[8 * n:8 * n + 8]
    d.text((14, y0), 'Glyph 13 ("A", byte $41 in a text) at $%04X, byte by byte, bit 7 the left pixel:' % (ORG + 8 * n),
           fill=K.TEXT, font=f)
    img.paste(glyph_image(g, 12), (14, y0 + 24))
    for r in range(8):
        d.text((130, y0 + 24 + r * 12 - 1), '$%02X  %s' % (g[r], format(g[r], '08b').replace('0', '.').replace('1', '#')),
               fill=K.TEXT, font=fs)
    d.text((330, y0 + 24), 'A text is a list of bytes, glyph + $34, ended by $FF.\n'
           'Letters are plain ASCII: "A" $41 is glyph 13.\n'
           'A digit d is stored as d + $34: the menus\' "1" is the byte $35, the character "5".\n'
           'A space $20 moves one column on. The HUD draws the glyphs by number, no text at all.',
           fill=K.TEXT, font=f)
    img = img.crop((0, 0, W, y0 + 24 + 8 * 12 + 14))
    img.save(a.out)
    print(a.out, img.size)


def session_mem(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def mem(frame, addr, n, t=0):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                         'offset': addr, 'length': n}, ok=False)
        return bytes.fromhex((r.structured or {})['hex'])
    return mem


def fig_hud(a):
    mem = session_mem(a.work)
    scr = mem(a.at, 0x4000, 6912)
    score, cnt = mem(a.at, 0x7F1D, 6), mem(a.at, 0x8B3B, 3)
    full = zxscreen.render(scr, 1).convert('RGB')
    row = full.crop((0, 0, 256, 8)).resize((1024, 32), Image.NEAREST)
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 250), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), a.title or 'The HUD row at frame %d' % a.at, fill=K.TEXT, font=fb)
    x0, y0 = 13, 44
    img.paste(row, (x0, y0))
    for c in range(33):
        d.line((x0 + 32 * c, y0 + 34, x0 + 32 * c, y0 + 40), fill=K.DIM)
    fields = [
        (1, 6, 'Score $7F1D: %s' % ''.join(str(v) for v in score), 'attr $47 white, DrawScore $7A0C'),
        (9, 14, 'Detonators $8B3D: %d' % cnt[2], 'attr $42 red, DrawDetonators $79DF'),
        (17, 22, 'Ammunition $8B3C: %d' % cnt[1], 'attr $43 magenta, DrawAmmo $79D1'),
        (25, 30, 'Lives $8B3B: %d' % cnt[0], 'attr $44 green, DrawLives $79C3'),
    ]
    for c0, c1, t1, t2 in fields:
        xa, xb = x0 + 32 * c0, x0 + 32 * (c1 + 1)
        d.line((xa, y0 + 46, xb - 2, y0 + 46), fill=(250, 220, 120), width=2)
        d.text((xa, y0 + 52), 'columns %d-%d' % (c0, c1), fill=K.DIM, font=fs)
        d.text((xa, y0 + 70), t1, fill=K.TEXT, font=fs)
        d.text((xa, y0 + 88), t2, fill=K.DIM, font=fs)
    d.text((14, y0 + 120), 'Screen row 0 (bitmap $4000-$47FF, line n of a cell at $4000 + 256 n + column; attributes '
           '$5800-$581F), drawn 4 times.\nDrawHud $796F clears it with PUSH, colours it in four bright bands, '
           'then draws all four fields.\nEach field is redrawn alone when its value changes: 6 icons or blanks, '
           'or 6 digits.', fill=K.TEXT, font=f)
    img.save(a.out)
    print(a.out, img.size)


def fig_letters(a):
    mem = session_mem(a.work)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    glyph_bytes = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()[0:320]
    pictures = []
    for fr in range(a.start, a.end + 1, a.step):
        scr = mem(fr, 0x4000, 6912)
        recs = mem(fr, 0x7B8F, 8 * 24)
        img = Image.new('RGB', (W, 440), K.BACKGROUND)
        img.paste(zxscreen.render(scr, 2).convert('RGB'), (4, 30))
        d = ImageDraw.Draw(img)
        d.text((8, 6), a.title, fill=K.TEXT, font=fb)
        px = 530
        d.text((px, 30), 'frame %d: the letter records at $7B8F' % fr, fill=K.TEXT, font=fb)
        d.text((px, 54), 'glyph col  y.frac  speed  delay stop', fill=K.DIM, font=fs)
        y = 72
        for i in range(24):
            r = recs[8 * i:8 * i + 8]
            if r[0] == 0xFF or y > 420:
                break
            gl = r[0]
            sp = r[4] | r[5] << 8
            sp = sp - 0x10000 if sp & 0x8000 else sp
            moving = r[6] == 0 and sp != 0
            col = (250, 220, 120) if moving else (K.DIM if r[6] else K.TEXT)
            if gl < 40:
                img.paste(glyph_image(glyph_bytes[8 * gl:8 * gl + 8], 2, ink=col, paper=K.BACKGROUND), (px, y))
            d.text((px + 22, y), '%3d %4d.%02X %+6.2f %4d %4d' % (r[1], r[2], r[3], sp / 256.0, r[6], r[7]),
                   fill=col, font=fs)
            y += 17
        d.text((px, 420), 'yellow: falling, grey: waiting its delay, white: stopped', fill=K.DIM, font=fs)
        pictures.append(img)
    K.save_gif(a.out, pictures, [a.step * 20] * (len(pictures) - 1) + [2000])
    print(a.out, len(pictures), 'pictures')


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('font')
    p.add_argument('out')
    p.set_defaults(fn=fig_font)
    p = sub.add_parser('hud')
    p.add_argument('--work', required=True)
    p.add_argument('--at', type=int, required=True)
    p.add_argument('--title', default='')
    p.add_argument('out')
    p.set_defaults(fn=fig_hud)
    p = sub.add_parser('letters')
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='start', type=int, required=True)
    p.add_argument('--to', dest='end', type=int, required=True)
    p.add_argument('--step', type=int, default=3)
    p.add_argument('--title', default='The falling letters')
    p.add_argument('out')
    p.set_defaults(fn=fig_letters)
    a = ap.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    a.fn(a)


if __name__ == '__main__':
    main()
