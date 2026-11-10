#!/usr/bin/env python3
"""The figures and the WAVs of docs/09-sound.md, from the speaker events of tools/sound_events.py.

    python3 tools/fig_sound.py tone       docs/img/sound/tone.png: ToneBeep, the first cycles and every period
    python3 tools/fig_sound.py noise      docs/img/sound/noise.png: NoiseBurst, the gate mask E of every burst
    python3 tools/fig_sound.py cost       docs/img/sound/cost.png: each sound against the interrupts taken
    python3 tools/fig_sound.py soundoff   docs/img/sound/soundoff.png: the experiment, a fire with SOUND on and off
    python3 tools/fig_sound.py wav        docs/audio/*.wav: each sound from its measured edges, 44 100 Hz mono 16 bit
    python3 tools/fig_sound.py waves      docs/img/sound/waves.png: every WAV and its spectrogram
    python3 tools/fig_sound.py all

Inputs (work/docs/scD, made by work/docs/scD/run_dis.sh and tools/sound_events.py):
dis-{fire,flood,quake,meltdown}.json (the disasters recording), tools-occupied.json (the tools recording, frames
13430-13460) and exp-soundoff.json (work/docs/scD/exp_soundoff.py). A T of an event is counted from the start of the
frame in which the instruction ran.
"""
import argparse
import json
import os
import struct
import wave

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
EV = os.path.join(CASE, 'work', 'docs', 'scD')
IMG = os.path.join(CASE, 'docs', 'img', 'sound')
AUDIO = os.path.join(CASE, 'docs', 'audio')
CLOCK, RATE, FT = 3_500_000, 44_100, 69_888
DISPLAY = (14_336, 14_336 + 192 * 224)   # the T of a frame in which the ULA fetches the screen (contention)

plt.rcParams.update({'font.size': 11, 'axes.titlesize': 11, 'axes.labelsize': 10.5, 'xtick.labelsize': 10,
                     'ytick.labelsize': 10, 'legend.fontsize': 10, 'text.parse_math': False})

# key, json, caller, what
NOISES = [('fire', 'dis-fire', 'FireNoise', 'FIRE: 127 bursts, E = B AND $3F'),
          ('flood', 'dis-flood', 'FloodNoise', 'FLOOD: 127 bursts, E = NOT B AND $7F'),
          ('quake', 'dis-quake', 'Earthquake', 'EARTHQUAKE: 255 bursts, E = C >> 4'),
          ('meltdown', 'dis-meltdown', 'CrashNoise', 'MELTDOWN: 255 bursts, E = 0, 1 ... 254 (INC E)')]
COLOURS = {'fire': '#d62728', 'flood': '#1f77b4', 'quake': '#8c564b', 'meltdown': '#2ca02c', 'tone': '#9467bd'}


def load(name):
    d = json.load(open(os.path.join(EV, f'{name}.json')))
    d['outs'] = [(f * FT + t, v, pc) for f, t, v, pc in d['out_fe']]
    d['abs_calls'] = [(f * FT + t, n, a, bc, de, hl, c) for f, t, n, a, bc, de, hl, c in d['calls']]
    d['irqs'] = [f * FT + t for f, t, _ in d['irq']]
    return d


def edges(outs):
    """[(t, level)] where the speaker bit (bit 4) changes; the first write is kept as the start"""
    es, last = [], None
    for t, v, _ in outs:
        b = v >> 4 & 1
        if b != last:
            es.append((t, b))
            last = b
    return es


def bursts(d):
    """[(t, E)] for each NoiseBurst entry; E is the low byte of DE"""
    return [(t, de & 0xFF) for t, n, a, bc, de, hl, c in d['abs_calls'] if n == 'NoiseBurst']


def save(fig, name):
    os.makedirs(IMG, exist_ok=True)
    path = os.path.join(IMG, name)
    fig.savefig(path, dpi=100)
    plt.close(fig)
    print(os.path.relpath(path, CASE))


def ft(t):
    return f'{t // FT}:{t % FT}'


# ------------------------------------------------------------------------------------------------ tone

