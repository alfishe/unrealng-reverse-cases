#!/usr/bin/env python3
"""UltraXOR v1.2 (Paracels), the envelope of A_NETHER.B: decrypt it, encrypt it, list its layers.

    python3 tools/ultraxor.py decrypt CIPHER.bin PLAIN.bin   the file as on the disk -> its plain form
    python3 tools/ultraxor.py encrypt PLAIN.bin CIPHER.bin   the plain form -> the file as on the disk
    python3 tools/ultraxor.py layers PLAIN.bin               the layers: where each runs, what it decrypts, its key

The file (2816 bytes, 11 sectors) loads at PROG = $5D3B. Its line 0 holds the code; the entry is $5D97 (line 1:
CLOSE # USR Eternity, the variable Eternity = 23959). The entry clears the screen and copies the file's
$5DE0-$8815 (2614 bytes) to $7705 and jumps there: the text "UltraXOR v1.2 (c) PARACELS", then DI and LD R,A with
A = $2A. From there on everything is a function of the code alone: interrupts are off, R starts at $2A and counts
one per opcode fetch (a prefix DD / FD / ED is a fetch of its own), so every R value the layers read is fixed by the
number of instructions run before it, which the plain code itself fixes.

Each layer is a loop: HL = the next layer's first byte, B (or BC) = its length; per byte LD A,R and a few
operations on A with registers that the loop changes (DEC C, INC D, the halves of IX and IY, B, H, L), then
XOR (HL) and LD (HL),A. The key byte K never depends on the data (the loop has no branch on it and reads (HL) only
in XOR (HL)); the decrypted byte is cipher XOR K. So encryption is the same chain run on the plain bytes: the code
runs as it will once decrypted, each LD (HL),A gives K, and the disk byte is plain XOR K (a byte two loops
decrypt takes both keys). 78 loops: the first ($7721, plain in the file) decrypts the second ($7757), each one the
next, from its own DJNZ displacement byte on; the last one ($7FCA, BC = $0152) decrypts $7FE9-$813A, which holds a
jump to $8000: the TR-DOS reader (copied to $5D3F) that reads the loader.

The interpreter below runs the Z80 instructions the layers use (any other one is an error, so a change of the
plain code that needs more shows at once). It models what the key depends on: the registers, R, and the Z flag
for the last layer's JR NZ; no other flag is read by the layers.
"""
import sys

PROG = 0x5D3B
COPY_FROM, COPY_TO, COPY_LEN = 0x5DE0, 0x7705, 0x0A36  # the entry's LDIR
START = 0x7721  # DI; LD A,$2A; LD R,A
STOP = 0x8000   # the TR-DOS reader's copy: no more decryption from here
SIZE = 2816


