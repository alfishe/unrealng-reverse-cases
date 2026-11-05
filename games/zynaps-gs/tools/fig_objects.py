#!/usr/bin/env python3
"""The object records of Zynaps GS as figures (docs/07-objects.md), from tools/gs_podbot.py's frame logs.
(The slots, record and big panels are adapted from the 48K case's tools/fig_objects.py.)

    python3 tools/fig_objects.py slots  --npz work/zgsB/e1/bot.npz
    python3 tools/fig_objects.py record --npz work/zgsB/e2/bot.npz FRAME
    python3 tools/fig_objects.py kinds
    python3 tools/fig_objects.py paths  --npz work/zgsB/e1/bot.npz [--to FRAME]
    python3 tools/fig_objects.py grid   --npz work/zgsB/f1/grid.npz FRAME
    python3 tools/fig_objects.py big    --npz work/zgsB/e2/bot.npz

  slots   docs/img/objects/slots-NAME.png: the 16 records $F36C-$F62B over the recording, one line a slot, the colour
          the kind (+7) while +8 bit 7 says active; the level changes and the weapons taken marked.
  record  docs/img/objects/records-NAME-FRAME.png: the 44 bytes of every active record at one frame, the fields
          named, and the screen with each record boxed.
  kinds   docs/img/objects/kinds.png: one crop of a real screen per kind 0-12 (e1, e2, f1), the record boxed.
  paths   docs/img/objects/paths-NAME.png: the enemies' positions over time (every logged frame), grouped by the path
          their pointer +$1D/+$1E was in when they appeared, one panel a path, the path's bytecode under it.
  grid    docs/img/objects/hit-grid.png: one frame of tools/obj_probe.py's log: the X bytes $FC00 and the Y bytes
          $FD00 of the collision grid against the screen, and the friendly records' +$0D a frame later.
  big     docs/img/objects/big-enemy.png: the big enemy (kind 12) of e2 at five moments, its hit points +$0D.
"""
import argparse
import os
import re

import numpy as np
from PIL import Image, ImageDraw

import zgsbplot as P

SLOTS = ['0 ship', '1 enemy', '2 enemy', '3 enemy', '4 enemy', '5 enemy', '6 enemy shot', '7 enemy shot',
         '8 enemy shot', '9 laser', '10 laser', '11 laser', '12 laser', '13 plasma 2', '14 side shot', '15 sight']
KIND_NAMES = {0: 'ship', 1: 'laser shot', 2: 'enemy (2)', 3: 'explosion', 4: 'pod', 5: 'enemy shot', 6: 'sight',
              7: 'seeker', 8: 'lockable (8)', 9: 'plasma ball', 10: 'homing missile', 11: 'enemy (11)',
              12: 'big enemy'}
FONT = P.K.font


def kind_rgb(k):
    return tuple(v / 255 for v in P.KIND_COLOUR.get(k, (230, 230, 230)))


def events_of(work):
    path = os.path.join(work, 'bot-events.txt')
    out = []
    if not os.path.isfile(path):
        return out
    for line in open(path):
        f, _, text = line.strip().partition('\t')
        m = re.match(r'action (\d) taken', text)
        if m:
            a = int(m.group(1))
            what = ['speed', 'laser', 'plasma', 'homing', 'seeker'][a]
            if a == 2 and 'double 1' in text:
                what = 'double plasma'
            out.append((int(f), what))
        elif text.startswith('level index') and int(f) > 0:
            out.append((int(f), 'level ' + text.split('(level ')[1].split(')')[0]))
    return out


