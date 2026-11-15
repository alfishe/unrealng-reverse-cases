#!/usr/bin/env python3
"""The figures of doc 5 (controls), and the helpers figs 6 and 8 share (fig_render.py, fig_hud.py import them).

    python3 tools/fig_controls.py keys --out docs/img/controls/keys.png
    python3 tools/fig_controls.py readers --out docs/img/controls/readers.png \
        --rec "tape=build/game.bin" --rec "DEFINE P L Z X M=work/docs/rxB/readers-define.txt:00" ...
    python3 tools/fig_controls.py play --work W --from F --to G --step S --keys tests/inputs/c1.txt --offset 15000 \
        --out docs/img/play/keys.gif
    python3 tools/fig_controls.py tutor --out docs/img/controls/tutor-scripts.png
    python3 tools/fig_controls.py shots --work W --shot F=label --shot G=label --title T --out O

keys: which key or port bit gives which control, for the tape's keys and the menu's three fixed choices, read from
the code (the readers' operands as loaded, ChooseSinclair, ChooseCursor, ChooseKempston). readers: the five readers
$A477-$A4E6 as each choice leaves them, read from dumps of the recordings (the 125 bytes from SetFire $A46A, read with
time_travel memory_at at the frame the caption names). play: a recording's play window beside the keys its input script
holds and the variables they drive, sampled at T 0 of each frame. tutor: DEMO's four input scripts as lanes.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(CASE, '..', '..', 'kit')
sys.path.insert(0, KIT)
import kitlib as K  # noqa: E402

PARTS = {'rex1': ('build/game.bin', 0x6018, 'build/game.lst'),
         'rex2': ('build/rex2.bin', 0x61A8, 'build/rex2.lst'),
         'demo': ('build/demo.bin', 0x61A8, 'build/demo.lst')}
WIDTH = 1050


# ---------------------------------------------------------------------------------------------------------------
# shared helpers

def image(part='rex1'):
    """The part's 64 K as the loader leaves it (the build's bytes at their address)"""
    path, base, _ = PARTS[part]
    data = open(os.path.join(CASE, path), 'rb').read()
    mem = bytearray(0x10000)
    mem[base:base + len(data)] = data
    return mem


def symbols(part='rex1'):
    """label -> address from the part's listing"""
    out = {}
    for line in open(os.path.join(CASE, PARTS[part][2]), encoding='latin-1'):
        m = K.LINE.match(line)
        if not m:
            continue
        lab = K.LABEL.match(m.group(3).strip())
        if lab and lab.group(1) not in out:
            out[lab.group(1)] = int(m.group(1), 16)
    return out


class Live:
    """time_travel memory_at on the instance a re_session work folder holds"""

    def __init__(self, work):
        sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import re_session  # noqa: E402
        self.session, _ = re_session.session_of(work)

    def mem(self, frame, address, length, t=None):
        body = {'action': 'memory_at', 'space': 'cpu', 'frame': int(frame), 'offset': address, 'length': length}
        if t is not None:
            body['tinframe'] = int(t)
        r = self.session.call('time_travel', body, ok=False)
        data = (r.structured or {}).get('hex')
        if r.is_error or not data:
            raise SystemExit(f'memory_at {frame} ${address:04X}: {r.text}')
        return bytes.fromhex(data)


def screen(mem, base=0x4000):
    """The 6912 bytes at base as an RGB picture"""
    buf = bytearray(0x10000)
    buf[0x4000:0x5B00] = mem[base:base + 0x1B00] if len(mem) >= base + 0x1B00 else mem[:0x1B00]
    return K.render_screen(buf)


def title(draw, text, y=8, size=17):
    draw.text((12, y), text, fill=K.TEXT, font=K.font(size))


def input_events(path, offset=0):
    """(frame, keys) of an input script, absolute frames + offset"""
    f, out = 0, []
    for line in open(path):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        t, _, k = line.partition(' ')
        if t.startswith('+'):
            f += int(t[1:])
        elif t.isdigit():
            f = int(t)
        else:
            continue
        if k == 'END':
            out.append((f + offset, []))
            break
        out.append((f + offset, [] if k.strip() in ('-', '') else k.split()))
    return out


