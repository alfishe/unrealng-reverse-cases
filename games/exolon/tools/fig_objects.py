"""Figures of docs/07-objects.md (docs agent B).

  python3 tools/fig_objects.py kinds        docs/img/objects/kinds.png, kinds-2.png  the 16 object kinds on their
                                            elements (two figures of 8 and 6 elements)
  python3 tools/fig_objects.py sprites      docs/img/objects/sprites-small.png, sprites16.png  the two sprite sets
  python3 tools/fig_objects.py paths        docs/img/objects/alien-paths.png the six alien paths, integrated
  python3 tools/fig_objects.py traps        docs/img/objects/trap-cycle.png  a trap's counter in recording t1 (TTD reads)
  python3 tools/fig_objects.py lists        docs/img/objects/screen-lists.png a recording's CellTypes map and lists
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402
import numpy as np  # noqa: E402

# kind -> (list, record size, map value after, name); KindTable $8EF4 (record n at $8EE8 + 6n)
KINDS = {
    2: (0x8F89, 2, 0, 'flame jet'), 3: (0x9022, 3, 3, 'turret'), 4: (0x9135, 2, 0, 'colour cycle'),
    5: (0x91B0, 3, 1, 'mine'), 6: (0x9930, 2, 1, 'teleport'), 7: (0x99F2, 2, 0, 'ammo pod'),
    8: (0x99F5, 2, 0, 'grenade pod'), 9: (0x9B4B, 2, 0, 'ball spawner'), 10: (0x9C70, 3, 1, 'trap'),
    11: (0x9DC1, 2, 0, 'gun'), 12: (0x9F6E, 2, 1, 'exo booth'), 13: (0xA266, 2, 13, 'missile launcher'),
    14: (0xA333, 3, 0, 'pickup cell'), 15: (0xA814, 2, 0, 'flicker pad'), 16: (0xAAEF, 2, 0, 'zone end'),
    17: (0xABCC, 2, 1, 'force field'),
}


def kind_table_check():
    """the KINDS above against the image's KindTable"""
    M = B.image()
    for k, (lst, size, after, _) in KINDS.items():
        a = 0x8EE8 + 6 * k
        assert B.word(M, a) == lst and M[a + 4] == size and M[a + 5] == after, (k, M[a:a + 6].hex())


def element(el, r0=4, c0=4):
    M = B.image()
    cv = B.Canvas(M)
    st = {'font': 0xD7E0, 'ctype': 1, 'mark': 0, 'marks': []}
    B.print_string(cv, B.element_address(el), r0, c0, 0x47, st)
    marked = [(r, c, v[2]) for (r, c), v in cv.cells.items() if v[2] > 1] + st['marks']
    return cv, marked


