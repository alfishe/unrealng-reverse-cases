#!/usr/bin/env python3
"""Input scripts (re_session.py capture --inputs) from (keys, frames) pairs: each pair holds its keys for its frames.

    python3 tools/inputs.py x2 tests/inputs/x2-imm-right.txt

The format's "+N KEYS" line waits N frames, then holds KEYS until the next line; this writes the waits from the
pairs so a pair's frames are its own.
"""
import sys

MENU = [('-', 100), ('5', 30), ('-', 50), ('1', 30), ('-', 100)]  # the menu: 5 Kempston, 1 start game


def script(title, pairs):
    lines = ['# ' + title, '0 ' + pairs[0][0]]
    for (_, frames), (keys, _) in zip(pairs, pairs[1:]):
        lines.append('+%d %s' % (frames, keys))
    lines.append('+%d END' % pairs[-1][1])
    return '\n'.join(lines) + '\n'


PLANS = {
    'x2': ('x2: from work/snaps/entry-imm.z80 (ZXDB POKEs: lives, ammo, grenades, immunity, mines, traps): the menu '
           '(5, 1), then right; fire held 40 frames (a grenade), a jump, a shot',
           MENU + [('KF', 40), ('KR', 40), ('KR KU', 16), ('KR', 30), ('KR KF', 6), ('KR', 20)] * 150),
    'm1': ('m1: from work/snaps/entry.z80, no POKE: the menu: 2 (define keys: P O Q A M, then SPACE for the last '
           'prompts), 3 (keyboard), 4 (Interface 2), 5 (Kempston), 1 (start); the first screen kills the player nine times, '
           'GAME OVER, the menu again',
           [('-', 100), ('2', 30), ('-', 60), ('P', 20), ('-', 40), ('O', 20), ('-', 40), ('Q', 20), ('-', 40),
            ('A', 20), ('-', 40), ('M', 20), ('-', 40), ('SPACE', 20), ('-', 40), ('ENTER', 20), ('-', 100),
            ('3', 30), ('-', 60), ('4', 30), ('-', 60), ('5', 30), ('-', 60), ('1', 30), ('-', 100)]
           + [('KR', 60), ('KR KF', 6), ('KR', 30), ('KU', 10)] * 60 + [('-', 1500)]),
    'h1': ('h1: from work/snaps/entry-score.z80 (a clone: the score digits $AD8A set to 009000 and the reset at $6D88-$6D94 made NOPs): '
           'the menu (5, 1), the first screen kills the player nine times, then the Hall of Fame entry: E X O L O N, '
           'ENTER',
           MENU + [('KR', 60), ('KR KF', 6), ('KR', 30)] * 60
           + [('-', 300)] + [(k, 20) for k in 'EXOLON' for _ in (0,)] + [('-', 30), ('ENTER', 20), ('-', 1500)]),
}

if __name__ == '__main__':
    title, pairs = PLANS[sys.argv[1]]
    open(sys.argv[2], 'w').write(script(title, pairs))
