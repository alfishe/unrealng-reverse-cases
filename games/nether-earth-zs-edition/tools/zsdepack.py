#!/usr/bin/env python3
"""The backward LZ depacker of NEZSEd99.B (the copy the loader moves to $5B00), reimplemented.

  zsdepack.py IMAGE64K SRC_END DST_END STOP --out OUT [--far-bits 11]
  zsdepack.py block IMAGE64K AT --out OUT     (a self-extracting block loaded at AT: its own parameters)

Reads the bit stream backwards from SRC_END (the byte at SRC_END first, bits from bit 7 down), writes backwards
from DST_END until the write pointer drops to STOP (the depacker's `LD HL,STOP / SBC HL,DE / JR C`). Tokens:

  0                      literal: 1 byte (8 bits)
  1 1 b                  match length 2 + b (2..3)
  1 0 1 bb               match length 4 + bb (4..7)
  1 0 0 1 bbbb           bbbb < 15: match length 8 + bbbb (8..22); bbbb = 15: a literal run of 14 + 5 bits bytes
  1 0 0 0 (8 bits)*      match length 23 + the bytes, a byte $FF adds the next one
  then the offset:  1 -> 11 bits (10 in the second block: the depacker's LD B,n) + $221;  0 1 -> 5 bits + 1;  0 0 -> 9 bits + $21
  the match copies LDDR from DE + offset (exactly: HL = DE + offset) down to DE.
"""
import argparse


class Bits:
    def __init__(self, mem, end):
        self.mem, self.p, self.b, self.e = mem, end, 1, 0   # B' = 1: the first call loads a byte

    def bit(self):
        self.b -= 1
        if self.b == 0:
            self.b = 8
            self.e = self.mem[self.p]
            self.p -= 1
        c = (self.e >> 7) & 1
        self.e = (self.e << 1) & 0xFF
        return c

    def bits(self, n):
        v = 0
        for _ in range(n):
            v = (v << 1) | self.bit()
        return v


def depack(mem, src_end, dst_end, stop, far_bits=11, log=None):
    bs = Bits(mem, src_end)
    de = dst_end
    while True:
        if not bs.bit():
            mem[de] = bs.bits(8); de -= 1
            if log is not None: log.append(('lit', 1))
        else:
            run = None
            if bs.bit():
                n = 2 + bs.bits(1)
            elif bs.bit():
                n = 4 + bs.bits(2)
            elif bs.bit():
                v = bs.bits(4)
                if v + 8 < 0x17:
                    n = 8 + v
                else:
                    run = 14 + bs.bits(5)
            else:
                n = 0x17
                while True:
                    v = bs.bits(8)
                    n += v
                    if v != 0xFF:
                        break
            if run is not None:
                for _ in range(run):
                    mem[de] = bs.bits(8); de -= 1
                if log is not None: log.append(('lit', run))
            else:
                if bs.bit():
                    off = 0x221 + bs.bits(far_bits)
                elif bs.bit():
                    off = 1 + bs.bits(5)
                else:
                    off = 0x21 + bs.bits(9)
                hl = de + off
                for _ in range(n):
                    mem[de] = mem[hl]; de -= 1; hl -= 1
                if log is not None: log.append(('match', n, off))
        if de < stop:   # SBC HL,DE with HL = STOP-1... the loop runs while DE > STOP - 1
            break
    return de, bs.p


def block_params(mem, at):
    """The parameters of a self-extracting block loaded at AT: its 22-byte set-up (copy the depacker to $5B00,
    DE = AT, HL = AT + $B0, BC = the packed length, RET into the copy, whose LDIR moves the stream down to AT) and
    the operands of the depacker copy ($5B00 + n = AT + $16 + n)"""
    w = lambda a: mem[a] | mem[a + 1] << 8
    d = at + 0x16
    assert mem[at:at + 3] == bytes([0x11, 0x00, 0x5B]) and mem[d:d + 2] == bytes([0xED, 0xB0]), 'not a block'
    return dict(length=w(at + 0x13), src_end=w(d + 0x06), dst_end=w(d + 0x0B), far_bits=mem[d + 0x6C],
                stop=w(d + 0x78), jump=w(d + 0x81))


def unpack_block(mem, at):
    """Runs a block as the CPU does: the LDIR of the stream to AT, then the depacker; returns its parameters"""
    p = block_params(mem, at)
    mem[at:at + p['length']] = bytes(mem[at + 0xB0:at + 0xB0 + p['length']])
    p['de'], p['src_left'] = depack(mem, p['src_end'], p['dst_end'], p['stop'] + 1, p['far_bits'])
    return p


def main():
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'block':
        # zsdepack.py block IMAGE64K AT --out OUT
        mem = bytearray(open(sys.argv[2], 'rb').read())
        p = unpack_block(mem, int(sys.argv[3], 16))
        print(' '.join(f'{k} {v:04X}' if k != 'far_bits' else f'{k} {v}' for k, v in p.items()))
        open(sys.argv[sys.argv.index('--out') + 1], 'wb').write(mem)
        return
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('image')
    p.add_argument('src_end')
    p.add_argument('dst_end')
    p.add_argument('stop', help='the first output byte (the loop ends when DE = STOP - 1)')
    p.add_argument('--out', required=True)
    p.add_argument('--far-bits', type=int, default=11)
    a = p.parse_args()
    mem = bytearray(open(a.image, 'rb').read())
    de, sp = depack(mem, int(a.src_end, 16), int(a.dst_end, 16), int(a.stop, 16), a.far_bits)
    print(f'end: DE {de:04X} (stops below {int(a.stop, 16):04X}), source pointer {sp:04X}')
    open(a.out, 'wb').write(mem)


if __name__ == '__main__':
    main()