def slots(rec, name, work):
    F = rec.F
    n = len(F)
    kinds = np.full((16, n), -1)
    for i in range(n):
        for s, k, _, _ in rec.active(i):
            kinds[s, i] = k
    P.style()
    fig, ax = P.plt.subplots(figsize=(14, 6.4))
    img = np.zeros((16, n, 3)) + np.array(P.PANEL)
    for s in range(16):
        for i in range(n):
            if kinds[s, i] >= 0:
                img[s, i] = kind_rgb(kinds[s, i])
    ax.imshow(img, aspect='auto', interpolation='nearest', extent=(F[0], F[-1], 15.5, -0.5))
    ax.set_yticks(range(16))
    ax.set_yticklabels([f'{SLOTS[s]}  ${0xF36C + 44 * s:04X}' for s in range(16)], family='monospace', fontsize=8.5)
    for k in sorted({int(k) for k in np.unique(kinds) if k >= 0}):
        ax.plot([], [], 's', color=kind_rgb(k), label=f'{k} {KIND_NAMES[k]}', ms=9)
    ax.legend(loc='upper left', bbox_to_anchor=(1.005, 1.0), fontsize=8.5, title='kind (+7)')
    busy = [(kinds[1:6, i] >= 0).sum() for i in range(n)]
    full = sum(1 for b in busy if b == 5) / n * 100
    for s in (0.5, 5.5, 8.5, 12.5):
        ax.axhline(s, color=P.BG, lw=2)
    marks = events_of(work)
    for k, (f, text) in enumerate(marks):
        ax.axvline(f, color=(1, 1, 0.6), lw=1, ls='--')
        ax.text(f, -0.75 - 0.0 * (k % 2), chr(65 + k), color=(1, 1, 0.6), fontsize=10, ha='center', va='bottom',
                weight='bold')
    ax.set_xlabel(f'{name} bot frame (a sample every 2 frames);   ' +
                  ';  '.join(f'{chr(65 + k)} {t} ({f})' for k, (f, t) in enumerate(marks)), fontsize=9)
    ax.set_title(f'The 16 object records over {name}: slots 1-5 hold the enemies, then their explosions and pods '
                 f'(all five busy {full:.0f} % of the samples);\n6-8 the enemy shots, 9-15 the ship\'s weapons',
                 fontsize=10.5, pad=20)
    fig.tight_layout()
    P.save(fig, P.out('objects', f'slots-{name}.png'))


FIELDS = [(0, 2, 'sprite descriptor'), (2, 1, 'frame'), (3, 2, 'X 8.8 (col + 16)'), (5, 2, 'Y 8.8 (row)'),
          (7, 1, 'kind'), (8, 1, 'flags'), (9, 2, 'strip buffer'), (0x0B, 1, 'row mask'),
          (0x0C, 1, 'score index'), (0x0D, 1, 'hit points / hit mask'), (0x0E, 2, 'Vx'), (0x10, 2, 'Ax'),
          (0x12, 2, 'Vy'), (0x14, 2, 'Ay'), (0x16, 1, 'direction 0-63'), (0x17, 1, 'speed'), (0x18, 1, 'fire rate'),
          (0x19, 1, 'shot speed'), (0x1A, 1, 'wave record'), (0x1B, 1, 'frames left'), (0x1C, 1, 'path command'),
          (0x1D, 2, 'path pointer'), (0x1F, 1, 'loop count'), (0x20, 1, 'shot colour'), (0x21, 1, 'aim mode'),
          (0x22, 1, 'shot life'), (0x23, 1, 'wave check'), (0x24, 1, 'collision bit'), (0x25, 1, 'colour'),
          (0x26, 1, 'counter 1 / pod'), (0x27, 1, 'counter 2'), (0x28, 1, 'counter 2 reload'), (0x29, 2, 'target'),
          (0x2B, 1, 'turn rate')]


