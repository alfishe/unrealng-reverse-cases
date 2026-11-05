#!/usr/bin/env python3
"""The AY port timeline of a recording (docs/09-sound.md 9.8): when the page-4 engine writes the AY, from which glue
entry, what it writes, and which hook stub started which effect.

    python3 tools/fig_ports.py collect --work work/z128B/r1 --from 440 --to 1160 --out work/z128B/ports-r1.json
    python3 tools/fig_ports.py draw --data work/z128B/ports-r1.json --out docs/img/sound/port-timeline.png
    python3 tools/fig_ports.py stats --data work/z128B/ports-r1.json

collect (the instance of W up, its recording loaded):
  - `time_travel port_events` ay-select and ay-write over the frames: the engine's output (`SendRegisters` of
    `PlayFrame` `$CA60`, the `OUTD` loop at `$CA49` / `$CA4C`) is 14 selects R13 down to R0, each followed by its
    write; a select of R13 starts one engine step. Each step keeps its frame, T-state and the 14 values;
  - `time_travel coverage_scan` (executed) of the four glue entries that call the engine (`$5B21` the menu handler,
    `$5B28` the handler tail, `$5B31` the play pass's start, `$5B3C` its end; RAM page 5) and of the 15 hook stubs
    (page 2) with their engine entries (page 4), as tools/play_stubs.py does: the frames each ran in.
draw --kind timing: the T-state of each engine step in its TV frame, coloured by its glue entry, over the phases
  (menu pages, play), and the time since the step before.
draw --kind effects --window F:G: the effects started in F..G (the frames of each hook stub and its engine entry, and
  of the glue's level start and music switch), over the three channels' volumes and tone / noise bits.
stats: the spacing of the steps in T per glue entry and per phase (menu, play).
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

GLUE = {0x5B21: 'PlayAtA9E5', 0x5B28: 'PlayAtA581', 0x5B31: 'PlayAtA9F7', 0x5B3C: 'PlayAtAB03'}
# stub: (site, engine entry, sounds, event)
STUBS = {
    0xB32F: (0x9C77, 0xC971, '$0E', 'laser shot'),
    0xB334: (0xACA2, 0xC975, '$0F+$10', 'extra life'),
    0xB33C: (0x9EC2, 0xC97B, '$11', 'bomb bounce'),
    0xB344: (0xA81B, 0xC97F, '$12', 'role of honour'),
    0xB34C: (0xA8B7, 0xC987, '$14+$15', 'honour result'),
    0xB354: (0x9BFF, 0xC987, '$14+$15', 'ship lost'),
    0xB35C: (0x9CFA, 0xC98B, '$1A+$1B', 'homing launch'),
    0xB364: (0xA247, 0xC991, '$16', 'pod taken'),
    0xB36C: (0x9CB0, 0xC999, '$18', 'special launch'),
    0xB374: (0xA1C4, 0xC99D, '$19', 'enemy missile'),
    0xB379: (0xA21A, 0xC9A1, '$0F', 'weapon selected'),
    0xB381: (0xA31D, 0xC9A9, '$1C', 'pod appears'),
    0xB386: (0xA29F, 0xC9AD, '$1D', 'explosion'),
    0xB38F: (0xA7BB, 0xC9B1, '$1E+$1F', 'SELECTIONS'),
    0xB39C: (0xA5D1, 0xC9B1, '$1E+$1F', 'screen wipe'),
}
# glue routines that start or stop sound (RAM page 5): (engine entry or None, sounds, what)
GLUE_SOUND = {0x5B6D: (0xC9A5, '$10', 'level start (glue $5B6D)'),
              0x5B50: (None, 'music', 'music off / restart (glue $5B50)')}
FRAME_T = {'PENTAGON': 71680, '128K': 70908}


def scan(s, address, page, first, last):
    body = {'action': 'coverage_scan', 'kind': 'executed', 'addr_from': hex(address), 'addr_to': hex(address),
            'phys_page': page, 'limit': 10000, 'from_frame': first, 'to_frame': last}
    r = s.call('time_travel', body, ok=False)
    frames = (r.structured or {}).get('frames') or []
    return [int(f['frame']) if isinstance(f, dict) else int(f) for f in frames]


def events(s, kind, first, last):
    out = []
    for lo in range(first, last + 1, 200):
        hi = min(last, lo + 199)
        r = s.call('time_travel', {'action': 'port_events', 'event': kind, 'from_frame': lo, 'to_frame': hi + 1,
                                   'limit': 20000, 'context': False}, ok=False)
        hits = (r.structured or {}).get('hits') or []
        out += [(h['frame'], h['tinframe'], h['value'], h['pc']) for h in hits if lo <= h['frame'] <= hi]
    return sorted(set(out), key=lambda h: (h[0], h[1]))


def collect(args):
    import z128lib as Z
    s = Z.session(args.work)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    sel = events(s, 'ay-select', args.first, args.last)
    wr = events(s, 'ay-write', args.first, args.last)
    # pair each select with the next write (the OUTD loop: select, then write, 50 T apart)
    wi, steps, cur = 0, [], None
    for f, t, reg, pc in sel:
        while wi < len(wr) and (wr[wi][0], wr[wi][1]) < (f, t):
            wi += 1
        val = wr[wi][2] if wi < len(wr) and wr[wi][0] == f else None
        if reg == 13:
            cur = {'frame': f, 't': t, 'pc': pc, 'regs': [None] * 14}
            steps.append(cur)
        if cur is not None and val is not None:
            cur['regs'][reg] = val
    glue = {name: scan(s, a, 5, args.first, args.last) for a, name in GLUE.items()}
    stubs = {}
    for stub, (site, entry, sounds, what) in STUBS.items():
        sf = set(scan(s, stub, 2, args.first, args.last))
        ef = set(scan(s, entry, 4, args.first, args.last))
        stubs[f'{stub:04X}'] = sorted(sf & ef)
    for g, (entry, sounds, what) in GLUE_SOUND.items():
        gf = set(scan(s, g, 5, args.first, args.last))
        if entry:
            gf &= set(scan(s, entry, 4, args.first, args.last))
        stubs[f'{g:04X}'] = sorted(gf)
    model = json.load(open(os.path.join(args.work, 'session.json'))).get('model', 'PENTAGON')
    json.dump({'work': args.work, 'from': args.first, 'to': args.last, 'model': model, 'steps': steps,
               'glue': glue, 'stubs': stubs}, open(args.out, 'w'))
    print(f'{len(steps)} engine steps, {len(sel)} selects, {len(wr)} writes; glue',
          {k: len(v) for k, v in glue.items()}, 'stubs', {k: len(v) for k, v in stubs.items() if v})


def label_steps(d):
    """the glue entry of each step: the entries that ran in its frame, in their order inside the handler"""
    order = ['PlayAtA9E5', 'PlayAtA9F7', 'PlayAtA581', 'PlayAtAB03']
    ran = {name: set(fr) for name, fr in d['glue'].items()}
    byframe = {}
    for st in d['steps']:
        byframe.setdefault(st['frame'], []).append(st)
    for f, sts in byframe.items():
        names = [n for n in order if f in ran[n]]
        if len(names) == len(sts):
            for st, n in zip(sts, names):
                st['glue'] = n
        else:
            # a pass that runs over a frame edge: the start ran in the frame before
            for st in sts:
                st['glue'] = (('PlayAtA9F7' if st['t'] < 2000 else 'PlayAtAB03') if names and names[0] in
                              ('PlayAtA9F7', 'PlayAtAB03') else (names[0] if names else '?'))
    return d['steps']


def stats(args):
    d = json.load(open(args.data))
    T = FRAME_T.get(d['model'], 71680)
    steps = label_steps(d)
    by = {}
    prev = None
    for st in steps:
        at = st['frame'] * T + st['t']
        if prev is not None:
            by.setdefault((prev['glue'], st['glue']), []).append(at - prev['at'])
        st['at'] = at
        prev = st
    for k, v in sorted(by.items(), key=lambda kv: -len(kv[1])):
        v = sorted(v)
        print(f'{k[0]:>11} -> {k[1]:<11} {len(v):4} gaps, T min {v[0]} median {v[len(v) // 2]} max {v[-1]}')
    names = {}
    for st in steps:
        names.setdefault(st['glue'], []).append(st['t'])
    for n, ts in names.items():
        ts = sorted(ts)
        print(f'{n:>11}: {len(ts)} steps, T in frame {ts[0]}-{ts[-1]}, median {ts[len(ts) // 2]}')
    print('frames', d['from'], d['to'], 'steps', len(steps), 'per frame', round(len(steps) / (d['to'] - d['from'] + 1), 3))


def esc(text):
    return text.replace('$', r'\$')


def draw_timing(args, d, steps, T, plt):
    """the T-state of each step and the time since the previous one, over the phases"""
    fig, axes = plt.subplots(2, 1, figsize=(12, 7.4), sharex=True, gridspec_kw={'height_ratios': [3, 1.7]})
    colours = {'PlayAtA9E5': '#4fc3f7', 'PlayAtA581': '#aed581', 'PlayAtA9F7': '#ffb74d', 'PlayAtAB03': '#f06292',
               '?': '#9e9e9e'}
    words = {'PlayAtA9E5': 'the menu handler, at its start (PlayAtA9E5 \\$5B21)',
             'PlayAtA581': 'the raster menu handler, at its tail (PlayAtA581 \\$5B28)',
             'PlayAtA9F7': 'the play pass, at its start (PlayAtA9F7 \\$5B31)',
             'PlayAtAB03': 'the play pass, at its end (PlayAtAB03 \\$5B3C)'}
    phases = json.loads(args.phases or '[]')
    ax = axes[0]
    for i, (x, text) in enumerate(phases):
        x2 = phases[i + 1][0] if i + 1 < len(phases) else d['to']
        for a in axes:
            a.axvspan(x, x2, color='#ffffff' if i % 2 else '#000000', alpha=0.06, lw=0)
            a.axvline(x, color='#888', lw=0.6, ls=':')
        ax.text((x + x2) / 2, T / 1000 + 1.5, text, ha='center', va='bottom', fontsize=9, color='#eee')
    for n, c in colours.items():
        xs = [st['frame'] for st in steps if st['glue'] == n]
        ys = [st['t'] / 1000 for st in steps if st['glue'] == n]
        if xs:
            ax.scatter(xs, ys, s=8, color=c, label=f'{words.get(n, n)}: {len(xs)} steps')
    ax.set_ylim(-2, T / 1000)
    ax.set_ylabel('T-state of the step in its TV frame (x1000)')
    fig.legend(loc='lower center', ncol=2, fontsize=9, framealpha=0.9)
    fig.suptitle(args.title, fontsize=12, x=0.02, ha='left')
    for name, (x, y, text) in json.loads(args.notes or '{}').items():
        ax.annotate(esc(text), xy=(x, y), fontsize=8.8, color='white', bbox=dict(boxstyle='round', fc='#222', ec='#888'))
    ax = axes[1]
    prev = None
    xs, ys, cs = [], [], []
    for st in steps:
        at = st['frame'] * T + st['t']
        if prev is not None and st['frame'] > d['from']:
            xs.append(st['frame'])
            ys.append((at - prev) / T)
            cs.append(colours.get(st['glue'], '#999'))
        prev = at
    ax.scatter(xs, ys, s=6, c=cs)
    ax.set_ylim(0, 2.2)
    ax.set_yticks([0, 0.5, 1, 1.5, 2])
    ax.axhline(1, color='#888', lw=0.6)
    ax.set_ylabel('time since the step\nbefore (TV frames)')
    ax.set_xlabel(f"frame of the recording {os.path.basename(d['work'].rstrip('/'))} ({d['model']}, "
                  f"{T} T a frame)")
    ax.set_xlim(d['from'], d['to'])
    for name, (x, y, text) in json.loads(args.notes2 or '{}').items():
        ax.annotate(esc(text), xy=(x, y), fontsize=8.8, color='white', bbox=dict(boxstyle='round', fc='#222', ec='#888'))
    fig.subplots_adjust(left=0.08, right=0.98, top=0.9, bottom=0.21, hspace=0.12)


def draw_effects(args, d, steps, T, plt):
    """the three channels' volume and tone/noise bits per step, with the effects started"""
    lo, hi = args.window
    steps = [st for st in steps if lo <= st['frame'] <= hi]
    rows = [(k, [f for f in v if lo <= f <= hi]) for k, v in d['stubs'].items()]
    rows = [(k, v) for k, v in rows if v]
    rows.sort(key=lambda kv: kv[1][0])
    fig, axes = plt.subplots(4, 1, figsize=(12, 8.6), sharex=True,
                             gridspec_kw={'height_ratios': [max(2, len(rows)) * 0.42, 1.4, 1.4, 1.4]})
    ax = axes[0]
    for i, (k, fr) in enumerate(rows):
        site, entry, sounds, what = STUBS.get(int(k, 16)) or ((None, None) + GLUE_SOUND[int(k, 16)][1:])
        ax.scatter(fr, [i] * len(fr), marker='v', s=40, color='#ce93d8')
        ax.text(lo - 0.8, i, esc(f'{what}: {sounds}'), ha='right', va='center', fontsize=9)
        for f in fr:
            for a in axes[1:]:
                a.axvline(f, color='#ce93d8', lw=0.5, alpha=0.5)
    ax.set_yticks([])
    ax.set_ylim(-0.7, len(rows) - 0.3)
    ax.invert_yaxis()
    fig.suptitle(esc(args.title), fontsize=12, x=0.01, ha='left')
    for n, (reg, c, ch) in enumerate(((8, '#4fc3f7', 'A'), (9, '#ffb74d', 'B'), (10, '#f06292', 'C'))):
        ax = axes[1 + n]
        xs = [st['frame'] + st['t'] / T for st in steps]
        vol = [(st['regs'][reg] or 0) & 0x1F for st in steps]
        mix = [st['regs'][7] or 0 for st in steps]
        ax.step(xs, [min(16, v) for v in vol], where='post', color=c, lw=1.2)
        tone = [i for i, m in enumerate(mix) if not m & (1 << n) and vol[i]]
        noise = [i for i, m in enumerate(mix) if not m & (8 << n) and vol[i]]
        ax.scatter([xs[i] for i in tone], [17.3] * len(tone), s=5, marker='s', color='#e0e0e0')
        ax.scatter([xs[i] for i in noise], [19.1] * len(noise), s=5, marker='s', color='#ff8a65')
        ax.set_ylim(-0.5, 20.3)
        ax.set_yticks([0, 8, 15, 17.3, 19.1])
        ax.set_yticklabels(['0', '8', '15', 'tone', 'noise'], fontsize=8)
        ax.set_ylabel(f'channel {ch}\nR{reg} volume', fontsize=9)
    axes[-1].set_xlabel(f"frame of the recording {os.path.basename(d['work'].rstrip('/'))} ({d['model']}); "
                        f"one step of the line = one engine step (the AY's state until the next)")
    axes[-1].set_xlim(lo, hi + 1)
    fig.subplots_adjust(left=0.22, right=0.98, top=0.92, bottom=0.07, hspace=0.1)


