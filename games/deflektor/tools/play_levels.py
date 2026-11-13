#!/usr/bin/env python3
"""Deflektor played by a bot on a Lab instance, level after level: the cursor steered from CursorX/CursorY
(`$96C3`/`$96C4`), mirrors turned with fire held and Left / Right (Sinclair keys: 6 left, 7 right, 8 down, 9 up,
0 fire), the next turn chosen by tools/solver.py (the game's own TraceBeam on a copy of the state). Every key change
goes through Lab.keys and every frame through Lab.run; at each level's start the state is saved
(OUT/LNN.szx) and from there the keys are written as an mm_session input script (OUT/LNN.txt), so each level can be
captured again with `re_session.py capture --snapshot OUT/LNN.szx --inputs OUT/LNN.txt`.

    python3 tools/play_levels.py --out work/stage2/levels [--port-base 37480] [--start work/stage1/probe/menu.szx]
                                 [--level N] [--until L] [--frames F]

From the title snapshot: SPACE, 7 (START GAME), then play. --level N: a POKE of Level `$81FF` = N - 1 on the
instance right after the start (a clone; the level set-up is forced with the poke before the first level is built:
see the log), stated in OUT/play.json.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import solver as S  # noqa: E402  (re-runs this tool under the SkoolKit venv when needed)
from lab import Lab, CASE  # noqa: E402

LEVEL, LIVES, CURSOR, CHARGING = 0x81FF, 0x837D, 0x96C3, 0xA509
DIRS = {'L': '6', 'R': '7', 'D': '8', 'U': '9'}
FIRE = '0'


class Player:
    def __init__(self, lab, out):
        self.lab = lab
        self.out = out
        self.script = []
        self.level_frame = 0
        self.level = None
        self.log = []
        self.skipped = set()
        self.skip_after = 0
        self.keep_lives = 0

    def keys(self, k):
        if list(k) != self.lab.held:
            self.script.append((self.lab.frame - self.level_frame, list(k)))
            self.lab.keys(list(k))

    def state(self):
        """One read of the whole memory a tick: the state and, when a move is planned, the solver's copy"""
        mem = bytearray(self.lab.read(0, 0x10000))
        grid = mem[S.GRID:S.GRID + S.STRIDE * S.ROWS]
        return mem, grid, (mem[CURSOR], mem[CURSOR + 1]), \
            (mem[LEVEL], mem[LIVES], mem[S.CELLS_LEFT], mem[CHARGING])

    def flush_level(self, reason):
        if self.level is None:
            return
        path = os.path.join(self.out, 'L%02d.txt' % (self.level + 1))
        with open(path, 'w') as f:
            f.write('# Deflektor level %d by tools/play_levels.py (%s): from L%02d.szx, the keys as held\n'
                    % (self.level + 1, reason, self.level + 1))
            for fr, k in self.script:
                f.write('%d %s\n' % (fr, ' '.join(k) if k else '-'))
            f.write('%d END\n' % (self.lab.frame - self.level_frame + 50))

    def new_level(self, level):
        self.keys([])
        self.flush_level(('unfinished: skipped by a POKE of LevelDone' if self.level in self.skipped else 'completed')
                         if self.level is not None else 'start')
        self.level = level
        self.level_frame = self.lab.frame
        self.script = [(0, [])]
        self.lab.save(os.path.join(self.out, 'L%02d.szx' % (level + 1)))
        self.log.append({'level': level + 1, 'frame': self.lab.frame})
        print('level %d at frame %d' % (level + 1, self.lab.frame), flush=True)

    def play(self, until, max_frames):
        moves = []
        idle = 0
        lost = 0
        armed = False
        lives0 = None
        while self.lab.frame < max_frames:
            mem, grid, cur, (level, lives, left, charging) = self.state()
            if level != self.level:
                self.new_level(level)
                moves = []
                idle = 0
                lost = 0
                armed = False
                if level >= until:
                    return 'until'
            if charging:
                armed = True
            if not armed:      # the level changed at CONTACT!: the old grid until the new one is built and charging
                self.keys([])
                self.lab.run(8)
                continue
            if lives0 is not None and lives < lives0:
                print('  life lost at frame %d (lives %d)' % (self.lab.frame - self.level_frame, lives), flush=True)
                self.log.append({'level': level + 1, 'life_lost': self.lab.frame})
                moves = []
                lost += 1
            if self.keep_lives and lives < self.keep_lives:
                # Lives `$837D` topped up on this clone (stated in the log), so the run reaches the ending
                print('  lives poked %d -> %d at frame %d' % (lives, self.keep_lives, self.lab.frame - self.level_frame),
                      flush=True)
                self.log.append({'level': level + 1, 'lives_poked': self.lab.frame})
                self.lab.write(LIVES, bytes([self.keep_lives]))
                lives = self.keep_lives
            lives0 = lives
            if self.skip_after and (idle >= self.skip_after or lost >= 2):
                # Stuck (no move found, or two lives gone): LevelDone `$8ED2` = `$FF` poked on this clone, so the
                # game's own LevelComplete runs and builds the next level; this level's script stays unfinished
                print('  level %d skipped by a POKE of LevelDone at frame %d (cells left %d)'
                      % (level + 1, self.lab.frame - self.level_frame, left), flush=True)
                self.log.append({'level': level + 1, 'skipped': self.lab.frame, 'cells_left': left})
                self.skipped.add(level)
                self.keys([])
                for _ in range(100):   # TraceBeam clears the flag each pass: poke until PassEnd sees it
                    self.lab.write(0x8ED2, bytes([0xFF]))
                    self.lab.run(1)
                    if self.lab.read(LEVEL, 1)[0] != level:
                        break
                self.lab.run(10)
                idle = 0
                lost = 0
                continue
            if charging or left == 0:
                self.keys([])
                self.lab.run(8)
                continue
            if not moves:
                hit, done, *_ = S.trace(mem)
                if hit or S.slots(mem) or (done and left == 0xFF):
                    self.keys([])
                    self.lab.run(5)
                    continue
                p = S.plan(mem, cur, want_done=(left == 0xFF))
                if p is None:
                    idle += 1
                    if idle % 20 == 1:
                        print('  level %d: no move (cells left %d) frame %d' % (level + 1, left,
                              self.lab.frame - self.level_frame), flush=True)
                    self.keys([])
                    self.lab.run(10)
                    continue
                idle = 0
                if not p:          # the mirrors as they are will do once a turning element or the prism turns: wait
                    self.keys([])
                    for _ in range(16):
                        self.lab.run(5)
                        sl = self.lab.read(S.SLOTS, 28)
                        if any(sl[0:28:4]):    # a cell burns: the turn came
                            break
                    continue
                moves = list(p)
            r, c, a, key = moves[0]
            v = grid[S.STRIDE * r + c]
            if not 1 <= v <= 0x10:
                moves = []
                continue
            if v == a:
                self.keys([])
                moves.pop(0)
                if not moves:
                    self.lab.run(2)
                continue
            if cur != (c, r):
                k = []
                if c < cur[0]:
                    k.append(DIRS['L'])
                elif c > cur[0]:
                    k.append(DIRS['R'])
                if r < cur[1]:
                    k.append(DIRS['U'])
                elif r > cur[1]:
                    k.append(DIRS['D'])
                self.keys(k)
                far = max(abs(c - cur[0]), abs(r - cur[1]))
                self.lab.run(5 if far > 2 else 2)
            else:
                self.keys([FIRE, DIRS[key]])
                steps = min((a - v) % 16, (v - a) % 16)
                self.lab.run(5 if steps > 2 else 2)
        return 'frames'


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', required=True)
    p.add_argument('--port-base', type=int, default=37480)
    p.add_argument('--start', default=os.path.join(CASE, 'work', 'stage1', 'probe', 'menu.szx'))
    p.add_argument('--snapshot', help='start from a saved level start instead (OUT/LNN.szx), no menu keys')
    p.add_argument('--level', type=int)
    p.add_argument('--until', type=int, default=60, help='stop when Level reaches this (60: the ending)')
    p.add_argument('--frames', type=int, default=2000000)
    p.add_argument('--skip-after', type=int, default=0,
                   help='after this many plans with no move (or two lives lost) poke LevelDone and go on (a clone)')
    p.add_argument('--keep-lives', type=int, default=0, help='poke Lives back to this when it drops (a clone)')
    p.add_argument('--after', type=int, default=3000, help='frames run after the last level, keys up')
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    lab = Lab(port_base=a.port_base)
    info = {'start': a.start, 'snapshot': a.snapshot, 'poke_level': a.level, 'port_base': a.port_base}
    try:
        pl = Player(lab, a.out)
        pl.skip_after = a.skip_after
        pl.keep_lives = a.keep_lives
        if a.snapshot:
            lab.load(a.snapshot)
        else:
            lab.load(a.start)
            lab.run(300)
            lab.tap(['SPACE'], hold=5, gap=95)
            if a.level:
                lab.write(LEVEL, bytes([a.level - 1]))
            lab.tap(['7'], hold=5, gap=5)
        t = time.time()
        why = pl.play(a.until, a.frames)
        pl.keys([])
        lab.run(a.after)
        pl.flush_level(why)
        lab.shot(os.path.join(a.out, 'end.png'))
        lab.save(os.path.join(a.out, 'end.szx'))
        info.update(result=why, frames=lab.frame, seconds=round(time.time() - t), log=pl.log)
        print('done:', why, 'frame', lab.frame, flush=True)
    finally:
        json.dump(info, open(os.path.join(a.out, 'play.json'), 'w'), indent=1)
        lab.close()


if __name__ == '__main__':
    main()
