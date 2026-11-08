#!/usr/bin/env python3
"""Figures of docs/scenes.md that are not plain screens.

    python3 tools/fig_scenes.py [tape] [commanders]          # all when none named

- docs/img/scenes/tape.png: t1's commander save as the tape signal (the MIC bit's edges in the trace
  work/t1/traces/2364_0-2490_0.uatr: the end of the pilot, the sync, the flag byte and the first letters) above the
  102-byte record it carries (work/tapes/jameson-t1.tap, read back by tools/tape_from_trace.py), each byte
  coloured by its field.
- docs/img/scenes/commanders.png: the commander tapes the scenes load (work/tapes/*.tap), each against the tape it
  was made from: a strip of its 102 bytes (the changed ones bright, in their field's colour) and the changed fields
  with the old and the new values.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import rtplot as P  # noqa: E402
import tape_from_trace as T  # noqa: E402

# the record's fields: (offset, length, name) from $D054 (tools/commander_tape.py)
FIELDS = [(0x00, 11, 'name'), (0x0B, 1, 'legal'), (0x0C, 3, 'combat score'), (0x0F, 2, 'jumps'),
          (0x11, 1, 'galaxy'), (0x12, 4, 'cash'), (0x16, 1, 'fluctuation'), (0x17, 17, 'hold (17 goods)'),
          (0x28, 1, 'free space'), (0x29, 4, 'lasers'), (0x2D, 1, 'nova'), (0x2E, 1, 'fuel'), (0x2F, 1, 'missiles'),
          (0x30, 10, 'equipment flags'), (0x3A, 16, 'galaxy and system seeds'), (0x4A, 17, 'station stock'),
          (0x5B, 1, 'mission state'), (0x5C, 1, 'mission flags'), (0x5D, 9, 'sun position')]


def tape():
    trace = E.K.access_trace().load(os.path.join(E.CASE, 'work', 't1', 'traces', '2364_0-2490_0.uatr'))
    times = T.edges(trace)
    pilot, block, _hist = T.decode(times)
    gaps = [b - a for a, b in zip(times, times[1:])]
    i = 0
    while not 2000 < gaps[i] < 2400:
        i += 1
    while 2000 < gaps[i] < 2400:
        i += 1
    sync = i                     # the index of the first sync edge
    lo, hi = sync - 8, sync + 2 + 2 * 8 * 4 + 1
    t0 = times[lo]
    xs, ys, level = [], [], 0
    for k in range(lo, hi):
        xs += [(times[k] - t0) / 3500, (times[k + 1] - t0) / 3500]
        ys += [level, level]
        level ^= 1
    fig, (ax, bx) = P.figure(14, 8.4, nrows=2, gridspec_kw={'height_ratios': [1, 2.2]})
    ax.plot(xs, ys, color=P.EXEC, lw=1.2)
    ax.set_yticks([0, 1])
    ax.set_yticklabels(['MIC 0', 'MIC 1'])
    ax.set_xlabel('ms from the last pilot edges (3.5 T a microsecond)')
    x_sync = (times[sync] - t0) / 3500
    ax.axvspan(0, x_sync, color=P.DIM, alpha=0.15)
    ax.text(x_sync / 2, 1.18, 'pilot: edges 2168 T apart', ha='center', fontsize=9, color=P.TEXT)
    ax.text(x_sync, 1.36, 'sync 667 + 735', ha='left', fontsize=9, color=P.WRITE)
    k = sync + 2
    for n, byte in enumerate(block[:4]):
        a = (times[k] - t0) / 3500
        b = (times[k + 16] - t0) / 3500
        ax.axvline(a, color=P.DIM, lw=0.6, ls=':')
        ax.text((a + b) / 2, -0.22, '%s $%02X\n%s' % ('flag' if n == 0 else 'byte %d' % (n - 1), byte,
                                                         format(byte, '08b')),
                ha='center', va='top', fontsize=8.5, color=P.READ)
        k += 16
    ax.set_ylim(-0.75, 1.6)
    ax.set_title('The save as the tape hears it: SA-BYTES toggles the MIC bit; a 0 bit is two edges 855 T apart, a 1 '
                 'bit two of 1710 (%d pilot edges in all)' % pilot, fontsize=10, loc='left')
    rec = block[1:-1]
    colours = {}
    for idx, (off, ln, name) in enumerate(FIELDS):
        for j in range(off, off + ln):
            colours[j] = (idx, name)
    for j, v in enumerate(rec):
        r, c = divmod(j, 16)
        idx, name = colours[j]
        col = P.PALETTE[idx % len(P.PALETTE)]
        bx.add_patch(P.plt.Rectangle((c, r), 0.94, 0.9, color=col, alpha=0.85))
        ch = chr(v) if 0x41 <= v <= 0x5A else ''
        bx.text(c + 0.47, r + 0.45, '%02X%s' % (v, '\n' + ch if ch else ''), ha='center', va='center', fontsize=8,
                color=(0.05, 0.05, 0.08))
    for idx, (off, ln, name) in enumerate(FIELDS):
        r, c = divmod(off, 16)
        bx.text(16.3, idx * 0.37, '+$%02X %s (%d)' % (off, name, ln), fontsize=8.5,
                color=P.PALETTE[idx % len(P.PALETTE)], va='center')
    bx.set_xlim(0, 22)
    bx.set_ylim(7.1, -0.2)
    bx.set_xticks([c + 0.47 for c in range(16)])
    bx.set_xticklabels(['+%X' % c for c in range(16)], fontsize=8)
    bx.set_yticks([r + 0.45 for r in range(7)])
    bx.set_yticklabels(['$%02X' % (16 * r) for r in range(7)], fontsize=8)
    bx.set_aspect('equal')
    bx.set_title("The 102 bytes it carries: JAMESON after t1's trades (47.2 Cr, 3 t food, 2 t textiles, 4 missiles); "
                 'the name ends with a 0, the rest of its field keeps older bytes', fontsize=10,
                 loc='left')
    fig.suptitle('A commander on tape: one headerless block (flag $FF), the record $D054-$D0B9 and a parity byte',
                 fontsize=12)
    fig.tight_layout()
    P.save(fig, 'docs/img/scenes/tape.png')


LINEAGE = [('jameson-t1', None, "t1's save"), ('rich', 'jameson-t1', 'dk, gx, cs'), ('k2', 'rich', 'k2'),
           ('fs', 'rich', 'the attempt of 9'), ('sc', 'rich', 'no scene'), ('galaxy2', 'rich', "gx's save"),
           ('nova', 'galaxy2', 'm1'), ('mayday', 'galaxy2', 'm2')]


def commanders():
    import commander_tape as C
    from PIL import Image, ImageDraw
    K = E.K
    tapes = {n: C.read(os.path.join(E.CASE, 'work', 'tapes', n + '.tap')) for n, _, _ in LINEAGE}
    field_of = {}
    for idx, (off, ln, name) in enumerate(FIELDS):
        for j in range(off, off + ln):
            field_of[j] = idx
    colour = [tuple(int(255 * v) for v in P.PALETTE[i % len(P.PALETTE)][:3]) for i in range(len(FIELDS))]

    def value(r, name):
        off, ln = next((o, n) for o, n, f in FIELDS if f == name)
        b = r[off:off + ln]
        if name == 'name':
            return bytes(b).split(b'\0')[0].decode('ascii', 'replace').strip()
        if name == 'cash':
            return '%.1f Cr' % (C.cash(r) / 10)
        if name == 'fuel':
            return '%.1f ly' % (b[0] / 10)
        if name == 'combat score':
            return '$%02X%02X%02X' % (b[2], b[1], b[0])
        if name == 'lasers':
            return ','.join(str(v) for v in b)
        if name == 'hold (17 goods)':
            got = ['%d %s' % (v, C.GOODS[i].lower()) for i, v in enumerate(b) if v]
            return ', '.join(got) or 'empty'
        if name == 'equipment flags':
            return '%d items' % sum(1 for v in b if v)
        if name in ('free space', 'jumps', 'galaxy', 'fluctuation'):
            return str(b[0] if ln == 1 else b[0] | b[1] << 8)
        if name == 'mission flags':
            return '$%02X' % b[0]
        return 'new'

    f13, f14, f15, f17 = K.font(13), K.font(14), K.font(15), K.font(17)
    W, cell, x0 = 900, 7, 178
    rows = []
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    for n, src, used in LINEAGE:
        r = tapes[n]
        chips = []
        if src:
            for idx, (off, ln, name) in enumerate(FIELDS):
                if tapes[src][off:off + ln] != r[off:off + ln]:
                    old, new = value(tapes[src], name), value(r, name)
                    chips.append((idx, '%s: %s' % (name.split(' (')[0], new if old == 'new' else '%s > %s' % (old, new))))
        # chips laid out in lines under the strip
        lines, line, w = [], [], 0
        for idx, text in chips:
            tw = probe.textlength(text, font=f13) + 16
            if w + tw > W - x0 - 10 and line:
                lines.append(line)
                line, w = [], 0
            line.append((idx, text, tw))
            w += tw + 6
        if line:
            lines.append(line)
        rows.append((n, src, used, r, lines))
    title = ['The scenes start from edited copies of real saves: each tape changes only the fields',
             'named, and the game loads it as a save (it checks only the parity)']
    top = 10 + 23 * len(title) + 30
    heights = [24 + 20 * max(1, len(lines)) + 16 for *_, lines in rows]
    im = Image.new('RGB', (W, top + sum(heights) + 10), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    for i, t in enumerate(title):
        d.text((10, 10 + 23 * i), t, fill=K.TEXT, font=f17)
    d.text((x0, top - 24), 'the 102 bytes of the record, +$00 at the left; bright: changed from the tape it came from',
           fill=K.DIM, font=f13)
    y = top
    for (n, src, used, r, lines), h in zip(rows, heights):
        d.text((10, y), n + '.tap', fill=K.TEXT, font=f15)
        d.text((10, y + 20), ('from ' + src + '.tap' if src else "from t1's trace"), fill=K.DIM, font=f13)
        d.text((10, y + 38), used, fill=K.DIM, font=f13)
        for j in range(102):
            idx = field_of[j]
            changed = src and tapes[src][j] != r[j]
            c = colour[idx] if (changed or not src) else tuple(v // 4 for v in colour[idx])
            d.rectangle([x0 + j * cell, y + 2, x0 + j * cell + cell - 2, y + 16], fill=c)
        yy = y + 24
        for line in lines:
            x = x0
            for idx, text, tw in line:
                d.rectangle([x, yy + 1, x + 10, yy + 13], fill=colour[idx])
                d.text((x + 14, yy - 1), text, fill=K.TEXT, font=f13)
                x += tw + 6
            yy += 20
        if not lines:
            d.text((x0, yy - 1), 'JAMESON after the trades of 2: the source of every other tape', fill=K.TEXT,
                   font=f13)
        y += h
    out = os.path.join(E.CASE, 'docs', 'img', 'scenes', 'commanders.png')
    im.save(out)
    print(out, im.size)


if __name__ == '__main__':
    os.makedirs(os.path.join(E.CASE, 'docs', 'img', 'scenes'), exist_ok=True)
    for n in sys.argv[1:] or ['tape', 'commanders']:
        globals()[n]()
