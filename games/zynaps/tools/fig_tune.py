#!/usr/bin/env python3
"""The title tune as a chart, modelled from its bytes (docs/09-sound.md 9.2).

    python3 tools/fig_tune.py [--wav work/zyB/audio/title-tune.wav]

Reads src/res/music/titletune.tune.txt through tools/res_tune.py (the bytes $FF01-$FFD3) and plays it on paper the
way TitleTune $B446 does: a length command L<n> sets n x 16 x 256 passes of the tone loop, a pass is 81 T
($B486-$B49B, uncontended), a note n runs two counters of p = TunePeriods[n] and p + 1 passes, each wrap flips the
speaker: two square waves of 3500000 / (2 x 81 x p) and 3500000 / (2 x 81 x (p + 1)) Hz, beating at their
difference. Draws docs/img/sound/tune-roll.png (the whole tune, one bar a note, coloured by pattern) and, with --wav
(tools/render_audio.py's capture of the beeper), docs/img/sound/tune-measured.png: the spectrogram of the captured
sound with the model's notes drawn over it.
"""
import argparse
import os
import sys

import numpy as np

import zybplot as P
import res_tune

CLOCK, PASS_T = 3500000, 81


def notes():
    """[(start s, length s, note, period, pattern name, pattern index in the order)]"""
    text = open(os.path.join(P.CASE, 'src', 'res', 'music', 'titletune.tune.txt'), 'rb').read()
    data = res_tune.from_text(text)
    periods = list(data[:27])
    order = [data[27 + 2 * k] | data[28 + 2 * k] << 8 for k in range(7)]
    names = {}
    at = 27 + 14
    k = 0
    while at < len(data):
        names[0xFF01 + at] = 'ABCDEFG'[k]
        at = data.index(0xFF, at) + 1
        k += 1
    t, out, length = 0.0, [], 0
    for i, ptr in enumerate(order):
        at = ptr - 0xFF01
        while data[at] != 0xFF:
            b = data[at]
            at += 1
            if b >= 0xC0:
                length = (b & 0x0F) * 16 * 256
                continue
            p = periods[b]
            dur = length * PASS_T / CLOCK
            out.append((t, dur, b, p, names[ptr], i))
            t += dur
    return out, periods


def hz(p):
    """the pitch heard: each counter flips the speaker every p (p + 1) passes, so the speaker carries the XOR of two
    square waves of 3500000 / (2 x 81 x p) Hz; their XOR is a pulse train of twice that, 3500000 / (81 p), whose width
    is the counters' phase difference (one pass more each period): the slow sweep of the sound"""
    return CLOCK / (PASS_T * p)


def hz_counter(p):
    return CLOCK / (2 * PASS_T * p)


def roll(ns, periods):
    P.style()
    fig, ax = P.plt.subplots(figsize=(13, 5.2))
    cols = {'A': P.COLOURS[1], 'B': P.COLOURS[2], 'C': P.COLOURS[3], 'D': P.COLOURS[4]}
    for t, d, n, p, name, i in ns:
        ax.add_patch(P.plt.Rectangle((t, n - 0.4), d * 0.97, 0.8, color=cols[name], lw=0))
    starts = {}
    for t, d, n, p, name, i in ns:
        starts.setdefault(i, (t, name))
    for i, (t, name) in starts.items():
        ax.axvline(t, color=P.DIM, lw=0.8, ls=':')
        ax.text(t + 0.1, 26.6, f'{name}', color=cols[name], fontsize=12, fontweight='bold')
    end = ns[-1][0] + ns[-1][1]
    ax.axvline(end, color=P.DIM, lw=0.8, ls=':')
    used = sorted({n for _, _, n, _, _, _ in ns})
    ax.set_yticks(range(1, 27))
    ax.set_yticklabels([f'{n:2d}  p={periods[n]:3d}  {hz(periods[n]):3.0f} Hz' + ('' if n in used else '  (unused)')
                        for n in range(1, 27)], fontsize=7.5, family='monospace')
    ax.set_ylim(0.3, 27.4)
    ax.set_xlim(0, end + 0.2)
    ax.set_xlabel('seconds from the first note (48K, 81 T a pass of the tone loop)')
    ax.set_title(f'The title tune from its bytes: 7 patterns A A B A C C D, {len(ns)} notes, {end:.1f} s, '
                 f'notes 1-25 of 26 ({hz(242):.0f}-{hz(57):.0f} Hz heard)')
    ax.grid(axis='x', alpha=0.4)
    for k, name in enumerate('ABCD'):
        ax.add_patch(P.plt.Rectangle((0, 0), 0, 0, color=cols[name], label={
            'A': 'A the theme (3 times)', 'B': 'B the arpeggios', 'C': 'C the ostinato (twice)',
            'D': 'D the close'}[name]))
    ax.legend(loc='upper right', fontsize=8.5, bbox_to_anchor=(0.995, 0.9))
    fig.tight_layout()
    P.save(fig, P.out('sound', 'tune-roll.png'))
    return end


