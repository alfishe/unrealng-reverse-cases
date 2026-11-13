#!/usr/bin/env python3
"""Write the TZX of Myth from a block list and the files the build makes, or read a TZX back through the same
list (docs/03-build-and-load.md).

    python3 tools/mktape.py LIST.txt OUT.tzx BUILD_DIR             # write
    python3 tools/mktape.py LIST.txt --decode ORIG.tzx OUT_DIR      # the plain bytes of every `sl` block

The list (src/tape/tape.txt), one TZX block a line:

    version MAJOR MINOR                      the TZX header
    archive / info ID TEXT / archive-end     a $32 archive info block, one `info` line a field (TEXT latin-1 with
                                             Python escapes: `\r`, `\xA3`)
    text TEXT                                a $30 text block
    group TEXT / group-end                   $21 / $22
    stop                                     a $20 block of 0 ms (stop the tape)
    header PAUSE TYPE NAME FILE [P1 [P2]]    a $10 ROM header: flag $00, TYPE program / bytes, NAME, the length of
                                             FILE (or a number), P1 (LINE or the start), P2 (default the length);
                                             the XOR checksum
    rom PAUSE SOURCE                         a $10 ROM block: flag $FF, the bytes, the XOR checksum
    raw PAUSE SOURCE                         a $10 block of exactly these bytes (flag and check included)
    turbo PILOT SYNC1 SYNC2 ZERO ONE PILOT_PULSES LAST PAUSE $FLAG SOURCE
                                             a $11 turbo block: the flag, the bytes, the XOR checksum
    tone PULSE COUNT                         a $12 pure tone
    pulses P,P,...                           a $13 pulse sequence
    pure ZERO ONE LAST PAUSE SOURCE          a $14 pure data block of these bytes
    sl ZERO ONE LAST PAUSE DEST SOURCE [check]
                                             a $14 block the SpeedLock loader reads into DEST: each plain byte p is
                                             stored on the tape as ((p - a) & 255) ^ k, with k, a the operands of
                                             the loader's store, `LD A,k / XOR L / ADD A,a` at $FDB5 (every byte
                                             but the last) and at $FDE9 (the last byte); `check`: no last-byte
                                             store, every byte by $FDB5 and a check byte after them: the loader
                                             XORs every byte it reads into H and wants 0 at the end, so the check
                                             byte makes the XOR of the `sl` blocks since the last check 0. A block
                                             whose bytes land on $FDB5-$FDED changes the keys for the bytes after
                                             them, as the loader's own code does.

A SOURCE is `hex:BYTES`, `FILE` (in BUILD_DIR), `FILE:LO:HI` (hex offsets, HI exclusive) or `FILE@ORG:LO:HI`
(addresses of a file that starts at ORG), any of them followed by `^NN` (every byte XORed with $NN). The loader's
keys at the start are its own bytes, from BUILD_DIR's chain.bin ($EDE4-$FF25, src/loader/chain.asm). The method is
Battle Command's tools/mktape.py (another SpeedLock 7 tape), with Myth's store addresses and block kinds.
"""
import os
import shlex
import sys

KEY_LO, KEY_HI = 0xFDB5, 0xFDEE      # the two stores' code
KEY_BODY, KEY_LAST = 0xFDB5, 0xFDE9
CHAIN_ORG = 0xEDE4


def u16(v):
    return v.to_bytes(2, 'little')


def xor(data):
    x = 0
    for b in data:
        x ^= b
    return x


class Keys:
    """the loader's store code at $FDB5-$FDED, as the blocks rewrite it"""

    def __init__(self, chain):
        self.m = bytearray(chain[KEY_LO - CHAIN_ORG:KEY_HI - CHAIN_ORG])
        self.h = 0                   # the loader's H: the XOR of the tape bytes since the last check

    def k(self, last):
        o = (KEY_LAST if last else KEY_BODY) - KEY_LO
        assert self.m[o] == 0x3E and self.m[o + 2] == 0xAD and self.m[o + 3] == 0xC6, \
            'mktape: the store at $%04X is no LD A,k / XOR L / ADD A,a' % (KEY_LO + o)
        return self.m[o + 1], self.m[o + 4]

    def store(self, addr, p):
        if KEY_LO <= addr < KEY_HI:
            self.m[addr - KEY_LO] = p


def encode(keys, dest, plain, check):
    out = bytearray()
    for i, p in enumerate(plain):
        k, a = keys.k(last=not check and i == len(plain) - 1)
        out.append(((p - a) & 255) ^ k)
        keys.store(dest + i, p)
    keys.h ^= xor(out)
    if check:
        out.append(keys.h)
        keys.h = 0
    return bytes(out)


def decode(keys, dest, tape, check):
    data = tape[:-1] if check else tape
    keys.h ^= xor(tape)
    if check:
        assert keys.h == 0, 'mktape: the stream before a check byte does not XOR to 0'
    out = bytearray()
    for i, t in enumerate(data):
        k, a = keys.k(last=not check and i == len(data) - 1)
        p = ((t ^ k) + a) & 255
        out.append(p)
        keys.store(dest + i, p)
    return bytes(out)


