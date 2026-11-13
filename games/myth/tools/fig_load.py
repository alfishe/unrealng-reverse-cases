#!/usr/bin/env python3
"""Doc 03's figures: the tape in time and in memory, the BASIC line, the chain's layers, the bit timing.

    python3 tools/fig_load.py tape docs/img/load/tape.png
    python3 tools/fig_load.py basic docs/img/load/basic-line.png
    python3 tools/fig_load.py chain LAYERS.txt docs/img/load/chain.png
    python3 tools/fig_load.py bits docs/img/load/bit-timing.png

tape: the blocks of work/stage1/media/myth.tzx (read by tools/tzxblocks.py list) as time bands, the first two minutes
magnified, and where each block lands in memory.

basic: the 59 bytes of line 0 (build/basic.lst: BasicLine0 up to CopyChain), the tokens over them, the hidden number.

chain: the output of `tools/speedlock.py layers` (one row a layer: its loop's address, its kind, the bytes it
rewrites): each layer a bar from its loop to $FF25, coloured by its kind.

bits: one bit of the data stream read by BitRead, a zero (714 T a half) and a one (1428 T a half), with the time the
code does not poll (counted from the instructions in src/loader/reader.asm and reveal.asm) and the polls of EdgeWait
(54 T each) that count B up from $B2 to the threshold $D0.
"""
import re
import subprocess
import sys

from figmyth import P, W, F, TEXT, DIM, HI, PANEL, canvas, save

KIND_COLOUR = {'standard': (110, 180, 110), 'speedlock': (220, 130, 60), 'mark': (240, 220, 90),
               'turbo': (90, 140, 220), 'pause': (60, 60, 72), 'tone': (200, 100, 100)}


def tzx_blocks():
    """[(index, kind, seconds, pause seconds, text)] of the original tape."""
    out = subprocess.run([sys.executable, P('tools', 'tzxblocks.py'), 'list', P('work', 'stage1', 'media', 'myth.tzx')],
                         capture_output=True, text=True, check=True).stdout
    blocks = []
    for line in out.splitlines():
        m = re.match(r'\s*(\d+) @\s*\d+ id (\w+) (\w+)', line)
        if not m:
            continue
        idx, bid = int(m.group(1)), m.group(2)
        secs = re.search(r'\| ([\d.]+) s$', line)
        pause = re.search(r'pause (\d+) ms', line)
        secs = float(secs.group(1)) if secs else 0.0
        pause = int(pause.group(1)) / 1000 if pause else 0.0
        if bid == '10':
            kind = 'standard'
        elif bid in ('12', '13'):
            kind = 'tone'
        elif bid == '14':
            kind = 'mark' if 'len 3 |' in line and 'flag 07' in line else 'speedlock'
        elif bid == '11':
            kind = 'turbo'
        else:
            continue
        blocks.append((idx, kind, secs, pause, line))
    return blocks


