#!/usr/bin/env python3
"""A contact sheet of PNG screenshots, each labelled with its file name.

    python3 tools/sheet.py OUT.png COLUMNS SCALE IMG...
"""
import sys

from PIL import Image, ImageDraw


def main():
    out, cols, scale, files = sys.argv[1], int(sys.argv[2]), float(sys.argv[3]), sys.argv[4:]
    ims = [Image.open(f).convert('RGB') for f in files]
    w, h = int(ims[0].width * scale), int(ims[0].height * scale)
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * w, rows * (h + 12)), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    for i, (f, im) in enumerate(zip(files, ims)):
        x, y = i % cols * w, i // cols * (h + 12)
        sheet.paste(im.resize((w, h)), (x, y + 12))
        d.text((x + 2, y), f.rsplit('/', 1)[-1], fill=(255, 255, 255))
    sheet.save(out)


if __name__ == '__main__':
    main()
