#!/usr/bin/env python3
"""The parts of the tape that are not the stage images, cut from the original tape (SkoolKit's Python for the chain).

    $SKOOLKIT_VENV/bin/python tools/parts.py [--out work/parts] [--orig build/orig]

Writes into --out:
  basic-5ccb.bin       the BASIC "MYTH" as on the tape (4514 bytes at $5CCB): the line, the machine code of
                       line 0 ($5D06) and the enciphered chain ($5D2A, copied to $EDE4)
  chain-ede4.bin       the plain view of $EDE4-$FF25: every layer of the chain as it runs, the loader as the last
                       layer leaves it (tools/speedlock.py plain)
  chain-trace.json     the chain's instructions in that view, a simulator trace for kit/mkgame.py
  sl1-ff26.bin         the loader's second stage, $FF26-$FFCF (tape block 7, tools/mktape.py --decode)
  loading.scr          the loading screen (blocks 13 and 15)
  resident-f000.bin    the resident part $F000-$FFFF (blocks 25, 17 and 27 with their XOR $DF taken off; Boot $5B00
                       copies $CB80-$EB7F to $E000-$FFFF, and $E000-$EFFF is zero)
  unxor-fe76.bin       block 29, $FE76-$FEE8
  sl1end-ff3a.bin      block 31, $FF3A-$FF48
  boot-5b00.bin        blocks 33 and 35, $5B00-$5B2E
and into --orig the original TZX (myth.tzx) for the build's compare.
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

MEMBER = 'Myth - History In The Making.tzx'


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=os.path.join(CASE, 'work/parts'))
    p.add_argument('--orig', default=os.path.join(CASE, 'build/orig'))
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.orig, exist_ok=True)
    tzx = os.path.join(a.orig, 'myth.tzx')
    open(tzx, 'wb').write(zipfile.ZipFile(os.path.join(CASE, 'orig/Myth-HistoryInTheMaking.tzx.zip')).read(MEMBER))
    blocks = list(tzxblocks.parse(open(tzx, 'rb').read()))
    basic = blocks[2]['data'][1:-1]
    w = lambda n, d: open(os.path.join(a.out, n), 'wb').write(d)
    w('basic-5ccb.bin', basic)
    tail = basic[speedlock.TAIL - speedlock.PROG:][:speedlock.HI - speedlock.LO]
    chain, _ = speedlock.plain(tail)
    w('chain-ede4.bin', chain)
    master, _ = speedlock.master(chain)
    assert master == tail, 'parts: the chain does not master back'
    subprocess.run([sys.executable, os.path.join(HERE, 'speedlock.py'), 'trace', os.path.join(a.out, 'chain-ede4.bin'),
                    os.path.join(a.out, 'chain-trace.json')], check=True, stdout=subprocess.DEVNULL)
    dec = os.path.join(a.out, 'decoded')
    if os.path.isdir(dec):
        shutil.rmtree(dec)
    os.makedirs(dec)
    shutil.copy(os.path.join(a.out, 'chain-ede4.bin'), os.path.join(dec, 'chain.bin'))
    subprocess.run([sys.executable, os.path.join(HERE, 'mktape.py'), os.path.join(CASE, 'src/tape/tape.txt'),
                    '--decode', tzx, dec], check=True, stdout=subprocess.DEVNULL)
    rd = lambda n: open(os.path.join(dec, n), 'rb').read()
    unx = lambda d: bytes(b ^ 0xDF for b in d)
    w('sl1-ff26.bin', rd('sl-07-FF26.bin'))
    w('loading.scr', rd('sl-13-4000.bin') + rd('sl-15-8000.bin'))
    w('resident-f000.bin', unx(rd('sl-25-DB80.bin') + rd('sl-17-DE80.bin') + rd('sl-27-E300.bin')))
    w('unxor-fe76.bin', rd('sl-29-FE76.bin'))
    w('sl1end-ff3a.bin', rd('sl-31-FF3A.bin'))
    w('boot-5b00.bin', rd('sl-33-5B00.bin') + rd('sl-35-5B21.bin'))
    print('parts: written to', a.out)


if __name__ == '__main__':
    main()
