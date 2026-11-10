#!/usr/bin/env python3
"""The figures of doc 05 (controls), drawn from the listing and from recordings read with TTD memory_at.

    python3 tools/fig_controls.py keyboard --out docs/img/controls/keyboard.png
    python3 tools/fig_controls.py bits --out docs/img/controls/bits.png
    python3 tools/fig_controls.py path --work W --trace T --from 14596 --to 14608 --out docs/img/controls/path.png
    python3 tools/fig_controls.py probe --work W --from 40 --to 146 --out docs/img/controls/probe.png
    python3 tools/fig_controls.py shield --work W --from 180 --to 300 --out docs/img/controls/shield.png

W is a work folder whose instance holds the recording (re_session.py session.json): `path` reads c1
(work/stage1/rec/c1/session.ttd) and its access trace T (`analysis trace` over 14600:0-14606:0); `probe` and
`shield` read probe-shield (work/docs/tjB/rec/probe-shield/session.ttd, recorded with tools/record.py from
work/stage1/rzx/at065000.szx and the input script work/docs/tjB/probe-shield.txt). A memory sample of frame N is the
memory at the start of frame N (TTD memory_at, tinframe 0), so it shows what the previous frame left.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)
COL = {'left': (40, 100, 200), 'right': (46, 140, 60), 'down': (225, 120, 20), 'up': (170, 50, 170),
       'fire': (200, 40, 40), 'menu': (90, 90, 100), 'pause': (0, 140, 150), 'weapon': (150, 110, 20)}

# the eight half rows: port high byte and the keys from bit 0 to bit 4
ROWS = {0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'], 0xFB: ['Q', 'W', 'E', 'R', 'T'],
        0xDF: ['P', 'O', 'I', 'U', 'Y'], 0xFD: ['A', 'S', 'D', 'F', 'G'], 0xBF: ['ENTER', 'L', 'K', 'J', 'H'],
        0xFE: ['CS', 'Z', 'X', 'C', 'V'], 0x7F: ['SPACE', 'SS', 'M', 'N', 'B']}
LAYOUT = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
          ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
          ['CS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SS', 'SPACE']]


def port_of(key):
    for row, keys in ROWS.items():
        if key in keys:
            return row, keys.index(key)
    raise KeyError(key)


def keyboard_uses():
    """(method, key) -> [(kind, text)] as ReadControls $7161, MenuPoll $893B, WeaponSelect $7976, Pause $793A read"""
    k = {}

    def use(method, keys, kind, text=None):
        for key in keys:
            k.setdefault((method, key), []).append((kind, text or kind))
    use('kbd', ['Z', 'C', 'M', 'B'], 'left')
    use('kbd', ['X', 'V', 'SS', 'N'], 'right')
    use('kbd', list('ASDFGHJKL'), 'down')
    use('kbd', list('QWERTYUIOP'), 'up')
    use('kbd', list('1234567890'), 'fire')
    use('cur', ['5'], 'left')
    use('cur', ['6'], 'down')
    use('cur', ['7'], 'up')
    use('cur', ['8'], 'right')
    use('cur', ['0'], 'fire')
    for m in ('kbd', 'cur'):
        use(m, ['SPACE', 'CS'], 'weapon', 'weapon')
        use(m, ['ENTER'], 'pause', 'pause')
        use(m, ['1'], 'menu', 'menu kbd')
        use(m, ['2'], 'menu', 'menu cursor')
        use(m, ['3'], 'menu', 'menu kempst.')
        use(m, ['0'], 'menu', 'menu start')
    return k


def draw_keyboard(d, uses, method, y0, title):
    f, fs, ft, fb = K.font(13), K.font(11), K.font(16), K.font(19)
    kw, kh, gap = 99, 96, 5
    d.text((14, y0), title, font=ft, fill=FG)
    y0 += 26
    for r, row in enumerate(LAYOUT):
        x0 = 14 + r * 12
        for c, key in enumerate(row):
            x, y = x0 + c * 98, y0 + r * (kh + gap)
            ks = uses.get((method, key), [])
            d.rectangle([x, y, x + kw - 6, y + kh], fill=(255, 255, 255) if ks else (236, 236, 236),
                        outline=FG if ks else GRID, width=2 if ks else 1)
            port, bit = port_of(key)
            d.text((x + 5, y + 3), key, font=fb if len(key) <= 2 else f, fill=FG if ks else DIM)
            d.text((x + 5, y + 26), f'${port:02X}FE b{bit}', font=fs, fill=DIM)
            for i, (kind, text) in enumerate(ks[:4]):
                d.rectangle([x + 4, y + 42 + i * 13, x + kw - 10, y + 54 + i * 13], fill=COL[kind])
                d.text((x + 7, y + 42 + i * 13), text, font=fs, fill=(255, 255, 255))
    return y0 + 4 * (kh + gap)


def fig_keyboard(out):
    uses = keyboard_uses()
    h = 2 * (30 + 4 * 101) + 280
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f = K.font(13)
    y = draw_keyboard(d, uses, 'kbd', 8, 'Method 1, keyboard (Controls $80): ReadControls $7178, eight IN, all '
                                         'letters and digits')
    y = draw_keyboard(d, uses, 'cur', y + 8, 'Method 2, cursor (Controls $40): ReadCursor $71E1, two IN, keys 5 6 '
                                             '7 8 and 0')
    y += 10
    lx = 14
    for kind in ('left', 'right', 'down', 'up', 'fire', 'weapon', 'pause', 'menu'):
        d.rectangle([lx, y + 2, lx + 16, y + 16], fill=COL[kind])
        d.text((lx + 22, y), kind, font=f, fill=FG)
        lx += 22 + d.textlength(kind, font=f) + 22
    notes = [
        'How to read: one box per key in the keyboard layout; the grey line is the half row (the port) and the bit',
        'that is 0 while the key is down. White keys are read in that method; grey keys are not. Method 1 makes the',
        'bottom row alternate (Z left, X right, C left, V right, B left, N right, M left, SS right); a whole row is',
        'down (A-L), up (Q-P) or fire (1-0): up reads Q-T and Y-P with one IN on port $DBFE, fire reads 1-5 and 6-0',
        'with one IN on port $E7FE. Method 3, Kempston (Controls $00): IN A,($1F), bits 0-4 right, left, down, up,',
        'fire as the interface gives them. SPACE or CAPS SHIFT (weapon: one IN on port $7EFE, bit 0 of both rows) and',
        'ENTER (pause, $BFFE b0) work in every method;',
        'the menu keys 1, 2, 3 and 0 are read by MenuPoll $893B on $F7FE and $EFFE.',
        'Drawn from the IN sites of build/game.lst: python3 tools/fig_controls.py keyboard --out '
        'docs/img/controls/keyboard.png']
    for i, line in enumerate(notes):
        d.text((14, y + 26 + i * 18), line, font=f, fill=FG if i < 8 else DIM)
    im.save(out)


def fig_bits(out):
    im = Image.new('RGB', (W, 560), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(17)
    rows = [
        ('Controls $63C2', 'written by ReadControls $7161 in every interrupt, read by MoveDroid, Fire, MoveShot3, '
                           'Pause', [
            ('7', 'method', 'keyboard ($80)', 'menu'), ('6', 'method', 'cursor ($40)', 'menu'),
            ('5', 'pause', 'paused, XOR $20', 'pause'), ('4', 'fire', 'fire held', 'fire'),
            ('3', 'up', '', 'up'), ('2', 'down', 'alone: shield', 'down'), ('1', 'left', '', 'left'),
            ('0', 'right', '', 'right')]),
        ('KeyLatches $6369', 'edge latches: a key must be released before it acts again', [
            ('7', 'lock', 'no moves, no fire', 'up'), ('6', 'fire lock', 'release fire first', 'fire'),
            ('5', '-', '', None), ('4', '-', '', None), ('3', '-', '', None), ('2', '-', '', None),
            ('1', 'ENTER', 'released (armed)', 'pause'), ('0', 'SPACE', 'released (armed)', 'weapon')]),
    ]
    y = 12
    for name, what, bits in rows:
        d.text((14, y), name, font=ft, fill=FG)
        d.text((190, y + 3), what, font=f, fill=DIM)
        y += 30
        for i, (b, short, long_, kind) in enumerate(bits):
            x = 14 + i * 127
            d.rectangle([x, y, x + 121, y + 86], fill=COL[kind] if kind else (236, 236, 236), outline=FG)
            fill = (255, 255, 255) if kind else DIM
            d.text((x + 6, y + 4), f'bit {b}', font=f, fill=fill)
            d.text((x + 6, y + 26), short, font=K.font(16), fill=fill)
            d.text((x + 6, y + 54), long_, font=fs, fill=fill)
        y += 104
    notes = [
        'Controls: ReadControls first keeps bits 7-5 (AND $E0), then sets bits 4-0 from the keys of the method in bits',
        '7-6, so the method and the pause flag survive each interrupt and the directions are fresh. Down alone (the low',
        'four bits = $04) is the shield in MoveDroid $7368; left and right together count as no key ($7306).',
        'KeyLatches: bit 6 is set when a straight shot ends ($8572) or the probe explodes ($8489) and cleared at $72FE',
        'when a MoveDroid pass sees fire up, so holding fire gives one shot. Bit 7 is set while the probe flies ($86B8)',
        'and during the death effect; MoveDroid then reads no keys. Bits 0 and 1 are the SPACE and ENTER release',
        'latches of WeaponSelect $7976 and Pause $793A.',
        'Drawn from build/game.lst: python3 tools/fig_controls.py bits --out docs/img/controls/bits.png']
    for i, line in enumerate(notes):
        d.text((14, y + i * 18), line, font=f, fill=FG if i < 7 else DIM)
    im.save(out)


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, addr, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                               'offset': addr, 'length': n, 'format': 'base64'}, ok=False)
    st = r.structured or {}
    if 'hex' not in st:
        raise SystemExit(f'memory_at {frame}: {r.text[:200]}')
    return bytes.fromhex(st['hex'])


def samples(work, a, b, step=1):
    s = session(work)
    out = []
    for fr in range(a, b + 1, step):
        m = mem(s, fr, 0x6359, 0x80)
        out.append((fr, {n: m[addr - 0x6359] for n, addr in VARS.items()}))
    return out


VARS = {'x': 0x6359, 'y': 0x635A, 'flags': 0x635B, 'frame': 0x635C, 'shot': 0x635E, 'sx': 0x635F, 'sy': 0x6360,
        'keylatch': 0x6369, 'energy': 0x636E, 'delay': 0x636F, 'reload': 0x6374, 'touch': 0x6377,
        'controls': 0x63C2, 'flagptr': 0x637E, 'timer': 0x6366}


def lanes(d, x0, x1, y, frames, rows, f, fs):
    """rows: [(label, values per frame, formatter)] drawn as value boxes per frame"""
    n = len(frames)
    cw = (x1 - x0) / n
    for i, fr in enumerate(frames):
        d.text((x0 + i * cw + 4, y), str(fr), font=fs, fill=DIM)
    y += 18
    for label, vals, fmt, colour in rows:
        d.text((14, y + 6), label, font=f, fill=FG)
        prev = None
        for i, v in enumerate(vals):
            x = x0 + i * cw
            changed = prev is not None and v != prev
            d.rectangle([x + 1, y, x + cw - 2, y + 26], fill=colour if changed else (255, 255, 255), outline=GRID)
            d.text((x + 5, y + 6), fmt(v), font=f, fill=(255, 255, 255) if changed else FG)
            prev = v
        y += 32
    return y


def fig_path(work, trace_path, a, b, out):
    data = samples(work, a, b)
    frames = [fr for fr, _ in data]
    im = Image.new('RGB', (W, 640), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), f'c1, X held: the key reaches Controls in the interrupt, the droid moves in a later pass '
                    f'(frames {a}-{b})', font=ft, fill=FG)
    rows = [('Controls $63C2', [v['controls'] for _, v in data], lambda v: f'{v:02X}', COL['right']),
            ('MoveDelay $636F', [v['delay'] for _, v in data], str, COL['menu']),
            ('DroidFlags $635B', [v['flags'] for _, v in data], lambda v: f'{v:02X}', COL['up']),
            ('DroidFrame $635C', [v['frame'] for _, v in data], str, COL['down']),
            ('x column $6359', [v['x'] for _, v in data], str, COL['left'])]
    y = lanes(d, 190, W - 14, 36, frames, rows, f, fs)
    # the trace: the moments that matter
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import access_trace  # noqa: E402
    t = access_trace.load(trace_path)
    events = []
    for x in t.instructions:
        for c in x.cycles:
            if c.tag == 'I' and x.pc == 0x717B and len(events) < 3:
                events.append((x.frame, x.t, f'IN A,(C) at $717B reads port ${c.address:04X} = ${c.value:02X} '
                                             f'(X is bit 2)'))
            if c.tag == 'W' and c.address == 0x63C2 and x.pc == 0x7187 and len(events) < 6:
                events.append((x.frame, x.t, f'SET 0,(HL) at $7187: Controls = ${c.value:02X} (right)'))
            if c.tag == 'W' and c.address == 0x636F and x.pc == 0x7214:
                events.append((x.frame, x.t, f'MoveDroid $7208: MoveDelay reloaded {c.value}, the step runs'))
            if c.tag == 'W' and c.address == 0x635C:
                events.append((x.frame, x.t, f'DroidFrame = {c.value} at ${x.pc:04X}'))
            if c.tag == 'W' and c.address == 0x6359:
                events.append((x.frame, x.t, f'x = {c.value} at ${x.pc:04X}'))
    y += 10
    d.text((14, y), f'From the access trace {os.path.basename(trace_path)} (frame : T in the frame of 69 888 T):',
           font=ft, fill=FG)
    y += 24
    seen = set()
    for fr, tt, text in events:
        if text in seen:
            continue
        seen.add(text)
        d.text((24, y), f'{fr}:{tt:5d}  {text}', font=f, fill=FG)
        y += 18
    notes = [
        'How to read: one column per frame; each box is the value at the start of that frame (TTD memory_at, T 0),',
        'coloured where it changed. The interrupt of frame 14600 writes Controls $81 at T 2048, so the sample of 14601',
        'is the first to show it. MoveDroid acts every second pass (MoveDelay 2): the pass of 14601 only counts down,',
        'the pass of 14603 starts the walk (MoveDroidMoving $7392 sets flags bit 3, frame 2 and x - 1, then',
        'MoveDroidWalkRight makes frame 3 and x + 1); the next acting pass makes frame 4 and column 10 (sample 14608).',
        'Key to the first changed picture: the new frame is queued in the pass of 14603, about 3 frames (60 ms).',
        f'python3 tools/fig_controls.py path --work W --trace T --from {a} --to {b} --out {out}']
    y += 8
    for i, line in enumerate(notes):
        d.text((14, y + i * 18), line, font=f, fill=FG if i < 6 else DIM)
    im = im.crop((0, 0, W, y + len(notes) * 18 + 10))
    im.save(out)


def fig_probe(work, a, b, out):
    s = session(work)
    m = mem(s, b, 0x4000, 6912)
    pts = []
    for fr in range(a, b + 1):
        v = mem(s, fr, 0x635E, 3)
        if v[0]:
            pts.append((fr, v[0], v[1], v[2]))
    scale = 3
    scr = K.render_screen(m, base=0).resize((256 * scale, 192 * scale), Image.NEAREST)
    im = Image.new('RGB', (W, 192 * scale + 230), BG)
    im.paste(scr, (14, 40))
    d = ImageDraw.Draw(im)
    f, ft = K.font(13), K.font(16)
    d.text((14, 8), f'probe-shield: the weapon 3 probe steered while fire is held (frames {a}-{b}, ShotPos $635F '
                    f'each frame)', font=ft, fill=FG)
    prev = None
    for fr, shot, px, py in pts:
        x, y = 14 + (px + 8) * scale, 40 + (py + 8) * scale
        if prev:
            d.line([prev, (x, y)], fill=(255, 60, 60), width=3)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 220, 60))
        prev = (x, y)
    # the legs
    legs, last = [], None
    for fr, shot, px, py in pts:
        dirn = None
        if last:
            dx, dy = px - last[1], py - last[2]
            dirn = 'left' if dx < 0 else 'right' if dx > 0 else 'up' if dy < 0 else 'down' if dy > 0 else None
        if dirn and (not legs or legs[-1][0] != dirn):
            legs.append([dirn, fr, fr, px, py])
        elif dirn:
            legs[-1][2:] = [fr, px, py]
        last = (fr, px, py)
    x0 = 14 + 256 * scale + 14
    y = 44
    d.text((x0, y), 'legs (frames, end x,y)', font=f, fill=FG)
    for dirn, f0, f1, px, py in legs:
        y += 20
        d.text((x0, y), f'{dirn:5} {f0}-{f1}  {px},{py}', font=f, fill=COL.get(dirn, FG))
    y += 30
    d.text((x0, y), f'{len(pts)} frames in flight', font=f, fill=FG)
    notes = [
        'How to read: the screen at the end of the window; the dots are the probe\'s pixel position (ShotPos $635F x,',
        f'$6360 y, offset by 8 to its centre) at the start of each frame from {a} to {b}, joined in time order. The input',
        'script holds fire with left, up, right and down in turn (work/docs/tjB/probe-shield.txt); each held direction',
        'moves the probe 2 pixels a pass where the cell ahead is free (MoveShot3 $82AA, CellSolidColumn/CellSolidRow),',
        'the droid stands still (KeyLatches bit 7). Fire is released at 136: MoveShot3Explode $8472, Shot $51 at 140.',
        f'python3 tools/fig_controls.py probe --work W --from {a} --to {b} --out {out}']
    y = 40 + 192 * scale + 12
    for i, line in enumerate(notes):
        d.text((14, y + i * 18), line, font=f, fill=FG if i < 5 else DIM)
    im.save(out)


def fig_shield(work, a, b, out):
    data = samples(work, a, b, 4)
    frames = [fr for fr, _ in data]
    im = Image.new('RGB', (W, 470), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(16)
    d.text((14, 8), f'probe-shield: down held alone raises the shield (frames {a}-{b}, every 4th frame)', font=ft,
           fill=FG)
    rows = [('Controls & $0F', [v['controls'] & 15 for _, v in data], lambda v: f'{v:02X}', COL['down']),
            ('Flags bit 4', [v['flags'] >> 4 & 1 for _, v in data], str, COL['up']),
            ('FlagPointer', [v['flagptr'] for _, v in data], lambda v: f'{v:02X}', COL['menu']),
            ('EnergyReload', [v['reload'] for _, v in data], str, COL['fire']),
            ('Energy $636E', [v['energy'] for _, v in data], lambda v: f'{v:02X}', COL['right'])]
    y = lanes(d, 150, W - 14, 36, frames, rows, f, fs)
    notes = [
        'How to read: each column is the start of a frame (TTD memory_at, T 0); a box is coloured where the value',
        'changed since the last column. Down alone (Controls low bits $04) takes MoveDroid to $7368: DroidFlags bit 4',
        'set, FlagPointer to 0 (the sprite list then writes the collision bit into ROM address 0, so touches are',
        'lost), EnergyReload 10 instead of 250, so the BCD energy drops a unit every 10 interrupts. HazardFlash $699B',
        'flashes the droid while bit 4 is set. Releasing down ($737F-$738C) restores the flag pointer and 250.',
        f'python3 tools/fig_controls.py shield --work W --from {a} --to {b} --out {out}']
    y += 10
    for i, line in enumerate(notes):
        d.text((14, y + i * 18), line, font=f, fill=FG if i < 5 else DIM)
    im = im.crop((0, 0, W, y + len(notes) * 18 + 10))
    im.save(out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['keyboard', 'bits', 'path', 'probe', 'shield'])
    p.add_argument('--work')
    p.add_argument('--trace')
    p.add_argument('--from', dest='a', type=int)
    p.add_argument('--to', dest='b', type=int)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.what == 'keyboard':
        fig_keyboard(args.out)
    elif args.what == 'bits':
        fig_bits(args.out)
    elif args.what == 'path':
        fig_path(args.work, args.trace, args.a, args.b, args.out)
    elif args.what == 'probe':
        fig_probe(args.work, args.a, args.b, args.out)
    else:
        fig_shield(args.work, args.a, args.b, args.out)


if __name__ == '__main__':
    main()
