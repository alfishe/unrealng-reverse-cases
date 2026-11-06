#!/usr/bin/env python3
"""Docs 11 and 12 (the data and routine references) through kit/refdocs.py on a scratch copy of the case.

    python3 tools/fig_refdocs.py [--work work/gsB/refcase] [--sjasmplus SJASMPLUS]

kit/refdocs.py reads CASE/work/mkgame/game.ctl (kit/mkgame.py writes it into work/mkgame/main/) and the L1 of the
builds named in case.json "ref_builds". This script makes a scratch case in --work: case.json with this case's
recordings as the builds, src/ and docs/ linked (docs/ only for the routine animations refdocs links), the control
file and the image linked, the recordings linked under work/gsB/. It runs kit/refdocs.py there, gives both documents
this case's header, and adds to doc 12 the routines of the parts outside the game image (the GS drivers and the
loaders), assembled with sjasmplus into --work/lst (their listings). Nothing outside --work and docs/11-*, docs/12-*
is written.
"""
import argparse
import json
import os
import re
import subprocess
import sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
KIT = os.path.join(CASE, '..', '..', 'kit')
SJASMPLUS = toolpaths.sjasmplus(required=False) or 'sjasmplus'

BUILDS = [
    ['gsB/rT', "Hood's tape on Pentagon 128 + GS 512 KB from 48 BASIC (`USR 0`): the bot's game of 40134 frames, "
               "13 robots built, the fights from frame 17441 on"],
    ['gsB/rD', 'the SCL on Pentagon 128 + GS 512 KB from the main menu: the bot plays 2324 frames'],
    ['stage2/r1', 'the SCL on Pentagon 128 + GS 512 KB from the main menu: the bot builds 5 robots and gives their '
                  'orders, 12073 frames'],
]
LINKS = {'work/gsB/rT': 'work/gsB/rT', 'work/gsB/rD': 'work/gsB/rD', 'work/stage2/r1': 'work/stage2/r1',
         'src': 'src', 'docs': 'docs', 'work/mkgame/game.ctl': 'work/mkgame/main/game.ctl',
         'work/mkgame/original.bin': 'work/mkgame/original.bin'}

# (source, listing name, the part's title)
PARTS = [
    ('src/disk/driver.asm', 'disk-driver', 'The disk GS driver `neart021` (bank 1 `$C000`, `src/disk/driver.asm`)'),
    ('src/tape/driver.asm', 'tape-driver', "Hood's tape GS driver `neart021` (bank 6 `$C000`, `src/tape/driver.asm`)"),
    ('src/disk/loader.asm', 'disk-loader', 'The disk loader `neart000` code (`src/disk/loader.asm`)'),
    ('src/tape/loader.asm', 'tape-loader', "Hood's tape loader (`src/tape/loader.asm`)"),
]

HEAD11 = """# 11. Data reference

Every data entry of the game image `$6590`-`$FFFF` (banks 5, 2 and 0 as the CPU sees them in play), in address order
by module (`src/game/<module>.asm`): tables, buffers, records, variables, graphics, text. The name, the title and
the description are the source's (`src/game/game.ann`). The readers and writers are the routines that the
recordings saw touch the entry:

- `work/gsB/rT`: {rT};
- `work/gsB/rD`: {rD};
- `work/stage2/r1`: {r1}.

The recordings are local, not in the repository; [gsB-NOTES](../work/docs/gsB-NOTES.md) and the WALKTHROUGH give
the commands that make them. The robot, shot and map records are laid out in [7. Objects](07-objects.md); the
variables of play in [10. Gameplay logic](10-gameplay-logic.md). What lives on the GS card (the module, the 14
effects) is in [9.2](09-sound.md#92-what-the-card-holds).

Written by `python3 tools/fig_refdocs.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

"""

HEAD12 = """# 12. Routine reference

Every code entry of the game image, in address order by module (`src/game/<module>.asm`), then the routines of the
parts outside it: the two GS drivers and the two loaders. The name, the title and the description are the source's
(`src/game/game.ann`). The rest is what the recordings saw:

- `work/gsB/rT`: {rT};
- `work/gsB/rD`: {rD};
- `work/stage2/r1`: {r1}.

They are local, not in the repository; [gsB-NOTES](../work/docs/gsB-NOTES.md) and the WALKTHROUGH give the commands
that make them.

- **Runs** count the calls of the entry itself. The time is its own t-states (callees excluded) and its share of the
  recording.
- **Called from / Calls** are the calls the recordings made, by entry; "(tail)" is a jump into another entry.
- **Reads / Writes** name the entries the ranges cover.
- **Ports** are as L1 saw them: `$7FFD` pages (the GS driver's page in and bank 0 back), `$FE` the border and the
  keyboard. The GS ports `$B3` and `$BB` are written by the driver in its own page, listed under the drivers below.
- An entry no recording reached says so; such code is read, not seen.

Where a routine's rules are explained with figures, the chapter is named here:

| Routines | Explained in |
| --- | --- |
| `GsSound`, `GsMenuSound`, `SoundEffect`, `Beep`, `NuclearRumble`, the drivers | [9. Sound](09-sound.md) |
| `WorldTurn`, `UpdateRobot`, `RobotStep`, `FireShot`, `MoveShot`, `ShotGone` | [7. Objects](07-objects.md) |
| `PrintInline`, `PrintChar`, `PrintBigChar`, the number printers, `ShowRadar` | [8. HUD and text](08-hud-and-text.md) |
| `GameTurn`, `DailyProduction`, `ConstructionMenu`, `StartRobot`, `EnemyCommander`, the capture and the blast | [10. Gameplay logic](10-gameplay-logic.md) |

Written by `python3 tools/fig_refdocs.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

"""

