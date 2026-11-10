#!/usr/bin/env python3
"""Re-lay a wide kit/routine_anim.py GIF (memory grid | view | code panel, side by side) into a narrow one: the grid
and the view at half size, one above the other, on the left; the code panel unchanged on the right. Both picture
panels of routine_anim are scaled 4x, so the half size keeps whole 2x pixels.

    python3 tools/anim_compact.py docs/img/routines/CountDown.gif docs/img/routines/CountDown.gif \
        --grid 12,34,1036,78 --view 1048,34,2072,290 --code 2076 \
        --grid-label 'memory $9C00-$A6FF, 256 bytes a row' --view-label 'buffer $4000, 32 x 64 bytes'

--grid and --view are the boxes x0,y0,x1,y1 of the two picture panels in the source (without their labels); --code is
the x where the code panel starts (it runs to the right edge, above the legend). Without --title the
source's own title strip (the routine of the picture) is kept.
"""
import argparse

from PIL import Image, ImageDraw, ImageFont

BACKGROUND, DIM, TEXT = (14, 14, 20), (140, 140, 150), (220, 220, 220)


def font(size):
    for p in ('/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/Monaco.ttf'):
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()


def box(text):
    return tuple(int(v) for v in text.split(','))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('out')
    ap.add_argument('--grid', required=True)
    ap.add_argument('--view', required=True)
    ap.add_argument('--code', type=int, required=True)
    ap.add_argument('--legend-height', type=int, default=24)
    ap.add_argument('--title', default='')
    ap.add_argument('--grid-label', default='')
    ap.add_argument('--view-label', default='')
    a = ap.parse_args()
    gb, vb = box(a.grid), box(a.view)
    src = Image.open(a.src)
    frames, durations = [], []
    small, big = font(12), font(15)
    for i in range(src.n_frames):
        src.seek(i)
        durations.append(src.info.get('duration', 100))
        f = src.convert('RGB')
        w, h = f.size
        grid = f.crop(gb)
        grid = grid.resize((grid.width // 2, grid.height // 2), Image.NEAREST)
        view = f.crop(vb)
        view = view.resize((view.width // 2, view.height // 2), Image.NEAREST)
        code = f.crop((a.code, 0, w, h - a.legend_height))
        legend = f.crop((0, h - a.legend_height, w, h))
        gap = 12
        left = max(grid.width, view.width)
        width = gap + left + gap + code.width
        height = max(code.height, 34 + grid.height + 22 + view.height + 22) + a.legend_height
        out = Image.new('RGB', (width, height), BACKGROUND)
        d = ImageDraw.Draw(out)
        if a.title:
            d.text((gap, 8), a.title, fill=TEXT, font=big)
        else:
            out.paste(f.crop((0, 0, gap + left, 32)), (0, 0))
        y = 34
        out.paste(grid, (gap, y))
        y += grid.height + 4
        d.text((gap, y), a.grid_label, fill=DIM, font=small)
        y += 18
        out.paste(view, (gap, y))
        y += view.height + 4
        d.text((gap, y), a.view_label, fill=DIM, font=small)
        out.paste(code, (gap + left + gap, 0))
        out.paste(legend.crop((0, 0, min(legend.width, width), legend.height)), (0, height - a.legend_height))
        frames.append(out)
    pal = [fr.quantize(colors=128, method=Image.Quantize.MEDIANCUT) for fr in frames]
    pal[0].save(a.out, save_all=True, append_images=pal[1:], duration=durations, loop=0, optimize=True)
    print(a.out, frames[0].size, len(frames))


if __name__ == '__main__':
    main()
