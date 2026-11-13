#!/usr/bin/env python3
"""Doc 08's figures: the fonts with their width masks, and one line printed by hand.

    python3 tools/fig_text.py fonts docs/img/hud/fonts.png
    python3 tools/fig_text.py hud WORK FRAME docs/img/hud/hud-fields.png

fonts: the glyphs as build/res holds them (res/resident/print-font.bin, the resident's PrintFont `$F880`;
res/front/font-small.bin, the front's FontSmall `$9ED2`; the front's FontLarge `$9FFA` is the first 27 glyphs of
PrintFont, byte for byte, so it is not drawn twice; stage 5's TextFont `$8F96` is the same 27 glyphs and a full stop). Each glyph is 8 bytes: a width mask, then 7 pixel rows. Over
each glyph its mask (gold: a set bit); under it the advance, 9 less the mask's trailing zero bits (Advance `$F465`,
AdvanceColumn `$9E24`). Under the fonts: GAME OVER laid out as TextToBuffer `$F3CB` lays it out (column byte 12,
bit 0), each glyph's pen position in bytes and bits.
hud: WORK is a re_session work folder whose instance holds the recording (rzx-r1); at FRAME the screen's top 48
lines and their colours are read with TTD memory_at and drawn at 4 x, each field the stage-1 code writes outlined
and named with its routine and its screen place (from src/stage1/hud.asm, hero.asm and entry.asm).
"""
import os
import sys

from figmyth import F, TEXT, DIM, HI, PANEL, COLOURS, CASE, canvas, save, kitlib

NAMES = [chr(ord('A') + i) for i in range(26)] + ['space'] + [str(i) for i in range(10)]


def font(part):
    return open(os.path.join(CASE, 'build', 'res', part), 'rb').read()


def advance(mask):
    c = 9
    while not mask & 1:
        mask >>= 1
        c -= 1
    return c


