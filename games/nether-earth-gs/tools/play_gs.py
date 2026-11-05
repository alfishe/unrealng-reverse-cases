#!/usr/bin/env python3
"""Play the GS game on a live gs_session.py instance with Nether Earth's own bot (NE tools/bot.py, imported read-only),
steering by the keyboard (the menu's default device 1) instead of a Kempston stick, so the GS card stays as plugged.

    python3 play_gs.py --work work/stage1/x4 --shots work/stage1/screens --frames 6000

It starts the game from the main menu (key 0), lands on the warbase (construction menu), builds robots, gives them
orders (robot menu, orders, targets) and then follows NE's PLAN loop for --frames frames, screenshotting each new
screen kind once. The host's port writes go to whatever history the caller armed (gs_session.py hist:...).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
NE_TOOLS = os.path.join(HERE, '..', '..', 'nether-earth', 'tools')
sys.path.insert(0, NE_TOOLS)
sys.path.insert(0, HERE)
import bot  # noqa: E402
import gs_session  # noqa: E402

KEYS = {'fire': 'symbol', 'left': 'o', 'right': 'p', 'up': 'q', 'down': 'a'}


class KeyGame(bot.Game):
    def __init__(self, work, shots):
        super().__init__(gs_session.UNREAL, work)
        self.shots = shots
        self.taken = set()
        self.live = gs_session.Live(work)

    def stick(self, buttons):
        buttons = set(buttons)
        for b in self.held - buttons:
            self.s.call('type_input', {'action': 'release', 'key': KEYS[b]}, ok=False)
        for b in buttons - self.held:
            self.s.call('type_input', {'action': 'press', 'key': KEYS[b]}, ok=False)
        self.held = buttons

    def shot(self, name):
        if name in self.taken:
            return
        self.taken.add(name)
        path = os.path.abspath(os.path.join(self.shots, name + '.png'))
        self.s.call('capture_media', {'action': 'screenshot', 'path': path}, ok=False)
        self.note(f'screenshot {name}')

    def choose(self, menu, item, then=()):
        for _ in range(100):
            if self.menu_item(menu):
                break
            self.run(1)
        self.shot({bot.MAIN_MENU: 'tap-06-robot-menu', bot.ORDERS_MENU: 'tap-07-orders',
                   bot.TARGET_MENU: 'tap-08-target'}[menu])
        return super().choose(menu, item, then)

    def land_on_warbase(self, x, y):
        ok = super().land_on_warbase(x, y)
        if ok:
            self.shot('tap-04-construction-menu')
        return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--shots', required=True)
    ap.add_argument('--frames', type=int, default=6000)
    args = ap.parse_args()
    g = KeyGame(args.work, args.shots).attach()
    if g.state()['handler'] != PLAY:
        g.key('0', gap=100)
    for _ in range(100):
        if g.state()['handler'] == PLAY:
            break
        g.run(10)
    home = next(b for b in g.buildings() if b['type'] == 0)
    g.note(f"game on, warbase at ({home['x']},{home['y']}), state {g.state()}")
    step = 0
    while g.frame < args.frames:
        st = g.state()
        if st['handler'] not in (PLAY, bot.START_INTERRUPT):
            g.note(f"handler ${st['handler']:04X}: left play")
            g.shot('tap-09-end')
            break
        parts, kind, target = bot.PLAN[step % len(bot.PLAN)]
        if sum(r['mine'] for r in g.robots()) < 24 and bot.affordable(parts, st['resources']):
            if not g.land_on_warbase(home['x'], home['y']):
                g.note('the pad is blocked')
                g.climb()
                g.fly_to(home['x'] + 3, home['y'])
                g.run(100)
                continue
            robot = g.build(parts)
            g.shot('tap-05-robot-built')
            if robot is None:
                g.note(f'build refused {parts}')
                g.run(200)
                continue
            g.note(f"built slot {robot['slot']} parts ${robot['parts']:02X}")
            g.note(f"order {g.order(robot['slot'], kind, target)}")
            step += 1
            continue
        g.fly_to(home['x'] + 3, home['y'], limit=200)
        g.run(100)
    g.stick(set())
    with open(os.path.join(args.work, 'play.log'), 'w') as f:
        f.write('\n'.join(g.log) + '\n')


PLAY = bot.PLAY_INTERRUPT

if __name__ == '__main__':
    main()