def measured(ns, wav, end):
    import wave
    w = wave.open(wav)
    rate = w.getframerate()
    raw = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    if w.getnchannels() == 2:
        raw = raw[0::2]
    x = raw.astype(float)
    # the first note: the first sample loud enough
    first = int(np.argmax(np.abs(x - np.median(x)) > 2000))
    x = x[first:first + int((end + 0.3) * rate)]
    P.style()
    fig, axes = P.plt.subplots(2, 1, figsize=(13, 7.4), gridspec_kw={'height_ratios': [3, 1.3]})
    ax = axes[0]
    nfft = 8192
    ax.specgram(x, NFFT=nfft, Fs=rate, noverlap=nfft - 1024, cmap='magma', vmin=-10, vmax=60)
    for t, d, n, p, name, i in ns:
        ax.plot([t, t + d], [hz(p)] * 2, color=(0.3, 1, 0.5), lw=1.2, alpha=0.9)
    ax.set_ylim(120, 2400)
    ax.set_yscale('log')
    ticks = [179, 251, 357, 502, 758, 1516]
    ax.set_yticks(ticks)
    ax.set_yticklabels([str(v) for v in ticks])
    ax.set_ylabel('Hz')
    ax.set_xlim(0, end)
    ax.set_title('The tune as unreal-ng sounded it (beeper capture, spectrogram) and the model (green: 3.5 MHz / 81p, '
                 'twice one counter\'s rate): they agree')
    # a zoom: the longest note at its start and 0.8 s later (the measured time runs 1.7 % slower than the model and
    # starts 0.1 s before the first note: the cut of render_audio.py)
    scale = (len(x) / rate - 0.3) / end
    t0, d0, n0, p0 = max(((t, d, n, p) for t, d, n, p, name, i in ns), key=lambda v: v[1])
    ax2 = axes[1]
    for k, (off, colour) in enumerate(((0.2, P.COLOURS[2]), (0.8, P.COLOURS[3]))):
        a = int((0.1 + (t0 + off) * scale) * rate)
        b = a + int(0.03 * rate)
        y = x[a:b]
        y = (y - y.min()) / max(1, y.max() - y.min())
        ax2.plot(np.arange(b - a) / rate * 1000, y + 1.25 * (1 - k), color=colour, lw=0.8,
                 label=f'{off:.2f} s into the note')
    ax2.set_xlabel('ms')
    ax2.set_yticks([])
    ax2.legend(loc='upper right', fontsize=8)
    ax2.set_title(f'30 ms of note {n0} (p = {p0}, {d0:.2f} s) 0.2 and 0.8 s in: pulses at {hz(p0):.0f} Hz '
                  f'(every {p0} passes), their width the phase difference of the two counters, which grows one '
                  f'pass a period', fontsize=9.5)
    fig.tight_layout()
    P.save(fig, P.out('sound', 'tune-measured.png'))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--wav')
    args = p.parse_args()
    ns, periods = notes()
    end = roll(ns, periods)
    print(f'{len(ns)} notes, {end:.2f} s')
    if args.wav:
        measured(ns, args.wav, end)


if __name__ == '__main__':
    sys.exit(main())
