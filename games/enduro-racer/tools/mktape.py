#!/usr/bin/env python3
"""Write Enduro Racer's TZX from a block list and the files the build makes, or read the original back through the
same list (docs/03-build-and-load.md 3.1).

    python3 tools/mktape.py LIST.txt OUT.tzx BUILD_DIR             # write
    python3 tools/mktape.py LIST.txt --decode ORIG.tzx OUT_DIR      # the plain bytes of every `sl` block

The list (src/tape/tape.txt), one TZX block a line:

    version MAJOR MINOR                      the TZX header
    group TEXT / group-end                   $21 / $22
    header PAUSE program NAME FILE LINE P2   a $10 ROM header: flag $00, type 0, NAME, the length of FILE, LINE, P2
                                             (the program's length without its variables)
    rom PAUSE SOURCE                         a $10 ROM block: flag $FF, the bytes, the XOR checksum
    tone PULSE COUNT                         a $12 pure tone
    pulses P,P,...                           a $13 pulse sequence
    sl ZERO ONE LAST PAUSE DEST SOURCE MODE [fresh]
                                             a $14 pure data block the SpeedLock 2 loader stores at DEST: each plain
                                             byte p is on the tape as ((p - a) & 255) ^ k, k and a the operands of
                                             the loader's store `LD A,k / XOR L / ADD A,a`: Store at $FE04 for
                                             every byte but the last; MODE `last`: the last byte by StoreLast at
                                             $FE3C; MODE `check`: every byte by $FE04 and a check byte after them,
                                             not stored, which makes the XOR of every tape byte since the last
                                             `fresh` block 0 (the loader XORs each byte into H, and the end checks
                                             H = 0); `fresh`: H starts at 0 (a block LoadBlock $FD47 reads after
                                             its own leader and sync). A block whose bytes land on $FE04-$FE08 or
                                             $FE3C-$FE40 changes the keys for the bytes after them, as the loader's
                                             own code does.

A SOURCE is `hex:BYTES`, `FILE` (in BUILD_DIR), `FILE:LO:HI` (hex offsets, HI exclusive) or `FILE@ORG:LO:HI`
(addresses of a file that starts at ORG). The loader's keys at the start are its own bytes, from BUILD_DIR's
loader.bin ($FCA3-$FFBF, src/loader/loader.asm). The method is R-Type's tools/mktape.py (SpeedLock 7 stores bytes
the same way), with Enduro Racer's store addresses, check and blocks.
"""
import os
import shlex
import sys

LOADER_ORG = 0xFCA3
STORES = {'body': 0xFE04, 'last': 0xFE3C}


def u16(v):
    return v.to_bytes(2, 'little')


def xor(data):
    x = 0
    for b in data:
        x ^= b
    return x


class Keys:
    """the loader's two stores at $FE04-$FE08 and $FE3C-$FE40, as the blocks rewrite them"""

    def __init__(self, loader):
        self.m = {}
        for at in STORES.values():
            for i in range(5):
                self.m[at + i] = loader[at + i - LOADER_ORG]
        self.h = 0                   # the loader's H: the XOR of the tape bytes since the last fresh block

    def k(self, which):
        at = STORES[which]
        assert self.m[at] == 0x3E and self.m[at + 2] == 0xAD and self.m[at + 3] == 0xC6, \
            'mktape: the store at $%04X is no LD A,k / XOR L / ADD A,a' % at
        return self.m[at + 1], self.m[at + 4]

    def store(self, addr, p):
        if addr in self.m:
            self.m[addr] = p


def encode(keys, dest, plain, mode, fresh):
    if fresh:
        keys.h = 0
    out = bytearray()
    for i, p in enumerate(plain):
        k, a = keys.k('last' if mode == 'last' and i == len(plain) - 1 else 'body')
        out.append(((p - a) & 255) ^ k)
        keys.store(dest + i, p)
    keys.h ^= xor(out)
    if mode == 'check':
        out.append(keys.h)
        keys.h = 0
    return bytes(out)


def decode(keys, dest, tape, mode, fresh):
    if fresh:
        keys.h = 0
    data = tape[:-1] if mode == 'check' else tape
    keys.h ^= xor(tape)
    if mode == 'check':
        assert keys.h == 0, 'mktape: the stream before a check byte does not XOR to 0'
    out = bytearray()
    for i, t in enumerate(data):
        k, a = keys.k('last' if mode == 'last' and i == len(data) - 1 else 'body')
        p = ((t ^ k) + a) & 255
        out.append(p)
        keys.store(dest + i, p)
    return bytes(out)


