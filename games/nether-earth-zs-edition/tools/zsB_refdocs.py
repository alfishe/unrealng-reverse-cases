#!/usr/bin/env python3
"""Docs 11 and 12 of the case: every data entry and every routine of every annotated part, through kit/refdocs.py.

    python3 tools/zsB_refdocs.py [--work work/zsB/refcase]

kit/refdocs.py reads one case: case.json, work/mkgame/game.ctl (kit/mkgame.py's control file), src/game/game.ann and
the L1 builds work/<key>/l1.json. This case has nine annotated parts, each with its own .ann, its own control file
(written by kit/mkgame.py --part src/<part>/<name>.json under work/stage2/) and its own recordings. For each part this
script makes a scratch case under --work with those files linked (the patches block's pieces each get the lines of
their own piece of src/patches99/patches.ann), runs kit/refdocs.py there, and joins the parts into
docs/11-data-reference.md and docs/12-routine-reference.md, one section a part, the headings one level down.
Nothing outside --work and the two documents is written. The control files are the parts' own: run
tools/regen.sh (or the part's kit/mkgame.py --part) first when an .ann changed.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
KIT = os.path.join(CASE, '..', '..', 'kit')
S2 = 'work/stage2'

ALL_BASES = {'5': '4000', '2': '8000', '0': 'C000'}
# (key, title, src dir, ann, ctl, lo, hi, builds [(key, l1 dir, text)], animations)
PARTS = [
    ('game99', "The '99 game (`src/game99`)", 'src/game99', 'src/game99/game.ann', f'{S2}/game99/mkgame/out-game/game.ctl',
     '6780', 'D7D3',
     [('deep99', 'work/zsB/deep', "the bot's game on HARD, built-in level, 30602 frames from START (doc 10)"),
      ('map0', 'work/zsB/deep-map0', "the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)"),
      ('r99-play', f'{S2}/game99/r99-play', 'the start-up menu, LOAD MAP, HARD + PHASERS, play'),
      ('crit-play', f'{S2}/game99/crit-play', 'CRITICAL with every upgrade, several game days'),
      ('loadmap-menu', f'{S2}/game99/loadmap-menu', 'LOAD MAP: the catalogue and a map loaded')], True),
    ('game98', "The '98 game (`src/game98`)", 'src/game98', 'src/game98/game.ann', f'{S2}/game98/mk/game.ctl',
     '6780', 'D880',
     [('deep98', f'{S2}/game98/deep', "the bot's '98 game, 30284 frames, 9 game days"),
      ('play98', f'{S2}/game98/play', 'r98 4500-5903: the menu, START GAME, play'),
      ('key5menu', f'{S2}/game98/key5menu', 'the menu, LOAD NEW LEVEL, the menu again, START')], False),
    ('intro98', "The '98 intro (`src/intro98`)", 'src/intro98', 'src/intro98/intro.ann', f'{S2}/intro98/mkgame/game.ctl',
     'C000', 'EA00', [('w-intro', f'{S2}/intro98/w-intro', "r98's intro window")], False),
    ('stage2', "The '99 stage 2: the intro (`src/stage2`)", 'src/stage2', 'src/stage2/stage2.ann',
     f'{S2}/front99/mk-stage2/stage2.ctl', '61A8', '7D87', [('intro99', f'{S2}/front99/intro', "r99's intro window")],
     False),
    ('pictures99', "The '99 pictures block (`src/pictures99`)", 'src/pictures99', 'src/pictures99/pictures.ann',
     f'{S2}/front99/mk-pictures/pictures.ctl', '7D87', '8A87', [('intro99', f'{S2}/front99/intro', "r99's intro window")],
     False),
    ('music99', "The '99 music block (`src/music99`)", 'src/music99', 'src/music99/music.ann',
     f'{S2}/front99/mk-music/music.ctl', 'C000', 'CD00', [('intro99', f'{S2}/front99/intro', "r99's intro window")],
     False),
    ('stage3', "The '99 stage 3: System checking (`src/stage3`)", 'src/stage3', 'src/stage3/stage3.ann',
     f'{S2}/menu99/mk-stage3/game.ctl', '61A8', '67EC',
     [('r99-s3a', f'{S2}/menu99/r99-s3a', 'r99 2194-2300'), ('r99-s3b', f'{S2}/menu99/r99-s3b', 'r99 2299-2662'),
      ('s99-s3', f'{S2}/menu99/s99-s3', 'the Scorpion'), ('r48-s3', f'{S2}/menu99/r48-s3', 'the 48 K path')], False),
    ('menu99', "The '99 start-up menu (`src/menu99`)", 'src/menu99', 'src/menu99/menu.ann',
     f'{S2}/menu99/mk-menu/game.ctl', 'D800', 'E6F4',
     [('r99-menu', f'{S2}/menu99/r99-menu', 'r99 2661-6462'), ('m99-menu1', f'{S2}/menu99/m99-menu1', 'every item'),
      ('m99-menu4', f'{S2}/menu99/m99-menu4', 'REDEFINE')], False),
]
# The patches block: one piece a run address (tools/game99_image.py PIECES), its lines of patches.ann
PIECES = [('diskread', 'A598', 'A5D6'), ('diskmap', 'C1FD', 'C333'), ('paging128', 'A56A', 'A598'),
          ('menu128', 'C100', 'C17F'), ('taperead', 'A598', 'A5D6'), ('tapemap', 'C1FD', 'C333'),
          ('textload48', 'A56A', 'A598'), ('menu48', 'C100', 'C17F')]
PATCH_BUILDS = [('r99-play', f'{S2}/game99/r99-play', 'the start-up menu, LOAD MAP, HARD + PHASERS, play'),
                ('loadmap-menu', f'{S2}/game99/loadmap-menu', 'LOAD MAP: the catalogue and a map loaded')]

INTRO12 = """# 12. Routine reference

