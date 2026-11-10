#!/usr/bin/env python3
"""Doc 09: the beeper measured from the speaker writes of the recordings, and drawn.

The events come from tools/sound_events.py (work/docs/tjD/<recording>-events.json): every `OUT ($FE)` with its
value, PC and moment (frame, T-state in the frame), every entry of the sound routines, every interrupt entry.

    python3 tools/fig_sound.py table      every sound site measured (the numbers of doc 09)
    python3 tools/fig_sound.py shapes     docs/img/sound/shapes.png: one call of each site, the speaker bit
    python3 tools/fig_sound.py sweeps     docs/img/sound/sweeps.png: the pitch of RiseSweep and FallSweep per edge
    python3 tools/fig_sound.py teleport   docs/img/sound/teleport.png: the teleport's sound and the lost interrupts
    python3 tools/fig_sound.py cost       docs/img/sound/cost.png: the sound's share of each frame, lost interrupts
    python3 tools/fig_sound.py wav        docs/audio/*.wav: each sound from its measured edges, 44 100 Hz mono 16 bit
    python3 tools/fig_sound.py waves      docs/img/sound/waves.png: every WAV drawn against time
    python3 tools/fig_sound.py all
"""
import argparse
import json
import os
import struct
import wave
from collections import defaultdict

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.ticker  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
EV = os.path.join(CASE, 'work', 'docs', 'tjD')
IMG = os.path.join(CASE, 'docs', 'img', 'sound')
AUDIO = os.path.join(CASE, 'docs', 'audio')
CLOCK, RATE, FT = 3_500_000, 44_100, 69_888

SITES = {0x7F79: 'PassTick', 0x7B68: 'PrintBcd', 0x7B6C: 'PrintBcd', 0x785A: 'PickupTone', 0x69D5: 'HazardFlash',
         0x7F51: 'RiseSweep', 0x7F61: 'FallSweep', 0x7FD0: 'BeamDown', 0x801A: 'BeamUp'}
ENTRY = {'PassTick': 0x7F6D, 'PrintBcd': 0x7B3F, 'PickupTone': 0x7856, 'HazardFlash': 0x699B,
         'RiseSweep': 0x7F4D, 'FallSweep': 0x7F5D, 'BeamDown': 0x7F9C, 'BeamUp': 0x8005}
COLOURS = {'PassTick': '#1f77b4', 'PrintBcd': '#ff7f0e', 'PickupTone': '#2ca02c', 'HazardFlash': '#d62728',
           'RiseSweep': '#9467bd', 'FallSweep': '#8c564b', 'BeamDown': '#e377c2', 'BeamUp': '#17becf'}
# the recordings traced (work/docs/tjD/run_traces.sh) and their windows
RECS = {'r30': ('rzx-030000', '0-672'), 'energy-out': ('energy-out', '540-1700'),
        'game-over': ('game-over', '150-1100'), 'win': ('win', '0-600'), 'rzx-036000': ('rzx-036000', '0-869'),
        'menu-cursor': ('menu-cursor', '0-1201'), 'rzx-059000': ('rzx-059000', '0-43'),
        'rzx-031000': ('rzx-031000', '0-247'), 'rzx-028000': ('rzx-028000', '0-474')}

plt.rcParams.update({'font.size': 11, 'axes.titlesize': 11, 'axes.labelsize': 10.5, 'xtick.labelsize': 10,
                     'ytick.labelsize': 10, 'legend.fontsize': 10, 'text.parse_math': False})


def load(key):
    d = json.load(open(os.path.join(EV, f'{key}-events.json')))
    d['outs'] = [(f * FT + t, v, pc) for f, t, v, pc in d['out_fe']]
    d['abs_calls'] = [(f * FT + t, n, a, bc, de, hl, c) for f, t, n, a, bc, de, hl, c in d['calls']]
    d['irqs'] = [f * FT + t for f, t, _ in d['irq']]
    return d


def ft(t):
    return f'{t // FT}:{t % FT}'