def source(spec, build):
    if spec.startswith('hex:'):
        return bytes.fromhex(spec[4:])
    parts = spec.split(':')
    name, org = parts[0], 0
    if '@' in name:
        name, o = name.split('@')
        org = int(o.lstrip('$'), 16)
    d = open(os.path.join(build, name), 'rb').read()
    if len(parts) == 3:
        lo, hi = int(parts[1].lstrip('$'), 16) - org, int(parts[2].lstrip('$'), 16) - org
        assert 0 <= lo <= hi <= len(d), 'mktape: %s is outside %s' % (spec, name)
        d = d[lo:hi]
    return d


def lines(list_path):
    for n, line in enumerate(open(list_path), 1):
        line = line.split(' #')[0].rstrip('\n').rstrip()
        if not line.strip() or line.startswith('#'):
            continue
        if line.startswith('group '):
            w = line.split(' ', 1)
        else:
            w = shlex.split(line)
        yield n, w


def std(pause, body):
    return b'\x10' + u16(pause) + u16(len(body)) + body


def pure(zero, one, last, pause, data):
    return b'\x14' + u16(zero) + u16(one) + bytes([last]) + u16(pause) + len(data).to_bytes(3, 'little') + data


def sl_args(w):
    zero, one, last, pause = (int(x) for x in w[1:5])
    return zero, one, last, pause, int(w[5].lstrip('$'), 16), w[6], w[7], 'fresh' in w[8:]


def write(list_path, build):
    out = bytearray()
    keys = None
    for n, w in lines(list_path):
        op = w[0]
        if op == 'version':
            out += b'ZXTape!\x1a' + bytes([int(w[1]), int(w[2])])
        elif op == 'group':
            t = w[1].encode('latin-1')
            out += b'\x21' + bytes([len(t)]) + t
        elif op == 'group-end':
            out += b'\x22'
        elif op == 'header':
            pause, kind, name = int(w[1]), w[2], w[3]
            length = len(source(w[4], build))
            body = (bytes([0, {'program': 0}[kind]]) + name.encode('latin-1').ljust(10)[:10] + u16(length)
                    + u16(int(w[5])) + u16(int(w[6])))
            out += std(pause, body + bytes([xor(body)]))
        elif op == 'rom':
            body = b'\xff' + source(w[2], build)
            out += std(int(w[1]), body + bytes([xor(body)]))
        elif op == 'tone':
            out += b'\x12' + u16(int(w[1])) + u16(int(w[2]))
        elif op == 'pulses':
            p = [int(x) for x in w[1].split(',')]
            out += b'\x13' + bytes([len(p)]) + b''.join(u16(x) for x in p)
        elif op == 'sl':
            if keys is None:
                keys = Keys(open(os.path.join(build, 'loader.bin'), 'rb').read())
            zero, one, last, pause, dest, src, mode, fresh = sl_args(w)
            out += pure(zero, one, last, pause, encode(keys, dest, source(src, build), mode, fresh))
        else:
            raise SystemExit(f'{list_path}:{n}: cannot read: {" ".join(w)}')
    return bytes(out)


def decode_tape(list_path, tzx_path, out_dir, loader_path):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import tzxblocks
    blocks = [b for b in tzxblocks.parse(open(tzx_path, 'rb').read())]
    keys = Keys(open(loader_path, 'rb').read())
    os.makedirs(out_dir, exist_ok=True)
    i = 0
    for n, w in lines(list_path):
        if w[0] == 'version':
            continue
        b = blocks[i]
        i += 1
        if w[0] == 'sl':
            zero, one, last, pause, dest, src, mode, fresh = sl_args(w)
            p = decode(keys, dest, b['data'], mode, fresh)
            name = 'sl-%03d-%04X.bin' % (b['index'], dest)
            open(os.path.join(out_dir, name), 'wb').write(p)
            print('%s: %d bytes' % (name, len(p)))


def main():
    a = sys.argv[1:]
    if len(a) == 4 and a[1] == '--decode':
        decode_tape(a[0], a[2], a[3], os.path.join(a[3], 'loader.bin'))
        return 0
    if len(a) != 3:
        print(__doc__)
        return 1
    open(a[1], 'wb').write(write(a[0], a[2]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
