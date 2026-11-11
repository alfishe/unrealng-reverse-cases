#!/usr/bin/env python3
"""The 3D models of Battle Command (display scripts of RunScript `$990F`, src/game/render.asm) as text and as
figures.

    python3 tools/models3d.py list IMAGE ORG START END        # the scripts of START-END as a listing
    python3 tools/models3d.py mission src/res/missions/NN-NAME.txt [OUT.png]
                                                            # the models of a mission (its templates' model words)
    python3 tools/models3d.py fig IMAGE ORG START END OUT.png [TITLE]
                                                            # every model of START-END drawn from above-front

IMAGE is a file whose first byte is at ORG (a mission block at `$DBC5`, a bank part at `$C000`). A library is a
run of scripts, each ended by `$FF`; parts reached by `order_by_face` and `call` lie inside the run and end with
`return` (`$09`).

The opcodes (docs: src/game/render.asm, OpcodeTable `$98E1`):

    00 nn nn a b c  native: a box generator writes the corners V34-V41 (box_square turn, size, height;
                    box_rect / box_rect16 / box_tilted half angle, radius, height)
    00 nn nn        native: any other address is a routine of the mission's code, no operands
    01 ...          the vertex program: 00-3F P=V[n], 40-7F V[n]=P, 80-BF P=(P+V[n])/2, C0 m P+=V[m],
                    E0 m P-=V[m], F0 P=-P, F8 P.x,P.z=-P.x,-P.z, any other byte ends it
    02 n 2k         project n vertices from V[k]
    03 / 10 ...     a polyline: v line to V[v], 80+v move, C0 end
    04 / 11 ...     lines drawn when one of two faces shows: (f1, f2, v), 80+v move, C0 end
    05 f n (a b c)  test n faces from slot f by the winding of three points (4 x vertex)
    06 / 07 f addr  jump when face f shows;  08 f vis hid  branch on face f
    09              return from a part;  0A f a b  draw part a then b, or b then a, by face f
    0B addr         call a part;  12 2k  translate by V[k];  16  the carried object (`$B7E5`)
    0C / 0D / 0F / 14 count, (face, length, k, colour, k points)  fill the faces (clipped / back faces)
    0E / 13 count, (k, colour, k points)  fill polygons (clipped)
    15 n next table  polar points: frames of (angle, radius, y) triples
    FF              end of the model

The geometry of the figures follows the box generators with the heading 0: BoxSquare `$AA63` V34 = (C, -h, -S),
V35 = (S, -h, C), V36 = (-C, -h, S), V37 = (-S, -h, -C) for S, C = size sin, cos (turn); BoxRect `$AB7B` V34 =
(S, -h, -C), V35 = (S, -h, C), V36 = (-S, -h, C), V37 = (-S, -h, -C) for S, C = r sin, cos (half angle), and
BoxRect16 `$AAF5` the same with r x 64 (Sine16 is 8192 sin, MulWordByte divides by 128); V38-V41 are V34-V37 at
+h. The parts ordered by a face are all drawn, back to front by a fixed view; the sizes are model units.
"""
import math
import sys

OPS = {0: 'native', 1: 'verts', 2: 'project', 3: 'lines', 4: 'lines_if_faces', 5: 'faces_test',
       6: 'jump_if_visible', 7: 'jump_if_visible2', 8: 'branch_visible', 9: 'return', 10: 'order_by_face',
       11: 'call', 12: 'fill_faces', 13: 'fill_faces_clip', 14: 'fill_polys', 15: 'fill_back_faces',
       16: 'lines_clip', 17: 'lines_if_faces_clip', 18: 'translate', 19: 'fill_polys_clip',
       20: 'fill_back_faces_clip', 21: 'polar_points', 22: 'carried_object'}
NATIVE = {0x67F4: 'box_square', 0x67F7: 'box_rect', 0x67FA: 'box_rect16', 0x67FD: 'box_square_turret',
          0xAA63: 'box_square', 0xAB7B: 'box_rect', 0xAAF5: 'box_rect16', 0xABFF: 'box_tilted',
          0xAA47: 'box_square_turret'}