def draw(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    d = json.load(open(args.data))
    T = FRAME_T.get(d['model'], 71680)
    steps = label_steps(d)
    plt.style.use('dark_background')
    if args.kind == 'timing':
        draw_timing(args, d, steps, T, plt)
    else:
        draw_effects(args, d, steps, T, plt)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    plt.savefig(args.out, dpi=args.dpi)
    print('wrote', args.out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('collect')
    a.add_argument('--work', required=True)
    a.add_argument('--from', dest='first', type=int, required=True)
    a.add_argument('--to', dest='last', type=int, required=True)
    a.add_argument('--out', required=True)
    a.set_defaults(func=collect)
    b = sub.add_parser('draw')
    b.add_argument('--data', required=True)
    b.add_argument('--out', required=True)
    b.add_argument('--title', default='')
    b.add_argument('--kind', choices=('timing', 'effects'), default='timing')
    b.add_argument('--window', type=lambda v: tuple(int(x) for x in v.split(':')), help='F:G for --kind effects')
    b.add_argument('--notes2', help='JSON {name: [x, y, text]}: notes on the second panel (timing)')
    b.add_argument('--phases', help='JSON list of [frame, text]: the phase boundaries')
    b.add_argument('--notes', help='JSON {name: [x, y, text]}: notes on the top panel (y in kT)')
    b.add_argument('--dpi', type=int, default=80)
    b.set_defaults(func=draw)
    c = sub.add_parser('stats')
    c.add_argument('--data', required=True)
    c.set_defaults(func=stats)
    args = p.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