def edges(outs, level=None):
    """[(t, new level)] from the writes: a write that changes bit 4"""
    out = []
    for t, v, pc in outs:
        b = (v >> 4) & 1
        if b != level:
            out.append((t, b, pc))
            level = b
    return out


def calls_of(d, name):
    return [c for c in d['abs_calls'] if c[1] == name]


def outs_between(d, a, b, pcs=None):
    return [o for o in d['outs'] if a <= o[0] < b and (pcs is None or o[2] in pcs)]


def call_spans(d, name):
    """each call of a sound routine: its writes, from its entry to the next entry of any traced routine of the
    same name, or to its last write"""
    pcs = [p for p, n in SITES.items() if n == name]
    cs = calls_of(d, name)
    spans = []
    for i, c in enumerate(cs):
        end = cs[i + 1][0] if i + 1 < len(cs) else c[0] + 300 * FT
        w = [o for o in outs_between(d, c[0], end, pcs)]
        if w:
            spans.append((c, w))
    return spans


def in_display(t):
    return 14336 <= t % FT < 14336 + 192 * 224


# ------------------------------------------------------------------------------------------------ table

def cmd_table(_a):
    print('site  routine      rec          calls  writes/call  edge gaps (T): min  median  max   span/call (T)')
    rows = [('PassTick', 'menu-cursor'), ('PrintBcd', 'energy-out'), ('PickupTone', 'rzx-036000'),
            ('PickupTone', 'rzx-059000'), ('HazardFlash', 'menu-cursor'), ('HazardFlash', 'rzx-036000'),
            ('RiseSweep', 'r30'), ('FallSweep', 'r30'), ('FallSweep', 'energy-out'), ('BeamDown', 'r30'),
            ('BeamUp', 'r30')]
    for name, key in rows:
        d = load(key)
        sp = call_spans(d, name)
        gaps, spans, n = [], [], []
        for c, w in sp:
            ts = [o[0] for o in w]
            gaps += [ts[i + 1] - ts[i] for i in range(len(ts) - 1)]
            spans.append(ts[-1] - ts[0])
            n.append(len(w))
        if name == 'PassTick':
            gaps = [g for g in gaps if g < 20000]
        gaps.sort()
        print(f'{ENTRY[name]:04X}  {name:12} {key:12} {len(sp):5}  {min(n):3}-{max(n):<5}  '
              f'{gaps[0]:6} {gaps[len(gaps) // 2]:7} {gaps[-1]:6}   {min(spans)}-{max(spans)}')
    # whole calls: entry to return (the next instruction after the routine is not traced: use the next call or
    # the last write + the tail)
    for key in ('r30', 'energy-out'):
        d = load(key)
        for name in ('RiseSweep', 'FallSweep', 'BeamDown', 'BeamUp', 'TeleportFlash', 'DeathEffect', 'Teleport'):
            for c in calls_of(d, name):
                print(key, name, ft(c[0]), f'DE={c[4]:04X}')
    # interrupts lost: interrupts entered per window against frames
    for key, (a, b) in (('r30', (118, 249)), ('r30', (251, 500)), ('r30', (509, 616)), ('energy-out', (1570, 1634)),
                        ('rzx-059000', (25, 28))):
        d = load(key)
        n = sum(1 for t in d['irqs'] if a * FT <= t < b * FT)
        print(f'{key} frames {a}-{b}: {b - a} frames, {n} interrupts entered')
    # the PassTick halves: the gap low -> high, by where in the frame it starts
    d = load('menu-cursor')
    w = [o for o in d['outs'] if o[2] == 0x7F79]
    g_disp, g_bord = [], []
    for i in range(0, len(w) - 1, 2):
        g = w[i + 1][0] - w[i][0]
        (g_disp if in_display(w[i][0]) else g_bord).append(g)
    print('PassTick low half: in the display', sorted(set(g_disp))[:8], len(g_disp), 'in the border',
          sorted(set(g_bord))[:8], len(g_bord))
    # the pass period seen by PassTick
    starts = [w[i][0] for i in range(0, len(w), 2)]
    per = [starts[i + 1] - starts[i] for i in range(len(starts) - 1)]
    from collections import Counter
    print('PassTick period (frames):', Counter(round(p / FT) for p in per).most_common(5))