class Script:
    def __init__(self, data, org):
        self.d, self.org = data, org

    def b(self, a):
        return self.d[a - self.org]

    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8

    def op(self, a):
        """(text, next address, geometry event) of the instruction at a"""
        op = self.b(a)
        if op == 0xFF:
            return 'end', a + 1, ('end',)
        n = OPS.get(op)
        if n is None:
            return 'byte $%02X (no opcode)' % op, None, None
        a += 1
        if op == 0:
            t = self.w(a)
            if t not in NATIVE:  # a routine of the mission's own code: no operands
                return 'native $%04X' % t, a + 2, None
            args = [self.b(a + 2 + i) for i in range(3)]
            return '%s %d %d %d' % (NATIVE[t], *args), a + 5, ('box', NATIVE[t], args)
        if op == 1:
            prog = []
            while True:
                x = self.b(a)
                a += 1
                if x < 0xC0 or x in (0xF0, 0xF8):
                    prog.append((x,))
                elif x in (0xC0, 0xE0):
                    prog.append((x, self.b(a)))
                    a += 1
                else:
                    break
            txt = []
            for p in prog:
                x = p[0]
                txt.append('P=V%d' % x if x < 0x40 else 'V%d=P' % (x & 63) if x < 0x80 else
                           'P=(P+V%d)/2' % (x & 63) if x < 0xC0 else 'P+=V%d' % p[1] if x == 0xC0 else
                           'P-=V%d' % p[1] if x == 0xE0 else 'P=-P' if x == 0xF0 else 'P.xz=-P.xz')
            return 'verts ' + ' '.join(txt), a, ('verts', prog)
        if op == 2:
            return 'project %d from V%d' % (self.b(a), self.b(a + 1) // 2), a + 2, None
        if op in (3, 16, 4, 17):
            seq = []
            while True:
                x = self.b(a)
                a += 1
                if x == 0xC0:
                    break
                if op in (4, 17) and not x & 0x80:  # face, face, vertex
                    seq.append(('L', self.b(a + 1), x, self.b(a)))
                    a += 2
                else:
                    seq.append(('M' if x & 0x80 else 'L', x & 0x7F))
            txt = ' '.join('%s%d' % (s[0], s[1]) + ('[f%d|f%d]' % (s[2], s[3]) if len(s) > 2 else '') for s in seq)
            return '%s %s' % (n, txt), a, ('lines', seq)
        if op == 5:
            f, k = self.b(a), self.b(a + 1)
            tr = [tuple(self.b(a + 2 + 3 * i + j) // 4 for j in range(3)) for i in range(k)]
            return 'faces_test from %d: %s' % (f, ' '.join('(%d %d %d)' % t for t in tr)), a + 2 + 3 * k, None
        if op in (6, 7):
            return '%s f%d $%04X' % (n, self.b(a), self.w(a + 1)), a + 3, ('jump', self.w(a + 1))
        if op == 8:
            return 'branch_visible f%d $%04X $%04X' % (self.b(a), self.w(a + 1), self.w(a + 3)), a + 5, \
                ('parts', [self.w(a + 1), self.w(a + 3)])
        if op == 9:
            return 'return', a, ('return',)
        if op == 10:
            return 'order_by_face f%d $%04X $%04X' % (self.b(a), self.w(a + 1), self.w(a + 3)), a + 5, \
                ('parts', [self.w(a + 1), self.w(a + 3)])
        if op == 11:
            return 'call $%04X' % self.w(a), a + 2, ('parts', [self.w(a)])
        if op == 18:
            return 'translate V%d' % (self.b(a) // 2), a + 1, None
        if op == 22:
            return 'carried_object', a, None
        if op in (12, 13, 15, 20, 14, 19):
            cnt = self.b(a)
            a += 1
            polys, txt = [], []
            for _ in range(cnt):
                if op in (14, 19):
                    k, col = self.b(a), self.b(a + 1)
                    vs = [self.b(a + 2 + i) // 4 for i in range(k)]
                    a += 2 + k
                    txt.append('(c%d %s)' % (col, ' '.join(map(str, vs))))
                else:
                    f, k, col = self.b(a), self.b(a + 2), self.b(a + 3)
                    vs = [self.b(a + 4 + i) // 4 for i in range(k)]
                    a += 4 + k
                    txt.append('(f%d c%d %s)' % (f, col, ' '.join(map(str, vs))))
                polys.append((col, vs))
            return '%s %s' % (n, ' '.join(txt)), a, ('polys', polys)
        if op == 21:
            k, nxt = self.b(a), self.w(a + 1)
            return 'polar_points %d (frames to $%04X)' % (k, nxt), nxt, None
        return n, None, None


def library(data, org, start, end):
    """[(start, [(addr, text)])] the scripts of start-end"""
    s = Script(data, org)
    out, a = [], start
    while a < end:
        lines, first = [], a
        while a is not None and a < end:
            t, nxt, ev = s.op(a)
            lines.append((a, t))
            if nxt is None or ev == ('end',):
                a = nxt
                break
            a = nxt
        out.append((first, lines))
        if a is None:
            break
    return out


def geometry(data, org, start, depth=0, seen=None):
    """the polygons and lines of the model at start, every part drawn, heading 0"""
    s = Script(data, org)
    V = {}
    polys, lines = [], []
    seen = seen if seen is not None else set()
    a = start
    for _ in range(500):
        try:
            t, nxt, ev = s.op(a)
        except IndexError:
            break
        if ev is None and nxt is None:
            break
        if ev:
            k = ev[0]
            if k in ('end', 'return'):
                break
            if k == 'box':
                kind, (p, q, h) = ev[1], ev[2]
                if kind and 'square' in kind:
                    ang = p * 2 * math.pi / 256
                    S, C = q * math.sin(ang), q * math.cos(ang)
                    base = [(C, -S), (S, C), (-C, S), (-S, -C)]
                else:  # BoxRect: r sin8 / 128; BoxRect16: r Sine16 / 128 with Sine16 = 8192 sin, 64 times larger
                    ang = p * 2 * math.pi / 256
                    r = q * (64 if '16' in kind else 1)
                    S, C = r * math.sin(ang), r * math.cos(ang)
                    base = [(S, -C), (S, C), (-S, C), (-S, -C)]
                for i, (x, z) in enumerate(base):
                    V[34 + i] = (x, -h, z)
                    V[38 + i] = (x, h, z)
                V[33] = (0, 0, 0)
            elif k == 'verts':
                P = (0, 0, 0)
                for st in ev[1]:
                    x = st[0]
                    if x < 0x40:
                        P = V.get(x, (0, 0, 0))
                    elif x < 0x80:
                        V[x & 63] = P
                    elif x < 0xC0:
                        o = V.get(x & 63, (0, 0, 0))
                        P = tuple((P[i] + o[i]) / 2 for i in range(3))
                    elif x == 0xC0:
                        o = V.get(st[1], (0, 0, 0))
                        P = tuple(P[i] + o[i] for i in range(3))
                    elif x == 0xE0:
                        o = V.get(st[1], (0, 0, 0))
                        P = tuple(P[i] - o[i] for i in range(3))
                    elif x == 0xF0:
                        P = tuple(-c for c in P)
                    elif x == 0xF8:
                        P = (-P[0], P[1], -P[2])
            elif k == 'polys':
                for col, vs in ev[1]:
                    polys.append((col, [V.get(v) for v in vs]))
            elif k == 'lines':
                cur = None
                for st in ev[1]:
                    p = V.get(st[1])
                    if st[0] == 'L' and cur is not None and p is not None:
                        lines.append((cur, p))
                    cur = p
            elif k == 'parts' and depth < 4:
                for part in ev[1]:
                    if part not in seen:
                        seen.add(part)
                        sub = geometry(data, org, part, depth + 1, seen)
                        polys += sub[0]
                        lines += sub[1]
        if nxt is None:
            break
        a = nxt
    return polys, lines


COLOURS = [(40, 40, 40), (200, 200, 200), (90, 150, 230), (210, 80, 70), (90, 190, 90), (220, 200, 80),
           (170, 110, 210), (90, 200, 200), (230, 150, 70), (140, 140, 140), (240, 240, 240), (120, 80, 50),
           (60, 100, 60)]


def model_lines(data, org, start):
    """the instructions of one model up to its `end`, the parts it jumps to included (they lie before the end)"""
    s, a, out = Script(data, org), start, []
    while a is not None:
        try:
            t, nxt, ev = s.op(a)
        except IndexError:
            out.append((a, 'runs past the block (not a model script)'))
            break
        out.append((a, t))
        if nxt is None or ev == ('end',):
            break
        a = nxt
    return out


def mission_models(text):
    """(block, [model addresses]) of a mission text: the templates' model words (+26) inside the block"""
    import res_missions
    d = res_missions.from_text(text)
    m = res_missions.parse(d)
    end = res_missions.ORG + len(d)
    ms = sorted(set(t[26] | t[27] << 8 for t in m['templates']))
    return d, [x for x in ms if res_missions.ORG <= x < end]


def figure(data, org, start, end, out_png, title='', models=None):
    from PIL import Image, ImageDraw
    if models is None:
        models = [m for m, _ in library(data, org, start, end)]
    cell, cols = 150, 8
    rows = (len(models) + cols - 1) // cols
    img = Image.new('RGB', (cols * cell, rows * cell + 20), (22, 24, 28))
    dr = ImageDraw.Draw(img)
    dr.text((4, 4), '%s: %d models, drawn from the front and above, heading 0 (tools/models3d.py)' % (
        title, len(models)), fill=(230, 230, 230))
    for i, m in enumerate(models):
        if model_lines(data, org, m)[-1][1] != 'end':
            x0, y0 = (i % cols) * cell, (i // cols) * cell + 20
            dr.rectangle([x0, y0, x0 + cell - 1, y0 + cell - 1], outline=(50, 54, 60))
            dr.text((x0 + 3, y0 + 2), '$%04X broken' % m, fill=(220, 90, 90))
            continue
        polys, lines = geometry(data, org, m)
        pts = [p for _, vs in polys for p in vs if p] + [p for l in lines for p in l]
        x0, y0 = (i % cols) * cell, (i // cols) * cell + 20
        dr.rectangle([x0, y0, x0 + cell - 1, y0 + cell - 1], outline=(50, 54, 60))
        dr.text((x0 + 3, y0 + 2), '$%04X' % m, fill=(160, 160, 160))
        if not pts:
            continue

        def proj(p):
            x, y, z = p
            return x * 0.9 + z * 0.35, -y - z * 0.35 + x * 0.15
        pp = [proj(p) for p in pts]
        mx = max(max(abs(a) for a, _ in pp), max(abs(b) for _, b in pp), 1)
        sc = (cell / 2 - 14) / mx
        cx, cy = x0 + cell / 2, y0 + cell / 2 + 6

        def scr(p):
            a, b = proj(p)
            return cx + a * sc, cy + b * sc
        depth = lambda vs: sum(p[2] - p[0] * 0.2 for p in vs) / len(vs)
        for col, vs in sorted(((c, [v for v in vs if v]) for c, vs in polys if all(vs) and len(vs) >= 3),
                              key=lambda e: -depth(e[1])):
            dr.polygon([scr(p) for p in vs], fill=COLOURS[col % len(COLOURS)], outline=(10, 10, 10))
        for p, q in lines:
            dr.line([scr(p), scr(q)], fill=(250, 250, 120), width=1)
    img.save(out_png)


def main():
    a = sys.argv[1:]
    if a[:1] == ['mission'] and len(a) >= 2:
        import os
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        d, ms = mission_models(open(a[1]).read())
        name = os.path.basename(a[1]).split('.')[0]
        if len(a) > 2:
            figure(d, 0xDBC5, 0, 0, a[2], name, ms)
        else:
            print('# %s: the %d models its templates use, in the block (tools/models3d.py mission)' % (name, len(ms)))
            for m in ms:
                lines = model_lines(d, 0xDBC5, m)
                broken = lines[-1][1] != 'end'
                print('model $%04X%s' % (m, '  # broken: the bytes are not a model script' if broken else ''))
                for ad, t in lines[:12] if broken else lines:
                    print('  $%04X %s' % (ad, t))
                print()
        return 0
    if len(a) >= 5 and a[0] in ('list', 'fig'):
        data = open(a[1], 'rb').read()
        org, start, end = (int(x.lstrip('$'), 16) for x in a[2:5])
        if a[0] == 'list':
            for m, lines in library(data, org, start, end):
                print('model $%04X' % m)
                for ad, t in lines:
                    print('  $%04X %s' % (ad, t))
                print()
        else:
            figure(data, org, start, end, a[5], a[6] if len(a) > 6 else '')
        return 0
    print(__doc__)
    return 1


if __name__ == '__main__':
    sys.exit(main())