def cmd_tone(_a):
    d = load('tools-occupied')
    outs = d['outs']
    t0 = outs[0][0]
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10.5, 7.4), gridspec_kw={'height_ratios': [1, 1.25]})
    # the first five cycles as a step line, with the measured halves
    n = 11
    xs = [(t - t0) for t, _, _ in outs[:n]]
    ys = [v >> 4 & 1 for _, v, _ in outs[:n]]
    ax1.step(xs, ys, where='post', color=COLOURS['tone'], lw=2)
    for i in range(n - 1):
        mid = (xs[i] + xs[i + 1]) / 2
        ax1.text(mid, 0.5, f'{xs[i + 1] - xs[i]} T', ha='center', va='center', fontsize=10,
                 bbox={'fc': 'white', 'ec': '#999', 'lw': 0.6})
    ax1.set_yticks([0, 1], ['0 (OUT $FE,0)', '1 (OUT $FE,$10)'])
    ax1.set_ylim(-0.2, 1.25)
    ax1.set_xlabel(f'T after the first OUT ({ft(t0)}, frame:T)')
    ax1.set_title(f'The first five cycles: the high half (L = $30 DJNZ loops) and the low half (H = $10), '
                  f'all in the display period', loc='left')
    # every period of the 500 cycles against the frame time; interrupts as lines
    on = [t for t, v, _ in outs if v & 0x10]
    per = [(a, b - a) for a, b in zip(on, on[1:])]
    disp = [(a, p) for a, p in per if DISPLAY[0] <= a % FT < DISPLAY[1]]
    bord = [(a, p) for a, p in per if not DISPLAY[0] <= a % FT < DISPLAY[1]]
    for grp, col, lab in ((disp, '#d62728', 'cycle starts in the display period (contended)'),
                          (bord, '#1f77b4', 'cycle starts in the border period')):
        ax2.scatter([(a - t0) / FT for a, _ in grp], [p for _, p in grp], s=9, color=col, label=lab)
    for it in d['irqs']:
        if t0 - FT < it < outs[-1][0] + FT:
            ax2.axvline((it - t0) / FT, color='#888', lw=0.8, ls='--')
    ax2.axhline(889, color='#333', lw=0.8)
    ax2.text(0.02, 905, '889 T: the uncontended period (3 937 Hz)', fontsize=10)
    ax2.set_xlabel('frames after the first OUT (dashed: an interrupt taken, the handler runs)')
    ax2.set_ylabel('T from one "on" to the next')
    ax2.set_title(f'All 500 periods: {len(outs)} writes over {(outs[-1][0] - t0) / FT:.1f} frames '
                  f'({(outs[-1][0] - t0) / CLOCK * 1000:.0f} ms)', loc='left')
    ax2.legend(loc='upper right')
    fig.suptitle('ToneBeep $5B66: the refusal of an occupied cell (tools recording, frames 13434-13442)', fontsize=12)
    fig.tight_layout()
    save(fig, 'tone.png')


# ------------------------------------------------------------------------------------------------ noise

def cmd_noise(_a):
    fig, axs = plt.subplots(3, 1, figsize=(10.5, 10.2), gridspec_kw={'height_ratios': [1.2, 1, 1]})
    ax = axs[0]
    for key, js, caller, what in NOISES:
        b = bursts(load(js))
        wide = key == 'flood'   # its E is the meltdown's first 127: drawn wide beneath it
        ax.plot(range(1, len(b) + 1), [e for _, e in b], '-' if wide else '.-', ms=3, lw=6 if wide else 0.8,
                alpha=0.45 if wide else 1, zorder=1 if wide else 2, color=COLOURS[key],
                label=f'{what}, {(b[-1][0] - b[0][0]) / FT:.0f} frames' + (' (under MELTDOWN)' if wide else ''))
    ax.set_xlabel('burst number')
    ax.set_ylabel('E at the burst (gate mask)')
    ax.set_yscale('symlog', linthresh=4)
    ax.set_yticks([0, 1, 3, 7, 15, 31, 63, 127, 254], ['0', '1', '3', '7', '15', '31', '63', '127', '254'])
    ax.set_title('The gate mask E of every burst: a new random bit each time (D AND E) = 0; '
                 'a larger E is a lower, sparser noise', loc='left')
    ax.legend(loc='lower right', fontsize=9.5)
    # one E = 0 burst and one E = 15 burst, 4 ms each
    for ax, key, js, e_want in ((axs[1], 'fire', 'dis-fire', 0), (axs[2], 'quake', 'dis-quake', 15)):
        d = load(js)
        b = bursts(d)
        i = max(k for k, (_, e) in enumerate(b) if e == e_want)
        start, end = b[i][0], b[i + 1][0] if i + 1 < len(b) else b[i][0] + FT
        ws = [(t, v, pc) for t, v, pc in d['outs'] if start <= t < end]
        es = edges(ws)
        span = 4e-3 * CLOCK
        xs = [(t - start) / CLOCK * 1000 for t, _ in es if t - start < span]
        ys = [lv for t, lv in es if t - start < span]
        ax.step(xs + [4], ys + [ys[-1]], where='post', color=COLOURS[key], lw=1.2)
        ax.plot([(t - start) / CLOCK * 1000 for t, _, _ in ws if t - start < span],
                [1.12] * sum(1 for t, _, _ in ws if t - start < span), '|', color='#333', ms=7)
        gaps = [b2 - a2 for (a2, _, _), (b2, _, _) in zip(ws, ws[1:])]
        ax.set_xlim(0, 4)
        ax.set_ylim(-0.15, 1.25)
        ax.set_yticks([0, 1])
        ax.set_xlabel(f'ms after the burst start ({ft(start)})')
        ax.set_title(f'{key.upper()} burst {i + 1} of {len(b)}, E = {e_want}: {len(ws)} OUTs (ticks), '
                     f'median {int(np.median(gaps))} T apart, {len(es)} level changes', loc='left')
    fig.suptitle('NoiseBurst $5B48: the disaster noise (disasters recording)', fontsize=12)
    fig.tight_layout()
    save(fig, 'noise.png')


