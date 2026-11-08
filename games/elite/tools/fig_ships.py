#!/usr/bin/env python3
"""The ship blueprints as a data sheet (docs/07-objects.md) and the 3D cost per ship type (docs/runtime-analysis.md),
from src/res/ships/ships.txt.

    python3 tools/fig_ships.py [--list]

The sheet: every blueprint drawn from the same three-quarter view as the game would draw it at close range: an edge
is bright when one of its two faces turns towards the viewer (EitherFace, the test DrawEdges `$AE01` makes), dim
otherwise; under it the counts (header +$03-+$05: vertices, edges, faces) and three header bytes: +$06 the top
speed, +$07 the energy, +$08-$09 the bounty in tenths of a credit (AddCash).

The cost: the title's Python (slot 7 holds the header ShipPythonTrader `$68E6`: 11 vertices, 26 edges, 13 faces) is
the only ship drawn up close in the recordings (d1 100-200). Its 13 updates give the T a vertex (ProjectVertices), a
face (FaceVisibility) and an edge (DrawEdges with its DrawLine calls); the other blueprints' cost at the same
distance is estimated from their counts with those rates (an estimate: the visible share of edges is taken as the
Python's).
"""
import argparse
import math
import os
import re
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402

SHIPS = os.path.join(P.CASE, 'src', 'res', 'ships', 'ships.txt')
# blueprint numbers (Blueprints $6180) of the header parts, from src/game/game.ann's entries
NUMBERS = {'Asp': 13, 'RockHermit': 7, 'Asteroid': 6, 'Canister': 4, 'CobraTrader': 9, 'CobraPirate': 12,
           'EscapePod': 2, 'FerDeLance': 14, 'Missile': 1, 'Plate': 3, 'PythonTrader': 10, 'PythonPirate': 11,
           'Sidewinder': 16, 'Coriolis': 0, 'Splinter': 5, 'Thargoid': 15, 'Krait': 17, 'Viper': 8, 'Thargon': 18}


def load():
    """{shape name: {'vertices': [...], 'edges': [...], 'faces': [...]}} and [(header name, shape name, bytes)]"""
    shapes, headers = {}, []
    kind = name = None
    for line in open(SHIPS):
        if line.startswith('#') or not line.strip():
            continue
        m = re.match(r'^\[Ship(\w+?)(Vertices|Edges|Faces)? (\w+)\]$', line.strip())
        if m:
            name, part, kind = m.group(1), m.group(2), m.group(3)
            if kind == 'header':
                headers.append([name, None, None])
            else:
                shapes.setdefault(name, {'vertices': [], 'edges': [], 'faces': []})
            continue
        f = line.split()
        if kind == 'header':
            headers[-1][2] = [int(x, 16) for x in f]
        elif kind == 'vertices':
            sx, sy, sz = [-1 if c == '-' else 1 for c in f[3]]
            shapes[name]['vertices'].append((sx * int(f[0]), sy * int(f[1]), sz * int(f[2]), int(f[4]),
                                             [int(x) for x in f[5:9]]))
        elif kind == 'edges':
            shapes[name]['edges'].append((int(f[0]), int(f[1]), int(f[2]), int(f[3]), int(f[4])))
        elif kind == 'faces' and f[0] != 'bytes':
            sx, sy, sz = [-1 if c == '-' else 1 for c in f[0]]
            shapes[name]['faces'].append((sx * int(f[2]), sy * int(f[3]), sz * int(f[4]), int(f[1])))
    # a header part shares the shape that follows it (CobraTrader and CobraPirate both use CobraVertices)
    names = list(shapes)
    for h in headers:
        if h[0] == 'RockHermit':  # the rock hermit has no shape of its own: the asteroid's follows its header
            h[1] = 'Asteroid'
            continue
        h[1] = next((s for s in names if h[0].startswith(s)), None) or next(
            (s for s in names if s.startswith(h[0][:5])), None)
    return shapes, headers


def rotation(yaw, pitch):
    cy, sy, cp, sp = math.cos(yaw), math.sin(yaw), math.cos(pitch), math.sin(pitch)
    ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    rx = np.array([[1, 0, 0], [0, cp, -sp], [0, sp, cp]])
    return rx @ ry