# ------------------------------------------------------------------------------------------------ shapes

def step_xy(ts, levels, t0, scale=1.0):
    xs, ys = [], []
    for t, b in zip(ts, levels):
        x = (t - t0) / CLOCK * 1e6 * scale
        if xs:
            xs.append(x)
            ys.append(ys[-1])
        xs.append(x)
        ys.append(b)
    return xs, ys


def cmd_shapes(_a):
    panels = [('PassTick', 'menu-cursor', 0, 'three passes: a low pulse each'),
              ('PrintBcd', 'energy-out', 0, 'the click: 50 edges 42 T apart'),
              ('PickupTone', 'rzx-036000', 0, 'its first 40 of 256 edges'),
              ('HazardFlash', 'rzx-036000', 0, 'an edge per attribute row'),
              ('RiseSweep', 'r30', 0, '220 edges, each 13 T shorter'),
              ('FallSweep', 'r30', 0, '256 edges, each 13 T longer'),
              ('BeamDown', 'r30', 0, 'a line: 30 edges, then the delay'),
              ('BeamUp', 'r30', 0, 'a line erased: the same')]
    fig, axs = plt.subplots(4, 2, figsize=(10.5, 10.5))
    for ax, (name, key, k, note) in zip(axs.flat, panels):
        d = load(key)
        sp = call_spans(d, name)
        c, w = sp[k]
        if name == 'PassTick':
            w = sp[k][1] + sp[k + 1][1] + sp[k + 2][1]
        if name == 'PickupTone':
            w = w[:41]
        if name in ('BeamDown', 'BeamUp'):
            w = w[:31]
        e = edges(w)
        ts, lv = [x[0] for x in e], [x[1] for x in e]
        t0 = ts[0]
        span = ts[-1] - t0
        unit, scale = ('ms', 1e-3) if span > 20000 else ('us', 1)
        xs, ys = step_xy(ts, lv, t0, scale)
        ax.plot(xs, ys, color=COLOURS[name], lw=1.1)
        ax.set_ylim(-0.25, 1.45)
        ax.set_yticks([0, 1])
        ax.set_yticklabels(['0', '1'])
        ax.set_xlabel(unit + ' from the first edge')
        ax.set_title(f'{name} ${ENTRY[name]:04X}: {note}', fontsize=10.5)
        ax.text(0.01, 0.93, f'{RECS[key][0]} {ft(c[0])}, {len(e)} edges, {span} T',
                transform=ax.transAxes, fontsize=10, va='top')
        ax.grid(alpha=0.3)
    fig.suptitle('Every beeper sound of Tujad, one call each: the speaker bit (port $FE bit 4) as written', fontsize=12)
    fig.tight_layout()
    save(fig, 'shapes.png')


# ------------------------------------------------------------------------------------------------ sweeps

