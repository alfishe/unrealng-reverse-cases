#!/usr/bin/env python3
"""The parts of side 1 that are not the game image, cut from the original tape (SkoolKit's Python for the chain).

    $SKOOLKIT_VENV/bin/python tools/parts.py [--out work/parts] [--orig build/orig]

Writes into --out:
  basic-5ccb.bin       the BASIC "BATTLE" as on the tape (4917 bytes at $5CCB): the lines, the machine code of
                       line 0 ($5D06) and the enciphered chain ($5D2A, copied to $AC38)
  chain-ac38.bin       the plain view of $AC38-$BF0C: every layer of the chain as it runs, the loader as the last
                       layer leaves it (tools/speedlock.py plain)
  chain-trace.json     the chain's instructions in that view, a simulator trace for kit/mkgame.py
  stage2-bf0d.bin      the loader's second stage, $BF0D-$BFCF (tape block 7, tools/mktape.py --decode)
  final-be5d.bin       the loader's timing check $BE5D-$BECF (block 37)
  final-bf21.bin       the stage's new end $BF21-$BF2F (block 39)
  loading.scr          the loading screen (blocks 13 and 15)
  bankN-c000.bin       banks 3, 4, 6 and 7 as their blocks load them (29, 31, 33, 35; the rest of each bank is zero)
and into --orig the two sides of orig/BattleCommand.tzx.zip (side1.tzx, side2.tzx) for the build's compare.
"""
import argparse
import os
import shutil
import subprocess
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import speedlock  # noqa: E402
import tzxblocks  # noqa: E402

SIDES = {'side1.tzx': 'Battle Command - Side 1.tzx', 'side2.tzx': 'Battle Command - Side 2.tzx'}


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'work/parts'))
    p.add_argument('--orig', default=os.path.join(CASE, 'build/orig'))
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.orig, exist_ok=True)
    z = zipfile.ZipFile(os.path.join(CASE, 'orig/BattleCommand.tzx.zip'))
    for name, member in SIDES.items():
        open(os.path.join(a.orig, name), 'wb').write(z.read(member))
    side1 = os.path.join(a.orig, 'side1.tzx')
    blocks = list(tzxblocks.parse(open(side1, 'rb').read()))
    basic = blocks[2]['data'][1:-1]
    open(os.path.join(a.out, 'basic-5ccb.bin'), 'wb').write(basic)
    chain, _ = speedlock.plain(basic[speedlock.TAIL - speedlock.PROG:][:speedlock.HI - speedlock.LO])
    open(os.path.join(a.out, 'chain-ac38.bin'), 'wb').write(chain)
    master, _ = speedlock.master(chain)
    assert master == basic[speedlock.TAIL - speedlock.PROG:][:len(master)], 'parts: the chain does not master back'
    subprocess.run([sys.executable, os.path.join(HERE, 'speedlock.py'), 'trace', os.path.join(a.out, 'chain-ac38.bin'),
                    os.path.join(a.out, 'chain-trace.json')], check=True, stdout=subprocess.DEVNULL)
    dec = os.path.join(a.out, 'decoded')
    if os.path.isdir(dec):
        shutil.rmtree(dec)
    os.makedirs(dec)
    shutil.copy(os.path.join(a.out, 'chain-ac38.bin'), os.path.join(dec, 'chain.bin'))
    subprocess.run([sys.executable, os.path.join(HERE, 'mktape.py'), os.path.join(CASE, 'src/tape/side1.txt'),
                    '--decode', side1, dec], check=True, stdout=subprocess.DEVNULL)
    rd = lambda n: open(os.path.join(dec, n), 'rb').read()
    open(os.path.join(a.out, 'stage2-bf0d.bin'), 'wb').write(rd('sl-07-BF0D.bin'))
    open(os.path.join(a.out, 'final-be5d.bin'), 'wb').write(rd('sl-37-BE5D.bin'))
    open(os.path.join(a.out, 'final-bf21.bin'), 'wb').write(rd('sl-39-BF21.bin'))
    open(os.path.join(a.out, 'loading.scr'), 'wb').write(rd('sl-13-4000.bin') + rd('sl-15-8000.bin'))
    for n, blk in ((3, 29), (4, 31), (6, 33), (7, 35)):
        open(os.path.join(a.out, 'bank%d-c000.bin' % n), 'wb').write(rd('sl-%02d-C000.bin' % blk))
    print('parts: written to', a.out)


if __name__ == '__main__':
    main()
