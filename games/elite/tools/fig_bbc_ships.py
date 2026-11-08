#!/usr/bin/env python3
"""The same ship from the Spectrum's blueprint and from the BBC disc's (docs/bbc-comparison.md 1): both drawn by one
renderer from the same view, so what differs is the data, not the drawing.

    python3 tools/fig_bbc_ships.py BBC_DIR     # -> docs/img/bbc/ships.png

The renderer turns the vertices and the face normals by one matrix, puts the ship ahead of the eye, and draws an
edge when one of its two faces turns towards the eye (normal . point < 0); face 15 is always seen (the BBC's
XX2+15 = 255), and a ship with no faces has every edge drawn. The
third column overlays the two: white where both draw an edge, orange only the Spectrum, blue only the BBC.
BBC_DIR as for tools/bbc_compare.py.
"""
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import bbc_compare as B  # noqa: E402

BG, TEXT, DIM = (14, 14, 20), (220, 220, 230), (130, 130, 145)
BOTH, ZX, BBC = (230, 230, 230), (255, 150, 60), (90, 160, 255)
ROWS = [('Viper', 'VIPER', 'the same data: the same picture'),
        ('PythonTrader', 'PYTHON', 'same faces; four edges seen to visibility 9, not 7: alike up close'),
        ('Missile', 'MISSILE', 'faces 7-8 differ from the default disc build (the sideways RAM one has ours)'),
        ('Splinter', 'SPLINTER', 'the escape pod\'s edges in both; other face normals'),
        ('Plate', 'PLATE', 'no normals against one, but face 15 is always seen: alike')]


def matrix(yaw, pitch, roll):
    cy, sy, cp, sp, cr, sr = (math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch), math.cos(roll),
                              math.sin(roll))
    ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    rx = [[1, 0, 0], [0, cp, -sp], [0, sp, cp]]
    rz = [[cr, -sr, 0], [sr, cr, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return mul(rz, mul(rx, ry))


def turn(m, v):
    return [sum(m[i][k] * v[k] for k in range(3)) for i in range(3)]


def visible_edges(ship, m, dist):
    verts = [turn(m, v[0:3]) for v in ship['vertices']]
    pts = [(x, y, z + dist) for x, y, z in verts]
    faces = ship['faces']
    seen = set()
    for f, n in enumerate(faces):
        nn = turn(m, n[0:3])
        on = [pts[i] for i, v in enumerate(ship['vertices']) if f in v[4]]
        if not on:
            continue
        p = on[0]
        if nn[0] * p[0] + nn[1] * p[1] + nn[2] * p[2] < 0:
            seen.add(f)
    out = set()
    for _vis, (a, b), (f1, f2) in ship['edges']:
        if not faces or f1 in seen or f2 in seen or 15 in (f1, f2):
            out.add((a, b))
    return pts, out


def draw(d, pts, edges, box, colour_of):
    x0, y0, w, h = box
    proj = [(x / z, -y / z) for x, y, z in pts]
    xs, ys = [p[0] for p in proj], [p[1] for p in proj]
    s = 0.8 * min(w / (max(xs) - min(xs) or 1), h / (max(ys) - min(ys) or 1))
    cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    for e in sorted(edges, key=lambda e: colour_of(e) == BOTH):
        (ax, ay), (bx, by) = proj[e[0]], proj[e[1]]
        d.line((x0 + w / 2 + (ax - cx) * s, y0 + h / 2 + (ay - cy) * s,
                x0 + w / 2 + (bx - cx) * s, y0 + h / 2 + (by - cy) * s), fill=colour_of(e), width=2)


def main():
    bbc = sys.argv[1]
    zx, bb = B.spectrum_ships(), B.bbc_ships(bbc)
    m = matrix(1.04, 1.14, 0.25)
    cw, ch, lw = 230, 170, 250
    im = Image.new('RGB', (lw + 3 * cw + 20, 70 + len(ROWS) * ch + 30), BG)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'The same ship from both blueprints, one renderer: only the missile\'s and the splinter\'s '
           'faces change it', fill=TEXT, font=K.font(15))
    heads = ('the Spectrum\'s blueprint', 'the BBC disc\'s', 'both: white same,\norange ZX only, blue BBC only')
    for k, t in enumerate(heads):
        d.multiline_text((lw + k * cw + 6, 34), t, fill=DIM, font=K.font(12), spacing=2)
    for r, (zname, bname, note) in enumerate(ROWS):
        y = 66 + r * ch
        a, b = zx[zname], bb[bname]
        dist = 4 * max(abs(c) for v in a['vertices'] for c in v[0:3])
        pa, ea = visible_edges(a, m, dist)
        pb, eb = visible_edges(b, m, dist)
        d.text((10, y + 50), zname, fill=TEXT, font=K.font(15))
        d.text((10, y + 74), note, fill=DIM, font=K.font(12)) if len(note) < 34 else None
        if len(note) >= 34:
            words, line, yy = note.split(), '', y + 74
            for w in words:
                if len(line) + len(w) > 32:
                    d.text((10, yy), line, fill=DIM, font=K.font(12))
                    line, yy = '', yy + 16
                line += w + ' '
            d.text((10, yy), line, fill=DIM, font=K.font(12))
        draw(d, pa, ea, (lw, y, cw, ch - 10), lambda e: BOTH)
        draw(d, pb, eb, (lw + cw, y, cw, ch - 10), lambda e: BOTH)
        both = ea | eb
        draw(d, pa, both, (lw + 2 * cw, y, cw, ch - 10),
             lambda e: BOTH if e in ea and e in eb else (ZX if e in ea else BBC))
        print('%s: %d edges drawn ZX, %d BBC, %d in both' % (zname, len(ea), len(eb), len(ea & eb)))
    d.text((10, im.height - 24), 'python3 tools/fig_bbc_ships.py work/bbc: one view (yaw 1.04, pitch 1.14, roll 0.25), '
           'the face test normal . point < 0', fill=DIM, font=K.font(12))
    out = os.path.join(HERE, '..', 'docs', 'img', 'bbc', 'ships.png')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    im.save(out)
    print('wrote docs/img/bbc/ships.png')


if __name__ == '__main__':
    main()
