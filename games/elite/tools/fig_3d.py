#!/usr/bin/env python3
"""Figures and measurements of docs/3d-engine.md, every number from the game's own code run in the Z80 simulator of
tools/shipsim.py (the recorded title memory of d1 frame 250).

    python3 tools/fig_3d.py [formats] [pipeline] [drift] [maths] [octants] [costs]   # all when none named

- docs/img/3d/formats.png: the number formats as byte diagrams: a position part (24 bits, sign and magnitude), an
  axis part (16 bits), a vertex, an edge and a face of a blueprint, a projected point;
- docs/img/3d/pipeline.png: the Cobra Mk III through one DrawShip: its blueprint, the slot's three axes, the face
  test, the projected points and the back buffer, with the T of each stage (traced instruction by instruction);
- docs/img/3d/drift.png: the title's turn (MoveShip with roll $8C, pitch $94) run 3000 times with and without the
  tidy (Orthogonalise and TidyAxis): the axes' lengths and the angle between the nose and the roof;
- docs/img/3d/maths.png: Multiply8, Multiply8High, LineFraction and SquareRoot over their inputs against the exact
  results, with the T of each call;
- docs/img/3d/octants.png: 32 lines from the centre drawn by DrawLine, each pixel coloured by the loop LineSetup
  chose, with the T a pixel of each loop;
- costs: prints the T of one title update (turn, tidy, DrawShip) for each blueprint at its gallery distance.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402
import shipsim  # noqa: E402
import fig_ships  # noqa: E402

OUT = os.path.join(shipsim.CASE, 'docs', 'img', '3d')
A_, F_, B_, C_, D_, E_, H_, L_ = range(8)
SP_, PC_, T_ = 12, 24, 25
RET = shipsim.STUB + 0x40


def call(sim, mem, addr, **regs):
    """run the routine at addr with the registers given (A, B, C, ... by name) until it returns; its T"""
    names = {'A': A_, 'B': B_, 'C': C_, 'D': D_, 'E': E_, 'H': H_, 'L': L_}
    for k, v in regs.items():
        sim.registers[names[k]] = v
    mem[RET] = 0
    sp = 0xFF50
    mem[sp - 2], mem[sp - 1] = RET & 0xFF, RET >> 8
    sim.registers[SP_] = sp - 2
    t = sim.registers[T_]
    sim.run(addr, RET)
    return sim.registers[T_] - t


def traced(ship, code, marks):
    """the stub run one instruction at a time: {label: T at its first entry}, the total T"""
    sim, mem, L = ship.sim, ship.mem, ship.L
    at = {L[m]: m for m in marks}
    mem[shipsim.STUB:shipsim.STUB + len(code)] = bytes(code)
    mem[RET] = 0
    sp = 0xFF50
    mem[sp - 2], mem[sp - 1] = RET & 0xFF, RET >> 8
    sim.registers[SP_] = sp - 2
    sim.registers[PC_] = shipsim.STUB
    t0 = sim.registers[T_]
    seen = {}
    while sim.registers[PC_] != RET:
        pc = sim.registers[PC_]
        if pc in at and at[pc] not in seen:
            seen[at[pc]] = sim.registers[T_] - t0
        sim.run()
    return seen, sim.registers[T_] - t0


def turn_stub(ship):
    """TurnTitleShip with the ship's rates (as shipsim.Ship.step), as a stub"""
    L = ship.L
    t = L['TurnTitleShip']
    return [0xDD, 0x21, L['Slot7'] & 0xFF, L['Slot7'] >> 8, 0xDD, 0x66, 0x24, 0xDD, 0x6E, 0x23, 0xE5, 0xFD,
            0xE1, 0x3E, ship.roll, 0x32, L['TurnRates'] & 0xFF, L['TurnRates'] >> 8, 0x3E, ship.pitch,
            0xC3, (t + 20) & 0xFF, (t + 20) >> 8]


def word(mem, a):
    """a sign and magnitude axis part: bit 15 the sign, 15 bits of magnitude, $7FFF one"""
    w = mem[a] | mem[a + 1] << 8
    return (-1 if w & 0x8000 else 1) * (w & 0x7FFF) / 0x7FFF


