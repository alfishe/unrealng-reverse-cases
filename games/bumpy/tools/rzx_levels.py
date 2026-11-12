#!/usr/bin/env python3
"""Play the RZX archive's bumpy.rzx in SkoolKit's simulator and cut it at the level starts: a Z80 snapshot at the end
of every RZX frame where the level number `$AB00` changes (OUT/lvl-FFFFFF.z80, the state after that frame), and the
end of every RZX frame where the play timer `$AB04` (a word, 1000 at a level's start) first counts down, the moment
play starts after READY? (OUT/play-FFFFFF.z80, listed in OUT/plays.tsv), and the game's state block `$AAF0-$AB0F`
after every frame (OUT/state.bin, 32 bytes a frame, frame 0 first), so a replay of
ours can be compared with the RZX's own run frame by frame.

    python3 tools/rzx_levels.py work/candidates/zxdb-extra/bumpy.rzx --out work/stage1/rzx/levels

Prints one line a change: RZX frame, the old and new level. The RZX is someone else's run: a witness only where said.
"""
import argparse
import os
import sys

V = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
for p in [os.path.join(V, 'lib', d, 'site-packages') for d in os.listdir(os.path.join(V, 'lib'))]:
    sys.path.insert(0, p)
from skoolkit import rzxplay  # noqa: E402
from skoolkit.simutils import get_state  # noqa: E402
from skoolkit.snapshot import write_snapshot  # noqa: E402

LEVEL = 0xAB00


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rzx')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    state = open(os.path.join(a.out, 'state.bin'), 'wb')
    log = open(os.path.join(a.out, 'levels.tsv'), 'w')
    log.write('# rzx frame (snapshot after it)\told level\tnew level\n')
    plays = open(os.path.join(a.out, 'plays.tsv'), 'w')
    plays.write('# rzx frame (snapshot after it)\tlevel\n')
    last = [None]
    timer = [None]
    orig_next = rzxplay.RZXTracer.next_frame

    def next_frame(self):
        if self.frame_index >= 0:
            n = self.context.frame_count  # frames completed so far
            mem = self.simulator.memory
            state.write(bytes(mem[0xAAF0:0xAB10]))
            lv = mem[LEVEL]
            if last[0] is not None and lv != last[0]:
                ram, registers, st, machine = get_state(self.simulator)
                write_snapshot(os.path.join(a.out, f'lvl-{n:06d}.z80'), ram, registers, st, machine)
                log.write(f'{n}\t{last[0]}\t{lv}\n')
                print(n, last[0], lv, flush=True)
            last[0] = lv
            t = mem[0xAB04] | mem[0xAB05] << 8
            if timer[0] == 1000 and t == 999:
                ram, registers, st, machine = get_state(self.simulator)
                write_snapshot(os.path.join(a.out, f'play-{n:06d}.z80'), ram, registers, st, machine)
                plays.write(f'{n}\t{lv}\n')
            timer[0] = t
        return orig_next(self)

    rzxplay.RZXTracer.next_frame = next_frame
    rzxplay.main(['--no-screen', '--quiet', '--fps', '0', a.rzx, os.path.join(a.out, 'end.z80')])


if __name__ == '__main__':
    main()
