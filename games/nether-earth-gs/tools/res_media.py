#!/usr/bin/env python3
"""The loaders' resources (src/res/music, sfx, screen, text) as editable files, built back into the exact bytes.

    python3 tools/res_media.py build --out build/res      every resource to the files the media hold
    python3 tools/res_media.py install                     (once) the resources from the original files in work/media
    python3 tools/res_media.py check                       build into a scratch folder and compare with work/media

| Resource (src/res/)                 | Built (OUT/)                             | Format |
| ----------------------------------- | ---------------------------------------- | ------ |
| music/desert-dream.mod              | music/neart002.bin ... neart006.bin      | the ProTracker module; cut in 32768-byte files |
| sfx/fxNN-neartMMM.wav               | sfx/neartMMM.bin                         | WAV, 8-bit unsigned mono PCM: its data chunk is the file |
| sfx/fx14-neart019-020.wav           | sfx/neart019.bin, sfx/neart020.bin       | the same, cut at 32768 |
| screen/loading.png                  | screen/neart000.bin                      | 256 x 192 indexed PNG + its text chunk zx-hidden |
| text/disk-basic.txt, tape-basic.txt | text/disk-basic.bin, tape-basic.bin      | BASIC listings (tools/basic_tok.py) |
| text/media-trd-sector9.txt          | text/media-trd-sector9.bin               | the TRD's sector 9 text, CP437/ASCII, NUL bytes as {00} |

The screen code (png_write, png_read, screen_to_png, png_to_screen) is copied from
advanced-nether-earth/tools/intro_screen.py (that case's lossless screen PNG), unchanged but for the names.
"""
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
MEDIA = os.path.join(ROOT, 'work', 'media', 'scl', 'files')

# effect number (the card's handle in load order), WAV name, the files it is cut into
EFFECTS = [(1, ['neart007']), (2, ['neart008']), (3, ['neart009']), (4, ['neart010']), (5, ['neart011']),
           (6, ['neart012']), (7, ['neart013']), (8, ['neart014']), (9, ['neart015']), (10, ['neart016']),
           (11, ['neart017']), (12, ['neart018']), (13, ['neart023']), (14, ['neart019', 'neart020'])]
MODULE = ['neart002', 'neart003', 'neart004', 'neart005', 'neart006']
CUT = 32768
RATE = 11025  # nominal: the GS plays an effect at the pitch of its note, not at a stored rate


def wav_name(n, files):
    return 'fx%02d-%s.wav' % (n, '-'.join([files[0]] + [f[-3:] for f in files[1:]]))


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


# --- the TRD's sector 9 text: printable ASCII, other bytes as {XX} ---

def text_to_bytes(text):
    return bytes(int(m[1:3], 16) if m.startswith('{') else ord(m)
                 for m in re.findall(r'\{[0-9A-F]{2}\}|.', text.rstrip('\n'), re.S))


def bytes_to_text(data):
    return ''.join(chr(b) if 32 <= b < 127 and b not in (123, 125) else '{%02X}' % b for b in data) + '\n'


# --- the commands ---

def build(out):
    for sub in ('music', 'sfx', 'screen', 'text'):
        os.makedirs(os.path.join(out, sub), exist_ok=True)
    mod = open(os.path.join(RES, 'music', 'desert-dream.mod'), 'rb').read()
    for k, name in enumerate(MODULE):
        open(os.path.join(out, 'music', name + '.bin'), 'wb').write(mod[k * CUT:(k + 1) * CUT])
    for n, files in EFFECTS:
        data = wav_read(os.path.join(RES, 'sfx', wav_name(n, files)))
        for k, name in enumerate(files):
            open(os.path.join(out, 'sfx', name + '.bin'), 'wb').write(data[k * CUT:(k + 1) * CUT if k + 1 < len(files)
                                                                           else None])
    open(os.path.join(out, 'screen', 'neart000.bin'), 'wb').write(
        png_to_screen(os.path.join(RES, 'screen', 'loading.png')))
    for name in ('disk-basic', 'tape-basic'):
        subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'basic_tok.py'), 'tokenize',
                        os.path.join(RES, 'text', name + '.txt'), os.path.join(out, 'text', name + '.bin')],
                       check=True)
    text = open(os.path.join(RES, 'text', 'media-trd-sector9.txt'), encoding='utf-8').read()
    open(os.path.join(out, 'text', 'media-trd-sector9.bin'), 'wb').write(text_to_bytes(text))


def originals():
    """{built path: the original bytes}"""
    out = {}
    for name in MODULE + [f for _, files in EFFECTS for f in files] + ['neart000']:
        sub = 'music' if name in MODULE else 'screen' if name == 'neart000' else 'sfx'
        out[f'{sub}/{name}.bin'] = open(os.path.join(MEDIA, name + '.C'), 'rb').read()
    trd = open(os.path.join(ROOT, 'orig', 'Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2002 Tron Z].trd'),
               'rb').read()
    out['text/media-trd-sector9.bin'] = trd[0x800:0x8E1]
    return out


def install():
    os.makedirs(os.path.join(RES, 'music'), exist_ok=True)
    os.makedirs(os.path.join(RES, 'sfx'), exist_ok=True)
    os.makedirs(os.path.join(RES, 'screen'), exist_ok=True)
    os.makedirs(os.path.join(RES, 'text'), exist_ok=True)
    o = originals()
    open(os.path.join(RES, 'music', 'desert-dream.mod'), 'wb').write(b''.join(o[f'music/{n}.bin'] for n in MODULE))
    for n, files in EFFECTS:
        wav_write(os.path.join(RES, 'sfx', wav_name(n, files)), b''.join(o[f'sfx/{f}.bin'] for f in files))
    screen_to_png(o['screen/neart000.bin'], os.path.join(RES, 'screen', 'loading.png'))
    open(os.path.join(RES, 'text', 'media-trd-sector9.txt'), 'w', encoding='utf-8').write(
        bytes_to_text(o['text/media-trd-sector9.bin']))


def check():
    with tempfile.TemporaryDirectory(dir=os.path.join(ROOT, 'work')) as tmp:
        build(tmp)
        bad = 0
        for path, data in originals().items():
            mine = open(os.path.join(tmp, path), 'rb').read()
            if mine != data:
                bad += 1
                print(f'{path}: differs')
        print('res_media: %s' % ('every resource round-trips' if not bad else f'{bad} differ'))
        return 1 if bad else 0


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'build':
        build(sys.argv[sys.argv.index('--out') + 1])
    elif cmd == 'install':
        install()
    elif cmd == 'check':
        sys.exit(check())
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
