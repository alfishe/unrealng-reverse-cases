#!/usr/bin/env python3
"""The media resources of Zynaps GS (src/res/music, sfx, screen) as editable files, built back into the bytes
the disk holds.

    python3 tools/disk_media.py build --out build/res      every resource to the files the disk builder reads
    python3 tools/disk_media.py install                     (once) the resources from the original media in work/media
    python3 tools/disk_media.py check                       build into a scratch folder and compare with work/media

| Resource (src/res/)            | Built (OUT/)                         | Format |
| ------------------------------ | ------------------------------------ | ------ |
| music/levelNN.mod              | music/levelNN.bin                    | the ProTracker module as the loader streams it (13: the title) |
| sfx/fx-start.wav, fxNN.wav     | sfx/fx-start.bin, fxNN.bin           | WAV, 8-bit unsigned mono PCM: its data chunk is the effect |
| screen/loading.png             | screen/loading.scr                   | 256 x 192 indexed PNG + its text chunk zx-hidden (6912 bytes back) |

The module and the effects become the disk's data in tools/mkdisk.py (the boot banks, the FX sets, the module
parts). The WAV and the screen PNG code is copied from ../nether-earth-gs/tools/res_media.py (itself from
advanced-nether-earth/tools/intro_screen.py), unchanged.
"""
import json
import os
import shutil
import struct
import sys
import tempfile
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
WORK = os.path.join(ROOT, 'work', 'media')
RATE = 11025  # nominal: the GS plays an effect at the pitch of its note, not at a stored rate
EFFECTS = ['fx-start'] + ['fx%02d' % n for n in range(1, 22)]
LEVELS = range(1, 14)


# --- WAV ---

def wav_write(path, data, rate=RATE):
    head = struct.pack('<4sI4s4sIHHIIHH4sI', b'RIFF', 36 + len(data) + (len(data) & 1), b'WAVE', b'fmt ', 16, 1, 1,
                       rate, rate, 1, 8, b'data', len(data))
    open(path, 'wb').write(head + data + (b'\0' if len(data) & 1 else b''))


def wav_read(path):
    """the data chunk of an 8-bit mono PCM WAV"""
    d = open(path, 'rb').read()
    assert d[:4] == b'RIFF' and d[8:12] == b'WAVE', path
    p, fmt = 12, None
    while p < len(d):
        kind, n = struct.unpack('<4sI', d[p:p + 8])
        body = d[p + 8:p + 8 + n]
        if kind == b'fmt ':
            fmt = struct.unpack('<HHIIHH', body[:16])
        elif kind == b'data':
            if fmt is None or fmt[0] != 1 or fmt[1] != 1 or fmt[5] != 8:
                sys.exit(f'{path}: not 8-bit mono PCM')
            return body
        p += 8 + n + (n & 1)
    sys.exit(f'{path}: no data chunk')


# --- the screen PNG (from advanced-nether-earth/tools/intro_screen.py) ---

PALETTE = [(0, 0, 0), (0, 0, 0xC0), (0xC0, 0, 0), (0xC0, 0, 0xC0), (0, 0xC0, 0), (0, 0xC0, 0xC0), (0xC0, 0xC0, 0),
           (0xC0, 0xC0, 0xC0)]
BRIGHT = [(0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF), (0xFF, 0xFF, 0),
          (0xFF, 0xFF, 0xFF)]


def pixel_address(x, y):
    return ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2) | x


def png_write(path, width, height, rows, palette, text):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xFFFFFFFF)
    raw = b''.join(b'\0' + bytes(r) for r in rows)
    out = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 3, 0, 0, 0))
    out += chunk(b'PLTE', b''.join(bytes(c) for c in palette))
    for key, value in text.items():
        out += chunk(b'tEXt', key.encode() + b'\0' + value.encode())
    out += chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
    open(path, 'wb').write(out)