def record(rec, frame, name):
    i = rec.index(frame)
    act = rec.active(i)
    cell, left, top = 26, 230, 200
    rows = len(act)
    W_ = left + 44 * cell + 20
    img = Image.new('RGB', (W_, top + rows * 40 + 30 + 384 + 10), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f, fs, tx = FONT(13), FONT(10), FONT(11)
    d.text((10, 8), f'The active object records at {name} frame {int(rec.F[i])}: 44 bytes each (hex), the fields named '
                    f'above, the kind +7 picks the handler', fill=P.K.TEXT, font=FONT(15))
    shades = [(40, 44, 60), (52, 56, 76)]
    for k, (off, n, label) in enumerate(FIELDS):
        x0 = left + off * cell
        d.rectangle([x0, top - 4, x0 + n * cell - 2, top + rows * 40], fill=shades[k % 2])
        tw = int(d.textlength(label, font=tx)) + 4
        lab = Image.new('RGB', (tw, 14), P.K.BACKGROUND)
        ImageDraw.Draw(lab).text((2, 0), label, fill=P.K.TEXT if k % 2 == 0 else (180, 200, 255), font=tx)
        lab = lab.rotate(90, expand=True)
        img.paste(lab, (x0 + (n * cell - 14) // 2, top - 22 - lab.size[1]))
        d.text((x0 + 2, top - 18), f'{off:02X}', fill=P.K.DIM, font=fs)
    for r, (s, kind, x, y) in enumerate(act):
        y0 = top + 14 + r * 40
        rb = rec.slot(i, s)
        col = P.KIND_COLOUR.get(kind, (230, 230, 230))
        d.text((10, y0 + 4), f'slot {s:2d} ${0xF36C + 44 * s:04X}', fill=P.K.TEXT, font=f)
        d.text((10, y0 + 20), f'kind {kind} {KIND_NAMES.get(kind, "")}', fill=col, font=fs)
        for b in range(44):
            d.text((left + b * cell + 3, y0 + 10), f'{rb[b]:02X}', fill=col if b in (3, 4, 5, 6, 7, 8) else P.K.TEXT,
                   font=f)
    scr = rec.screen_img(i, 2)
    P.boxes(scr, rec, i, 2, slots=True)
    img.paste(scr, (left, top + rows * 40 + 30))
    d.text((10, top + rows * 40 + 40), 'the same frame:\nevery active record\nboxed at its X, Y,\nslot:kind',
           fill=P.K.TEXT, font=f)
    P.saveimg(img, P.out('objects', f'records-{name}-{int(rec.F[i])}.png'))


# kind -> (recording, frame, what the crop shows); the frames were chosen with `first` below and checked by eye
KIND_PICKS = [(0, 'e1', 'ship'), (1, 'e1', 'laser shots'), (2, 'e1', 'enemy, kind 2'), (3, 'e1', 'explosion'),
              (4, 'e1', 'pod'), (5, 'e1', 'enemy shot'), (6, 'e2', 'sight (no lock)'), (7, 'f1/probe2', 'seeker'),
              (8, 'e1', 'lockable enemy'), (9, 'e1', 'plasma ball'), (10, 'e2', 'homing missile'),
              (11, 'e1', 'enemy, kind 11'), (12, 'e2', 'big enemy')]


MIN_FRAME = {7: 0, 6: 1000, 0: 600}


def kinds():
    recs = {}
    scale, cw, ch = 3, 80, 56
    W_ = 5 * (cw * scale + 14) + 14
    rows = (len(KIND_PICKS) + 4) // 5
    img = Image.new('RGB', (W_, 70 + rows * (ch * scale + 80)), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 8), 'The 13 object kinds (+7) as they show in play: a crop of a real screen per kind, its record '
                    'boxed at its X, Y (record +3/+4, +5/+6)', fill=P.K.TEXT, font=FONT(15))
    d.text((14, 30), 'kind 7 (the seeker) from f1/probe2 (tools/obj_probe.py), the others from e1 and e2 (tools/gs_podbot.py); '
                     '80 x 56 pixels x3 (kind 12: 104 x 72); a moving object shows one move behind its box',
           fill=P.K.DIM, font=FONT(13))
    for n, (kind, name, label) in enumerate(KIND_PICKS):
        path = os.path.join(P.CASE, 'work', 'zgsB', name + '.npz' if '/' in name else os.path.join(name, 'bot.npz'))
        if not os.path.isfile(path):
            continue
        rec = recs.setdefault(name, P.Rec(path, name))
        pick = None
        age = {}
        for i in range(len(rec.F)):
            now = {s: (x, y) for s, k, x, y in rec.active(i) if k == kind}
            age = {s: age.get(s, 0) + 1 for s in now}
            if rec.F[i] < MIN_FRAME.get(kind, 300):
                continue
            for s, (x, y) in now.items():
                x0, y0, x1, y1 = P.box_of(kind, x, y, 1)
                if age[s] < 4 or x0 < 8 or y0 < 10 or x1 > 248 or y1 > 140:
                    continue
                if kind == 12 and rec.slot(i, s)[0x0D] < 40:
                    continue
                pick = (i, s, x0, y0, x1, y1)
                break
            if pick:
                break
        if pick is None:
            continue
        i, s, x0, y0, x1, y1 = pick
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        if kind == 12:
            cw_, ch_ = 104, 72
        else:
            cw_, ch_ = cw, ch
        sx = int(max(0, min(256 - cw_, cx - cw_ / 2)))
        sy = int(max(0, min(192 - ch_, cy - ch_ / 2)))
        scr = rec.screen_img(i, 1).crop((sx, sy, sx + cw_, sy + ch_)).resize((cw * scale, ch * scale), Image.NEAREST)
        dd = ImageDraw.Draw(scr)
        k_ = cw * scale / cw_
        col = P.KIND_COLOUR.get(kind, (230, 230, 230))
        dd.rectangle([(x0 - sx) * k_ - 3, (y0 - sy) * k_ - 3, (x1 - sx) * k_ + 3, (y1 - sy) * k_ + 3], outline=col,
                     width=2)
        X, Y = 14 + (n % 5) * (cw * scale + 14), 64 + (n // 5) * (ch * scale + 80)
        img.paste(scr, (X, Y))
        d.text((X, Y + ch * scale + 4), f'kind {kind}: {label}', fill=col, font=FONT(14))
        r = rec.slot(i, s)
        d.text((X, Y + ch * scale + 22), f'{name} frame {int(rec.F[i])}, slot {s}\nX ${r[4]:02X}{r[3]:02X}  '
                                         f'Y ${r[6]:02X}{r[5]:02X}', fill=P.K.DIM, font=FONT(12))
        print(kind, name, int(rec.F[i]), s)
    P.saveimg(img, P.out('objects', 'kinds.png'))


def path_table():
    g = open(os.path.join(P.CASE, 'build', 'game.bin'), 'rb').read()
    m = bytearray(0x10000)
    m[0x5C00:0x5C00 + len(g)] = g
    starts = [0x681C + 2 * m[0x6800 + k] for k in range(28)]
    text = {}
    cur = None
    for line in open(os.path.join(P.CASE, 'src', 'res', 'levels', 'levels.lev.txt')):
        mm = re.match(r'(path\d+|p[0-9A-F]{4}):', line)
        if mm:
            cur = mm.group(1)
            text.setdefault(cur, '')
            continue
        if line.startswith('section') and cur:
            if 'paths' not in line:
                cur = None
            continue
        if cur and line.startswith('    '):
            text[cur] += line.strip() + ' '
    return starts, text


def lives_of(rec, upto, path_of):
    """each enemy record's life in slots 1-5: (the path it was in when it appeared, its points, frame, kind)"""
    lives, cur = [], {}
    last = rec.index(upto) if upto else len(rec.F)
    for i in range(last):
        seen = set()
        for s, k, x, y in rec.active(i):
            if s < 1 or s > 5 or k not in (2, 8, 11, 12):
                continue
            seen.add(s)
            r = rec.slot(i, s)
            ptr = int(r[0x1D]) | int(r[0x1E]) << 8
            if s not in cur:
                cur[s] = [path_of(ptr), [], int(rec.F[i]), k]
            px = (x / 256 - 16) * 8 + 12
            py = (y / 256 + 1) * 8 + 8
            cur[s][1].append((px, py))
        for s in list(cur):
            if s not in seen:
                lives.append(cur.pop(s))
    lives += list(cur.values())
    return lives


def paths(recs, upto):
    starts, text = path_table()
    uniq = sorted(set(starts))
    owner = {}
    for k, a in enumerate(starts):
        owner.setdefault(a, k)

    def path_of(ptr):
        best = None
        for a in uniq:
            if a <= ptr:
                best = a
        return owner.get(best)
    lives = []        # (path, [(x, y)], first frame)
    for rec in recs:
        lives += lives_of(rec, upto, path_of)
    rec = recs[0]
    name = '+'.join(r.name for r in recs)
    by = {}
    for p, pts, f0, k in lives:
        if p is not None and len(pts) > 3:
            by.setdefault(p, []).append((pts, f0, k))
    order = sorted(by, key=lambda p: -len(by[p]))[:8]
    P.style()
    fig, axes = P.plt.subplots(2, 4, figsize=(16, 7.4))
    bgi = rec.screen_img(rec.index(500), 1)
    bg = np.asarray(bgi).astype(float) / 255 * 0.35
    for ax, p in zip(axes.flat, order):
        ax.imshow(bg, extent=(0, 256, 192, 0))
        for n, (pts, f0, k) in enumerate(by[p][:12]):
            xs, ys = zip(*pts)
            ax.plot(xs, ys, '-', lw=1.2, color=P.COLOURS[n % len(P.COLOURS)])
            ax.plot(xs[0], ys[0], 'o', ms=4, color=P.COLOURS[n % len(P.COLOURS)])
            ax.plot(xs[-1], ys[-1], 'x', ms=5, color=P.COLOURS[n % len(P.COLOURS)])
        ax.set_xlim(0, 256)
        ax.set_ylim(152, 0)
        ax.set_xticks([0, 64, 128, 192, 256])
        ax.set_yticks([0, 40, 80, 120])
        label = f'path{p}'
        code = text.get(label, '').strip().rstrip(',')
        wrapped, line = [], ''
        for tok in code.split(', '):
            if len(line) + len(tok) > 44:
                wrapped.append(line)
                line = ''
            line += tok + ', '
        wrapped.append(line.rstrip(', '))
        ax.set_title(f'path {p} (${starts[p]:04X}): {len(by[p])} enemies\n' + '\n'.join(wrapped[:3]) +
                     (' ...' if len(wrapped) > 3 else ''), fontsize=8.5, loc='left')
    for ax in list(axes.flat)[len(order):]:
        ax.axis('off')
    kinds_seen = sorted({k for p in by for _, _, k in by[p]})
    fig.suptitle(f'The enemies of {name} as they flew, one panel per path (the 8 most flown): the '
                 f'path a record was in when it appeared, its X, Y every 2 frames\n(o where it appeared, x where it '
                 f'went: killed, exploded or off the screen; screen pixels; the background is the screen at frame '
                 f'500, dimmed; kinds {kinds_seen})', fontsize=10.5)
    fig.tight_layout()
    P.save(fig, P.out('objects', 'paths.png'))
    for p in order:
        print(p, len(by[p]))


def grid(npz, frame):
    d0 = np.load(npz)
    F = d0['frames']
    i = int(np.where(F == frame)[0][0])
    rec = P.Rec(npz, os.path.basename(os.path.dirname(os.path.abspath(npz))))
    gr = d0['grid'][i]
    xs, ys = gr[0:0x100], gr[0x100:0x190]
    scale = 3
    img = rec.screen_img(i, scale)
    P.boxes(img, rec, i, scale, slots=True)
    L, T0 = 150, 200
    canvas = Image.new('RGB', (L + 256 * scale + 290, T0 + 192 * scale + 20), P.K.BACKGROUND)
    canvas.paste(img, (L, T0))
    d = ImageDraw.Draw(canvas)
    f = FONT(13)
    cols = [(255, 90, 80), (90, 200, 120), (90, 150, 250), (240, 200, 70), (200, 110, 230), (70, 210, 220),
            (255, 150, 60), (230, 230, 230)]
    for xi in range(256):
        col_x = xi / 4 - 16
        if not xs[xi] or not 0 <= col_x < 32:
            continue
        for b in range(8):
            if xs[xi] & (1 << b):
                px = L + col_x * 8 * scale
                d.rectangle([px, T0 - 12 - 12 * b - 9, px + 2 * scale - 1, T0 - 12 - 12 * b], fill=cols[b])
    for yi in range(0x90):
        for b in range(8):
            if ys[yi] & (1 << b):
                py = T0 + (yi + 8) * scale
                d.rectangle([L - 12 - 12 * b - 9, py, L - 12 - 12 * b, py + scale - 1], fill=cols[b])
    d.text((10, 8), f'The hit grid at the end of {rec.name} frame {frame}: each enemy record (slots 1-8) ORs its '
                    f'bit into the X bytes $FC00', fill=P.K.TEXT, font=FONT(15))
    d.text((10, 28), '(above: a byte a quarter column) and the Y bytes $FD00 (left: a byte a pixel line); a friendly '
                     'record ANDs the two unions', fill=P.K.TEXT, font=FONT(15))
    d.text((10, 48), 'under its own box into +$0D: the set of enemies it overlaps. MarkEnemyGrid sets every 4th X byte and every '
                     '8th Y byte', fill=P.K.TEXT, font=FONT(15))
    d.text((10, T0 - 100), 'X bytes $FC00:\nbit b = slot b+1,\none tick a byte', fill=P.K.DIM, font=FONT(12))
    d.text((10, T0 + 4), 'Y bytes\n$FD00:\none tick\na byte', fill=P.K.DIM, font=FONT(12))
    x0 = L + 256 * scale + 16
    y = T0
    d.text((x0, y), 'bit = enemy record', fill=P.K.TEXT, font=f)
    for b in range(8):
        y += 17
        d.text((x0, y), f'bit {b}: slot {b + 1} ${0xF398 + 44 * b:04X}', fill=cols[b], font=f)
    y += 30
    nxt = i + 1
    d.text((x0, y), f'+$0D of the friendly records\nat frame {int(F[nxt])} (TestHitGrid\nruns in the next '
                    f'interrupt):', fill=P.K.TEXT, font=f)
    y += 52
    for sl, k, _, _ in rec.active(nxt):
        if sl in (0, 9, 10, 11, 12, 13, 14, 15):
            v = rec.slot(nxt, sl)[0x0D]
            d.text((x0, y), f'slot {sl:2d} {P.KINDS.get(k, k)}: %{v:08b}', fill=P.K.TEXT if v else P.K.DIM, font=f)
            y += 17
    y += 14
    v = d0['masks'][nxt]
    d.text((x0, y), f'the masks at frame {int(F[nxt])}:\n$80BB ship + lasers %{v[0]:08b}\n$80E5 plasma, seeker '
                    f'%{v[1]:08b}\n$80E3 missile %{v[2]:08b}\n$80E4 sight %{v[3]:08b}', fill=P.K.TEXT, font=f)
    P.saveimg(canvas, P.out('objects', 'hit-grid.png'))


def bigsheet(rec):
    """the big enemy of e2 at five moments"""
    F = rec.F
    life = []
    for i in range(len(F)):
        for s, k, x, y in rec.active(i):
            if k == 12:
                hp = int(rec.slot(i, s)[0x0D])
                life.append((i, s, hp - 256 if hp > 127 else hp, x, y))
    if not life:
        raise SystemExit('no kind 12 in the recording')
    first = life[0]
    # the first fight: up to the first gap
    fight = [life[0]]
    for e in life[1:]:
        if e[0] != fight[-1][0] + 1:
            break
        fight.append(e)
    end = fight[-1][0]
    hp0 = fight[0][2]
    inside = [e for e in fight if P.box_of(12, e[3], e[4], 1)[2] <= 256]
    picks = [inside[0], fight[len(fight) // 4], fight[len(fight) // 2], fight[-1]]
    drops = [(fight[k][0], fight[k - 1][2] - fight[k][2]) for k in range(1, len(fight)) if fight[k][2] < fight[k - 1][2]]
    big = [(i, n) for i, n in drops if n >= 4]
    after = min(end + 3, len(F) - 1)
    W_ = 3 * (256 * 2 + 12) + 12
    img = Image.new('RGB', (W_, 2 * (384 + 70) + 60), P.K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((12, 8), f'The big enemy of {rec.name} (level 11, handler 12): BuildBigSprite\'s 9 x 7 cells, {hp0} hit '
                    f'points worn down in {int(F[end] - F[first[0]])} frames (laser 1, missile 4), then the debris',
           fill=P.K.TEXT, font=FONT(15))
    labels = ['all on the screen', 'a quarter through the fight', 'half through', 'the last sample alive']
    shots = [(p[0], labels[k] + f', +$0D = {p[2]}') for k, p in enumerate(picks)]
    shots.append((after, 'ScatterDebris: explosions in slots 1-5'))
    for k, (i, label) in enumerate(shots):
        pic = rec.screen_img(i, 2)
        P.boxes(pic, rec, i, 2, only=(12, 3), label=False)
        x, y0 = 12 + (k % 3) * (512 + 12), 40 + (k // 3) * (384 + 70)
        img.paste(pic, (x, y0))
        d.text((x, y0 + 388), f'{rec.name} frame {int(F[i])}', fill=P.K.TEXT, font=FONT(14))
        d.text((x, y0 + 408), label, fill=P.KIND_COLOUR[12], font=FONT(14))
    # the hit points over the fight
    import matplotlib
    P.style()
    fig, ax = P.plt.subplots(figsize=(5.0, 3.6))
    ax.plot([F[e[0]] for e in fight], [e[2] for e in fight], color=tuple(c / 255 for c in P.KIND_COLOUR[12]),
            label='+$0D (signed)')
    ax.plot([F[i] for i, _ in big], [next(e[2] for e in fight if e[0] == i) for i, _ in big], 'v', ms=7,
            color=(1, 0.35, 0.35), label=f'a drop of 4+ in one sample ({len(big)})')
    ax.axhline(0, color=P.DIM, lw=0.8)
    ax.legend(fontsize=8)
    ax.set_xlabel(f'{rec.name} frame')
    ax.set_ylabel('+$0D hit points')
    ax.set_title('the hit points over the fight', fontsize=10)
    fig.tight_layout()
    tmp = os.path.join(P.CASE, 'work', 'zgsB', 'f', 'big-hp.png')
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    fig.savefig(tmp, dpi=100)
    matplotlib.pyplot.close(fig)
    ch = Image.open(tmp)
    img.paste(ch, (12 + 2 * (512 + 12), 40 + 384 + 70))
    P.saveimg(img, P.out('objects', 'big-enemy.png'))
    print('fight', int(F[first[0]]), int(F[end]), 'hp', hp0, 'samples', len(fight), 'drops', len(drops),
          'of 4+', big)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what')
    p.add_argument('rest', nargs='*')
    p.add_argument('--npz', default=os.path.join(P.CASE, 'work', 'zgsB', 'e1', 'bot.npz'))
    p.add_argument('--to', type=int, default=0)
    a = p.parse_args()
    name = os.path.basename(os.path.dirname(os.path.abspath(a.npz)))
    if a.what == 'kinds':
        kinds()
        return
    if a.what == 'grid':
        grid(a.npz, int(a.rest[0]))
        return
    rec = P.Rec(a.npz.split(',')[0], name)
    if a.what == 'slots':
        slots(rec, name, os.path.dirname(a.npz))
    elif a.what == 'record':
        record(rec, int(a.rest[0]), name)
    elif a.what == 'paths':
        paths([P.Rec(n, os.path.basename(os.path.dirname(os.path.abspath(n)))) for n in a.npz.split(',')], a.to)
    elif a.what == 'big':
        bigsheet(rec)


if __name__ == '__main__':
    main()
