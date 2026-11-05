#!/usr/bin/env python3
"""Docs 11 and 12: every entry of the game, through kit/refdocs.py on a scratch copy of the case (advanced-nether-
earth's tools/fig_routines.py, copied and moved onto this case).

    python3 tools/fig_routines.py [--work work/zgsB/refcase] [--docs docs]

kit/refdocs.py reads the builds of case.json "ref_builds" (work/<key>/l1.json) and work/mkgame/game.ctl. This
script writes a scratch case (--work): game.ctl from kit/mkgame.py's own functions (the image work/mkgame/original.bin,
the code the recordings ran, the static walk, the code entries of src/game/game.ann), a case.json whose ref_builds
are the GS recording first and the 48K case's two recordings after it, and links to src/ and the recordings. It
runs kit/refdocs.py there, then writes docs 11 and 12 with this case's header and the GS parts that live outside
the image (the driver in bank 1). Nothing outside --work and --docs is written; case.json is read only.
"""
import argparse
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
KIT = os.path.normpath(os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, KIT)
import mkgame  # noqa: E402

# (key in the scratch case, the recording, what it is)
BUILDS = [
    ('gsplay', 'work/zgsB/gsplay',
     "the GS game's own play: stage 2's TTD recording `r1` (Pentagon 128 + GS 512 KB, music) replayed by L1 over "
     'its frames 2951-4724, level 1 from the round start (1773 frames; zgsA\'s `work/zgsA/r1-play`, copied)'),
    ('z48r1', 'work/z48r1',
     "the 48K case's `r1` (`../zynaps/work/r1`): all 12 levels and the wrap, 75000 frames (the same code at the same "
     'addresses, without the GS hooks)'),
    ('z48c2', 'work/z48c2', "the 48K case's `c2` (`../zynaps/work/c2`): level 1 from the start, 1500 frames"),
]

HEADER12 = """# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`): the image `$5C00`-`$FFFF` in
banks 5, 2 and 0 as the installer leaves it. The name, the title and the description are the source's
(`src/game/game.ann`). The rest is what the recordings saw:

{builds}

They are local, not in the repository; the WALKTHROUGH's commands rebuild them.

- **Runs** count the calls of the entry itself. The time is its own t-states (callees excluded) and its share of
  the recording.
- **Called from / Calls** are the calls the recordings made, by entry; "(tail)" is a jump into another entry.
- **Reads / Writes** name the entries the ranges cover.
- The patched call sites run their GS form only in `gsplay`; the 48K recordings have the original bytes there. The
  hook stubs the installer writes (`$FF1C`-`$FFD1`, `$B2F0`, `$B47F`, `$A6AE`) are not entries of the image: they
  have a table of their own at the end, with their counts over whole levels (the memory profiler, levels 1-11).
- An entry no recording reached says so; such code is read, not seen.

Where a routine's rules are explained with figures, the chapter is named here:

| Routines | Explained in |
| --- | --- |
| `RunObjects`, the handlers, `RunPath` and the path ops | [7. Objects](07-objects.md) |
| `PrintChar`, the panel, the score, `DrawLives` | [8. HUD and text](08-hud-and-text.md) |
| the hook stubs `$FF1C`-`$FFC3`, `ObjectSoundStub` `$B2F0`, `SlotGoneHook` `$B47F`, `WaitStub` `$A6AE` | [9.4](09-sound.md#94-where-the-game-makes-a-sound) |
| `PodStep`, `FireLaser`, `PlasmaFrame`, `HomingFrame`, `SeekerFrame`, `FuelOut` | [10.2](10-gameplay-logic.md#102-weapons-pods-and-the-selector), [10.3](10-gameplay-logic.md#103-fuel) |
| `PlayersSetup`, `SetLevelStart`, `CmdLevelEnd`, `EndOfPlay`, `MainLoop` | [10.5](10-gameplay-logic.md#105-levels-and-their-order), [10.6](10-gameplay-logic.md#106-the-hidden-options) |

Written by `python3 tools/fig_routines.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

"""

HEADER11 = """# 11. Data reference

Every data entry of the game image (`$5C00`-`$FFFF`) and every variable of `src/game/game.ann`, in address order by
module, with the routines the recordings saw read and write it:

{builds}

The object records' fields are drawn in [7. Objects](07-objects.md), the player record and the weapons' variables in
[10. Gameplay logic](10-gameplay-logic.md). The driver's data in bank 1 (its stubs' parameters, the FX tables) is in
[9. Sound](09-sound.md).

Written by `python3 tools/fig_routines.py` (through `kit/refdocs.py`); edit `src/game/game.ann` and run it again.

"""