def player_frame(n):
    """PlayerFrames $EF80: 25 frames of 96 bytes, 3 bytes across, 32 lines"""
    M = B.image()
    a = 0xEF80 + 96 * n
    px = np.zeros((32, 24))
    for y in range(32):
        for x in range(24):
            px[y, x] = M[a + 3 * y + x // 8] >> (7 - x % 8) & 1
    return px


KIND_PANELS = [(1, 'drop pod: jets + field'), (5, 'turret'), (43, 'blinking light'), (12, 'mine'),
               (17, 'teleport booth'), (19, 'ammo pod'), (20, 'grenade pod'), (21, 'ball pedestal'),
               (39, 'ball marks only'), (22, 'trap mark'), (26, 'gun'), (29, 'exo booth'), (31, 'missile launcher'),
               (42, 'flicker pad + zone end')]


def kind_panel(ax, el, name):
    cv, marked = element(el)
    cells = cv.cells
    rows = [r for r, _ in cells] + [r for r, _, _ in marked]
    cols = [c for _, c in cells] + [c for _, c, _ in marked]
    r0, r1, c0, c1 = min(rows) - 2, max(rows) + 2, min(cols) - 2, max(cols) + 3
    im = B.render_cells(cells, r1 - r0, c1 - c0, r0, c0)
    ax.imshow(np.asarray(im), interpolation='nearest')
    if el == 22:
        h, w = (r1 - r0) * 8, (c1 - c0) * 8
        canvas = np.zeros((max(h, 48), max(w, 80), 3))
        f = player_frame(24)
        canvas[8:40, 48:72, 1] = f * 0.85
        ax.imshow(canvas, interpolation='nearest')
        r0, c0 = marked[0][0] - 2, marked[0][1] - 2
        ax.annotate('', xy=(46, 24), xytext=(24, 20), arrowprops={'arrowstyle': '->', 'color': B.TEXT})
        ax.text(2, 46, 'drawn each pass by\n$76DA: sprite $18', fontsize=10, va='bottom')
    seen = {}
    for r, c, k in marked:
        seen.setdefault(k, []).append((r, c))
        ax.add_patch(Rectangle(((c - c0) * 8 - 0.5, (r - r0) * 8 - 0.5), 8, 8, fill=False,
                               ec=B.COLOURS[k % len(B.COLOURS)], lw=2.5))
    # one number a kind, next to its first cell, on the first free side (no two numbers within a cell of each other)
    boxes = [((c - c0) * 8, (r - r0) * 8) for r, c, _ in marked]
    placed = []
    lines = []
    for k, where in sorted(seen.items()):
        lst, size, after, kn = KINDS[k]
        lines.append(f'{k} {kn}: x{len(where)}, list ${lst:04X},\n   {size} B, map {after} after')
        r, c = where[0]
        x0, y0 = (c - c0) * 8 + 4, (r - r0) * 8 + 4
        for dx, dy in ((0, -9), (-11, 0), (11, 0), (0, 13), (-11, -9), (11, -9), (0, -18), (-20, 0), (20, 0)):
            x, y = x0 + dx, y0 + dy
            free = all(abs(x - px) > 9 or abs(y - py) > 9 for px, py in placed)
            off = all(not (bx - 1 <= x <= bx + 9 and by - 1 <= y <= by + 9) for bx, by in boxes) or dy == -18
            if free and off:
                break
        placed.append((x, y))
        ax.text(x, y, str(k), color=B.COLOURS[k % len(B.COLOURS)], ha='center', va='center', fontsize=12,
                fontweight='bold', bbox=dict(facecolor=B.BG, edgecolor='none', pad=0.5, alpha=0.75))
    ax.set_title(f'element {el} (${B.element_address(el):04X}):\n{name}', fontsize=11)
    ax.set_xlabel('\n'.join(lines), fontsize=10, loc='left')
    ax.set_xticks([])
    ax.set_yticks([])


def kinds():
    kind_table_check()
    B.style()
    for part, panels, out in ((1, KIND_PANELS[:8], 'kinds.png'), (2, KIND_PANELS[8:], 'kinds-2.png')):
        fig, axs = plt.subplots(3 if part == 1 else 2, 3, figsize=(B.WIDTH, 13.5 if part == 1 else 9.2))
        flat = list(axs.flat)
        for ax, (el, name) in zip(flat, panels):
            kind_panel(ax, el, name)
        for ax in flat[len(panels):]:
            ax.axis('off')
        last = flat[-1]
        if part == 1:
                last.text(0, 0.98, 'How the marks get there\n\n'
                      '$E8 n: the cells printed next\n   get CellTypes n (boxed)\n'
                      '$EB n: CellTypes n at the cursor,\n   nothing printed (traps, ball\n   marks, flicker pad, zone end)\n\n'
                      'IndexObjectCells $8E86 turns\neach marked cell into a record\nin the kind\'s list (KindTable\n'
                      '$8EF4), writes "map after" back.', va='top', fontsize=10.5, transform=last.transAxes)
        B.suptitle(fig, f'Sixteen object kinds: 14 of the 21 scenery elements that carry them ({part} of 2); each marked cell becomes one '
                   'list record; the number is the kind (model of PrintString $AF2B on the image)')
        fig.tight_layout(rect=(0, 0, 1, 0.95 if part == 1 else 0.93), h_pad=3.5)
        B.save(fig, B.out('objects', out))


def traps():
    """the three traps of screen 14 in recording t1 (work/ann/exC/t1): counter, row, the player's X; read through TTD
    memory_at by work/docs/docB/read_series.py into work/docs/docB/t1/traps.json"""
    import json
    d = json.load(open(os.path.join(B.DOCB, 't1', 'traps.json')))
    fr = sorted((int(f), v) for f, v in d['frames'].items())
    fr = [(f, v) for f, v in fr if 190 <= f < 1072]
    F = np.array([f for f, _ in fr])
    T = np.array([list(bytes.fromhex(v[2])) for _, v in fr])
    X = np.array([int(v[1][:2], 16) for _, v in fr])
    B.style()
    fig, axs = plt.subplots(4, 1, figsize=(B.WIDTH, 11.5), sharex=True, gridspec_kw={'height_ratios': [1, 1, 1, 1.2]})
    bands = [(0, 0x65, 'resting', (0.2, 0.2, 0.25)), (0x65, 0x69, 'rising 4', (0.55, 0.45, 0.1)),
             (0x69, 0x74, 'up 11', (0.6, 0.15, 0.15)), (0x74, 0x78, 'sinking 4', (0.55, 0.45, 0.1))]
    for t in range(3):
        ax = axs[t]
        col = T[-1, 3 * t]
        cnt = T[:, 3 * t + 2]
        for lo, hi, name, c in bands:
            ax.axhspan(lo, hi, color=c, alpha=0.6, lw=0)
            ly = {0: 0x38, 0x65: 0x5A, 0x69: 0x6E, 0x74: 0x83}[lo]     # the three thin bands' labels spread out
            ax.annotate(name, ((F[-1] + 4), (lo + hi) / 2), (F[-1] + 14, ly), fontsize=10.5, va='center',
                        annotation_clip=False, arrowprops={'arrowstyle': '-', 'color': B.DIM, 'lw': 0.8})
        ax.step(F, cnt, where='post', color=B.COLOURS[t], lw=1.6)
        for i in range(1, len(cnt)):
            if cnt[i] < cnt[i - 1] - 8:
                ax.annotate(f'${cnt[i]:02X}', (F[i], cnt[i]), (F[i] + 6, cnt[i] - 16), fontsize=10.5, color=B.TEXT)
        ax.set_ylim(0, 0x80)
        ax.set_yticks([0x14, 0x65, 0x78])
        ax.set_yticklabels(['$14', '$65', '$78'])
        ax.set_ylabel(f'trap {t}: column {col}\ncounter')
        ax.set_xlim(F[0], F[-1] + 110)
    ax = axs[3]
    ax.plot(F, X, color=B.TEXT, lw=1.5, label='PlayerX $82F5')
    for t in range(3):
        col = T[-1, 3 * t]
        up = T[:, 3 * t + 2] >= 0x65
        ax.fill_between(F, col * 4, col * 4 + 12, where=up, color=(0.85, 0.2, 0.2), alpha=0.9, step='post', lw=0)
        ax.fill_between(F, col * 4, col * 4 + 12, where=~up, color=B.COLOURS[t], alpha=0.25, step='post', lw=0)
        ax.text(F[-1] + 8, col * 4 + 6, f'trap {t}:\nX {col * 4}-{col * 4 + 11}', fontsize=10.5, va='center')
    ax.set_ylabel('X (2 px a unit, 4 a column)')
    ax.set_xlabel('frame of recording t1 (screen 14; the screen changes to 15 at frame 1072)')
    ax.legend(loc='upper left')
    ax.set_title(B.wrap('red = the trap is out (counter $65-$77); the player reaches trap 0 at frame 828 as it sinks '
                        '(row $13), traps 1 and 2 at rest', 100), fontsize=11)
    B.suptitle(fig, 'A trap rests from a random $14-$53 start to $65, rises 4 passes, stands 11, sinks 4 '
               '(t1: exploration clone on screen 14 with the immunity POKE; TrapList $9C70 read at every frame)')
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    B.save(fig, B.out('objects', 'trap-cycle.png'))


PATHS = [0xA406, 0xA445, 0xA490, 0xA4C5, 0xA4CE, 0xA4E3]


def alien_path(start, x=0x78, y=96, passes=400):
    """AliensStep $A360 on one alien: the positions pass by pass until it leaves (X >= $80 or Y >= $B0)"""
    M = B.image()
    pts = [(x, y)]
    bc, hold = start, 0
    for _ in range(passes):
        if hold:
            hold -= 1
        else:
            while True:
                if M[bc] == 0xC4:
                    hold = M[bc + 1] - 1
                    bc += 2
                    break
                if M[bc] == 0xC3:
                    bc = start
                    continue
                break
        dx, dy = B.s8(M[bc]), B.s8(M[bc + 1])
        if not hold:
            bc += 2
        x, y = (x + dx) & 0xFF, (y + dy) & 0xFF
        if x >= 0x80 or y >= 0xB0:
            return pts, True
        pts.append((x, y))
    return pts, False


def alien_screens():
    M = B.image()
    a, rows = 0xA677, []
    while M[a] != 0xFF:
        rows.append((M[a], B.word(M, a + 1), M[a + 3], M[a + 4]))
        a += 5
    return rows


def paths():
    import json
    B.style()
    rows = alien_screens()
    fig = plt.figure(figsize=(B.WIDTH, 10.8))
    gs = fig.add_gridspec(3, 3)
    flat = [fig.add_subplot(gs[r, c]) for r in range(3) for c in range(3) if (r, c) != (2, 2)]
    flat[7].remove()
    flat[7] = fig.add_subplot(gs[2, 1:])
    for i, start in enumerate(PATHS):
        ax = flat[i]
        pts, left = alien_path(start)
        xs = [2 * x for x, _ in pts]
        ys = [y for _, y in pts]
        ax.plot(xs, ys, color=B.COLOURS[i], lw=1.8)
        ax.plot(xs[::10], ys[::10], 'o', color=B.COLOURS[i], ms=3.5)
        ax.plot(xs[0], ys[0], 's', color=B.TEXT, ms=7)
        use = [r for r in rows if r[1] == start]
        ax.set_title(f'path {i + 1} ${start:04X}: {len(use)} screens\n'
                     + (f'{len(pts) - 1} passes to the left edge' if left else 'loops'), fontsize=11)
        ax.set_xlim(0, 256)
        ax.set_ylim(176, 0)
        ax.set_aspect('equal')
        ax.grid(True, alpha=0.3)
    ax = flat[6]
    d = json.load(open(os.path.join(B.DOCB, 'x2', 'aliens.json')))
    tracks = {}
    for f, v in sorted((int(f), v) for f, v in d['frames'].items()):
        if int(v[0], 16) != 5:
            continue
        b = bytes.fromhex(v[2])
        for k in range(6):
            r = b[10 * k:10 * k + 10]
            if r[2]:
                key = (k, r[3] | r[4] << 8)
                tr = tracks.setdefault(k, [])
                if not tr or tr[-1][-1] != (r[0], r[1]):
                    if tr and abs(tr[-1][-1][0] - r[0]) > 8:
                        tr.append([])
                    if not tr:
                        tr.append([])
                    tr[-1].append((r[0], r[1]))
    n = 0
    for k, segs in tracks.items():
        for seg in segs:
            if len(seg) < 5:
                continue
            n += 1
            ax.plot([2 * x for x, _ in seg], [y for _, y in seg], color=B.COLOURS[k], lw=1.2, alpha=0.9)
            mp, _ = alien_path(PATHS[0], seg[0][0], seg[0][1])
            ax.plot([2 * x for x, _ in mp], [y for _, y in mp], ':', color=B.TEXT, lw=0.8)
    ax.set_title(f'measured: x2 screen 5,\nframes 3000-3999 ({n} aliens)', fontsize=11)
    ax.set_xlim(0, 256)
    ax.set_ylim(176, 0)
    ax.set_aspect('equal')
    ax.grid(True, alpha=0.3)
    ax = flat[7]
    ax.axis('off')
    from collections import Counter
    looks = Counter(r[2] for r in rows)
    delays = Counter(r[3] for r in rows)
    ax.text(0, 1, 'AlienScreens $A677: 70 records\n(screen, path, frame, delay)\n\n'
            'frame (first of 4 sprites):\n  ' + ', '.join(f'{k}: {v}' for k, v in sorted(looks.items())) +
            '\n\ndelay between aliens (passes: screens):\n  ' +
            ', '.join(f'{k}: {v}' for k, v in sorted(delays.items())[:6]) + '\n  ' +
            ', '.join(f'{k}: {v}' for k, v in sorted(delays.items())[6:]) +
            '\n\nstart X = $78 (240 px), Y = player Y-10 or + 0..15;\n56 in 256 passes a try while PlayerX < $54\n'
            'paths: dots every 10 passes, square = start\nmeasured: solid = AlienList $A508 each frame,\n'
            'dotted = path 1 model from the same start', va='top', fontsize=10.5, transform=ax.transAxes)
    for ax in flat[:7]:
        ax.set_xlabel('X pixels')
    B.suptitle(fig, 'Six alien paths: dX dY pairs, $C4 n holds, $C3 loops; four of them end in a dash at 8 px a pass '
               '(model from the image; start at X $78, Y 96)')
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    B.save(fig, B.out('objects', 'alien-paths.png'))


def ram_lists(m):
    """the live records of every kind's list in a 64 K memory: kind -> [(column, row, rest)]"""
    out = {}
    for k, (lst, size, _, _) in KINDS.items():
        a, recs = lst, []
        while m[a] & 0x80 == 0 and len(recs) < 16:
            recs.append((m[a], m[a + 1], bytes(m[a + 2:a + size])))
            a += size
        out[k] = recs
    return out


def lists():
    rec, frame, n = 'ann/exC/t1', 500, 14
    m = B.snapshot_ram(rec, frame)
    assert m[0x8523] == n
    cv, marks = B.build_screen(n)
    model = sorted([(c, r, v[2]) for (r, c), v in cv.cells.items() if v[2] > 1] + [(c, r, k) for r, c, k in marks])
    got = ram_lists(m)
    ram = sorted((c, r, k) for k, recs in got.items() for c, r, _ in recs)
    same = model == ram
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 10.4))
    ax = fig.add_axes((0.01, 0.29, 0.6, 0.57))
    ax.imshow(np.asarray(B.zoom(B.screen(m), 1)), interpolation='nearest')
    placed = []
    for c, r, k in ram:
        col = B.COLOURS[k % len(B.COLOURS)]
        ax.add_patch(Rectangle((c * 8 - 0.5, r * 8 - 0.5), 8, 8, fill=False, ec=col, lw=2))
        if any(abs(c * 8 - x) < 28 and abs(r * 8 - y) < 28 and kk == k for x, y, kk in placed):
            continue                                  # one number for a cluster of records of one kind
        lx, ly = c * 8 + 4, r * 8 - 1.5
        while any(abs(lx - x) < 11 and abs(ly - y) < 11 for x, y, _ in placed):
            ly -= 11                                  # another kind's number there: stack above it
        placed.append((lx, ly, k))
        ax.text(lx, ly, str(k), color=col, fontsize=11, ha='center', va='bottom', fontweight='bold',
                bbox=dict(facecolor=B.BG, edgecolor='none', pad=0.3, alpha=0.7))
    ax.set_xticks([])
    ax.set_yticks([])
    ax.set_title(f'screen {n}, t1 frame {frame}: each box = one record\n(column, row) in its list; the number = kind of the group',
                 fontsize=11.5)
    ax2 = fig.add_axes((0.65, 0.6, 0.33, 0.26))
    ct = np.frombuffer(m[0x6100:0x6400], dtype=np.uint8).reshape(24, 32)
    ax2.imshow(ct, cmap='gray', vmin=0, vmax=1, interpolation='nearest')
    for c, r, k in ram:
        ax2.add_patch(Rectangle((c - 0.5, r - 0.5), 1, 1, fill=False, ec=B.COLOURS[k % len(B.COLOURS)], lw=1.5))
    ax2.set_title('CellTypes $6100 after the build:\n1 solid, 0 empty; the kinds 2-17\nare gone (each wrote its map value)',
                  fontsize=11)
    ax2.set_xticks([0, 16, 31])
    ax2.set_yticks([0, 8, 16, 23])
    ax3 = fig.add_axes((0.65, 0.24, 0.33, 0.26))
    op = np.frombuffer(m[0x5B00:0x5E00], dtype=np.uint8).reshape(24, 32)
    ax3.imshow(op == 0, cmap='gray', vmin=0, vmax=1, interpolation='nearest')
    ax3.set_title('OpenCells $5B00: white = 0\n(scenery drawn), black = $FF (open)', fontsize=11)
    ax3.set_xticks([0, 16, 31])
    ax3.set_yticks([0, 8, 16, 23])
    ax4 = fig.add_axes((0.01, 0.01, 0.98, 0.17))
    ax4.axis('off')
    import textwrap
    lines = ['kind list   records in RAM (column, row [, third byte])']
    for k, recs in got.items():
        if recs:
            lst, size, after, name = KINDS[k]
            rs = '  '.join(f'({c},{r}' + (f',${x[0]:02X}' if x else '') + ')' for c, r, x in recs)
            lines += textwrap.wrap(f'{k:>4} ${lst:04X}  {name}: {rs}', 96, subsequent_indent=' ' * 12)
    lines.append('')
    lines += textwrap.wrap(f'model (PrintString on ScreenTable $C7F4 entry {n}): {len(model)} marked cells; '
                           f'RAM: {len(ram)} records; {"equal" if same else "DIFFERENT"}', 96)
    ax4.text(0, 1, '\n'.join(lines), va='top', family='DejaVu Sans Mono', fontsize=11.5, transform=ax4.transAxes)
    B.suptitle(fig, f'The screen builder leaves the objects as list records, not as map cells: screen {n} has '
               f'{len(ram)} records in 5 lists (the model equals RAM)')
    B.save(fig, B.out('objects', 'screen-lists.png'))