def keys_at(events, frame):
    held = []
    for f, k in events:
        if f > frame:
            break
        held = k
    return held


# ---------------------------------------------------------------------------------------------------------------
# keys: the keyboard and what each choice reads

ROWS = [('1', '2', '3', '4', '5', '6', '7', '8', '9', '0'),
        ('Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'),
        ('A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENT'),
        ('CS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SS', 'SPC')]
# half-row port -> the keys of bits 0-4
HALF = {0xFEFE: ('CS', 'Z', 'X', 'C', 'V'), 0xFDFE: ('A', 'S', 'D', 'F', 'G'), 0xFBFE: ('Q', 'W', 'E', 'R', 'T'),
        0xF7FE: ('1', '2', '3', '4', '5'), 0xEFFE: ('0', '9', '8', '7', '6'), 0xDFFE: ('P', 'O', 'I', 'U', 'Y'),
        0xBFFE: ('ENT', 'L', 'K', 'J', 'H'), 0x7FFE: ('SPC', 'SS', 'M', 'N', 'B')}
MOVES = ['FIRE', 'LEFT', 'RIGHT', 'UP', 'DOWN']
MOVE_COLOUR = {'FIRE': (240, 80, 70), 'LEFT': (90, 150, 250), 'RIGHT': (80, 210, 120), 'UP': (240, 200, 70),
               'DOWN': (200, 110, 230)}
FIXED = {'H': 'pause', 'SPC': 'smart bomb', 'ENT': 'restart'}
SETTERS = {'SetFire': 'FIRE', 'SetLeft': 'LEFT', 'SetRight': 'RIGHT', 'SetUp': 'UP', 'SetDown': 'DOWN'}
READERS = [('FIRE', 'ReadFire', 'ReadFireBit'), ('LEFT', 'ReadLeft', 'ReadLeftBit'),
           ('RIGHT', 'ReadRight', 'ReadRightBit'), ('UP', 'ReadUp', 'ReadUpBit'), ('DOWN', 'ReadDown', 'ReadDownBit')]


def readers_of(mem, sym):
    """{move: (port, bit)} from the readers' operands in mem"""
    out = {}
    for move, reader, bit in READERS:
        a = sym[reader]
        port = mem[a + 1] | mem[a + 2] << 8
        out[move] = (port, (mem[sym[bit] + 1] - 0x47) >> 3)
    return out


def choice_of(mem, sym, entry, stop):
    """{move: (port, bit)} from a Choose routine: LD HL,port / LD (DefinePort),HL; LD A,op / LD (DefineBit),A;
    CALL Setter"""
    names = {v: k for k, v in sym.items() if k in SETTERS}
    port, op, out, a = None, None, {}, entry
    while a < stop:
        b = mem[a]
        if b == 0x21:
            port = mem[a + 1] | mem[a + 2] << 8
            a += 3
        elif b == 0x3E:
            op = mem[a + 1]
            a += 2
        elif b == 0xCD:
            target = mem[a + 1] | mem[a + 2] << 8
            if target in names:
                out[SETTERS[names[target]]] = (port, (op - 0x47) >> 3)
            a += 3
        else:
            a += 1
    return out


def key_name(port, bit):
    return HALF[port][bit] if port in HALF else None


def draw_keyboard(draw, x0, y0, label, mapping, f, fs, menu=False):
    kw, kh, gap = 40, 30, 4
    draw.text((x0, y0), label, fill=K.TEXT, font=f)
    y0 += 24
    keyed = {key_name(*v): m for m, v in mapping.items() if key_name(*v)}
    for r, row in enumerate(ROWS):
        for c, k in enumerate(row):
            x = x0 + c * (kw + gap) + r * 8
            y = y0 + r * (kh + gap)
            fill, ink = (44, 44, 54), K.DIM
            if k in keyed:
                fill, ink = MOVE_COLOUR[keyed[k]], (10, 10, 10)
            elif k in FIXED:
                fill, ink = (150, 150, 160), (10, 10, 10)
            elif menu and k in ('1', '2', '3', '4', 'Y', 'N'):
                fill, ink = (70, 70, 90), K.TEXT
            draw.rectangle([x, y, x + kw, y + kh], fill=fill, outline=(90, 90, 100))
            draw.text((x + 4, y + 7), k, fill=ink, font=fs)
    return y0 + 4 * (kh + gap)


