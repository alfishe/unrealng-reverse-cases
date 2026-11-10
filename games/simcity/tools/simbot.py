#!/usr/bin/env python3
"""The SimCity bot's moves on a Lab instance: the cursor steered from the game's own cursor bytes `$5CFC` (x) and
`$5CFD` (y), tools picked on the icon bar, menus opened from the top bar, keys tapped. Every key change goes through
Lab.keys and every frame through Lab.run, so a recording started on the instance holds exactly what the bot did;
the moves are logged as an mm_session input script (frame, keys) for the record.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lab import Lab  # noqa: E402

CURSOR = 0x5CFC


class Bot:
    def __init__(self, lab):
        self.lab = lab
        self.script = []
        self.frame = 0

    def keys(self, k):
        k = list(k)
        if k != self.lab.held:
            self.script.append((self.frame, k))
        self.lab.keys(k)

    def run(self, n):
        self.lab.run(n)
        self.frame += n

    def cursor(self):
        v = self.lab.read(CURSOR, 2)
        return v[0], v[1]

    def goto(self, x, y, limit=600):
        """Steers the cursor to (x, y) in the game's units, one frame at a time"""
        for _ in range(limit):
            cx, cy = self.cursor()
            if (cx, cy) == (x, y):
                break
            k = []
            if cy > y:
                k.append('Q')
            elif cy < y:
                k.append('A')
            if cx > x:
                k.append('O')
            elif cx < x:
                k.append('P')
            self.keys(k)
            self.run(1)
        self.keys([])
        self.run(1)
        return self.cursor()

    def tap(self, k, hold=4, gap=12):
        self.keys(k if isinstance(k, list) else [k])
        self.run(hold)
        self.keys([])
        self.run(gap)

    def wait(self, n):
        self.keys([])
        self.run(n)

    def write_script(self, path, note=''):
        with open(path, 'w') as f:
            if note:
                f.write(''.join(f'# {ln}\n' for ln in note.splitlines()))
            last = 0
            for frame, k in self.script:
                f.write(f'+{frame - last} {" ".join(k) if k else "-"}\n')
                last = frame
            f.write(f'+{self.frame - last} END\n')


MENU_X = {'SYSTEM': 4, 'OPTIONS': 20, 'DISASTERS': 38, 'WINDOWS': 56}


def down(bot, n=1, key='A'):
    """Moves a menu or dialog highlight by `n` items: each press held 8 frames, 16 frames apart. The window loops
    (`$6953` and the menu loops) poll the keys once in 8 frames, and the item `$6A7D` moves once per poll that sees
    a key: held 12 frames, a press is often seen twice (measured on the SYSTEM menu: 4 presses at 12/6 moved the
    item 0, 2, 3, 4, 6; at 8/16 exactly 1, 2, 3, 4)"""
    for _ in range(n):
        bot.tap(key, 8, 16)


def menu(bot, name, item, settle=30):
    """Opens a top-bar menu and picks its item (0 = the first, the one lit on opening): the cursor to the menu's name
    on row 0, fire, then down `item` times, fire"""
    bot.goto(MENU_X[name], 1)
    bot.tap('SPACE', 6, settle)
    down(bot, item)
    bot.tap('SPACE', 8, settle)


def open_menu(bot, name, settle=30):
    bot.goto(MENU_X[name], 1)
    bot.tap('SPACE', 6, settle)


def tool(bot, icon):
    """Picks icon 0-13 on the icon bar (0 bulldozer ... 13 airport) with the cursor (rows 1-2, columns 2 + 2 icon)"""
    bot.goto(4 * icon + 5, 12)
    bot.tap('SPACE', 4, 12)


def place(bot, col, row):
    """Fires the current tool at screen cell (col, row 8-23): the cursor's top-left there"""
    bot.goto(2 * col, 8 * row + 3)
    bot.tap('SPACE', 4, 20)


def shots_grid(paths, out, cols=2):
    from PIL import Image
    ims = [Image.open(p) for p in paths]
    w, h = ims[0].size
    rows = (len(ims) + cols - 1) // cols
    c = Image.new('RGB', (w * cols, h * rows))
    for i, im in enumerate(ims):
        c.paste(im, ((i % cols) * w, (i // cols) * h))
    c.save(out)