def bits(data, wbytes, rows):
    px = np.zeros((rows, 8 * wbytes))
    for y in range(rows):
        for x in range(8 * wbytes):
            px[y, x] = data[wbytes * y + x // 8] >> (7 - x % 8) & 1
    return px


SMALL_USE = {0: 'grenade\n(right)', 1: 'grenade\n(left)', 2: 'debris', 3: 'no caller', 4: 'ball,\nspawn',
             5: 'no caller', 6: 'pass pad\n$9E85', 7: 'ball,\nmove', 8: 'gun shot'}


def sprite_roles():
    """frame -> (short label, colour index, legend text)"""
    roles = {0: ('blank', 7)}
    for r in alien_screens():
        for i in range(4):
            roles[r[2] + i] = (f'alien {r[2]}', 0)
    for f in range(5, 10):
        roles[f] = ('blast', 1)
    roles[10] = ('missile slow', 2)
    roles[11] = ('missile fast', 2)
    for f in range(0x1C, 0x21):
        roles[f] = ('flicker pad', 3)
    roles[0x24] = ('idle missile', 4)
    for f in range(0x0C, 0x10):
        roles[f] = ('menu star', 5)
    return roles


ROLE_LEGEND = [(0, 'alien N: alien look N (AlienScreens +3), frame N + (animation AND 3)'),
               (1, 'blast: BlastFrames $A001'), (2, 'missile slow / fast: the homing missile $A26B'),
               (3, 'flicker pad: $A7D6'), (4, 'idle missile: $AC7D'), (5, 'menu star: SparkleFrames'),
               (7, 'blank: erase and pass pad $9E99; grey "no caller": no code draws it')]
ROLE_COLOURS = [(0.7, 1, 0.7), (0.95, 0.3, 0.3), (0.4, 0.8, 1.0), (0.9, 0.9, 0.3), (0.7, 0.5, 1.0), (1, 1, 1),
                (1, 1, 1), (0.55, 0.55, 0.55)]


def sprites():
    M = B.image()
    B.style()
    # the small XOR sprites: 9 across, the four shifted copies stacked
    fig, axs = plt.subplots(1, 9, figsize=(B.WIDTH, 4.0))
    for n, ax in enumerate(axs):
        a = 0xED40 + 64 * n
        img = np.vstack([bits(M[a + 16 * k:a + 16 * k + 16], 2, 8) for k in range(4)])
        ax.imshow(img, cmap='gray', interpolation='nearest', vmin=0, vmax=1)
        for k in range(1, 4):
            ax.axhline(8 * k - 0.5, color=B.DIM, lw=0.8)
        ax.set_title(str(n), fontsize=12)
        ax.set_xlabel(SMALL_USE[n], fontsize=10.5, color=B.TEXT if 'no' not in SMALL_USE[n] else B.DIM)
        ax.set_xticks([])
        ax.set_yticks([3.5, 11.5, 19.5, 27.5])
        ax.set_yticklabels(['0', '1', '2', '3'] if n == 0 else [])
    axs[0].set_ylabel('copy E AND 3')
    B.suptitle(fig, 'SmallSprites $ED40: 9 XOR sprites of 16 x 8, each in four copies shifted 2 px (DrawSmallSprite '
               'picks copy E AND 3); 3 and 5 have no caller, 6 (the pass pad) is blank')
    fig.tight_layout(rect=(0, 0, 1, 0.88))
    B.save(fig, B.out('objects', 'sprites-small.png'))
    # Sprites16: 45 frames, 9 across
    roles = sprite_roles()
    fig = plt.figure(figsize=(B.WIDTH, 11.4))
    gs = fig.add_gridspec(6, 9, height_ratios=[1, 1, 1, 1, 1, 1.6], hspace=0.7)
    for n in range(45):
        ax = fig.add_subplot(gs[n // 9, n % 9])
        a = 0xF8E0 + 32 * n
        px = bits(M[a:a + 32], 2, 16)
        role, c = roles.get(n, ('no caller', 7))
        col = ROLE_COLOURS[c]
        ax.imshow(np.dstack([px * col[0], px * col[1], px * col[2]]), interpolation='nearest')
        ax.set_xticks([])
        ax.set_yticks([])
        ax.set_title(f'{n} ${n:02X}', fontsize=10.5)
        ax.set_xlabel(role, fontsize=10, color=B.DIM if role == 'no caller' else B.TEXT)
    ax = fig.add_subplot(gs[5, :])
    ax.axis('off')
    for i, (c, text) in enumerate(ROLE_LEGEND):
        y = 1 - i * 0.14
        ax.add_patch(Rectangle((0, y - 0.1), 0.012, 0.09, color=ROLE_COLOURS[c], transform=ax.transAxes,
                               clip_on=False))
        ax.text(0.02, y - 0.05, text, fontsize=10.5, va='center', transform=ax.transAxes)
    B.suptitle(fig, 'Sprites16 $F8E0: 45 frames of 16 x 16 drawn by DrawSprite, coloured by who draws them; '
               'frames 33-35 have no caller')
    fig.subplots_adjust(left=0.02, right=0.98, top=0.9, bottom=0.02)
    B.save(fig, B.out('objects', 'sprites16.png'))


if __name__ == '__main__':
    {'kinds': kinds, 'traps': traps, 'paths': paths, 'lists': lists, 'sprites': sprites}[sys.argv[1]]()
