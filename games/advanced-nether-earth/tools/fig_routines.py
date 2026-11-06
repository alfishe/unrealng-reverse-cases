#!/usr/bin/env python3
"""Doc 12: every routine of the game in play, through kit/refdocs.py on a scratch copy of the case.

    python3 tools/fig_routines.py [--out docs/12-routine-reference.md] [--work work/docL/refcase]

kit/refdocs.py needs work/mkgame/game.ctl, which kit/mkgame.py writes. This script writes that control file into a
scratch case (--work) with kit/mkgame.py's own functions (the image work/mkgame/original.bin, the code the recordings
ran, the static walk, the entries of src/game/game.ann), links src/ and the recordings into it, runs kit/refdocs.py
there and keeps only doc 12, with this case's header and the parts of the game that live in the other banks.
Nothing outside --work and --out is written.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
KIT = os.path.join(CASE, '..', '..', 'kit')
sys.path.insert(0, KIT)
import mkgame  # noqa: E402

BUILDS = [
    ['deep', "`work/docL/deep`, the bot's game"],
    ['game-r2', '`work/game-r2`, save and load'],
    ['game', "`work/game`, the first game"],
]
LINKS = {'deep': 'work/docL/deep', 'game-r2': 'work/game-r2', 'game': 'work/game'}

HEADER = """# 12. Routine reference

Every code entry of the game in play, in address order by module (`src/game/<module>.asm`): the image of banks 5, 2
and 0 at `$6731`-`$D7D7` as the CPU sees it once the game block is unpacked. The name, the title and the description
are the source's (`src/game/game.ann`). The rest is what the recordings saw:

