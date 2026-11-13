#!/usr/bin/env python3
"""Doc 05's figures: a key reader byte by byte with the five readers under each set-up, and the SELECT JOYSTICK
recording as a contact sheet.

    python3 tools/fig_keys.py reader docs/img/keys/readers.png
    python3 tools/fig_keys.py joystick docs/img/keys/joystick.png

reader: KeyUp's 15 bytes from build/resident.lst, then a table of the five readers' port and bit in each set-up:
the tape's defaults, the menu recording's DEFINE KEYS, and the three joystick choices of the joystick recording
(work/stage2/rec/joystick/record.json moments, which keep UP to RIGHT; FIRE from the Patch* code).
joystick: the joystick recording's saved screens (work/stage2/rec/joystick/screens).
"""
import sys

from figmyth import F, TEXT, DIM, HI, PANEL, W, canvas, save, listing, rec_screen, sheet

ROWS = {0xFEFE: ['CAPS', 'Z', 'X', 'C', 'V'], 0xFDFE: ['A', 'S', 'D', 'F', 'G'], 0xFBFE: ['Q', 'W', 'E', 'R', 'T'],
        0xF7FE: ['1', '2', '3', '4', '5'], 0xEFFE: ['0', '9', '8', '7', '6'], 0xDFFE: ['P', 'O', 'I', 'U', 'Y'],
        0xBFFE: ['ENTER', 'L', 'K', 'J', 'H'], 0x7FFE: ['SPACE', 'SYM', 'M', 'N', 'B']}
NAMES = ['UP', 'DOWN', 'LEFT', 'RIGHT', 'FIRE']
# (port, bit) per reader, UP DOWN LEFT RIGHT FIRE
SETUPS = [
    ('the tape', [(0xDFFE, 2), (0xBFFE, 3), (0xFBFE, 0), (0xFBFE, 1), (0xDFFE, 1)], 0),
    ('DEFINE KEYS (menu rec.)', [(0xFEFE, 2), (0xBFFE, 2), (0xBFFE, 1), (0xDFFE, 0), (0x7FFE, 0)], 0),
    ('CURSOR KEYS', [(0xEFFE, 3), (0xEFFE, 4), (0xF7FE, 4), (0xEFFE, 2), (0xEFFE, 0)], 0),
    ('SINCLAIR', [(0xEFFE, 1), (0xEFFE, 2), (0xEFFE, 4), (0xEFFE, 3), (0xEFFE, 0)], 0),
    ('KEMPSTON', [(0x001F, 3), (0x001F, 2), (0x001F, 1), (0x001F, 0), (0x001F, 4)], 0xFF),
]


def key_name(port, bit):
    if port == 0x001F:
        return 'bit %d' % bit
    return ROWS[port][bit]


def reader(out):
    rows = [r for r in listing('resident') if 0xFC90 <= r[0] < 0xFC9F and r[1]]
    im, d, y = canvas(700, 'A key reader, byte by byte, and the five readers in each set-up',
                      'KeyUp at $FC90 (build/resident.lst). DEFINE KEYS and SELECT JOYSTICK write the port at +4 and '
                      'the BIT opcode at +13;\nSELECT JOYSTICK also writes KeyXorMask $FCFA ($FF for the Kempston, '
                      'whose bits are set when pressed).')
    y += 10
    x = 20
    bw = 62
    offs = 0
    for addr, bts, text in rows:
        n = len(bts)
        for i, b in enumerate(bts):
            o = offs + i
            hot = o in (4, 5, 13)
            bx = x + o * (bw + 4)
            d.rectangle((bx, y, bx + bw, y + 40), fill=(150, 110, 40) if hot else PANEL,
                        outline=HI if hot else (70, 70, 84))
            d.text((bx + 18, y + 4), b, font=F(16), fill=TEXT)
            d.text((bx + 20, y + 24), '+%d' % o, font=F(13), fill=DIM)
        bx0 = x + offs * (bw + 4)
        bx1 = x + (offs + n) * (bw + 4) - 4
        d.line((bx0, y + 48, bx1, y + 48), fill=DIM)
        label = text.split(';')[0].strip()
        lw = d.textlength(label, font=F(13))
        lx = (bx0 + bx1) / 2 - lw / 2
        d.text((max(lx, 4), y + 54 + (18 if offs in (6, 11) else 0)), label, font=F(13), fill=TEXT)
        offs += n
    y += 110
    d.text((x, y), '+4/+5: the port (LD BC,nn).  +13: BIT n,A = $47 + 8 x n.  Z after BIT: the control is on.',
           font=F(14), fill=HI)
    y += 40
    cw = [230, 152, 152, 152, 152, 152]
    cx = [x]
    for w in cw[:-1]:
        cx.append(cx[-1] + w)
    head = ['set-up'] + NAMES
    for i, h in enumerate(head):
        d.text((cx[i] + 6, y), h, font=F(14), fill=DIM)
    y += 26
    for name, rd, mask in SETUPS:
        d.rectangle((x, y - 2, x + sum(cw) - 10, y + 44), fill=PANEL)
        d.text((cx[0] + 6, y + 4), name, font=F(14), fill=TEXT)
        d.text((cx[0] + 6, y + 24), 'KeyXorMask $%02X' % mask, font=F(13), fill=DIM)
        for i, (port, bit) in enumerate(rd):
            d.text((cx[i + 1] + 6, y + 4), key_name(port, bit), font=F(16), fill=HI)
            d.text((cx[i + 1] + 6, y + 24), '$%04X bit %d' % (port, bit), font=F(13), fill=DIM)
        y += 52
    im = im.crop((0, 0, W, y + 10))
    save(im, out)


def joystick(out):
    items = [
        (rec_screen('joystick', 218), 'frame 218: SELECT JOYSTICK, the highlight\non CURSOR KEYS'),
        (rec_screen('joystick', 1016), 'frame 1016: SPACE on SINCLAIR,\nthe lines being wiped'),
        (rec_screen('joystick', 1876), 'frame 1876: after LEAVE THIS MENU,\nthe menu again'),
        (rec_screen('joystick', 2248), 'frame 2248: SPACE on KEMPSTON,\nthe lines being wiped'),
        (rec_screen('joystick', 9380), 'frame 9380: stage 1, Kempston right'),
        (rec_screen('joystick', 9416), 'frame 9416: stage 1, Kempston fire'),
    ]
    sheet(items, out, 'The joystick recording: SELECT JOYSTICK four times, then stage 1 on a Kempston',
          'work/stage2/rec/joystick: c1\'s menu state on a 48K with a Kempston card; the screens the recording '
          'tool saved.')


if __name__ == '__main__':
    {'reader': reader, 'joystick': joystick}[sys.argv[1]](sys.argv[2])