def png_read(path):
    data = open(path, 'rb').read()
    pos, idat, text, head = 8, b'', {}, None
    while pos < len(data):
        n, kind = struct.unpack('>I4s', data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if kind == b'IHDR':
            head = struct.unpack('>IIBBBBB', body)
        elif kind == b'IDAT':
            idat += body
        elif kind == b'tEXt':
            key, _, value = body.partition(b'\0')
            text[key.decode()] = value.decode()
        pos += 12 + n
    width, height, depth, kind, _, _, interlace = head
    if depth != 8 or kind != 3 or interlace:
        from PIL import Image
        image = Image.open(path)
        if image.mode != 'P':
            sys.exit(f'{path}: not an indexed PNG')
        pixels = list(image.getdata())
        return width, height, [pixels[y * width:(y + 1) * width] for y in range(height)], text
    raw = zlib.decompress(idat)
    rows, prev, stride = [], bytes(width), width + 1
    for y in range(height):
        f, line = raw[y * stride], bytearray(raw[y * stride + 1:(y + 1) * stride])
        for i in range(width):
            a = line[i - 1] if i else 0
            b, c = prev[i], prev[i - 1] if i else 0
            if f == 1:
                line[i] = (line[i] + a) & 255
            elif f == 2:
                line[i] = (line[i] + b) & 255
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(list(line))
        prev = bytes(line)
    return width, height, rows, text


def screen_to_png(scr, path):
    """index = bright x 16 + (pixel set) x 8 + colour; what a cell does not show (the ink of a cell with no set
    pixel, the paper of one with no clear pixel, flash) goes in the text chunk zx-hidden, two characters a cell"""
    rows = [[0] * 256 for _ in range(192)]
    hidden = []
    for cell in range(768):
        cx, cy = cell % 32, cell // 32
        attr = scr[6144 + cell]
        ink, paper, bright = attr & 7, (attr >> 3) & 7, (attr >> 6) & 1
        ones = zeros = 0
        for line in range(8):
            y = cy * 8 + line
            byte = scr[pixel_address(cx, y)]
            for bit in range(8):
                on = byte >> (7 - bit) & 1
                ones += on
                zeros += 1 - on
                rows[y][cx * 8 + bit] = bright * 16 + on * 8 + (ink if on else paper)
        h = '-'
        if not ones:
            h = str(ink)
        elif not zeros:
            h = str(paper)
        hidden.append(h + ('F' if attr & 0x80 else '-'))
    palette = [c for bright in (PALETTE, BRIGHT) for c in bright + bright]
    png_write(path, 256, 192, rows, palette, {'zx-hidden': ''.join(hidden)})


def png_to_screen(path):
    width, height, rows, text = png_read(path)
    if (width, height) != (256, 192):
        sys.exit(f'{path}: {width} x {height}, not 256 x 192')
    hidden = text.get('zx-hidden', '--' * 768)
    scr = bytearray(6912)
    for cell in range(768):
        cx, cy = cell % 32, cell // 32
        ink = paper = bright = None
        for line in range(8):
            y = cy * 8 + line
            byte = 0
            for bit in range(8):
                v = rows[y][cx * 8 + bit]
                on = v >> 3 & 1
                byte = byte << 1 | on
                if on:
                    ink = v & 7
                else:
                    paper = v & 7
                bright = v >> 4 & 1
            scr[pixel_address(cx, y)] = byte
        h, f = hidden[cell * 2], hidden[cell * 2 + 1]
        if ink is None:
            ink = int(h)
        if paper is None:
            paper = int(h)
        scr[6144 + cell] = (0x80 if f == 'F' else 0) | bright << 6 | paper << 3 | ink
    return bytes(scr)



def build(out):
    for sub in ('music', 'sfx', 'screen'):
        os.makedirs(os.path.join(out, sub), exist_ok=True)
    for n in LEVELS:
        shutil.copyfile(os.path.join(RES, 'music', 'level%02d.mod' % n), os.path.join(out, 'music', 'level%02d.bin' % n))
    for name in EFFECTS:
        open(os.path.join(out, 'sfx', name + '.bin'), 'wb').write(wav_read(os.path.join(RES, 'sfx', name + '.wav')))
    open(os.path.join(out, 'screen', 'loading.scr'), 'wb').write(png_to_screen(os.path.join(RES, 'screen', 'loading.png')))


def originals():
    """the original bytes of every built file, from work/media (stage 1's cuts of the disk)"""
    files = {}
    for n in LEVELS:
        files['music/level%02d.bin' % n] = open(os.path.join(WORK, 'gs', 'mod', 'level%02d.mod' % n), 'rb').read()
    for name in EFFECTS:
        files['sfx/%s.bin' % name] = open(os.path.join(WORK, 'gs', 'fx', name + '.raw'), 'rb').read()
    blk00 = open(os.path.join(WORK, 'unpacked', 'blk00-s0003-7F58.bin'), 'rb').read()
    files['screen/loading.scr'] = blk00[0x8000 - 0x7F58:]
    return files


def install():
    files = originals()
    for sub in ('music', 'sfx', 'screen'):
        os.makedirs(os.path.join(RES, sub), exist_ok=True)
    for n in LEVELS:
        open(os.path.join(RES, 'music', 'level%02d.mod' % n), 'wb').write(files['music/level%02d.bin' % n])
    for name in EFFECTS:
        wav_write(os.path.join(RES, 'sfx', name + '.wav'), files['sfx/%s.bin' % name])
    screen_to_png(files['screen/loading.scr'], os.path.join(RES, 'screen', 'loading.png'))
    print('installed %d modules, %d effects, the loading screen' % (len(LEVELS), len(EFFECTS)))


def check():
    files = originals()
    with tempfile.TemporaryDirectory() as tmp:
        build(tmp)
        bad = [k for k, v in files.items() if open(os.path.join(tmp, k), 'rb').read() != v]
    for k in bad:
        print('disk_media: %s DIFFERS' % k)
    print('disk_media: %d files, %d differ' % (len(files), len(bad)))
    return 1 if bad else 0


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'build':
        out = sys.argv[sys.argv.index('--out') + 1] if '--out' in sys.argv else os.path.join(ROOT, 'build', 'res')
        build(out)
    elif cmd == 'install':
        install()
    elif cmd == 'check':
        sys.exit(check())
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
