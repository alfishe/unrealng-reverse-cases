#!/usr/bin/env python3
"""Doc 01's screen sheets: the screens of the game as the recordings captured them (kit/screen_shot.py PNGs in
docs/img/play), labelled with the recording and the frame.

    python3 tools/fig_play.py docs/img/design

Writes screens-front.png (every screen outside play) and screens-play.png (the moments of play: charging, overload,
a cell burnt, the mine, the door, CONTACT!, the bonus, a gremlin, the energy messages, a life lost).
"""
import os
import sys

import figlib

PLAY = os.path.join(figlib.CASE, 'docs', 'img', 'play')

FRONT = [
    ('title.png', 'Title (TitleScreen $A729)', 'c1, frame 250'),
    ('options.png', 'Options panel (OptionsMenu $A757)', 'c1, frame 500'),
    ('options-menu.png', '5 DEMO: level 1 wipes in', 'menu, frame 3250'),
    ('demo.png', 'Demo: a level a pass', 'menu, frame 4500'),
    ('practice-001750.png', 'Practice P1 (6 on the menu)', 'dfA practice, frame 1750'),
    ('controls-001500-intermission.png', 'Pause: INTERMISSION (P)', 'controls, frame 1500'),
    ('game-aborted.png', 'GAME ABORTED (U + G)', 'controls, frame 2000'),
    ('gameover-000150.png', 'GAME OVER', 'gameover, frame 150'),
    ('hof-017160-name.png', 'Entered: AGENT 021940, place 6', 'hof, frame 17160'),
    ('hall-of-fame.png', 'Hall of fame after the ending', 'rzx-344752, frame 1250'),
    ('ending-001000.png', 'The ending: plug and kettle', 'ending, frame 1000'),
    ('title-after-abort.png', 'Title again, in magenta', 'menu, frame 8500'),
]

MOMENTS = [
    ('l01-000100-charging.png', 'CHARGING LASER, no beam', 'L01, frame 100'),
    ('l01-000262-overload.png', 'Beam back in the laser: OVERLOAD', 'L01, frame 262'),
    ('l01-000395-burn.png', 'A cell burns (explosion)', 'L01, frame 395'),
    ('l01-001000-play.png', 'Mid level, score 1560', 'L01, frame 1000'),
    ('l01-001346-mine.png', 'Beam on a mine: MINE ALERT', 'L01, frame 1346'),
    ('l01-001425-door.png', 'Last cell: the receiver opens', 'L01, frame 1425'),
    ('l01-001560-contact.png', 'Receiver reached: CONTACT!', 'L01, frame 1560'),
    ('l01-001610-bonus.png', 'Bonus count: energy, lives', 'L01, frame 1610'),
    ('l03-001180-gremlin.png', 'A gremlin appears: BEWARE', 'L03, frame 1180'),
    ('l03-001300-gremlin-mirror.png', 'A gremlin turns a mirror', 'L03, frame 1300'),
    ('energy-005000-low.png', 'ENERGY LOW', 'energy, frame 5000'),
    ('energy-005760-critical.png', 'ENERGY CRITICAL', 'energy, frame 5760'),
    ('energy-006460-drained.png', 'ENERGY DRAINED: a life', 'energy, frame 6460'),
    ('gameover-000100.png', 'A life lost: BOOM, red', 'gameover, frame 100'),
    ('life-lost.png', 'BOOM BOOM BOOM (3 lives)', 'mine, frame 500'),
]


def build(items, title, notes):
    pics = [(figlib.screen_png(os.path.join(PLAY, f)), [a, b]) for f, a, b in items]
    return figlib.sheet(pics, 4, 252, 189, title=title, label_h=40, gap=8, notes=notes)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    build(FRONT, 'Every screen outside play, as recorded',
          ['Recordings: WALKTHROUGH 6.0 (c1, menu, controls, gameover), work/stage2/rec (hof, ending),',
           'work/docs/dfA/rec/practice. Screens by kit/screen_shot.py at the frame named (state at the frame start).']
          ).save(os.path.join(out, 'screens-front.png'))
    build(MOMENTS, 'The moments of play, as recorded',
          ['L01, L03: the bot\'s level recordings work/stage2/rec/L01, L03; energy, gameover, mine: work/stage1.',
           'gameover and mine start from POKEd states (the overload bar full): said in WALKTHROUGH 6.0.']
          ).save(os.path.join(out, 'screens-play.png'))
    print(out)


if __name__ == '__main__':
    main()
