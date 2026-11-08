#!/usr/bin/env python3
"""The Softlock stream of a side: the turbo block and the pure-data blocks after it, decoded the way the loader at
`$FF00` reads them (each byte arrives least significant bit first, so a TZX byte is the loader's byte bit-reversed).

    python3 tools/softlock.py [--side A]          # the chunk table: TZX block, length, load address
    python3 tools/softlock.py --screen OUT.scr    # the loading screen (the turbo block's first 6912 bytes)

The stream: the turbo block (flag `$FF`, then `$1C00` bytes for `$4000-$5BFF`: the loading screen and the chunk reader
at `$5B00`), then chunk after chunk: a 4-byte header (length word, address word) read by the chunk reader, the data read by the
loader's byte loop, and one check byte (the XOR of the header, the data and the check byte is 0). The TZX splits
header and data into id-14 blocks of their own; the signal is one, with no pilot between the chunks.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402


def rev(b):
    return int('{:08b}'.format(b)[::-1], 2)


def stream(side='A'):
    """[(tzx index, kind, bytes as the loader sees them)] of the Softlock group"""
    out = []
    for b in E.tape_blocks(side):
        if b['id'] in (0x11, 0x14):
            out.append((b['index'], 'turbo' if b['id'] == 0x11 else 'pure', bytes(rev(x) for x in b['data'])))
    return out


def chunks(side='A'):
    """[(header block, data block, length, address, data)]: the chunks the reader at `$5B00` loads"""
    s = stream(side)
    res = []
    for k in range(1, len(s) - 1, 2):
        (ih, _, h), (idt, _, d) = s[k], s[k + 1]
        if len(h) != 4:
            break
        ln, ad = h[0] | h[1] << 8, h[2] | h[3] << 8
        res.append((ih, idt, ln, ad, d[:ln]))
    return res


def screen(side='A'):
    return stream(side)[0][2][1:1 + 6912]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--side', default='A')
    p.add_argument('--screen')
    a = p.parse_args()
    if a.screen:
        open(a.screen, 'wb').write(screen(a.side))
        return
    t = stream(a.side)[0]
    print(f'TZX {t[0]:2}  turbo  {len(t[2]) - 2:5} bytes  $4000-$5BFF  (flag ${t[2][0]:02X})')
    for ih, idt, ln, ad, d in chunks(a.side):
        print(f'TZX {ih:2}+{idt:2}  chunk {ln:5} bytes  ${ad:04X}-${(ad + ln - 1) & 0xFFFF:04X}')


if __name__ == '__main__':
    sys.exit(main())
