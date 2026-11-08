#!/usr/bin/env python3
"""b1 live: Side B past the Lenslok with the code computed by the game's own code, then the game image at its entry
$70E0 compared with build/sideb/game.bin (the source build). b1 must be open (the capture leaves it open).

    python3 tools/b1_live.py [--branch 15800]
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import kitlib as K  # noqa: E402
import lenslok_sim as LS  # noqa: E402
import lenslok_live as LL  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--branch', type=int, default=15800)
    a = p.parse_args()
    out = os.path.join(E.CASE, 'work', 'b1', 'live')
    os.makedirs(out, exist_ok=True)
    lv = LL.Live(E.session(os.path.join(E.CASE, 'work', 'b1')))
    lv.call('time_travel', {'action': 'seek', 'frame': a.branch})
    lv.call('time_travel', {'action': 'resume'})
    lv.call('control_execution', {'action': 'pause'})
    lv.key('enter', gap=0)
    if not lv.until(0xC2A0, 3000):
        sys.exit('no attempt')
    mem = lv.read(0, 0x10000)
    if not mem[0xC785] & 0x80:
        sys.exit('not at the seed (%02X)' % mem[0xC785])
    sim = LS.attempt(mem)
    code = sim['code'].decode()
    lv.until(0xC2A9)
    open(os.path.join(out, 'code.scr'), 'wb').write(lv.read(0x4000, 6912))
    print('seed %04X, code %s (the game\'s code $C2A0-$C2A5 in the simulator)' % (mem[0xC784] | mem[0xC785] << 8, code))
    lv.key(code[0].lower())
    lv.call('type_input', {'action': 'press', 'key': code[1].lower()})
    ok = lv.until(0x70E0, 100)
    lv.call('type_input', {'action': 'release', 'key': code[1].lower()})
    print('accepted, at the entry $70E0:', ok)
    if not ok:
        sys.exit(1)
    img = lv.read(0, 0x10000)
    open(os.path.join(out, 'entry.bin'), 'wb').write(img)
    lo = 0x5B00
    for side, path in (('B', 'build/sideb/game.bin'), ('A', 'build/game.bin')):
        built = open(os.path.join(E.CASE, path), 'rb').read()
        diff = [x for x in range(lo, lo + len(built)) if img[x] != built[x - lo]]
        runs = []
        for x in diff:
            if runs and x == runs[-1][1] + 1:
                runs[-1][1] = x
            else:
                runs.append([x, x])
        print('entry image against the built Side %s (%s): %d bytes differ in %d runs: %s' % (
            side, path, len(diff), len(runs), ', '.join('$%04X-$%04X' % (r0, r1) for r0, r1 in runs[:12])))
    lv.frames(400)
    scr = lv.read(0x4000, 6912)
    open(os.path.join(out, 'title.scr'), 'wb').write(scr)
    K.render_screen(bytes(0x4000) + scr + bytes(0x10000 - 0x4000 - 6912)).save(os.path.join(out, 'title.png'))
    print('title screen: work/b1/live/title.png')


if __name__ == '__main__':
    main()
