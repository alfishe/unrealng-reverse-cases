#!/usr/bin/env python3
"""The figure of doc 05 (the keys): the Spectrum keyboard with what each key does in the menu, its half-row port
and its bit, read from KeyTable $6B53 and ReadKeyboard $6864 of the image.

    python3 tools/fig_keys.py

Writes docs/img/controls/keyboard.png.
"""
import figzyx as Z

KEY_TABLE = 0x6B53

ROWS = [  # (port, keys left to right, bit of each key)
    [(0xF7FE, '12345', [0, 1, 2, 3, 4]), (0xEFFE, '67890', [4, 3, 2, 1, 0])],
    [(0xFBFE, 'QWERT', [0, 1, 2, 3, 4]), (0xDFFE, 'YUIOP', [4, 3, 2, 1, 0])],
    [(0xFDFE, 'ASDFG', [0, 1, 2, 3, 4]), (0xBFFE, 'HJKL\n', [4, 3, 2, 1, 0])],
    [(0xFEFE, '^ZXCV', [0, 1, 2, 3, 4]), (0x7FFE, 'BNM~ ', [4, 3, 2, 1, 0])],
]
NAMES = {'\n': 'ENTER', '^': 'CS', '~': 'SS', ' ': 'SPACE'}

ROLE = {
    'letter': ((70, 150, 210), 'a letter A-X: run the file with that letter at once (RunLetter)'),
    'column': ((90, 200, 120), '1 2 6 7: the other column (ColumnKey)'),
    'down': ((240, 200, 70), '3 8: the cursor down (DownKey)'),
    'up': ((250, 150, 60), '4 9: the cursor up (UpKey)'),
    'fire': ((230, 90, 80), '5 0 ENTER: run the file under the cursor (FireKey)'),
    'page': ((200, 110, 230), 'CS: the first page; SS: the next page'),
    'disk': ((70, 210, 220), 'SPACE: read the catalogue again (a new disk)'),
    'none': ((60, 60, 72), 'Y, Z: nothing (KeyTable stops at X)'),
}
DIGIT = {'1': 'column', '2': 'column', '3': 'down', '4': 'up', '5': 'fire', '6': 'column', '7': 'column',
         '8': 'down', '9': 'up', '0': 'fire', '\n': 'fire', '^': 'page', '~': 'page', ' ': 'disk'}


def main():
    img = Z.image()
    table = {}
    for i in range(24):
        b = img[KEY_TABLE + i]
        table[chr(0x41 + i)] = (b >> 5, b & 0x1F)
    out, d = Z.canvas(580)
    Z.title(d, 'The menu\'s keys: what each key does, its half-row and its bit (ReadKeyboard $6864, every 8th '
               'frame)', 'a key: its name, the port it is read on (IN A,($FE) with this high byte) and its bit; '
                         'letters from KeyTable $6B53')
    kw, kh, gap = 86, 70, 8
    f, fs = Z.font(16), Z.font(11)
    y = 70
    for r, halves in enumerate(ROWS):
        x = 14 + r * 22
        for port, keys, bits in halves:
            for k, bit in zip(keys, bits):
                role = DIGIT.get(k) or ('letter' if k in table else 'none')
                colour = ROLE[role][0]
                d.rounded_rectangle([x, y, x + kw, y + kh], radius=6, fill=colour)
                name = NAMES.get(k, k)
                d.text((x + 8, y + 6), name, fill=(0, 0, 0), font=f)
                d.text((x + 8, y + 32), f'${port >> 8:02X} bit {bit}', fill=(0, 0, 0), font=fs)
                if k in table:
                    row, mask = table[k]
                    d.text((x + 8, y + 48), f'table ${row << 5 | mask:02X}', fill=(0, 0, 0), font=fs)
                x += kw + gap
            x += 12
        y += kh + gap
    y += 14
    for i, (key, (colour, text)) in enumerate(ROLE.items()):
        xx = 14 + (i % 2) * 520
        yy = y + (i // 2) * 24
        d.rectangle([xx, yy + 2, xx + 16, yy + 16], fill=colour)
        d.text((xx + 24, yy), text, fill=Z.TEXT, font=Z.font(13))
    y += 4 * 24 + 8
    d.text((14, y), '"table $xx": the KeyTable byte, the half-row in bits 7-5 (the bit cleared in the port\'s high '
                    'byte), the key\'s mask in bits 4-0.', fill=Z.DIM, font=Z.font(12))
    d.text((14, y + 18), 'The digit rows are the two Sinclair joysticks (1-5 and 6-0: left, right, down, up, fire). '
                         'The Kempston read after them', fill=Z.DIM, font=Z.font(12))
    d.text((14, y + 36), 'is LD A,$00 in the original, so no joystick port is read.', fill=Z.DIM, font=Z.font(12))
    Z.save(out, 'docs/img/controls/keyboard.png')


if __name__ == '__main__':
    main()
