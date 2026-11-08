#!/usr/bin/env python3
"""The beeper as recorded (docs/09-sound.md): every OUT to port $FE in an access trace, the speaker bit (bit 4) as a
pitch track. Each dot is one half cycle: its time from the effect's first edge, and the pitch it implies
(3.5 MHz / two half cycles); the dot's colour is the routine whose OUT made the edge.

    python3 tools/fig_sound.py OUT.png TRACE:FROM-TO:LABEL [TRACE:FROM-TO:LABEL ...] [--title TEXT] [--dump]

FROM-TO are frames. --dump prints, for each panel, the edges, the span, the pitch range and the writers.

    python3 tools/fig_sound.py OUT.png --spectrogram TRACE:FROM-TO:LABEL [...] [--title TEXT]

--spectrogram draws each panel's speaker bit as a spectrogram instead: the bit sampled at 44.1 kHz, 256-sample
(5.8 ms) Hann windows every 32 samples, each window's mean removed, the power in dB on a log frequency axis. A
steady tone shows as a line with its odd harmonics above; a pulse train or noise spreads over many lines.

    python3 tools/fig_sound.py OUT.png --timeline TRACE:FROM-TO [--title TEXT]

draws instead who plays the sound frame by frame: the T each frame spends in the sound code inside the interrupt
and from the main code, the frames whose interrupt was lost, the request bits of SoundRequests and SoundMode.
"""
import argparse
import bisect
import os
import re
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import rtplot as P  # noqa: E402

CLOCK = 3500000
FRAME = 69888
IM2_ENTRY, IM2_RET = 0xFF25, 0xFF4B  # IM2Handler and its RET
SOUND = (0x9509, 0x96C5)  # sound.asm's code, ClearShips excluded below
BEEPER = (0x03B5, 0x03F8)
BITS = ['0 energy bomb', '1 missile', '2 explosion', '3 ship hit', '4 laser', '5 ECM', '6 player hit']
ANN = os.path.join(HERE, '..', 'src', 'game', 'game.ann')


def routines():
    out = []
    for line in open(ANN):
        m = re.match(r'^\$([0-9A-F]{4}) c (\w+)', line)
        if m:
            out.append((int(m.group(1), 16), m.group(2)))
    out.sort()
    return [a for a, _ in out], [n for _, n in out]


def edges(path, first, last):
    """[(T from the trace's start, pc)] of every change of the speaker bit in frames first-last"""
    trace = K.access_trace().load(path)
    times = K.instruction_times(trace)
    units = max(1, trace.units_per_t)
    out, level = [], None
    for i, x in enumerate(trace.instructions):
        if not first <= x.frame <= last:
            continue
        at = times[i]
        for c in x.cycles:
            at += c.dt / units
            if c.tag == 'O' and c.address & 0xFF == 0xFE:
                bit = c.value >> 4 & 1
                if level is not None and bit != level:
                    out.append((at, x.pc))
                level = bit
    return out