class Z80:
    def __init__(self, mem, encrypt=False):
        self.m = mem
        self.encrypt = encrypt
        self.cipher = {}
        self.writes = []  # (writer PC, address, key)
        self.a = self.b = self.c = self.d = self.e = self.h = self.l = 0
        self.ix = self.iy = self.sp = 0
        self.alt = [0, 0, 0]
        self.r = 0
        self.z = False
        self.pc = START

    def fetch(self):
        v = self.m[self.pc]
        self.pc = (self.pc + 1) & 0xFFFF
        return v

    def m1(self):
        self.r = (self.r & 0x80) | ((self.r + 1) & 0x7F)
        return self.fetch()

    def word(self):
        lo = self.fetch()
        return lo | self.fetch() << 8

    def disp(self):
        d = self.fetch()
        return d - 256 if d & 0x80 else d

    def setz(self, v):
        v &= 0xFF
        self.z = v == 0
        return v

    def step(self):
        pc = self.pc
        op = self.m1()
        if op == 0x00: pass
        elif op == 0x01: v = self.word(); self.b, self.c = v >> 8, v & 0xFF
        elif op == 0x06: self.b = self.fetch()
        elif op == 0x07: self.a = ((self.a << 1) | (self.a >> 7)) & 0xFF
        elif op == 0x0B: v = (self.b << 8 | self.c) - 1 & 0xFFFF; self.b, self.c = v >> 8, v & 0xFF
        elif op == 0x0C: self.c = self.setz(self.c + 1)
        elif op == 0x0D: self.c = self.setz(self.c - 1)
        elif op == 0x0E: self.c = self.fetch()
        elif op == 0x0F: self.a = ((self.a >> 1) | (self.a << 7)) & 0xFF
        elif op == 0x10:
            d = self.disp()
            self.b = (self.b - 1) & 0xFF
            if self.b: self.pc = (self.pc + d) & 0xFFFF
        elif op == 0x11: v = self.word(); self.d, self.e = v >> 8, v & 0xFF
        elif op == 0x14: self.d = self.setz(self.d + 1)
        elif op == 0x15: self.d = self.setz(self.d - 1)
        elif op == 0x1C: self.e = self.setz(self.e + 1)
        elif op == 0x1D: self.e = self.setz(self.e - 1)
        elif op == 0x20:
            d = self.disp()
            if not self.z: self.pc = (self.pc + d) & 0xFFFF
        elif op == 0x21: v = self.word(); self.h, self.l = v >> 8, v & 0xFF
        elif op == 0x23: v = (self.h << 8 | self.l) + 1 & 0xFFFF; self.h, self.l = v >> 8, v & 0xFF
        elif op == 0x2F: self.a ^= 0xFF
        elif op == 0x31: self.sp = self.word()
        elif op == 0x3E: self.a = self.fetch()
        elif op == 0x77: self.store(pc)
        elif op == 0x78: self.a = self.b
        elif op in (0x80, 0x81, 0x84): self.a = self.setz(self.a + self.reg(op & 7))
        elif op in (0x90, 0x91, 0x94, 0x95): self.a = self.setz(self.a - self.reg(op & 7))
        elif op in (0xA8, 0xA9, 0xAC, 0xAD): self.a = self.setz(self.a ^ self.reg(op & 7))
        elif op == 0xAE: self.a = self.setz(self.a ^ self.load())
        elif op == 0xB1: self.a = self.setz(self.a | self.c)
        elif op == 0xC3: self.pc = self.word()
        elif op == 0xD9:
            bc, de, hl = self.b << 8 | self.c, self.d << 8 | self.e, self.h << 8 | self.l
            (bc2, de2, hl2), self.alt = self.alt, [bc, de, hl]
            self.b, self.c, self.d, self.e, self.h, self.l = bc2 >> 8, bc2 & 255, de2 >> 8, de2 & 255, hl2 >> 8, hl2 & 255
        elif op == 0xF3: pass  # DI (they are off from here on)
        elif op == 0xF9: self.sp = self.h << 8 | self.l
        elif op == 0xEE: self.a = self.setz(self.a ^ self.fetch())
        elif op in (0xDD, 0xFD): self.index(op, pc)
        elif op == 0xED: self.ed(pc)
        else:
            raise RuntimeError('$%04X: opcode $%02X is not one the layers use' % (pc, op))

    def reg(self, n):
        return (self.b, self.c, self.d, self.e, self.h, self.l, None, self.a)[n]

    def load(self):
        a = self.h << 8 | self.l
        return 0 if self.encrypt else self.m[a]  # encryption: XOR (HL) gives the key alone

    def store(self, pc):
        a = self.h << 8 | self.l
        self.writes.append((pc, a, self.a ^ (0 if self.encrypt else self.m[a])))
        if self.encrypt:
            # the memory keeps the plain bytes (the code runs as decrypted); a byte two layers decrypt ($7FE9, the
            # last layer's JR NZ displacement, is also the end of the layer before) takes both keys
            self.cipher[a] = self.cipher.get(a, self.m[a]) ^ self.a
        else:
            self.m[a] = self.a

    def index(self, prefix, pc):
        op = self.m1()
        name = 'ix' if prefix == 0xDD else 'iy'
        x = getattr(self, name)
        hi, lo = x >> 8, x & 0xFF
        if op == 0x21: x = self.word()
        elif op == 0x24: hi = self.setz(hi + 1); x = hi << 8 | lo
        elif op == 0x25: hi = self.setz(hi - 1); x = hi << 8 | lo
        elif op == 0x2C: lo = self.setz(lo + 1); x = hi << 8 | lo
        elif op == 0x2D: lo = self.setz(lo - 1); x = hi << 8 | lo
        elif op == 0x84: self.a = self.setz(self.a + hi)
        elif op == 0x94: self.a = self.setz(self.a - hi)
        elif op == 0xAC: self.a = self.setz(self.a ^ hi)
        elif op == 0xAD: self.a = self.setz(self.a ^ lo)
        elif op == 0xF9: self.sp = x
        else:
            raise RuntimeError('$%04X: $%02X $%02X is not one the layers use' % (pc, prefix, op))
        setattr(self, name, x)

    def ed(self, pc):
        op = self.m1()
        if op == 0x44: self.a = self.setz(-self.a)
        elif op == 0x47: pass  # LD I,A: no effect on the key
        elif op == 0x4F: self.r = self.a  # LD R,A: R is A after the instruction's own fetches
        elif op == 0x5F: self.a = self.r; self.z = self.a == 0  # LD A,R: R after both fetches
        elif op in (0x4E, 0x56, 0x5E, 0x6E): pass  # IM 0/1, IM 1, IM 2, IM 0 (undocumented): no effect here
        elif op < 0x40 or op > 0x7F and op & 0xE4 != 0xA0: pass  # ED NOP (8 T, two fetches: R + 2)
        else:
            raise RuntimeError('$%04X: $ED $%02X is not one the layers use' % (pc, op))