def cmd_sweeps(_a):
    fig, axs = plt.subplots(1, 2, figsize=(10.5, 5.2))
    for ax, (name, key, ks) in zip(axs, (('RiseSweep', 'r30', (0, 1)), ('FallSweep', 'r30', (0, 1)))):
        sp = call_spans(load(key), name)
        for k, style in zip(ks, ('-', '--')):
            c, w = sp[k]
            ts = [o[0] for o in w]
            gaps = [ts[i + 1] - ts[i] for i in range(len(ts) - 1)]
            hz = [CLOCK / (2 * g) for g in gaps]
            x = [(t - ts[0]) / CLOCK * 1000 for t in ts[1:]]
            disp = sum(1 for t in ts if in_display(t))
            ax.plot(x, hz, style, lw=1.2, label=f'{ft(c[0])}: {(ts[-1] - ts[0]) / CLOCK * 1000:.0f} ms, '
                                                 f'{disp} of {len(ts)} edges in the display')
        # the model
        es = range(220, 0, -1) if name == 'RiseSweep' else [256] + list(range(1, 256))
        t, xs, ys = 0, [], []
        for e in es:
            g = 33 + 13 * e
            t += g
            xs.append(t / CLOCK * 1000)
            ys.append(CLOCK / (2 * g))
        ax.plot(xs, ys, ':', color='k', lw=1.4, label='model 33 + 13 E T a half period')
        ax.set_yscale('log')
        ax.set_ylim(250, 60000)
        ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _p: f'{v:,.0f}'))
        ax.yaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
        ax.set_xlabel('ms from the first edge')
        ax.set_ylabel('pitch, Hz (from each half period)')
        ax.set_title(f'{name} ${ENTRY[name]:04X}, two calls of TeleportFlash')
        ax.grid(alpha=0.3, which='both')
        ax.legend(loc='upper left' if name == 'RiseSweep' else 'upper right', fontsize=9.5)
    fig.suptitle('The two sweeps in rzx-030000: the pitch of each half period, measured and modelled', fontsize=12)
    fig.tight_layout()
    save(fig, 'sweeps.png')


# ------------------------------------------------------------------------------------------------ teleport

def cmd_teleport(_a):
    d = load('r30')
    a, b = 110 * FT, 625 * FT
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10.5, 6.2), sharex=True,
                                   gridspec_kw={'height_ratios': [3, 2]})
    names = ['PassTick', 'PrintBcd', 'BeamDown', 'FallSweep', 'RiseSweep', 'BeamUp']
    for i, name in enumerate(names):
        pcs = [p for p, n in SITES.items() if n == name]
        xs = [(o[0]) / FT for o in d['outs'] if a <= o[0] < b and o[2] in pcs]
        ax1.scatter(xs, [i] * len(xs), s=4, color=COLOURS[name], marker='|')
    ax1.set_yticks(range(len(names)))
    ax1.set_yticklabels(names)
    marks = {'Teleport': (len(names) - 0.25, 'Teleport $7719'), 'QueueMessage': (len(names) - 0.75,
             'TRANSPORTING queued'), 'TeleportFlash': (len(names) - 0.25, 'TeleportFlash $8051')}
    for c in d['abs_calls']:
        if c[1] in marks and a <= c[0] < b:
            y, label = marks[c[1]]
            ax1.axvline(c[0] / FT, color='grey', lw=0.8, ls='--')
            ax1.text(c[0] / FT + 3, y, f'{label} ({c[0] // FT})', fontsize=9.5)
    for c in calls_of(d, 'BeamDown') + calls_of(d, 'BeamUp'):
        ax1.text(c[0] / FT + 3, names.index(c[1]) + 0.18, f'{c[1]} ({c[0] // FT}, BeamScreen {c[4]})', fontsize=9.5)
    ax1.set_title('Each speaker write of rzx-030000 frames 110-625, by routine (dashed: the calls named)')
    ax1.set_ylim(-0.7, len(names) + 0.3)
    # interrupts entered per 10 frames
    bins = list(range(110, 625, 10))
    cnt = [sum(1 for t in d['irqs'] if f * FT <= t < (f + 10) * FT) for f in bins]
    ax2.bar([f + 5 for f in bins], cnt, width=9, color='#4c72b0')
    ax2.axhline(10, color='k', lw=0.8, ls=':')
    ax2.set_ylim(0, 11.5)
    ax2.set_ylabel('interrupts entered\nper 10 frames')
    ax2.set_xlabel('frame of rzx-030000')
    ax2.set_title('Interrupts the game took (10 = none lost): the sweeps run with interrupts off, the beam does not')
    ax2.grid(alpha=0.3)
    fig.suptitle('A teleport heard and timed: BeamDown, TeleportFlash (18 sweep pairs), BeamDown, BeamUp',
                 fontsize=12)
    fig.tight_layout()
    save(fig, 'teleport.png')


