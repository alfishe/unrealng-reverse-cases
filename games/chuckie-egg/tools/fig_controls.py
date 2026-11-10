#!/usr/bin/env python3
"""The figures of doc 05 (controls), drawn from the image and from recordings read with TTD memory_at.

    python3 tools/fig_controls.py keyboard --out docs/img/controls/keyboard.png
    python3 tools/fig_controls.py keysets  --out docs/img/controls/keysets.png
    python3 tools/fig_controls.py path --work W --from 990 --to 1260 --out docs/img/controls/path.png
    python3 tools/fig_controls.py hold --work W --from 1060 --to 1440 --out docs/img/controls/hold.png
    python3 tools/fig_controls.py redefine --work W --frames 140,200,400 --out docs/img/controls/redefine-odd.png

W is a work folder whose instance holds the recording (re_session.py session.json): `path` reads tour-type2
(work/stage1/rec/tour-type2/session.ttd), `hold` reads hold-abort (work/docs/ceB/rec/hold-abort/session.ttd),
`redefine` reads redefine-odd (work/docs/ceB/rec/redefine-odd/session.ttd). The
image is build/game.bin (`sh tools/build.sh`), the game block `$8214-$CBE7`. A memory sample of frame N is the
memory at the start of frame N (TTD memory_at, tinframe 0).
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

GAME = os.path.join(CASE, 'build', 'game.bin')
ORG = 0x8214
W = 1050
BG, FG, DIM, GRID = (250, 250, 247), (20, 20, 24), (105, 105, 115), (205, 205, 210)

# the eight half rows: port high byte and the keys from bit 0 to bit 4
ROWS = {0xF7: ['1', '2', '3', '4', '5'], 0xEF: ['0', '9', '8', '7', '6'], 0xFB: ['Q', 'W', 'E', 'R', 'T'],
        0xDF: ['P', 'O', 'I', 'U', 'Y'], 0xFD: ['A', 'S', 'D', 'F', 'G'], 0xBF: ['ENTER', 'L', 'K', 'J', 'H'],
        0xFE: ['CS', 'Z', 'X', 'C', 'V'], 0x7F: ['SPACE', 'SS', 'M', 'N', 'B']}
LAYOUT = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'], ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
          ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'], ['CS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SS',
                                                                    'SPACE']]
COL = {'t1': (46, 140, 60), 't2': (40, 100, 200), 't3': (225, 120, 20), 'menu': (170, 50, 170),
       'hold': (200, 40, 40)}
DIRS = ['up', 'down', 'left', 'right', 'jump', 'jump']


def game():
    return open(GAME, 'rb').read()


def key_of(mask, row):
    """the key named by a (mask, port row) pair: the first clear bit of the mask in that row"""
    for bit in range(5):
        if not mask >> bit & 1:
            return ROWS[row][bit], bit
    return '?', None


def key_sets(img):
    out = []
    for n in range(3):
        base = 0x8250 + 12 * n - ORG
        out.append([(img[base + 2 * i], img[base + 2 * i + 1]) for i in range(6)])
    return out


def port_of(key):
    for row, keys in ROWS.items():
        if key in keys:
            return row, keys.index(key)
    raise KeyError(key)


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    return re_session.session_of(work)[0]


def mem(s, frame, addr, n):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                               'offset': addr, 'length': n}, ok=False)
    st = r.structured or {}
    if 'hex' not in st:
        raise SystemExit(f'memory_at {frame}: {r.text[:200]}')
    return bytes.fromhex(st['hex'])


def script_keys(path, a, b):
    """[(frame, keys)] of an input script between frames a and b (each line holds its keys until the next)"""
    events = []
    for raw in open(path):
        line = raw.split('#', 1)[0].strip()
        if not line:
            continue
        f, *k = line.split()
        if k == ['END']:
            break
        events.append((int(f), [] if k == ['-'] else k))
    spans = []
    for i, (f, k) in enumerate(events):
        end = events[i + 1][0] if i + 1 < len(events) else b
        if k and end > a and f < b:
            spans.append((max(f, a), min(end, b), k))
    return spans


# ---------------------------------------------------------------------------------------------------------------------

def fig_keyboard(out):
    img = game()
    sets = key_sets(img)
    uses = {}

    def use(key, kind, text):
        uses.setdefault(key, []).append((kind, text))
    for n, kind in enumerate(('t1', 't2', 't3')):
        for i, (m, r) in enumerate(sets[n]):
            k, _ = key_of(m, r)
            use(k, kind, f'{n + 1} {DIRS[i]}')
    for k, t in (('S', 'start'), ('R', 'redefine'), ('I', 'instr.')):
        use(k, 'menu', t)
    for k in ('1', '2', '3'):
        use(k, 'menu', 'key type')
    for k in ('1', '2', '3', '4'):
        use(k, 'menu', 'players')
    use('CS', 'hold', 'HOLD/ABORT')
    use('H', 'hold', 'HOLD')
    use('A', 'hold', 'ABORT')
    use('S', 'hold', 'resume')
    use('ENTER', 'menu', 'name end')
    kw, kh, gap = 99, 112, 5
    h = 70 + 4 * (kh + gap) + 250
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft, fb = K.font(13), K.font(11), K.font(17), K.font(20)
    d.text((14, 10), 'The keys Chuckie Egg reads, all on port $FE: each key with its half row, its bit and its uses',
           font=ft, fill=FG)
    y0 = 46
    for r, row in enumerate(LAYOUT):
        x0 = 14 + r * 12
        for c, key in enumerate(row):
            x, y = x0 + c * 98, y0 + r * (kh + gap)
            ks = uses.get(key, [])
            d.rectangle([x, y, x + kw - 6, y + kh], fill=(255, 255, 255) if ks else (236, 236, 236),
                        outline=FG if ks else GRID, width=2 if ks else 1)
            port, bit = port_of(key)
            d.text((x + 5, y + 3), key, font=fb if len(key) <= 2 else f, fill=FG if ks else DIM)
            d.text((x + 5, y + 27), f'${port:02X}FE b{bit}', font=fs, fill=DIM)
            for i, (kind, text) in enumerate(ks[:5]):
                d.rectangle([x + 4, y + 43 + i * 13, x + kw - 10, y + 55 + i * 13], fill=COL[kind])
                d.text((x + 7, y + 43 + i * 13), text, font=fs, fill=(255, 255, 255))
    y = y0 + 4 * (kh + gap) + 12
    lx = 14
    for kind, text in (('t1', 'key type 1 ($8250)'), ('t2', 'key type 2 ($825C)'),
                       ('t3', 'key type 3 ($8268, as loaded)'), ('menu', 'menus, name entry'),
                       ('hold', 'HOLD, ABORT')):
        d.rectangle([lx, y + 2, lx + 16, y + 16], fill=COL[kind])
        d.text((lx + 22, y), text, font=f, fill=FG)
        lx += 22 + d.textlength(text, font=f) + 18
    notes = [
        'How to read: one box per key in the keyboard\'s layout; the grey line is the port read (IN A,($FE) with the',
        'high byte in A) and the bit that is 0 while the key is down. White keys are read somewhere; grey keys are not.',
        'Coloured tags name each use: "1 up" is the up key of key type 1; the menu tags are the title (S, R, I), the',
        'instructions page (1, 2, 3 for the key type, S, R), the players prompt (1-4) and the name entry (ENTER;',
        'the letters come from the ROM there, every key works). HOLD is CAPS SHIFT + H, then S resumes; ABORT is',
        'CAPS SHIFT + A. The point: 22 IN instructions, every one on port $FE; no Kempston port $1F, no IN r,(C).',
        'Drawn from KeySets $8250 in build/game.bin and the IN sites of build/game.lst: python3 tools/fig_controls.py',
        'keyboard --out docs/img/controls/keyboard.png']
    for i, line in enumerate(notes):
        d.text((14, y + 30 + i * 18), line, font=f, fill=FG if i < 6 else DIM)
    im.save(out)


def fig_keysets(out):
    img = game()
    sets = key_sets(img)
    h = 560
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(17)
    d.text((14, 10), 'KeySets $8250: three sets of six (mask, port row) pairs, decoded bit by bit', font=ft, fill=FG)
    names = ['type 1 $8250 (KeyType 6)', 'type 2 $825C (KeyType 5)', 'type 3 $8268 (KeyType 3, redefinable)']
    y = 44
    cw = 168
    for n in range(3):
        d.text((14, y), names[n], font=K.font(15), fill=COL[('t1', 't2', 't3')[n]])
        y += 22
        for i, (m, r) in enumerate(sets[n]):
            x = 14 + i * (cw + 4)
            key, bit = key_of(m, r)
            a = 0x8250 + 12 * n + 2 * i
            d.rectangle([x, y, x + cw, y + 92], fill=(255, 255, 255), outline=GRID)
            d.text((x + 5, y + 3), f'${a:04X}: {m:02X} {r:02X}', font=f, fill=FG)
            d.text((x + 5, y + 20), f'{DIRS[i]}: key {key}', font=f, fill=FG)
            for b in range(5):
                bx = x + 6 + (4 - b) * 31
                clear = not m >> b & 1
                d.rectangle([bx, y + 42, bx + 28, y + 62], fill=COL[('t1', 't2', 't3')[n]] if clear else (238, 238,
                                                                                                        238),
                            outline=FG)
                d.text((bx + 9, y + 44), '0' if clear else '1', font=f, fill=(255, 255, 255) if clear else DIM)
                d.text((bx + 3, y + 64), ROWS[r][b][:4], font=fs, fill=FG if clear else DIM)
            d.text((x + 5, y + 77), f'row ${r:02X}FE, bit {bit}', font=fs, fill=DIM)
        y += 104
    notes = ['How to read: each box is one pair of the set, at its address: the mask byte, then the port row (the high',
             'byte of the port). The five boxes are the mask\'s bits 4 to 0 under the keys of that half row; the',
             'coloured 0 is the key. A key is down when ((IN row x 256 + $FE) AND $1F) OR mask is not $1F: only the',
             'mask\'s 0 bit can pull the result below $1F. SetupLevel $AE9C copies one set into KeyTable $732E (CP 5:',
             '5 takes type 2, below 5 type 3, above 5 type 1). The point: the table is the controls; a redefinition',
             'writes new pairs into set 3 and nothing else changes. python3 tools/fig_controls.py keysets --out',
             'docs/img/controls/keysets.png (from build/game.bin)']
    for i, line in enumerate(notes):
        d.text((14, y + i * 18), line, font=f, fill=FG if i < 5 else DIM)
    im.save(out)


def chart_axes(d, x0, y0, w, h, a, b, lo, hi, label, f, ticks=None):
    d.rectangle([x0, y0, x0 + w, y0 + h], outline=GRID)
    d.text((x0 + 6, y0 + 2), label, font=f, fill=FG)
    for v in ticks or (lo, hi):
        yy = y0 + h - (v - lo) / (hi - lo) * h
        d.line([x0 - 3, yy, x0, yy], fill=FG)
        d.text((x0 - 6 - d.textlength(str(v), font=K.font(11)), yy - 7), str(v), font=K.font(11), fill=DIM)

    def X(fr):
        return x0 + (fr - a) / (b - a) * w

    def Y(v):
        return y0 + h - (v - lo) / (hi - lo) * h
    return X, Y


def fig_path(work, a, b, out):
    s = session(work)
    rows = []
    for fr in range(a, b + 1):
        m = mem(s, fr, 0x72D8, 0x7330 - 0x72D8)
        rows.append((fr, m[0], m[1], m[3], m[0x7325 - 0x72D8]))
    spans = script_keys(os.path.join(CASE, 'tests', 'inputs', 'tour-type2.txt'), a, b)
    h = 640
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(17)
    d.text((14, 10), f'From the key to Harry: tour-type2 frames {a}-{b}, key type 2 (8 right, 5 left, 4 jump)',
           font=ft, fill=FG)
    x0, w = 60, W - 90
    X, _ = chart_axes(d, x0, 46, w, 40, a, b, 0, 1, 'keys', f, ticks=[])
    kc = {'8': (40, 100, 200), '5': (225, 120, 20), '4': (200, 40, 40)}
    for s0, s1, k in spans:
        for j, key in enumerate(k):
            yy = 50 + j * 16
            d.rectangle([X(s0), yy, X(s1), yy + 13], fill=kc.get(key, DIM))
            d.text((X(s0) + 3, yy - 1), key, font=fs, fill=(255, 255, 255))
    xs = [r[1] for r in rows]
    X, Y = chart_axes(d, x0, 104, w, 170, a, b, 60, 160, 'HarryX', f, ticks=[60, 80, 100, 120, 140, 160])
    d.line([(X(r[0]), Y(r[1])) for r in rows], fill=(40, 100, 200), width=2)
    X, Y = chart_axes(d, x0, 292, w, 110, a, b, 20, 36, 'HarryY', f, ticks=[20, 23, 28, 34])
    d.line([(X(r[0]), Y(r[2])) for r in rows], fill=(46, 140, 60), width=2)
    X, Y = chart_axes(d, x0, 420, w, 50, a, b, 0, 2, 'JumpState', f, ticks=[0, 2])
    d.line([(X(r[0]), Y(r[4])) for r in rows], fill=(200, 40, 40), width=2)
    for t in range(a - a % 50 + 50, b + 1, 50):
        d.line([X(t), 470, X(t), 476], fill=FG)
        d.text((X(t) - 14, 478), str(t), font=fs, fill=DIM)
    d.text((x0 + w / 2 - 20, 494), 'frame', font=f, fill=DIM)
    first = {}
    for r0, r1 in zip(rows, rows[1:]):
        if r1[1] != r0[1] and 'x' not in first:
            first['x'] = r1[0]
    notes = ['How to read: the top lane is the input script (each bar a key held); below, HarryX, HarryY and JumpState',
             'sampled at the start of each frame (TTD memory_at). The walk is one pixel per slow tick, about 1.2 a',
             'frame; a jump climbs 11 pixels and falls back over 38 frames; 5 + 4 at 1200 jumps to the left.',
             'The point: the keys are read only in the slow tick (every 130 passes), straight from port $FE; nothing',
             'buffers them, so a key acts within the frame it is pressed in and stops the tick it is released.',
             f'python3 tools/fig_controls.py path --work W --from {a} --to {b} --out docs/img/controls/path.png',
             '(W holds work/stage1/rec/tour-type2/session.ttd)']
    for i, line in enumerate(notes):
        d.text((14, 520 + i * 17), line, font=f, fill=FG if i < 5 else DIM)
    im.save(out)


def fig_hold(work, a, b, out):
    s = session(work)
    rows = []
    for fr in range(a, b + 1):
        m = mem(s, fr, 0x72D8, 0x7348 - 0x72D8)
        t = m[0x7342 - 0x72D8:0x7345 - 0x72D8]
        tv = t[0] * 100 + t[1] * 10 + t[2] if max(t) <= 9 else None
        rows.append((fr, m[0], tv, m[0x72DC - 0x72D8]))
    spans = script_keys(os.path.join(CASE, 'work', 'docs', 'ceB', 'hold-abort.txt'), a, b)
    h = 640
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f, fs, ft = K.font(13), K.font(11), K.font(17)
    d.text((14, 10), f'HOLD and ABORT: hold-abort frames {a}-{b}', font=ft, fill=FG)
    x0, w = 60, W - 90
    X, _ = chart_axes(d, x0, 46, w, 40, a, b, 0, 1, 'keys', f, ticks=[])
    kc = {'0': (40, 100, 200), 'CS': (200, 40, 40), 'H': (200, 40, 40), 'A': (120, 20, 20), 'S': (46, 140, 60)}
    for s0, s1, k in spans:
        for j, key in enumerate(k):
            yy = 50 + j * 16
            d.rectangle([X(s0), yy, max(X(s1), X(s0) + 14), yy + 13], fill=kc.get(key, DIM))
            d.text((X(s0) + 2, yy - 1), key, font=fs, fill=(255, 255, 255))
    d.rectangle([X(1100), 100, X(1300), 420], fill=(255, 232, 232))
    d.text((X(1100) + 6, 104), 'MainLoopHold $98D0: 1100 T 54 699 .. 1300 T 305', font=fs, fill=(150, 30, 30))
    d.line([X(1400), 100, X(1400), 420], fill=(120, 20, 20), width=2)
    d.text((X(1400) - 6 - d.textlength('JP Start: 1400 T 29 350', font=fs), 104), 'JP Start: 1400 T 29 350',
           font=fs, fill=(120, 20, 20))
    X, Y = chart_axes(d, x0, 124, w, 130, a, b, 130, 180, 'HarryX', f, ticks=[130, 140, 160, 180])
    pts = [(X(r[0]), Y(r[1])) for r in rows if r[0] < 1400]
    d.line(pts, fill=(40, 100, 200), width=2)
    tv = [r for r in rows if r[2] is not None and r[0] < 1400]
    lo, hi = min(r[2] for r in tv) - 2, max(r[2] for r in tv) + 2
    X, Y = chart_axes(d, x0, 272, w, 130, a, b, lo, hi, 'TIME', f, ticks=[lo, hi])
    d.line([(X(r[0]), Y(r[2])) for r in tv], fill=(225, 120, 20), width=2)
    for t in range(a - a % 50 + 50, b + 1, 50):
        d.line([X(t), 420, X(t), 426], fill=FG)
        d.text((X(t) - 14, 428), str(t), font=fs, fill=DIM)
    d.text((x0 + w / 2 - 20, 444), 'frame', font=f, fill=DIM)
    notes = ['How to read: the top lane is the input script; HarryX and the TIME digits (TimeDigits $7342) are',
             'sampled at each frame\'s start. The pink band is the hold: the slow tick spins in MainLoopHold reading',
             'only S, so Harry, the clock, the hens and the bonus stop; the interrupt (phrases) still runs. The line',
             'at 1400 is ABORT: POP HL drops the return into PlayLevel, JP Start resets the key type to 1 and redraws',
             'the title. Times are from a trace (frame and T of the instruction). TIME stops again at 1330 for another',
             'reason: Harry took a grain (score 50, BonusDelay and TimeDelay $FF). The point: both keys are read once',
             'per slow tick, from inside MainLoop, and HOLD freezes the whole game in place.',
             f'python3 tools/fig_controls.py hold --work W --from {a} --to {b} --out docs/img/controls/hold.png',
             '(W holds work/docs/ceB/rec/hold-abort/session.ttd)']
    for i, line in enumerate(notes):
        d.text((14, 470 + i * 17), line, font=f, fill=FG if i < 7 else DIM)
    im.save(out)




def fig_redefine(work, frames, out):
    """the redefine page at named frames with KeySet3's 12 bytes under each"""
    s = session(work)
    shots = []
    for fr in frames:
        m = bytearray(0x10000)
        m[0x4000:0x5B00] = mem(s, fr, 0x4000, 0x1B00)
        ks = mem(s, fr, 0x8268, 12)
        shots.append((fr, K.render_screen(bytes(m)).crop((0, 32, 256, 168)), ks))
    sw = (W - 14 * 4) // 3
    sc = sw / 256
    sh = int(136 * sc)
    h = 70 + sh + 110 + 150
    im = Image.new('RGB', (W, h), BG)
    d = ImageDraw.Draw(im)
    f, ft = K.font(13), K.font(17)
    d.text((14, 10), 'Redefining with odd keys: redefine-odd, the redefine page and KeySet3 $8268 at three frames',
           font=ft, fill=FG)
    notes_at = {140: ['9 for up at 110: stored as 1D EF,', 'refused by KeyUsed, not printed'],
                200: ['Q for up; W + E together for down:', 'one half row, mask $19, named w'],
                400: ['1 + Q at 230 refused (two rows);', 'O, P, M taken']}
    for i, (fr, pic, ks) in enumerate(shots):
        x = 14 + i * (sw + 14)
        im.paste(pic.resize((sw, sh), Image.NEAREST), (x, 44))
        lines = [f'frame {fr}'] + notes_at.get(fr, [])
        for j, line in enumerate(lines):
            d.text((x, 50 + sh + j * 17), line, font=f, fill=FG)
        d.text((x, 104 + sh), ' '.join(f'{b:02X}' for b in ks[:6]), font=f, fill=(40, 100, 200))
        d.text((x, 121 + sh), ' '.join(f'{b:02X}' for b in ks[6:]), font=f, fill=(40, 100, 200))
    notes = ['How to read: each panel is the screen rows 4-20 (from the top) of the redefine page at the frame\'s start',
             '(TTD memory_at); under it, in blue, the twelve bytes of key set 3: (mask, row) for up, down, left, right,',
             'jump, jump. A label shows only once RedefineOne paints its bar (ink 3); ClearScreen left it black on',
             'black. The last pair (1E F7, key 1) is never cleared. The point: KeyUsed compares a new key with the pairs',
             'before it and with the two pairs in front of the set, key set 2\'s jumps (4 and 9), so 4 and 9 can never',
             'be chosen; two keys of one half row become one control; two half rows give no key.',
             'python3 tools/fig_controls.py redefine --work W --frames 140,200,400 --out docs/img/controls/redefine-odd.png',
             '(W holds work/docs/ceB/rec/redefine-odd/session.ttd)']
    for i, line in enumerate(notes):
        d.text((14, 146 + sh + i * 18), line, font=f, fill=FG if i < 6 else DIM)
    im.save(out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['keyboard', 'keysets', 'path', 'hold', 'redefine'])
    p.add_argument('--work')
    p.add_argument('--from', dest='a', type=int)
    p.add_argument('--to', dest='b', type=int)
    p.add_argument('--frames', help='redefine: comma-separated frames')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    if args.what == 'keyboard':
        fig_keyboard(args.out)
    elif args.what == 'keysets':
        fig_keysets(args.out)
    elif args.what == 'path':
        fig_path(args.work, args.a, args.b, args.out)
    elif args.what == 'hold':
        fig_hold(args.work, args.a, args.b, args.out)
    else:
        fig_redefine(args.work, [int(x) for x in args.frames.split(',')], args.out)
    print(args.out)


if __name__ == '__main__':
    main()
