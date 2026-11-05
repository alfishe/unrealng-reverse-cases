#!/usr/bin/env python3
"""Every effect of the page-4 engine, simulated from its loaded image (docs/09-sound.md 9.6): its length, channels,
pitch and volume a step, a chart of all of them and a WAV each (written to files, never played).

    python3 tools/fig_effects.py table
    python3 tools/fig_effects.py chart --out docs/img/sound/effects.png
    python3 tools/fig_effects.py wav --dir work/z128B/effects
    python3 tools/fig_effects.py check --data work/z128B/ports-w1.json --entry C9A1 --frame 2984

The engine (build/sound/engine-c968.bin, engine-data-de48.bin) runs in SkoolKit's simulator as tools/sound_render.py
runs it: StartMusic ($CA25, LastChannel = 3), StopMusic ($CA0F: the state in play, where the glue stopped the music
at the level's start), then the effect's entry ($C971-$C9B1), then PlayFrame ($CA60) a step at a time until no
channel is active (the records' +$1E at $CCBA, $CCE7, $CD14) or 300 steps (a sound whose top level ends in $FF
starts again: it plays until the next StopMusic).

check compares one effect's simulated register steps with the recording's (tools/fig_ports.py collect data): the
steps of the recording from the frame the hook stub ran in, the volumes and tone periods of the channel the effect
took.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sound_render as S  # noqa: E402

CLOCK = 1773400
# entry: (name, sounds, the event, the hook stub or caller)
ENTRIES = [
    (0xC971, 'EffectShot', '$0E', 'the player fires a laser shot', 'stub $B32F, site $9C77'),
    (0xC975, 'EffectExtraLife', '$0F + $10', 'an extra life', 'stub $B334, site $ACA2'),
    (0xC97B, 'EffectBombBounce', '$11', 'a plasma bomb bounces', 'stub $B33C, site $9EC2'),
    (0xC97F, 'EffectRoleOfHonour', '$12', 'the role of honour shown', 'stub $B344, site $A81B'),
    (0xC983, 'EffectSound13', '$13', 'no caller', '-'),
    (0xC987, 'EffectShipLost', '$14 + $15', 'the ship destroyed; the honour result', 'stubs $B354, $B34C'),
    (0xC98B, 'EffectHomingLaunch', '$1A + $1B', 'a homing missile launched', 'stub $B35C, site $9CFA'),
    (0xC991, 'EffectPodTaken', '$16', 'a pod scooped (the selector moves)', 'stub $B364, site $A247'),
    (0xC995, 'EffectSound17', '$17', 'no caller', '-'),
    (0xC999, 'EffectSpecialLaunch', '$18', 'a bomb, missile or seeker leaves the ship', 'stub $B36C, site $9CB0'),
    (0xC99D, 'EffectEnemyMissile', '$19', 'an enemy fires', 'stub $B374, site $A1C4'),
    (0xC9A1, 'EffectWeaponSelect', '$0F', 'a weapon selected (pod + fire held)', 'stub $B379, site $A21A'),
    (0xC9A5, 'EffectLevelStart', '$10', 'a level starts', 'glue $5B6D'),
    (0xC9A9, 'EffectPodAppears', '$1C', 'a pod appears', 'stub $B381, site $A31D'),
    (0xC9AD, 'EffectExplosion', '$1D', 'an explosion starts', 'stub $B386, site $A29F'),
    (0xC9B1, 'EffectScreenWipe', '$1E + $1F', 'the screen wipe; SELECTIONS', 'stubs $B39C, $B38F'),
]
ACTIVE = (0xCCBA, 0xCCE7, 0xCD14)
MAX = 300


def simulate(entry, venv, steps=MAX, music=False):
    """[(regs, active channels)] a step after the entry was called, the state as in play (the music stopped)"""
    p = S.Player('game', venv)
    regs = [0] * 14
    regs[7] = 0x3F
    for r, v in p.start():
        regs[r] = v
    if not music:
        for r, v in p.call(0xCA0F):
            regs[r] = v
    p.call(entry)
    out = []
    for i in range(steps):
        for r, v in p.frame():
            if r < 14:
                regs[r] = v
        act = tuple(p.mem[a] for a in ACTIVE)
        out.append((tuple(regs), act))
        if not any(act) and i > 0:
            break
    return out


def summary(states):
    chans = sorted({c for _, act in states for c in range(3) if act[c]})
    n = len(states)
    loops = n >= MAX
    hz = []
    noise = False
    for regs, act in states:
        for c in chans:
            vol = regs[8 + c] & 15
            if not vol:
                continue
            if not regs[7] & (1 << c):
                period = (regs[2 * c] | regs[2 * c + 1] << 8) & 0xFFF
                if period:
                    hz.append(CLOCK / (16 * period))
            if not regs[7] & (8 << c):
                noise = True
    return chans, n, loops, (min(hz), max(hz)) if hz else None, noise


def cmd_table(args):
    print('| Entry | Name | Sounds | Event | Called by | Channels | Steps | Tone (Hz) | Noise |')
    print('| --- | --- | --- | --- | --- | --- | --- | --- | --- |')
    for entry, name, sounds, what, caller in ENTRIES:
        st = simulate(entry, args.venv)
        chans, n, loops, hz, noise = summary(st)
        length = f'{n}+ (loops)' if loops else str(n)
        tone = f'{hz[0]:.0f}-{hz[1]:.0f}' if hz else '-'
        print(f"| `${entry:04X}` | `{name}` | {sounds} | {what} | {caller} | {''.join('ABC'[c] for c in chans)} | "
              f'{length} | {tone} | {"yes" if noise else "no"} |')


def cmd_chart(args):
    import math
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.style.use('dark_background')
    cols = 4
    rows = (len(ENTRIES) + cols - 1) // cols
    fig, axes = plt.subplots(rows, cols, figsize=(12.5, 2.35 * rows + 0.9))
    colours = ('#4fc3f7', '#ffb74d', '#f06292')
    shown = args.steps
    for ax, (entry, name, sounds, what, caller) in zip(axes.flat, ENTRIES):
        st = simulate(entry, args.venv)
        chans, n, loops, hz, noise = summary(st)
        ax2 = ax.twinx()
        for c in chans:
            xs, ps, vs, ns = [], [], [], []
            for i, (regs, act) in enumerate(st[:shown]):
                vol = regs[8 + c] & 15
                vs.append(vol)
                period = (regs[2 * c] | regs[2 * c + 1] << 8) & 0xFFF
                tone = not regs[7] & (1 << c)
                if vol and tone and period:
                    xs.append(i)
                    ps.append(12 * math.log2(CLOCK / (16 * period) / 440) + 69)
                if vol and not regs[7] & (8 << c):
                    ns.append(i)
            ax2.fill_between(range(len(vs)), vs, step='post', color=colours[c], alpha=0.32, lw=0)
            ax.scatter(xs, ps, s=3, color=colours[c])
            ax.scatter(ns, [30] * len(ns), s=3, marker='s', color=colours[c])
        ax2.set_ylim(0, 16)
        ax2.set_yticks([])
        ax.set_ylim(28, 112)
        ax.set_yticks([36, 60, 84, 108])
        ax.set_yticklabels(['C2', 'C4', 'C6', 'C8'], fontsize=7)
        ax.set_xlim(0, shown)
        ax.tick_params(axis='x', labelsize=7)
        length = f'{n}+ steps, loops' if loops else f'{n} steps'
        ax.set_title(f"${entry:04X} {sounds.replace('$', '')}: {what}\n{length}, "
                     f"{''.join('ABC'[c] for c in chans) or '-'}{', noise' if noise else ''}".replace('$', r'\$'),
                     fontsize=8, loc='left')
    for ax in axes.flat[len(ENTRIES):]:
        ax.axis('off')
    fig.suptitle('Every engine effect as it starts in play (simulated from the loaded bytes; checked against w1):\n'
                 'dots = the tone pitch (left scale), shading = the volume 0-15, squares at the bottom = noise on; '
                 'blue = channel A, orange = B, pink = C',
                 fontsize=10.5, x=0.01, ha='left')
    for ax in axes[-1]:
        ax.set_xlabel('engine steps (about 50 a second)', fontsize=8)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    fig.savefig(args.out, dpi=args.dpi)
    print('wrote', args.out)


def cmd_wav(args):
    os.makedirs(args.dir, exist_ok=True)
    for entry, name, sounds, what, caller in ENTRIES:
        st = simulate(entry, args.venv, steps=min(MAX, 150))
        frames = [(regs, False) for regs, act in st] + [((0,) * 7 + (0x3F,) + (0,) * 6, False)] * 10
        path = os.path.join(args.dir, f'{entry:04X}-{name}.wav')
        S.write_wav(path, S.render(frames, CLOCK))
        print('wrote', path)


def cmd_check(args):
    d = json.load(open(args.data))
    entry = int(args.entry, 16)
    st = simulate(entry, args.venv, steps=args.steps)
    # compare only up to the next effect started in the recording (it takes a channel too)
    # (a shot takes channel A only; the other effects alternate B and C, so the effect keeps its channel until the
    # second effect after it on B / C, or the first when it took both)
    sim = [regs for regs, act in st]
    chans = sorted({c for _, act in st for c in range(3) if act[c]})
    on_a = chans == [0]
    later = sorted({f for k, fr in d['stubs'].items() for f in fr if f > args.frame and (k == 'B32F') == on_a
                    and k != '5B50'})
    nth = 0 if on_a else 1
    until = later[nth] if len(later) > nth else args.frame + args.steps
    rec = [s for s in d['steps'] if args.frame <= s['frame'] < until]
    maps = [dict(zip(chans, chans))]
    if chans == [1]:
        maps.append({1: 2})
    if chans == [1, 2]:
        maps.append({1: 2, 2: 1})
    best = None
    for m in maps:
        for off in range(0, 3):
            ok = tot = 0
            for i, regs in enumerate(sim[:len(rec) - off]):
                r = rec[i + off]['regs']
                for c, rc in m.items():
                    tot += 1
                    ok += (r[8 + rc] == regs[8 + c] and r[2 * rc] == regs[2 * c] and r[2 * rc + 1] == regs[2 * c + 1])
            if tot and (best is None or ok / tot > best[1] / best[2]):
                best = (off, ok, tot, m)
    if best is None:
        print(f'entry ${entry:04X} at frame {args.frame}: no step before the next effect')
        return
    m = ', '.join(f"{'ABC'[c]} as {'ABC'[rc]}" for c, rc in best[3].items())
    print(f'entry ${entry:04X} at frame {args.frame}: simulated {m}, {best[0]} steps later: {best[1]} / {best[2]} '
          f'channel-steps equal (volume and period), compared up to frame {until}')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--venv', default=os.environ.get('SKOOLKIT_VENV', S.DEFAULT_VENV))
    sub = p.add_subparsers(dest='cmd', required=True)
    sub.add_parser('table').set_defaults(func=cmd_table)
    c = sub.add_parser('chart')
    c.add_argument('--out', required=True)
    c.add_argument('--steps', type=int, default=120)
    c.add_argument('--dpi', type=int, default=80)
    c.set_defaults(func=cmd_chart)
    w = sub.add_parser('wav')
    w.add_argument('--dir', required=True)
    w.set_defaults(func=cmd_wav)
    k = sub.add_parser('check')
    k.add_argument('--data', required=True)
    k.add_argument('--entry', required=True)
    k.add_argument('--frame', type=int, required=True)
    k.add_argument('--steps', type=int, default=40)
    k.set_defaults(func=cmd_check)
    args = p.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
