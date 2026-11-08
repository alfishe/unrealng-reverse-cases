#!/usr/bin/env python3
"""Write Side A's TZX from the sources: the block list src/tape/elite-tzx.txt and the files the build assembled.

    python3 tools/mktape.py LIST.txt OUT.tzx BUILD_DIR [--rom 48.rom]

BUILD_DIR holds basic-plain.bin (src/tape/basic.asm), the Softlock pieces (src/tape/softlock.asm), game.bin
($5B00-$FFA7, src/game/game.asm), lenslok.bin ($C000-$C7FF, src/lenslok/lenslok.asm) and res/ (src/res). Two steps
are not assembly (docs/03-build-and-load.md):
- the stub's tail is encrypted with the screen key: the inverse of StubDecrypt (3.3);
- the plain memory of the two 16 KB chunks is encrypted over $6049-$D0A8: the inverse of Decrypt (3.6), its key the
  loading screen from $5AFF down and the 48K ROM. The plain memory is game.bin with the Lenslok at $C000-$C7FF (the
  kickoff copies the game over it later), zeros at $BE00-$BFFF (where the kickoff builds the squares) and, at
  $5C00-$6047, src/res/tape/master-memory.bin (bytes the last ROM block covers before anything reads them).
The ROM is unreal-ng's data/rom/48.rom unless --rom names one.
"""
import argparse
import os
import shlex
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import image as I  # noqa: E402

PROG = 0x5CCB
STUB_TAIL = 0x5DD0
SCREEN_KEY = 0xCA4E
GAME_LO = 0x5B00


def rev(b):
    return int('{:08b}'.format(b)[::-1], 2)


def xor(data):
    x = 0
    for b in data:
        x ^= b
    return x


def encrypt_stub(plain):
    """the inverse of StubDecrypt: from STUB_TAIL, pairs, until a plain pair ends in $48"""
    out = bytearray(plain)
    key, chain, p = SCREEN_KEY, 0x32, STUB_TAIL - PROG
    while True:
        for half in (key & 0xFF, key >> 8):
            v = plain[p]
            out[p] = ((v - chain) & 0xFF) ^ half
            chain = v
            p += 1
            key = (key + 1) & 0xFFFF
        if chain == 0x48:
            return bytes(out)


def plain_memory(build, rom):
    """the 64 KB as the chunks carry it, encrypted over $6049-$D0A8"""
    game = open(os.path.join(build, 'game.bin'), 'rb').read()
    m = bytearray(0x10000)
    m[GAME_LO:GAME_LO + len(game)] = game
    m[0xC000:0xC800] = open(os.path.join(build, 'lenslok.bin'), 'rb').read()
    m[0xBE00:0xC000] = bytes(0x200)
    m[0x5C00:0x6048] = open(os.path.join(build, 'res', 'tape', 'master-memory.bin'), 'rb').read()
    m[0xD0BA:0x10000] = bytes(0x10000 - 0xD0BA)       # the chunks end at $DBFF; past $D0B9 they carry zeros
    key = bytearray(0x10000)
    key[0:0x4000] = rom
    key[0x4000:0x5B00] = open(os.path.join(build, 'res', 'screens', 'loading.scr'), 'rb').read()
    return I.encrypt(m, key)


def source(spec, build, rom, tape):
    if spec.startswith('zeros:'):
        return bytes(int(spec[6:]))
    if spec.startswith('rom:'):
        _, lo, n = spec.split(':')
        return rom[int(lo, 16):int(lo, 16) + int(n)]
    if spec.startswith('tape:'):
        _, lo, hi = spec.split(':')
        return bytes(tape[int(lo, 16):int(hi, 16)])
    if spec.startswith('filler:'):
        _, n, off, name = spec.split(':')
        d = bytearray(int(n))
        piece = open(os.path.join(build, name), 'rb').read()
        d[int(off):int(off) + len(piece)] = piece
        return bytes(d)
    name, _, n = spec.partition(':')
    d = open(os.path.join(build, name), 'rb').read()
    return d[:int(n)] if n else d


def u16(v):
    return v.to_bytes(2, 'little')


def std_block(pause, body):
    return b'\x10' + u16(pause) + u16(len(body)) + body


def pure_block(zero, one, last, pause, data):
    return b'\x14' + u16(zero) + u16(one) + bytes([last]) + u16(pause) + len(data).to_bytes(3, 'little') + \
        bytes(rev(b) for b in data)


def write(list_path, build, rom):
    tape = None
    out = bytearray()
    files = {}

    def read(name):
        if name not in files:
            d = open(os.path.join(build, name), 'rb').read()
            if name == 'basic-plain.bin':
                d = encrypt_stub(d)
            files[name] = d
        return files[name]

    for line in open(list_path):
        line = line.rstrip('\n')
        if not line.strip() or line.startswith('#'):
            continue
        w = shlex.split(line) if not line.startswith('group ') else line.split(' ', 1)
        op = w[0]
        if op == 'version':
            out += b'ZXTape!\x1a' + bytes([int(w[1]), int(w[2])])
        elif op == 'text':
            t = line[5:].encode('ascii')
            out += b'\x30' + bytes([len(t)]) + t
        elif op == 'group':
            t = w[1].encode('ascii')
            out += b'\x21' + bytes([len(t)]) + t
        elif op == 'group-end':
            out += b'\x22'
        elif op == 'header':
            pause, kind, name, line_no, vars_off, f = int(w[1]), w[2], w[3], int(w[4]), int(w[5]), w[6]
            assert kind == 'program'
            body = bytes([0, 0]) + name.encode('ascii').ljust(10)[:10] + u16(len(read(f))) + u16(line_no) + \
                u16(vars_off)                             # flag 0, type 0 (a program)
            body += bytes([xor(body)])
            out += std_block(pause, body)
        elif op == 'data':
            d = read(w[2])
            if len(w) > 3:
                lo, hi = int(w[3], 16) - GAME_LO, int(w[4], 16) - GAME_LO
                d = d[lo:hi]
            body = b'\xff' + d
            out += std_block(int(w[1]), body + bytes([xor(body)]))
        elif op == 'turbo':
            pilot, s1, s2, zero, one, pulses, last, pause = (int(x) for x in w[1:9])
            body = b'\xff' + b''.join(read(f) for f in w[9:])
            body += bytes([xor(body)])
            out += b'\x11' + b''.join(u16(x) for x in (pilot, s1, s2, zero, one, pulses)) + bytes([last]) + \
                u16(pause) + len(body).to_bytes(3, 'little') + bytes(rev(b) for b in body)
        elif op == 'chunk':
            zero, one, last = (int(x) for x in w[1:4])
            addr = int(w[4].lstrip('$'), 16)
            if w[5].startswith('tape:') and tape is None:
                tape = plain_memory(build, rom)
            d = source(w[5], build, rom, tape)
            head = u16(len(d)) + u16(addr)
            out += pure_block(zero, one, last, 0, head)
            out += pure_block(zero, one, last, 0, d + bytes([xor(head + d)]))
        elif op == 'pure':
            zero, one, last, pause = (int(x) for x in w[1:5])
            out += pure_block(zero, one, last, pause, bytes.fromhex(w[5]))
        else:
            raise SystemExit(f'{list_path}: cannot read: {line}')
    return bytes(out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('list')
    p.add_argument('out')
    p.add_argument('build')
    p.add_argument('--rom')
    a = p.parse_args()
    rom = open(a.rom or os.path.join(E.K.unreal_root(), 'data', 'rom', '48.rom'), 'rb').read()
    open(a.out, 'wb').write(write(a.list, a.build, rom))


if __name__ == '__main__':
    sys.exit(main())
