#!/usr/bin/env python3
"""Write a side of the tape of Rick Dangerous 2 from the built parts, as orig/RickDangerous2.tzx.zip holds it
(tools/build.sh):

    python3 tools/mktape.py src/tape/side-a.txt OUT.tzx BUILD_DIR
    python3 tools/mktape.py --orig A|B OUT.tzx                       # the original side, unchanged

A manifest (src/tape/side-a.txt, side-b.txt) lists the TZX blocks in order, one line a block (docs/03-build-and-load.md
3.1):

    tzx MAJOR.MINOR                       the file header ("ZXTape!", $1A, the version)
    archive ID TEXT                       one item of an archive info block ($32); consecutive lines make one block;
                                          "\\r" in TEXT is a carriage return; the text is written in Latin-1 (the "£")
    header PAUSE TYPE NAME LENGTH P1 P2   a standard ($10) ROM header block: flag $00, the type (0 Program, 3 Bytes),
                                          the name padded with spaces to 10 ("_" for a space), the length ("@FILE":
                                          the file's), P1 and P2
    data PAUSE ITEM [ITEM ...]            a standard ($10) block the ROM's LD-BYTES reads: flag $FF, the items' bytes,
                                          the XOR checksum (the XOR of all is 0)
    reversed PAUSE ITEM [ITEM ...]        a standard ($10) block the game's loader $FF2D reads: flag $FF, the items'
                                          bytes and a checksum chosen so that the XOR of all is $FF, then every byte
                                          (flag and checksum too) with its bits in reversed order

An ITEM is a file of BUILD_DIR, with a prefix that transforms it:

    FILE                  the file as built
    loader:FILE           the loader's cipher: every byte from offset 11 ($FF0B) XOR $5C (tools/parts.py)
    maps:FILE             a level at $A800 with its maps' last 768 bytes enciphered as $894E deciphers them
    zeros:N               N zero bytes (side A block 6's $FD00-$FEFD, the room the entry code fills with the IM 2
                          table)

PAUSE is the pause after the block in ms, as the original has it.
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import image as I  # noqa: E402
import parts  # noqa: E402


def std(pause, body):
    return bytes([0x10]) + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def xor(data):
    x = 0
    for b in data:
        x ^= b
    return x


def item(build, name):
    kind, _, rest = name.partition(':')
    if not rest:
        return open(os.path.join(build, name), 'rb').read()
    if kind == 'zeros':
        return bytes(int(rest))
    data = open(os.path.join(build, rest), 'rb').read()
    if kind == 'loader':
        return parts.crypt_loader(data)
    if kind == 'maps':
        return parts.crypt_maps(data)
    sys.exit(f'mktape: cannot read the item {name}')


def tape(manifest, build):
    out = bytearray()
    info = []

    def flush():
        if info:
            body = bytes([len(info)]) + b''.join(bytes([i, len(t)]) + t for i, t in info)
            out.extend(bytes([0x32]) + len(body).to_bytes(2, 'little') + body)
            info.clear()

    for line in open(manifest, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        kind, *f = line.split()
        if kind != 'archive':
            flush()
        if kind == 'tzx':
            major, minor = (int(x) for x in f[0].split('.'))
            out += b'ZXTape!\x1a' + bytes([major, minor])
        elif kind == 'archive':
            text = line.split(None, 2)[2].replace('\\r', '\r')
            info.append((int(f[0]), text.encode('latin-1')))
        elif kind == 'header':
            pause, typ, name, length, p1, p2 = f
            n = len(item(build, length[1:])) if length.startswith('@') else int(length)
            hdr = bytes([0, int(typ)]) + name.replace('_', ' ').encode('ascii').ljust(10) + \
                n.to_bytes(2, 'little') + int(p1).to_bytes(2, 'little') + int(p2).to_bytes(2, 'little')
            out += std(int(pause), hdr + bytes([xor(hdr)]))
        elif kind == 'data':
            body = bytes([0xFF]) + b''.join(item(build, n) for n in f[1:])
            out += std(int(f[0]), body + bytes([xor(body)]))
        elif kind == 'reversed':
            body = bytes([0xFF]) + b''.join(item(build, n) for n in f[1:])
            body += bytes([xor(body) ^ 0xFF])
            out += std(int(f[0]), body.translate(I.REV))
        else:
            sys.exit(f'{manifest}: cannot read: {line}')
    flush()
    return bytes(out)


def main():
    if len(sys.argv) == 4 and sys.argv[1] == '--orig':
        with zipfile.ZipFile(os.path.join(CASE, 'orig', 'RickDangerous2.tzx.zip')) as z:
            open(sys.argv[3], 'wb').write(z.read(I.SIDES[sys.argv[2]]))
        return
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    open(sys.argv[2], 'wb').write(tape(sys.argv[1], sys.argv[3]))


if __name__ == '__main__':
    main()
