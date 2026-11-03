#!/usr/bin/env python3
"""The title tune model of tools/res_preview.py (docs/09-sound.md) against the first recording (work/c2): reads the
player's operands `$8000-$83FF` at the start of every frame from the first note on and compares, frame by frame,

- the period of voice A (`$82CA`) and voice B (`$832C`) and every note start, a repeated pitch included (the period
  operand changes or the pulse width `$82D4` / `$8336` is set back up);
- every drum step (the timer `$8244` reloaded from the speed `$824B`; the position `$8250` past the step) and the
  sound it plays;
- the length of the song: the periods repeat after the frame the model jumps back.

    python3 tools/verify_tune.py [--first 2617] [--passes 2] [--unreal UNREAL_NG_CHECKOUT]

Needs build/game.bin and an unreal-ng instance with work/c2 open (re_session.py open --ttd work/c2/hate.ttd).
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import res_preview  # noqa: E402

PERIOD, WIDTH = (0x82CA, 0x832C), (0x82D4, 0x8336)
DRUM_TIMER, DRUM_SPEED, DRUM_POSITION = 0x8244, 0x824B, 0x8250


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--first', type=int, default=2617, help='the frame of the first note in the recording')
    p.add_argument('--passes', type=int, default=2, help='passes of the song to compare')
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(os.path.join(ROOT, 'work', 'c2'))
    mem = bytes(res_preview.LO) + open(os.path.join(ROOT, 'build', 'game.bin'), 'rb').read()
    notes, drums, end = res_preview.title_tune(mem)
    frames = {}
    for f in range(args.first - 1, args.first + end * args.passes + 1):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                         'offset': 0x8000, 'length': 0x400}, ok=False)
        frames[f - args.first] = bytes.fromhex(r.structured['hex'])

    def at(t, address):
        return frames[t][address - 0x8000]

    failures = 0
    for v in (0, 1):
        played = [at(t, PERIOD[v]) for t in range(end)]
        model = [0] * end
        for start, stop, period in notes[v]:
            model[start:stop] = [period] * (stop - start)
        bad = [t for t in range(end) if played[t] != model[t]]
        started = {t for t in range(1, end) if at(t, PERIOD[v]) != at(t - 1, PERIOD[v]) or
                   at(t, WIDTH[v]) > at(t - 1, WIDTH[v])}
        expected = {s for s, _, _ in notes[v] if s}
        print(f'voice {"AB"[v]}: period equal in {end - len(bad)}/{end} frames; note starts {len(started & expected)}'
              f'/{len(expected)} (recording {len(started)})')
        failures += len(bad) + len(started ^ expected)
    position = lambda t: at(t, DRUM_POSITION) | at(t, DRUM_POSITION + 1) << 8  # noqa: E731
    # the first step leaves the operands as assembled, so a step is the timer just reloaded, not the position moved
    stepped = {(t, mem[position(t) - 1]) for t in range(0, end) if at(t, DRUM_TIMER) == at(t, DRUM_SPEED)}
    stepped = {s for s in stepped if s[1]}  # a step on a rest byte plays nothing
    expected = {d for d in drums if d[0] < end}
    print(f'drums: {len(stepped & expected)}/{len(expected)} steps at the frame with the sound (recording {len(stepped)})')
    failures += len(stepped ^ expected)
    loop = all(at(t, a) == at(t + end, a) for t in range(end * (args.passes - 1)) for a in PERIOD)
    print(f'song: {end} frames ({end / 50:.1f} s), the next pass {"repeats it" if loop else "differs"}')
    failures += not loop
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
