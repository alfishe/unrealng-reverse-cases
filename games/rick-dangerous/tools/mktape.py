#!/usr/bin/env python3
"""Write the tape of Rick Dangerous from the built parts, as orig/RickDangerous.tzx.zip's "Rick Dangerous.tzx"
holds it (tools/build.sh):

    python3 tools/mktape.py src/tape/tape.txt OUT.tzx BUILD_DIR
    python3 tools/mktape.py --orig OUT.tzx                         # the original TZX, unchanged

The manifest (src/tape/tape.txt) lists the TZX blocks in order; its header says the format. The standard blocks are
written as the ROM's SA-BYTES would (flag, bytes, XOR). The turbo blocks are Bleepload's: each payload is taken
plain from a built file and enciphered by tools/bleepload.py (group 1: the key, made from the key page and Rick1;
groups 2 and 3: the high byte of the address), then framed with its number, address and tail.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bleepload  # noqa: E402


def std(pause, flag, data):
    body = bytes([flag]) + data
    body += bytes([bleepload.xor_all(body)])
    return bytes([0x10]) + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def turbo(timing, pilots, pause, data):
    pilot, sync1, sync2, zero, one, last = timing
    head = b''.join(v.to_bytes(2, 'little') for v in (pilot, sync1, sync2, zero, one, pilots))
    return bytes([0x11]) + head + bytes([last]) + pause.to_bytes(2, 'little') + len(data).to_bytes(3, 'little') + data


def num(text):
    return int(text[1:], 16) if text.startswith('$') else int(text)


def read(build, item, length=None):
    """FILE (all of it), or FILE@ORG:ADDR (length bytes from ADDR of FILE, whose first byte is at ORG; hex)"""
    name, _, where = item.partition('@')
    data = open(os.path.join(build, name), 'rb').read()
    if not where:
        return data
    org, addr = (int(x, 16) for x in where.split(':'))
    out = data[addr - org:addr - org + length]
    if len(out) != length:
        sys.exit(f'{item}: {len(out)} bytes, not {length}')
    return out


def tape(manifest, build):
    out = bytearray()
    timing = key = None
    filler = 8                      # Rick1's first N (`$FF15`)
    for n, line in enumerate(open(manifest), 1):
        line = line.split('#', 1)[0].strip() if not line.lstrip().startswith('text') else line.strip()
        if not line:
            continue
        kind, *f = line.split()
        if kind == 'tzx':
            major, minor = (int(x) for x in f[0].split('.'))
            out += b'ZXTape!\x1a' + bytes([major, minor])
        elif kind == 'text':
            text = line.split(None, 1)[1].encode('ascii')
            out += bytes([0x30, len(text)]) + text
        elif kind == 'header':
            pause, typ, name, length, p1, p2 = f
            size = len(read(build, length[1:])) if length.startswith('@') else num(length)
            p2 = size if p2 == '=' else num(p2)
            hdr = bytes([num(typ)]) + name.encode('ascii').ljust(10) + size.to_bytes(2, 'little') + \
                num(p1).to_bytes(2, 'little') + p2.to_bytes(2, 'little')
            out += std(num(pause), 0x00, hdr)
        elif kind == 'data':
            out += std(num(f[0]), 0xFF, b''.join(read(build, x) for x in f[1:]))
        elif kind == 'group':
            text = line.split(None, 1)[1].encode('ascii')
            out += bytes([0x21, len(text)]) + text
        elif kind == 'group-end':
            out += bytes([0x22])
        elif kind == 'tone':
            out += bytes([0x12]) + num(f[0]).to_bytes(2, 'little') + num(f[1]).to_bytes(2, 'little')
        elif kind == 'pause':
            out += bytes([0x20]) + num(f[0]).to_bytes(2, 'little')
        elif kind == 'turbo':
            timing = [num(x) for x in f]
        elif kind == 'key':
            key = bleepload.key(read(build, f[0]), read(build, f[1]))
        elif kind == 'g1':
            pilots, pause, number, dest, item, fill, jump = f
            dest, fill = num(dest), bytes.fromhex(fill)
            if len(fill) != filler:
                sys.exit(f'{manifest}:{n}: the filler is {len(fill)} bytes; the previous block\'s checksum asks {filler}')
            payload = bleepload.group1_cipher(read(build, item, 256), dest, key)
            block = bleepload.group1_block(num(number), dest, payload, fill, num(jump))
            filler = bleepload.next_filler(block)
            out += turbo(timing, num(pilots), num(pause), bleepload.turbo_data(block))
        elif kind == 'g23':
            group, pilots, pause, number, dest, end, go, item = f
            dest = num(dest)
            payload = bleepload.group23_cipher(read(build, item, 256), dest)
            block = bleepload.group23_block(num(group), num(number), dest, payload, num(end), num(go))
            out += turbo(timing, num(pilots), num(pause), bleepload.turbo_data(block))
        else:
            sys.exit(f'{manifest}:{n}: cannot read: {line}')
    return bytes(out)


def main():
    if len(sys.argv) == 3 and sys.argv[1] == '--orig':
        open(sys.argv[2], 'wb').write(bleepload.original_tzx())
        return
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    open(sys.argv[2], 'wb').write(tape(sys.argv[1], sys.argv[3]))


if __name__ == '__main__':
    main()
