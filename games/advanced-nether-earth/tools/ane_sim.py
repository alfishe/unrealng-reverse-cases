#!/usr/bin/env python3
"""The SCL's load run without the emulator: SkoolKit's Simulator on a Pentagon 128 with a Beta disk interface.

    VENV/bin/python tools/ane_sim.py [--keys FRAME:KEY ...] [--until HEX ...] [--frames N] [--dump OUT]
                                     [--log FILE] [--depacks DIR]

The machine: SkoolKit's Simulator (128 K paging through $7FFD), the 48 K BASIC ROM (`48.rom`) and TR-DOS 5.04T
(`trdos504t.rom`) from unreal-ng's `data/rom`, paged as the Beta interface does (in on an M1 fetch from
$3D00-$3DFF with the 48 K ROM selected, out on one from $4000 up), and a WD1793 model at the ports $1F, $3F, $5F,
$7F, $FF over the SCL laid out as a TR-DOS disk (80 tracks, 2 sides, 16 sectors of 256 bytes; the files from
logical track 1 sector 0 in the order of the catalogue, as TR-DOS would write them). The frame is 71680 T
(Pentagon), the interrupt 32 T long.

The run starts where TR-DOS leaves the BASIC A_NETHER.B: the program at PROG = $5D3B, the variables after it, and
the ROM's USR call of line 1 (`CLOSE # USR Eternity`, the variable Eternity = $5D97) with BC = $5D97; the system
variables TR-DOS uses ($5CF4 the next track / sector) as after reading the file's 11 sectors.

Logs (--log): every sector the FDC read (logical track, sector, the address the INI loop wrote it to), every $7FFD
write, every run of the HRUM depacker (its stream start, output start and end: --depacks DIR writes each output).
"""
import argparse
import os
import sys

from skoolkit.simulator import Simulator
from skoolkit.pagingtracer import Memory
from skoolkit import simutils as su
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
SCL = os.path.join(CASE, 'orig', 'Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl')
ROM_DIR = os.environ.get('UNREAL_ROMS') or os.path.join(toolpaths.unreal_ng(required=False) or 'unreal-ng', 'data', 'rom')
FRAME = 71680
INT_LEN = 32
KEYS = {  # half row (address line), bit
    'cs': (0, 0), 'z': (0, 1), 'x': (0, 2), 'c': (0, 3), 'v': (0, 4),
    'a': (1, 0), 's': (1, 1), 'd': (1, 2), 'f': (1, 3), 'g': (1, 4),
    'q': (2, 0), 'w': (2, 1), 'e': (2, 2), 'r': (2, 3), 't': (2, 4),
    '1': (3, 0), '2': (3, 1), '3': (3, 2), '4': (3, 3), '5': (3, 4),
    '0': (4, 0), '9': (4, 1), '8': (4, 2), '7': (4, 3), '6': (4, 4),
    'p': (5, 0), 'o': (5, 1), 'i': (5, 2), 'u': (5, 3), 'y': (5, 4),
    'enter': (6, 0), 'l': (6, 1), 'k': (6, 2), 'j': (6, 3), 'h': (6, 4),
    'space': (7, 0), 'ss': (7, 1), 'm': (7, 2), 'n': (7, 3), 'b': (7, 4),
}


def scl_files(data):
    """[(name, ext, start, length, sectors, bytes)] of an SCL"""
    assert data[:8] == b'SINCLAIR'
    n = data[8]
    off = 9 + 14 * n
    files = []
    for i in range(n):
        e = data[9 + 14 * i:23 + 14 * i]
        s = e[13]
        files.append((e[:8].decode('latin-1'), chr(e[8]), int.from_bytes(e[9:11], 'little'),
                      int.from_bytes(e[11:13], 'little'), s, data[off:off + 256 * s]))
        off += 256 * s
    return files


def disk_image(files):
    """the files as TR-DOS lays them out: track 0 the catalogue (not modelled: zeros), the data from track 1"""
    disk = bytearray(16 * 256)
    for f in files:
        disk += f[5]
    disk += bytes(256 * 16 * 160 - len(disk))
    return disk