def cmd_keys(args):
    mem, sym = image(), symbols()
    tape = readers_of(mem, sym)
    sinclair = choice_of(mem, sym, sym['ChooseSinclair'], sym['KeysConfirm'])
    cursor = choice_of(mem, sym, sym['ChooseCursor'], sym['Confirm'])
    kempston = choice_of(mem, sym, sym['ChooseKempston'], sym['ChooseSinclair'])
    pic = Image.new('RGB', (WIDTH, 690), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, ft = K.font(15), K.font(12), K.font(13)
    title(d, 'What each menu choice reads for FIRE, LEFT, RIGHT, UP (jump) and DOWN (shield)')
    y = 40
    yb = draw_keyboard(d, 12, y, '1 DEFINE: tape keys until redefined', tape,
                       f, fs, menu=True)
    draw_keyboard(d, 530, y, '4 SINCLAIR ($DE5D): port $EFFE', sinclair, f, fs)
    y2 = yb + 20
    yb2 = draw_keyboard(d, 12, y2, '3 CURSOR ($DE99): $EFFE, LEFT $F7FE', cursor, f, fs)
    # Kempston bits
    x0 = 530
    d.text((x0, y2), '2 KEMPSTON ($DE20): port $001F, XOR $FF', fill=K.TEXT, font=f)
    for bit in range(8):
        x = x0 + (7 - bit) * 58
        move = next((m for m, v in kempston.items() if v[1] == bit), None)
        fill = MOVE_COLOUR[move] if move else (44, 44, 54)
        d.rectangle([x, y2 + 30, x + 52, y2 + 70], fill=fill, outline=(90, 90, 100))
        d.text((x + 4, y2 + 34), f'bit {bit}', fill=(10, 10, 10) if move else K.DIM, font=fs)
        if move:
            d.text((x + 4, y2 + 51), move, fill=(10, 10, 10), font=fs)
    d.text((x0, y2 + 80), 'The interface reads 1 for a closed switch: XOR $FF', fill=K.DIM, font=ft)
    d.text((x0, y2 + 98), 'turns that into the keyboard\'s 0 before BIT n,A.', fill=K.DIM, font=ft)
    # legend
    ly = yb2 + 20
    x = 12
    for m in MOVES:
        d.rectangle([x, ly, x + 22, ly + 18], fill=MOVE_COLOUR[m])
        d.text((x + 28, ly + 1), {'UP': 'UP (jump)', 'DOWN': 'DOWN (shield)'}.get(m, m), fill=K.TEXT, font=ft)
        x += 150
    ly += 30
    d.rectangle([12, ly, 34, ly + 18], fill=(150, 150, 160))
    d.text((40, ly + 1), 'fixed keys in play, whatever the choice: H pause ($BFFE bit 4), SPACE smart bomb ($7FFE '
           'bit 0), ENTER restart ($BFFE bit 0)', fill=K.TEXT, font=ft)
    ly += 26
    d.rectangle([12, ly, 34, ly + 18], fill=(70, 70, 90))
    d.text((40, ly + 1), 'the menu\'s keys: 1-4 ($F7FE bits 0-3), Y ($DFFE bit 4) and N ($7FFE bit 3) at the '
           'confirm', fill=K.TEXT, font=ft)
    pic = pic.crop((0, 0, WIDTH, ly + 32))
    pic.save(args.out)
    print(args.out)


# ---------------------------------------------------------------------------------------------------------------
# readers: the reader code as each choice leaves it

def cmd_readers(args):
    sym = symbols()
    states = []
    for spec in args.rec:
        name, _, src = spec.partition('=')
        if src.endswith('.bin'):
            mem = image()
            xor = mem[sym['ControlXor']]
        else:
            path, _, xor = src.rpartition(':')
            dump = bytes.fromhex(open(os.path.join(CASE, path)).read())
            mem = bytearray(0x10000)
            mem[sym['SetFire']:sym['SetFire'] + len(dump)] = dump
            xor = int(xor, 16)
        states.append((name, src, mem, xor))
    tape = states[0][2]
    rows = []
    for move, reader, bitlab in READERS:
        a = sym[reader]
        rows.append((move, reader, a, sym[bitlab]))
    cw, lw, rh = 170, 200, 74
    pic = Image.new('RGB', (WIDTH, 64 + rh * (len(rows) + 1) + 70), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    title(d, 'The readers as each choice leaves them: LD BC,port / IN A,(C) / XOR (ControlXor) / BIT n,A / RET')
    y = 40
    for i, (name, src, mem, xor) in enumerate(states):
        x = lw + i * cw
        head, _, sub = name.partition(',')
        d.text((x, y), head, fill=K.TEXT, font=fb)
        d.text((x, y + 18), sub.strip(), fill=K.DIM, font=fs)
        d.text((x, y + 34), f'ControlXor ${xor:02X}', fill=(255, 210, 70) if xor else K.DIM, font=fs)
    y += 60
    hot, cold = (255, 210, 70), K.TEXT
    for move, reader, a, bitaddr in rows:
        d.rectangle([12, y + 2, 12 + 14, y + 16], fill=MOVE_COLOUR[move])
        d.text((32, y), move, fill=K.TEXT, font=fb)
        d.text((32, y + 20), f'{reader} ${a:04X}', fill=K.DIM, font=fs)
        d.text((32, y + 36), f'port ${a + 1:04X}, bit ${bitaddr + 1:04X}', fill=K.DIM, font=fs)
        for i, (name, src, mem, xor) in enumerate(states):
            x = lw + i * cw
            port = mem[a + 1] | mem[a + 2] << 8
            op = mem[bitaddr + 1]
            bit = (op - 0x47) >> 3
            pc = hot if mem[a + 1:a + 3] != tape[a + 1:a + 3] else cold
            bc = hot if op != tape[bitaddr + 1] else cold
            d.text((x, y), f'LD BC,${port:04X}', fill=pc, font=fs)
            d.text((x, y + 16), f'BIT {bit},A  (CB {op:02X})', fill=bc, font=fs)
            k = key_name(port, bit)
            label = f'key {k}' if k else ('Kempston' if port == 0x1F else '?')
            d.text((x, y + 34), label, fill=MOVE_COLOUR[move], font=fb)
        y += rh
    d.text((12, y + 4), 'Yellow: what the choice changed against the tape (the port of LD BC,nn; the BIT n,A byte $47 + 8n). '
           'Each reader', fill=K.TEXT, font=f)
    d.text((12, y + 22), 'returns Z when its control is pressed. The memory is the recording\'s at T 0 of the frame '
           'named in the caption.', fill=K.TEXT, font=f)
    pic = pic.crop((0, 0, WIDTH, y + 46))
    pic.save(args.out)
    print(args.out)


# ---------------------------------------------------------------------------------------------------------------
# play: Rex answering the keys

VARS = [('RexX', 0xA0B6, 'X'), ('RexY', 0xA0B7, 'Y'), ('RexFacing', 0xA0BB, 'facing'), ('Jumping', 0xA0BD, 'jump'),
        ('FallSpeed', 0xA0BC, 'fall'), ('ShieldOn', 0xA049, 'shield'), ('FireLatch', 0xA012, 'fire latch'),
        ('Bombs', 0xA06C, 'bombs'), ('ShieldEnergy', 0xA04D, 'shield energy')]


def cmd_play(args):
    live = Live(args.work)
    events = input_events(args.keys, args.offset)
    frames = list(range(args.start, args.end + 1, args.step))
    samples = []
    for fr in frames:
        m = live.mem(fr, 0x4000, 0x1B00)
        v = live.mem(fr, 0xA000, 0xC4)
        samples.append((fr, m, {name: v[a - 0xA000] for name, a, _ in VARS}))
    keys_used = []
    for f_, k in events:
        for key in k:
            if key not in keys_used and args.start - 400 <= f_ <= args.end:
                keys_used.append(key)
    sc = 2
    crop = (0, 0, 256, 192)
    sw, sh = (crop[2] - crop[0]) * sc, (crop[3] - crop[1]) * sc
    W, H = WIDTH, sh + 120
    f, fs = K.font(14), K.font(12)
    xs = sw + 30
    cw = W - xs - 16
    span = args.end - args.start

    def fx(fr):
        return xs + 60 + (fr - args.start) * (cw - 60) / span

    pictures = []
    for fr, m, v in samples:
        pic = Image.new('RGB', (W, H), K.BACKGROUND)
        d = ImageDraw.Draw(pic)
        d.text((12, 8), args.title, fill=K.TEXT, font=K.font(15))
        scr = screen(m, 0).crop(crop).resize((sw, sh), Image.NEAREST)
        pic.paste(scr, (12, 40))
        y = 40
        d.text((xs, y), f'frame {fr} (script frame {fr - args.offset})', fill=K.TEXT, font=f)
        y += 26
        held = keys_at(events, fr)
        for key in keys_used:
            d.text((xs, y), key, fill=K.TEXT, font=fs)
            for (f0, k), nxt in zip(events, events[1:] + [(args.end + 1, [])]):
                if key in k and nxt[0] > args.start and f0 < args.end:
                    a, b = max(f0, args.start), min(nxt[0], args.end)
                    d.rectangle([fx(a), y + 3, fx(b), y + 13], fill=(90, 150, 250))
            y += 18
        # variables
        y += 8
        for name, a, short in VARS:
            hist = [s[2][name] for s in samples]
            lo, hi = min(hist), max(hist)
            d.text((xs, y), f'{name} ${a:04X} = {v[name]}', fill=K.TEXT, font=fs)
            if hi > lo and name in ('RexX', 'RexY', 'ShieldEnergy'):
                y += 16
                pts = [(fx(s[0]), y + 30 - (s[2][name] - lo) * 30 / (hi - lo)) for s in samples]
                d.line(pts, fill=(80, 210, 120), width=2)
                y += 34
            else:
                y += 16
        d.line([fx(fr), 66, fx(fr), y], fill=(255, 210, 70), width=1)
        held_txt = ' '.join(held) if held else 'none'
        d.text((12, 46 + sh), f'keys held: {held_txt}', fill=(255, 210, 70), font=f)
        d.text((12, 68 + sh), 'Memory and screen sampled at T 0 of the frame. Blue bars: the keys of the input '
               'script; the yellow line: this frame.', fill=K.DIM, font=fs)
        pictures.append(pic)
    K.save_gif(args.out, pictures, [args.delay] * (len(pictures) - 1) + [args.hold])
    print(args.out, len(pictures))


# ---------------------------------------------------------------------------------------------------------------
# tutor: DEMO's input scripts

def tutor_passes(mem, start, end):
    """the input of each pass of a TutorStep script: the first count, then [input][count] pairs to end. An input
    holds for one pass (TutorStep loads it when the count runs out), then $FF for count - 1 passes; a count of 0
    (the padding at the end) stops the drawing"""
    passes = [0xFF] * (mem[start] - 1)
    for a in range(start + 1, end - 1, 2):
        inp, count = mem[a], mem[a + 1]
        passes.append(inp)
        if count == 0:  # the padding at the end: 255 empty passes, the room has ended before
            break
        passes += [0xFF] * (count - 1)
    return passes


def cmd_tutor(args):
    mem, sym = image('demo'), symbols('demo')
    scripts = [('TutorScript0', 'room 0'), ('TutorScript1', 'room 1'), ('TutorScript2', 'room 2'),
               ('TutorScript4', 'room 4')]
    lanes = [(0, 'fire'), (1, 'up'), (2, 'down'), (3, 'right'), (4, 'left')]
    colours = {0: MOVE_COLOUR['FIRE'], 1: MOVE_COLOUR['UP'], 2: MOVE_COLOUR['DOWN'], 3: MOVE_COLOUR['RIGHT'],
               4: MOVE_COLOUR['LEFT']}
    ends = sorted(set(sym.values()))
    data = [(lab, room, tutor_passes(mem, sym[lab], min(v for v in ends if v > sym[lab]))) for lab, room in scripts]
    longest = max(len(p) for _, _, p in data)
    lw = 120
    pw = WIDTH - lw - 20
    lane_h = 12
    block = lane_h * 5 + 44
    pic = Image.new('RGB', (WIDTH, 50 + block * len(data) + 40), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    f, fs = K.font(13), K.font(12)
    title(d, 'DEMO\'s input scripts: what TutorStep $9F82 presses on each pass (TutorInput $6079, 0 = pressed)')
    y = 44
    order = {'room 4': 0, 'room 1': 1, 'room 0': 2, 'room 2': 3}
    for lab, room, passes in sorted(data, key=lambda x: order[x[1]]):
        n = len(passes)
        d.text((12, y), f'{lab} ${sym[lab]:04X}: {room}, {n} passes', fill=K.TEXT, font=f)
        y += 20
        for bit, name in lanes:
            d.text((12, y), name, fill=K.DIM, font=fs)
            for i, p in enumerate(passes):
                if not p & (1 << bit):
                    x = lw + i * pw / longest
                    d.rectangle([x, y + 1, x + max(1, pw / longest), y + lane_h - 2], fill=colours[bit])
            y += lane_h
        # pass ticks
        for t in range(0, n + 1, 100):
            x = lw + t * pw / longest
            d.line([x, y, x, y + 4], fill=K.DIM)
            if t % 200 == 0:
                d.text((x - 8, y + 4), str(t), fill=K.DIM, font=K.font(10))
        y += 24
    d.text((12, y), 'Played in the order of TutorRooms $A2A2 (rooms 4, 1, 0, 2); a pass is about 4 frames. Drawn '
           'from build/demo.bin.', fill=K.DIM, font=fs)
    pic.save(args.out)
    print(args.out)


def cmd_shots(args):
    """Two screens of a recording side by side, 2x, each with its label"""
    live = Live(args.work)
    pic = Image.new('RGB', (WIDTH, 40 + 384 + 34), K.BACKGROUND)
    d = ImageDraw.Draw(pic)
    title(d, args.title)
    for i, spec in enumerate(args.shot):
        frame, _, label = spec.partition('=')
        scr = screen(live.mem(int(frame), 0x4000, 0x1B00), 0).resize((512, 384), Image.NEAREST)
        x = 8 + i * 522
        pic.paste(scr, (x, 40))
        d.text((x, 40 + 384 + 8), label, fill=K.TEXT, font=K.font(13))
    pic.save(args.out)
    print(args.out)


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('keys')
    s.add_argument('--out', required=True)
    s = sub.add_parser('readers')
    s.add_argument('--out', required=True)
    s.add_argument('--rec', action='append', required=True,
                   help='NAME=build/game.bin, or NAME=DUMP:XOR (DUMP: hex of the 125 bytes from SetFire $A46A)')
    s = sub.add_parser('play')
    s.add_argument('--work', required=True)
    s.add_argument('--from', dest='start', type=int, required=True)
    s.add_argument('--to', dest='end', type=int, required=True)
    s.add_argument('--step', type=int, default=4)
    s.add_argument('--keys', required=True)
    s.add_argument('--offset', type=int, default=0)
    s.add_argument('--title', default='Rex answering the keys')
    s.add_argument('--delay', type=int, default=120)
    s.add_argument('--hold', type=int, default=2000)
    s.add_argument('--out', required=True)
    s = sub.add_parser('tutor')
    s.add_argument('--out', required=True)
    s = sub.add_parser('shots')
    s.add_argument('--work', required=True)
    s.add_argument('--shot', action='append', required=True, help='FRAME=label (two)')
    s.add_argument('--title', required=True)
    s.add_argument('--out', required=True)
    args = p.parse_args()
    {'shots': cmd_shots, 'keys': cmd_keys, 'readers': cmd_readers, 'play': cmd_play, 'tutor': cmd_tutor}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