def axes(mem, slot):
    return [[word(mem, slot + 9 + 6 * k + 2 * i) for i in range(3)] for k in range(3)]


# ---------------------------------------------------------------------------------------------------------------
def box(ax, x, y, w, label, colour, sub=''):
    ax.add_patch(P.plt.Rectangle((x, y), w, 0.8, color=colour, alpha=0.85))
    ax.text(x + w / 2, y + 0.4, label, ha='center', va='center', fontsize=8.5, color=(0.05, 0.05, 0.08))
    if sub:
        ax.text(x + w / 2, y - 0.25, sub, ha='center', va='center', fontsize=7.5, color=P.TEXT)


def formats():
    rows = [
        ('a position part, slot +$00 (x), +$03 (y), +$06 (z)',
         [(8, 'low'), (8, 'high'), (1, 'S'), (7, 'top')],
         'three bytes, little-endian, bit 23 the sign, 23 bits of magnitude; z > 0 is ahead.'
         ' The station in f1 1500: top $80, high $05, low $5E: z = -$055E = -1374'),
        ('an axis part, slot +$09-+$1A (nose, roof, side: x, y, z each)',
         [(8, 'low'), (1, 'S'), (7, 'high')],
         'a word, bit 15 the sign; $7FFF is one. The drawing reads only the high byte: S and 7 bits'),
        ('a blueprint vertex, 6 bytes',
         [(8, 'x'), (8, 'y'), (8, 'z'), (1, 'sx'), (1, 'sy'), (1, 'sz'), (5, 'visibility'), (4, 'face 2'),
          (4, 'face 1'), (4, 'face 4'), (4, 'face 3')],
         'magnitudes, then the three signs and the distance below which it is drawn (31 always);'
         ' the four faces it belongs to'),
        ('a blueprint edge, 4 bytes',
         [(8, 'visibility'), (8, 'vertex 1'), (8, 'vertex 2'), (4, 'face 2'), (4, 'face 1')],
         'drawn when one of its two faces is visible and the detail level is below its visibility'),
        ('a blueprint face, 4 bytes',
         [(8, 'x'), (8, 'y'), (8, 'z'), (1, 'sx'), (1, 'sy'), (1, 'sz'), (5, 'visibility')],
         "the normal's magnitudes, then its signs and visibility (the order of a vertex's first four bytes)"),
        ('a projected point, ProjectedPoints $A8FA, 3 bytes a vertex',
         [(8, 'x offset'), (8, 'y offset'), (6, '0'), (1, 'left'), (1, 'down')],
         'from the view centre (128, 64): x 0-$7F, y 0-$3F; bit 0 below it, bit 1 left of it (the signs of y and x);'
         ' $FF behind the view'),
    ]
    fig, ax = P.figure(14, 9.6)
    y = 0
    for n, (title, fields, note) in enumerate(rows):
        ax.text(0, y - 0.55, title, fontsize=10.5, color=P.WRITE, va='center')
        x = 0
        for k, (bits, label) in enumerate(fields):
            w = bits * 0.36 if bits > 1 else 0.62          # a one-bit field drawn wider, to hold its name
            box(ax, x, y, w - 0.04, label, P.PALETTE[k % len(P.PALETTE)], '%d bit%s' % (bits, 's' * (bits > 1)))
            x += w
        for b in range(0, sum(f[0] for f in fields) + 1, 8):
            ax.axvline(b * 0.36, ymin=0, ymax=0, color=P.DIM)
        import textwrap
        ax.text(0, y + 1.3, textwrap.fill(note, 120), fontsize=8.5, color=P.TEXT, va='center')
        y += 2.6
    ax.set_xlim(-0.2, 18.2)
    ax.set_ylim(y - 0.6, -1.2)
    ax.axis('off')
    ax.set_title('The 3D engine\'s numbers: sign and magnitude everywhere, positions 24 bits, axes 16, '
                 'the blueprints in bytes', fontsize=12, loc='left')
    fig.tight_layout()
    P.save(fig, os.path.join(OUT, 'formats.png'))