def timeline(spec, out, title):
    path, window = spec.split(':', 1)
    first, _, last = window.partition('-')
    first, last = int(first), int(last)
    trace = K.access_trace().load(os.path.join(P.CASE, path))
    times = K.instruction_times(trace)
    n = last - first + 1
    irq, main, taken = [0.0] * n, [0.0] * n, [0] * n
    requests, mode = {}, {}
    inside = False
    req, md = None, None
    for i, x in enumerate(trace.instructions):
        if x.pc == IM2_ENTRY:
            inside = True
        f = x.frame - first
        if 0 <= f < n:
            if x.pc == IM2_ENTRY:
                taken[f] += 1
            if SOUND[0] + 0x19 <= x.pc < SOUND[1] or BEEPER[0] <= x.pc < BEEPER[1]:
                dt = (times[i + 1] if i + 1 < len(times) else times[i]) - times[i]
                (irq if inside else main)[f] += dt
        for c in x.cycles:
            if c.tag == 'W' and c.address == 0x7128:
                req = c.value
            if c.tag == 'W' and c.address == 0x9522:
                md = c.value
        if 0 <= f < n:
            requests[f], mode[f] = req, md
        if x.pc == IM2_RET:
            inside = False
    fig, (ax, bx) = P.figure(9.6, 7.4, nrows=2, ncols=1, sharex=True,
                             gridspec_kw={'height_ratios': [1.25, 1], 'hspace': 0.32})
    xs = list(range(first, last + 1))
    ax.bar(xs, [v / 1000 for v in irq], width=0.9, color=P.HOT, label='sound inside the interrupt (SoundTick)')
    ax.bar(xs, [v / 1000 for v in main], width=0.9, bottom=[v / 1000 for v in irq], color=P.WRITE,
           label='sound from the main code (SoundPlay, the click)')
    lost = [x for x, t in zip(xs, taken) if not t]
    ax.scatter(lost, [FRAME / 1000 + 4] * len(lost), marker='v', s=16, color=P.READ, label='no interrupt taken')
    ax.axhline(FRAME / 1000, color=P.DIM, lw=0.8, ls='--')
    ax.text(last, FRAME / 1000 - 1.5, 'one frame, 69 888 T ', color=P.DIM, fontsize=9, ha='right', va='top')
    ax.set_ylim(0, FRAME / 1000 + 9)
    ax.set_ylabel('thousand T a frame')
    ax.legend(loc='upper left', bbox_to_anchor=(0, -0.04), fontsize=8.5, ncol=3, frameon=False)
    total = sum(irq) + sum(main)
    ax.set_title('Sound T in the window: %.0f k of %.0f k (%.0f %%); %d of %d interrupts taken' % (
        total / 1000, n * FRAME / 1000, 100 * total / (n * FRAME), sum(1 for t in taken if t), n), fontsize=10.5,
        loc='left')
    for b, name in enumerate(BITS):
        on = [x for x in xs if requests.get(x - first) is not None and requests[x - first] >> b & 1]
        bx.scatter(on, [b] * len(on), marker='s', s=22, color=P.PALETTE[b % len(P.PALETTE)], lw=0)
    names = {0: 'none', 1: 'sweep', 2: 'noise', 3: 'pulses', 0x83: 'pulses, two-phase'}
    for x in xs:
        m = mode.get(x - first)
        if m:
            bx.scatter([x], [7.4], marker='s', s=22, color=P.EXEC if m & 0x7F == 3 else P.HOT if m == 1 else P.READ,
                       lw=0)
    prev, k = None, 0
    for x in xs:
        m = mode.get(x - first)
        if m and m != prev:
            bx.text(x, 7.8 + 0.6 * (k % 2), names.get(m, '%02X' % m), fontsize=8.5, color=P.TEXT, va='bottom')
            k += 1
        prev = m
    bx.set_yticks(list(range(7)) + [7.4])
    bx.set_yticklabels(['request bit ' + n for n in BITS] + ['SoundMode'], fontsize=8.5)
    bx.set_ylim(-0.7, 9.4)
    bx.set_xlabel('frame (the request and the mode as they stand at the end of each frame)')
    bx.grid(True, axis='x', lw=0.4)
    fig.suptitle(title, fontsize=12)
    fig.subplots_adjust(left=0.12, right=0.98, top=0.9, bottom=0.08)
    P.save(fig, out)


def spectrogram(ax, e, rate=44100, size=256, hop=32):
    """the speaker bit of edges e as a power spectrogram on ax (x in ms from the first edge, y in Hz)"""
    import numpy as np
    start = e[0][0]
    n = int((e[-1][0] - start) / CLOCK * rate) + size
    t = np.arange(n) / rate * CLOCK + start
    level = (np.searchsorted([a for a, _ in e], t, side='right') % 2).astype(float) - 0.5
    window = np.hanning(size)
    cols = []
    for k in range(0, n - size, hop):
        part = level[k:k + size]
        cols.append(np.abs(np.fft.rfft((part - part.mean()) * window)) ** 2)
    db = 10 * np.log10(np.array(cols).T + 1e-9)
    hz = np.fft.rfftfreq(size, 1 / rate)
    ms = (np.arange(len(cols)) * hop + size / 2) / rate * 1000
    ax.pcolormesh(ms, hz[1:], db[1:], shading='auto', cmap='magma', vmin=db.max() - 60, vmax=db.max())


