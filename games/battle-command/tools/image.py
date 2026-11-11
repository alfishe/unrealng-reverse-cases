#!/usr/bin/env python3
"""The game image of Battle Command as the original tape's loader leaves it, all eight 128K banks.

  image.py [--ttd work/stage1/rec/c1/session.ttd] [--port-base 37320] [--out work/mkgame]

The tape's game blocks are enciphered (SpeedLock 7: no tape block of side 1 is found in memory as it is on the tape),
so the image is taken from a recording of the original: c1, which tools/record.py makes from power-on with
orig/BattleCommand.tzx.zip side 1 played at signal speed. The moment is the loader's jump into the game, `JP $68F4`
at `$8043` (re_session.py stages: stage 23, frame 23974, t 30360): the image is read at t 30350 of that frame.

Writes OUT/original.bin (the 64 K Z80 view at that moment: ROM 0, banks 5, 2, 0 paged) and OUT/bankN.bin
(16 K each, banks 0-7). Launches its own instance (re_session.py open) on --port-base and stops it after.
"""
import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import ttd_dump  # noqa: E402

ENTRY_FRAME, ENTRY_T = 23974, 30350


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--ttd', default=os.path.join(CASE, 'work/stage1/rec/c1/session.ttd'))
    p.add_argument('--port-base', type=int, default=37320)
    p.add_argument('--out', default=os.path.join(CASE, 'work/mkgame'))
    args = p.parse_args()
    rs, binary = os.environ['RS'], os.environ['BIN']
    work = os.path.join(args.out, 'image-session')
    os.makedirs(work, exist_ok=True)
    subprocess.run([sys.executable, rs, 'open', '--work', work, '--ttd', args.ttd, '--model', '128K',
                    '--port-base', str(args.port_base), '--binary', binary], check=True, stdout=subprocess.DEVNULL)
    try:
        s = ttd_dump.session(work)
        for n in range(8):
            data = ttd_dump.read(s, 'ram', ENTRY_FRAME, ENTRY_T, n * 0x4000, 0x4000)
            open(os.path.join(args.out, f'bank{n}.bin'), 'wb').write(data)
        cpu = b''.join(ttd_dump.read(s, 'cpu', ENTRY_FRAME, ENTRY_T, o, 0x4000) for o in range(0, 0x10000, 0x4000))
        open(os.path.join(args.out, 'original.bin'), 'wb').write(cpu)
    finally:
        subprocess.run([sys.executable, rs, 'stop', '--work', work], stdout=subprocess.DEVNULL)


if __name__ == '__main__':
    main()