class FDC:
    """WD1793 as the Beta interface wires it; every command completes at once, data on demand"""

    def __init__(self, disk, log):
        self.disk = disk
        self.log = log
        self.track = self.sector = self.data = 0
        self.cyl = 0
        self.status = 0
        self.intrq = False
        self.buf = b''
        self.pos = 0
        self.dest = None  # where the INI loop puts the bytes (for the log)
        self.system = 0
        self.multi = False
        self.cur = None

    def side(self):
        return 0 if self.system & 0x10 else 1

    def command(self, v, t):
        if v & 0xF0 == 0xD0:  # force interrupt
            self.buf, self.pos = b'', 0
            self.status = 0x20 | (4 if self.cyl == 0 else 0)
            self.intrq = bool(v & 0x0F)
            return
        if v & 0x80 == 0:  # type I
            if v & 0xF0 == 0:
                self.cyl = 0
                self.track = 0
            elif v & 0xF0 == 0x10:
                self.cyl = self.data
                self.track = self.data
            else:
                step = 1 if v & 0x60 == 0x40 else -1 if v & 0x60 == 0x60 else 0
                self.cyl = max(0, self.cyl + step)
                if v & 0x10:
                    self.track = self.cyl
            self.status = 0x20 | (4 if self.cyl == 0 else 0)
            self.intrq = True
            return
        if v & 0xE0 == 0x80:  # read sector
            self.multi = bool(v & 0x10)
            self.start_read(t)
            return
        if v & 0xE0 == 0xA0:  # write sector
            self.multi = bool(v & 0x10)
            self.log.append(('write', self.cyl, self.side(), self.sector, t))
            self.wbuf = bytearray()
            self.status = 0x03
            self.intrq = False
            return
        if v & 0xF0 == 0xC0:  # read address
            self.buf = bytes([self.cyl, self.side(), 1, 1, 0, 0])
            self.pos = 0
            self.status = 0x03
            self.intrq = False
            return
        raise RuntimeError('FDC command $%02X' % v)

    def start_read(self, t):
        if not 1 <= self.sector <= 16 or self.track != self.cyl:
            self.status = 0x10
            self.intrq = True
            return
        logical = (self.cyl * 2 + self.side()) * 16 + self.sector - 1
        self.buf = self.disk[logical * 256:logical * 256 + 256]
        self.pos = 0
        self.cur = logical
        self.status = 0x03
        self.intrq = False
        self.log.append(('read', logical // 16, logical % 16, t))

    def read_data(self):
        if self.pos < len(self.buf):
            v = self.buf[self.pos]
            self.pos += 1
            if self.pos == len(self.buf):
                if self.multi and self.cur is not None and self.sector < 16:
                    self.sector += 1
                    self.start_read(0)
                else:
                    self.status = 0
                    self.intrq = True
            return v
        return self.data

    def write_data(self, v):
        if self.status & 1 and hasattr(self, 'wbuf'):
            self.wbuf.append(v)
            if len(self.wbuf) == 256:
                logical = (self.cyl * 2 + self.side()) * 16 + self.sector - 1
                self.disk[logical * 256:logical * 256 + 256] = self.wbuf
                del self.wbuf
                self.status = 0
                self.intrq = True
            return
        self.data = v

    def drq(self):
        return self.status & 1 and (self.pos < len(self.buf) or hasattr(self, 'wbuf'))


class Machine:
    def __init__(self, scl=SCL, keys=()):
        self.files = scl_files(open(scl, 'rb').read())
        self.disk = disk_image(self.files)
        self.mem = Memory(machine='128K')
        self.rom48 = list(open(os.path.join(ROM_DIR, '48.rom'), 'rb').read())
        self.trdos = list(open(os.path.join(ROM_DIR, 'trdos504t.rom'), 'rb').read())
        self.mem.roms = (self.mem.roms[0], self.rom48)
        self.dos = False
        self.mem.out7ffd(0x10)
        self.sim = Simulator(self.mem, {'SP': 0x5FFF}, config={'fast_ldir': False, 'fast_djnz': False})
        self.sim.frame_duration = FRAME
        self.sim.set_tracer(self)
        self.log = []
        self.fdc = FDC(self.disk, self.log)
        self.ay = [0] * 16
        self.ay_reg = 0
        self.keys = sorted(keys)  # [(frame, frames held, key)]
        self.depacks = []
        self.watch = {}

    # ports
    def write_port(self, registers, port, value, *a):
        lo = port & 0xFF
        if self.dos and lo in (0x1F, 0x3F, 0x5F, 0x7F, 0xFF):
            t = registers[su.T]
            if lo == 0x1F:
                self.fdc.command(value, t)
            elif lo == 0x3F:
                self.fdc.track = value
            elif lo == 0x5F:
                self.fdc.sector = value
            elif lo == 0x7F:
                self.fdc.write_data(value)
            else:
                self.fdc.system = value
            return
        if port & 0x8002 == 0:
            self.log.append(('7ffd', registers[su.PC], value, registers[su.T] // FRAME))
            self.mem.out7ffd(value)
            if self.dos:
                self.mem.memory[0] = self.trdos
            return
        if port & 0xC002 == 0xC000:
            self.ay_reg = value & 15
            return
        if port & 0xC002 == 0x8000:
            self.ay[self.ay_reg] = value
            return

    def read_port(self, registers, port):
        lo = port & 0xFF
        if self.dos and lo in (0x1F, 0x3F, 0x5F, 0x7F, 0xFF):
            f = self.fdc
            if lo == 0x1F:
                f.intrq = False
                s = f.status
                if s & 0x20 == 0x20 or s & 0x80 == 0 and not s & 1:
                    # type I: the index pulse for 4 ms of every 200 ms
                    if registers[su.T] % 700000 < 14000:
                        s |= 2
                if f.status & 1 and not f.drq():
                    s &= ~2
                return s
            if lo == 0x3F:
                return f.track
            if lo == 0x5F:
                return f.sector
            if lo == 0x7F:
                if f.pos == 0 and f.buf and self.log and self.log[-1][0] == 'read' and len(self.log[-1]) == 4:
                    hl = registers[su.H] * 256 + registers[su.L]
                    self.log[-1] = self.log[-1] + ('%04X' % hl, '%02X' % (self.mem.o7ffd & 7), registers[su.PC])
                return f.read_data()
            return (0x80 if f.intrq else 0) | (0x40 if f.drq() else 0) | 0x3F
        if lo & 1 == 0:
            frame = registers[su.T] // FRAME
            v = 0x1F
            for (f0, n, key) in self.keys:
                if f0 <= frame < f0 + n:
                    row, bit = KEYS[key]
                    if not (port >> 8) & (1 << row):
                        v &= ~(1 << bit)
            return v | 0xE0
        if port & 0xC002 == 0xC000:
            return self.ay[self.ay_reg]
        if lo == 0x1F:
            return 0  # Kempston: nothing pressed
        return 0xFF

    def poke(self, addr, data):
        for i, b in enumerate(data):
            self.mem[addr + i] = b

    def peek(self, addr, n):
        return bytes(self.mem[addr + i] for i in range(n))

    def boot_basic(self):
        f = self.files[0]
        prog = 0x5D3B
        self.poke(prog, f[5][:f[2]])
        vars_ = prog + f[3]
        e_line = prog + f[2]
        for a, w in {0x5C53: prog, 0x5C4B: vars_, 0x5C59: e_line, 0x5C61: e_line + 2, 0x5C63: e_line + 2,
                     0x5C65: e_line + 2, 0x5C3D: 0x5FFE}.items():
            self.poke(a, w.to_bytes(2, 'little'))
        self.poke(0x5CF4, bytes([11, 1]))  # sector 11 of track 1: the sector after the BASIC's 11
        r = self.sim.registers
        r[su.B], r[su.C] = 0x5D, 0x97
        r[su.IYh], r[su.IYl] = 0x5C, 0x3A
        r[su.SP] = 0x5FF0
        r[su.PC] = 0x5D97
        r[su.IM] = 1
        r[su.I] = 0x3F

    def page(self, pc):
        if pc >= 0x4000:
            if self.dos:
                self.dos = False
                self.mem.memory[0] = self.rom48 if self.mem.o7ffd & 0x10 else self.mem.roms[0]
        elif 0x3D00 <= pc <= 0x3DFF and not self.dos and self.mem.o7ffd & 0x10:
            self.dos = True
            self.mem.memory[0] = self.trdos

    def run(self, stop=(), frames=None, hook=None):
        """run until PC is in stop or the frame count passes frames; return the PC"""
        sim = self.sim
        r = sim.registers
        ops = sim.opcodes
        mem = self.mem
        next_int = (r[su.T] // FRAME + 1) * FRAME
        end_t = None if frames is None else frames * FRAME
        stop = set(stop)
        watch = self.watch
        page = self.page
        while True:
            pc = r[su.PC]
            if pc in stop:
                return pc
            if pc < 0x4000 or self.dos:
                page(pc)
            if pc in watch:
                watch[pc](self)
            if hook:
                hook(self, pc)
            prev = pc
            if r[su.HALT] and r[su.IFF] and r[su.T] + 4 < next_int:
                skipped = (next_int - r[su.T]) // 4
                r[su.T] += 4 * skipped
                r[su.R] = (r[su.R] & 0x80) | ((r[su.R] + skipped) & 0x7F)
            else:
                ops[mem[pc]]()
            t = r[su.T]
            if t >= next_int:
                if t < next_int + INT_LEN and r[su.IFF]:
                    if r[su.HALT]:
                        r[su.PC] = (r[su.PC] + 1) & 0xFFFF
                        r[su.HALT] = 0
                    sim.accept_interrupt(r, mem, prev)
                    if r[su.PC] < 0x4000:
                        page(0x4000)  # the interrupt never pages TR-DOS in
                if t >= next_int + INT_LEN or not r[su.IFF] or True:
                    next_int += FRAME
                    while next_int + INT_LEN <= t:
                        next_int += FRAME
            if end_t is not None and t >= end_t:
                return r[su.PC]

    def dump(self, out):
        """the 64 K view and the eight banks"""
        with open(out + '-cpu.bin', 'wb') as f:
            f.write(self.peek(0, 0x10000))
        for b in range(8):
            with open(out + '-bank%d.bin' % b, 'wb') as f:
                f.write(bytes(self.mem.banks[b]))


DEPACKER = bytes.fromhex('edb81603')  # LDDR; LD D,3: the HRUM 3.5 depacker's first bytes


def depack_hook(outdir):
    """a hook for Machine.run: log every HRUM run (entry: stream start, output start; end: output end) and write
    each output to OUTDIR/dNN-ADDR-bankB.bin"""
    state = {}

    def hook(m, pc):
        if m.mem[pc] == 0xED and pc + 0x5F not in state and m.peek(pc, 4) == DEPACKER:  # LDDR repeats at its PC
            r = m.sim.registers
            sp = m.peek(pc + 5, 2)
            state[pc + 0x5F] = (r[su.xD] * 256 + r[su.xE], sp[0] | sp[1] << 8, r[su.T] // FRAME)
            hl, bc = r[su.H] * 256 + r[su.L], r[su.B] * 256 + r[su.C]
            m.log.append(('depacker', '%04X' % pc, 'moves %04X-%04X' % (hl - bc + 1, hl), 'to end %04X' % (r[su.D] * 256 + r[su.E]),
                          'bank %d' % (m.mem.o7ffd & 7)))
            if outdir:
                os.makedirs(outdir, exist_ok=True)
                n = len([e for e in m.log if e[0] == 'depacker'])
                with open(os.path.join(outdir, 's%02d-%04X.bin' % (n - 1, hl - bc + 1)), 'wb') as f:
                    f.write(m.peek(hl - bc + 1, bc))
        elif pc in state:
            start, sp, frame = state.pop(pc)
            r = m.sim.registers
            end = r[su.xD] * 256 + r[su.xE] + 5  # the output pointer is in DE' here; the 5 tail bytes follow
            n = len([e for e in m.log if e[0] == 'depack'])
            m.log.append(('depack', '%04X' % start, '%04X' % end, 'stream %04X' % sp, 'bank %d' % (m.mem.o7ffd & 7),
                          'frame %d' % frame))
            if outdir:
                os.makedirs(outdir, exist_ok=True)
                # the bytes once the tail is copied: read them when the depacker returns, here from the output
                tail = m.peek(pc + 0x13, 5)
                data = m.peek(start, end - 5 - start) + tail
                with open(os.path.join(outdir, 'd%02d-%04X-bank%d.bin' % (n, start, m.mem.o7ffd & 7)), 'wb') as f:
                    f.write(data)
    return hook


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--scl', default=SCL)
    p.add_argument('--keys', nargs='*', default=[], help='FRAME:KEY[:FRAMES held, default 10]')
    p.add_argument('--until', nargs='*', default=[], help='hex PCs: stop at the first of them')
    p.add_argument('--frames', type=int)
    p.add_argument('--dump', help='write OUT-cpu.bin and OUT-bankN.bin at the stop')
    p.add_argument('--log')
    p.add_argument('--depacks', help='write each depacker output here')
    args = p.parse_args()
    keys = []
    for k in args.keys:
        parts = k.split(':')
        keys.append((int(parts[0]), int(parts[2]) if len(parts) > 2 else 10, parts[1]))
    m = Machine(args.scl, keys)
    m.boot_basic()
    pc = m.run([int(u, 16) for u in args.until], args.frames, depack_hook(args.depacks))
    r = m.sim.registers
    print('stop at $%04X, frame %d + %d T, $7FFD = $%02X' % (pc, r[su.T] // FRAME, r[su.T] % FRAME, m.mem.o7ffd))
    if args.log:
        with open(args.log, 'w') as f:
            for e in m.log:
                f.write(' '.join(str(x) for x in e) + '\n')
    if args.dump:
        m.dump(args.dump)


if __name__ == '__main__':
    main()