# ------------------------------------------------------------------------------------------------ cost

def cmd_cost(_a):
    rows = [(key, js, what.split(':')[0]) for key, js, _, what in NOISES] + [('tone', 'tools-occupied', 'REFUSAL')]
    fig, ax = plt.subplots(figsize=(10.5, 5.2))
    for y, (key, js, label) in enumerate(rows):
        d = load(js)
        a, z = d['outs'][0][0], d['outs'][-1][0]
        f0 = a // FT - 3
        ax.barh(y, (z - a) / FT, left=(a - f0 * FT) / FT, height=0.5, color=COLOURS[key], alpha=0.75)
        taken = [t for t in d['irqs'] if a <= t <= z]
        window = [t for t in d['irqs'] if f0 * FT <= t <= z + 4 * FT]
        ax.plot([(t - f0 * FT) / FT for t in window], [y] * len(window), '|', color='black', ms=16, mew=1.3)
        frames = (z - a) / FT
        ax.text((z - f0 * FT) / FT + 5, y, f'{frames:.1f} frames, {len(taken)} of {int(frames) + 1} '
                f'interrupts taken', va='center', fontsize=10)
    ax.set_yticks(range(len(rows)), [r[2] for r in rows])
    ax.invert_yaxis()
    ax.set_xlim(0, 190)
    ax.set_xlabel('frames from 3 frames before the first OUT (bar: first to last speaker write; '
                  'tick: an interrupt taken)')
    ax.set_title('The cost of a sound: NoiseBurst runs with DI, so the frame interrupts are lost; ToneBeep keeps '
                 'them', loc='left')
    fig.tight_layout()
    save(fig, 'cost.png')


# ------------------------------------------------------------------------------------------------ soundoff

def cmd_soundoff(_a):
    log = json.load(open(os.path.join(EV, 'exp-soundoff.json')))
    fig, axs = plt.subplots(1, 3, figsize=(10.5, 4.0))
    for sound, col, lab in ((1, '#2ca02c', 'SOUND on (control)'), (0, '#d62728', 'SOUND off')):
        pts = [(fr, st) for s, fr, st in log if s == sound]
        xs = [fr for fr, _ in pts]
        axs[0].step(xs, [st['interrupt']['iff1'] for _, st in pts], where='post', color=col, lw=2, label=lab)
        axs[1].plot(xs, [st['year'] * 12 + st['month'] - (1935 * 12 + 11) for _, st in pts], 'o-', color=col)
        passes, tot, last = [], 0, None
        for _, st in pts:
            if last is not None:
                tot += (st['pass'] - last) & 0xFF
            last = st['pass']
            passes.append(tot)
        axs[2].plot(xs, passes, 'o-', color=col)
    axs[0].set_title('IFF1 (interrupts enabled)', loc='left')
    axs[0].set_yticks([0, 1])
    axs[0].legend(loc='center right', fontsize=9.5)
    axs[1].set_title('months after DEC 1935', loc='left')
    axs[1].set_yticks([0, 1])
    axs[2].set_title('UI passes (PassCount)', loc='left')
    for ax in axs:
        ax.set_xlabel('frames after FIRE is set')
        ax.axvline(400, color='#888', lw=0.8, ls='--')
    axs[2].text(395, 5, 'P held', ha='right', fontsize=9.5, color='#555')
    fig.suptitle('A fire with SOUND off: the interrupts never come back, the simulation and the keys stop '
                 '(city2/end.szx, a clone)', fontsize=11.5)
    fig.tight_layout()
    save(fig, 'soundoff.png')