# ------------------------------------------------------------------------------------------------ cost

def cmd_cost(_a):
    """per routine: the T-states from entry to the last write of each call, as frames; and the interrupts lost"""
    rows = []
    for name, key in (('PassTick', 'menu-cursor'), ('PrintBcd', 'energy-out'), ('HazardFlash', 'menu-cursor'),
                      ('PickupTone', 'rzx-036000'), ('RiseSweep', 'r30'), ('FallSweep', 'r30'),
                      ('BeamUp', 'r30'), ('BeamDown', 'r30')):
        d = load(key)
        sp = call_spans(d, name)
        ts = [w[-1][0] - c[0] for c, w in sp]
        if name in ('BeamDown',):
            ts = [max(ts)]
        rows.append((name, key, sum(ts) / len(ts), len(ts)))
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10.5, 4.6), gridspec_kw={'width_ratios': [5, 4]})
    names = [r[0] for r in rows]
    vals = [r[2] / FT for r in rows]
    ax1.barh(range(len(rows)), vals, color=[COLOURS[n] for n in names])
    ax1.set_xscale('log')
    ax1.set_yticks(range(len(rows)))
    ax1.set_yticklabels([f'{n} ({k})' for n, k, *_ in rows])
    for i, v in enumerate(vals):
        ax1.text(v * 1.08, i, f'{v * FT:,.0f} T' if v < 1 else f'{v:.1f} frames', va='center', fontsize=9.5)
    ax1.set_xlim(min(vals) / 2, max(vals) * 8)
    ax1.xaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _p: f'{v:g}'))
    ax1.xaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
    ax1.set_xlabel('frames a call, entry to the last edge (log)')
    ax1.set_title('What one call costs')
    ax1.grid(alpha=0.3, axis='x')
    # lost interrupts
    spans = [('play', 'menu-cursor', 540, 820), ('death', 'energy-out', 1570, 1634),
             ('Beam\nDown', 'r30', 118, 249), ('Teleport\nFlash', 'r30', 251, 500),
             ('Beam\nUp', 'r30', 511, 616)]
    lost = []
    for label, key, a, b in spans:
        d = load(key)
        n = sum(1 for t in d['irqs'] if a * FT <= t < b * FT)
        lost.append((label, b - a, n))
    ax2.bar(range(len(lost)), [100 * (f - n) / f for _, f, n in lost], color='#c44e52')
    ax2.set_xticks(range(len(lost)))
    ax2.set_xticklabels([x[0] for x in lost], fontsize=9.5)
    for i, (_, f, n) in enumerate(lost):
        ax2.text(i, 100 * (f - n) / f + 2, f'{f - n} of {f}', ha='center', fontsize=9.5)
    ax2.set_ylim(0, 110)
    ax2.set_ylabel('% of the frames with no interrupt')
    ax2.set_title('Interrupts lost while it plays')
    fig.suptitle('The beeper\'s cost: every loop holds the CPU; the sweeps also stop the interrupt',
                 fontsize=12)
    fig.tight_layout()
    save(fig, 'cost.png')


# ------------------------------------------------------------------------------------------------ wav

def render(es, path, pad_ms=30):
    """the speaker bit from its edges [(t, level)], 44.1 kHz 16-bit mono, a soft high-pass (no DC)"""
    if not es:
        return
    t0 = es[0][0]
    n = int((es[-1][0] - t0) / CLOCK * RATE) + int(pad_ms * RATE / 1000)
    buf = [0.0] * n
    level, last = es[0][1] ^ 1, t0
    for e, b in list(es) + [(es[-1][0] + int(pad_ms * CLOCK / 1000), es[-1][1])]:
        i0 = int((last - t0) / CLOCK * RATE)
        i1 = min(n, int((e - t0) / CLOCK * RATE))
        for i in range(i0, i1):
            buf[i] = level
        level, last = b, e
    out, prev_in, prev_out = [], 0.0, 0.0
    for s in buf:
        y = 0.995 * (prev_out + s - prev_in)
        prev_in, prev_out = s, y
        out.append(int(max(-1, min(1, y)) * 12000))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack(f'<{len(out)}h', *out))
    print(os.path.relpath(path, CASE), f'{len(out) / RATE * 1000:.0f} ms')