def tape(out):
    blocks = tzx_blocks()
    im, d, y = canvas(820, 'The tape of Myth in time and in memory',
                      'Top: the whole tape (815.9 s with the pauses). Middle: its first 160 s magnified, the '
                      'loader\'s parts named.\nBottom: where the blocks land; the last rows are what the '
                      'loader moves and what the turbo loader puts over $6C3F.')
    x0, x1 = 60, W - 20

    def band(y, t_lo, t_hi, h, labels):
        px = lambda t: x0 + (t - t_lo) * (x1 - x0) / (t_hi - t_lo)  # noqa: E731
        d.rectangle((x0, y, x1, y + h), fill=PANEL)
        t = 0.0
        for idx, kind, secs, pause, line in blocks:
            a, b = t, t + secs
            if b > t_lo and a < t_hi:
                d.rectangle((max(px(a), x0), y, min(max(px(b), px(a) + 1), x1), y + h), fill=KIND_COLOUR[kind])
            t = b + pause
        step = 60 if t_hi - t_lo > 300 else 10
        s = int(t_lo // step * step)
        while s <= t_hi:
            if s >= t_lo:
                d.line((px(s), y + h, px(s), y + h + 4), fill=DIM)
                d.text((px(s) - 8, y + h + 6), '%d s' % s, font=F(13), fill=DIM)
            s += step
        for t_at, text, row in labels:
            if t_lo <= t_at <= t_hi:
                tx = min(px(t_at) + 2, x1 - d.textlength(text, font=F(13)))
                d.text((tx, y - 18 - 18 * row), text, font=F(13), fill=TEXT)
                d.line((px(t_at), y - 4 - 18 * row, px(t_at), y), fill=TEXT)
        return px

    # the start times of the parts
    t, starts = 0.0, {}
    for idx, kind, secs, pause, line in blocks:
        starts[idx] = t
        t += secs + pause
    whole = [(starts[1], 'BASIC', 0), (starts[37], 'front', 0), (starts[40], 'stage 1', 0), (starts[43], 'stage 2', 0),
             (starts[46], 'stage 3', 0), (starts[49], 'stage 4', 0), (starts[52], 'stage 5', 0)]
    y += 22
    band(y, 0, t, 34, whole)
    y += 128
    near = [(starts[1], 'header', 0), (starts[2], 'BASIC 4514 bytes', 1), (starts[4], 'SpeedLock group 1', 0),
            (starts[13], 'screen bitmap 6144', 1), (starts[15], 'attributes', 0), (starts[17], 'resident, keys, table',
                                                                                    1),
            (starts[27], 'Unxor, Boot', 2), (starts[37], 'front (turbo)', 0)]
    px = band(y, 0, 160, 44, near)
    yy = y + 70
    # legend
    yy += 46
    lx = 60
    for kind, text in (('standard', 'ROM speed'), ('tone', 'pilot tone, sync'), ('speedlock', 'SpeedLock data'),
                       ('mark', 'mark 07 FF 00'), ('turbo', 'turbo data')):
        d.rectangle((lx, yy + 3, lx + 14, yy + 15), fill=KIND_COLOUR[kind])
        d.text((lx + 20, yy), text, font=F(13), fill=TEXT)
        lx += 40 + d.textlength(text, font=F(13))
    # memory
    yy += 40
    d.text((16, yy), 'Where each block lands ($0000-$FFFF; the time order top down)', font=F(15), fill=TEXT)
    yy += 26
    ax = lambda a: x0 + a * (x1 - x0) / 0x10000  # noqa: E731
    rows = [
        ('BASIC', [(0x5CCB, 0x6E6C, 'standard', '$5CCB BASIC')]),
        ('chain', [(0xEDE4, 0xFF25, 'standard', '$EDE4 the chain (CopyChain)')]),
        ('group 1', [(0xFF26, 0xFFCF, 'speedlock', '$FF26 second stage')]),
        ('group 2', [(0x4000, 0x57FF, 'speedlock', '$4000 bitmap'), (0x8000, 0x82FF, 'speedlock', '$8000 attributes'),
                     (0xDB80, 0xEB7F, 'speedlock', '$DB80 resident, XORed')]),
        ('group 2', [(0x5B00, 0x5B2E, 'speedlock', '$5B00 Boot'), (0xFDB5, 0xFDB6, 'mark', ''),
                     (0xFDE9, 0xFDEC, 'mark', ''), (0xFE76, 0xFEE8, 'speedlock', ''), (0xFF3A, 0xFF48, 'mark', ''),
                     (0xFF49, 0xFF7F, 'mark', 'keys $FDB5 $FDE9, Unxor $FE76, Sl1End $FF3A, table $FF49')]),
        ('Boot', [(0xE000, 0xFFFF, 'tone', '$CB80-$EB7F to $E000-$FFFF')]),
        ('front', [(0x6C3F, 0xA83E, 'turbo', '$6C3F the front, 15 360 bytes')]),
        ('stage', [(0x6C3F, 0xF03E, 'turbo', '$6C3F a stage, 33 792 bytes')]),
    ]
    for name, spans in rows:
        d.rectangle((x0, yy, x1, yy + 22), fill=PANEL)
        d.text((8, yy + 3), name, font=F(13), fill=DIM)
        lane_end = x0 - 10
        for a, b, kind, text in spans:
            d.rectangle((ax(a), yy, max(ax(b + 1), ax(a) + 3), yy + 22), fill=KIND_COLOUR[kind])
        for a, b, kind, text in spans:
            if not text:
                continue
            tw = d.textlength(text, font=F(13))
            tx = ax(a) + 3
            if len(spans) > 2 and kind == 'mark':
                tx = ax(spans[1][0]) - tw - 6
            elif tx + tw > x1:
                tx = ax(a) - tw - 4
            if tx < lane_end:
                tx = lane_end
            inside = ax(a) <= tx and tx + tw <= max(ax(b + 1), ax(a) + 3)
            d.text((tx, yy + 3), text, font=F(13), fill=(15, 15, 20) if inside else TEXT)
            lane_end = tx + tw + 8
        yy += 28
    for a in range(0, 0x10001, 0x2000):
        d.line((ax(a), yy, ax(a), yy + 4), fill=DIM)
        d.text((ax(a) - 20, yy + 6), '$%04X' % min(a, 0xFFFF), font=F(13), fill=DIM)
    im = im.crop((0, 0, W, yy + 30))
    save(im, out)


def basic(out):
    raw = open(P('build', 'basic.bin'), 'rb').read()[:59]
    data = [(0x5CCB + k, v) for k, v in enumerate(raw)]
    groups = [(0, 2, 'line 0'), (2, 4, 'length 55'), (4, 8, 'INK 0 PAPER 0'), (8, 10, 'RANDOMIZE USR'),
              (10, 12, '( ('), (12, 13, 'PEEK'), (13, 18, '"23635"'), (18, 24, '$0E + 23635'), (24, 25, '+'),
              (25, 28, '"256"'), (28, 34, '$0E + 256'), (34, 35, '*'), (35, 36, 'PEEK'), (36, 41, '"23636"'),
              (41, 47, '$0E + 23636'), (47, 48, ')'), (48, 49, '+'), (49, 51, '"10"'), (51, 52, '$0E'),
              (52, 57, 'hidden: 59'), (57, 58, ')'), (58, 59, '$0D')]
    per = 15
    cw, ch = 64, 42
    nrows = (len(data) + per - 1) // per
    im, d, y = canvas(140 + nrows * (ch + 46) + 40, 'Line 0 of the BASIC: what LIST would show, what the ROM adds',
                      'The 59 bytes at PROG $5CCB (build/basic.bin). Every number in a line is its digits, $0E and '
                      'five bytes the interpreter really uses.\nThe digits 10 carry the number 59: USR enters '
                      'PROG + 59 = $5D06, the first byte after the line, CopyChain.')
    hidden = range(52, 57)
    x0 = 30
    tags = {}
    for gi, (a, b, text) in enumerate(groups):
        for k in range(a, b):
            tags[k] = gi
    for i, (addr, val) in enumerate(data):
        r, c = divmod(i, per)
        x, yy = x0 + c * cw, y + 10 + r * (ch + 46)
        gi = tags.get(i, 0)
        fill = (120, 60, 40) if i in hidden else ((48, 54, 76) if gi % 2 == 0 else (40, 64, 56))
        d.rectangle((x, yy, x + cw - 4, yy + ch), fill=fill, outline=HI if i in hidden else None)
        d.text((x + 16, yy + 3), '%02X' % val, font=F(17), fill=TEXT)
        d.text((x + 10, yy + ch - 18), '$%04X' % addr, font=F(13), fill=DIM)
    # group labels under their first cell in each row
    for gi, (a, b, text) in enumerate(groups):
        r, c = divmod(a, per)
        x, yy = x0 + c * cw, y + 10 + r * (ch + 46) + ch + 4
        lane = gi % 2
        d.text((x, yy + 16 * lane), text, font=F(13), fill=HI if 'hidden' in text else DIM)
    yy = y + 10 + nrows * (ch + 46) + 10
    d.text((x0, yy), 'Shown:   RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10)', font=F(15), fill=TEXT)
    d.text((x0, yy + 22), 'Run:     RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+59) = USR $5D06', font=F(15), fill=HI)
    save(im, out)


KIND = {'add': (220, 130, 60), 'sub': (90, 140, 220), 'xor': (110, 180, 110), 'dec': (240, 220, 90)}


def chain(layers, out):
    rows = []
    for line in open(layers):
        m = re.match(r'\s*(\d+) \$([0-9A-F]{4}) (\w+)\s+(\d+) bytes', line)
        if m:
            rows.append((int(m.group(1)), int(m.group(2), 16), m.group(3), int(m.group(4))))
    rh = 5
    head = 96
    im, d, y = canvas(head + len(rows) * rh + 110, 'The 103 layers of the decryption chain over $EDE4-$FF25',
                      'One row a layer, top down in the order they run: a bar from the layer\'s first rewritten byte '
                      'to $FF25.\nEach layer starts where the one before ends; right of the yellow line is the loader, '
                      'rewritten 103 times.\nThe colour is how the layer rewrites a byte c into p.')
    lo, hi = 0xEDE4, 0xFF26
    x0, x1 = 80, W - 30
    px = lambda a: x0 + (a - lo) * (x1 - x0) / (hi - lo)  # noqa: E731
    y += 6
    for n, loop, kind, count in rows:
        start = 0xFF26 - count
        yy = y + n * rh
        d.rectangle((px(start), yy, x1, yy + rh - 2), fill=KIND[kind])
        if n % 10 == 0:
            d.text((20, yy - 6), 'layer %d' % n, font=F(13), fill=DIM)
    yb = y + len(rows) * rh + 6
    for a in (0xEDE4, 0xF000, 0xF400, 0xF800, 0xFBD4, 0xFF25):
        d.line((px(a), yb, px(a), yb + 4), fill=DIM)
        tx = px(a) - 20 if a != 0xFF25 else px(a) - 44
        d.text((tx, yb + 6), '$%04X' % a, font=F(13), fill=DIM)
    d.line((px(0xFBD4), y, px(0xFBD4), yb), fill=HI)
    d.text((px(0xFBD4) + 6, y + 30), 'LoaderStart $FBD4:', font=F(13), fill=(15, 15, 20))
    d.text((px(0xFBD4) + 6, y + 48), 'the loader', font=F(13), fill=(15, 15, 20))
    yy = yb + 34
    lx = x0
    counts = {}
    for r in rows:
        counts[r[2]] = counts.get(r[2], 0) + 1
    for kind, text in (('add', 'p = post(key + c)'), ('sub', 'p = post(key - c)'), ('xor', 'p = key XOR c'),
                       ('dec', 'p = c - 1')):
        n = counts.get(kind, 0)
        label = '%s: %d layer%s' % (text, n, '' if n == 1 else 's')
        d.rectangle((lx, yy + 3, lx + 14, yy + 15), fill=KIND[kind])
        d.text((lx + 20, yy), label, font=F(13), fill=TEXT)
        lx += 50 + d.textlength(label, font=F(13))
    save(im, out)


def bits(out):
    """Two bits as BitRead sees them; the dead times are counted from the code (see the module's docstring)."""
    poll = 54
    dead1, dead2 = 288, 332        # after the edge before the bit; after the first edge (the reveal task)
    im, d, y = canvas(560, 'One bit of the SpeedLock stream: what BitRead counts',
                      'B starts at $B2 at each bit. The code does not poll for 288 T after the edge before the bit, '
                      'nor for 332 T\nafter the middle edge (the task). In the rest each 54 T poll of EdgeWait adds 1 '
                      'to B.\nThe bit is 1 when B ends above $D0. T-states counted from the code, without contention.')
    x0, x1 = 120, W - 30
    tmax = 2 * 1428 + 700
    px = lambda t: x0 + t * (x1 - x0) / tmax  # noqa: E731
    y += 20
    ends = []
    for half, name in ((714, 'a zero: 714 T + 714 T'), (1428, 'a one: 1428 T + 1428 T')):
        d.text((16, y), name.split(':')[0], font=F(15), fill=TEXT)
        d.text((x0, y), name.split(': ')[1], font=F(13), fill=DIM)
        yw = y + 26
        # the waveform: low half, then high half
        lvl = [(0, half, 1), (half, 2 * half, 0)]
        for a, b, high in lvl:
            yy = yw + (0 if high else 30)
            d.line((px(a), yy, px(b), yy), fill=TEXT, width=2)
        for t in (0, half, 2 * half):
            d.line((px(t), yw, px(t), yw + 30), fill=TEXT, width=2)
        # the dead and polled parts, as a strip below
        ys = yw + 44
        polls = 0
        for a, dead, b in ((0, dead1, half), (half, dead2, 2 * half)):
            d.rectangle((px(a), ys, px(a + dead), ys + 18), fill=(80, 60, 60))
            t = a + dead
            while t + poll <= b:
                d.rectangle((px(t) + 1, ys, px(t + poll) - 1, ys + 18), fill=(70, 120, 90))
                t += poll
                polls += 1
            # the last poll catches the edge
            d.rectangle((px(t) + 1, ys, px(min(t + poll, b + poll)) - 1, ys + 18), fill=(120, 170, 120))
            polls += 1
        b_end = 0xB2 + polls
        ends.append(b_end)
        d.text((px(2 * half) + 40, ys - 20), '%d polls' % polls, font=F(15), fill=TEXT)
        d.text((px(2 * half) + 40, ys), 'B = $%02X: %s' % (b_end, 'bit 1' if b_end > 0xD0 else 'bit 0'), font=F(15),
               fill=HI)
        y = ys + 60
    # the threshold line on a B scale
    yb = y + 10
    d.text((16, yb), 'B', font=F(15), fill=TEXT)
    bx = lambda b: x0 + (b - 0xB2) * (x1 - x0) / (0xE0 - 0xB2)  # noqa: E731
    d.rectangle((x0, yb, x1, yb + 18), fill=PANEL)
    zero_b, one_b = ends
    for b, text in ((0xB2, '$B2 start'), (zero_b, '$%02X a zero' % zero_b), (0xD0, '$D0 threshold'),
                    (one_b, '$%02X a one' % one_b)):
        d.line((bx(b), yb - 4, bx(b), yb + 22), fill=HI if b == 0xD0 else TEXT, width=2)
        d.text((bx(b) - 30, yb + 26), text, font=F(13), fill=HI if b == 0xD0 else TEXT)
    yy = yb + 60
    for colour, text in (((80, 60, 60), 'no polling: the return, the threshold test, EdgeDelay (A = 9), the task'),
                         ((70, 120, 90), 'one poll of EdgeWaitLoop: INC B, RET Z, LD A, IN, RRA, XOR C, AND, JR Z = 54 T'),
                         ((120, 170, 120), 'the poll that sees the edge')):
        d.rectangle((x0, yy + 3, x0 + 14, yy + 15), fill=colour)
        d.text((x0 + 20, yy), text, font=F(13), fill=TEXT)
        yy += 20
    im = im.crop((0, 0, W, yy + 10))
    save(im, out)


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'tape':
        tape(sys.argv[2])
    elif cmd == 'basic':
        basic(sys.argv[2])
    elif cmd == 'chain':
        chain(sys.argv[2], sys.argv[3])
    elif cmd == 'bits':
        bits(sys.argv[2])
    else:
        raise SystemExit(__doc__)
