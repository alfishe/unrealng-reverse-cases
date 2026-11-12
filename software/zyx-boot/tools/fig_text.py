#!/usr/bin/env python3
"""The figures of doc 08 (the font and the text): the font sheet, one catalogue line byte by byte, the help texts.

    python3 tools/fig_text.py --c1 work/docs/zbA/c1 --c2 work/docs/zbA/c2

--c1 / --c2 are instances holding c1 and c2 (re_session.py open); the moments are kept in work/docs/figcache/. Writes
docs/img/text/font.png, entryline.png and texts.png.
"""
import argparse

from PIL import Image

import figzyx as Z

FONT, ENTRY_LINE, MENU_HELP, NO_FILES = 0xA600, 0xB3CE, 0x6AFD, 0x6B41
ROM_FONT = 0x3D00
CONTROL = {0x16: ('AT', 2), 0x13: ('BRIGHT', 1), 0x10: ('INK', 1), 0x11: ('PAPER', 1), 0xFF: ('end', 0)}


def fig_font(img64):
    scale = 3
    cw = 8 * scale + 34
    out, d = Z.canvas(70 + 6 * (8 * scale + 30) + 40)
    Z.title(d, 'The menu font: Font $A600, 96 characters of 8 x 8 (space to the copyright sign), CHARS = $A500',
            'each cell: the character, its code and its address; the ROM prints it through RST $10 '
            '(PrintString $6720)')
    f = Z.font(11)
    for i in range(96):
        code = 0x20 + i
        data = img64[FONT + 8 * i:FONT + 8 * i + 8]
        x = 14 + (i % 16) * (cw + 6)
        y = 66 + (i // 16) * (8 * scale + 30)
        out.paste(Z.sprite(data, 8, 8, ink=(110, 230, 250), scale=scale), (x, y))
        label = chr(code) if code < 0x7F else '(c)'
        d.text((x + 8 * scale + 4, y), label, fill=Z.TEXT, font=Z.font(13))
        d.text((x, y + 8 * scale + 2), f'{code:02X} {FONT + 8 * i:04X}', fill=Z.DIM, font=f)
    d.text((14, out.height - 30), 'drawn by tools/fig_text.py from the image (src/res/graphics/font.png holds the '
                                  'same bytes as an editable sheet)', fill=Z.DIM, font=Z.font(12))
    Z.save(out, 'docs/img/text/font.png')


def decode(data):
    """A string of RST $10 bytes as (bytes, meaning) items"""
    items, i = [], 0
    while i < len(data):
        b = data[i]
        if b in CONTROL:
            name, n = CONTROL[b]
            args = list(data[i + 1:i + 1 + n])
            items.append((data[i:i + 1 + n], f'{name} ' + ','.join(str(a) for a in args) if n else name))
            i += 1 + n
            if b == 0xFF:
                break
        else:
            j = i
            while j < len(data) and data[j] not in CONTROL:
                j += 1
            items.append((data[i:j], '"' + data[i:j].decode('latin-1') + '"'))
            i = j
    return items


def fig_entryline(mems):
    out, d = Z.canvas(380)
    Z.title(d, 'EntryLine $B3CE: one catalogue line as PrintColumn builds it, byte by byte (c2)',
            'the bytes as the recording holds them after the last line of a page; the ROM reads the control codes '
            'AT, BRIGHT, INK')
    f, fb = Z.font(12), Z.font(14)
    y = 70
    for label, mem, shot in mems:
        data = mem[ENTRY_LINE:ENTRY_LINE + 22]
        d.text((14, y), label, fill=Z.TEXT, font=Z.font(13))
        y += 22
        x = 14
        palette = [(70, 150, 210), (200, 110, 230), (90, 200, 120), (240, 200, 70), (250, 150, 60),
                   (70, 210, 220), (230, 90, 80)]
        for k, (chunk, meaning) in enumerate(decode(data)):
            w = max(len(chunk) * 30, len(meaning) * 8 + 8)
            colour = palette[k % len(palette)]
            d.rectangle([x, y, x + w - 4, y + 24], fill=tuple(c // 3 for c in colour), outline=colour)
            d.text((x + 4, y + 4), ' '.join(f'{b:02X}' for b in chunk), fill=Z.TEXT, font=f)
            d.text((x + 4, y + 30), meaning, fill=colour, font=f)
            x += w
        y += 56
        out.paste(shot, (14, y))
        y += shot.height + 20
    d.text((14, y), 'AT row,col and the letter are written for each line (EntryLine+1, +7); INK 4 (green) marks a '
                    'BASIC file, INK 6 (yellow) a 192-sector CODE file;', fill=Z.DIM, font=f)
    d.text((14, y + 18), 'a name byte below 32 or from 128 up is printed as ".". The row in the bytes is one past the '
                         'printed line: PrintColumn adds 1 after each print.', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/text/entryline.png')


def strip(mem, row, col, cells, scale=3):
    """A strip of the screen: cells character cells from (row, col)"""
    scr = Z.screen(mem)
    return scr.crop((col * 8, row * 8, (col + cells) * 8, row * 8 + 8)).resize((cells * 8 * scale, 8 * scale),
                                                                              Image.NEAREST)


def fig_texts(img64, mem_help, mem_nofiles):
    out, d = Z.canvas(420)
    Z.title(d, 'The menu\'s two fixed texts: MenuHelp $6AFD and NoFilesText $6B41, decoded',
            'the bytes with the ROM\'s control codes, and the screen they print (c1 frame 850 and c1 frame 1000)')
    f = Z.font(12)
    y = 70
    for name, addr, length, mem, rows in (('MenuHelp $6AFD (68 bytes)', MENU_HELP, 68, mem_help, [(19, 7, 18),
                                                                                                    (20, 7, 18),
                                                                                                    (21, 7, 18)]),
                                          ('NoFilesText $6B41 (18 bytes)', NO_FILES, 18, mem_nofiles,
                                           [(11, 9, 14)])):
        d.text((14, y), name, fill=Z.TEXT, font=Z.font(13))
        y += 20
        line = []
        for chunk, meaning in decode(img64[addr:addr + length]):
            line.append(meaning)
        text = '  '.join(line)
        while text:
            d.text((14, y), text[:120], fill=(240, 200, 70), font=f)
            text = text[120:]
            y += 16
        y += 6
        for r, c, n in rows:
            out.paste(strip(mem, r, c, n), (14, y))
            d.text((14 + n * 24 + 10, y + 4), f'row {r}, columns {c}-{c + n - 1}', fill=Z.DIM, font=f)
            y += 28
        y += 16
    d.text((14, y), 'MenuHelp sets BRIGHT 1 and INK 5 once: the three lines share them. Both texts end with $FF, '
                    'which PrintString stops at; the ROM never sees it.', fill=Z.DIM, font=f)
    Z.save(out, 'docs/img/text/texts.png')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--c1', required=True)
    p.add_argument('--c2', required=True)
    args = p.parse_args()
    img64 = Z.image()
    fig_font(img64)
    m1500, m2000 = Z.moment(args.c2, '1500'), Z.moment(args.c2, '2000')
    fig_entryline([('c2 frame 1500, page 1: the last line printed, "X>  T24" (a BASIC file)', m1500,
                    strip(m1500, 17, 18, 12)),
                   ('c2 frame 2000, page 2: the last line printed, "G>  magic" (the 192-sector CODE file)', m2000,
                    strip(m2000, 12, 10, 12))])
    fig_texts(img64, Z.moment(args.c1, '850'), Z.moment(args.c1, '1000'))


if __name__ == '__main__':
    main()