def draw_ship(ax, shape, yaw=-2.5, pitch=0.45):
    R = rotation(yaw, pitch)
    v = np.array([[x, y, z] for x, y, z, _d, _f in shape['vertices']], dtype=float) @ R.T
    normals = np.array([[x, y, z] for x, y, z, _d in shape['faces']], dtype=float).reshape(-1, 3) @ R.T
    vis = [n[2] < 0 for n in normals]  # the viewer looks along +z
    seen = 0
    for _d, a, b, f1, f2 in sorted(shape['edges'], key=lambda e: 0):
        if a >= len(v) or b >= len(v):
            continue
        on = (not len(vis)) or (f1 < len(vis) and vis[f1]) or (f2 < len(vis) and vis[f2])
        seen += on
        ax.plot([v[a, 0], v[b, 0]], [v[a, 1], v[b, 1]], color=P.EXEC if on else (0.25, 0.35, 0.3),
                lw=1.4 if on else 0.7, zorder=3 if on else 2)
    ax.set_aspect('equal')
    ax.set_xticks([])
    ax.set_yticks([])
    lim = max(1.0, float(np.abs(v[:, :2]).max())) * 1.1
    ax.set_xlim(-lim, lim)
    ax.set_ylim(-lim, lim)
    return seen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--list', action='store_true')
    a = ap.parse_args()
    shapes, headers = load()
    if a.list:
        for h, s, b in headers:
            print('%-13s shape %-10s V %2d E %2d F %2d  speed %3d energy %3d bounty %4d' % (
                h, s, b[3], b[4], b[5], b[6], b[7], b[8] | b[9] << 8))
        return
    order = sorted(headers, key=lambda h: NUMBERS.get(h[0], 99))
    n = len(order)
    cols = 4
    rows = math.ceil(n / cols)
    fig, axes = P.figure(9.6, 3.1 * rows, nrows=rows, ncols=cols)
    for ax in axes.flat:
        ax.axis('off')
    for ax, (h, s, b) in zip(axes.flat, order):
        ax.axis('on')
        shp = shapes[s]
        seen = draw_ship(ax, shp)
        ax.set_title('%d %s' % (NUMBERS.get(h, -1), h), fontsize=10)
        ax.text(0.5, -0.04, 'V %d  E %d (%d seen)  F %d\nspeed %d  energy %d\nbounty %.1f Cr' % (
            b[3], b[4], seen, b[5], b[6], b[7], (b[8] | b[9] << 8) / 10), transform=ax.transAxes, ha='center',
            va='top', fontsize=8.5, color=P.TEXT)
    fig.suptitle('The 19 blueprints (src/res/ships/ships.txt) by number: edges with a face towards the viewer bright '
                 '(what DrawEdges draws), the rest dim', fontsize=12)
    fig.tight_layout(h_pad=3.2, rect=(0, 0, 1, 0.975))
    P.save(fig, 'docs/img/objects/blueprints.png')

    # the cost per ship type, from the title Python's rates
    sys.path.insert(0, HERE)
    import rtscenes as S
    p = S.profile(S.scene('title'))
    r = p['routines']
    upd = r['ProjectVertices']['calls']
    base = shapes['Python']
    vtx_t = r['ProjectVertices']['incl'] / upd / len(base['vertices'])
    face_t = r['FaceVisibility']['incl'] / upd / len(base['faces'])
    edge_t = r['DrawEdges']['incl'] / upd / len(base['edges'])
    est = []
    for h, s, b in order:
        shp = shapes[s]
        t = vtx_t * len(shp['vertices']) + face_t * len(shp['faces']) + edge_t * len(shp['edges'])
        est.append((h, t, len(shp['vertices']), len(shp['faces']), len(shp['edges'])))
    est.sort(key=lambda e: -e[1])
    fig, ax = P.figure(11, 6)
    y = np.arange(len(est))
    left = np.zeros(len(est))
    for label, idx, rate, c in (('vertices (ProjectVertices, %.0f T each)' % vtx_t, 2, vtx_t, P.READ),
                                ('faces (FaceVisibility, %.0f T each)' % face_t, 3, face_t, P.WRITE),
                                ('edges (DrawEdges with DrawLine, %.0f T each)' % edge_t, 4, edge_t, P.EXEC)):
        vals = np.array([e[idx] * rate for e in est])
        ax.barh(y, vals, left=left, color=c, label=label)
        left += vals
    for i, e in enumerate(est):
        ax.text(e[1], i, ' %d T = %.2f frames' % (e[1], e[1] / S.FRAME_T), va='center', fontsize=8)
    ax.set_yticks(y)
    ax.set_yticklabels([e[0] for e in est], fontsize=8.5)
    ax.invert_yaxis()
    ax.set_xlim(0, max(e[1] for e in est) * 1.3)
    ax.set_xlabel('estimated T to draw one ship up close, once (the Python\'s measured rates x the blueprint\'s counts)')
    ax.legend(fontsize=8, loc='lower right')
    cob = [e for e in est if e[0] == 'PythonTrader'][0][1]
    ax.set_title('Cost per ship type: the Python measured at the title (%d updates, %.1f TV frames each), the others '
                 'estimated from their counts' % (upd, cob / S.FRAME_T), fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/runtime/ship-cost.png')
    print('rates: vertex %.0f T, face %.0f T, edge %.0f T' % (vtx_t, face_t, edge_t))


if __name__ == '__main__':
    main()
