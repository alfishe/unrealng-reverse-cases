#!/usr/bin/env python3
"""Write a TZX of standard-speed blocks from a block list (src/tape/exolon-tzx.txt gives the format). From the Zynaps
case, with the header form "type" added for the Hewson loader's type-42 headers.

    python3 tools/tzx.py LIST.txt OUT.tzx [DIR]      # the files the list names are read from DIR (default: .)
"""
import os
import sys


def std_block(pause, flag, data):
    body = bytes([flag]) + data
    x = 0
    for b in body:
        x ^= b
    body += bytes([x])
    return b'\x10' + pause.to_bytes(2, 'little') + len(body).to_bytes(2, 'little') + body


def rom_header(kind, name, length, p1, p2):
    return bytes([kind]) + name.encode('ascii').ljust(10)[:10] + length.to_bytes(2, 'little') + \
        p1.to_bytes(2, 'little') + p2.to_bytes(2, 'little')


def write(list_path, folder):
    out, info = bytearray(), []
    version = None

    def flush_info():
        if info:
            body = bytes([len(info)]) + b''.join(bytes([i, len(t)]) + t for i, t in info)
            out.extend(b'\x32' + len(body).to_bytes(2, 'little') + body)
            info.clear()

    for line in open(list_path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        kind, rest = line.split(None, 1)
        if kind == 'version':
            major, minor = rest.split('.')
            version = bytes([int(major), int(minor)])
            continue
        if kind == 'info':
            tid, text = rest.split(None, 1)
            info.append((int(tid, 16), text.encode('latin-1')))
            continue
        flush_info()
        f = rest.split()
        data = lambda name: open(os.path.join(folder, name), 'rb').read()  # noqa: E731
        if kind == 'header' and f[1] == 'program':
            body = data(f[4])
            out += std_block(int(f[0]), 0, rom_header(0, f[2], len(body), int(f[3]), len(body)))
        elif kind == 'header' and f[1] == 'bytes':
            body = data(f[5])
            out += std_block(int(f[0]), 0, rom_header(3, f[2], len(body), int(f[3]), int(f[4])))
        elif kind == 'header' and f[1] == 'type':
            body = data(f[6])
            out += std_block(int(f[0]), 0, rom_header(int(f[2]), f[3], len(body), int(f[4]), int(f[5])))
        elif kind == 'data':
            out += std_block(int(f[0]), 0xFF, data(f[1]))
        else:
            sys.exit(f'{list_path}: cannot read: {line}')
    flush_info()
    return b'ZXTape!\x1a' + version + bytes(out)


if __name__ == '__main__':
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    open(sys.argv[2], 'wb').write(write(sys.argv[1], sys.argv[3] if len(sys.argv) == 4 else '.'))
