#!/usr/bin/env python3
"""The beeper effects of Nether Earth measured from access traces (docs/09-sound.md): every OUT to port $FE in a
window, grouped by the routine that did it, and the pitch over time against the formulas of the code.

    python3 effects_chart.py extract --work work/docC/fight --window 18679:0-18712:0 --out work/docC/fx-fire.json
    python3 effects_chart.py chart --fire work/docC/fx-fire.json --chirp work/docC/fx-chirp.json \
                                   --out docs/img/sound-effects.png

`extract` traces the window once (kit/kitlib.load_trace keeps it in W/traces/) and writes each OUT ($FE) as
(T from the window start, bit 4, the PC of the OUT). `chart` draws two panels:

  - a shot: SoundEffect ($D5C4) at each frame while SoundFx ($FD53) counts. A positive SoundFx A gives pulses of
    13A + 63 T, each level bit 4 of the next ROM byte from $0000; the panel plots the pulse rate 3.5 MHz / interval
    and the formula's line. A negative SoundFx gives 30 levels from Random (NoiseLoop), plotted as their rate.
  - the build chirp: Beep ($CCAC) with A = $50 down to $14 by 5 (BuildChirp $CB82), then $C8
    (LeaveConstructionMenu); a Beep half-period is 13A + 50 T, the tone 3.5 MHz / (2 (13A + 50)).

The T-states are the trace's (contention included), so the measured points show what the formulas leave out.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

CLOCK = 3500000
ROUTINES = [(0xD5E0, 0xD5E0, 'SoundEffect pulses'), (0xD5E9, 0xD5E9, 'SoundEffect off'), (0xD5EC, 0xD5F7, 'SoundEffect noise'),
            (0xCCAC, 0xCCBC, 'Beep')]


def routine_of(pc):
    for lo, hi, name in ROUTINES:
        if lo <= pc <= hi:
            return name
    return f'${pc:04X}'


def extract(args):
    trace = K.load_trace(args)
    times = K.instruction_times(trace)
    out = []
    for x, t in zip(trace.instructions, times):
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0xFF == 0xFE:
                out.append((t + c.dt, c.value >> 4 & 1, x.pc, x.frame, x.reg('b')))
    start, _, _ = args.window.partition('-')
    json.dump({'window': args.window, 'from_frame': K.parse_moment(start, 0)[0], 'frame_t': trace.frame_t,
               'truncated': trace.truncated, 'outs': out}, open(args.out, 'w'))
    names = {}
    for o in out:
        names[routine_of(o[2])] = names.get(routine_of(o[2]), 0) + 1
    print(f'{len(out)} OUTs to $FE, {names}, truncated {trace.truncated}')


def bursts(outs, name, gap, same_b=True):
    """Runs of OUTs by one routine with the same B (the delay) and no pause longer than gap T: [[(t, b)]]"""
    runs, cur = [], None
    for t, bit, pc, frame, b in outs:
        if routine_of(pc) != name:
            continue
        if cur and t - cur[-1][0] <= gap and (b == cur[-1][1] or not same_b):
            cur.append((t, b))
        else:
            cur = [(t, b)]
            runs.append(cur)
    return runs


def chart(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import matplotlib.ticker  # noqa: F401
    plt.rcParams['text.parse_math'] = False
    fire, chirp = json.load(open(args.fire)), json.load(open(args.chirp))
    fig, axes = plt.subplots(2, 1, figsize=(12, 8.4), dpi=100)

    ax = axes[0]
    ft = fire['frame_t']
    for name, colour, label in (('SoundEffect pulses', '#1070d0', 'measured pulse rate (SoundFx 1..$7F, PulseLoop)'),
                                ('SoundEffect noise', '#d03010', 'measured level rate (SoundFx $FA..$FF, NoiseLoop)')):
        xs, ys = [], []
        for run in bursts(fire['outs'], name, 3000, name.endswith('pulses')):
            for (t0, _), (t1, _) in zip(run, run[1:]):
                xs.append(fire['from_frame'] + t0 / ft)
                ys.append(CLOCK / (t1 - t0))
        ax.plot(xs, ys, '.', ms=2.5, color=colour, label=label)
    # the formula: each frame's SoundFx A gives pulses of 13A + 63 T
    model_x, model_y = [], []
    for run in bursts(fire['outs'], 'SoundEffect pulses', 3000):
        t0, b = run[0]
        if b:
            model_x += [fire['from_frame'] + t0 / ft, fire['from_frame'] + run[-1][0] / ft]
            model_y += [CLOCK / (13 * b + 63)] * 2
            model_x.append(None)
            model_y.append(None)
    ax.plot(model_x, model_y, '-', color='#000000', lw=1.2, label='formula 3.5 MHz / (13A + 63), A = SoundFx')
    ax.set_yscale('log')
    ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f'{v:,.0f}'))
    ax.yaxis.set_minor_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f'{v:,.0f}'))
    ax.set_ylabel('rate (Hz)')
    ax.set_xlabel(f"frame of work/docC/fight (window {fire['window']}, T-states from the trace)")
    ax.set_title('a robot shot: fired at frame 18680 (SoundFx = 1, then +1 a frame), hit at 18702 (SoundFx = $FA)',
                 fontsize=10)
    ax.grid(alpha=0.3, which='both')
    ax.legend(fontsize=8, loc='upper right')

    ax = axes[1]
    ct = chirp['frame_t']
    runs = bursts(chirp['outs'], 'Beep', 8000)
    xs, ys = [], []
    for run in runs:
        for (t0, _), (t1, _) in zip(run, run[1:]):
            xs.append(t0 / CLOCK * 1000)
            ys.append(CLOCK / (2 * (t1 - t0)))
    t_first = xs[0] if xs else 0
    xs = [x - t_first for x in xs]
    ax.plot(xs, ys, '.', ms=2, color='#1070d0', label='measured: 3.5 MHz / (2 x the interval between two OUTs)')
    mx, my = [], []
    for run in runs:
        a = run[0][1]  # B at the first OUT is the delay A
        lo, hi = run[0][0] / CLOCK * 1000 - t_first, run[-1][0] / CLOCK * 1000 - t_first
        f = CLOCK / (2 * (13 * a + 50))
        mx += [lo, hi, None]
        my += [f, f, None]
        ax.annotate(f'${a:02X}', ((lo + hi) / 2, f), textcoords='offset points', xytext=(0, 7), ha='center',
                    fontsize=7)
    ax.plot(mx, my, '-', color='#000000', lw=1.2, label='formula 3.5 MHz / (2 (13A + 50)), A above each tone')
    first = chirp['from_frame'] + int(runs[0][0][0] // ct) if runs else chirp['from_frame']
    ax.set_title(f'the build chirp: {len(runs)} Beeps, BuildChirp A = $50 down to $14, then LeaveConstructionMenu '
                 f'$C8 (from frame {first})', fontsize=10)
    ax.set_xlabel(f"ms from the first OUT (work/docC/fight, window {chirp['window']})")
    ax.set_ylabel('tone (Hz)')
    ax.grid(alpha=0.3)
    ax.legend(fontsize=8, loc='upper left')
    fig.tight_layout()
    fig.savefig(args.out)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='command', required=True)
    e = sub.add_parser('extract')
    K.add_trace_args(e)
    e.add_argument('--out', required=True)
    c = sub.add_parser('chart')
    c.add_argument('--fire', required=True)
    c.add_argument('--chirp', required=True)
    c.add_argument('--out', required=True)
    args = p.parse_args()
    extract(args) if args.command == 'extract' else chart(args)


if __name__ == '__main__':
    main()
