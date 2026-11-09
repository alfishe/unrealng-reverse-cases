#!/usr/bin/env python3
"""Input scripts (re_session.py capture --inputs) from (keys, frames) pairs: each pair holds its keys for its frames.

    python3 tools/inputs.py m1 tests/inputs/m1-menus.txt
    python3 tools/inputs.py all            # every plan into tests/inputs/

The format's "+N KEYS" line waits N frames, then holds KEYS until the next line; this writes the waits from the
pairs so a pair's frames are its own. Keys: A-Z 0-9 ENTER SPACE CS SS; the game's default control is the keyboard
(option K: A slow, Q fast, O jump, P fire).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'tests', 'inputs')


def tap(key, hold=20, gap=40):
    return [(key, hold), ('-', gap)]


# a pass over the course: fast, a jump, fire; repeated (the buggy jumps craters and rocks now and then)
PLAY = [('Q', 30), ('Q O', 8), ('Q', 20), ('P', 6), ('-', 20), ('O', 8), ('-', 10), ('P O', 6), ('-', 20)]
# a slower pass: no Q, jumps and shots
PLAY_SLOW = [('O', 8), ('-', 24), ('P', 6), ('-', 24), ('A', 30), ('O P', 8), ('-', 26)]

PLANS = {
    'a1': ('a1: from work/snaps/entry.z80, no POKE: the title, H (hi-score table), M (options page), every option '
           'key (O T 1 2 Z X C V B K, then O 1 K), S (start); play with the keyboard; H (hold) and H again; T (tune '
           'off) and T (on); 0 (nothing), then CAPS+SPACE: the abort to $8004 (the play keys held after it keep the '
           'options page up to the end of the script)',
           [('-', 150)] + tap('H') + [('-', 200)] + tap('M') + [('-', 60)]
           + sum((tap(k) for k in 'OT12ZXCVBKO1K'), [])
           + tap('S') + [('-', 150)]
           + PLAY * 4
           + tap('H', 20, 150) + tap('H', 20, 60)
           + PLAY * 2
           + tap('T', 20, 200) + tap('T', 20, 60)
           + PLAY * 2
           + tap('0', 20, 60) + tap('CS SPACE', 20, 60)
           + PLAY * 120 + [('-', 3000)]),
    'g1': ('g1: from work/snaps/entry.z80, no POKE: S from the title, play until GAME OVER, the attract cycle (title, '
           'options, score advance table, demo, hi-score table)',
           [('-', 150)] + tap('S') + [('-', 150)] + PLAY * 50 + [('-', 4000)]),
    'i1': ('i1: from work/snaps/immune.z80 (a clone: the kill entry $A7DD made RET): S from the title, the play '
           'pattern for 30000 frames: the Beginner course from its start',
           [('-', 150)] + tap('S') + [('-', 150)] + PLAY * 235),
    'i2': ('i2: from work/snaps/immune.z80 (a clone: the kill entry $A7DD made RET): M (options), 2 (Champion '
           'course), S, the play pattern for about 33500 frames: the Champion course from its start, then the loop '
           'back to the Beginner course',
           [('-', 150)] + tap('M') + [('-', 60)] + tap('2') + tap('S') + [('-', 150)] + PLAY * 260),
    'h1': ('h1: from work/snaps/entry.z80, no POKE: g1 up to its GAME OVER (score 1260, above the lowest of the '
           'heroes), then the initials M P A and ENTER, and the attract cycle',
           [('-', 150)] + tap('S') + [('-', 150)] + PLAY * 28 + [('-', 400)]
           + sum((tap(k) for k in 'MPA'), []) + tap('ENTER') + [('-', 3000)]),
    'h2': ('h2: from work/snaps/g1-3700-score60000.z80 (a clone: g1 at frame 3700, the last life, with the score '
           '$B272 = 00 06 00 00, above the all-time best 50000): GAME OVER, the all-time entry (20 letters): STAGE '
           'ONE, ENTER, and the attract cycle',
           [('-', 600)] + sum((tap(k) for k in ['S', 'T', 'A', 'G', 'E', 'SPACE', 'O', 'N', 'E']), [])
           + tap('ENTER') + [('-', 3000)]),
    't1': ('t1: from work/snaps/entry.z80, no tape: J (save the hi-score table: the ROM SA-BYTES), then L (load: '
           'LD-BYTES with no tape, SPACE breaks it: the tape error), then G (verify, SPACE: the tape error)',
           [('-', 150)] + tap('J', 20, 900) + tap('L', 20, 300) + tap('SPACE', 20, 200) + tap('M', 20, 100)
           + [('-', 600)] + tap('G', 20, 300) + tap('SPACE', 20, 200) + tap('M', 20, 600)),
    'p2': ('p2: from work/snaps/entry.z80, no POKE: M (options), T (two players), S; both players play until GAME '
           'OVER',
           [('-', 150)] + tap('M') + [('-', 60)] + tap('T') + tap('S') + [('-', 150)] + PLAY * 160
           + [('-', 3000)]),
    'c2': ('c2: from work/snaps/entry.z80, no POKE: M (options), 2 (Champion course), S; play until GAME OVER',
           [('-', 150)] + tap('M') + [('-', 60)] + tap('2') + tap('S') + [('-', 150)] + PLAY * 100
           + [('-', 2000)]),
    'w-short': ('w: from a warp clone (tools/warp_snapshot.py): S from the title, then the play pattern for about '
                '3400 frames',
                [('-', 150)] + tap('S') + [('-', 150)] + PLAY * 26),
    'w2-short': ('w2: from a Champion warp clone (tools/warp_snapshot.py --course 2): M (options), 2, S, then the '
                 'play pattern for about 3400 frames',
                 [('-', 150)] + tap('M') + [('-', 60)] + tap('2') + tap('S') + [('-', 150)] + PLAY * 26),
}


def script(title, pairs):
    lines = ['# ' + title, '0 ' + pairs[0][0]]
    for (_, frames), (keys, _) in zip(pairs, pairs[1:]):
        lines.append('+%d %s' % (frames, keys))
    lines.append('+%d END' % pairs[-1][1])
    return '\n'.join(lines) + '\n'


NAMES = {'a1': 'a1-menus-abort', 'g1': 'g1-game-over', 'i1': 'i1-immune-beginner', 'i2': 'i2-immune-champion', 'h1': 'h1-heroes-entry', 'h2': 'h2-all-time-entry', 't1': 't1-tape', 'p2': 'p2-two-players', 'c2': 'c2-champion', 'w-short': 'w-short',
         'w2-short': 'w2-short'}

if __name__ == '__main__':
    if sys.argv[1] == 'all':
        for k, (title, pairs) in PLANS.items():
            open(os.path.join(OUT, NAMES[k] + '.txt'), 'w').write(script(title, pairs))
    else:
        title, pairs = PLANS[sys.argv[1]]
        open(sys.argv[2], 'w').write(script(title, pairs))