# ---------------------------------------------------------------------------------------------------------------
def points(mem, L, n):
    out = []
    a = L['ProjectedPoints']
    for i in range(n):
        x, y, q = mem[a + 3 * i:a + 3 * i + 3]
        out.append(None if q == 0xFF else (x, y, q))
    return out


def screen_xy(p):
    x, y, q = p
    return (128 - x if q & 2 else 128 + x), (64 + y if q & 1 else 64 - y)


def pipeline(n=9, warm=7):
    import copy
    d = 2
    s = shipsim.Ship(n, distance=d)
    for _ in range(warm):
        s.step()
    L, mem = s.L, s.mem
    snap = bytes(mem)
    regs = list(s.sim.registers)
    s.call('ClearView')
    marks = ['MoveShip', 'Orthogonalise', 'TidyAxis', 'DrawShip', 'ViewMatrixSetup', 'FaceVisibility',
             'ProjectVertices', 'DrawEdges']
    seen, total = traced(s, turn_stub(s), marks)
    shapes, headers = fig_ships.load()
    hdr = next(h for h in headers if fig_ships.NUMBERS[h[0]] == n)
    shape = shapes[hdr[1]]
    nv, ne, nf = len(shape['vertices']), len(shape['edges']), len(shape['faces'])
    fv = list(mem[L['FaceVisible']:L['FaceVisible'] + nf])
    level = mem[L['ShipDistance']]
    # ProjectVertices skips a vertex too far for the detail level or with no visible face (its entry keeps old bytes)
    seen_pts = [v if ((vis == 31 or level < vis) and any(f < nf and fv[f] for f in faces)) else None
                for v, (_x, _y, _z, vis, faces) in zip(range(nv), shape['vertices'])]
    ax_vals = axes(mem, s.slot)
    buf = shipsim.back_buffer(mem)
    # the same pass with every face visible: every point projected
    s2 = shipsim.Ship(n, distance=d)
    s2.mem[:] = snap
    s2.sim.registers[:] = regs
    s2.hidden = False
    s2.step()
    all_pts = points(s2.mem, L, nv)
    fig, axs = P.figure(15, 9.4, nrows=2, ncols=3)
    axs = axs.flatten()
    # 1 the blueprint
    a = axs[0]
    fig_ships.draw_ship(a, shape)
    a.set_title('1. The blueprint: %d vertices, %d edges, %d faces\nin the ship\'s own axes (src/res/ships)'
                % (nv, ne, nf), fontsize=9.5, loc='left')
    # 2 the axes
    a = axs[1]
    names = ['nose', 'roof', 'side']
    for k, v in enumerate(ax_vals):
        a.annotate('', xy=(v[0], v[1]), xytext=(0, 0),
                   arrowprops=dict(arrowstyle='->', color=P.PALETTE[k], lw=2))
        a.text(v[0] * 1.12, v[1] * 1.12, '%s\n(%.2f, %.2f, %.2f)' % (names[k], v[0], v[1], v[2]),
               color=P.PALETTE[k], fontsize=8.5, ha='center', va='center')
    a.set_xlim(-1.4, 1.4)
    a.set_ylim(-1.4, 1.4)
    a.set_aspect('equal')
    a.set_xticks([])
    a.set_yticks([])
    a.set_title('2. Its orientation: the slot\'s three axes\n(x across, y up here; z, the depth, in brackets)',
                fontsize=9.5, loc='left')
    # 3 the face test, 4 the points
    def edges(a, bright_only=False):
        for _d, v1, v2, f1, f2 in shape['edges']:
            p, q = all_pts[v1], all_pts[v2]
            if not p or not q:
                continue
            on = (f1 < nf and fv[f1]) or (f2 < nf and fv[f2])
            if bright_only and not on:
                continue
            (x1, y1), (x2, y2) = screen_xy(p), screen_xy(q)
            a.plot([x1, x2], [y1, y2], color=P.EXEC if on else P.HOT, lw=1.3 if on else 0.8,
                   ls='-' if on else ':')
    a = axs[2]
    edges(a)
    a.set_title('3. The face test (FaceVisibility): %d of %d faces face the player\n'
                'green: an edge of a visible face; red dotted: dropped' % (sum(1 for f in fv if f), nf),
                fontsize=9.5, loc='left')
    a = axs[3]
    for i, p in enumerate(all_pts):
        if p is None:
            continue
        x, y = screen_xy(p)
        vis = seen_pts[i] is not None
        a.plot(x, y, 'o' if vis else 'x', color=P.EXEC if vis else P.HOT, ms=4)
    a.set_title('4. The vertices projected (ProjectVertices): %d of %d\nx / depth, y / depth; red: not rotated at all'
                % (sum(1 for p in seen_pts if p), nv), fontsize=9.5, loc='left')
    a = axs[4]
    import numpy as np
    a.imshow(np.array(buf), cmap='gray', interpolation='nearest')
    a.set_title('5. The edges drawn (DrawEdges, DrawLine)\ninto the back buffer, 256 x 128', fontsize=9.5,
                loc='left')
    for a in (axs[2], axs[3]):
        a.set_xlim(0, 256)
        a.set_ylim(128, 0)
        a.set_aspect('equal')
    for a in axs[2:5]:
        a.set_xticks([0, 128, 255])
        a.set_yticks([0, 64, 127])
    # 6 the T
    a = axs[5]
    order = [m for m in marks if m in seen] + ['end']
    ts = [seen[m] for m in order[:-1]] + [total]
    labels = {'MoveShip': 'MoveShip: turn and move', 'Orthogonalise': 'Orthogonalise',
              'TidyAxis': 'TidyAxis x 2', 'DrawShip': 'DrawShip: depth, screen point',
              'ViewMatrixSetup': 'ViewMatrixSetup: side, matrix', 'FaceVisibility': 'FaceVisibility',
              'ProjectVertices': 'ProjectVertices', 'DrawEdges': 'DrawEdges + DrawLine'}
    for k in range(len(order) - 1):
        dt = ts[k + 1] - ts[k]
        a.barh(k, dt, left=ts[k], color=P.PALETTE[k])
        a.text(ts[k + 1] + total * 0.01, k, '%s  %d T' % (labels[order[k]], dt), va='center', fontsize=8.5,
               color=P.TEXT)
        print('%-18s %7d T' % (order[k], dt))
    print('total %d T, faces %s, points %d of %d' % (total, fv, sum(1 for p in seen_pts if p), nv))
    a.set_ylim(len(order) - 0.5, -0.5)
    a.set_xlim(0, total * 1.9)
    a.set_yticks([])
    a.set_xlabel('thousands of T into the update (%d T in all: %.1f frames)' % (total, total / 69888))
    a.xaxis.set_major_formatter(P.plt.FuncFormatter(lambda v, _p: '%dk' % (v / 1000)))
    a.set_title('6. Where the update\'s T goes (traced instruction by instruction)', fontsize=9.5, loc='left')
    fig.suptitle('One Cobra Mk III through the pipeline, as the title draws it (the game\'s code in the simulator, '
                 'distance %d pages)' % d, fontsize=12)
    fig.tight_layout()
    P.save(fig, os.path.join(OUT, 'pipeline.png'))


