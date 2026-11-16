#!/usr/bin/env python3
"""The code images of Enduro Racer's tape, cut from the original TZX for kit/mkgame.py's part files (work/parts/):

    python3 tools/parts.py [ORIG.tzx]      # default: orig/EnduroRacer.tzx.zip's "Enduro Racer.tzx"

    basic1-5ccb.bin   the first BASIC "enduro" (205 bytes at PROG $5CCB)
    basic2-5ccb.bin   the second BASIC "end2" (1770 bytes at PROG $5CCB)
    loader-fca3.bin   the loader's plain view $FCA3-$FFBF (tools/speedlock2.py plain)
    tail-ff63.bin     $FF63-$FF86 as blocks 12 and 14 load it (tools/mktape.py --decode)
    game-5b00.bin     $5B00-$FFFF at the entry $8000, from the tape alone: every `sl` block decoded, Mover's LDDR run,
                      $5B40-$5BC7 zero (no block loads them); checked against case.json's image when it exists
    loading.scr       the loading screen (block 6)
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import mktape      # noqa: E402
import speedlock2  # noqa: E402
import tzxblocks   # noqa: E402

SHIFT = 0x5E0      # Mover: LDDR $5BC4-$FA1F to $61A4-$FFFF


def original():
    if len(sys.argv) > 1:
        return open(sys.argv[1], 'rb').read()
    with zipfile.ZipFile(os.path.join(CASE, 'orig', 'EnduroRacer.tzx.zip')) as z:
        return z.read('Enduro Racer.tzx')


def main():
    out = os.path.join(CASE, 'work', 'parts')
    os.makedirs(out, exist_ok=True)
    blocks = list(tzxblocks.parse(original()))
    rom = [b['data'] for b in blocks if b['kind'] == 'standard']
    basic1, basic2 = rom[1][1:-1], rom[3][1:-1]
    loader = speedlock2.plain(speedlock2.from_basic(basic2))
    keys = mktape.Keys(loader)
    mem = bytearray(0x10000)
    pure = iter(b for b in blocks if b['kind'] == 'pure data')
    for n, w in mktape.lines(os.path.join(CASE, 'src', 'tape', 'tape.txt')):
        if w[0] != 'sl':
            continue
        zero, one, last, pause, dest, src, mode, fresh = mktape.sl_args(w)
        p = mktape.decode(keys, dest, next(pure)['data'], mode, fresh)
        mem[dest:dest + len(p)] = p
    tail = bytes(mem[0xFF63:0xFF87])
    screen = bytes(mem[0x4000:0x5B00])
    game = bytearray(mem)
    game[0x5BC4 + SHIFT:0x10000] = mem[0x5BC4:0xFA20]
    files = {'basic1-5ccb.bin': basic1, 'basic2-5ccb.bin': basic2, 'loader-fca3.bin': loader,
             'tail-ff63.bin': tail, 'game-5b00.bin': bytes(game[0x5B00:]), 'loading.scr': screen}
    for name, data in files.items():
        open(os.path.join(out, name), 'wb').write(data)
        print('work/parts/%s: %d bytes' % (name, len(data)))
    entry = os.path.join(CASE, 'work', 'stage1', 'images', 'entry.cpu.bin')
    if os.path.exists(entry):
        e = open(entry, 'rb').read()
        diff = [a for a in range(0x5B00, 0x10000) if e[a] != game[a]]
        print('game-5b00.bin against work/stage1/images/entry.cpu.bin (c1 frame 11646 T 14544): %s'
              % ('identical' if not diff else '%d bytes differ, first $%04X' % (len(diff), diff[0])))
    return 0


if __name__ == '__main__':
    sys.exit(main())
