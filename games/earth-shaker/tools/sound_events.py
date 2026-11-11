#!/usr/bin/env python3
"""Every speaker write, every entry of the sound and text routines and every interrupt of a window of a recording,
from access traces taken in chunks (docs 08 and 09).

    python3 tools/sound_events.py --work work/docs/esD/rzx01 --frames 760-860 --out work/docs/esD/rzx01-760.json
          [--chunk 50] [--keep]

The instance of --work holds the recording (`kit/rs.py open`). Each event carries its moment: the frame in which the
instruction ran and the CPU T-state in that frame (a trace's convention; a memory sample of frame N is the state at
the frame's start). The JSON holds:

- `out_fe`: [frame, t, value, pc] of every `OUT` to an even port (port `$FE`: bit 4 is the speaker);
- `calls`: [frame, t, name, A, BC, DE, HL, caller pc] of every entry of a routine in ENTRIES (the labels of
  build/game.lst) and of the ROM's BEEPER `$03B5`;
- `irq`: [frame, t, pc] of every interrupt taken;
- `di`: [frame, t, pc, iff] each time the interrupt flag changes (`DI` / `EI`).

tools/fig_sound.py and tools/fig_text.py read it.
"""
import argparse
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

NAMES = """PlayTune NoteLoop PlayNote TuneEnds GemSound ThudSound NoiseThud NoiseBurst FallSound DigNoiseIfDug DeathSound
ExitOpenSound RaspSound Jingle SwitchSound FizzSound AntiGravSound AntiGravPass TeleportOutEffect TeleportInEffect
JellyBean BonusTick TimeBonus QuitKey TimeOutSound TimerStep KeyClick PlayTitleTune PlayCaveTune PotionTune
PlayMapTune PlayGameOverTune PlayWinTune PassSound PrintText PrintDigits ShowScore ShowCounters CountGem AddPoints
AddPoint AddGemValue IncDigits ShowHudLine CaveIntro ShowLevelLivesScore RunScroller ScrollBottomLine EnterName
HiScoreInsert ShowHiScoreTable ShiftTimeBar FillTimeBar TimeRefill SwitchScore AntiGravStart PotionScore
BubbleScore CollectGem PassLoop WaitKey GameOverScreen ShowGameOver ShowHiScores WinGame""".split()


def labels():
    out = {}
    for line in open(os.path.join(CASE, 'build', 'game.lst')):
        m = re.match(r'\s*\d+\+?\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):\s*$', line)
        if m:
            out.setdefault(m.group(2), int(m.group(1), 16))
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--frames', required=True, help='F0-F1')
    p.add_argument('--chunk', type=int, default=50)
    p.add_argument('--out', required=True)
    p.add_argument('--keep', action='store_true')
    p.add_argument('--unreal')
    a = p.parse_args()
    lab = labels()
    entries = {lab[n]: n for n in NAMES if n in lab}
    entries[0x03B5] = 'RomBeeper'
    f0, f1 = (int(v) for v in a.frames.split('-'))
    out = {'work': os.path.relpath(a.work, CASE), 'frames': [f0, f1], 'frame_t': None, 'instructions': 0,
           'out_fe': [], 'calls': [], 'irq': [], 'di': []}
    iff = None
    for start in range(f0, f1, a.chunk):
        end = min(f1, start + a.chunk)
        ns = argparse.Namespace(trace=None, work=a.work, window=f'{start}:0-{end}:0', max_cycles=None,
                                unreal=a.unreal)
        trace = K.load_trace(ns)
        out['frame_t'] = trace.frame_t
        ins = trace.instructions
        out['instructions'] += len(ins)
        units = max(1, trace.units_per_t)
        if trace.truncated:
            print(f'{start}-{end}: TRUNCATED', file=sys.stderr)
        for i, x in enumerate(ins):
            for c in x.cycles:
                if c.tag == 'O' and (c.address & 1) == 0:
                    f, t = trace.cycle_t(x, c)
                    out['out_fe'].append([f, t, c.value, x.pc])
            name = entries.get(x.pc)
            if name:
                out['calls'].append([x.frame, x.t // units, name, x.af >> 8, x.bc, x.de, x.hl,
                                     ins[i - 1].pc if i else None])
            if x.interrupted:
                out['irq'].append([x.frame, x.t // units, x.pc])
            # DI / EI: the opcode is the first fetch
            f = x.cycles[0] if x.cycles else None
            if f is not None and f.tag == 'F' and f.address == x.pc and f.value in (0xF3, 0xFB):
                v = 1 if f.value == 0xFB else 0
                if v != iff:
                    out['di'].append([x.frame, x.t // units, x.pc, v])
                    iff = v
        if not a.keep:
            os.remove(os.path.join(os.path.abspath(a.work), 'traces', f'{start}_0-{end}_0.uatr'))
        print(f'{start}-{end}: {len(out["out_fe"])} speaker writes, {len(out["calls"])} calls', flush=True)
    with open(a.out, 'w') as f:
        json.dump(out, f)


if __name__ == '__main__':
    main()
