"""Meme Man cut out of the original stonks meme (tools/data/stonks-meme.png) for the trading guide's mash-up:

    python3 tools/fig_mememan.py                # -> tools/data/mememan.png (RGBA)

GrabCut seeded with the man's rectangle; the meme's own word and its glow (right of the shoulder) masked out, and right of the neck only the dark suit kept (the word's glow lies there); the
the shirt's V between the lapels added, the largest piece kept, its holes filled, the edge feathered.
"""
import os

import cv2
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'data', 'stonks-meme.png')
OUT = os.path.join(HERE, 'data', 'mememan.png')


def main():
    img = cv2.imread(SRC)
    h, w = img.shape[:2]
    mask = np.zeros((h, w), np.uint8)
    bg, fg = np.zeros((1, 65)), np.zeros((1, 65))
    cv2.grabCut(img, mask, (0, 30, 640, h - 30), bg, fg, 8, cv2.GC_INIT_WITH_RECT)
    m = np.where((mask == 1) | (mask == 3), 255, 0).astype(np.uint8)
    m[:545, 480:] = 0  # the meme's "stonks"
    # below the chin, right of the neck, the word's white glow lies on the shoulder: there only the dark suit counts
    grey = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    right = m[440:, 440:]
    right[grey[440:, 440:] > 60] = 0
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
    m[440:, 440:] = cv2.morphologyEx(cv2.morphologyEx(right, cv2.MORPH_OPEN, k), cv2.MORPH_CLOSE, k)
    # the white collar and the blue tie: the tie is the board's blue and the collar touches the board, so GrabCut
    # drops them; the V between the lapels is the man's
    cv2.fillPoly(m, [np.array([(238, 492), (300, 528), (352, 482), (366, 492), (380, 560), (385, 700), (300, 700),
                               (250, 540)], np.int32)], 255)
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    m = np.where(lab == 1 + np.argmax(st[1:, cv2.CC_STAT_AREA]), 255, 0).astype(np.uint8)
    fill = m.copy()
    cv2.floodFill(fill, np.zeros((h + 2, w + 2), np.uint8), (w - 1, 0), 255)
    m |= cv2.bitwise_not(fill)
    m = cv2.GaussianBlur(cv2.erode(m, np.ones((3, 3), np.uint8)), (5, 5), 0)
    ys, xs = np.nonzero(m)
    x0, x1, y0 = xs.min(), xs.max() + 1, ys.min()
    rgba = np.dstack([img, m])[y0:, x0:x1]
    cv2.imwrite(OUT, rgba)
    print('wrote', os.path.relpath(OUT, os.path.dirname(HERE)), rgba.shape[1], 'x', rgba.shape[0])


if __name__ == '__main__':
    main()