def main():
    p = argparse.ArgumentParser()
    p.add_argument('out')
    p.add_argument('panels', nargs='*')
    p.add_argument('--timeline')
    p.add_argument('--title', default='The beeper, recorded')
    p.add_argument('--dump', action='store_true')
    p.add_argument('--spectrogram', action='store_true')
    args = p.parse_intermixed_args()
    if args.timeline:
        return timeline(args.timeline, args.out, args.title)
    addresses, names = routines()

    def writer(pc):
        if pc < 0x4000:
            return 'BEEPER (ROM)'
        return names[bisect.bisect_right(addresses, pc) - 1]

    panels = []
    for spec in args.panels:
        path, window, label = spec.split(':', 2)
        a, _, b = window.partition('-')
        e = edges(os.path.join(P.CASE, path), int(a), int(b))
        panels.append((label, e))
    if args.dump:
        for label, e in panels:
            if not e:
                print(label, 'no edges')
                continue
            halves = [b[0] - a[0] for a, b in zip(e, e[1:])]
            hz = sorted(CLOCK / (2 * h) for h in halves if h > 0)
            print('%s: %d edges over %.1f ms, pitch %.0f-%.0f Hz (median %.0f), %s' % (
                label, len(e), (e[-1][0] - e[0][0]) / CLOCK * 1000, hz[0], hz[-1], hz[len(hz) // 2],
                dict(Counter(writer(pc) for _, pc in e))))
        return
    fig, axes = P.figure(9.6, 2.5 * len(panels) + 1.0, nrows=len(panels), ncols=2,
                         gridspec_kw={'width_ratios': [3.2, 1]}, squeeze=False)
    colour = P.colours(sorted({writer(pc) for _, e in panels for _, pc in e}))
    for (ax, wave), (label, e) in zip(axes, panels):
        start = e[0][0]
        xs, ys, cs = [], [], []
        for (t0, pc), (t1, _) in zip(e, e[1:]):
            if t1 > t0:
                xs.append((t0 - start) / CLOCK * 1000)
                ys.append(CLOCK / (2 * (t1 - t0)))
                cs.append(colour[writer(pc)])
        if args.spectrogram:
            spectrogram(ax, e)
        else:
            ax.scatter(xs, ys, s=6, c=cs, lw=0)
        ax.set_yscale('log')
        ax.set_ylim(25, 20000)
        ax.set_ylabel('pitch, Hz')
        ax.grid(True, which='major', lw=0.4)
        span = (e[-1][0] - start) / CLOCK * 1000
        ax.set_title('%s\n%d edges over %.0f ms' % (label, len(e), span), fontsize=10.5, loc='left')
        # the waveform: the speaker level over 6 ms from the middle of the effect
        mid = start + (e[-1][0] - start) * 0.5
        i = next(k for k, (t, _) in enumerate(e) if t >= mid)
        level, tx, ty = i % 2, [], []
        for t, _ in e[i:]:
            if t - e[i][0] > 0.006 * CLOCK:
                break
            x = (t - e[i][0]) / CLOCK * 1000
            tx += [x, x]
            ty += [level, 1 - level]
            level = 1 - level
        wave.plot(tx, ty, color=P.WRITE, lw=0.9)
        wave.set_ylim(-0.3, 1.3)
        wave.set_yticks([0, 1])
        wave.set_xlim(0, 6)
        wave.set_title('speaker bit:\n6 ms at %.0f ms' % ((e[i][0] - start) / CLOCK * 1000), fontsize=9.5,
                       loc='left')
    axes[-1][0].set_xlabel('ms from the first edge' + (' (the power: dark low, bright high, 60 dB range)'
                                                        if args.spectrogram else
                                                        ' (a dot is one half cycle, at the pitch it implies)'))
    axes[-1][1].set_xlabel('ms')
    handles = [] if args.spectrogram else [P.plt.matplotlib.patches.Patch(color=c, label='edge made by ' + n)
                                           for n, c in colour.items()]
    if handles:
        fig.legend(handles=handles, loc='lower center', ncol=min(4, len(handles)), fontsize=9, frameon=False)
    fig.suptitle(args.title, fontsize=12.5)
    fig.tight_layout(rect=(0, 0.035, 1, 1))
    P.save(fig, args.out)


if __name__ == '__main__':
    main()
