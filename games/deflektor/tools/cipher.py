#!/usr/bin/env python3
"""The cipher of Deflektor's main block and its move: the game's image and the head's code become the bytes the
tape loads at `$5C00-$DDEF` (tools/build.sh), and the check that the tape's own code turns them back.

    python3 tools/cipher.py encrypt HEAD.bin GAME.bin KEYS.txt OUT.bin   # OUT: $5C00-$DDEF as loaded (33264 bytes)
    python3 tools/cipher.py check TAPE.tzx GAME.bin                      # load, decrypt, move: the entry == GAME

HEAD.bin is src/head assembled (496 bytes): BlockHead `$5C00-$5C26`, then the chain `$7B52-$7CFF` as it stands when
it has run, then the mover `$FD00-$FD1A`; GAME.bin is src/game assembled, `$6000-$DFFF`. The tape's block runs
(src/head/head.ann):

1. BlockHead `$5C00` moves `$5C27-$DDEF` up by `$1F2B` to `$7B52-$FD1A` (LDDR) and enters the chain at `$7B52`.
2. The chain: a sum of all memory, then 30 layers (18 XorLayers, 12 sum layers). XorLayer `$7B84` decrypts the B
   bytes after its call: each plain byte is `(17 * previous + C) XOR cipher` (the first "previous" is the key A),
   then `A = last + (RET)` and C is written over the byte at RET, the call's return address, and the code goes on
   at RET + 1. A sum layer (`$7BD2`, `$7C15`, `$7C54`) adds B and every (C + 1)-th byte of `$4000-$FFFF` to A and writes C at RET the same way.
3. FinalSum `$7CA6`: a 16-bit sum of `$4000-$FFFF` is the key of the last layer, which decrypts `$7D00-$FD19` a word
   at a time: H = L, HL += BC (C = `$29`, B the last plain high byte), plain low = cipher XOR L, L = plain low,
   plain high = cipher XOR H. The last word, `$FD18`, gives the jump: `JP (HL)` to `$FD18`'s word + `$7A3D` = `$FD00`.
4. The mover `$FD00` copies `$7D00-$FCFF` to `$6000-$DFFF` and jumps to the game at `$8382`.

The keys are sums over memory that hold the cipher itself (and the loading screen, the loader), so they are not
computed here: src/head/keys.txt lists them as the original tape gives them, with the bytes the chain overwrites.
`encrypt` applies the layers backwards with those keys. A changed game or head makes the original's sums wrong:
`check` runs the tape's own code (tools/tapesim.py) from the BASIC to the entry and says where it stops agreeing.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tapesim  # noqa: E402  (re-runs this tool under the SkoolKit venv when needed)

MOVE = 0x1F2B                      # BlockHead's LDDR distance
LOADED, LOADED_END = 0x5C00, 0xDDF0
HEAD_END = 0x5C27                  # BlockHead's own bytes stay at $5C00
CHAIN, MOVED_END = 0x7B52, 0xFD1B  # the moved block
CIPHER16, CIPHER16_END = 0x7D00, 0xFD1A
GAME, GAME_END = 0x6000, 0xE000
ENTRY = 0x8382
MOVER = 0xFD00
HEAD_SIZE = (HEAD_END - LOADED) + (CIPHER16 - CHAIN) + (MOVED_END - MOVER)


def read_keys(path):
    plants, layers, operands, key16 = [], [], [], None
    for line in open(path):
        line = line.split('#', 1)[0].split()
        if not line:
            continue
        kind = line[0]
        if kind == 'plant':
            plants.append((int(line[1], 16), int(line[2])))
        elif kind in ('xor', 'sum'):
            layers.append((kind, int(line[1], 16), int(line[2]), int(line[3]), int(line[4]), int(line[5])))
        elif kind == 'operand':
            operands.append((int(line[1], 16), int(line[2])))
        elif kind == 'key16':
            key16 = int(line[1], 16)
        else:
            sys.exit('cipher: %s: cannot read %r' % (path, kind))
    return plants, layers, operands, key16


def encrypt16(mem, key):
    """FinalSum's layer backwards: the plain words at $7D00-$FD19 become the cipher (the state runs on the plain)."""
    h, l = key >> 8, key & 0xFF
    b, c = h, 0x29
    for de in range(CIPHER16, CIPHER16_END, 2):
        h = l
        hl = ((h << 8 | l) + (b << 8 | c)) & 0xFFFF
        h, l = hl >> 8, hl & 0xFF
        plo, phi = mem[de], mem[de + 1]
        mem[de] = plo ^ l
        mem[de + 1] = phi ^ h
        l, b = plo, phi


def encrypt(head, game, keys):
    plants, layers, operands, key16 = keys
    mem = bytearray(0x10000)
    n1, n2 = HEAD_END - LOADED, CIPHER16 - CHAIN
    mem[LOADED:HEAD_END] = head[:n1]
    mem[CHAIN:CIPHER16] = head[n1:n1 + n2]
    mem[MOVER:MOVED_END] = head[n1 + n2:]
    mem[CIPHER16:CIPHER16 + GAME_END - GAME] = game
    encrypt16(mem, key16)
    for addr, byte in operands:
        mem[addr] = byte
    for kind, ret, b, c, a, byte in reversed(layers):
        if kind == 'xor':
            n = b or 256
            plain = [a] + [mem[ret + 1 + k] for k in range(n)]
            for k in range(n):
                mem[ret + 1 + k] = plain[k + 1] ^ ((17 * plain[k] + c) & 0xFF)
        mem[ret] = byte
    for addr, byte in plants:
        mem[addr] = byte
    out = bytearray(mem[LOADED:HEAD_END])
    out += mem[CHAIN:MOVED_END]
    assert len(out) == LOADED_END - LOADED
    return bytes(out)


def check(tzx, game):
    sys.path.insert(0, HERE)
    import tzxblocks
    blocks = list(tzxblocks.parse(open(tzx, 'rb').read()))
    basic = blocks[1]['data'][1:-1]
    turbo = blocks[2]
    mem, sim, loads, pairs = tapesim.decode(basic, tapesim.bits_of(turbo['data'], turbo['timing']['last']))
    print('cipher check: the loader took %d loads, %d pulse pairs' % (len(loads), pairs))
    tapesim.run_to(mem, sim, 0xFD00)
    if mem[CIPHER16:CIPHER16 + GAME_END - GAME] != game:
        bad = [a for a in range(GAME_END - GAME) if mem[CIPHER16 + a] != game[a]]
        sys.exit('cipher check: the chain decrypts %d bytes wrong, the first at $%04X (a changed source moves the '
                 'sums: src/head/keys.txt)' % (len(bad), GAME + bad[0]))
    tapesim.run_to(mem, sim, ENTRY)
    if mem[GAME:GAME_END] != game:
        sys.exit('cipher check: the mover left a different image')
    print('cipher check: the tape decrypts and moves to the game at $%04X: identical to %s' % (ENTRY, os.path.basename(gpath)))


if __name__ == '__main__':
    a = sys.argv[1:]
    if len(a) == 5 and a[0] == 'encrypt':
        head = open(a[1], 'rb').read()
        game = open(a[2], 'rb').read()
        if len(head) != HEAD_SIZE or len(game) != GAME_END - GAME:
            sys.exit('cipher: HEAD.bin must be %d bytes, GAME.bin $6000-$DFFF' % HEAD_SIZE)
        open(a[4], 'wb').write(encrypt(head, game, read_keys(a[3])))
    elif len(a) == 3 and a[0] == 'check':
        gpath = a[2]
        check(a[1], open(gpath, 'rb').read())
    else:
        sys.exit(__doc__)
