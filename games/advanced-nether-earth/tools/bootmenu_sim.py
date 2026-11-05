#!/usr/bin/env python3
"""The boot program ($6060-$F6D4: the boot menu and the help) run in tools/ane_sim.py's machine, traced.

    VENV/bin/python tools/bootmenu_sim.py SCRIPT --out DIR

The machine boots the SCL as ane_sim.py does (SPACE on the intro at frame 1300) up to the boot program's entry
($61A8 after its block is unpacked to $6060); frame 0 of SCRIPT is that moment. SCRIPT holds one event a line:

    FRAME KEY [FRAMES]     a key held from FRAME for FRAMES frames (default 4); KEY as in ane_sim.KEYS, or a
                           Kempston line: kright kleft kdown kup kfire
    FRAME shot NAME        the shown screen (bank 5 or 7, as $7FFD says) written as DIR/NAME.scr
    FRAME end              stop

DIR/trace.json: the instruction starts run inside the image with the image's own opcode byte ("starts"), the
addresses a CALL / RST reached ("entries"), the data reads per byte ("reads": every read that is not an opcode or
operand fetch of a run instruction, made by the boot program's own instructions before the game starter
runs), the first and last frame each start ran ("frames") and the $7FFD writes.
Addresses $C000 up count only with bank 0 there (bank 1 holds the boot music at $C000 too).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import ane_sim  # noqa: E402
from ane_sim import Machine, depack_hook, FRAME  # noqa: E402
from skoolkit import simutils as su  # noqa: E402
from skoolkit.pagingtracer import Memory  # noqa: E402
from mkgame import decode  # noqa: E402

CASE = os.path.dirname(HERE)
IMAGE = os.path.join(CASE, 'src', 'res', 'img', 'd05-6060.bin')
LO, HI = 0x6060, 0xF6D5
KEMPSTON = {'kright': 0, 'kleft': 1, 'kdown': 2, 'kup': 3, 'kfire': 4}


class CountingMemory(Memory):
    """Memory that counts every read of the image's bytes (bank 0 at $C000 only)"""
    counts = None
    active = False  # the instruction running is the boot program's own

    def __getitem__(self, index):
        if self.active and LO <= index < HI and (index < 0xC000 or self.o7ffd & 7 == 0):
            self.counts[index] += 1
        return self.memory[index // 0x4000][index % 0x4000]


class Traced(Machine):
    def read_port(self, registers, port):
        if not self.dos and port & 0xFF == 0x1F:
            frame = registers[su.T] // FRAME - self.f0
            v = 0
            for (f0, n, key) in self.events:
                if key in KEMPSTON and f0 <= frame < f0 + n:
                    v |= 1 << KEMPSTON[key]
            return v
        return super().read_port(registers, port)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('script')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    events, shots, end = [], [], None
    for line in open(args.script):
        line = line.split('#')[0].split()
        if not line:
            continue
        f = int(line[0])
        if line[1] == 'shot':
            shots.append((f, line[2]))
        elif line[1] == 'end':
            end = f
        else:
            events.append((f, int(line[2]) if len(line) > 2 else 4, line[1].lower()))
    image = open(IMAGE, 'rb').read()
    m = Traced(keys=[(1300, 10, 'space')])
    m.f0 = 10 ** 9
    m.events = []
    m.boot_basic()
    hook = depack_hook(None)
    while True:
        pc = m.run([0x61A8], 3000, hook)
        if pc != 0x61A8:
            sys.exit('no boot program by frame 3000')
        if any(e[0] == 'depack' and e[1] == '6060' for e in m.log):
            break
        # past this $61A8 (the loader's own, before the boot program is unpacked)
        r = m.sim.registers
        m.sim.opcodes[m.mem[r[su.PC]]]()
    built = bytes(m.peek(LO, HI - LO))
    assert built == image, 'the unpacked boot program is not src/res/img/d05-6060.bin'
    r = m.sim.registers
    m.f0 = r[su.T] // FRAME
    m.events = events
    # ane_sim's keyboard: the script's keys, shifted to absolute frames
    m.keys = [(m.f0 + f, n, k) for f, n, k in events if k not in KEMPSTON]
    counts = [0] * 0x10000
    CountingMemory.counts = counts
    m.mem.__class__ = CountingMemory
    starts, entries, frames, fetched = {}, set(), {}, set()
    state = {'prev': None}
    print('boot program entry at frame %d' % m.f0)

    def trace(mm, pc):
        prev = state['prev']
        if prev is not None:
            n, tg, falls, call = decode(image_view, prev)
            if call and pc in tg or (image_view[prev] & 0xC7 == 0xC7 and pc == image_view[prev] & 0x38):
                entries.add(pc)
        state['prev'] = None
        CountingMemory.active = False
        if pc == 0x9C40:
            # the game starter, copied from bank 7 over the pictures: from here no read is the boot program's and only
            # the start code below $62DE runs from the image (the game then overwrites $6731 up)
            state['starter'] = True
        if LO <= pc < HI and (pc < 0xC000 or mm.mem.o7ffd & 7 == 0):
            frame = r[su.T] // FRAME - mm.f0
            op = mm.mem.memory[pc // 0x4000][pc % 0x4000]
            n = decode(live, pc)[0]
            if op == image[pc - LO] and not (state.get('starter') and pc >= 0x62DE):
                CountingMemory.active = not state.get('starter')
                starts[pc] = n
                f = frames.setdefault(pc, [frame, frame])
                f[1] = frame
                for b in range(pc, pc + n):
                    fetched.add(b)
            state['prev'] = pc

    class Live:
        def __getitem__(self, a):
            a &= 0xFFFF
            return m.mem.memory[a // 0x4000][a % 0x4000]
    live = Live()
    image_view = live
    shots.sort()
    stop_at = end if end is not None else max([e[0] + e[1] for e in events] + [0]) + 100
    marks = sorted(set([f for f, _ in shots] + [stop_at]))
    for mark in marks:
        m.run([], m.f0 + mark, trace)
        for f, name in shots:
            if f == mark:
                bank = 7 if m.mem.o7ffd & 8 else 5
                open(os.path.join(args.out, name + '.scr'), 'wb').write(bytes(m.mem.banks[bank][:6912]))
    # a byte some run instruction fetched counts as no data read (code that also reads itself is not told apart)
    reads = {a: counts[a] for a in range(LO, HI) if counts[a] and a not in fetched}
    # the first $7FFD writes (PC, value, frame): the boot program's own paging
    pages = [[e[1], e[2], e[3] - m.f0] for e in m.log if e[0] == '7ffd' and e[3] >= m.f0][:200]
    json.dump({'f0': m.f0, 'starts': {'%04X' % a: n for a, n in sorted(starts.items())},
               'entries': ['%04X' % a for a in sorted(entries) if LO <= a < HI],
               'reads': {'%04X' % a: n for a, n in sorted(reads.items())},
               'frames': {'%04X' % a: f for a, f in sorted(frames.items())},
               'pages': pages}, open(os.path.join(args.out, 'trace.json'), 'w'))
    print('%d starts, %d entries, %d bytes read as data, stop at $%04X frame %d' %
          (len(starts), len(entries), len(reads), r[su.PC], r[su.T] // FRAME - m.f0))


if __name__ == '__main__':
    main()
