#!/usr/bin/env python3
"""The market alive (docs/10-gameplay-logic.md 10.3): one system's 17 prices and stocks as MakeMarket `$E148` makes
them for each fluctuation byte, the byte stepped through 0-255. Each row's price moves only through the bits of its
mask (the fourth byte of its Commodities entry), so the rows move at their own speeds.

    python3 tools/fig_market.py [--system Lave] [--galaxy 1] [--step 5]   # -> docs/img/logic/market.gif

The prices and stocks are galaxy.market(), checked against the recordings in 10.3.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import galaxy as G  # noqa: E402

BG, TEXT, DIM, GRID = (14, 14, 20), (220, 220, 230), (130, 130, 145), (60, 60, 75)
PRICE, STOCK, NOW = (90, 160, 255), (110, 210, 120), (255, 210, 70)


def picture(name, economy, fl, rows, ranges, masks):
    w, h = 900, 120 + 17 * 24 + 40
    im = Image.new('RGB', (w, h), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 8), '%s\'s market (economy %d): each row moves only through its mask\'s bits of the byte'
           % (name, economy), fill=TEXT, font=K.font(15))
    d.text((10, 34), 'fluctuation $%02X = %s' % (fl, format(fl, '08b')), fill=NOW, font=K.font(18))
    d.text((230, 64), 'the price within its range over all 256 bytes (Cr)', fill=DIM, font=K.font(13))
    d.text((150, 92), 'mask', fill=DIM, font=K.font(12))
    d.text((480, 92), 'price  its range', fill=DIM, font=K.font(12))
    d.text((655, 64), 'the stock, 0-63 tonnes', fill=DIM, font=K.font(13))
    px, pw, sx, sw = 230, 240, 655, 200
    for i in range(17):
        y = 116 + i * 24
        price, stock = rows[i]
        lo, hi = ranges[i]
        d.text((10, y), G.GOODS[i], fill=TEXT, font=K.font(14))
        d.text((150, y + 2), format(masks[i], '08b'), fill=DIM, font=K.font(12))
        d.rectangle((px, y + 4, px + pw, y + 14), outline=GRID)
        if hi > lo:
            x = px + (price - lo) * pw // (hi - lo)
            d.rectangle((px, y + 4, x, y + 14), fill=PRICE)
        d.text((px + pw + 8, y), '%.1f' % (price / 10), fill=TEXT, font=K.font(13))
        d.text((px + pw + 58, y + 2), '%.1f-%.1f' % (lo / 10, hi / 10), fill=DIM, font=K.font(11))
        d.rectangle((sx, y + 4, sx + sw, y + 14), outline=GRID)
        d.rectangle((sx, y + 4, sx + stock * sw // 63, y + 14), fill=STOCK)
        d.text((sx + sw + 8, y), str(stock), fill=TEXT, font=K.font(13))
    d.text((10, h - 28), 'MakeMarket $E148 step for step (tools/fig_market.py): the economy sets the centre, the '
           'byte the swing', fill=DIM, font=K.font(12))
    return im


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--system', default='Lave')
    p.add_argument('--galaxy', type=int, default=1)
    p.add_argument('--step', type=int, default=5)
    p.add_argument('--out', default=os.path.join(HERE, '..', 'docs', 'img', 'logic', 'market.gif'))
    a = p.parse_args()
    img = G.image()
    s = [x for x in G.systems(a.galaxy, img) if x['name'] == a.system][0]
    every = [G.market(s['economy'], f, img) for f in range(256)]
    ranges = [(min(m[i][0] for m in every), max(m[i][0] for m in every)) for i in range(17)]
    masks = [G.byte(img, G.COMMODITIES + 4 * i + 3) for i in range(17)]
    pics = [picture(a.system, s['economy'], f, every[f], ranges, masks) for f in range(0, 256, a.step)]
    K.save_gif(a.out, pics, [140] * (len(pics) - 1) + [1500])
    print('wrote', os.path.relpath(a.out), len(pics), 'pictures')


if __name__ == '__main__':
    main()
