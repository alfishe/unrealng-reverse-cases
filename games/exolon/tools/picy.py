#!/usr/bin/env python3
"""The loading screen's packer and unpacker (the "picy" block, src/tape/picy.asm), both ways.

    python3 tools/picy.py pack SCREEN.scr OUTDIR        # OUTDIR/picy-literals.bin, picy-masks.bin, picy-flags.bin
    python3 tools/picy.py unpack PICY.bin OUT.scr       # the block as the tape holds it (4096 bytes at $8000)
    python3 tools/picy.py check                          # the tape's block: unpack, pack again, the same streams

The format is in src/tape/picy.asm. The packer marks a byte as a repeat whenever it equals the byte before it, so
the three streams follow from the screen alone; the tape's are exactly that (check).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def pack(scr):
    """(literals, masks, flags) of a 6912-byte screen"""
    assert len(scr) == 6912
    lit, masks, flags = bytearray(), bytearray(), bytearray()
    for g in range(len(scr) // 64):
        f = 0
        for k in range(8):
            m = 0
            for j in range(8):
                i = g * 64 + k * 8 + j
                if i and scr[i] == scr[i - 1]:
                    m |= 1 << j
                else:
                    lit.append(scr[i])
            if m:
                f |= 1 << k
                masks.append(m)
        flags.append(f)
    return bytes(lit), bytes(masks), bytes(flags)


def unpack(blk, base=0x8000):
    """The screen and the stream ends, from the block as loaded at base (the unpacker's reading, $8001 + offsets)"""
    entry = 0x8001 - base
    w = lambda o: blk[entry + o] | blk[entry + o + 1] << 8  # noqa: E731
    lit, masks, flags = entry + w(3), entry + w(5), entry + w(7)
    out = bytearray()
    for _ in range(108):
        c = 1
        while c < 256:
            m = 0
            if blk[flags] & c:
                m = blk[masks]
                masks += 1
            b = 1
            while b < 256:
                if out and m & b:
                    out.append(out[-1])
                else:
                    out.append(blk[lit])
                    lit += 1
                b <<= 1
            c <<= 1
        flags += 1
    return bytes(out), dict(literal_end=lit + base, mask_end=masks + base, flag_end=flags + base, border=blk[entry + 9])


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'pack':
        scr = open(sys.argv[2], 'rb').read()
        os.makedirs(sys.argv[3], exist_ok=True)
        for name, data in zip(('literals', 'masks', 'flags'), pack(scr)):
            open(os.path.join(sys.argv[3], 'picy-%s.bin' % name), 'wb').write(data)
    elif cmd == 'unpack':
        scr, info = unpack(open(sys.argv[2], 'rb').read())
        open(sys.argv[3], 'wb').write(scr)
        print(len(scr), {k: (f'${v:04X}' if k != 'border' else v) for k, v in info.items()})
    elif cmd == 'check':
        import image
        blk = image.blocks()[6]['data'][1:-1]
        scr, info = unpack(blk)
        lit, masks, flags = pack(scr)
        ok = blk[0x9E:0x9E + len(lit)] == lit and blk[0x9E + len(lit):0x9E + len(lit) + len(masks)] == masks and \
            blk[0x9E + len(lit) + len(masks):0x9E + len(lit) + len(masks) + len(flags)] == flags
        print(f'picy: {len(lit)} literals, {len(masks)} masks, {len(flags)} flags; the tape\'s streams '
              + ('repacked exactly' if ok else 'DIFFER'))
        return 0 if ok else 1
    else:
        sys.exit(__doc__)
    return 0


if __name__ == '__main__':
    sys.exit(main())