def source(spec, build):
    spec, _, x = spec.partition('^')
    if x:
        return bytes(b ^ int(x, 16) for b in source(spec, build))
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
        if line.startswith(('text ', 'group ')):
            w = line.split(' ', 1)
        elif line.startswith('info '):
            w = line.split(' ', 2)
        else:
            w = shlex.split(line)
        yield n, w


def std(pause, body):
    return b'\x10' + u16(pause) + u16(len(body)) + body


def pure(zero, one, last, pause, data):
    return b'\x14' + u16(zero) + u16(one) + bytes([last]) + u16(pause) + len(data).to_bytes(3, 'little') + data


def write(list_path, build):
    out = bytearray()
    keys = None
    for n, w in lines(list_path):
        op = w[0]
        if op == 'version':
            out += b'ZXTape!\x1a' + bytes([int(w[1]), int(w[2])])
        elif op == 'text':
            t = w[1].encode('latin-1')
            out += b'\x30' + bytes([len(t)]) + t
        elif op == 'group':
            t = w[1].encode('latin-1')
            out += b'\x21' + bytes([len(t)]) + t
        elif op == 'archive':
            info = []
        elif op == 'info':
            t = w[2].encode('latin-1').decode('unicode_escape').encode('latin-1')
            info.append(bytes([int(w[1]), len(t)]) + t)
        elif op == 'archive-end':
            body = bytes([len(info)]) + b''.join(info)
            out += b'\x32' + u16(len(body)) + body
        elif op == 'turbo':
            pilot, s1, s2, zero, one, pulses, last, pause = (int(x) for x in w[1:9])
            body = bytes([int(w[9].lstrip('$'), 16)]) + source(w[10], build)
            body += bytes([xor(body)])
            out += (b'\x11' + b''.join(u16(x) for x in (pilot, s1, s2, zero, one, pulses)) + bytes([last]) + u16(pause)
                    + len(body).to_bytes(3, 'little') + body)
        elif op == 'group-end':
            out += b'\x22'
        elif op == 'stop':
            out += b'\x20' + u16(0)
        elif op == 'header':
            pause, kind, name = int(w[1]), w[2], w[3]
            length = int(w[4]) if w[4].isdigit() else len(source(w[4], build))
            p1 = int(w[5].lstrip('$'), 16) if len(w) > 5 and w[5].startswith('$') else int(w[5]) if len(w) > 5 else 0
            p2 = int(w[6]) if len(w) > 6 else length
            t = {'program': 0, 'bytes': 3}[kind]
            body = bytes([0, t]) + name.encode('latin-1').ljust(10)[:10] + u16(length) + u16(p1) + u16(p2)
            out += std(pause, body + bytes([xor(body)]))
        elif op == 'rom':
            body = b'\xff' + source(w[2], build)
            out += std(int(w[1]), body + bytes([xor(body)]))
        elif op == 'raw':
            out += std(int(w[1]), source(w[2], build))
        elif op == 'tone':
            out += b'\x12' + u16(int(w[1])) + u16(int(w[2]))
        elif op == 'pulses':
            p = [int(x) for x in w[1].split(',')]
            out += b'\x13' + bytes([len(p)]) + b''.join(u16(x) for x in p)
        elif op == 'pure':
            zero, one, last, pause = (int(x) for x in w[1:5])
            out += pure(zero, one, last, pause, source(w[5], build))
        elif op == 'sl':
            if keys is None:
                keys = Keys(open(os.path.join(build, 'chain.bin'), 'rb').read())
            zero, one, last, pause = (int(x) for x in w[1:5])
            dest = int(w[5].lstrip('$'), 16)
            data = encode(keys, dest, source(w[6], build), len(w) > 7 and w[7] == 'check')
            out += pure(zero, one, last, pause, data)
        else:
            raise SystemExit(f'{list_path}:{n}: cannot read: {" ".join(w)}')
    return bytes(out)


def decode_tape(list_path, tzx_path, out_dir, chain_path):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import tzxblocks
    blocks = [b for b in tzxblocks.parse(open(tzx_path, 'rb').read())]
    keys = Keys(open(chain_path, 'rb').read())
    os.makedirs(out_dir, exist_ok=True)
    i = 0
    for n, w in lines(list_path):
        if w[0] in ('version', 'info', 'archive-end'):
            continue
        b = blocks[i]
        i += 1
        if w[0] == 'sl':
            dest = int(w[5].lstrip('$'), 16)
            p = decode(keys, dest, b['data'], len(w) > 7 and w[7] == 'check')
            name = 'sl-%02d-%04X.bin' % (b['index'], dest)
            open(os.path.join(out_dir, name), 'wb').write(p)
            print('%s: %d bytes' % (name, len(p)))


def main():
    a = sys.argv[1:]
    if len(a) == 4 and a[1] == '--decode':
        decode_tape(a[0], a[2], a[3], os.path.join(a[3], 'chain.bin'))
        return 0
    if len(a) != 3:
        print(__doc__)
        return 1
    open(a[1], 'wb').write(write(a[0], a[2]))
    return 0


if __name__ == '__main__':
    sys.exit(main())