Every code entry of every annotated part of both releases, part by part, in address order by module. The name, the
title and the description are the source's (the part's `.ann`); the rest is what that part's recordings saw:

- **Runs** count the calls of the entry itself; the time is its own t-states (callees excluded) and its share of the
  recording.
- **Called from / Calls** are the calls the recordings made; "(tail)" is a jump into another entry.
- **Reads / Writes** name the entries the ranges cover; past the part's bytes they are the work space (the robots
  `$DA00`, the map `$DD00`, the variables `$FD00`).
- **Ports** as L1 saw them: `$FE` the border and the beeper, `$7FFD` the pages, `$FFFD` / `$BFFD` the AY, `$1F` the
  Kempston stick, `$xxFE` keyboard half rows.
- An entry no recording reached says so; such code is read, not seen (the '99's tape and one-page pieces).

The recordings are local (`work/`), not in the repository; [the WALKTHROUGH](../WALKTHROUGH.md) and
`work/docs/zsB-NOTES.md` give the commands. The routines with an animation link it
(`docs/img/routines/<Label>.gif`, the '99 game only); where a routine's rules are explained with figures:

| Routines | Explained in |
| --- | --- |
| `WorldTurn`, `UpdateRobot`, `RobotStep`, `TurnOrStep`, `PlaceRobot`, `FireShot`, `MoveShot`, `BuildMap` | [7. Objects](07-objects.md) |
| `DrawPlayScreen`, `PrintInline`, `PrintChar`, `PrintBigChar`, `UpdateStatusPanel`, the start-up menu's viewer | [8. HUD and text](08-hud-and-text.md) |
| `SoundEffect`, `Beep`, `PlayInterrupt`, the PT3 and Sound Tracker players | [9. Sound](09-sound.md) |
| `GameTurn`, `DailyProduction`, `EnemyCommander`, `UpgradeEnemyRobots`, `FillEnemyResources`, `GameTurnEnd`, `CheckGameEnd` | [10. Gameplay logic](10-gameplay-logic.md) |

Written by `python3 tools/zsB_refdocs.py` (through `kit/refdocs.py`); edit the part's `.ann`, run
`kit/mkgame.py --part` on its part file (all: `tools/regen.sh`), then this script.
"""

INTRO11 = """# 11. Data reference

Every data entry of every annotated part of both releases, part by part, in address order by module: tables,
buffers, records, graphics, text. The name, the title and the description are the source's (the part's `.ann`); the
readers and writers are the routines the part's recordings saw touch it (local, not in the repository). The
records of the work space past the images (robots `$DA00`, shots `$D7D3`, the map `$DD00`, buildings `$FF01`,
capture points `$FD70`) are laid out in [7. Objects](07-objects.md); the texts are in [8](08-hud-and-text.md) and
[texts/](texts/README.md); the tunes in [9](09-sound.md).

