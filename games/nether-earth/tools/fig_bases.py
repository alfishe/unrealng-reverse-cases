#!/usr/bin/env python3
"""Doc 01 figures: an enemy warbase and a neutral factory as the player meets them, each object named on the screen
(docs/img/game-3-enemy-warbase.png, docs/img/game-2-factory.png).

    python3 tools/fig_bases.py capture [--port-base 9410]   # own instance: new game, fly, screens + memory
    python3 tools/fig_bases.py draw                         # the annotated figures from the capture

capture: a new game from the menu snapshot (work/play/start.szx, Kempston), the ship flown east (tools/bot.py, which
reads only memory, so every run gives the same screens) to a stop near each base; at each stop the screen, the view
column, the ship, the robots, the building records ($FF01) and the capture points ($FD70) are saved to
work/figA/bases/<name>.json. The instance is muted and killed at the end.

draw: each object's DrawSprite anchor (the sprite's lower left) is projected from its record with 06-rendering 6.3
(ill_ui.project) and named with a callout.
"""
import argparse
import json
import os
import signal
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
import bot  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

OUT = os.path.join(CASE, 'work', 'figA', 'bases')
UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
BINARY = toolpaths.unreal_binary(required=False) or 'unreal-qt'
# (name, ship x, ship y): the factory roof at (53,3) (chassis, neutral at the start), the enemy warbase door (261,8)
STOPS = [('factory', 57, 9), ('warbase', 263, 12)]
KINDS = ['warbase', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis']


def capture(args):
    os.makedirs(OUT, exist_ok=True)
    g = bot.Game(args.unreal, os.path.join(OUT, 'instance'))
    process = g.launch(args.binary, os.path.join(CASE, 'work', 'play', 'start.szx'), args.port_base)
    try:
        g.key('2')
        g.key('0', gap=100)
        for _ in range(100):
            if g.state()['handler'] == bot.PLAY_INTERRUPT:
                break
            g.run(10)
        stops = STOPS if not args.stops else [(n, int(x), int(y)) for n, x, y in
                                              (t.split(':') for t in args.stops.split(','))]
        for name, x, y in stops:
            g.fly_to(x, y, cruise=30, limit=8000)
            g.run(20)
            st = g.state()
            g.screen(os.path.join(OUT, name + '.png'))
            points = g.m.read(0xFD70, 28 * 5)
            caps = [{'x': points[5 * i] | points[5 * i + 1] << 8, 'y': points[5 * i + 2], 'kind': points[5 * i + 3]}
                    for i in range(28)]
            doc = {'frame': g.frame, 'state': st, 'robots': g.robots(), 'buildings': g.buildings(), 'points': caps}
            json.dump(doc, open(os.path.join(OUT, name + '.json'), 'w'), indent=1)
            print(name, 'frame', g.frame, 'ship', st['x'], st['y'], st['altitude'], 'view', st['view'],
                  'clock', st['clock'])
    finally:
        os.kill(process.pid, signal.SIGTERM)


def project(column, row, height, view_x):
    """06-rendering 6.3: DrawSprite's anchor in screen pixels, the view buffer copied to character (1,1)"""
    e = column - view_x
    return 8 * e + 4 * row - 96 + 8, 8 * row + 100 - 4 * e - height + 8


def in_view(p):
    return 8 <= p[0] < 168 and 8 <= p[1] < 168


def draw(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from PIL import Image

    for name, out, title in (
            ('warbase', 'game-3-enemy-warbase.png',
             'An enemy warbase: its flag says who holds it; a robot on its door for 144 turns takes it'),
            ('factory', 'game-2-factory.png',
             'A neutral factory: the roof shows what it makes; no flag, nobody holds it yet')):
        doc = json.load(open(os.path.join(OUT, name + '.json')))
        st = doc['state']
        view = st['view']
        screen = Image.open(os.path.join(OUT, name + '.png'))
        fig, ax = plt.subplots(figsize=(10.5, 5.6), dpi=100)
        fig.patch.set_facecolor('#15161b')
        ax.imshow(screen, extent=(0, 256, 192, 0), interpolation='nearest')
        ax.set_xlim(-150, 256)
        ax.set_ylim(192, 0)
        ax.axis('off')
        marks = []  # (point, label, colour)
        # the black cross: the ship's shadow, sprite 1 at height 0 under ShipX, ShipY (06-rendering 6.4)
        marks.append((project(st['x'], st['y'], 0, view), f'the ship\'s shadow, under ShipX, ShipY = {st["x"]}, '
                      f'{st["y"]}', '#e070c0'))
        for b in doc['buildings']:
            # BuildingHeights $CE5F: the pad $13, a factory roof $0F, a flag $1A (06-rendering 6.5)
            p = project(b['x'], b['y'], 0x1A if b['type'] in (7, 8) else 0x13 if b['type'] == 0 else 0x0F, view)
            if not in_view(p):
                continue
            if b['type'] == 8:
                marks.append((p, f'the enemy\'s flag\n(building type 8 at {b["x"]},{b["y"]})', '#f0d050'))
            elif b['type'] == 7:
                marks.append((p, f'our flag\n(building type 7 at {b["x"]},{b["y"]})', '#70d070'))
            elif 1 <= b['type'] <= 6:
                marks.append((p, f'a factory roof: {KINDS[b["type"]]}\n(building type {b["type"]} at '
                              f'{b["x"]},{b["y"]})', '#80c0ff'))
        for c in doc['points']:
            p = project(c['x'], c['y'], 0, view)
            if not in_view(p):
                continue
            owner = 'the enemy\'s' if c['kind'] & 0x20 else 'ours' if c['kind'] & 0x40 else 'neutral'
            what = f'the {KINDS[c["kind"] & 7]} factory' if c['kind'] & 7 else 'the warbase'
            marks.append((p, f'the door of {what} ({owner}), cell {c["x"]},{c["y"]}:\n'
                          'the capture point', '#60e0a0'))
        enemy = [r for r in doc['robots'] if not r['mine'] and in_view(project(r['x'], r['y'], 0, view))]
        for r in enemy:
            ground = int(r['raw'].split()[13], 16)
            marks.append((project(r['x'], r['y'], ground, view),
                          f'an enemy robot (slot {r["slot"]})', '#ff8060'))
        marks.sort(key=lambda m: m[0][1])
        n = len(marks)
        for i, (p, label, colour) in enumerate(marks):
            ly = 12 + i * (176 / max(1, n - 1)) if n > 1 else 96
            ax.plot(*p, 'o', ms=8, mfc=colour, mec='black', mew=1.5)
            ax.annotate(label, xy=p, xytext=(-8, ly), ha='right', va='center', color=colour, fontsize=10,
                        arrowprops=dict(arrowstyle='-', color=colour, lw=1.2))
        ax.set_title(title, color='#e6e6e6', fontsize=12, loc='left')
        clock = st['clock']
        fig.text(0.02, 0.04, f'Own instance, a new game flown east, day {clock[2]} {clock[1]:02d}:{clock[0]:02d}. '
                 'Dots: where DrawSprite anchors each object (its lower left), projected from its record (6.3).',
                 color='#b8bcc8', fontsize=9)
        path = os.path.join(args.out_dir, out)
        fig.savefig(path, facecolor=fig.get_facecolor(), bbox_inches='tight')
        plt.close(fig)
        print(path)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    c = sub.add_parser('capture')
    c.add_argument('--unreal', default=os.environ.get('UNREAL_NG', UNREAL))
    c.add_argument('--binary', default=BINARY)
    c.add_argument('--port-base', type=int, default=9410)
    c.add_argument('--stops', help='NAME:X:Y,... instead of the built-in stops')
    d = sub.add_parser('draw')
    d.add_argument('--out-dir', default=os.path.join(CASE, 'docs', 'img'))
    args = p.parse_args()
    capture(args) if args.cmd == 'capture' else draw(args)


if __name__ == '__main__':
    sys.exit(main())
