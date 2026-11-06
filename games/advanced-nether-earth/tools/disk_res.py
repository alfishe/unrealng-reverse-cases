#!/usr/bin/env python3
"""Editable sources for the disk part's resources (aneD: the disk module in bank 4, bank 7, the game starter at
$9C40); the build turns them back into the bytes the sources INCBIN.

| Source (src/res/diskmod/) | Built (build/disk/res/diskmod/) | Format |
| --- | --- | --- |
| `font.png` | `font.bin` | the disk module's 64-column font ($49C7-$4CC6 at run time, codes $20-$7F, 8 bytes a glyph): 8 x 8 cells, 16 a row, the byte's bits as they are (the module masks one nibble: each glyph is drawn twice, in both halves); index 0 paper, 1 ink |
| `sample.wav` | `sample.bin` | bank 7 $CE09-$FFFF, the boot menu's digitised sample (key 3, $6273 in the boot program): one AY volume (0-15) a byte; the WAV is 8-bit mono PCM at 11401 Hz (307 T-states a sample at 3.5 MHz), each byte volume * 16 |
| `title.png` | `title.bin` | the game starter's picture ($9C90-$B78F: 6144 pixel bytes, 768 attributes), a 256 x 192 indexed PNG with 256 palette entries: index = bright * 128 + pixel bit * 64 + ink * 8 + paper, the entry's colour the one the pixel shows; every pixel so carries its cell's attribute (no flash) |

    python3 tools/disk_res.py build --out build/disk/res     # every source to its .bin
    python3 tools/disk_res.py export NAME FILE.bin            # bytes to the source (NAME: font, sample, title)
"""
import argparse
import os
import sys
import wave

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res')
RATE = 11401
INK, PAPER = (0, 0, 0), (255, 255, 255)


def zx_rgb(colour, bright):
    v = 0xFF if bright else 0xD7
    return ((v if colour & 2 else 0), (v if colour & 4 else 0), (v if colour & 1 else 0))


# --- the font: 96 glyphs, 8 bytes each, as 8 x 8 cells, 16 a row
def font_to_png(data):
    assert len(data) == 768
    img = Image.new('P', (128, 48), 0)
    img.putpalette(list(PAPER) + list(INK))
    for g in range(96):
        for r in range(8):
            b = data[g * 8 + r]
            for x in range(8):
                img.putpixel(((g % 16) * 8 + x, (g // 16) * 8 + r), (b >> (7 - x)) & 1)
    return img


def png_to_font(img):
    assert img.size == (128, 48) and img.mode == 'P'
    out = bytearray()
    for g in range(96):
        for r in range(8):
            b = 0
            for x in range(8):
                b = b << 1 | (1 if img.getpixel(((g % 16) * 8 + x, (g // 16) * 8 + r)) else 0)
            out.append(b)
    return bytes(out)


# --- the sample: AY volumes 0-15
def sample_to_wav(data, path):
    assert max(data) < 16
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(1)
        w.setframerate(RATE)
        w.writeframes(bytes(v * 16 for v in data))


def wav_to_sample(path):
    with wave.open(path, 'rb') as w:
        assert w.getnchannels() == 1 and w.getsampwidth() == 1
        raw = w.readframes(w.getnframes())
    return bytes(v >> 4 for v in raw)


# --- the picture: a screen (6144 + 768) as an indexed PNG whose index holds the cell's attribute and the pixel bit
def pixel_addr(y, cx):
    return (y & 0xC0) << 5 | (y & 7) << 8 | (y & 0x38) << 2 | cx


def palette():
    pal = []
    for i in range(256):
        bright, bit, ink, paper = i >> 7, i >> 6 & 1, i >> 3 & 7, i & 7
        pal += zx_rgb(ink if bit else paper, bright)
    return pal


def screen_to_png(data):
    assert len(data) == 6912
    img = Image.new('P', (256, 192), 0)
    img.putpalette(palette())
    for y in range(192):
        for cx in range(32):
            a = data[6144 + (y // 8) * 32 + cx]
            assert not a & 0x80, 'flash is not in the format'
            b = data[pixel_addr(y, cx)]
            for x in range(8):
                bit = b >> (7 - x) & 1
                img.putpixel((cx * 8 + x, y), (a >> 6 & 1) << 7 | bit << 6 | (a & 7) << 3 | (a >> 3 & 7))
    return img


def png_to_screen(img):
    assert img.size == (256, 192) and img.mode == 'P'
    out = bytearray(6912)
    for cy in range(24):
        for cx in range(32):
            attr = None
            for y in range(cy * 8, cy * 8 + 8):
                b = 0
                for x in range(8):
                    i = img.getpixel((cx * 8 + x, y))
                    a = (i >> 7) << 6 | (i & 7) << 3 | (i >> 3 & 7)
                    if attr is None:
                        attr = a
                    if a != attr:
                        sys.exit(f'title.png: cell ({cx},{cy}) holds two attributes')
                    b = b << 1 | (i >> 6 & 1)
                out[pixel_addr(y, cx)] = b
            out[6144 + cy * 32 + cx] = attr
    return bytes(out)


SOURCES = {  # resource (as the .asm INCBINs it, under build/disk/res) -> (source under src/res, to bytes, from bytes)
    'diskmod/font.bin': ('diskmod/font.png', lambda p: png_to_font(Image.open(p)),
                         lambda d, p: font_to_png(d).save(p)),
    'diskmod/sample.bin': ('diskmod/sample.wav', wav_to_sample, sample_to_wav),
    'diskmod/title.bin': ('diskmod/title.png', lambda p: png_to_screen(Image.open(p)),
                          lambda d, p: screen_to_png(d).save(p)),
}


def install(files):
    """The resources kit/mkgame.py --part src/disk/*.json found, written as their sources (and checked to give the bytes back)"""
    for name, data in files.items():
        if name not in SOURCES:
            sys.exit(f'disk_res: no source format for {name}')
        src, to_bytes, from_bytes = SOURCES[name]
        path = os.path.join(RES, src)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        from_bytes(bytes(data), path)
        if to_bytes(path) != bytes(data):
            sys.exit(f'disk_res: {src} does not give the bytes back')
        print(f'disk_res: {src} ({len(data)} bytes)')


def build(out):
    for name, (src, to_bytes, _) in SOURCES.items():
        path = os.path.join(out, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(to_bytes(os.path.join(RES, src)))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--out', required=True)
    e = sub.add_parser('export')
    e.add_argument('name', choices=['font', 'sample', 'title'])
    e.add_argument('file')
    args = p.parse_args()
    if args.cmd == 'build':
        build(args.out)
    else:
        install({f'diskmod/{args.name}.bin': open(args.file, 'rb').read()})


if __name__ == '__main__':
    main()