# ------------------------------------------------------------------------------------------------ wav

def render(es, path, pad_ms=30):
    """the speaker bit from its edges [(t, level)], 44.1 kHz 16-bit mono, a soft high-pass (no DC)"""
    t0 = es[0][0]
    n = int((es[-1][0] - t0) / CLOCK * RATE) + int(pad_ms * RATE / 1000)
    buf = np.zeros(n)
    for (a, lv), (b, _) in zip(es, es[1:] + [(es[-1][0] + int(pad_ms * CLOCK / 1000), 0)]):
        i0, i1 = int((a - t0) / CLOCK * RATE), min(n, int((b - t0) / CLOCK * RATE))
        buf[i0:i1] = lv
    out = np.zeros(n)
    prev_in = prev_out = 0.0
    for i, s in enumerate(buf):
        prev_out = 0.995 * (prev_out + s - prev_in)
        prev_in = s
        out[i] = prev_out
    pcm = (np.clip(out, -1, 1) * 12000).astype('<i2')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    print(os.path.relpath(path, CASE), f'{n / RATE * 1000:.0f} ms')


WAVS = [  # file, json, what
    ('fire-noise', 'dis-fire', 'FireNoise, 127 bursts (disasters 134-177)'),
    ('flood-noise', 'dis-flood', 'FloodNoise, 127 bursts (disasters 2236-2276)'),
    ('earthquake-noise', 'dis-quake', 'Earthquake, 255 bursts (disasters 4403-4522)'),
    ('meltdown-noise', 'dis-meltdown', 'CrashNoise of the meltdown, 255 bursts (disasters 11020-11091)'),
    ('refusal-tone', 'tools-occupied', 'ToneBeep, 500 cycles (tools 13434-13442)'),
]


def cmd_wav(_a):
    for name, js, _ in WAVS:
        render(edges(load(js)['outs']), os.path.join(AUDIO, f'{name}.wav'))


def cmd_waves(_a):
    fig, axs = plt.subplots(len(WAVS), 2, figsize=(10.5, 2.0 * len(WAVS) + 0.6),
                            gridspec_kw={'width_ratios': [1, 1]})
    for row, (name, _, what) in zip(axs, WAVS):
        with wave.open(os.path.join(AUDIO, f'{name}.wav')) as w:
            n = w.getnframes()
            data = np.frombuffer(w.readframes(n), dtype='<i2').astype(float)
        secs = n / RATE
        step = max(1, n // 6000)
        row[0].plot(np.arange(0, n, step) / RATE, data[::step], lw=0.5, color='#333')
        row[0].set_yticks([])
        row[0].set_xlim(0, secs)
        row[0].set_title(f'{name}.wav, {secs:.2f} s', loc='left', fontsize=10.5)
        row[1].specgram(data, NFFT=512, Fs=RATE, noverlap=256, cmap='magma', vmin=-10)
        row[1].set_ylim(0, 12000)
        row[1].set_yticks([0, 4000, 8000, 12000], ['0', '4k', '8k', '12k'])
        row[1].set_ylabel('Hz')
        row[1].set_title(what, loc='left', fontsize=10)
    axs[-1][0].set_xlabel('s')
    axs[-1][1].set_xlabel('s')
    fig.suptitle('The rendered sounds (docs/audio): waveform (left) and spectrogram (right), from the measured '
                 'speaker edges', fontsize=11.5)
    fig.tight_layout()
    save(fig, 'waves.png')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['tone', 'noise', 'cost', 'soundoff', 'wav', 'waves', 'all'])
    a = p.parse_args()
    cmds = {'tone': cmd_tone, 'noise': cmd_noise, 'cost': cmd_cost, 'soundoff': cmd_soundoff, 'wav': cmd_wav,
            'waves': cmd_waves}
    for k in (cmds if a.what == 'all' else [a.what]):
        cmds[k](a)


if __name__ == '__main__':
    main()
