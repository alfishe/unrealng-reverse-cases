#!/usr/bin/env python3
"""The game's own 3D code run in skoolkit's Z80 simulator: any blueprint drawn exactly as Elite draws it.

The memory is a recorded title (d1 frame 250: the title loop, the front view, the squares table built, slot 7 the
title ship). A ship is placed the way ActionTitleShip `$B98C` places the title's ship (CreateShip, then the title's
axes and z = 2 pages), and each picture is the title loop's own work: ClearView, then TurnTitleShip (MoveShip with
pitch $8C and roll $94, Orthogonalise, TidyAxis, DrawShip), then the back buffer `$C000-$CFFF` read as the screen's
top two thirds (256 x 128). Nothing is modelled: the rotation, the projection, the face test, the detail level and
the lines are the game's instructions.

    import shipsim
    sim = shipsim.Ship(blueprint=8)          # a Viper
    frames = [sim.step() for _ in range(40)] # 1-bit 256 x 128 pictures (lists of rows of 0/1)

Options: distance (the z page, default the title's 2), rates (pitch, roll: the byte MoveShip takes in A, which
TurnOwn reads from TurnRates+1 and turns the nose towards the roof by, and the byte TurnRates, which turns the side
towards the roof, the roll about the nose; the title's $8C and $94: TurnTitleShip's comment in the source has the
names the other way round), hidden=False
(every face counted visible: FaceVisible `$A984` filled after FaceVisibility, so the hidden edges are drawn too).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "kit"))

NAMES = ['Coriolis', 'Missile', 'Escape pod', 'Plate (alloys)', 'Cargo canister', 'Splinter', 'Asteroid',
         'Rock hermit', 'Viper', 'Cobra Mk III (trader)', 'Python (trader)', 'Python (pirate)',
         'Cobra Mk III (pirate)', 'Asp Mk II', 'Fer-de-Lance', 'Thargoid', 'Sidewinder', 'Krait', 'Thargon']
_LABELS = {}


def labels():
    """label -> address, from build/game.lst"""
    if not _LABELS:
        for line in open(os.path.join(CASE, 'build', 'game.lst'), errors='replace'):
            m = re.match(r'^\s*\d+\+?\s+([0-9A-F]{4})\s+(?:[0-9A-F]{2}\s?)*\s*([A-Za-z_]\w*):', line)
            if m:
                _LABELS.setdefault(m.group(2), int(m.group(1), 16))
    return _LABELS


def title_memory(rec='d1', frame=250):
    """the 64 KB of a recorded snapshot (48K: pages 5, 2, 0) with the ROM"""
    d = os.path.join(CASE, 'work', rec, 'snapshots', '%06d' % frame)
    import kitlib as K
    rom = open(os.path.join(K.unreal_root(), 'data', 'rom', '48.rom'), 'rb').read()
    page = lambda n: open(os.path.join(d, 'ram-%d.bin' % n), 'rb').read()
    return bytearray(rom + page(5) + page(2) + page(0))


def _simulator():
    try:
        from skoolkit.simulator import Simulator
    except ImportError:
        import glob
        sys.path += glob.glob(os.path.join(os.environ.get('SKOOLKIT_VENV', ''), 'lib', 'python3*', 'site-packages'))
        from skoolkit.simulator import Simulator
    return Simulator


STUB = 0xFFB0          # free bytes above the game image ($FFA8 on), below the stack's top


def back_buffer(mem, base=0xC000):
    """the 256 x 128 back buffer as rows of 0/1 (laid out like the screen's top two thirds)"""
    rows = []
    for y in range(128):
        a = base + ((y & 0xC0) << 5) + ((y & 7) << 8) + ((y & 0x38) << 2)
        row = []
        for b in mem[a:a + 32]:
            row += [(b >> (7 - i)) & 1 for i in range(8)]
        rows.append(row)
    return rows


class Ship:
    def __init__(self, blueprint, distance=2, rates=(0x8C, 0x94), hidden=True, mem=None, x=0, y=0):
        L = labels()
        self.L = L
        self.mem = bytearray(mem or title_memory())
        self.sim = _simulator()(self.mem, {'SP': 0xFF50, 'IY': 0x5C3A})
        self.hidden = hidden
        self.pitch, self.roll = rates
        # place it: LD IX,Slot7 / LD A,n / CALL CreateShip / JP the rest of ActionTitleShip
        rest = L["ActionTitleShip"] + 10
        code = [0xDD, 0x21, L['Slot7'] & 0xFF, L['Slot7'] >> 8, 0x3E, blueprint,
                0xCD, L['CreateShip'] & 0xFF, L['CreateShip'] >> 8, 0xC3, rest & 0xFF, rest >> 8]
        self.call_stub(code)
        s7 = L['Slot7']
        self.mem[s7 + 7] = distance & 0xFF
        self.mem[s7 + 6] = 0
        self.mem[s7 + 1], self.mem[s7 + 4] = x & 0xFF, y & 0xFF
        self.slot = s7
        self.blueprint = blueprint
        self.pictures = 0

    def call_stub(self, code):
        """CALL a stub written at STUB and run until it returns"""
        m = self.mem
        m[STUB:STUB + len(code)] = bytes(code)
        ret = STUB + 0x40
        m[ret] = 0x00          # a NOP the run stops on
        sp = 0xFF50
        m[sp - 2], m[sp - 1] = ret & 0xFF, ret >> 8
        regs = self.sim.registers
        regs[12] = sp - 2
        self.sim.run(STUB, ret)

    def call(self, routine):
        a = self.L[routine]
        self.call_stub([0xCD, a & 0xFF, a >> 8, 0xC9])

    def step(self, after_clear=()):
        """one title-loop picture: ClearView, the routines named in after_clear (TitleTextPress for the title's
        own pass), TurnTitleShip with the rates, the back buffer"""
        L, m = self.L, self.mem
        self.call('ClearView')
        for r in after_clear:
            self.call(r)
        if self.hidden:
            # TurnTitleShip with this ship's rates: LD A,roll / LD (TurnRates),A / LD A,pitch / JP past them
            t = L['TurnTitleShip']
            code = [0xDD, 0x21, L['Slot7'] & 0xFF, L['Slot7'] >> 8, 0xDD, 0x66, 0x24, 0xDD, 0x6E, 0x23, 0xE5, 0xFD,
                    0xE1, 0x3E, self.roll, 0x32, L['TurnRates'] & 0xFF, L['TurnRates'] >> 8, 0x3E, self.pitch,
                    0xC3, (t + 20) & 0xFF, (t + 20) >> 8]
            self.call_stub(code)
        else:
            self.turn_all_faces()
        self.pictures += 1
        return back_buffer(m)

    def turn_all_faces(self):
        """the same turn, but DrawShip with FaceVisibility answered 'all visible' (a patched copy of its first
        instruction: fill FaceVisible with $FF and return)"""
        L, m = self.L, self.mem
        fv = L['FaceVisibility']
        saved = bytes(m[fv:fv + 12])
        tab = L['FaceVisible']
        # LD HL,FaceVisible / LD B,16 / loop: LD (HL),$FF / INC HL / DJNZ loop / RET
        m[fv:fv + 11] = bytes([0x21, tab & 0xFF, tab >> 8, 0x06, 0x10, 0x36, 0xFF, 0x23, 0x10, 0xFB, 0xC9])
        t = L['TurnTitleShip']
        code = [0xDD, 0x21, L['Slot7'] & 0xFF, L['Slot7'] >> 8, 0xDD, 0x66, 0x24, 0xDD, 0x6E, 0x23, 0xE5, 0xFD,
                0xE1, 0x3E, self.roll, 0x32, L['TurnRates'] & 0xFF, L['TurnRates'] >> 8, 0x3E, self.pitch,
                0xC3, (t + 20) & 0xFF, (t + 20) >> 8]
        self.call_stub(code)
        m[fv:fv + 12] = saved


if __name__ == '__main__':
    import time
    t = time.time()
    s = Ship(8)
    pics = [s.step() for _ in range(5)]
    print('5 pictures in %.2f s; lit pixels' % (time.time() - t), [sum(map(sum, p)) for p in pics])