# ---------------------------------------------------------------------------------------------------------------
def drift(passes=3000):
    res = {}
    for tidy in (True, False):
        s = shipsim.Ship(8, distance=4)
        L, mem = s.L, s.mem
        slot = L['Slot7']
        code = [0xDD, 0x21, slot & 0xFF, slot >> 8, 0xDD, 0x66, 0x24, 0xDD, 0x6E, 0x23, 0xE5, 0xFD, 0xE1,
                0x3E, 0x94, 0x32, L['TurnRates'] & 0xFF, L['TurnRates'] >> 8, 0x3E, 0x8C,
                0xCD, L['MoveShip'] & 0xFF, L['MoveShip'] >> 8]
        if tidy:
            code += [0xCD, L['Orthogonalise'] & 0xFF, L['Orthogonalise'] >> 8,
                     0xDD, 0x21, (slot + 9) & 0xFF, (slot + 9) >> 8,
                     0xCD, L['TidyAxis'] & 0xFF, L['TidyAxis'] >> 8, 0xCD, L['TidyAxis'] & 0xFF, L['TidyAxis'] >> 8]
        code += [0xC9]
        out = []
        for i in range(passes):
            s.call_stub(code)
            nose, roof, _side = axes(mem, slot)
            ln = math.sqrt(sum(c * c for c in nose))
            lr = math.sqrt(sum(c * c for c in roof))
            dot = sum(a * b for a, b in zip(nose, roof)) / (ln * lr) if ln and lr else 0
            out.append((ln, lr, math.degrees(math.acos(max(-1, min(1, dot))))))
        res[tidy] = out
    fig, (ax, bx) = P.figure(13, 7.4, nrows=2, sharex=True)
    for tidy, col in ((False, P.HOT), (True, P.EXEC)):
        o = res[tidy]
        tag = 'with the tidy' if tidy else 'MoveShip alone'
        ax.plot([r[0] for r in o], color=col, lw=1.2, label='nose, ' + tag)
        ax.plot([r[1] for r in o], color=col, lw=1.0, ls='--', label='roof, ' + tag)
        bx.plot([r[2] for r in o], color=col, lw=1.2, label=tag)
        print('tidy' if tidy else 'raw ', 'nose %.4f..%.4f roof %.4f..%.4f angle %.2f..%.2f (last %.4f %.4f %.2f)'
              % (min(r[0] for r in o), max(r[0] for r in o), min(r[1] for r in o), max(r[1] for r in o),
                 min(r[2] for r in o), max(r[2] for r in o), o[-1][0], o[-1][1], o[-1][2]))
    ax.set_ylabel('axis length ($7FFF = 1)')
    ax.legend(fontsize=8.5, loc='best')
    bx.set_ylabel('nose to roof, degrees')
    bx.set_xlabel('passes of the title\'s turn (roll $8C, pitch $94)')
    bx.axhline(90, color=P.DIM, lw=0.6)
    bx.legend(fontsize=8.5)
    raw, tid = res[False], res[True]
    ax.set_title('Small-angle turns drift: MoveShip alone lets the axes reach %.2f-%.2f long and %.0f-%.0f degrees '
                 'apart in %d passes; with Orthogonalise and TidyAxis they stay %.2f-%.2f and %.1f-%.1f'
                 % (min(min(r[0], r[1]) for r in raw), max(max(r[0], r[1]) for r in raw), min(r[2] for r in raw),
                    max(r[2] for r in raw), passes, min(min(r[0], r[1]) for r in tid),
                    max(max(r[0], r[1]) for r in tid), min(r[2] for r in tid), max(r[2] for r in tid)),
                 fontsize=10.5, loc='left')
    fig.tight_layout()
    P.save(fig, os.path.join(OUT, 'drift.png'))