Written by `python3 tools/zsB_refdocs.py` (through `kit/refdocs.py`).
"""


def link(path, target):
    if os.path.islink(path) or os.path.exists(path):
        if os.path.isdir(path) and not os.path.islink(path):
            shutil.rmtree(path)
        else:
            os.remove(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    os.symlink(target, path)


def piece_ann(name, lo, hi, out):
    """The lines of src/patches99/patches.ann before the first piece (less the @equ names inside the piece's own
    range: there they are its labels), and those of piece NAME"""
    head, body, current = [], [], None
    for line in open(os.path.join(CASE, 'src/patches99/patches.ann')):
        m = re.match(r'#\s*@piece\s+(\w+)', line)
        if m:
            current = m.group(1)
            continue
        if current is None:
            e = re.match(r'@equ \$([0-9A-Fa-f]{4})', line)
            if not (e and int(lo, 16) <= int(e.group(1), 16) < int(hi, 16)):
                head.append(line)
        elif current == name:
            body.append(line)
    open(out, 'w').write(''.join(head + body))


def run_part(work, key, title, src, ann, ctl, lo, hi, builds, animations):
    case = os.path.join(work, key)
    os.makedirs(case, exist_ok=True)
    import json
    json.dump({'lo': lo, 'hi': hi, 'bases': ALL_BASES, 'read_builds': [b[0] for b in builds],
               'ref_builds': [[b[0], b[2]] for b in builds]}, open(os.path.join(case, 'case.json'), 'w'), indent=1)
    os.makedirs(os.path.join(case, 'src', 'game'), exist_ok=True)
    if ann.startswith('/'):
        shutil.copy(ann, os.path.join(case, 'src', 'game', 'game.ann'))
    else:
        link(os.path.join(case, 'src', 'game', 'game.ann'), os.path.join(CASE, ann))
    link(os.path.join(case, 'work', 'mkgame', 'game.ctl'), os.path.join(CASE, ctl))
    for b, d, _ in builds:
        link(os.path.join(case, 'work', b), os.path.join(CASE, d))
    if animations:
        link(os.path.join(case, 'docs'), os.path.join(CASE, 'docs'))
    out = os.path.join(case, 'out')
    os.makedirs(out, exist_ok=True)
    p = subprocess.run([sys.executable, os.path.join(KIT, 'refdocs.py'), '--case', case, '--docs', out],
                       capture_output=True, text=True)
    if p.returncode:
        sys.exit(f'{key}: {p.stderr or p.stdout}')
    t12 = open(os.path.join(out, '12-routine-reference.md')).read()
    t11 = open(os.path.join(out, '11-data-reference.md')).read()
    return section(t12, '| Module | Entries | Code entries |', title, src, builds, key), \
        section(t11, '## ', title, src, builds, key, data=True)


def section(text, start, title, src, builds, key, data=False):
    i = text.find(start)
    body = text[i:] if i >= 0 else ''
    body = body.replace('`src/game/', '`%s/' % src)
    # the module table's links would collide between parts: plain names
    body = re.sub(r'\[`(\w+)`\]\((?:11-data-reference\.md)?#\w+\)', r'`\1`', body)
    lines = []
    for line in body.split('\n'):
        if line.startswith('#'):
            line = '#' + line
        lines.append(line)
    body = '\n'.join(lines).rstrip() + '\n'
    rec = ', '.join(f'`{d}` ({t})' for _, d, t in builds)
    head = f'## {title}\n\nRecordings: {rec}.\n\n'
    if data and not body.strip():
        body = 'No data entries.\n'
    return head + body


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', default=os.path.join(CASE, 'work', 'zsB', 'refcase'))
    a = p.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(work, exist_ok=True)
    s12, s11 = [], []
    for part in PARTS:
        builds = [b for b in part[7] if os.path.exists(os.path.join(CASE, b[1], 'l1.json'))]
        r12, r11 = run_part(work, *part[:7], builds, part[8])
        s12.append(r12)
        s11.append(r11)
    for name, lo, hi in PIECES:
        ann = os.path.join(work, f'patch-{name}.ann')
        piece_ann(name, lo, hi, ann)
        r12, r11 = run_part(work, 'patch-' + name, f"The '99 patches block: `{name}` (`src/patches99`)", 'src/patches99',
                            ann, f'{S2}/game99/mkgame/out-patches/patches-{name}.ctl', lo, hi, PATCH_BUILDS, False)
        s12.append(r12)
        s11.append(r11)
    toc12 = '\n'.join('- ' + s.split('\n')[0][3:] for s in s12)
    open(os.path.join(CASE, 'docs', '12-routine-reference.md'), 'w').write(
        INTRO12 + '\nThe parts:\n\n' + toc12 + '\n\n' + '\n'.join(s12))
    open(os.path.join(CASE, 'docs', '11-data-reference.md'), 'w').write(
        INTRO11 + '\nThe parts:\n\n' + toc12 + '\n\n' + '\n'.join(s11))
    print('written docs/11-data-reference.md, docs/12-routine-reference.md')


if __name__ == '__main__':
    main()
