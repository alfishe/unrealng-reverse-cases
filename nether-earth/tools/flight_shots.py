#!/usr/bin/env python3
"""Screens of the landscape away from the home warbase, for docs/01-game-design.md: a new game from the menu snapshot,
the ship flown east over a neutral factory and to the first enemy warbase, a screen at each.

    python3 tools/flight_shots.py --unreal U --binary B --work work/docA/flight --out-dir docs/img [--port-base 24050]

The emulator is exact and the flight reads only memory (tools/bot.py), so every run gives the same screens. The
instance is killed at the end.
"""
import argparse
import os
import shutil
import signal
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bot  # noqa: E402

# (name, x, y) of the ship's stops: factory 1 (53,3, chassis, neutral at the start), enemy warbase 1 (261,8)
STOPS = [('game-2-factory', 53, 7), ('game-3-enemy-warbase', 263, 12)]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--unreal', required=True)
    p.add_argument('--binary', required=True)
    p.add_argument('--work', required=True)
    p.add_argument('--out-dir', required=True)
    p.add_argument('--start', default=os.path.join(bot.HERE, '..', 'work', 'play', 'start.szx'))
    p.add_argument('--port-base', type=int, default=24050)
    args = p.parse_args()
    g = bot.Game(args.unreal, args.work)
    process = g.launch(args.binary, args.start, args.port_base)
    try:
        g.key('2')
        g.key('0', gap=100)
        for _ in range(100):
            if g.state()['handler'] == bot.PLAY_INTERRUPT:
                break
            g.run(10)
        for name, x, y in STOPS:
            g.fly_to(x, y, cruise=30, limit=8000)
            g.run(20)
            st = g.state()
            path = g.screen(os.path.join(args.out_dir, name + '.png'))
            print(f"{path}: frame {g.frame} after the start, ship ({st['x']},{st['y']}) altitude {st['altitude']}, "
                  f"day {st['clock'][2]} {st['clock'][1]:02d}:{st['clock'][0]:02d}")
    finally:
        os.kill(process.pid, signal.SIGTERM)


if __name__ == '__main__':
    sys.exit(main())
