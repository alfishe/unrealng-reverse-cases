#!/usr/bin/env python3
"""Doc 05's animation: the hero answering the keys, one picture every --step frames of a recording.

    python3 tools/anim_keys.py --work W --script tests/inputs/c1.txt --from 15590 --to 15720 --step 2 \
        --title 'c1 frames 15590-15720: ...' docs/img/play/keys-hero.gif

Left: the Spectrum screen at the frame (TTD memory_at on the instance that holds the recording, scale 3). Right: the
keys the recording's script holds at that frame (the tape's defaults I J Q W O, and SPACE, ENTER, H), the five
readers' ports and bits as they stand in memory (`$FC90-$FCDA`), the hero's record (`$74E0`: column, line, frame,
state) and PassCounter `$FE31`. 1050 px wide.
"""
import argparse
import os
import sys

from PIL import Image, ImageDraw

from figmyth import F, BG, TEXT, DIM, HI, W, kitlib

sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
import zxscreen  # noqa: E402  (kit)

STATES = {0: 'stand', 1: 'walk', 2: 'jump', 3: 'fall', 4: 'leap back', 5: 'middle strike', 6: 'high strike',
          7: 'low strike', 9: 'leap up', 0x0B: 'thrown back', 0x0F: 'dying'}
READERS = [('UP', 0xFC90), ('DOWN', 0xFC9F), ('LEFT', 0xFCAE), ('RIGHT', 0xFCBD), ('FIRE', 0xFCCC)]
ROWS = {0xFEFE: 'CAPS Z X C V', 0xFDFE: 'A S D F G', 0xFBFE: 'Q W E R T', 0xF7FE: '1 2 3 4 5', 0xEFFE: '0 9 8 7 6',
        0xDFFE: 'P O I U Y', 0xBFFE: 'ENTER L K J H', 0x7FFE: 'SPACE SYM M N B'}
KEYS = [('I', 'UP'), ('J', 'DOWN'), ('Q', 'LEFT'), ('W', 'RIGHT'), ('O', 'FIRE'), ('SPACE', 'items'),
        ('ENTER', 'pause'), ('H', 'nothing')]


def script_keys(path):
    """(frame, set of keys) changes from a tests/inputs script"""
    out = []
    for line in open(path):
        line = line.split('#')[0].split()
        if not line or not line[0].isdigit():
            continue
        f = int(line[0])
        keys = set() if line[1:] == ['-'] else set(line[1:])
        out.append((f, keys))
    return out


def held_at(changes, frame):
    keys = set()
    for f, k in changes:
        if f > frame:
            break
        keys = k
    return keys


def reader_key(port, bitop):
    bit = (bitop - 0x47) // 8
    names = ROWS.get(port, '').split()
    if port == 0x001F:
        return 'Kempston bit %d' % bit
    if port in (0xF7FE, 0xEFFE, 0xFEFE, 0xFDFE, 0xFBFE):
        order = names
    else:
        order = names
    return order[bit] if bit < len(order) else '?'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--script', required=True)
    ap.add_argument('--from', dest='start', type=int, required=True)
    ap.add_argument('--to', dest='end', type=int, required=True)
    ap.add_argument('--step', type=int, default=2)
    ap.add_argument('--delay', type=int, default=80)
    ap.add_argument('--title', default='')
    ap.add_argument('out')
    a = ap.parse_args()
    import re_session  # noqa: E402
    session, _ = re_session.session_of(a.work)

    def mem(frame, addr, n):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                         'offset': addr, 'length': n}, ok=False)
        body = r.structured or {}
        if r.is_error or not body.get('exact', False):
            raise SystemExit(f'memory_at {frame}: {r.text}')
        return bytes.fromhex(body['hex'])

    changes = script_keys(a.script)
    pictures = []
    for f in range(a.start, a.end + 1, a.step):
        scr = zxscreen.render(mem(f, 0x4000, 0x1B00), 3).convert('RGB')
        hero = mem(f, 0x74E0, 0x12)
        readers = mem(f, 0xFC90, 0x4B)
        pc = mem(f, 0xFE31, 1)[0]
        im = Image.new('RGB', (W, 40 + scr.height + 8), BG)
        d = ImageDraw.Draw(im)
        d.text((12, 10), a.title, font=F(17), fill=TEXT)
        im.paste(scr, (8, 40))
        x = 8 + scr.width + 14
        y = 44
        d.text((x, y), 'frame %d' % f, font=F(16), fill=HI)
        y += 30
        d.text((x, y), 'keys held (the script)', font=F(13), fill=DIM)
        y += 22
        held = held_at(changes, f)
        for i, (k, what) in enumerate(KEYS):
            on = k in held
            bx, by = x + (i % 2) * 130, y + (i // 2) * 34
            d.rectangle((bx, by, bx + 52, by + 26), fill=(230, 200, 60) if on else (45, 45, 56))
            d.text((bx + 6, by + 5), k, font=F(14), fill=(15, 15, 20) if on else TEXT)
            d.text((bx + 58, by + 6), what, font=F(13), fill=TEXT if on else DIM)
        y += 4 * 34 + 10
        d.text((x, y), 'the readers in memory', font=F(13), fill=DIM)
        y += 22
        for i, (name, addr) in enumerate(READERS):
            o = addr - 0xFC90
            port = readers[o + 4] | readers[o + 5] << 8
            bitop = readers[o + 13]
            d.text((x, y), '%-5s $%04X bit %d  %s' % (name, port, (bitop - 0x47) // 8, reader_key(port, bitop)),
                   font=F(13), fill=TEXT)
            y += 20
        y += 14
        d.text((x, y), 'the hero, $74E0', font=F(13), fill=DIM)
        y += 22
        state = hero[0x0A]
        d.text((x, y), 'state $%02X: %s' % (state, STATES.get(state, '?')), font=F(15), fill=HI)
        y += 24
        d.text((x, y), 'column %d  line %d' % (hero[0], hero[1]), font=F(13), fill=TEXT)
        y += 20
        d.text((x, y), 'frame $%02X  facing %s' % (hero[8], 'left' if hero[9] & 0x80 else 'right'),
               font=F(13), fill=TEXT)
        y += 20
        d.text((x, y), 'PassCounter $%02X' % pc, font=F(13), fill=TEXT)
        pictures.append(im.convert('P', palette=Image.ADAPTIVE, colors=64))
    durations = [a.delay] * (len(pictures) - 1) + [1500]
    pictures[0].save(a.out, save_all=True, append_images=pictures[1:], duration=durations, loop=0, optimize=True)
    print(a.out, len(pictures), pictures[0].size)


if __name__ == '__main__':
    main()