# ---------------------------------------------------------------------------------------------------------------
def maths():
    import numpy as np
    s = shipsim.Ship(4)
    sim, mem, L = s.sim, s.mem, s.L
    R = sim.registers
    m8 = np.zeros((256, 256))
    m8h = np.zeros((256, 256))
    t8, t8h = set(), set()
    for b in range(256):
        for c in range(256):
            t8.add(call(sim, mem, L['Multiply8'], B=b, C=c))
            m8[b, c] = b * c - (R[H_] << 8 | R[L_])
            t8h.add(call(sim, mem, L['Multiply8High'], B=b, C=c))
            m8h[b, c] = (b * c >> 8) - R[A_]
    odd = np.array([[(b + c) & 1 for c in range(256)] for b in range(256)])
    small = np.minimum.outer(np.arange(256), np.arange(256))
    rule = bool(((m8 == np.where(odd == 1, small, 0))).all())
    lf, tlf = [], []
    for b in range(1, 256):
        for a in range(b):
            tlf.append(call(sim, mem, L['LineFraction'], A=a, B=b))
            lf.append((a * 256 // b) - R[C_])
    lf = np.array(lf)
    sq, tsq = [], set()
    for n in range(1, 65536, 7):
        tsq.add(call(sim, mem, L['SquareRoot'], H=n >> 8, L=n & 0xFF))
        sq.append((n, R[H_] << 8 | R[L_]))
    ns = np.array([q[0] for q in sq], dtype=float)
    rs = np.array([q[1] for q in sq], dtype=float)
    rel = (rs - 256 * np.sqrt(ns)) / (256 * np.sqrt(ns)) * 100
    big = ns >= 256
    print('Multiply8: error %d..%d, exact %.1f %%, the rule "0 or min(b, c) when b + c is odd" %s, T %s'
          % (m8.min(), m8.max(), (m8 == 0).mean() * 100, rule, sorted(t8)))
    print('Multiply8High: error %d..%d, exact %.1f %%, T %s' % (m8h.min(), m8h.max(), (m8h == 0).mean() * 100,
                                                               sorted(t8h)))
    print('LineFraction: error %d..%d over %d inputs, T %d..%d' % (lf.min(), lf.max(), len(lf), min(tlf), max(tlf)))
    print('SquareRoot: HL out / (256 x root): %.3f..%.3f %% (HL >= 256: %.3f..%.3f %%), T %d..%d'
          % (rel.min(), rel.max(), rel[big].min(), rel[big].max(), min(tsq), max(tsq)))
    fig, axs = P.figure(15, 10, nrows=2, ncols=2)
    a = axs[0][0]
    im = a.imshow(m8, origin='lower', cmap='magma', interpolation='nearest')
    fig.colorbar(im, ax=a, fraction=0.046)
    a.set_xlabel('C')
    a.set_ylabel('B')
    a.set_title('Multiply8 $AB34, HL = B x C: exact minus HL (0 to %d)\n0 when B + C is even, exactly the smaller '
                'factor when odd; %s T' % (m8.max(), '/'.join(map(str, sorted(t8)))), fontsize=9.5, loc='left')
    a = axs[0][1]
    im = a.imshow(m8h, origin='lower', cmap='coolwarm', interpolation='nearest')
    fig.colorbar(im, ax=a, fraction=0.046)
    a.set_xlabel('C')
    a.set_ylabel('B')
    a.set_title('Multiply8High $AB0B, A = B x C / 256: the floor minus A (%d to %d)\n%.0f %% exact; %s T a call'
                % (m8h.min(), m8h.max(), (m8h == 0).mean() * 100, '/'.join(map(str, sorted(t8h)))), fontsize=9.5,
                loc='left')
    a = axs[1][0]
    a.hist(tlf, bins=range(min(tlf), max(tlf) + 2, 2), color=P.READ)
    a.set_xlabel('T a call')
    a.set_ylabel('inputs')
    a.set_title('LineFraction $B2FE, the slope C = A x 256 / B (A below B): exact for all %d inputs\n'
                '%d-%d T, eight shift-and-subtract steps' % (len(lf), min(tlf), max(tlf)), fontsize=9.5, loc='left')
    a = axs[1][1]
    a.semilogx(ns, rel, '.', ms=1.5, color=P.READ)
    a.axhline(0, color=P.DIM, lw=0.6)
    a.set_ylim(-2, 8)
    a.set_xlabel('HL in (log scale)')
    a.set_ylabel('error, % of 256 x the root')
    a.set_title('SquareRoot $9EF1: HL out = 256 x the root of HL in, two Newton steps\n%.2f to %.2f %% from 256 up '
                '(%.0f %% at HL = 1, off the scale); %d-%d T' % (rel[big].min(), rel[big].max(), rel.max(),
                                                                 min(tsq), max(tsq)), fontsize=9.5, loc='left')
    fig.suptitle('The arithmetic over all its inputs, run in the simulator: Multiply8 drops the smaller factor for '
                 'half of them, the rest are within a step', fontsize=12)
    fig.tight_layout()
    P.save(fig, os.path.join(OUT, 'maths.png'))


# ---------------------------------------------------------------------------------------------------------------
def octants(n=32, r=58):
    import numpy as np
    s = shipsim.Ship(4)
    sim, mem, L = s.sim, s.mem, s.L
    names = ('LineUpX', 'LineDownX', 'LineUpY', 'LineDownY')
    what = {'LineUpX': 'y major, going up', 'LineDownX': 'y major, going down', 'LineUpY': 'x major, going up',
            'LineDownY': 'x major, going down'}
    loops = {L[k]: k for k in names}
    col = {k: P.PALETTE[i] for i, k in enumerate(names)}
    pic = np.zeros((128, 256, 3))
    stats = {}
    R = sim.registers
    def line(x, y, q):
        mem[0xC000:0xD000] = bytes(0x1000)
        # the first end (D E) at the centre, quadrant 0; the line drawn towards the second (H L), bits 0-1
        R[D_], R[E_], R[H_], R[L_], R[C_] = 0, 0, x, y, q
        mem[RET] = 0
        sp = 0xFF50
        mem[sp - 2], mem[sp - 1] = RET & 0xFF, RET >> 8
        R[SP_] = sp - 2
        R[PC_] = L['DrawLine']
        t0 = R[T_]
        used = None
        while R[PC_] != RET:
            if R[PC_] in loops and used is None:
                used = loops[R[PC_]]
            sim.run()
        return used, R[T_] - t0, np.array(shipsim.back_buffer(mem))

    # the cost: lines of 2 to 62 pixels in four directions, one a loop
    for x, y, q in ((20, 50, 0), (20, 50, 1), (50, 20, 0), (50, 20, 1)):
        for k in range(1, 32):
            used, t, buf = line(round(x * k / 31), round(y * k / 31), q)
            stats.setdefault(used, []).append((t, int(buf.sum())))
    for i in range(n):
        ang = 2 * math.pi * (i + 0.5) / n
        dx, dy = r * math.cos(ang), r * math.sin(ang)
        x, y = min(127, round(abs(dx))), min(63, round(abs(dy)))
        q = (1 if dy > 0 else 0) | (2 if dx < 0 else 0)      # bit 0 below the centre, bit 1 left of it
        used, t, buf = line(x, y, q)
        pic[buf == 1] = col.get(used, P.TEXT)

    fig, (ax, bx) = P.figure(15, 6.2, ncols=2, gridspec_kw={'width_ratios': [1, 1.2]})
    ax.imshow(pic[:, 64:192], interpolation='nearest', extent=(63.5, 191.5, 127.5, -0.5))
    ax.set_title('32 lines drawn from the centre outwards, each coloured by the loop LineSetup chose', fontsize=10,
                 loc='left')
    ax.set_xticks([64, 128, 191])
    ax.set_yticks([0, 64, 127])
    for name in names:
        if name not in stats:
            continue
        ts = stats[name]
        per = np.polyfit([p for _t, p in ts], [t for t, _p in ts], 1)
        bx.plot([p for _t, p in ts], [t for t, _p in ts], 'o', color=col[name],
                label='%s (%s): %.0f T + %.1f T a pixel' % (name, what[name], per[1], per[0]))
        print('%-10s lines %d, %.0f T + %.1f T/pixel' % (name, len(ts), per[1], per[0]))
    bx.set_xlabel('pixels')
    bx.set_ylabel('DrawLine T')
    bx.legend(fontsize=8)
    bx.set_title('T against length, by loop', fontsize=10, loc='left')
    fig.suptitle('The line drawer\'s octants: four loops (the major axis, up or down), each patched for left or '
                 'right (RLC C or RRC C, INC L or DEC L)', fontsize=12)
    fig.tight_layout()
    P.save(fig, os.path.join(OUT, 'octants.png'))


def costs():
    import fig_ships_anim as A
    shapes, headers = fig_ships.load()
    for n in range(19):
        d = A.fit_distance(n)
        s = shipsim.Ship(n, distance=d)
        for _ in range(3):
            s.step()
        ts = []
        for _ in range(8):
            s.call('ClearView')
            t = s.sim.registers[T_]
            s.call_stub(turn_stub(s))
            ts.append(s.sim.registers[T_] - t)
        print('%2d %-24s d=%2d  %7d T (%.2f frames), min %d max %d' % (n, shipsim.NAMES[n], d, sum(ts) / len(ts),
                                                                      sum(ts) / len(ts) / 69888, min(ts), max(ts)))


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name in sys.argv[1:] or ['formats', 'pipeline', 'drift', 'maths', 'octants', 'costs']:
        globals()[name]()