DATA_OPS = {'DB', 'DW', 'DD', 'DEFB', 'DEFW', 'DEFD', 'DEFS', 'DS', 'DEFM', 'DM', 'DZ', 'DC', 'BLOCK', 'INCBIN'}


def listing_routines(path):
    """[(address, label, title)] of the code labels in an sjasmplus listing (local .labels included)"""
    out, comment, pending = [], [], None
    for line in open(path, errors='replace').read().split('\n'):
        m = re.match(r'^\s*\d+\+*\s+([0-9A-F]{4})\s(.{12}) ?(.*)$', line)
        if not m:
            continue
        addr, code, src = int(m.group(1), 16), m.group(2).strip(), m.group(3)
        if pending and code:
            op = src.split(';')[0].split()
            if op and op[0].upper() not in DATA_OPS and not op[0].endswith(':'):
                out.append(pending)
            pending = None
        if src.startswith(';'):
            text = src.lstrip(';').strip()
            if not text or set(text) <= set('-='):
                comment = comment + [None] if comment else []
            elif not comment or comment[-1] is not None:
                comment = comment + [text]  # the comment's first paragraph
            continue
        lm = re.match(r'^(\.?[A-Za-z_][A-Za-z0-9_]*):?(\s+;\s*(.*))?$', src)
        if lm and not re.search(r'\bEQU\b', src, re.I):
            para = []
            for c in comment:
                if c is None:
                    break
                para.append(c)
            title = (lm.group(3) or ' '.join(para)).strip()
            pending = (addr, lm.group(1), title)
            if code:
                op = src.split(';')[0].split()
                out.append(pending)
                pending = None
        elif src.strip():
            comment = []
    return out


def other_parts(work, sjasmplus):
    out = ['## The parts outside the game image', '',
           'Every code label of the GS drivers and the loaders as sjasmplus assembles their sources (the listings',
           'are written to the scratch case\'s `lst/`). Local labels (branches inside a routine) are left out.',
           'The drivers run in their own RAM page at `$C000` with interrupts off ([9.4](09-sound.md#94-the-drivers)); '
           'the',
           'loaders run once before the game ([3. Build and load](03-build-and-load.md)). L1 of `work/gsB/rT` saw the',
           'tape driver run (`$C000` page 6: 1030 calls); the disk driver ran in `work/gsB/rD` (page 1).', '']
    for d in ('lst', 'build/disk', 'build/tape'):  # the sources' OUTPUT lines write under the scratch case
        os.makedirs(os.path.join(work, d), exist_ok=True)
    for src, name, title in PARTS:
        lst = os.path.join(work, 'lst', name + '.lst')
        r = subprocess.run([sjasmplus, '--nologo', '--lst=' + lst, os.path.join(CASE, src)], cwd=work,
                           capture_output=True, text=True)
        if r.returncode or not os.path.exists(lst):
            print('sjasmplus', src, r.stdout[-400:], r.stderr[-400:])
            continue
        out += ['### ' + title, '', '| Address | Routine | What |', '| --- | --- | --- |']
        for addr, label, text in listing_routines(lst):
            if label.startswith('.'):  # a local label: a branch inside the routine above
                continue
            t = re.sub(r'(\$[0-9A-Fa-f]{2,4}(?:-\$?[0-9A-Fa-f]{2,4})?)', r'`\1`', text).replace('|', '\\|')
            t = re.sub(r'(#[0-9A-Fa-f]{2})\b', r'`\1`', t)
            out.append('| `$%04X` | `%s` | %s |' % (addr, label, t or '-'))
        out.append('')
    return '\n'.join(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--work', default=os.path.join(CASE, 'work', 'gsB', 'refcase'))
    p.add_argument('--sjasmplus', default=os.environ.get('SJASMPLUS', SJASMPLUS))
    args = p.parse_args()
    work = os.path.abspath(args.work)
    config = json.load(open(os.path.join(CASE, 'case.json')))
    config = dict(config, ref_builds=BUILDS, read_builds=[b[0] for b in BUILDS])
    os.makedirs(os.path.join(work, 'work', 'mkgame'), exist_ok=True)
    json.dump(config, open(os.path.join(work, 'case.json'), 'w'), indent=1)
    for name, target in LINKS.items():
        path = os.path.join(work, name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if os.path.islink(path):
            os.remove(path)
        os.symlink(os.path.join(CASE, target), path)
    out = os.path.join(work, 'out')
    subprocess.run([sys.executable, os.path.join(KIT, 'refdocs.py'), '--case', work, '--docs', out], check=True)
    desc = {'rT': BUILDS[0][1], 'rD': BUILDS[1][1], 'r1': BUILDS[2][1]}

    def runs(text):  # the long build names in the tables -> the short path
        for key, d in BUILDS:
            text = text.replace('(`work/%s`, %s)' % (key, d), '(`work/%s`)' % key)
        return text

    t11 = open(os.path.join(out, '11-data-reference.md')).read()
    t11 = t11[t11.index('\n## '):].lstrip('\n')
    open(os.path.join(CASE, 'docs', '11-data-reference.md'), 'w').write(HEAD11.format(**desc) + runs(t11))
    t12 = open(os.path.join(out, '12-routine-reference.md')).read()
    t12 = t12[t12.index('| Module | Entries | Code entries |'):].rstrip('\n') + '\n'
    open(os.path.join(CASE, 'docs', '12-routine-reference.md'), 'w').write(
        HEAD12.format(**desc) + runs(t12) + '\n' + other_parts(work, args.sjasmplus))
    print('written docs/11-data-reference.md, docs/12-routine-reference.md')


if __name__ == '__main__':
    main()