STUBS = """## The hook stubs

The installer (`src/disk/install.asm`, `HookStubs`, `WaitStub` and the `$B2F0` / `$B47F` stubs) writes these into the
image over the 48K's title tune data and over the beeper routine. Each does the instruction its site lost, loads HL
with a driver entry and calls `CallDriver` (`$B466`) or, for the effects-only sounds, `CallDriverFx` (`$B482`). The
address is the one the memory profiler counted; "Ran" is the total of the zgsB runs e1, e2 and e3 plus stage 2's h2
(levels 1-11, `docs/img/sound/hooks.png`).

| Address | Stub | The site and what it replaced | Driver entry | Through | Ran |
| --- | --- | --- | --- | --- | --- |
{rows}
"""

DRIVER = """## The driver in bank 1

The GS driver is not part of the game image: the loader puts it in bank 1 at `$C000` (`src/disk/driver/driver.asm`,
annotated in `src/disk/driver.ann`) and the stubs at the top of the image page it in for each call. Its entries, as
the stubs call them:

| Address | Entry | What |
| --- | --- | --- |
{rows}

How each entry talks to the card is in [9. Sound](09-sound.md).
"""


def driver_rows():
    path = os.path.join(CASE, 'src', 'disk', 'driver.ann')
    rows = []
    for line in open(path):
        m = re.match(r'\$([0-9A-F]{4}) c (\w+) ; (.*)', line)
        if m:
            t = re.sub(r'(\$[0-9A-Fa-f]{2,4}|#[0-9A-Fa-f]{2})', r'`\1`', m.group(3).strip()).replace('|', '\\|')
            rows.append('| `$%s` | `%s` | %s |' % (m.group(1), m.group(2), t))
    return '\n'.join(rows)


STUB_AT = {'RoundStartHook': 0xFF1C, 'GameStartHook': 0xFF26, 'ExplodeHook': 0xFF3B, 'ShipHitHook': 0xFF44,
           'MissileLaunchHook': 0xFF4D, 'PlasmaLaunchHook': 0xFF56, 'EnemyFireHook': 0xFF60,
           'PlasmaBounceHook': 0xFF69, 'ShotHook': 0xFF6F, 'WeaponOnHook': 0xFF75, 'PodAppearsHook': 0xFF7B,
           'NextWeaponHook': 0xFF81, 'NextLevelHook': 0xFF87, 'SceneryBounceHook': 0xFF8F,
           'BigEnemyHitHook': 0xFF99, 'BigEnemyDestroyedHook': 0xFFA3, 'ArenaBounceHook': 0xFFAC, 'DiveHook': 0xFFB6,
           'AimPlayerHook': 0xFFC3, 'ObjectSoundStub': 0xB2F0, 'SlotGoneHook': 0xB47F, 'WaitStub': 0xA6AE}


STUB_SITE = {'WaitStub': '$B102 (EndOfPlay), the only caller of $A6AE left: the wait between rounds',
             'ObjectSoundStub': "the 48K's beeper request $B2F0 itself, called by the path movers $9694, $9747"}


def stub_counts():
    """the profiler counts by address: the zgsB bot runs (bot-counts.json, last entry) and h2 (fx-long.tsv, mortal.tsv;
    their columns are in STUB_AT's order)"""
    total = {a: 0 for a in STUB_AT.values()}
    for e in ('e1', 'e2', 'e3'):
        path = os.path.join(CASE, 'work', 'zgsB', e, 'bot-counts.json')
        if os.path.exists(path):
            for k, v in json.load(open(path))[-1]['counts'].items():
                if int(k, 16) in total:
                    total[int(k, 16)] += v
    order = list(STUB_AT.values())
    for name in ('fx-long.tsv', 'mortal.tsv'):
        path = os.path.join(CASE, 'work', 'stage2', 'h2', name)
        if os.path.exists(path):
            for line in open(path).read().splitlines()[1:]:
                for a, v in zip(order, line.split('\t')[3:]):
                    total[a] += int(v)
    return total