WAVS = [  # name, recording, frames, what
    ('play-hum', 'menu-cursor', (540, 790), 'play: PassTick each pass; first the shield (HazardFlash, a digit click each 10 frames)'),
    ('digit-click', 'energy-out', (603, 604), 'PrintBcd: the click before the energy is printed'),
    ('pickup-tone', 'rzx-036000', (120, 124), 'PickupTone: GEN 19 picked up'),
    ('hazard-click', 'rzx-036000', None, 'HazardFlash: the shield, two passes'),
    ('rise-sweep', 'r30', None, 'RiseSweep: one call'),
    ('fall-sweep', 'r30', None, 'FallSweep: one call'),
    ('death', 'energy-out', (1570, 1640), 'DeathEffect: eight FallSweeps'),
    ('teleport', 'r30', (117, 620), 'a whole teleport: BeamDown, TeleportFlash, BeamDown, BeamUp'),
]


def wav_edges(name, key, frames):
    d = load(key)
    if frames:
        return [(t, b) for t, b, _ in edges(outs_between(d, frames[0] * FT, frames[1] * FT))]
    site = {'hazard-click': 'HazardFlash', 'rise-sweep': 'RiseSweep', 'fall-sweep': 'FallSweep'}[name]
    sp = call_spans(d, site)
    if site == 'HazardFlash':
        c, w = sp[0]
        return [(t, b) for t, b, _ in edges(outs_between(d, c[0], c[0] + 3 * FT))]
    c, w = sp[1]
    return [(t, b) for t, b, _ in edges(w)]


def cmd_wav(_a):
    for name, key, frames, _what in WAVS:
        render(wav_edges(name, key, frames), os.path.join(AUDIO, f'{name}.wav'))


def cmd_waves(_a):
    fig, axs = plt.subplots(len(WAVS), 1, figsize=(10.5, 1.45 * len(WAVS) + 0.6))
    for ax, (name, key, frames, what) in zip(axs, WAVS):
        with wave.open(os.path.join(AUDIO, f'{name}.wav')) as w:
            n = w.getnframes()
            data = struct.unpack(f'<{n}h', w.readframes(n))
        step = max(1, n // 6000)
        ys = data[::step]
        xs = [i * step / RATE * 1000 for i in range(len(ys))]
        ax.plot(xs, ys, lw=0.5, color='#333')
        ax.set_yticks([])
        ax.set_xlim(0, n / RATE * 1000)
        ax.set_title(f'{name}.wav, {n / RATE * 1000:.0f} ms: {what} ({RECS[key][0]})', fontsize=10.5, loc='left')
        ax.tick_params(axis='x', labelsize=9.5)
    axs[-1].set_xlabel('ms')
    fig.suptitle('The rendered sounds (docs/audio), each from its measured speaker edges', fontsize=12)
    fig.tight_layout()
    save(fig, 'waves.png')


def save(fig, name):
    os.makedirs(IMG, exist_ok=True)
    path = os.path.join(IMG, name)
    fig.savefig(path, dpi=100)
    plt.close(fig)
    print(os.path.relpath(path, CASE))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['table', 'shapes', 'sweeps', 'teleport', 'cost', 'wav', 'waves', 'all'])
    a = p.parse_args()
    cmds = {'table': cmd_table, 'shapes': cmd_shapes, 'sweeps': cmd_sweeps, 'teleport': cmd_teleport,
            'cost': cmd_cost, 'wav': cmd_wav, 'waves': cmd_waves}
    if a.what == 'all':
        for k in ('shapes', 'sweeps', 'teleport', 'cost', 'wav', 'waves'):
            cmds[k](a)
    else:
        cmds[a.what](a)


if __name__ == '__main__':
    main()