def draw_font(im, d, y, data, title, sub, names=NAMES):
    d.text((16, y), title, font=F(15), fill=TEXT)
    d.text((16, y + 20), sub, font=F(13), fill=DIM)
    y += 46
    sc, cw, ch = 4, 78, 92
    for g in range(len(data) // 8):
        x0 = 16 + (g % 13) * cw
        y0 = y + (g // 13) * ch
        mask = data[8 * g]
        d.text((x0, y0), names[g], font=F(13), fill=TEXT)
        d.text((x0 + 44, y0), '%02X' % mask, font=F(13), fill=DIM)
        for b in range(8):
            on = mask & (0x80 >> b)
            d.rectangle((x0 + b * sc, y0 + 20, x0 + b * sc + sc - 2, y0 + 24), fill=HI if on else PANEL)
        d.rectangle((x0 - 1, y0 + 27, x0 + 8 * sc, y0 + 28 + 7 * sc), fill=PANEL)
        for r in range(7):
            row = data[8 * g + 1 + r]
            for b in range(8):
                if row & (0x80 >> b):
                    d.rectangle((x0 + b * sc, y0 + 28 + r * sc, x0 + b * sc + sc - 1, y0 + 28 + r * sc + sc - 1),
                                fill=TEXT)
        d.text((x0, y0 + 60), '+%d' % advance(mask), font=F(13), fill=HI)
    rows = (len(data) // 8 + 12) // 13
    return y + rows * ch + 6


def layout(text, data, col, bit):
    """the glyphs of TextToBuffer: (character, glyph, pen x in pixels, advance)"""
    out = []
    pen = 8 * col + bit
    for ch in text:
        if ch == ' ':
            g = 26
        elif ch.isdigit():
            g = 27 + int(ch)
        else:
            g = ord(ch) - ord('A')
        a = advance(data[8 * g])
        out.append((ch, g, pen, a))
        pen += a
    return out


def draw_layout(im, d, y, data):
    text, col, bit = 'GAME OVER', 12, 0
    d.text((16, y), 'The worked example: GAME OVER (resident Print, column byte 12, bit 0), as TextToBuffer lays it out;\n'
           'the numbers over the strip are the column bytes of TextBuffer, the ticks under it each glyph\'s pen',
           font=F(15), fill=TEXT)
    y += 44
    glyphs = layout(text, data, col, bit)
    sc = 6
    first = 8 * col
    last = glyphs[-1][2] + 8
    x0 = 16
    # byte boundaries
    for byte in range(col, (last + 7) // 8 + 1):
        bx = x0 + (8 * byte - first) * sc
        d.line((bx, y, bx, y + 18 + 7 * sc + 6), fill=DIM)
        if 8 * byte < last:
            d.text((bx + 3, y), '%d' % byte, font=F(13), fill=DIM)
    y += 20
    d.rectangle((x0, y, x0 + (last - first) * sc, y + 7 * sc), fill=PANEL)
    for i, (ch, g, pen, a) in enumerate(glyphs):
        c = COLOURS[i % len(COLOURS)]
        for r in range(7):
            row = data[8 * g + 1 + r]
            for b in range(8):
                if row & (0x80 >> b):
                    px = x0 + (pen + b - first) * sc
                    d.rectangle((px, y + r * sc, px + sc - 1, y + r * sc + sc - 1), fill=c)
    y += 7 * sc + 10
    for i, (ch, g, pen, a) in enumerate(glyphs):
        c = COLOURS[i % len(COLOURS)]
        px = x0 + (pen - first) * sc
        d.line((px, y - 8, px, y), fill=c, width=2)
        d.text((px + 2, y + 2 + 18 * (i % 2)), ch if ch != ' ' else 'sp', font=F(13), fill=c)
    y += 44
    cells = ['%s: byte %d bit %d, +%d' % (ch if ch != ' ' else 'space', pen // 8, pen % 8, a)
             for ch, g, pen, a in glyphs]
    for k in range(0, len(cells), 3):
        d.text((16, y), '    '.join(cells[k:k + 3]), font=F(13), fill=TEXT)
        y += 18
    end = glyphs[-1][2] + glyphs[-1][3]
    d.text((16, y + 4), 'The pen ends at byte %d bit %d: %d pixels from the start (doc 08, worked example 1).' % (
        end // 8, end % 8, end - first), font=F(13), fill=HI)
    return y + 30


def fonts(out):
    resident = font('resident/print-font.bin')
    small = font('front/font-small.bin')
    large = font('front/font-large.bin')
    assert large == resident[:len(large)]
    im, d, y = canvas(1400, 'The fonts: PrintFont (resident) and FontSmall (front), 37 glyphs each',
                      'A glyph is 8 bytes: a width mask (gold bars over the glyph), then 7 pixel rows (drawn at 4 x).\n'
                      'Under each glyph its advance: 9 less the trailing zero bits of the mask, so the glyph\'s width + 1.\n'
                      'FontLarge $9FFA in the front is PrintFont\'s first 27 glyphs (A-Z, space), byte for byte.')
    y = draw_font(im, d, y + 4, resident, 'PrintFont $F880 (resident; also FontLarge $9FFA, A-Z and space)',
                  'Print and PrintRecord: PRESS PLAY ON TAPE, the stage titles, GAME OVER; DigitGlyphs $F959 = the "0" '
                  'glyph\'s rows')
    y = draw_font(im, d, y + 4, small, 'FontSmall $9ED2 (front)',
                  'PrintText with font 0: the credits, the menu, DEFINE KEYS; one pixel narrower than PrintFont')
    stage5 = font('stage5/bitmaps-text-font-1x8.bin')
    assert stage5[:216] == resident[:216]
    y = draw_font(im, d, y + 4, stage5[216:], 'Stage 5\'s TextFont $8F96: PrintFont\'s first 27 glyphs again, then one more',
                  'the full stop, written \\ in the texts (glyph 27, where PrintFont has the 0); the intro and the ending',
                  names=['stop'])
    y = draw_layout(im, d, y + 4, resident)
    save(im.crop((0, 0, im.width, y)), out)


# (name, routine, x, y, w, h in pixels)
FIELDS = [
    ('score', 'ShowScore $7BC3: 6 digits, column 6, line 8', 48, 8, 48, 8),
    ('item count', 'ShowItemCount $7D5E: column 15, line 8', 120, 8, 16, 8),
    ('energy bar', 'DrawEnergyBar $A3C5: $4134, lines 9-14', 160, 9, 48, 6),
    ('lives', 'LivesFlashStep $7DD2: colours $5861, $5881', 8, 24, 48, 16),
    ('item strip', 'ShowItemStrip $7E3D: $406A, 12 x 16', 80, 24, 96, 16),
    ('pieces', 'ShowPieceTaken $82FA: column 24 + n, line 25', 200, 24, 40, 16),
]


def hud(work, frame, out):
    sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    import zxscreen  # noqa: E402
    session, _ = re_session.session_of(work)
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                     'offset': 0x4000, 'length': 0x1B00}, ok=False)
    body = r.structured or {}
    if r.is_error or not body.get('exact', False):
        raise SystemExit(f'memory_at {frame}: {r.text}')
    scr = bytes.fromhex(body['hex'])
    sc = 4
    pic = zxscreen.render(scr, sc).convert('RGB').crop((0, 0, 256 * sc, 48 * sc))
    im, d, y = canvas(700, 'The HUD at rzx-r1 frame %d: its fields and the routines that write them' % frame,
                      'The top 48 pixel lines (rows 0-5), drawn at 4 x. DissolveHud $8AB1 brings the frame in once '
                      'from $7000;\nafter that each field is redrawn by its own routine, the score every pass, the '
                      'rest when their value changes.')
    x0, y0 = 13, y + 4
    im.paste(pic, (x0, y0))
    for i, (name, what, fx, fy, fw, fh) in enumerate(FIELDS):
        c = COLOURS[i % len(COLOURS)]
        d.rectangle((x0 + fx * sc - 2, y0 + fy * sc - 2, x0 + (fx + fw) * sc + 1, y0 + (fy + fh) * sc + 1),
                    outline=c, width=3)
    y = y0 + pic.height + 14
    for i, (name, what, fx, fy, fw, fh) in enumerate(FIELDS):
        c = COLOURS[i % len(COLOURS)]
        cx = 16 + (i % 2) * 520
        cy = y + (i // 2) * 24
        d.rectangle((cx, cy + 3, cx + 12, cy + 15), fill=c)
        d.text((cx + 20, cy), '%s: %s' % (name, what), font=F(13), fill=TEXT)
    save(im.crop((0, 0, im.width, y + 3 * 24 + 8)), out)


if __name__ == '__main__':
    if sys.argv[1] == 'hud':
        hud(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    else:
        {'fonts': fonts}[sys.argv[1]](sys.argv[2])