def run(data, encrypt):
    assert len(data) == SIZE, 'A_NETHER.B is %d bytes, not %d' % (SIZE, len(data))
    mem = bytearray(0x10000)
    mem[PROG:PROG + SIZE] = data
    mem[COPY_TO:COPY_TO + COPY_LEN] = mem[COPY_FROM:COPY_FROM + COPY_LEN]  # the entry's LDIR
    cpu = Z80(mem, encrypt)
    n = 0
    while cpu.pc != STOP:
        cpu.step()
        n += 1
        if n > 10_000_000:
            raise RuntimeError('no end at $%04X' % STOP)
    out = bytearray(data)
    for a in range(COPY_TO, COPY_TO + COPY_LEN):
        v = cpu.cipher.get(a, mem[a]) if encrypt else mem[a]
        out[a - COPY_TO + COPY_FROM - PROG] = v
    return bytes(out), cpu


def layers(plain):
    """[(loop PC, first byte decrypted, last, count, the key's operations)] from the writes of a decryption run"""
    _, cpu = run(plain, True)
    out = []
    for pc, a, k in cpu.writes:
        if out and out[-1][0] == pc and out[-1][2] == a - 1:
            out[-1][2] = a
            out[-1][3] += 1
        else:
            out.append([pc, a, a, 1])
    return out


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ('decrypt', 'encrypt', 'layers'):
        sys.exit(__doc__)
    data = open(sys.argv[2], 'rb').read()
    if sys.argv[1] == 'layers':
        for i, (pc, lo, hi, n) in enumerate(layers(data)):
            print('%2d  LD (HL),A at $%04X  decrypts $%04X-$%04X  %4d bytes' % (i, pc, lo, hi, n))
        return
    out, cpu = run(data, sys.argv[1] == 'encrypt')
    if sys.argv[1] == 'encrypt':  # the check: the result decrypts to the plain form
        back, _ = run(out, False)
        assert back == data, 'the encrypted file does not decrypt to the plain form'
    open(sys.argv[3], 'wb').write(out)


if __name__ == '__main__':
    main()