- `work/docL/deep`: the bot's game, 36009 frames from the game menu (robots built, orders given, factories captured,
  fights; [10.13](10-gameplay-logic.md#1013-what-the-deep-recording-showed));
- `work/game-r2`: stage 3's recording `r2` from the game's entry: a save and two loads through the disk module;
- `work/game`: stage 1's first game of the SCL, the menu and play to frame 11601.

They are local, not in the repository; the WALKTHROUGH's commands rebuild them.

- **Runs** count the calls of the entry itself. The time is its own t-states (callees excluded) and its share of the
  recording.
- **Called from / Calls** are the calls the recordings made, by entry; "(tail)" is a jump into another entry. The
  interrupt is left out: L1 counts the IM 2 jump (`ImJump`) and the vector read (`ImTable` `$68FF`-`$6900`) to
  whatever routine it falls in.
- **Reads / Writes** name the entries the ranges cover; past the image (`$D7D3` on) they are the variables of
  `src/game/game.ann`'s `@equ` lines (the robots, the map, the variables page).
- **Ports** are as L1 saw them: `$7FFD` pages, `$FE` the border and the beeper, `$FFFD` / `$BFFD` the AY.
- An entry no recording reached says so; such code is read, not seen.

Where a routine's rules are explained with figures, the chapter is named here:

| Routines | Explained in |
| --- | --- |
| `GameEntry`, `Restart`, `NewGameSetup`, `EnterPlay`, `PlayLoop` | [10.1 The start of a game](10-gameplay-logic.md#101-the-start-of-a-game) |
| `GameTurn`, `TurnPace`, `DailyProduction`, `ProduceSide`, `AddCapped` | [10.2](10-gameplay-logic.md#102-the-game-turn-and-the-clock), [10.3](10-gameplay-logic.md#103-production-and-resources) |
| `ConstructionMenu`, `ConstructionMenuLoop`, `RefundPart`, `StartRobot` | [10.4 Construction](10-gameplay-logic.md#104-construction) |
| `WorldTurn`, `UpdateRobot`, `RobotStep`, `SteerByOrder`, `RobotAim`, `SpotEnemies`, `SetStepDelay` | [7.2](07-objects.md#72-the-world-turn), [10.5](10-gameplay-logic.md#105-a-robots-turn-and-its-orders) |
| `FireShot`, `UpdateShot`, `MoveShot`, `ShotGone` | [7.5](07-objects.md#75-shots), [10.6](10-gameplay-logic.md#106-shooting-and-damage) |
| `GameTurnEnd`, `GiveFactory`, `GiveWarbase`, `SetBaseOwner`, `CountBases` | [10.7 Capture](10-gameplay-logic.md#107-capture) |
| `EnemyCommander`, `EnemyReplan`, `EnemyChooseOrder` | [10.8 The enemy commander](10-gameplay-logic.md#108-the-enemy-commander) |
| `NuclearBlast`, `BlastArea`, `NuclearFlash`, `NuclearRumble` | [10.9 The nuclear blast](10-gameplay-logic.md#109-the-nuclear-blast) |
| `GameLoad`, `LoadReturn`, `SaveGameStage`, `GameSave`, `SaveReturn`, `CheckGameEnd`, `GameWon` | [10.10](10-gameplay-logic.md#1010-load-save-and-the-end-of-a-game) |
| the bugs | [10.11 Bugs](10-gameplay-logic.md#1011-bugs) |

Written by `python3 tools/fig_routines.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

"""

OTHER_BANKS = """## The other banks

The game calls into four other banks at `$C000`. Their code is not part of the game image; each has its own source
and its own chapter. The entries the game uses:

| Bank | Address | Name | What the game does with it |
| --- | --- | --- | --- |
| 1 | `$C000` | `PlayerInit` | `Restart` calls it: the tune from its beginning |
| 1 | `$C005` | `PlayerFrame` | `MusicInterrupt` and `PlayMusic` call it once a frame: one 50 Hz step of the tune |
| 1 | `$D8E1` | `MusicStart` | `GameEntry` calls it once: bank 1's start-up code, the title cards (`src/music/title-cards.asm`) |
| 3 | `$E73B` | `MenuPictureCode` | `MenuPicture` calls it: the game menu's picture onto the screen |
| 3 | `$D2EF` | `DeadEnd` | `CheckGameEnd` jumps to it when we have no warbase: the lost game's ending |
| 4 | `$C000` | `DiskModule` | `GameLoad` and `GameSave` jump to it with IX = `$4000` (load) or `$4033` (save) |
| 6 | `$C000` | `FinalCutBlock` | `GameWon` copies its first `$3637` bytes to `FinalCut` `$6060` and jumps there: the won game's ending |

The tunes and their player are built from `src/music/`, the disk module from `src/disk/`, the endings from
`src/endings/` ([3. Build and load](03-build-and-load.md)); the endings' screens are in
[5.10](05-controls.md#510-the-intro-and-the-endings).
"""


# The other parts of ANE: their routines as tools/build.sh assembles them (the listings in build/), one table a
# source file, each file once (the first listing that includes it). (listing, the part's title)
PARTS = [
    ('build/boot.lst', 'The boot BASIC and UltraXOR (`src/boot/`)'),
    ('build/loader.lst', 'The loader (`src/loader.asm`)'),
    ('build/blocks.lst', 'The HRUM 3.5 depackers of the blocks (`src/sfx/`)'),
    ('build/intro/intro.lst', 'The intro (`src/intro/`)'),
    ('build/intro/presents.lst', 'The intro (`src/intro/`)'),
    ('build/intro/scroller.lst', 'The intro (`src/intro/`)'),
    ('build/intro/title.lst', 'The intro (`src/intro/`)'),
    ('build/bootmenu/bootmenu.lst', 'The boot menu and the help (`src/bootmenu/`)'),
    ('build/disk/starter.lst', 'The game starter and the disk module (`src/disk/`)'),
    ('build/disk/diskio.lst', 'The game starter and the disk module (`src/disk/`)'),
    ('build/disk/bank7.lst', 'The game starter and the disk module (`src/disk/`)'),
    ('build/music/music-bank1.lst', 'The music: players, tunes, title cards (`src/music/`)'),
    ('build/music/boot-music.lst', 'The music: players, tunes, title cards (`src/music/`)'),
    ('build/music/intro-music.lst', 'The music: players, tunes, title cards (`src/music/`)'),
    ('build/endings/deadend.lst', 'The endings (`src/endings/`)'),
    ('build/endings/finalcut.lst', 'The endings (`src/endings/`)'),
]
DATA_OPS = {'DB', 'DW', 'DD', 'DEFB', 'DEFW', 'DEFD', 'DEFS', 'DS', 'DEFM', 'DM', 'DZ', 'DC', 'BLOCK', 'INCBIN', 'ABYTE',
            'ABYTEZ', 'ABYTEC', 'BYTE', 'WORD'}


def listing_routines(path):
    """[(source file, address, label, title)] of the code labels in an sjasmplus listing"""
    lines = open(path, errors='replace').read().split('\n')
    files, out = [], []
    comment, pending = [], None
    for line in lines:
        if line.startswith('# file opened:'):
            files.append(line.split(':', 1)[1].strip())
            continue
        if line.startswith('# file closed:'):
            if files:
                files.pop()
            continue
        m = re.match(r'^\s*\d+\+*\s+([0-9A-F]{4})\s(.{12}) ?(.*)$', line)
        if not m:
            continue
        addr, code, src = int(m.group(1), 16), m.group(2).strip(), m.group(3)
        if pending and code:  # the first emitting line after a label tells code from data
            op = src.split(';')[0].split()
            if op and op[0].upper() not in DATA_OPS and not op[0].endswith(':'):
                out.append(pending)
            pending = None
        if src.startswith(';'):
            text = src.lstrip(';').strip()
            if text and not comment:
                comment = [text]
            elif not text:
                comment = comment + [''] if comment else []
            continue
        lm = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):?(\s+;\s*(.*))?$', src)
        if lm and not re.search(r'\bEQU\b', src, re.I):
            title = (lm.group(3) or (comment[0] if comment else '')).strip()
            pending = (files[-1] if files else os.path.basename(path), addr, lm.group(1), title)
            op = None
        elif src.strip():
            comment = []
    return out


def other_parts():
    """Section 12.x: the routines of ANE outside the game image"""
    out = ['## The other parts of the game', '',
           'Every code label of the parts outside the game image, as `tools/build.sh` assembles them (the listings in',
           '`build/`): the address where it runs, its name and the first line of its comment in the source. A source',
           'file that two parts include (a player) is listed once, at the address of its first build. The behaviour of',
           'these parts is in [2. Architecture](02-architecture.md) and [3. Build and load](03-build-and-load.md); this',
           'section only names them.', '']
    done, current = set(), None
    for listing, part in PARTS:
        path = os.path.join(CASE, listing)
        if not os.path.exists(path):
            continue
        rows = {}
        for src, addr, label, title in listing_routines(path):
            if src in done:
                continue
            rows.setdefault(src, []).append((addr, label, title))
        if not rows:
            continue
        if part != current:
            current = part
            out += ['### ' + part, '']
        for src, entries in rows.items():
            done.add(src)
            out += ['`%s` (`%s`)' % (src, listing), '', '| Address | Routine | What |', '| --- | --- | --- |']
            for addr, label, title in entries:
                t = re.sub(r'(\$[0-9A-Fa-f]{2,4})', r'`\1`', title).replace('|', '\\|')
                out.append('| `$%04X` | `%s` | %s |' % (addr, label, t or '-'))
            out.append('')
    return '\n'.join(out)


def tidy(body, ann):
    """Leave the interrupt out of the calls and reads, and name the work space by its EQUs"""
    equ = sorted((a, n, size) for a, (n, size, _) in ann.equ.items())

    def name(a):
        for lo, n, size in equ:
            if lo <= a < lo + size:
                return n
        return None

    def work(m):
        lo = int(m.group(1), 16)
        hi = int(m.group(2), 16) if m.group(2) else lo
        names = []
        a = lo
        while a <= hi:
            n = name(a)
            if n and n not in names:
                names.append(n)
            a += 1
        shown = ', '.join('`%s`' % n for n in names[:4]) + (' and %d more' % (len(names) - 4) if len(names) > 4 else '')
        return m.group(0).split(' (')[0] + ' (%s)' % (shown or 'work space')
    body = re.sub(r'`\$([0-9A-F]{4})`(?:-`\$([0-9A-F]{4})`)? \(`work space \$[0-9A-F]{4}\+`\)', work, body)
    lines = []
    for line in body.split('\n'):
        if line.startswith('| Calls |') or line.startswith('| Called from |'):
            head, items = line[:line.index('|', 2) + 1], line[line.index('|', 2) + 1:].rstrip(' |').strip()
            kept = [x for x in items.split(', ') if not x.startswith('`ImJump`')]
            if not kept:
                continue
            line = '%s %s |' % (head, ', '.join(kept))
        if line.startswith('| Reads |'):
            line = line.replace('`$68FF`-`$6900` (`ImTable`); ', '').replace('| `$68FF`-`$6900` (`ImTable`) |', '| - |')
            if line == '| Reads | - |':
                continue
        lines.append(line)
    return '\n'.join(lines)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(CASE, 'docs', '12-routine-reference.md'))
    p.add_argument('--work', default=os.path.join(CASE, 'work', 'docL', 'refcase'))
    args = p.parse_args()
    work = os.path.abspath(args.work)
    # the control file, as kit/mkgame.py writes it, from the case read only
    config = mkgame.load_case(CASE)
    mem = open(os.path.join(CASE, config['image']), 'rb').read()
    starts, entries, reads = mkgame.load_l1(sorted(glob.glob(os.path.join(CASE, 'work', '*', 'l1.json'))), mem)
    ann = mkgame.Annotations(os.path.join(CASE, 'src', 'game', 'game.ann'))
    code, targets, calls = mkgame.walk(mem, starts, reads, [a for a, e in ann.entries.items() if e[0] == 'c'],
                                       ann.inline_data)
    os.makedirs(os.path.join(work, 'work', 'mkgame'), exist_ok=True)
    mkgame.write_ctl(mem, code, targets, calls, entries, ann, os.path.join(work, 'work', 'mkgame', 'game.ctl'))
    # the scratch case: case.json with these builds, src/ and the recordings linked
    config = dict(config, ref_builds=BUILDS)
    json.dump(config, open(os.path.join(work, 'case.json'), 'w'), indent=1)
    links = {'src': os.path.join(CASE, 'src')}
    links.update({os.path.join('work', k): os.path.join(CASE, v) for k, v in LINKS.items()})
    for name, target in links.items():
        path = os.path.join(work, name)
        if os.path.islink(path):
            os.remove(path)
        os.symlink(target, path)
    out = os.path.join(work, 'out')
    subprocess.run([sys.executable, os.path.join(KIT, 'refdocs.py'), '--case', work, '--docs', out], check=True)
    text = open(os.path.join(out, '12-routine-reference.md')).read()
    body = text[text.index('| Module | Entries | Code entries |'):]
    body = re.sub(r'\n+$', '\n', body)
    body = tidy(body, ann)
    body = data_anchors(body)
    open(args.out, 'w').write(HEADER + body + '\n' + OTHER_BANKS + '\n' + other_parts())
    print('written', os.path.relpath(args.out, CASE))


def data_anchors(body):
    """kit/refdocs.py links a data-only module to its own doc 11's `## module` heading; this case's doc 11
    (tools/fig_dataref.py) titles the module's heading, so the link takes that heading's GitHub slug"""
    sys.path.insert(0, KIT)
    import check_docs
    slugs = check_docs.anchors(os.path.join(CASE, 'docs', '11-data-reference.md'))

    def fix(m):
        name = m.group(1)
        hits = sorted(s for s in slugs if s == name or s.startswith(name + '-'))
        return '(11-data-reference.md#%s)' % (hits[0] if hits else name)
    return re.sub(r'\(11-data-reference\.md#([\w-]+)\)', fix, body)


if __name__ == '__main__':
    main()