def stub_rows():
    lines = open(os.path.join(CASE, 'src', 'disk', 'install.asm')).read().split('\n')
    counts = stub_counts()
    rows = []
    for i, line in enumerate(lines):
        m = re.match(r'^(\w+):\s*(?:;\s*(.*))?$', line)
        if not m or m.group(1) not in STUB_AT:
            continue
        name, what = m.group(1), (m.group(2) or '').strip()
        entry, via = '-', '-'
        for nxt in lines[i + 1:i + 30]:
            lab = re.match(r'^(\w+):', nxt)
            if lab and lab.group(1) in ('CallDriver', 'CallDriverFx') and via == '-':
                via = lab.group(1)
            if lab and not lab.group(1).endswith('At') and lab.group(1) != 'HookCall':
                break
            if re.match(r'\s+JR HookCall', nxt) and via == '-':
                via = 'CallDriver'
            e = re.match(r'\s+LD HL,(\w+)', nxt)
            if e and entry == '-':
                entry = e.group(1)
            c = re.search(r'(?:CALL|JP) (CallDriverFx|CallDriver)\b', nxt)
            if c and via == '-':
                via = c.group(1)
        what = what or STUB_SITE.get(name, '')
        what = re.sub(r'(\$[0-9A-Fa-f]{2,4})', r'`\1`', what).replace('|', '\\|') or '-'
        rows.append((STUB_AT[name], '| `$%04X` | `%s` | %s | `%s` | `%s` | %d |' % (
            STUB_AT[name], name, what, entry, via, counts[STUB_AT[name]])))
    return '\n'.join(r for _, r in sorted(rows))


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--docs', default=os.path.join(CASE, 'docs'))
    p.add_argument('--work', default=os.path.join(CASE, 'work', 'zgsB', 'refcase'))
    args = p.parse_args()
    work = os.path.abspath(args.work)
    config = mkgame.load_case(CASE)
    mem = open(os.path.join(CASE, config['image']), 'rb').read()
    l1s = [os.path.join(CASE, path, 'l1.json') for _, path, _ in BUILDS]
    starts, entries, reads = mkgame.load_l1(l1s, mem)
    ann = mkgame.Annotations(os.path.join(CASE, 'src', 'game', 'game.ann'))
    code, targets, calls = mkgame.walk(mem, starts, reads, [a for a, e in ann.entries.items() if e[0] == 'c'],
                                       ann.inline_data)
    os.makedirs(os.path.join(work, 'work', 'mkgame'), exist_ok=True)
    mkgame.write_ctl(mem, code, targets, calls, entries, ann, os.path.join(work, 'work', 'mkgame', 'game.ctl'))
    config = dict(config, ref_builds=[[k, d] for k, _, d in BUILDS])
    json.dump(config, open(os.path.join(work, 'case.json'), 'w'), indent=1)
    links = {'src': os.path.join(CASE, 'src'), 'tools': os.path.join(CASE, 'tools')}
    links.update({os.path.join('work', k): os.path.join(CASE, v) for k, v, _ in BUILDS})
    links[os.path.join('work', 'mkgame', 'original.bin')] = os.path.join(CASE, config['image'])
    links['docs'] = os.path.join(CASE, 'docs')  # read only: refdocs links the routine GIFs it finds there
    for name, target in links.items():
        path = os.path.join(work, name)
        if os.path.islink(path):
            os.remove(path)
        os.symlink(target, path)
    out = os.path.join(work, 'out')
    subprocess.run([sys.executable, os.path.join(KIT, 'refdocs.py'), '--case', work, '--docs', out], check=True)
    builds = '\n'.join(f'- `{k}`: {d}' for k, _, d in BUILDS)
    t12 = open(os.path.join(out, '12-routine-reference.md')).read()
    body12 = t12[t12.index('| Module | Entries | Code entries |'):].rstrip('\n') + '\n'
    body12 = body12.replace('`work/gsplay`', '`gsplay`').replace('`work/z48r1`', '`z48r1`').replace('`work/z48c2`', '`z48c2`')
    open(os.path.join(args.docs, '12-routine-reference.md'), 'w').write(
        HEADER12.format(builds=builds) + body12 + '\n' + STUBS.format(rows=stub_rows()) + '\n' +
        DRIVER.format(rows=driver_rows()))
    t11 = open(os.path.join(out, '11-data-reference.md')).read()
    first = t11.index('\n## ')
    body11 = t11[first + 1:].rstrip('\n') + '\n'
    open(os.path.join(args.docs, '11-data-reference.md'), 'w').write(HEADER11.format(builds=builds) + body11)
    print('written docs/11-data-reference.md, docs/12-routine-reference.md')


if __name__ == '__main__':
    main()
